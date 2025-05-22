% tests/TestFiltering.m
classdef TestFiltering < matlab.unittest.TestCase
    % TestFiltering contains unit tests for filterData.m

    properties
        PrefsBackup
        TestFileDir
        TestAssets
        BaseDataTall % A pre-loaded tall array from a known CSV for consistent testing
        BaseDataTable % A pre-loaded table for testing direct table filtering
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

            % Define test file directory and assets once for the class
            testCase.TestFileDir = fullfile(fileparts(mfilename('fullpath')), 'data');
            testCase.TestAssets = struct(...
                'noHeader', fullfile(testCase.TestFileDir, 'noHeader.csv'), ...
                'twoLineNamesUnits', fullfile(testCase.TestFileDir, 'twoLineNamesUnits.csv') ...
            );
            testCase.assertTrue(isfile(testCase.TestAssets.noHeader), 'Test asset noHeader.csv not found.');
            testCase.assertTrue(isfile(testCase.TestAssets.twoLineNamesUnits), 'Test asset twoLineNamesUnits.csv not found.');

            % Pre-load data for filtering tests to avoid repeated ingestData calls
            % Using twoLineNamesUnits.csv as it has named columns including 'Time'
            try
                ds = ingestData(testCase.TestAssets.twoLineNamesUnits, 'NumHeaderLines', 2, 'OutputType', 'tall');
                testCase.BaseDataTall = ds;
                testCase.BaseDataTable = gather(ds); % For testing table inputs directly
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
            % Set any specific prefs for filtering tests if needed, though filterData mostly uses args
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
            % twoLineNamesUnits.csv has 6 data rows.
            % Time (s), Temp (degC), Pressure (kPa), Status (flag)
            % 0.0,25.1,101.2,0
            % 0.1,25.3,101.1,0
            % 0.2,25.4,101.3,1
            % 0.3,NaN,101.2,0
            % 0.4,25.5,,0
            % 0.5,25.6,101.0,0

            % Filter rows 2-4 from the tall array
            filtered_ds = filterData(testCase.BaseDataTall, 'RowRange', [2, 4], 'OutputType', 'tall');
            tbl = gather(filtered_ds);

            testCase.verifyClass(tbl, 'table');
            testCase.verifySize(tbl, [3, 4], 'Incorrect table size after RowRange filter on tall.');
            testCase.verifyEqual(tbl.Time(1), 0.1, 'First row Time mismatch.'); % Original row 2
            testCase.verifyEqual(tbl.Temperature(1), 25.3, 'First row Temperature mismatch.');
            testCase.verifyEqual(tbl.Time(3), 0.3, 'Last row Time mismatch.');   % Original row 4
            testCase.verifyTrue(ismissing(tbl.Temperature(3)), 'Last row Temperature (NaN) mismatch.');
        end

        function testFilterByRowRangeTableOutput(testCase)
            % Filter rows 3-5 directly, output as table
            tbl = filterData(testCase.BaseDataTall, 'RowRange', [3, 5], 'OutputType', 'table');
            testCase.verifyClass(tbl, 'table');
            testCase.verifySize(tbl, [3, 4]);
            testCase.verifyEqual(tbl.Time(1), 0.2); % Original row 3
            testCase.verifyEqual(tbl.Status(1), 1);
            testCase.verifyEqual(tbl.Time(3), 0.4); % Original row 5
            testCase.verifyTrue(ismissing(tbl.Pressure(3))); % Original row 5 Pressure is missing
        end

        function testFilterByRowRangeDirectTableInput(testCase)
            % Input is already a table
            tbl = filterData(testCase.BaseDataTable, 'RowRange', [1, 2], 'OutputType', 'table');
            testCase.verifyClass(tbl, 'table');
            testCase.verifySize(tbl, [2, 4]);
            testCase.verifyEqual(tbl.Time(1), 0.0);
            testCase.verifyEqual(tbl.Time(2), 0.1);
        end

        function testFilterByTimeRangeTall(testCase)
            % Time values: 0.0, 0.1, 0.2, 0.3, 0.4, 0.5
            % Filter Time >= 0.1 and Time <= 0.3
            % Expected rows: 0.1, 0.2, 0.3 (3 rows)
            filtered_ds = filterData(testCase.BaseDataTall, ...
                                     'TimeColumn', 'Time', ...
                                     'TimeRange', [0.1, 0.3], ...
                                     'OutputType', 'tall');
            tbl = gather(filtered_ds);
            testCase.verifySize(tbl, [3, 4], 'Incorrect size after TimeRange filter.');
            testCase.verifyEqual(tbl.Time, [0.1; 0.2; 0.3], 'Time values mismatch.');
            testCase.verifyEqual(tbl.Temperature(1), 25.3); % Corresponds to Time = 0.1
            testCase.verifyTrue(ismissing(tbl.Temperature(3))); % Corresponds to Time = 0.3
        end

        function testFilterByTimeRangeWithDatetime(testCase)
            % Create a temporary tall table with a datetime column
            baseTimes = [datetime(2023,1,1,10,0,0); datetime(2023,1,1,10,0,10); ...
                         datetime(2023,1,1,10,0,20); datetime(2023,1,1,10,0,30)];
            tempTbl = table(baseTimes, (1:4)', 'VariableNames', {'EventTime', 'Value'});
            tempTall = tall(tempTbl);

            tStart = datetime(2023,1,1,10,0,5);
            tEnd = datetime(2023,1,1,10,0,25);
            % Expected: 10:00:10, 10:00:20

            filtered_tt = filterData(tempTall, 'TimeColumn', 'EventTime', 'TimeRange', [tStart, tEnd], 'OutputType','tall');
            resultTbl = gather(filtered_tt);

            testCase.verifySize(resultTbl, [2,2]);
            testCase.verifyEqual(resultTbl.EventTime, [datetime(2023,1,1,10,0,10); datetime(2023,1,1,10,0,20)]);
            testCase.verifyEqual(resultTbl.Value, [2;3]);
        end

        function testFilterByPredicateTall(testCase)
            % Filter where Status == 1 (occurs at Time = 0.2)
            predicate = @(T) T.Status == 1;
            filtered_ds = filterData(testCase.BaseDataTall, 'Predicate', predicate, 'OutputType', 'tall');
            tbl = gather(filtered_ds);

            testCase.verifySize(tbl, [1, 4], 'Incorrect size after Predicate filter.');
            testCase.verifyEqual(tbl.Time(1), 0.2);
            testCase.verifyEqual(tbl.Status(1), 1);
        end

        function testFilterByPredicateOnValue(testCase)
            % Filter where Temperature > 25.3 AND Pressure < 101.3
            % Original Data:
            % Time Temp  Press Status
            % 0.0  25.1  101.2  0
            % 0.1  25.3  101.1  0
            % 0.2  25.4  101.3  1  (Temp > 25.3, Press not < 101.3)
            % 0.3  NaN   101.2  0
            % 0.4  25.5  NaN    0  (Temp > 25.3, Press is NaN - comparison result depends on NaN handling)
            % 0.5  25.6  101.0  0  (Temp > 25.3, Press < 101.3) -> This one should pass

            predicate = @(T) T.Temperature > 25.3 & T.Pressure < 101.3;
            tbl = filterData(testCase.BaseDataTall, 'Predicate', predicate, 'OutputType', 'table');

            testCase.verifySize(tbl, [1, 4], 'Incorrect size for combined predicate.');
            testCase.verifyEqual(tbl.Time(1), 0.5, 'Mismatch on combined predicate result.');
            testCase.verifyEqual(tbl.Temperature(1), 25.6);
            testCase.verifyEqual(tbl.Pressure(1), 101.0);
        end

        function testFilterCombination(testCase)
            % RowRange [1, 5], then Predicate Status == 0 on that subset
            % Original Rows 1-5:
            % Time Temp  Press Status
            % 0.0  25.1  101.2  0  -> Status 0
            % 0.1  25.3  101.1  0  -> Status 0
            % 0.2  25.4  101.3  1
            % 0.3  NaN   101.2  0  -> Status 0
            % 0.4  25.5  NaN    0  -> Status 0
            % Expected: 4 rows (0.0, 0.1, 0.3, 0.4)

            predicate = @(T) T.Status == 0;
            tbl = filterData(testCase.BaseDataTall, ...
                             'RowRange', [1, 5], ...
                             'Predicate', predicate, ...
                             'OutputType', 'table');

            testCase.verifySize(tbl, [4, 4], 'Incorrect size after combined RowRange and Predicate.');
            testCase.verifyEqual(tbl.Time, [0.0; 0.1; 0.3; 0.4], 'Time values mismatch in combined filter.');
        end

        function testFilterZeroOffsetTime(testCase)
            % Use BaseDataTable which has Time: 0.0, 0.1, 0.2, 0.3, 0.4, 0.5
            % Apply zero-offset to 'Time' column
            tbl = filterData(testCase.BaseDataTable, 'ZeroOffsetTimeColumn', 'Time', 'OutputType', 'table');

            expectedTimes = testCase.BaseDataTable.Time - testCase.BaseDataTable.Time(1);
            testCase.verifyEqual(tbl.Time, expectedTimes, 'Time column not zero-offset correctly.');
            % Verify other columns are unchanged
            testCase.verifyEqual(tbl.Temperature, testCase.BaseDataTable.Temperature, 'Temperature column changed during zero-offset.');
        end

        function testFilterZeroOffsetWithOtherFilters(testCase)
            % Filter for Time >= 0.2, then apply zero-offset
            % Subset by TimeRange: 0.2, 0.3, 0.4, 0.5
            % First time in this subset is 0.2.
            % Expected offset times: 0.0, 0.1, 0.2, 0.3

            tbl = filterData(testCase.BaseDataTall, ...
                             'TimeColumn', 'Time', 'TimeRange', [0.2, 0.5], ...
                             'ZeroOffsetTimeColumn', 'Time', ...
                             'OutputType', 'table');

            testCase.verifySize(tbl, [4,4]);
            expectedOriginalTimesInSubset = [0.2; 0.3; 0.4; 0.5];
            expectedOffsetTimes = expectedOriginalTimesInSubset - expectedOriginalTimesInSubset(1);

            testCase.verifyEqual(tbl.Time, expectedOffsetTimes, 'Time column not zero-offset correctly after TimeRange filter.');
            testCase.verifyEqual(tbl.Temperature(1), 25.4); % Temp for original time 0.2
        end

        function testFilterOutputTypeDatastoreWarning(testCase)
            % Applying filters that can't be pushed to datastore should warn if output is 'datastore'
            testCase.assertWarning(@() filterData(testCase.BaseDataTall.UnderlyingDatastores{1}, ...
                'RowRange', [1,2], 'OutputType', 'datastore'), ...
                'filterData:FiltersOnDatastoreOutput');

            % The function should return the original datastore in this case
            ds_orig = testCase.BaseDataTall.UnderlyingDatastores{1};
            ds_filtered = filterData(ds_orig, 'RowRange', [1,2], 'OutputType', 'datastore');
            testCase.verifySameHandle(ds_filtered, ds_orig, 'Should return original datastore if filters not applied.');
        end

        function testFilterInvalidTimeColumn(testCase)
            testCase.assertWarning(@() filterData(testCase.BaseDataTall, ...
                'TimeColumn', 'NonExistentColumn', 'TimeRange', [0.1, 0.3], 'OutputType', 'table'), ...
                'filterData:TimeRangeErrorTall'); % Or a more specific error about column not found

            % Depending on implementation, it might error or return unfiltered.
            % Current filterData warns and continues, effectively not filtering by time.
            tbl = filterData(testCase.BaseDataTall, ...
                'TimeColumn', 'NonExistentColumn', 'TimeRange', [0.1, 0.3], 'OutputType', 'table');
            testCase.verifySize(tbl, size(gather(testCase.BaseDataTall)), 'Table size should be original if TimeColumn is invalid and filter skipped.');
        end

        function testFilterEmptyRowRange(testCase)
            % An empty RowRange should not filter anything
            tbl = filterData(testCase.BaseDataTable, 'RowRange', [], 'OutputType', 'table');
            testCase.verifySize(tbl, size(testCase.BaseDataTable));
            testCase.verifyEqual(tbl, testCase.BaseDataTable);
        end

        function testFilterRowRangeExceedsData(testCase)
            % BaseDataTable has 6 rows. Request rows 5-10.
            tbl = filterData(testCase.BaseDataTable, 'RowRange', [5, 10], 'OutputType', 'table');
            testCase.verifySize(tbl, [2,4]); % Should get rows 5 and 6
            testCase.verifyEqual(tbl.Time(1), testCase.BaseDataTable.Time(5));
            testCase.verifyEqual(tbl.Time(2), testCase.BaseDataTable.Time(6));
        end

        function testFilterRowRangeStartAfterEnd(testCase)
            % Invalid range like [5, 2] should result in an empty table or warning
            % Current filterData implementation for table output will make an empty table.
            tbl = filterData(testCase.BaseDataTable, 'RowRange', [5,2], 'OutputType', 'table');
            testCase.verifyTrue(isempty(tbl) || height(tbl)==0, 'Invalid RowRange should produce an empty table.');
            if ~isempty(tbl) % if not empty, check it has 0 rows but correct vars
                testCase.verifyEqual(height(tbl),0);
                testCase.verifyEqual(tbl.Properties.VariableNames, testCase.BaseDataTable.Properties.VariableNames);
            end
        end

    end % methods (Test)
end % classdef
