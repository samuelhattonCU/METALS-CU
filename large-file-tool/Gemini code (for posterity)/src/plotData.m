% src/plotData.m
function fig = plotData(data, varargin)
%PLOTDATA Generate a plot from a table, tall array (gathered), or datastore (gathered).
%   FIG = PLOTDATA(DATA, 'XVar', XNAME, 'YVar', YNAME) plots YNAME vs XNAME.
%   DATA is typically a MATLAB table. If DATA is a tall array or datastore,
%   it will be gathered before plotting, which can be memory intensive.
%   It's recommended to decimate/filter data *before* calling plotData if it's large.
%
% Inputs:
%   data       - MATLAB table, tall array, or datastore.
% Name-Value Pairs:
%   'XVar'     - Name of the variable for the X-axis (char/string). Default 'Time' or first var.
%   'YVar'     - Name of the variable for the Y-axis (char/string). Default 'Signal' or second var.
%                Can be a cell array of strings to plot multiple Y variables against the same X.
%   'Title'    - Plot title (char/string). Default 'Data Plot'.
%   'XLabel'   - X-axis label (char/string). Default is XVar name.
%   'YLabel'   - Y-axis label (char/string). Default is YVar name(s).
%   'Legend'   - Cell array of strings for legend if multiple YVars. Auto-generated if empty.
%   'FigureHandle' - Existing figure handle to plot into. Default creates new figure.
%   'AxesHandle'   - Existing axes handle to plot into. Default creates new axes.
%
% Outputs:
%   fig        - MATLAB figure handle of the generated plot.

    p = inputParser;
    addRequired(p, 'data', @(x) istable(x) || istall(x) || isa(x, 'matlab.io.Datastore'));
    addParameter(p, 'XVar', '', @(x) ischar(x) || isstring(x));
    addParameter(p, 'YVar', '', @(x) (ischar(x) || isstring(x)) || iscellstr(x));
    addParameter(p, 'Title', 'Data Plot', @(x) ischar(x) || isstring(x));
    addParameter(p, 'XLabel', '', @(x) ischar(x) || isstring(x));
    addParameter(p, 'YLabel', '', @(x) ischar(x) || isstring(x));
    addParameter(p, 'Legend', {}, @iscellstr);
    addParameter(p, 'FigureHandle', [], @(x) isa(x, 'matlab.ui.Figure'));
    addParameter(p, 'AxesHandle', [], @(x) isa(x, 'matlab.graphics.axis.Axes'));
    parse(p, data, varargin{:});

    args = p.Results;

    % --- Prepare Data ---
    if istall(data) || isa(data, 'matlab.io.Datastore')
        warning('plotData:GatheringData', 'Input data is a tall array or datastore. Gathering all data for plotting. This may be slow or memory-intensive for large datasets. Consider downsampling or filtering first.');
        try
            tbl = gather(data); % Gather tall array or read all from datastore
            if isa(data, 'matlab.io.Datastore') && isprop(data,'ReadSize') % reset datastore if applicable
                reset(data);
            end
        catch ME
            error('plotData:GatherError', 'Failed to gather data for plotting: %s', ME.message);
        end
        fprintf('Data gathered. Table size for plotting: %d x %d.\n', size(tbl,1), size(tbl,2));
    elseif istable(data)
        tbl = data;
    else
        error('plotData:InvalidInputType', 'Input data must be a table, tall array, or datastore.');
    end

    if isempty(tbl) || height(tbl) == 0
        warning('plotData:EmptyData', 'Input data for plotting is empty. No plot generated.');
        if ~isempty(args.FigureHandle)
            fig = args.FigureHandle;
        else
            fig = figure; % Return an empty figure
        end
        title('No data to plot');
        return;
    end

    varNames = tbl.Properties.VariableNames;

    % Determine XVar
    if isempty(args.XVar)
        if any(strcmpi(varNames, 'Time'))
            xVarName = 'Time';
        elseif ~isempty(varNames)
            xVarName = varNames{1};
        else
            error('plotData:NoXVar', 'Cannot determine XVar. Table has no variables or XVar not specified.');
        end
    else
        xVarName = char(args.XVar);
        if ~any(strcmp(varNames, xVarName))
            error('plotData:XVarNotFound', 'XVar "%s" not found in the table.', xVarName);
        end
    end

    % Determine YVar(s)
    if isempty(args.YVar)
        if any(strcmpi(varNames, 'Signal'))
            yVarNames = {'Signal'};
        elseif length(varNames) >= 2
            if strcmp(varNames{1}, xVarName) % if XVar is the first
                yVarNames = {varNames{2}};
            else % XVar is not first, so Y can be first
                yVarNames = {varNames{1}};
            end
        else
            error('plotData:NoYVar', 'Cannot determine YVar. Table has less than 2 variables or YVar not specified.');
        end
    else
        yVarNames = cellstr(args.YVar);
    end

    for i = 1:length(yVarNames)
        if ~any(strcmp(varNames, yVarNames{i}))
            error('plotData:YVarNotFound', 'YVar "%s" not found in the table.', yVarNames{i});
        end
    end

    % --- Prepare Figure and Axes ---
    if ~isempty(args.AxesHandle)
        ax = args.AxesHandle;
        fig = ancestor(ax, 'figure');
    elseif ~isempty(args.FigureHandle)
        fig = args.FigureHandle;
        ax = gca(fig); % Get current axes or create one
    else
        fig = figure;
        ax = gca;
    end
    hold(ax, 'on'); % Hold on to plot multiple YVars

    % --- Plotting ---
    fprintf('Plotting %s vs %s...\n', strjoin(yVarNames, ', '), xVarName);
    xData = tbl.(xVarName);
    plotHandles = [];
    actualYVarNamesForLegend = {};

    for i = 1:length(yVarNames)
        yVarCurrent = yVarNames{i};
        yData = tbl.(yVarCurrent);

        % Check for non-numeric data that plot can't handle directly (e.g. string, cell)
        if ~(isnumeric(yData) || islogical(yData) || isdatetime(yData) || isduration(yData) || iscategorical(yData))
            warning('plotData:NonNumericYData', 'Y-variable "%s" is of type %s, which may not plot correctly. Skipping.', yVarCurrent, class(yData));
            continue;
        end
        if ~(isnumeric(xData) || islogical(xData) || isdatetime(xData) || isduration(xData) || iscategorical(xData))
            warning('plotData:NonNumericXData', 'X-variable "%s" is of type %s, which may not plot correctly. Skipping plots with this XVar.', xVarName, class(xData));
            break; % Skip all plots if X is bad
        end

        try
            h = plot(ax, xData, yData);
            plotHandles = [plotHandles, h]; %#ok<AGROW>
            actualYVarNamesForLegend{end+1} = yVarCurrent; %#ok<AGROW>
        catch ME_plot
            warning('plotData:PlottingError', 'Could not plot %s vs %s: %s', yVarCurrent, xVarName, ME_plot.message);
        end
    end

    if isempty(plotHandles)
        warning('plotData:NoDataPlotted', 'No data was successfully plotted.');
        hold(ax,'off');
        title(ax, args.Title); % Still set title
        if isempty(args.XLabel), xlabel(ax, strrep(xVarName, '_', ' ')); else, xlabel(ax, args.XLabel); end
        if isempty(args.YLabel) && ~isempty(yVarNames), ylabel(ax, strrep(strjoin(yVarNames,', '), '_', ' ')); else, ylabel(ax, args.YLabel); end
        return; % Exit if nothing plotted
    end

    hold(ax, 'off');

    % --- Customize Plot ---
    title(ax, args.Title);

    if isempty(args.XLabel)
        xlabel(ax, strrep(xVarName, '_', ' ')); % Replace underscores for display
    else
        xlabel(ax, args.XLabel);
    end

    if isempty(args.YLabel)
        ylabel(ax, strrep(strjoin(actualYVarNamesForLegend, ', '), '_', ' '));
    else
        ylabel(ax, args.YLabel);
    end

    if length(actualYVarNamesForLegend) > 1
        if ~isempty(args.Legend) && length(args.Legend) == length(actualYVarNamesForLegend)
            legend(ax, args.Legend, 'Interpreter', 'none');
        else
            legend(ax, strrep(actualYVarNamesForLegend, '_', ' '), 'Interpreter', 'none');
        end
    end

    grid(ax, 'on');
    fprintf('Plot generation complete.\n');
end
