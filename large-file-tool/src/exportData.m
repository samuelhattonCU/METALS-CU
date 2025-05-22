% src/exportData.m
function exportData(data, baseFilename, varargin)
%EXPORTDATA Write table, tall array (gathered), or datastore (gathered) to file.
%   EXPORTDATA(DATA, BASEFILENAME, 'Format', FMT) writes DATA to
%   BASEFILENAME.FMT.
%   If DATA is a tall array or datastore, it will be gathered before export.
%
% Inputs:
%   data         - MATLAB table, tall array, or datastore.
%   baseFilename - Base name for the output file (char/string, without extension).
% Name-Value Pairs:
%   'Format'     - File format: 'csv' (default), 'mat', 'parquet'.
%                  For 'parquet', MATLAB's Parquet functions are required.
%   'SelectedVariables' - Cell array of variable names to export. Exports all if empty.
%   'WriteMode'  - For 'csv': 'overwrite' (default) or 'append'.
%                  (Note: writetable's default is overwrite. Append might need more options)
%
% Outputs:
%   (none)     - Writes file to disk.

    p = inputParser;
    addRequired(p, 'data', @(x) istable(x) || istall(x) || isa(x, 'matlab.io.Datastore'));
    addRequired(p, 'baseFilename', @(x) ischar(x) || isstring(x));
    addParameter(p, 'Format', 'csv', @(x) ismember(lower(x), {'csv', 'mat', 'parquet'}));
    addParameter(p, 'SelectedVariables', {}, @iscellstr);
    addParameter(p, 'WriteMode', 'overwrite', @(x) ismember(lower(x), {'overwrite', 'append'})); % For CSV
    % Add more specific options for writetable if needed, e.g. Delimiter for CSV
    addParameter(p, 'Delimiter', ',', @(x) ischar(x) || isstring(x)); % For CSV

    parse(p, data, baseFilename, varargin{:});

    args = p.Results;
    baseFilename = char(args.baseFilename);
    format = lower(args.Format);

    % --- Prepare Data ---
    if istall(data) || isa(data, 'matlab.io.Datastore')
        warning('exportData:GatheringData', 'Input data is a tall array or datastore. Gathering all data for export. This may be slow or memory-intensive for large datasets.');
        try
            tbl = gather(data); % Gather tall array or read all from datastore
            if isa(data, 'matlab.io.Datastore') && isprop(data,'ReadSize') % reset datastore if applicable
                reset(data);
            end
        catch ME
            error('exportData:GatherError', 'Failed to gather data for export: %s', ME.message);
        end
        fprintf('Data gathered. Table size for export: %d x %d.\n', size(tbl,1), size(tbl,2));
    elseif istable(data)
        tbl = data;
    else
        error('exportData:InvalidInputType', 'Input data must be a table.');
    end

    if isempty(tbl)
        warning('exportData:EmptyData', 'Data to export is empty. No file written.');
        return;
    end

    % --- Select Variables ---
    if ~isempty(args.SelectedVariables)
        try
            tbl = tbl(:, args.SelectedVariables);
        catch ME
            error('exportData:SelectVariablesError', 'Error selecting variables for export: %s. Check variable names.', ME.message);
        end
    end

    if width(tbl) == 0
        warning('exportData:NoVariablesToExport', 'No variables selected or available for export. No file written.');
        return;
    end

    % --- Construct Full Filename ---
    fullFilename = [baseFilename, '.', format];
    if strcmp(format, 'mat') && ~endsWith(lower(baseFilename), '.mat')
         fullFilename = [baseFilename, '.mat']; % Ensure .mat for save
    elseif strcmp(format, 'parquet') && ~endsWith(lower(baseFilename), '.parquet')
         fullFilename = [baseFilename, '.parquet'];
    elseif strcmp(format, 'csv') && ~endsWith(lower(baseFilename), '.csv')
         fullFilename = [baseFilename, '.csv'];
    end


    % --- Export ---
    fprintf('Exporting data to %s (format: %s)...\n', fullFilename, format);
    try
        switch format
            case 'csv'
                writetableOpts = {};
                if strcmpi(args.WriteMode, 'append')
                    writetableOpts = [writetableOpts, {'WriteMode', 'append'}];
                end
                if ~strcmp(args.Delimiter, ',') % Only add if not default
                    writetableOpts = [writetableOpts, {'Delimiter', args.Delimiter}];
                end
                % Add other CSV options as needed, e.g. WriteVariableNames
                writetable(tbl, fullFilename, writetableOpts{:});
            case 'mat'
                % For 'save', the variable name in the MAT file will be 'tbl'
                % To save with a specific variable name, one might do:
                %   dataToSave = tbl; save(fullFilename, 'dataToSave');
                % Or, if the user wants the baseFilename to be the variable name:
                [~, nameForMat, ~] = fileparts(baseFilename);
                nameForMat = matlab.lang.makeValidName(nameForMat); % Ensure it's a valid var name
                eval([nameForMat, ' = tbl;']);
                save(fullFilename, nameForMat, '-v7.3'); % -v7.3 for potentially large tables
            case 'parquet'
                % Requires MATLAB's Parquet functions (e.g., from Hadoop support or separate add-on)
                if exist('parquetwrite', 'file')
                    parquetwrite(fullFilename, tbl);
                else
                    error('exportData:ParquetWriteMissing', 'Function parquetwrite not found. MATLAB Parquet support might be missing.');
                end
        end
        fprintf('Export successful: %s\n', fullFilename);
    catch ME
        error('exportData:ExportFailed', 'Failed to export data to %s: %s', fullFilename, ME.message);
    end
end
