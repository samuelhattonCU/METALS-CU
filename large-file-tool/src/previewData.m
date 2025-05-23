% src/previewData.m
function tbl = previewData(ds, varargin)
%PREVIEWDATA Return first N rows or a sparse sample from a datastore or tall array.
%   TBL = PREVIEWDATA(DS) returns the first 100 rows (default head).
%   TBL = PREVIEWDATA(DS, 'DsMeta', METADATA_STRUCT, ...) can use METADATA_STRUCT
%         for assigning variable units to the previewed table.
%   TBL = PREVIEWDATA(DS, 'Mode', 'head', 'N', VAL) returns first VAL rows.
%   TBL = PREVIEWDATA(DS, 'Mode', 'sparse', 'Step', VAL) returns every VAL-th row
%         from the underlying datastore (gathered).
%
% Inputs:
%   ds         - MATLAB datastore or tall array.
% Name-Value Pairs:
%   'Mode'     - 'head' (default) | 'sparse'.
%   'N'        - Number of rows for 'head' mode (default 100).
%   'Step'     - Sampling interval for 'sparse' mode (default 1000).
%   'DsMeta'   - Optional metadata structure (e.g., from ingestData)
%                containing fields like 'variableUnits'.
%
% Outputs:
%   tbl        - MATLAB table with preview rows.

    p = inputParser;
    % Allow ds to be a struct if users pass {datastore, meta} pair, though DsMeta is preferred
    addRequired(p, 'ds', @(x) isa(x, 'matlab.io.Datastore') || istall(x) || isstruct(x));
    addParameter(p, 'Mode', 'head', @(x) ismember(lower(x), {'head', 'sparse'}));
    addParameter(p, 'N', getpref('DataImport', 'PreviewHeadN', 100), @(x) isnumeric(x) && isscalar(x) && x > 0);
    addParameter(p, 'Step', getpref('DataImport', 'PreviewSparseStep', 1000), @(x) isnumeric(x) && isscalar(x) && x > 0);
    addParameter(p, 'DsMeta', [], @(x) isstruct(x) || isempty(x)); % MODIFIED: Added DsMeta
    parse(p, ds, varargin{:});

    dsInput = p.Results.ds;
    dsMeta = p.Results.DsMeta;

    % Handle if dsInput is a struct {data, meta} for backward compatibility or alternative use
    % However, prefer passing meta via 'DsMeta' Name-Value pair.
    if isstruct(dsInput) && isfield(dsInput, 'data') && isfield(dsInput, 'meta')
        currentDs = dsInput.data;
        if isempty(dsMeta) % If DsMeta wasn't passed explicitly, use the one from the struct
            dsMeta = dsInput.meta;
        end
    else
        currentDs = dsInput;
    end

    mode = lower(p.Results.Mode);
    N = round(p.Results.N);
    step = round(p.Results.Step);
    tbl = table;

    try
        if isa(currentDs, 'tall')
            if strcmp(mode, 'head')
                fprintf('Previewing head of tall array (first %d rows).\n', N);
                tbl = gather(head(currentDs, N));
            elseif strcmp(mode, 'sparse')
                warning('previewData:SparseTallWarning', ...
                    'Sparse preview on a tall array requires gathering all data first, then sampling. This might be slow or memory-intensive. Consider operating on the underlying datastore or filtering first.');
                fprintf('Gathering tall array for sparse preview (step %d). This may take time...\n', step);
                full_tbl = gather(currentDs);
                if height(full_tbl) > 0
                    indices = 1:step:height(full_tbl);
                    tbl = full_tbl(indices, :);
                else
                    tbl = full_tbl;
                end
                fprintf('Sparse preview complete. Selected %d rows.\n', height(tbl));
            end
        elseif isa(currentDs, 'matlab.io.Datastore')
            originalReadSize = currentDs.ReadSize;
            closerReadSize = onCleanup(@() set(currentDs, 'ReadSize', originalReadSize)); % Ensure ReadSize reset

            if strcmp(mode, 'head')
                fprintf('Previewing head of datastore (first %d rows).\n', N);
                if hasdata(currentDs)
                    reset(currentDs);
                    try
                        tbl_preview_ds = preview(currentDs);
                        if height(tbl_preview_ds) > N
                            tbl = tbl_preview_ds(1:N,:);
                        elseif height(tbl_preview_ds) < N && N > originalReadSize && hasdata(currentDs)
                            reset(currentDs);
                            currentDs.ReadSize = N;
                            if hasdata(currentDs)
                                tbl_temp = read(currentDs);
                                if ~isempty(tbl_temp)
                                   tbl = tbl_temp;
                                end
                            end
                            reset(currentDs);
                        else % Preview was N or less, or N was smaller/equal to originalReadSize
                            tbl = tbl_preview_ds;
                            if height(tbl) > N % Ensure it's capped at N if preview returned more
                                tbl = tbl(1:N, :);
                            end
                        end
                    catch ME_preview
                         warning('previewData:DatastorePreviewError', 'Datastore preview method failed: %s. Attempting manual read.', ME_preview.message);
                         reset(currentDs);
                         currentDs.ReadSize = N;
                         if hasdata(currentDs)
                            tbl = read(currentDs);
                         end
                         reset(currentDs);
                    end
                else
                    fprintf('Datastore has no data to preview.\n');
                end
            elseif strcmp(mode, 'sparse')
                fprintf('Previewing sparse sample of datastore (every %d-th row).\n', step);
                all_data_chunks = {};
                total_rows_read = 0;
                reset(currentDs);

                % Use a sensible chunk size for sparse preview, not necessarily 'file'
                originalReadSizeForSparse = currentDs.ReadSize;
                if isnumeric(originalReadSizeForSparse) % if it's a number
                    currentDs.ReadSize = min(100000, originalReadSizeForSparse * 10); % Read in larger chunks for speed
                else % if it's 'file' or other text, use a fixed large chunk
                    currentDs.ReadSize = 100000;
                end

                temp_tbl_list = {};
                if hasdata(currentDs)
                    while hasdata(currentDs)
                        chunk = read(currentDs);
                        if isempty(chunk), break; end % Avoid infinite loop if read returns empty at end
                        temp_tbl_list{end+1} = chunk;
                        total_rows_read = total_rows_read + height(chunk);
                    end
                end
                currentDs.ReadSize = originalReadSizeForSparse; % Restore
                reset(currentDs);

                if ~isempty(temp_tbl_list)
                    full_tbl = vertcat(temp_tbl_list{:});
                    if height(full_tbl) > 0
                        indices = 1:step:height(full_tbl);
                        tbl = full_tbl(indices, :);
                    else
                        tbl = full_tbl;
                    end
                    fprintf('Sparse preview complete. Selected %d rows from %d total.\n', height(tbl), height(full_tbl));
                else
                    fprintf('No data read for sparse preview.\n');
                end
            end
        end

        % MODIFIED: Try to assign variable units if available from dsMeta
        if ~isempty(tbl) && ~isempty(dsMeta) && isfield(dsMeta, 'variableUnits') && ...
           ~isempty(dsMeta.variableUnits)
            units = dsMeta.variableUnits;
            % Ensure variable names in table match what units correspond to, if possible
            % For simplicity, just check width.
            if width(tbl) == length(units)
                try
                    tbl.Properties.VariableUnits = units;
                catch ME_units
                    warning('previewData:UnitAssignFailed', 'Failed to assign variable units to preview table: %s', ME_units.message);
                end
            else
                 warning('previewData:UnitMismatch', 'Number of units (%d) does not match table width (%d) for preview. Units not assigned.', length(units), width(tbl));
            end
        end

    catch ME
        warning('previewData:Error', 'Error during previewData: %s', ME.message);
        if isa(currentDs, 'matlab.io.Datastore'), reset(currentDs); end
        tbl = table;
    end

    if isempty(tbl)
        fprintf('Preview resulted in an empty table.\n');
    else
        fprintf('Preview successful. Table size: %d x %d.\n', size(tbl,1), size(tbl,2));
    end
end
