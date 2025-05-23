% tests/TestDecimationPlotting.m
classdef TestDecimationPlotting < matlab.unittest.TestCase
    % TestDecimationPlotting contains unit tests for downsampleData.m and plotData.m

    properties
        PrefsBackup
        TestFileDir
        TestAssets
        BaseDataTall % A pre-loaded tall array
        BaseDataTable % A pre-loaded table
        % BaseDataMeta % MODIFIED: Store meta if needed, though not used in current tests
        LargeSignalTable % For more effective decimation testing
    end

    methods (TestClassSetup)
        function setupClass(testCase)
            currentFilePath = fileparts(mfilename('fullpath'));
            projectRoot = fileparts(currentFilePath);
            addpath(fullfile(projectRoot, 'src'));

            if exist('configManager', 'file')
                configManager('init');
            else
                warning('TestDecimationPlotting:ConfigManagerMissing', 'configManager.m not found.');
            end

            testCase.TestFileDir = fullfile(fileparts(mfilename('fullpath')), 'data');
            testCase.TestAssets = struct(...
                'twoLineNamesUnits', fullfile(testCase.TestFileDir, 'twoLineNamesUnits.csv') ...
            );
            testCase.assertTrue(isfile(testCase.TestAssets.twoLineNamesUnits), 'Test asset twoLineNamesUnits.csv not found.');

            try
                % MODIFIED: Capture both outputs from ingestData
                % Store meta if it might be useful, though current tests don't use it directly here.
                [ds, ~] = ingestData(testCase.TestAssets.twoLineNamesUnits, 'NumHeaderLines', 2, 'OutputType', 'tall');
                % testCase.BaseDataMeta = meta; % Uncomment if meta is needed
                testCase.BaseDataTall = ds;
                testCase.BaseDataTable = gather(ds);
            catch ME
                error('TestDecimationPlotting:ClassSetupError', 'Failed to load base data for tests: %s', ME.message);
            end

            rng(123);
            numRowsLarge = 2000;
            largeTime = (0:numRowsLarge-1)' * 0.01;
            largeSignal = cumsum(rand(numRowsLarge, 1) - 0.5) + sin(largeTime * 2*pi*0.5);
            largeStatus = randi([0,1], numRowsLarge, 1);
            testCase.LargeSignalTable = table(largeTime, largeSignal, largeStatus, 'VariableNames', {'Time', 'Signal', 'Status'});
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

        function TeardownMethodVerifyNoOpenFilesAndCloseFigs(testCase)
            testCase.verifyEmpty(fopen('all'), 'Some files were left open after the test.');
            close all force;
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

    % --- downsampleData Tests ---
    methods (Test)
        function testDownsampleStrideTall(testCase)
            stride = 2;
            dsDec = downsampleData(testCase.BaseDataTall, 'Stride', stride, 'OutputType', 'tall');
            tbl = gather(dsDec);

            testCase.verifyClass(tbl, 'table');
            testCase.verifySize(tbl, [3, 4], 'Incorrect table size after stride on tall.');
            testCase.verifyEqual(tbl.Time, [0.0; 0.2; 0.4], 'Time values mismatch after stride.');
            testCase.verifyEqual(tbl.Temperature(1), 25.1);
            testCase.verifyEqual(tbl.Temperature(2), 25.4);
        end

        function testDownsampleStrideTable(testCase)
            stride = 3;
            tblDec = downsampleData(testCase.BaseDataTable, 'Stride', stride, 'OutputType', 'table');

            testCase.verifyClass(tblDec, 'table');
            testCase.verifySize(tblDec, [2, 4], 'Incorrect table size after stride on table.');
            testCase.verifyEqual(tblDec.Time, [0.0; 0.3], 'Time values mismatch.');
            testCase.verifyTrue(ismissing(tblDec.Temperature(2)), 'NaN value mismatch (Original row 4 Temp).');
        end

        function testDownsampleStrideLargeTable(testCase)
            stride = 100;
            expectedNumRows = ceil(height(testCase.LargeSignalTable) / stride);
            tblDec = downsampleData(testCase.LargeSignalTable, 'Stride', stride, 'OutputType', 'table');

            testCase.verifySize(tblDec, [expectedNumRows, width(testCase.LargeSignalTable)]);
            testCase.verifyEqual(tblDec.Time(1), testCase.LargeSignalTable.Time(1));
            testCase.verifyEqual(tblDec.Time(end), testCase.LargeSignalTable.Time(1 + (expectedNumRows-1)*stride ));
        end

        function testDownsampleWithCustomFunction(testCase)
            customFunc = @(T) T(T.Status == 1, :);

            tblDec = downsampleData(testCase.BaseDataTable, 'Func', customFunc, 'OutputType', 'table');
            testCase.verifySize(tblDec, [1, 4]);
            testCase.verifyEqual(tblDec.Time(1), 0.2);

            expectedCount = sum(testCase.LargeSignalTable.Status == 1);
            tblDecLarge = downsampleData(testCase.LargeSignalTable, 'Func', customFunc, 'OutputType', 'table');
            testCase.verifySize(tblDecLarge, [expectedCount, width(testCase.LargeSignalTable)]);
        end

        function testDownsampleStrideOne(testCase)
            tblDec = downsampleData(testCase.BaseDataTable, 'Stride', 1, 'OutputType', 'table');
            testCase.verifyEqual(tblDec, testCase.BaseDataTable, 'Stride 1 should return original table.');
        end

        function testDownsampleStrideExceedsRows(testCase)
            stride = 10;
            tblDec = downsampleData(testCase.BaseDataTable, 'Stride', stride, 'OutputType', 'table');
            testCase.verifySize(tblDec, [1,4], 'Stride exceeding rows should return first row.');
            testCase.verifyEqual(tblDec.Time(1), testCase.BaseDataTable.Time(1));
        end

        % --- plotData Tests ---
        function testPlotDataBasic(testCase)
            fig = plotData(testCase.BaseDataTable, 'XVar', 'Time', 'YVar', 'Temperature');
            testCase.verifyClass(fig, 'matlab.ui.Figure', 'plotData did not return a figure handle.');
            testCase.verifyTrue(isvalid(fig), 'Returned figure handle is not valid.');

            ax = findobj(fig, 'Type', 'Axes');
            testCase.verifyNumElements(ax, 1, 'Expected one axes in the figure.');
            testCase.verifyEqual(ax.XLabel.String, 'Time', 'XLabel incorrect.');
            testCase.verifyEqual(ax.YLabel.String, 'Temperature', 'YLabel incorrect.');
            testCase.verifyEqual(ax.Title.String, 'Data Plot', 'Default title incorrect.');

            lines = findobj(ax, 'Type', 'Line');
            testCase.verifyNumElements(lines, 1, 'Expected one line series in the plot.');
        end

        function testPlotDataWithTitleAndLabels(testCase)
            customTitle = 'My Custom Plot';
            customXLabel = 'Elapsed Time (s)';
            customYLabel = 'Sensor Value (C)';
            fig = plotData(testCase.BaseDataTable, 'XVar', 'Time', 'YVar', 'Temperature', ...
                           'Title', customTitle, 'XLabel', customXLabel, 'YLabel', customYLabel);
            ax = findobj(fig, 'Type', 'Axes');
            testCase.verifyEqual(ax.Title.String, customTitle);
            testCase.verifyEqual(ax.XLabel.String, customXLabel);
            testCase.verifyEqual(ax.YLabel.String, customYLabel);
        end

        function testPlotDataMultipleYVars(testCase)
            yVars = {'Temperature', 'Pressure'};
            fig = plotData(testCase.BaseDataTable, 'XVar', 'Time', 'YVar', yVars);
            ax = findobj(fig, 'Type', 'Axes');
            lines = findobj(ax, 'Type', 'Line');
            testCase.verifyNumElements(lines, 2, 'Expected two line series for multiple YVars.');

            leg = findobj(fig, 'Type', 'Legend');
            testCase.verifyNumElements(leg, 1, 'Legend not found for multiple YVars.');
            testCase.verifyEqual(length(leg.String), 2, 'Legend does not have correct number of entries.');
            testCase.verifyEqual(leg.String{1}, 'Temperature');
            testCase.verifyEqual(leg.String{2}, 'Pressure');
        end

        function testPlotDataMultipleYVarsCustomLegend(testCase)
            yVars = {'Temperature', 'Pressure'};
            customLegend = {'Temp Series', 'Pressure Series'};
            fig = plotData(testCase.BaseDataTable, 'XVar', 'Time', 'YVar', yVars, 'Legend', customLegend);
            leg = findobj(fig, 'Type', 'Legend');
            testCase.verifyEqual(leg.String, customLegend', 'Custom legend strings incorrect.');
        end

        function testPlotDataFromTallArray(testCase)
            fig = plotData(testCase.BaseDataTall, 'XVar', 'Time', 'YVar', 'Status');
            testCase.verifyClass(fig, 'matlab.ui.Figure');
            ax = findobj(fig, 'Type', 'Axes');
            lines = findobj(ax, 'Type', 'Line');
            testCase.verifyNumElements(lines, 1, 'Plotting from tall array failed.');
            expectedYData = testCase.BaseDataTable.Status;
            actualYData = lines.YData;
            testCase.verifyEqual(actualYData(:), expectedYData(:));
        end

        function testPlotDataEmptyTable(testCase)
            emptyTbl = table();
            testCase.assertWarning(@() plotData(emptyTbl), 'plotData:EmptyData');
            fig = plotData(emptyTbl);
            testCase.verifyClass(fig, 'matlab.ui.Figure');
            ax = findobj(fig, 'Type', 'Axes');
            if ~isempty(ax)
                 testCase.verifyEqual(ax.Title.String, 'No data to plot', 'Title for empty data incorrect.');
            end
        end

        function testPlotDataIntoExistingFigureAndAxes(testCase)
            fig1 = figure;
            ax1 = axes(fig1);

            plotData(testCase.BaseDataTable, 'XVar', 'Time', 'YVar', 'Temperature', 'AxesHandle', ax1);
            testCase.verifyEqual(gca, ax1, 'Plot did not use the specified axes handle.');
            lines1 = findobj(ax1, 'Type', 'Line');
            testCase.verifyNumElements(lines1, 1, 'Line not plotted in specified axes.');

            fig2 = figure;
            plotData(testCase.BaseDataTable, 'XVar', 'Time', 'YVar', 'Pressure', 'FigureHandle', fig2);
            ax2 = findobj(fig2, 'Type', 'Axes');
            testCase.verifyEqual(gcf, fig2, 'Plot did not use the specified figure handle.');
            lines2 = findobj(ax2, 'Type', 'Line');
            testCase.verifyNumElements(lines2, 1, 'Line not plotted in specified figure.');
        end

    end % methods (Test)
end % classdef
