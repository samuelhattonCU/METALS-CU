% tests/TestDataImport.m
classdef TestDataImport < matlab.unittest.TestCase
    % TestDataImport contains unit tests for headerParser, ingestData, and previewData.

    properties
        PrefsBackup % To store original preferences
        TestFileDir % Directory containing test CSV files
        TestAssets % Struct to hold paths to test files
    end

    methods (TestClassSetup)
        % Setup executed once before all tests in the class
        function setupClass(testCase)
            % Ensure src and tests directories are on the path
            % This should ideally be handled by a startup.m script or project setup
            currentFilePath = fileparts(mfilename('fullpath')); % tests directory
            projectRoot = fileparts(currentFilePath); % project root
            addpath(fullfile(projectRoot, 'src'));

            % Initialize preferences if configManager is available
            if exist('configManager', 'file')
                configManager('init');
            else
                warning('TestDataImport:ConfigManagerMissing', 'configManager.m not found. Default preferences might not be set.');
                % Set minimal essential prefs for tests if configManager is missing
                if ~ispref('DataImport') || ~ispref('DataImport','NumHeaderLines')
                    setpref('DataImport', 'NumHeaderLines', 0);
                end
                if ~ispref('DataImport') || ~ispref('DataImport','Delimiter')
                    setpref('DataImport', 'Delimiter', ',');
                end
            end
        end
    end

    methods (TestMethodSetup)
        % Setup executed before each test method
        function saveAndSetPrefs(testCase)
            % Save original preferences
            if ispref('DataImport')
                testCase.PrefsBackup = getpref('DataImport');
            else
                testCase.PrefsBackup = struct(); % Empty struct if not set
            end

            % Define test file directory (assuming it's tests/data relative to this file)
            testCase.TestFileDir = fullfile(fileparts(mfilename('fullpath')), 'data');
            testCase.assertTrue(isfolder(testCase.TestFileDir), 'Test data directory not found.');

            % Define paths to test assets
            testCase.TestAssets = struct(...
                'noHeader', fullfile(testCase.TestFileDir, 'noHeader.csv'), ...
                'oneLineNames', fullfile(testCase.TestFileDir, 'oneLineNames.csv'), ...
                'twoLineNamesUnits', fullfile(testCase.TestFileDir, 'twoLineNamesUnits.csv'), ...
                'commented', fullfile(testCase.TestFileDir, 'commented.csv'), ...
                'malformed', fullfile(testCase.TestFileDir, 'malformed.csv'), ...
                'emptyFile', fullfile(testCase.TestFileDir, 'empty.csv'), ...
                'onlyHeaders', fullfile(testCase.TestFileDir, 'onlyHeaders.csv'), ...
                'onlyComments', fullfile(testCase.TestFileDir, 'onlyComments.csv'), ...
                'tabDelimited', fullfile(testCase.TestFileDir, 'tabDelimited.tsv') ...
            );

            % Verify all essential test files exist
            fields = fieldnames(testCase.TestAssets);
            for i = 1:length(fields)
                testCase.assertTrue(isfile(testCase.TestAssets.(fields{i})), ...
                    ['Test asset file not found: ', testCase.TestAssets.(fields{i})]);
            end

            % Reset to known preference state for DataImport if needed for a specific test
            % For most tests, we rely on headerParser/ingestData args or their internal pref handling
            setpref('DataImport', 'NumHeaderLines', 0); % Default for tests unless overridden
            setpref('DataImport', 'Delimiter', ',');   % Default for tests unless overridden
        end

        function TeardownMethodVerifyNoOpenFiles(testCase)
            % Verify no files are left open by the functions being tested
            % (This is a basic check; more sophisticated checks might be needed for file IDs)
            testCase.verifyEmpty(fopen('all'), 'Some files were left open after the test.');
        end
    end

    methods (TestMethodTeardown)
        % Teardown executed after each test method
        function restorePrefs(testCase)
            % Restore original preferences
            if ~isempty(fieldnames(testCase.PrefsBackup))
                currentGroupPrefs = fieldnames(testCase.PrefsBackup);
                for i = 1:length(currentGroupPrefs)
                    setpref('DataImport', currentGroupPrefs{i}, testCase.PrefsBackup.(currentGroupPrefs{i}));
                end
            else % If DataImport group didn't exist before, remove it
                if ispref('DataImport')
                    rmpref('DataImport');
                end
            end
        end
    end

    % --- headerParser Tests ---
    methods (Test)
        function testHeaderParserNoHeader(testCase)
            meta = headerParser(testCase.TestAssets.noHeader);
            testCase.verifyEqual(meta.numHeaderLines, 0, 'Incorrect numHeaderLines for noHeader.csv');
            testCase.verifyEqual(meta.dataStartLine, 1, 'Incorrect dataStartLine for noHeader.csv');
            testCase.verifyEmpty(meta.variableUnits, 'variableUnits should be empty for noHeader.csv if no names found');
            testCase.verifyFalse(meta.isAmbiguous, 'Should not be ambiguous for simple no header data.');
             % Expecting generated names like Var1, Var2, etc.
            testCase.verifyEqual(length(meta.variableNames), 3, 'Expected 3 generated variable names.');
            testCase.verifyEqual(meta.variableNames{1}, 'Var1', 'Incorrect first generated variable name.');
        end

        function testHeaderParserOneLineNames(testCase)
            % Test with explicit NumHeaderLines = 1
            meta = headerParser(testCase.TestAssets.oneLineNames, 'NumHeaderLines', 1);
            testCase.verifyEqual(meta.numHeaderLines, 1, 'Incorrect numHeaderLines.');
            testCase.verifyEqual(meta.dataStartLine, 2, 'Incorrect dataStartLine.');
            testCase.verifyEqual(meta.variableNames, {'ID', 'Value', 'Category'}, 'Incorrect variableNames.');
            testCase.verifyEmpty(meta.variableUnits, 'variableUnits should be empty.');
            testCase.verifyEqual(meta.delimiter, ',', 'Delimiter should be comma.');
        end

        function testHeaderParserOneLineNamesAutoDetect(testCase)
            % Test with auto-detection (NumHeaderLines = -1 or default)
            % headerParser should try to identify the header
            meta = headerParser(testCase.TestAssets.oneLineNames); % NumHeaderLines = -1 by default in parser
            testCase.verifyEqual(meta.numHeaderLines, 1, 'Auto-detected numHeaderLines incorrect.');
            testCase.verifyEqual(meta.dataStartLine, 2, 'Auto-detected dataStartLine incorrect.');
            testCase.verifyEqual(meta.variableNames, {'ID', 'Value', 'Category'}, 'Auto-detected variableNames incorrect.');
        end

        function testHeaderParserTwoLineNamesUnits(testCase)
            meta = headerParser(testCase.TestAssets.twoLineNamesUnits, 'NumHeaderLines', 2);
            testCase.verifyEqual(meta.numHeaderLines, 2);
            testCase.verifyEqual(meta.dataStartLine, 3);
            testCase.verifyEqual(meta.variableNames, {'Time', 'Temperature', 'Pressure', 'Status'});
            testCase.verifyEqual(meta.variableUnits, {'s', 'degC', 'kPa', 'flag'});
        end

        function testHeaderParserWithComments(testCase)
            meta = headerParser(testCase.TestAssets.commented, 'NumHeaderLines', 2); % Explicitly say 2 lines are name/unit after comments
            testCase.verifyGreaterThan(length(meta.commentLines), 0, 'Should detect comment lines.');
            testCase.verifyEqual(meta.variableNames, {'Time', 'Value'}, 'Variable names not parsed correctly with comments.');
            testCase.verifyEqual(meta.variableUnits, {'s', 'mV'}, 'Variable units not parsed correctly with comments.');
            % dataStartLine should be after all comments and the 2 specified "header" lines (name, unit)
            % File: #, %, #, Name, Unit, #, %, Data...
            % Comments: 3 before headers, 2 between headers and data
            % Headers: Name, Unit (2 lines)
            % Expected dataStartLine: 3 (initial comments) + 2 (name/unit) + 2 (interspersed comments) + 1 = 8
            testCase.verifyEqual(meta.dataStartLine, 8, 'dataStartLine incorrect with comments and specified headers.');
            testCase.verifyEqual(meta.numHeaderLines, 7, 'numHeaderLines (lines to skip) incorrect.');
        end

        function testHeaderParserWithCommentsAuto(testCase)
            meta = headerParser(testCase.TestAssets.commented); % Auto detect
            testCase.verifyGreaterThan(length(meta.commentLines), 0, 'Should detect comment lines (auto).');
            testCase.verifyEqual(meta.variableNames, {'Time', 'Value'}, 'Variable names (auto).');
            testCase.verifyEqual(meta.variableUnits, {'s', 'mV'}, 'Variable units (auto).');
             % Auto should find Time,Value and s,mV as headers after initial comments
            testCase.verifyEqual(meta.dataStartLine, 8, 'dataStartLine incorrect with comments (auto).');
        end

        function testHeaderParserEmptyFile(testCase)
            meta = headerParser(testCase.TestAssets.emptyFile);
            testCase.verifyNotEmpty(meta.errorMsg, 'Error message should be set for empty file.');
            testCase.verifyEqual(meta.dataStartLine, 1, 'dataStartLine should be 1 for empty file default.');
        end

        function testHeaderParserOnlyHeaders(testCase)
            meta = headerParser(testCase.TestAssets.onlyHeaders, 'NumHeaderLines', 2);
            testCase.verifyEqual(meta.variableNames, {'Name', 'Unit', 'Description'});
            testCase.verifyEqual(meta.numHeaderLines, 2);
            % dataStartLine will be 3, but no data exists. isAmbiguous might be true.
            testCase.verifyEqual(meta.dataStartLine, 3);
            testCase.verifyTrue(meta.isAmbiguous || ~isempty(meta.errorMsg), 'Should be ambiguous or error if only headers and no data found in inspection.');
        end

        function testHeaderParserOnlyComments(testCase)
            meta = headerParser(testCase.TestAssets.onlyComments);
            testCase.verifyEqual(length(meta.commentLines), 3, 'Not all comment lines detected.');
            testCase.verifyEmpty(meta.variableNames, 'Variable names should be empty.');
            testCase.verifyEqual(meta.numHeaderLines, 3, 'numHeaderLines should be count of comment lines.');
            testCase.verifyEqual(meta.dataStartLine, 4, 'dataStartLine should be after all comments.');
            testCase.verifyTrue(meta.isAmbiguous || ~isempty(meta.errorMsg), 'Should be ambiguous or error if only comments.');
        end

        function testHeaderParserTabDelimited(testCase)
            meta = headerParser(testCase.TestAssets.tabDelimited, 'Delimiter', sprintf('\t'), 'NumHeaderLines', 1);
            testCase.verifyEqual(meta.delimiter, sprintf('\t'));
            testCase.verifyEqual(meta.variableNames, {'Name', 'Age', 'City'});
            testCase.verifyEqual(meta.numHeaderLines, 1);
        end

        function testHeaderParserTabDelimitedAutoDelimiter(testCase)
            % This test relies on the auto-delimiter detection logic
            meta = headerParser(testCase.TestAssets.tabDelimited, 'NumHeaderLines', 1);
            testCase.verifyEqual(meta.delimiter, sprintf('\t'), 'Auto-detected delimiter incorrect for TSV.');
            testCase.verifyEqual(meta.variableNames, {'Name', 'Age', 'City'});
        end

        % --- ingestData Tests ---
        function testIngestNoHeader(testCase)
            ds = ingestData(testCase.TestAssets.noHeader); % Output should be tall by default
            testCase.verifyClass(ds, 'tall');
            tbl = gather(head(ds, 5));
            testCase.verifySize(tbl, [5, 3], 'Incorrect table size from ingested noHeader.csv');
            testCase.verifyEqual(ds.Properties.VariableNames, {'Var1', 'Var2', 'Var3'}, 'Default variable names incorrect.');
            testCase.verifyEqual(tbl.Var1(1), 1, 'Data mismatch.');
            testCase.verifyEqual(tbl.Var3{2}, 'B', 'Data mismatch.'); % String data
            testCase.verifyTrue(ismissing(tbl.Var2(6-5+1)), 'NaN not parsed correctly from noHeader.csv line 6'); % row 6 in file is row 2 in preview of 5
        end

        function testIngestOneLineHeader(testCase)
            ds = ingestData(testCase.TestAssets.oneLineNames, 'NumHeaderLines', 1);
            testCase.verifyClass(ds, 'tall');
            testCase.verifyEqual(ds.Properties.VariableNames, {'ID', 'Value', 'Category'}, 'Variable names not read correctly.');
            tbl = gather(head(ds, 3));
            testCase.verifyEqual(tbl.ID(1), 1);
            testCase.verifyEqual(tbl.Value(2), 105.9);
        end

        function testIngestTwoLineHeader(testCase)
            ds = ingestData(testCase.TestAssets.twoLineNamesUnits, 'NumHeaderLines', 2);
            testCase.verifyClass(ds, 'tall');
            testCase.verifyEqual(ds.Properties.VariableNames, {'Time', 'Temperature', 'Pressure', 'Status'});
            % Check units if they are stored in UserData by ingestData
            if isprop(ds.UnderlyingDatastores{1}, 'UserData') && isfield(ds.UnderlyingDatastores{1}.UserData, 'headerParserMeta')
                 meta = ds.UnderlyingDatastores{1}.UserData.headerParserMeta;
                 testCase.verifyEqual(meta.variableUnits, {'s', 'degC', 'kPa', 'flag'});
                 % Also check if tall array got units (if ingestData sets them)
                 if ~isempty(ds.Properties.VariableUnits)
                    testCase.verifyEqual(ds.Properties.VariableUnits, {'s', 'degC', 'kPa', 'flag'});
                 end
            else
                warning('TestDataImport:UnitsNotStored', 'Units not found in UserData for twoLineNamesUnits test.');
            end
            tbl = gather(head(ds,3));
            testCase.verifyEqual(tbl.Temperature(2), 25.3);
        end

        function testIngestWithUnitsProvided(testCase)
            customUnits = {'seconds', 'Celsius', 'Pascals', 'Mode'};
            ds = ingestData(testCase.TestAssets.twoLineNamesUnits, ...
                            'NumHeaderLines', 2, 'VariableUnits', customUnits);
            testCase.verifyClass(ds, 'tall');
            testCase.verifyEqual(ds.Properties.VariableNames, {'Time', 'Temperature', 'Pressure', 'Status'});
            if isprop(ds.UnderlyingDatastores{1}, 'UserData') && isfield(ds.UnderlyingDatastores{1}.UserData, 'headerParserMeta')
                 meta = ds.UnderlyingDatastores{1}.UserData.headerParserMeta;
                 testCase.verifyEqual(meta.variableUnits, customUnits, 'Provided units not stored correctly.');
                 if ~isempty(ds.Properties.VariableUnits)
                    testCase.verifyEqual(ds.Properties.VariableUnits, customUnits, 'Provided units not set on tall array.');
                 end
            end
        end

        function testIngestTabDelimited(testCase)
            ds = ingestData(testCase.TestAssets.tabDelimited, 'Delimiter', sprintf('\t'), 'NumHeaderLines', 1);
            testCase.verifyClass(ds, 'tall');
            testCase.verifyEqual(ds.Properties.VariableNames, {'Name', 'Age', 'City'});
            tbl = gather(head(ds,2));
            testCase.verifyEqual(tbl.Name{1}, 'Alice');
            testCase.verifyEqual(tbl.Age(2), 24);
        end

        function testIngestSelectedVariables(testCase)
            ds = ingestData(testCase.TestAssets.twoLineNamesUnits, ...
                'NumHeaderLines', 2, 'SelectedVariableNames', {'Time', 'Pressure'});
            testCase.verifyClass(ds, 'tall');
            testCase.verifyEqual(ds.Properties.VariableNames, {'Time', 'Pressure'});
            tbl = gather(head(ds,1));
            testCase.verifyEqual(tbl.Time(1), 0.0);
            testCase.verifyEqual(tbl.Pressure(1), 101.2);
        end

        function testIngestNumHeaderLinesOverride(testCase)
            % oneLineNames.csv has 1 header. Tell ingestData it has 0.
            ds = ingestData(testCase.TestAssets.oneLineNames, 'NumHeaderLines', 0);
            testCase.verifyClass(ds, 'tall');
            % Expects Var1, Var2, Var3, and first row of data to be the actual header
            tbl = gather(head(ds,1));
            testCase.verifyEqual(ds.Properties.VariableNames, {'Var1', 'Var2', 'Var3'});
            testCase.verifyEqual(tbl.Var1{1}, 'ID'); % Header ingested as data
        end

        function testIngestEmptyFile(testCase)
            ds = ingestData(testCase.TestAssets.emptyFile);
            testCase.verifyClass(ds, 'tall'); % Should still produce a tall structure
            testCase.verifyTrue(isempty(gather(ds)), 'Gathered result of empty file should be empty.');
        end

        function testIngestOutputTypeDatastore(testCase)
            ds = ingestData(testCase.TestAssets.noHeader, 'OutputType', 'datastore');
            testCase.verifyClass(ds, 'matlab.io.datastore.TabularTextDatastore'); % Or appropriate datastore class
            % Basic check that preview works
            prv = preview(ds);
            testCase.verifySize(prv, [8,3], 'Preview size incorrect for datastore.'); % datastore preview default is 8 rows
        end

        % --- previewData Tests ---
        function testPreviewHeadTall(testCase)
            ds = ingestData(testCase.TestAssets.noHeader); % tall array
            tbl = previewData(ds, 'N', 5);
            testCase.verifyClass(tbl, 'table');
            testCase.verifySize(tbl, [5, 3]);
            testCase.verifyEqual(tbl.Var1(1), 1);
        end

        function testPreviewHeadDatastore(testCase)
            ds = ingestData(testCase.TestAssets.noHeader, 'OutputType', 'datastore');
            tbl = previewData(ds, 'N', 3); % Preview fewer than default datastore preview
            testCase.verifyClass(tbl, 'table');
            testCase.verifySize(tbl, [3, 3]);
            testCase.verifyEqual(tbl.Var1(1), 1);
        end

        function testPreviewSparseDatastore(testCase)
            ds = ingestData(testCase.TestAssets.noHeader, 'OutputType', 'datastore');
            % noHeader.csv has 15 lines of data. Step 5 should give 1,6,11. (3 rows)
            tbl = previewData(ds, 'Mode', 'sparse', 'Step', 5);
            testCase.verifyClass(tbl, 'table');
            testCase.verifySize(tbl, [3, 3]);
            testCase.verifyEqual(tbl.Var1(1), 1); % First row
            testCase.verifyEqual(tbl.Var1(2), 6); % 6th row (1-based index in file)
            testCase.verifyEqual(tbl.Var1(3), 11);% 11th row
        end

        function testPreviewSparseTall(testCase)
            ds = ingestData(testCase.TestAssets.noHeader); % tall array
            % noHeader.csv has 15 lines of data. Step 5 should give 1,6,11. (3 rows)
            testCase.assertWarning(@() previewData(ds, 'Mode', 'sparse', 'Step', 5), 'previewData:SparseTallWarning');
            tbl = previewData(ds, 'Mode', 'sparse', 'Step', 5); % Suppress warning for execution
            testCase.verifyClass(tbl, 'table');
            testCase.verifySize(tbl, [3, 3]);
            testCase.verifyEqual(tbl.Var1(1), 1);
            testCase.verifyEqual(tbl.Var1(2), 6);
            testCase.verifyEqual(tbl.Var1(3), 11);
        end

        function testPreviewWithUnitsPropagation(testCase)
            % ingestData should store units in UserData, previewData should try to use them
            ds = ingestData(testCase.TestAssets.twoLineNamesUnits, 'NumHeaderLines', 2); % tall array
            tblPreview = previewData(ds, 'N', 3);
            expectedUnits = {'s', 'degC', 'kPa', 'flag'};
            testCase.verifyEqual(tblPreview.Properties.VariableUnits, expectedUnits, ...
                'VariableUnits not propagated correctly to previewed table.');
        end

        function testIngestMalformedFile(testCase)
            % malformed.csv has uneven rows. Datastore should handle this by padding with missing
            % or as per its 'TreatAsMissing' and error handling settings.
            % This test checks if it ingests without fatal error and what the structure looks like.
            ds = ingestData(testCase.TestAssets.malformed, 'NumHeaderLines', 1); % Header1,Header2,Header3
            testCase.verifyClass(ds, 'tall');

            % Default behavior of TabularTextDatastore for uneven lines is to error
            % or fill with missing if 'TreatAsMissing' and types allow.
            % Let's see what gather(head(...)) does. It might error.
            % We need to ensure ingestData sets up datastore to be somewhat robust.
            % The 'MissingRule' property of datastore is key here.
            % Default 'MissingRule' is 'error'. Let's assume ingestData might need to set it
            % to 'fill' or 'omitrow' for robustness, or users handle it via datastore properties.
            % For now, let's test if it can read the "good" parts.

            % The current ingestData doesn't explicitly set MissingRule.
            % Let's try to gather and see. This might error.
            try
                tbl = gather(head(ds, 5)); % Attempt to read a few lines
                % If it reaches here, it means datastore handled it.
                % malformed.csv:
                % Header1,Header2,Header3
                % 1,val1,100
                % 2,val2,200,extra_col  -> datastore might read 3 vars, ignore extra, or error
                % 3,val3                 -> datastore might fill 3rd with NaN/missing
                % 4,,400
                % 5,val5,500

                testCase.verifyEqual(ds.Properties.VariableNames, {'Header1','Header2','Header3'});
                testCase.verifySize(tbl, [5,3]); % Expecting 5 rows, 3 columns based on header

                % Check first valid row
                testCase.verifyEqual(tbl.Header1(1), 1);
                testCase.verifyEqual(tbl.Header2{1}, 'val1');
                testCase.verifyEqual(tbl.Header3(1), 100);

                % Check row that was short (row 3 in data, index 3 in tbl)
                testCase.verifyEqual(tbl.Header1(3), 3);
                testCase.verifyEqual(tbl.Header2{3}, 'val3');
                testCase.verifyTrue(ismissing(tbl.Header3(3)), 'Short row should have missing for Header3.');

                % Check row with missing middle (row 4 in data, index 4 in tbl)
                testCase.verifyEqual(tbl.Header1(4), 4);
                testCase.verifyTrue(ismissing(tbl.Header2(4)), 'Missing middle value not parsed as missing.');
                testCase.verifyEqual(tbl.Header3(4), 400);

            catch ME
                % If datastore errors due to malformed lines (e.g. extra columns if not handled)
                % this catch block will be executed. This indicates a need for more robust
                % datastore setup in ingestData for such files (e.g., 'MissingRule', 'VariableTypes').
                testCase. azioniFail(sprintf('Ingesting malformed.csv failed: %s. Consider robust datastore settings in ingestData.', ME.message));
            end
        end

    end % methods (Test)
end % classdef
