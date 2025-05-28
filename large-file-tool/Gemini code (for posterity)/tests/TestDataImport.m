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
                    setpref('DataImport', 'NumHeaderLines', 0); % For headerParser, 0 content headers, auto for comments
                end
                if ~ispref('DataImport') || ~ispref('DataImport','Delimiter')
                    setpref('DataImport', 'Delimiter', ',');
                end
                 if ~ispref('DataImport') || ~ispref('DataImport','PreviewHeadN')
                    setpref('DataImport', 'PreviewHeadN', 100);
                end
                 if ~ispref('DataImport') || ~ispref('DataImport','PreviewSparseStep')
                    setpref('DataImport', 'PreviewSparseStep', 1000);
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
            % Set specific defaults for tests, headerParser's NumHeaderLines is for *content* headers
            setpref('DataImport', 'NumHeaderLines', -1); % Default to auto-detect for headerParser
            setpref('DataImport', 'Delimiter', '');   % Default to auto-detect for headerParser
        end
    end

    methods (TestMethodTeardown)
        % Teardown executed after each test method
        function restorePrefs(testCase)
            if ~isempty(fieldnames(testCase.PrefsBackup))
                prefNames = fieldnames(testCase.PrefsBackup);
                for i = 1:length(prefNames)
                    setpref('DataImport', prefNames{i}, testCase.PrefsBackup.(prefNames{i}));
                end
            else % PrefsBackup was empty, meaning 'DataImport' group might not have existed
                if ispref('DataImport')
                    rmpref('DataImport'); % Remove the group if it was created during setup
                end
            end
        end

        function TeardownMethodVerifyNoOpenFiles(testCase)
            openFiles = fopen('all'); % Get all open file IDs
            testCase.verifyEmpty(openFiles, 'Some files were left open after the test.');
        end

    end

    % --- headerParser Tests ---
    methods (Test)
        function testHeaderParserNoHeader(testCase)
            meta = headerParser(testCase.TestAssets.noHeader);
            testCase.verifyEqual(meta.numContentHeaderLinesDetected, 0, 'Incorrect numContentHeaderLinesDetected for noHeader.csv');
            testCase.verifyEqual(meta.numHeaderLinesTotal, 0, 'Incorrect numHeaderLinesTotal for noHeader.csv');
            testCase.verifyEqual(meta.dataStartLine, 1, 'Incorrect dataStartLine for noHeader.csv');
            testCase.verifyEqual(length(meta.variableNames), 3, 'Expected 3 generated variable names.');
            testCase.verifyEqual(meta.variableNames, {'Var1', 'Var2', 'Var3'}, 'Incorrect generated variable names.');
            testCase.assertTrue(all(cellfun('isempty', meta.variableUnits)), 'variableUnits should be all empty cells for noHeader.csv');
            testCase.verifyFalse(meta.isAmbiguous, 'Should not be ambiguous for simple no header data.');
        end

        function testHeaderParserOneLineNames(testCase)
            % User specifies there is 1 content header line
            meta = headerParser(testCase.TestAssets.oneLineNames, 'NumHeaderLines', 1);
            testCase.verifyEqual(meta.numContentHeaderLinesDetected, 1, 'Incorrect numContentHeaderLinesDetected.');
            testCase.verifyEqual(meta.numHeaderLinesTotal, 1, 'Incorrect numHeaderLinesTotal.'); % Assumes no initial comments
            testCase.verifyEqual(meta.dataStartLine, 2, 'Incorrect dataStartLine.');
            testCase.verifyEqual(meta.variableNames, {'ID', 'Value', 'Category'}, 'Incorrect variableNames.');
            testCase.assertTrue(all(cellfun('isempty', meta.variableUnits)), 'variableUnits should be all empty cells.');
            testCase.verifyEqual(meta.delimiter, ',', 'Delimiter should be comma.');
        end

        function testHeaderParserOneLineNamesAutoDetect(testCase)
            % headerParser should auto-detect the 1 content header line
            meta = headerParser(testCase.TestAssets.oneLineNames); % NumHeaderLines = -1 (auto)
            testCase.verifyEqual(meta.numContentHeaderLinesDetected, 1, 'Auto-detected numContentHeaderLinesDetected incorrect.');
            testCase.verifyEqual(meta.numHeaderLinesTotal, 1, 'Auto-detected numHeaderLinesTotal incorrect.');
            testCase.verifyEqual(meta.dataStartLine, 2, 'Auto-detected dataStartLine incorrect.');
            testCase.verifyEqual(meta.variableNames, {'ID', 'Value', 'Category'}, 'Auto-detected variableNames incorrect.');
        end

        function testHeaderParserTwoLineNamesUnits(testCase)
            % User specifies 2 content header lines
            meta = headerParser(testCase.TestAssets.twoLineNamesUnits, 'NumHeaderLines', 2);
            testCase.verifyEqual(meta.numContentHeaderLinesDetected, 2);
            testCase.verifyEqual(meta.numHeaderLinesTotal, 2); % Assumes no initial comments
            testCase.verifyEqual(meta.dataStartLine, 3);
            testCase.verifyEqual(meta.variableNames, {'Time', 'Temperature', 'Pressure', 'Status'});
            testCase.verifyEqual(meta.variableUnits, {'s', 'degC', 'kPa', 'flag'});
        end

        function testHeaderParserWithComments(testCase)
            % User specifies 2 content header lines, file has comments before and between
            meta = headerParser(testCase.TestAssets.commented, 'NumHeaderLines', 2);
            testCase.verifyEqual(length(meta.commentLines), 5, 'Should detect 5 comment lines.');
            testCase.verifyEqual(meta.numContentHeaderLinesDetected, 2, 'Incorrect numContentHeaderLinesDetected.');
            testCase.verifyEqual(meta.variableNames, {'Time', 'Value'}, 'Variable names not parsed correctly.');
            testCase.verifyEqual(meta.variableUnits, {'s', 'mV'}, 'Variable units not parsed correctly.');
            % Comments: #, %, #, #, % (5 lines)
            % Headers: Time,Value (1st content), s,mV (2nd content)
            % Total lines before data: 5 (comments) + 2 (content) = 7
            testCase.verifyEqual(meta.numHeaderLinesTotal, 7, 'numHeaderLinesTotal incorrect.');
            testCase.verifyEqual(meta.dataStartLine, 8, 'dataStartLine incorrect.');
        end

        function testHeaderParserWithCommentsAuto(testCase)
            % Auto-detect content headers
            meta = headerParser(testCase.TestAssets.commented);
            testCase.verifyEqual(length(meta.commentLines), 5, 'Should detect 5 comment lines (auto).');
            testCase.verifyEqual(meta.numContentHeaderLinesDetected, 2, 'numContentHeaderLinesDetected (auto).');
            testCase.verifyEqual(meta.variableNames, {'Time', 'Value'}, 'Variable names (auto).');
            testCase.verifyEqual(meta.variableUnits, {'s', 'mV'}, 'Variable units (auto).');
            testCase.verifyEqual(meta.numHeaderLinesTotal, 7, 'numHeaderLinesTotal (auto) incorrect.');
            testCase.verifyEqual(meta.dataStartLine, 8, 'dataStartLine incorrect with comments (auto).');
        end

        function testHeaderParserEmptyFile(testCase)
            meta = headerParser(testCase.TestAssets.emptyFile);
            testCase.verifyEqual(meta.errorMsg, 'File is empty.', 'Error message should be set for empty file.');
            testCase.verifyEqual(meta.dataStartLine, 1, 'dataStartLine should be 1 for empty file default.');
            testCase.verifyEqual(meta.numHeaderLinesTotal, 0);
        end

        function testHeaderParserOnlyHeaders(testCase)
            % User specifies 2 content header lines
            meta = headerParser(testCase.TestAssets.onlyHeaders, 'NumHeaderLines', 2);
            testCase.verifyEqual(meta.variableNames, {'Name', 'Unit', 'Description'});
            testCase.verifyEqual(meta.numContentHeaderLinesDetected, 2);
            testCase.verifyEqual(meta.numHeaderLinesTotal, 2);
            testCase.verifyEqual(meta.dataStartLine, 3, 'Data should start after headers, even if no data lines exist in file.');
            testCase.verifyTrue(meta.isAmbiguous, 'Should be ambiguous if only headers and no data found in inspection.');
            testCase.verifyContains(meta.errorMsg, 'No data lines found', 'Error message missing expected text for only-headers file.');
        end

        function testHeaderParserOnlyComments(testCase)
            meta = headerParser(testCase.TestAssets.onlyComments); % Auto-detect
            testCase.verifyEqual(length(meta.commentLines), 3, 'Not all comment lines detected.');
            testCase.verifyTrue(all(cellfun('isempty', meta.variableNames)), 'Variable names should be empty.');
            testCase.verifyEqual(meta.numContentHeaderLinesDetected, 0);
            testCase.verifyEqual(meta.numHeaderLinesTotal, 3, 'numHeaderLinesTotal should be count of comment lines.');
            testCase.verifyEqual(meta.dataStartLine, 4, 'dataStartLine should be after all comments.');
            testCase.verifyTrue(meta.isAmbiguous, 'Should be ambiguous if only comments.');
             testCase.verifyContains(meta.errorMsg, 'File contains only comment lines', 'Error message missing expected text for only-comments file.');
        end

        function testHeaderParserTabDelimited(testCase)
            % User specifies delimiter and 1 content header line
            meta = headerParser(testCase.TestAssets.tabDelimited, 'Delimiter', sprintf('\t'), 'NumHeaderLines', 1);
            testCase.verifyEqual(meta.delimiter, sprintf('\t'));
            testCase.verifyEqual(meta.variableNames, {'Name', 'Age', 'City'});
            testCase.verifyEqual(meta.numContentHeaderLinesDetected, 1);
            testCase.verifyEqual(meta.numHeaderLinesTotal, 1); % Assumes no initial comments
            testCase.verifyEqual(meta.dataStartLine, 2);
        end

        function testHeaderParserTabDelimitedAutoDelimiter(testCase)
            % Auto-detect delimiter, user specifies 1 content header line
            meta = headerParser(testCase.TestAssets.tabDelimited, 'NumHeaderLines', 1);
            testCase.verifyEqual(meta.delimiter, sprintf('\t'), 'Auto-detected delimiter incorrect for TSV.');
            testCase.verifyEqual(meta.variableNames, {'Name', 'Age', 'City'});
            testCase.verifyEqual(meta.numContentHeaderLinesDetected, 1);
        end

        % --- ingestData Tests ---
        function testIngestNoHeader(testCase)
            [ds, dsMeta] = ingestData(testCase.TestAssets.noHeader); % Uses auto-detection from headerParser
            testCase.verifyClass(ds, 'tall');
            testCase.verifyEqual(dsMeta.variableNames, {'Var1', 'Var2', 'Var3'}, 'Default variable names in meta incorrect.');
            testCase.verifyEqual(ds.Properties.VariableNames, {'Var1', 'Var2', 'Var3'}, 'Default variable names on tall array incorrect.');

            tbl = gather(head(ds, 6)); % Read enough to get the NaN
            testCase.verifySize(tbl, [6, 3], 'Incorrect table size from ingested noHeader.csv');
            testCase.verifyEqual(tbl.Var1(1), 1, 'Data mismatch.');
            testCase.verifyEqual(tbl.Var3{2}, 'B', 'Data mismatch.');
            testCase.verifyTrue(ismissing(tbl.Var2(6)), 'NaN not parsed correctly from noHeader.csv line 6');
        end

        function testIngestOneLineHeader(testCase)
            % ingestData will call headerParser with NumHeaderLines=1 (user specified)
            [ds, dsMeta] = ingestData(testCase.TestAssets.oneLineNames, 'NumHeaderLines', 1);
            testCase.verifyClass(ds, 'tall');
            testCase.verifyEqual(dsMeta.variableNames, {'ID', 'Value', 'Category'}, 'Variable names in meta incorrect.');
            testCase.verifyEqual(ds.Properties.VariableNames, {'ID', 'Value', 'Category'}, 'Variable names on tall array not read correctly.');
            tbl = gather(head(ds, 3));
            testCase.verifyEqual(tbl.ID(1), 1);
            testCase.verifyEqual(tbl.Value(2), 105.9);
        end

        function testIngestTwoLineHeader(testCase)
            [ds, dsMeta] = ingestData(testCase.TestAssets.twoLineNamesUnits, 'NumHeaderLines', 2);
            testCase.verifyClass(ds, 'tall');
            expectedNames = {'Time', 'Temperature', 'Pressure', 'Status'};
            expectedUnits = {'s', 'degC', 'kPa', 'flag'};
            testCase.verifyEqual(dsMeta.variableNames, expectedNames);
            testCase.verifyEqual(dsMeta.variableUnits, expectedUnits);
            testCase.verifyEqual(ds.Properties.VariableNames, expectedNames);
            if ~isempty(ds.Properties.VariableUnits) % VariableUnits might not be set if all empty
                 testCase.verifyEqual(ds.Properties.VariableUnits, expectedUnits);
            end
            tbl = gather(head(ds,3));
            testCase.verifyEqual(tbl.Temperature(2), 25.3);
        end

        function testIngestWithUnitsProvidedByUser(testCase)
            customUnits = {'seconds', 'Celsius', 'Pascals', 'Mode'};
            [ds, dsMeta] = ingestData(testCase.TestAssets.twoLineNamesUnits, ...
                            'NumHeaderLines', 2, 'VariableUnits', customUnits);
            testCase.verifyClass(ds, 'tall');
            testCase.verifyEqual(ds.Properties.VariableNames, {'Time', 'Temperature', 'Pressure', 'Status'});
            testCase.verifyEqual(dsMeta.variableUnits, customUnits, 'Provided units not stored correctly in meta output.');
            if istall(ds) && ~isempty(ds.Properties.VariableUnits)
               testCase.verifyEqual(ds.Properties.VariableUnits, customUnits, 'Provided units not set on tall array.');
            end
        end

        function testIngestTabDelimited(testCase)
            % User specifies delimiter and NumHeaderLines for ingestData
            [ds, dsMeta] = ingestData(testCase.TestAssets.tabDelimited, 'Delimiter', sprintf('\t'), 'NumHeaderLines', 1);
            testCase.verifyClass(ds, 'tall');
            testCase.verifyEqual(dsMeta.delimiter, sprintf('\t'));
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
            % User tells ingestData there are NO content headers, overriding file content
            [ds, dsMeta] = ingestData(testCase.TestAssets.oneLineNames, 'NumHeaderLines', 0);
            testCase.verifyClass(ds, 'tall');
            testCase.verifyEqual(dsMeta.variableNames, {'Var1', 'Var2', 'Var3'}); % Expect generated names
            testCase.verifyEqual(ds.Properties.VariableNames, {'Var1', 'Var2', 'Var3'});
            tbl = gather(head(ds,1));
            % First data row will be the original header line
            testCase.verifyEqual(tbl.Var1{1}, 'ID');
        end

        function testIngestEmptyFile(testCase)
            [ds, dsMeta] = ingestData(testCase.TestAssets.emptyFile);
            testCase.verifyClass(ds, 'tall'); % Should be an empty tall table
            testCase.verifyTrue(isempty(gather(ds)), 'Gathered result of empty file should be empty.');
            testCase.verifyEqual(dsMeta.errorMsg, 'File is empty.');
        end

        function testIngestOutputTypeDatastore(testCase)
            [ds, ~] = ingestData(testCase.TestAssets.noHeader, 'OutputType', 'datastore');
            testCase.verifyClass(ds, 'matlab.io.datastore.TabularTextDatastore');
            prv = preview(ds); % Default preview for datastore
            % Size of preview depends on datastore's default, often 8 rows.
            testCase.verifyGreaterThanOrEqual(height(prv), 1, 'Preview should not be empty for non-empty file.');
            testCase.verifyEqual(width(prv), 3, 'Preview width incorrect for datastore.');
        end

        function testIngestMalformedFile(testCase)
            % This test expects ingestData to handle malformed CSVs gracefully,
            % typically by filling missing/extra cells with NaNs or default values.
            % The exact behavior depends on datastore's robustness.
            [ds, dsMeta] = ingestData(testCase.TestAssets.malformed, 'NumHeaderLines', 1);
            testCase.verifyClass(ds, 'tall');
            testCase.verifyEqual(ds.Properties.VariableNames, {'Header1','Header2','Header3'});

            try
                tbl = gather(head(ds, 5)); % Gather enough rows to see issues
                testCase.verifySize(tbl, [5,3]); % Expect 5 rows, 3 recognized columns

                % Line 1: 1,val1,100
                testCase.verifyEqual(tbl.Header1(1), 1);
                testCase.verifyEqual(tbl.Header2{1}, 'val1');
                testCase.verifyEqual(tbl.Header3(1), 100);

                % Line 2: 2,val2,200,extra_col (extra_col should be ignored by datastore based on header count)
                testCase.verifyEqual(tbl.Header1(2), 2);
                testCase.verifyEqual(tbl.Header2{2}, 'val2');
                testCase.verifyEqual(tbl.Header3(2), 200);

                % Line 3: 3,val3 (short row, Header3 should be missing)
                testCase.verifyEqual(tbl.Header1(3), 3);
                testCase.verifyEqual(tbl.Header2{3}, 'val3');
                testCase.verifyTrue(ismissing(tbl.Header3(3)), 'Short row should have missing for Header3.');

                % Line 4: 4,,400 (missing middle value)
                testCase.verifyEqual(tbl.Header1(4), 4);
                testCase.verifyTrue(ismissing(tbl.Header2(4)), 'Missing middle value not parsed as missing.');
                testCase.verifyEqual(tbl.Header3(4), 400);

                % Line 5: 5,val5,500
                testCase.verifyEqual(tbl.Header1(5), 5);
                testCase.verifyEqual(tbl.Header2{5}, 'val5');
                testCase.verifyEqual(tbl.Header3(5), 500);

            catch ME
                testCase.fail(sprintf('Processing malformed.csv failed: %s. Datastore might need different error handling settings.', ME.message));
            end
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
            [ds_store, meta] = ingestData(testCase.TestAssets.noHeader, 'OutputType', 'datastore');
            tbl = previewData(ds_store, 'N', 3, 'DsMeta', meta);
            testCase.verifyClass(tbl, 'table');
            testCase.verifySize(tbl, [3, 3]);
            testCase.verifyEqual(tbl.Var1(1), 1);
        end

        function testPreviewSparseDatastore(testCase)
            [ds_store, meta] = ingestData(testCase.TestAssets.noHeader, 'OutputType', 'datastore');
            tbl = previewData(ds_store, 'Mode', 'sparse', 'Step', 5, 'DsMeta', meta);
            testCase.verifyClass(tbl, 'table');
            testCase.verifySize(tbl, [3, 3]); % 1, 6, 11 are the start of rows
            testCase.verifyEqual(tbl.Var1(1), 1);
            testCase.verifyEqual(tbl.Var1(2), 6);
            testCase.verifyEqual(tbl.Var1(3), 11);
        end

        function testPreviewSparseTall(testCase)
            [ds, meta] = ingestData(testCase.TestAssets.noHeader);
            % Test for the warning when sparse previewing a tall array
            testCase.assertWarning(@() previewData(ds, 'Mode', 'sparse', 'Step', 5, 'DsMeta', meta), 'previewData:SparseTallWarning');

            tbl = previewData(ds, 'Mode', 'sparse', 'Step', 5, 'DsMeta', meta); % Execute to check results
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

    end % methods (Test)
end % classdef
