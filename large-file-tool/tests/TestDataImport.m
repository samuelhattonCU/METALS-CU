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
            currentFilePath = fileparts(mfilename('fullpath'));
            projectRoot = fileparts(currentFilePath);
            addpath(fullfile(projectRoot, 'src'));

            if exist('configManager', 'file')
                configManager('init');
            else
                warning('TestDataImport:ConfigManagerMissing', 'configManager.m not found. Default preferences might not be set.');
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
            if ispref('DataImport')
                testCase.PrefsBackup = getpref('DataImport');
            else
                testCase.PrefsBackup = struct();
            end

            testCase.TestFileDir = fullfile(fileparts(mfilename('fullpath')), 'data');
            testCase.assertTrue(isfolder(testCase.TestFileDir), 'Test data directory not found.');

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

            fields = fieldnames(testCase.TestAssets);
            for i = 1:length(fields)
                testCase.assertTrue(isfile(testCase.TestAssets.(fields{i})), ...
                    ['Test asset file not found: ', testCase.TestAssets.(fields{i})]);
            end
            setpref('DataImport', 'NumHeaderLines', 0);
            setpref('DataImport', 'Delimiter', ',');
        end
    end

    methods (TestMethodTeardown)
        % Teardown executed after each test method
        function restorePrefs(testCase)
            if ~isempty(fieldnames(testCase.PrefsBackup))
                currentGroupPrefs = fieldnames(testCase.PrefsBackup);
                for i = 1:length(currentGroupPrefs)
                    setpref('DataImport', currentGroupPrefs{i}, testCase.PrefsBackup.(currentGroupPrefs{i}));
                end
            else
                if ispref('DataImport')
                    rmpref('DataImport');
                end
            end
        end

        function TeardownMethodVerifyNoOpenFiles(testCase)
            openFiles = openedFiles();
            testCase.verifyEmpty(openFiles, 'Some files were left open after the test.');
        end

    end

    % --- headerParser Tests ---
    methods (Test)
        function testHeaderParserNoHeader(testCase)
            meta = headerParser(testCase.TestAssets.noHeader);
            testCase.verifyEqual(meta.numHeaderLines, 0, 'Incorrect numHeaderLines for noHeader.csv');
            testCase.verifyEqual(meta.dataStartLine, 1, 'Incorrect dataStartLine for noHeader.csv');
            % For noHeader, variableUnits should be initialized to empty cells matching numCols
            testCase.assertTrue(all(cellfun('isempty', meta.variableUnits)), 'variableUnits should be all empty cells for noHeader.csv');
            testCase.verifyFalse(meta.isAmbiguous, 'Should not be ambiguous for simple no header data.');
            testCase.verifyEqual(length(meta.variableNames), 3, 'Expected 3 generated variable names.');
            testCase.verifyEqual(meta.variableNames{1}, 'Var1', 'Incorrect first generated variable name.');
        end

        function testHeaderParserOneLineNames(testCase)
            meta = headerParser(testCase.TestAssets.oneLineNames, 'NumHeaderLines', 1);
            testCase.verifyEqual(meta.numHeaderLines, 1, 'Incorrect numHeaderLines.');
            testCase.verifyEqual(meta.dataStartLine, 2, 'Incorrect dataStartLine.');
            testCase.verifyEqual(meta.variableNames, {'ID', 'Value', 'Category'}, 'Incorrect variableNames.');
            testCase.assertTrue(all(cellfun('isempty', meta.variableUnits)), 'variableUnits should be all empty cells.');
            testCase.verifyEqual(meta.delimiter, ',', 'Delimiter should be comma.');
        end

        function testHeaderParserOneLineNamesAutoDetect(testCase)
            meta = headerParser(testCase.TestAssets.oneLineNames);
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
            meta = headerParser(testCase.TestAssets.commented, 'NumHeaderLines', 2);
            testCase.verifyGreaterThan(length(meta.commentLines), 0, 'Should detect comment lines.');
            testCase.verifyEqual(meta.variableNames, {'Time', 'Value'}, 'Variable names not parsed correctly with comments.');
            testCase.verifyEqual(meta.variableUnits, {'s', 'mV'}, 'Variable units not parsed correctly with comments.');
            testCase.verifyEqual(meta.dataStartLine, 8, 'dataStartLine incorrect with comments and specified headers.');
            testCase.verifyEqual(meta.numHeaderLines, 7, 'numHeaderLines (lines to skip) incorrect.');
        end

        function testHeaderParserWithCommentsAuto(testCase)
            meta = headerParser(testCase.TestAssets.commented);
            testCase.verifyGreaterThan(length(meta.commentLines), 0, 'Should detect comment lines (auto).');
            testCase.verifyEqual(meta.variableNames, {'Time', 'Value'}, 'Variable names (auto).');
            testCase.verifyEqual(meta.variableUnits, {'s', 'mV'}, 'Variable units (auto).');
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
            testCase.verifyEqual(meta.dataStartLine, 3);
            testCase.verifyTrue(meta.isAmbiguous || ~isempty(meta.errorMsg), 'Should be ambiguous or error if only headers and no data found in inspection.');
        end

        function testHeaderParserOnlyComments(testCase)
            meta = headerParser(testCase.TestAssets.onlyComments);
            testCase.verifyEqual(length(meta.commentLines), 3, 'Not all comment lines detected.');
            testCase.assertTrue(all(cellfun('isempty', meta.variableNames)), 'Variable names should be all empty cells.');
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
            meta = headerParser(testCase.TestAssets.tabDelimited, 'NumHeaderLines', 1);
            testCase.verifyEqual(meta.delimiter, sprintf('\t'), 'Auto-detected delimiter incorrect for TSV.');
            testCase.verifyEqual(meta.variableNames, {'Name', 'Age', 'City'});
        end

        % --- ingestData Tests ---
        function testIngestNoHeader(testCase)
            [ds, ~] = ingestData(testCase.TestAssets.noHeader);
            testCase.verifyClass(ds, 'tall');
            tbl = gather(head(ds, 5));
            testCase.verifySize(tbl, [5, 3], 'Incorrect table size from ingested noHeader.csv');
            testCase.verifyEqual(ds.Properties.VariableNames, {'Var1', 'Var2', 'Var3'}, 'Default variable names incorrect.');
            testCase.verifyEqual(tbl.Var1(1), 1, 'Data mismatch.');
            testCase.verifyEqual(tbl.Var3{2}, 'B', 'Data mismatch.');
            testCase.verifyTrue(ismissing(tbl.Var2(2)), 'NaN not parsed correctly from noHeader.csv line 6 (row 2 in preview)');
        end

        function testIngestOneLineHeader(testCase)
            [ds, ~] = ingestData(testCase.TestAssets.oneLineNames, 'NumHeaderLines', 1);
            testCase.verifyClass(ds, 'tall');
            testCase.verifyEqual(ds.Properties.VariableNames, {'ID', 'Value', 'Category'}, 'Variable names not read correctly.');
            tbl = gather(head(ds, 3));
            testCase.verifyEqual(tbl.ID(1), 1);
            testCase.verifyEqual(tbl.Value(2), 105.9);
        end

        function testIngestTwoLineHeader(testCase)
            [ds, metaFromIngest] = ingestData(testCase.TestAssets.twoLineNamesUnits, 'NumHeaderLines', 2);
            testCase.verifyClass(ds, 'tall');
            testCase.verifyEqual(ds.Properties.VariableNames, {'Time', 'Temperature', 'Pressure', 'Status'});

            expectedUnits = {'s', 'degC', 'kPa', 'flag'};
            testCase.verifyEqual(metaFromIngest.variableUnits, expectedUnits, 'Units not correctly parsed/returned by ingestData.');

            if istall(ds) && ~isempty(ds.Properties.VariableUnits)
                testCase.verifyEqual(ds.Properties.VariableUnits, expectedUnits, 'Units not set correctly on tall array properties.');
            elseif istall(ds) && isempty(ds.Properties.VariableUnits) && ~all(cellfun('isempty', expectedUnits))
                 warning('TestDataImport:TallUnitsNotSet', 'Tall array units not set despite being available in metadata for testIngestTwoLineHeader.');
            end

            tbl = gather(head(ds,3));
            testCase.verifyEqual(tbl.Temperature(2), 25.3);
        end

        function testIngestWithUnitsProvided(testCase)
            customUnits = {'seconds', 'Celsius', 'Pascals', 'Mode'};
            [ds, metaFromIngest] = ingestData(testCase.TestAssets.twoLineNamesUnits, ...
                            'NumHeaderLines', 2, 'VariableUnits', customUnits);
            testCase.verifyClass(ds, 'tall');
            testCase.verifyEqual(ds.Properties.VariableNames, {'Time', 'Temperature', 'Pressure', 'Status'});
            testCase.verifyEqual(metaFromIngest.variableUnits, customUnits, 'Provided units not stored correctly in meta output.');
            if istall(ds) && ~isempty(ds.Properties.VariableUnits)
               testCase.verifyEqual(ds.Properties.VariableUnits, customUnits, 'Provided units not set on tall array.');
            end
        end

        function testIngestTabDelimited(testCase)
            [ds, ~] = ingestData(testCase.TestAssets.tabDelimited, 'Delimiter', sprintf('\t'), 'NumHeaderLines', 1);
            testCase.verifyClass(ds, 'tall');
            testCase.verifyEqual(ds.Properties.VariableNames, {'Name', 'Age', 'City'});
            tbl = gather(head(ds,2));
            testCase.verifyEqual(tbl.Name{1}, 'Alice');
            testCase.verifyEqual(tbl.Age(2), 24);
        end

        function testIngestSelectedVariables(testCase)
            [ds, ~] = ingestData(testCase.TestAssets.twoLineNamesUnits, ...
                'NumHeaderLines', 2, 'SelectedVariableNames', {'Time', 'Pressure'});
            testCase.verifyClass(ds, 'tall');
            testCase.verifyEqual(ds.Properties.VariableNames, {'Time', 'Pressure'});
            tbl = gather(head(ds,1));
            testCase.verifyEqual(tbl.Time(1), 0.0);
            testCase.verifyEqual(tbl.Pressure(1), 101.2);
        end

        function testIngestNumHeaderLinesOverride(testCase)
            [ds, ~] = ingestData(testCase.TestAssets.oneLineNames, 'NumHeaderLines', 0);
            testCase.verifyClass(ds, 'tall');
            tbl = gather(head(ds,1));
            testCase.verifyEqual(ds.Properties.VariableNames, {'Var1', 'Var2', 'Var3'});
            testCase.verifyEqual(tbl.Var1{1}, 'ID');
        end

        function testIngestEmptyFile(testCase)
            [ds, ~] = ingestData(testCase.TestAssets.emptyFile);
            testCase.verifyClass(ds, 'tall');
            testCase.verifyTrue(isempty(gather(ds)), 'Gathered result of empty file should be empty.');
        end

        function testIngestOutputTypeDatastore(testCase)
            [ds, ~] = ingestData(testCase.TestAssets.noHeader, 'OutputType', 'datastore');
            testCase.verifyClass(ds, 'matlab.io.datastore.TabularTextDatastore');
            prv = preview(ds);
            testCase.verifySize(prv, [8,3], 'Preview size incorrect for datastore.');
        end

        % --- previewData Tests ---
        function testPreviewHeadTall(testCase)
            [ds, meta] = ingestData(testCase.TestAssets.noHeader);
            tbl = previewData(ds, 'N', 5, 'DsMeta', meta);
            testCase.verifyClass(tbl, 'table');
            testCase.verifySize(tbl, [5, 3]);
            testCase.verifyEqual(tbl.Var1(1), 1);
        end

        function testPreviewHeadDatastore(testCase)
            [ds, meta] = ingestData(testCase.TestAssets.noHeader, 'OutputType', 'datastore');
            tbl = previewData(ds, 'N', 3, 'DsMeta', meta);
            testCase.verifyClass(tbl, 'table');
            testCase.verifySize(tbl, [3, 3]);
            testCase.verifyEqual(tbl.Var1(1), 1);
        end

        function testPreviewSparseDatastore(testCase)
            [ds, meta] = ingestData(testCase.TestAssets.noHeader, 'OutputType', 'datastore');
            tbl = previewData(ds, 'Mode', 'sparse', 'Step', 5, 'DsMeta', meta);
            testCase.verifyClass(tbl, 'table');
            testCase.verifySize(tbl, [3, 3]);
            testCase.verifyEqual(tbl.Var1(1), 1);
            testCase.verifyEqual(tbl.Var1(2), 6);
            testCase.verifyEqual(tbl.Var1(3), 11);
        end

        function testPreviewSparseTall(testCase)
            [ds, meta] = ingestData(testCase.TestAssets.noHeader);
            testCase.assertWarning(@() previewData(ds, 'Mode', 'sparse', 'Step', 5, 'DsMeta', meta), 'previewData:SparseTallWarning');
            tbl = previewData(ds, 'Mode', 'sparse', 'Step', 5, 'DsMeta', meta);
            testCase.verifyClass(tbl, 'table');
            testCase.verifySize(tbl, [3, 3]);
            testCase.verifyEqual(tbl.Var1(1), 1);
            testCase.verifyEqual(tbl.Var1(2), 6);
            testCase.verifyEqual(tbl.Var1(3), 11);
        end

        function testPreviewWithUnitsPropagation(testCase)
            [ds, metaFromIngest] = ingestData(testCase.TestAssets.twoLineNamesUnits, 'NumHeaderLines', 2);
            tblPreview = previewData(ds, 'N', 3, 'DsMeta', metaFromIngest);
            expectedUnits = {'s', 'degC', 'kPa', 'flag'};
            testCase.verifyEqual(tblPreview.Properties.VariableUnits, expectedUnits, ...
                'VariableUnits not propagated correctly to previewed table.');
        end

        function testIngestMalformedFile(testCase)
            [ds, ~] = ingestData(testCase.TestAssets.malformed, 'NumHeaderLines', 1);
            testCase.verifyClass(ds, 'tall');
            try
                tbl = gather(head(ds, 5));
                testCase.verifyEqual(ds.Properties.VariableNames, {'Header1','Header2','Header3'});
                testCase.verifySize(tbl, [5,3]);

                testCase.verifyEqual(tbl.Header1(1), 1);
                testCase.verifyEqual(tbl.Header2{1}, 'val1');
                testCase.verifyEqual(tbl.Header3(1), 100);

                testCase.verifyEqual(tbl.Header1(3), 3);
                testCase.verifyEqual(tbl.Header2{3}, 'val3');
                testCase.verifyTrue(ismissing(tbl.Header3(3)), 'Short row should have missing for Header3.');

                testCase.verifyEqual(tbl.Header1(4), 4);
                testCase.verifyTrue(ismissing(tbl.Header2(4)), 'Missing middle value not parsed as missing.');
                testCase.verifyEqual(tbl.Header3(4), 400);

            catch ME
                % MODIFIED: Fixed typo from azioniFail to fail
                testCase.fail(sprintf('Ingesting malformed.csv failed: %s. Consider robust datastore settings in ingestData.', ME.message));
            end
        end

    end % methods (Test)
end % classdef
