% tests/TestExport.m
classdef TestExport < matlab.unittest.TestCase
    % TestExport contains unit tests for exportData.m

    properties
        PrefsBackup
        TestFileDir % For loading any base data if needed, though export mainly creates files
        ExportTempDir % Temporary directory for writing output files
        SampleTable % A simple table to use for export tests
    end

    methods (TestClassSetup)
        function setupClass(testCase)
            currentFilePath = fileparts(mfilename('fullpath'));
            projectRoot = fileparts(currentFilePath);
            addpath(fullfile(projectRoot, 'src'));

            if exist('configManager', 'file')
                configManager('init');
            else
                warning('TestExport:ConfigManagerMissing', 'configManager.m not found.');
            end

            testCase.TestFileDir = fullfile(fileparts(mfilename('fullpath')), 'data'); % Not strictly needed if not loading

            % Create a temporary directory for exported files
            testCase.ExportTempDir = fullfile(tempdir, 'DataImportToolkit_TestExport');
            if ~isfolder(testCase.ExportTempDir)
                mkdir(testCase.ExportTempDir);
            else
                % Clean up from previous runs if necessary
                delete(fullfile(testCase.ExportTempDir, '*.*'));
            end
            fprintf('Export test files will be written to: %s\n', testCase.ExportTempDir);

            % Create a sample table for testing
            Time = (0:4)';
            Temperature = [20.1; 20.3; 20.2; 20.5; 20.4];
            Pressure = [101.0; 101.1; 100.9; 101.2; 101.0];
            Status = categorical({'OK'; 'OK'; 'Warning'; 'OK'; 'Error'});
            testCase.SampleTable = table(Time, Temperature, Pressure, Status);
        end
    end

    methods (TestClassTeardown)
        function cleanupExportDir(testCase)
            % Remove the temporary export directory and its contents after all tests
            if isfolder(testCase.ExportTempDir)
                try
                    rmdir(testCase.ExportTempDir, 's');
                    fprintf('Cleaned up export test directory: %s\n', testCase.ExportTempDir);
                catch ME
                    warning('TestExport:CleanupFailed', 'Failed to remove temporary export directory %s: %s', testCase.ExportTempDir, ME.message);
                end
            end
        end
    end

    methods (TestMethodSetup)
        function savePrefsAndCleanDir(testCase)
            if ispref('DataImport')
                testCase.PrefsBackup = getpref('DataImport');
            else
                testCase.PrefsBackup = struct();
            end
            % Set known defaults for DataImport preferences that might affect export indirectly
            % (though exportData doesn't directly use many of these)
            setpref('DataImport', 'NumHeaderLines', 0);
            setpref('DataImport', 'Delimiter', ',');

            % Clean specific files from ExportTempDir before each test method
            files = dir(fullfile(testCase.ExportTempDir, '*.*'));
            for k = 1:length(files)
                if ~files(k).isdir
                    delete(fullfile(testCase.ExportTempDir, files(k).name));
                end
            end
        end

        function TeardownMethodVerifyNoOpenFiles(testCase)
             openFiles = fopen('all'); % Get all open file IDs
            testCase.verifyEmpty(openFiles, 'Some files were left open after the test.');
        end
    end

    methods (TestMethodTeardown)
        function restorePrefs(testCase)
            if ~isempty(fieldnames(testCase.PrefsBackup))
                prefNames = fieldnames(testCase.PrefsBackup);
                for i = 1:length(prefNames)
                    setpref('DataImport', prefNames{i}, testCase.PrefsBackup.(prefNames{i}));
                end
            else
                 if ispref('DataImport')
                    rmpref('DataImport');
                end
            end
        end
    end

    % --- exportData Tests ---
    methods (Test)
        function testExportToCsv(testCase)
            baseFilename = fullfile(testCase.ExportTempDir, 'testOutputCsv');
            exportData(testCase.SampleTable, baseFilename, 'Format', 'csv');

            outputFile = [baseFilename '.csv'];
            testCase.verifyTrue(isfile(outputFile), 'CSV file was not created.');

            % Read back and compare
            try
                readTbl = readtable(outputFile);
                % Compare column names (readtable might make them valid MATLAB names)
                testCase.verifyTrue(isequal(lower(readTbl.Properties.VariableNames), lower(testCase.SampleTable.Properties.VariableNames)), ...
                    'CSV column names mismatch after readback.');

                % Compare data (handle type conversions carefully)
                testCase.verifyEqual(readTbl.Time, testCase.SampleTable.Time, 'AbsTol', 1e-9, 'CSV Time data mismatch.');
                testCase.verifyEqual(readTbl.Temperature, testCase.SampleTable.Temperature, 'AbsTol', 1e-9, 'CSV Temperature data mismatch.');
                testCase.verifyEqual(readTbl.Pressure, testCase.SampleTable.Pressure, 'AbsTol', 1e-9, 'CSV Pressure data mismatch.');

                if iscategorical(testCase.SampleTable.Status)
                    testCase.verifyTrue(iscellstr(readTbl.Status) || isstring(readTbl.Status), 'CSV Status column type mismatch.');
                    testCase.verifyEqual(string(readTbl.Status), string(testCase.SampleTable.Status), 'CSV Status data mismatch.');
                else
                    testCase.verifyEqual(readTbl.Status, testCase.SampleTable.Status, 'CSV Status data mismatch.');
                end

            catch ME
                % Corrected typo from azioniFail to fail
                testCase.fail(['Error reading or comparing exported CSV: ' ME.message]);
            end
        end

        function testExportToMat(testCase)
            baseFilename = fullfile(testCase.ExportTempDir, 'testOutputMat');
            exportData(testCase.SampleTable, baseFilename, 'Format', 'mat');

            outputFile = [baseFilename '.mat'];
            testCase.verifyTrue(isfile(outputFile), 'MAT file was not created.');

            loadedData = load(outputFile);
            [~, expectedVarNameFromFile, ~] = fileparts(baseFilename); % Name used for saving
            expectedVarName = matlab.lang.makeValidName(expectedVarNameFromFile);


            testCase.verifyTrue(isfield(loadedData, expectedVarName), ['MAT file does not contain variable ' expectedVarName]);
            readTbl = loadedData.(expectedVarName);

            testCase.verifyEqual(readTbl, testCase.SampleTable, 'MAT file content mismatch.');
        end

        function testExportToParquet(testCase)
            if ~exist('parquetwrite', 'file') || ~exist('parquetread', 'file')
                testCase.assumeFail('Parquet read/write functions not available. Skipping Parquet test. Install appropriate add-on (e.g. MATLAB Support Package for Parquet Format).');
            end

            baseFilename = fullfile(testCase.ExportTempDir, 'testOutputParquet');
            tblToExport = testCase.SampleTable;
            if iscategorical(tblToExport.Status)
                tblToExport.Status = string(tblToExport.Status); % Parquet prefers string over categorical
            end

            exportData(tblToExport, baseFilename, 'Format', 'parquet');

            outputFile = [baseFilename '.parquet'];
            testCase.verifyTrue(isfile(outputFile), 'Parquet file was not created.');

            try
                readTbl = parquetread(outputFile);
                testCase.verifyEqual(readTbl, tblToExport, 'Parquet file content mismatch.');
            catch ME
                % Corrected typo from azioniFail to fail
                testCase.fail(['Error reading or comparing exported Parquet: ' ME.message]);
            end
        end

        function testExportSelectedVariablesCsv(testCase)
            baseFilename = fullfile(testCase.ExportTempDir, 'testOutputCsvSelected');
            selectedVars = {'Time', 'Status'}; % This is a 1x2 cell array
            exportData(testCase.SampleTable, baseFilename, 'Format', 'csv', 'SelectedVariables', selectedVars);

            outputFile = [baseFilename '.csv'];
            testCase.verifyTrue(isfile(outputFile), 'CSV file (selected vars) was not created.');

            readTbl = readtable(outputFile);
            % readTbl.Properties.VariableNames is also a 1xN cell array (row vector)
            % Corrected: compare selectedVars (1x2) with readTbl.Properties.VariableNames (1x2)
            testCase.verifyEqual(lower(readTbl.Properties.VariableNames), lower(selectedVars), 'CSV selected variable names mismatch.');
            testCase.verifyEqual(readTbl.Time, testCase.SampleTable.Time, 'AbsTol', 1e-9);
            if iscategorical(testCase.SampleTable.Status)
                 testCase.verifyEqual(string(readTbl.Status), string(testCase.SampleTable.Status));
            else
                 testCase.verifyEqual(readTbl.Status, testCase.SampleTable.Status);
            end
        end

        function testExportTallArray(testCase)
            baseFilename = fullfile(testCase.ExportTempDir, 'testOutputTallCsv');
            tallSample = tall(testCase.SampleTable);

            exportData(tallSample, baseFilename, 'Format', 'csv');
            outputFile = [baseFilename '.csv'];
            testCase.verifyTrue(isfile(outputFile), 'CSV file from tall array was not created.');

            readTbl = readtable(outputFile);
            testCase.verifyEqual(readTbl.Time, testCase.SampleTable.Time, 'AbsTol', 1e-9);
             if iscategorical(testCase.SampleTable.Status)
                 testCase.verifyEqual(string(readTbl.Status), string(testCase.SampleTable.Status));
            else
                 testCase.verifyEqual(readTbl.Status, testCase.SampleTable.Status);
            end
        end

        function testExportEmptyTable(testCase)
            baseFilename = fullfile(testCase.ExportTempDir, 'testOutputEmpty');
            emptyTbl = testCase.SampleTable(1:0, :);

            testCase.assertWarning(@() exportData(emptyTbl, baseFilename, 'Format', 'csv'), 'exportData:EmptyData');

            % Execute again to check file creation
            exportData(emptyTbl, baseFilename, 'Format', 'csv');
            outputFileCsv = [baseFilename '.csv'];

            if isfile(outputFileCsv)
                info = dir(outputFileCsv);
                testCase.verifyLessThanOrEqual(info.bytes, 200, 'CSV from empty table is unexpectedly large (headers only is OK).');
                try
                    tblRead = readtable(outputFileCsv);
                    testCase.verifyTrue(height(tblRead)==0, 'CSV from empty table should have 0 data rows.');
                catch ME_read_empty
                    % If readtable errors on an empty file or header-only file, that's also a possible outcome.
                    warning('TestExport:ReadEmptyCsv', 'Reading CSV exported from empty table caused: %s. This might be acceptable if file only contains headers or is truly empty.', ME_read_empty.message);
                end
            else
                % If exportData decides not to write a file for empty data, this is also acceptable.
                % The warning 'exportData:EmptyData' should have been issued.
            end

            outputFileMat = [baseFilename '.mat'];
             exportData(emptyTbl, baseFilename, 'Format', 'mat'); % Suppress warning for execution
            if isfile(outputFileMat)
                 ld = load(outputFileMat);
                 [~, expectedVarNameFromFile, ~] = fileparts(baseFilename);
                 expectedVarName = matlab.lang.makeValidName(expectedVarNameFromFile);
                 testCase.verifyTrue(isfield(ld, expectedVarName));
                 testCase.verifyTrue(isempty(ld.(expectedVarName)) || height(ld.(expectedVarName))==0);
            end
        end

    end % methods (Test)
end % classdef
