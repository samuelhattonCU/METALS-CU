% src/runPipeline.m
function runPipeline(inputFile, outputBaseName, varargin)
%RUNPIPELINE Example full data import-to-export workflow.
%   RUNPIPELINE(INPUTFILE, OUTPUTBASENAME) runs a predefined pipeline.
%
% Inputs:
%   inputFile      - Path to the input CSV/TSV file.
%   outputBaseName - Base name for output files (e.g., 'results/mydata').
%
% Name-Value Pairs (passed to underlying functions):
%   'NumHeaderLines' - For ingestData
%   'Delimiter'      - For ingestData
%   'PreviewHeadN'   - For previewData (number of rows for head preview)
%   'FilterRowRange' - For filterData [start, end]
%   'FilterTimeColumn' - For filterData
%   'FilterTimeRange'  - For filterData [tStart, tEnd]
%   'FilterPredicate'  - For filterData, function handle
%   'DownsampleStride' - For downsampleData
%   'PlotXVar'         - For plotData
%   'PlotYVar'         - For plotData (can be cellstr for multiple Y)
%   'ExportFormat'     - For exportData (e.g., 'csv', 'mat'). Default 'csv'.
%                          Can be a cell array like {'csv', 'mat'} to export multiple.

    % --- Setup Input Parser for runPipeline arguments ---
    p = inputParser;
    addRequired(p, 'inputFile', @(x) ischar(x) || isstring(x));
    addRequired(p, 'outputBaseName', @(x) ischar(x) || isstring(x));

    % Pass-through arguments for other functions
    addParameter(p, 'NumHeaderLines', getpref('DataImport', 'NumHeaderLines', -1), @isnumeric);
    addParameter(p, 'Delimiter', getpref('DataImport', 'Delimiter', ''), @(x) ischar(x) || isstring(x));
    addParameter(p, 'PreviewHeadN', getpref('DataImport', 'PreviewHeadN', 100), @isnumeric);

    addParameter(p, 'FilterRowRange', [], @isnumeric);
    addParameter(p, 'FilterTimeColumn', '', @(x) ischar(x) || isstring(x));
    addParameter(p, 'FilterTimeRange', [], @(x) isdatetime(x) || isduration(x) || isnumeric(x));
    addParameter(p, 'FilterPredicate', [], @(x) isa(x, 'function_handle'));
    addParameter(p, 'ZeroOffsetTimeColumn', '', @(x) (ischar(x) || isstring(x)) || islogical(x));


    addParameter(p, 'DownsampleStride', 10, @isnumeric);
    addParameter(p, 'DownsampleFunc', [], @(x) isa(x, 'function_handle'));


    addParameter(p, 'PlotXVar', 'Time', @(x) ischar(x) || isstring(x));
    addParameter(p, 'PlotYVar', 'Signal', @(x) (ischar(x) || isstring(x)) || iscellstr(x));
    addParameter(p, 'PlotTitle', 'Processed Data Plot', @(x) ischar(x) || isstring(x));

    addParameter(p, 'ExportFormat', {'csv', 'mat'}, @(x) ischar(x) || isstring(x) || iscellstr(x));

    parse(p, inputFile, outputBaseName, varargin{:});
    args = p.Results;

    fprintf('Starting pipeline for file: %s\n', args.inputFile);

    % Ensure output directory exists
    [outputPath, ~, ~] = fileparts(args.outputBaseName);
    if ~isempty(outputPath) && ~isfolder(outputPath)
        fprintf('Creating output directory: %s\n', outputPath);
        mkdir(outputPath);
    end

    % --- Phase 1: Ingest & Preview ---
    fprintf('\n--- Phase 1: Ingesting Data ---\n');
    ingestOpts = {};
    if args.NumHeaderLines ~= -1 % Only pass if not default auto (-1)
        ingestOpts = [ingestOpts, {'NumHeaderLines', args.NumHeaderLines}];
    end
    if ~isempty(args.Delimiter)
        ingestOpts = [ingestOpts, {'Delimiter', args.Delimiter}];
    end

    ds = ingestData(args.inputFile, ingestOpts{:});
    if isempty(ds)
        fprintf('Data ingestion failed. Pipeline terminated.\n');
        return;
    end

    fprintf('\n--- Previewing Ingested Data ---\n');
    tblHead = previewData(ds, 'N', args.PreviewHeadN);
    disp('Preview of ingested data (first few rows):');
    if height(tblHead) > 5
        disp(tblHead(1:5,:));
    else
        disp(tblHead);
    end
    fprintf('Full preview head table size: %d x %d\n', size(tblHead,1),size(tblHead,2));


    % --- Phase 2: Filtering (Conditional) ---
    fprintf('\n--- Phase 2: Filtering Data ---\n');
    filterOpts = {};
    needsFiltering = false;
    if ~isempty(args.FilterRowRange)
        filterOpts = [filterOpts, {'RowRange', args.FilterRowRange}];
        needsFiltering = true;
    end
    if ~isempty(args.FilterTimeRange) && ~isempty(args.FilterTimeColumn)
        filterOpts = [filterOpts, {'TimeColumn', args.FilterTimeColumn, 'TimeRange', args.FilterTimeRange}];
        needsFiltering = true;
    end
    if ~isempty(args.FilterPredicate)
        filterOpts = [filterOpts, {'Predicate', args.FilterPredicate}];
        needsFiltering = true;
    end
    zeroOffsetCol = '';
    if islogical(args.ZeroOffsetTimeColumn) && args.ZeroOffsetTimeColumn
        zeroOffsetCol = 'Time'; % Default
    elseif ischar(args.ZeroOffsetTimeColumn) || isstring(args.ZeroOffsetTimeColumn)
        zeroOffsetCol = char(args.ZeroOffsetTimeColumn);
    end
    if ~isempty(zeroOffsetCol)
        filterOpts = [filterOpts, {'ZeroOffsetTimeColumn', zeroOffsetCol}];
        needsFiltering = true; % Applying offset is a form of filtering/transformation
    end


    if needsFiltering
        % For pipeline, let's make filterData output a tall array if input was tall,
        % or table if input was datastore and filters applied that require gather.
        % Or simply, always output tall if possible, then gather later if needed.
        if istall(ds)
            filterOpts = [filterOpts, {'OutputType', 'tall'}];
        else % datastore
             % If filters require gathering, it will become a table.
             % If not, it might remain a datastore (though our filterData warns about this).
             % Let's aim for table if datastore and filtering, for simplicity in pipeline.
            filterOpts = [filterOpts, {'OutputType', 'table'}];
        end

        dsFiltered = filterData(ds, filterOpts{:});
        fprintf('Filtering complete. Output type: %s\n', class(dsFiltered));

        % Preview filtered data
        tblFilteredPreview = previewData(dsFiltered, 'N', 5); % Preview 5 rows of filtered
        disp('Preview of filtered data:');
        disp(tblFilteredPreview);

    else
        fprintf('No filters specified or applicable. Skipping filtering.\n');
        dsFiltered = ds; % Pass original data through
    end


    % --- Phase 3: Downsample & Plot ---
    fprintf('\n--- Phase 3: Downsampling and Plotting ---\n');
    downsampleOpts = {};
    if ~isempty(args.DownsampleFunc)
        downsampleOpts = [downsampleOpts, {'Func', args.DownsampleFunc}];
    elseif args.DownsampleStride > 1
        downsampleOpts = [downsampleOpts, {'Stride', args.DownsampleStride}];
    else
        fprintf('No downsampling required (Stride=1 or no function).\n');
        dsForPlot = dsFiltered; % Use filtered (or original) data
    end

    if ~isempty(downsampleOpts)
        % Output of downsampleData could be tall or table. For plotting, table is needed.
        downsampleOpts = [downsampleOpts, {'OutputType', 'table'}]; % Force table for plotting
        tblDecimated = downsampleData(dsFiltered, downsampleOpts{:});
        fprintf('Downsampling complete. Decimated table size: %d x %d.\n', size(tblDecimated,1), size(tblDecimated,2));
        dataToPlot = tblDecimated;
    else
        % If no downsampling, and dsFiltered is tall/datastore, gather for plotting
        if istall(dsFiltered) || isa(dsFiltered, 'matlab.io.Datastore')
            fprintf('Gathering data for plotting (no downsampling applied)...\n');
            dataToPlot = gather(dsFiltered);
            if isa(dsFiltered, 'matlab.io.Datastore') && isprop(dsFiltered,'ReadSize')
                reset(dsFiltered);
            end
            fprintf('Gathering complete. Table size for plotting: %d x %d.\n', size(dataToPlot,1), size(dataToPlot,2));
        else % dsFiltered is already a table
            dataToPlot = dsFiltered;
        end
    end

    if isempty(dataToPlot) || height(dataToPlot) == 0
        fprintf('No data available for plotting after filtering/downsampling. Skipping plot.\n');
    else
        plotFig = plotData(dataToPlot, 'XVar', args.PlotXVar, 'YVar', args.PlotYVar, 'Title', args.PlotTitle);
        plotFilename = [args.outputBaseName '_plot.png'];
        try
            exportgraphics(plotFig, plotFilename, 'Resolution', 300);
            fprintf('Plot saved to %s\n', plotFilename);
        catch ME_export
            warning('runPipeline:PlotExportFailed', 'Failed to export plot: %s. Trying saveas.', ME_export.message);
            try
                saveas(plotFig, [args.outputBaseName '_plot.fig']);
                fprintf('Plot saved to %s (MATLAB fig format)\n', [args.outputBaseName '_plot.fig']);
            catch ME_saveas
                 warning('runPipeline:PlotSaveAsFailed', 'Failed to save plot as .fig: %s.', ME_saveas.message);
            end
        end
    end

    % --- Phase 4: Export Results ---
    % Export the downsampled (and filtered) data used for plotting
    fprintf('\n--- Phase 4: Exporting Processed Data ---\n');
    exportFormats = cellstr(args.ExportFormat);

    if isempty(dataToPlot) || height(dataToPlot) == 0
         fprintf('No processed data to export.\n');
    else
        for i = 1:length(exportFormats)
            currentFormat = lower(strtrim(exportFormats{i}));
            if isempty(currentFormat), continue; end

            exportBase = [args.outputBaseName '_processed'];
            exportData(dataToPlot, exportBase, 'Format', currentFormat);
        end
    end

    % Optionally, export the *filtered but not downsampled* data if different
    if needsFiltering && (args.DownsampleStride > 1 || ~isempty(args.DownsampleFunc))
        fprintf('\n--- Exporting Filtered (but not downsampled) Data ---\n');
        if istall(dsFiltered) || isa(dsFiltered, 'matlab.io.Datastore')
            fprintf('Gathering filtered data for export...\n');
            tblFilteredFull = gather(dsFiltered);
             if isa(dsFiltered, 'matlab.io.Datastore') && isprop(dsFiltered,'ReadSize')
                reset(dsFiltered);
            end
            fprintf('Gathering complete. Filtered table size: %d x %d.\n', size(tblFilteredFull,1), size(tblFilteredFull,2));
        else % dsFiltered is already a table
            tblFilteredFull = dsFiltered;
        end

        if isempty(tblFilteredFull) || height(tblFilteredFull) == 0
            fprintf('No filtered data to export.\n');
        else
            for i = 1:length(exportFormats)
                currentFormat = lower(strtrim(exportFormats{i}));
                if isempty(currentFormat), continue; end

                exportBaseFiltered = [args.outputBaseName '_filtered'];
                exportData(tblFilteredFull, exportBaseFiltered, 'Format', currentFormat);
            end
        end
    end

    fprintf('\nPipeline finished for %s.\n', args.inputFile);
end
