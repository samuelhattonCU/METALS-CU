% tests/TestFiltering.m
classdef TestFiltering < matlab.unittest.TestCase
    % TestFiltering contains unit tests for filterData.m

    properties
        PrefsBackup
        TestFileDir
        TestAssets
        BaseDataTall % A pre-loaded tall array from a known CSV for consistent testing
        BaseDataTable % A pre-loaded table for testing direct table filtering
        % BaseDataMeta % MODIFIED: Store meta if needed, though not used in current tests
    end

    methods (TestClassSetup)
        function setupClass(testCase)
            currentFilePath = fileparts(mfilename('fullpath'));
            projectRoot = fileparts(currentFilePath);
            addpath(fullfile(projectRoot, 'src'));

            if exist('configManager', 'file')
                configManager('init');
            else
                warning('TestFiltering:ConfigManagerMissing', 'configManager.m not found.');
            end

            testCase.TestFileDir = fullfile(fileparts(mfilename('fullpath')), 'data');
            testCase.TestAssets = struct(...
                'noHeader', fullfile(testCase.TestFileDir, 'noHeader.csv'), ...
                'twoLineNamesUnits', fullfile(testCase.TestFileDir, 'twoLineNamesUnits.csv') ...
            );
            testCase.assertTrue(isfile(testCase.TestAssets.noHeader), 'Test asset noHeader.csv not found.');
            testCase.assertTrue(isfile(testCase.TestAssets.twoLineNamesUnits), 'Test asset twoLineNamesUnits.csv not found.');

            try
                % MODIFIED: Capture both outputs from ingestData
                % Store meta if it might be useful, though current tests don't use it directly here.
                [ds, ~] = ingestData(testCase.TestAssets.twoLineNamesUnits, 'NumHeaderLines', 2, 'OutputType', 'tall');
                % testCase.BaseDataMeta = meta; % Uncomment if meta is needed
                testCase.BaseDataTall = ds;
                testCase.BaseDataTable = gather(ds);
            catch ME
                error('TestFiltering:ClassSetupError', 'Failed to load base data for tests: %s', ME.message);
            end
        end
    end

    methods (TestMethodSetup)
        function savePrefs(testCase)
            if ispref('DataImport')
                testCase.PrefsBackup = getpref('DataImport');
            else
                testCase.PrefsBackup = struct();
            end
            setpref('DataImport', 'NumHeaderLines', 0);
            setpref('DataImport', 'Delimiter', ',');
        end
         function TeardownMethodVerifyNoOpenFiles(testCase)
            testCase.verifyEmpty(fopen('all'), 'Some files were left open after the test.');
        end
    end

    methods (TestMethodTeardown)
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
    end

    % --- filterData Tests ---
    methods (Test)
        function testFilterByRowRangeTall(testCase)
            filtered_ds = filterData(testCase.BaseDataTall, 'RowRange', [2, 4], 'OutputType', 'tall');
            tbl = gather(filtered_ds);

            testCase.verifyClass(tbl, 'table');
            testCase.verifySize(tbl, [3, 4], 'Incorrect table size after RowRange filter on tall.');
            testCase.verifyEqual(tbl.Time(1), 0.1, 'First row Time mismatch.');
            testCase.verifyEqual(tbl.Temperature(1), 25.3, 'First row Temperature mismatch.');
            testCase.verifyEqual(tbl.Time(3), 0.3, 'Last row Time mismatch.');
            testCase.verifyTrue(ismissing(tbl.Temperature(3)), 'Last row Temperature (NaN) mismatch.');
        end

        function testFilterByRowRangeTableOutput(testCase)
            tbl = filterData(testCase.BaseDataTall, 'RowRange', [3, 5], 'OutputType', 'table');
            testCase.verifyClass(tbl, 'table');
            testCase.verifySize(tbl, [3, 4]);
            testCase.verifyEqual(tbl.Time(1), 0.2);
            testCase.verifyEqual(tbl.Status(1), 1);
            testCase.verifyEqual(tbl.Time(3), 0.4);
            testCase.verifyTrue(ismissing(tbl.Pressure(3)));
        end

        function testFilterByRowRangeDirectTableInput(testCase)
            tbl = filterData(testCase.BaseDataTable, 'RowRange', [1, 2], 'OutputType', 'table');
            testCase.verifyClass(tbl, 'table');
            testCase.verifySize(tbl, [2, 4]);
            testCase.verifyEqual(tbl.Time(1), 0.0);
            testCase.verifyEqual(tbl.Time(2), 0.1);
        end

        function testFilterByTimeRangeTall(testCase)
            filtered_ds = filterData(testCase.BaseDataTall, ...
                                     'TimeColumn', 'Time', ...
                                     'TimeRange', [0.1, 0.3], ...
                                     'OutputType', 'tall');
            tbl = gather(filtered_ds);
            testCase.verifySize(tbl, [3, 4], 'Incorrect size after TimeRange filter.');
            testCase.verifyEqual(tbl.Time, [0.1; 0.2; 0.3], 'Time values mismatch.');
            testCase.verifyEqual(tbl.Temperature(1), 25.3);
            testCase.verifyTrue(ismissing(tbl.Temperature(3)));
        end

        function testFilterByTimeRangeWithDatetime(testCase)
            baseTimes = [datetime(2023,1,1,10,0,0); datetime(2023,1,1,10,0,10); ...
                         datetime(2023,1,1,10,0,20); datetime(2023,1,1,10,0,30)];
            tempTbl = table(baseTimes, (1:4)', 'VariableNames', {'EventTime', 'Value'});
            tempTall = tall(tempTbl);

            tStart = datetime(2023,1,1,10,0,5);
            tEnd = datetime(2023,1,1,10,0,25);

            filtered_tt = filterData(tempTall, 'TimeColumn', 'EventTime', 'TimeRange', [tStart, tEnd], 'OutputType','tall');
            resultTbl = gather(filtered_tt);

            testCase.verifySize(resultTbl, [2,2]);
            testCase.verifyEqual(resultTbl.EventTime, [datetime(2023,1,1,10,0,10); datetime(2023,1,1,10,0,20)]);
            testCase.verifyEqual(resultTbl.Value, [2;3]);
        end

        function testFilterByPredicateTall(testCase)
            predicate = @(T) T.Status == 1;
            filtered_ds = filterData(testCase.BaseDataTall, 'Predicate', predicate, 'OutputType', 'tall');
            tbl = gather(filtered_ds);

            testCase.verifySize(tbl, [1, 4], 'Incorrect size after Predicate filter.');
            testCase.verifyEqual(tbl.Time(1), 0.2);
            testCase.verifyEqual(tbl.Status(1), 1);
        end

        function testFilterByPredicateOnValue(testCase)
            predicate = @(T) T.Temperature > 25.3 & T.Pressure < 101.3;
            tbl = filterData(testCase.BaseDataTall, 'Predicate', predicate, 'OutputType', 'table');

            testCase.verifySize(tbl, [1, 4], 'Incorrect size for combined predicate.');
            testCase.verifyEqual(tbl.Time(1), 0.5, 'Mismatch on combined predicate result.');
            testCase.verifyEqual(tbl.Temperature(1), 25.6);
            testCase.verifyEqual(tbl.Pressure(1), 101.0);
        end

        function testFilterCombination(testCase)
            predicate = @(T) T.Status == 0;
            tbl = filterData(testCase.BaseDataTall, ...
                             'RowRange', [1, 5], ...
                             'Predicate', predicate, ...
                             'OutputType', 'table');

            testCase.verifySize(tbl, [4, 4], 'Incorrect size after combined RowRange and Predicate.');
            testCase.verifyEqual(tbl.Time, [0.0; 0.1; 0.3; 0.4], 'Time values mismatch in combined filter.');
        end

        function testFilterZeroOffsetTime(testCase)
            tbl = filterData(testCase.BaseDataTable, 'ZeroOffsetTimeColumn', 'Time', 'OutputType', 'table');

            expectedTimes = testCase.BaseDataTable.Time - testCase.BaseDataTable.Time(1);
            testCase.verifyEqual(tbl.Time, expectedTimes, 'Time column not zero-offset correctly.');
            testCase.verifyEqual(tbl.Temperature, testCase.BaseDataTable.Temperature, 'Temperature column changed during zero-offset.');
        end

        function testFilterZeroOffsetWithOtherFilters(testCase)
            tbl = filterData(testCase.BaseDataTall, ...
                             'TimeColumn', 'Time', 'TimeRange', [0.2, 0.5], ...
                             'ZeroOffsetTimeColumn', 'Time', ...
                             'OutputType', 'table');

            testCase.verifySize(tbl, [4,4]);
            expectedOriginalTimesInSubset = [0.2; 0.3; 0.4; 0.5];
            expectedOffsetTimes = expectedOriginalTimesInSubset - expectedOriginalTimesInSubset(1);

            testCase.verifyEqual(tbl.Time, expectedOffsetTimes, 'Time column not zero-offset correctly after TimeRange filter.');
            testCase.verifyEqual(tbl.Temperature(1), 25.4);
        end

        function testFilterOutputTypeDatastoreWarning(testCase)
            % This test assumes BaseDataTall.UnderlyingDatastores{1} is a valid datastore
            % If BaseDataTall is empty or not constructed as expected, this might error.
            if ~isempty(testCase.BaseDataTall) && ~isempty(testCase.BaseDataTall.UnderlyingDatastores)
                ds_to_test = testCase.BaseDataTall.UnderlyingDatastores{1};
                 testCase.assertWarning(@() filterData(ds_to_test, ...
                    'RowRange', [1,2], 'OutputType', 'datastore'), ...
                    'filterData:FiltersOnDatastoreOutput');

                ds_filtered = filterData(ds_to_test, 'RowRange', [1,2], 'OutputType', 'datastore');
                testCase.verifySameHandle(ds_filtered, ds_to_test, 'Should return original datastore if filters not applied.');
            else
                testCase.assumeFail('BaseDataTall or its UnderlyingDatastores not properly initialized for testFilterOutputTypeDatastoreWarning.');
            end
        end

        function testFilterInvalidTimeColumn(testCase)
            testCase.assertWarning(@() filterData(testCase.BaseDataTall, ...
                'TimeColumn', 'NonExistentColumn', 'TimeRange', [0.1, 0.3], 'OutputType', 'table'), ...
                'filterData:TimeRangeErrorTall');

            tbl = filterData(testCase.BaseDataTall, ...
                'TimeColumn', 'NonExistentColumn', 'TimeRange', [0.1, 0.3], 'OutputType', 'table');
            testCase.verifySize(tbl, size(gather(testCase.BaseDataTall)), 'Table size should be original if TimeColumn is invalid and filter skipped.');
        end

        function testFilterEmptyRowRange(testCase)
            tbl = filterData(testCase.BaseDataTable, 'RowRange', [], 'OutputType', 'table');
            testCase.verifySize(tbl, size(testCase.BaseDataTable));
            testCase.verifyEqual(tbl, testCase.BaseDataTable);
        end

        function testFilterRowRangeExceedsData(testCase)
            tbl = filterData(testCase.BaseDataTable, 'RowRange', [5, 10], 'OutputType', 'table');
            testCase.verifySize(tbl, [2,4]);
            testCase.verifyEqual(tbl.Time(1), testCase.BaseDataTable.Time(5));
            testCase.verifyEqual(tbl.Time(2), testCase.BaseDataTable.Time(6));
        end

        function testFilterRowRangeStartAfterEnd(testCase)
            tbl = filterData(testCase.BaseDataTable, 'RowRange', [5,2], 'OutputType', 'table');
            testCase.verifyTrue(isempty(tbl) || height(tbl)==0, 'Invalid RowRange should produce an empty table.');
            if ~isempty(tbl)
                testCase.verifyEqual(height(tbl),0);
                testCase.verifyEqual(tbl.Properties.VariableNames, testCase.BaseDataTable.Properties.VariableNames);
            end
        end

    end % methods (Test)
end % classdef
