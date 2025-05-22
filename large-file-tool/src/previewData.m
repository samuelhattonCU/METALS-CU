% src/previewData.m
function tbl = previewData(ds, varargin)
%PREVIEWDATA Return first N rows or a sparse sample from a datastore or tall array.
%   TBL = PREVIEWDATA(DS) returns the first 100 rows (default head).
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
%                For tall arrays, 'sparse' mode gathers the full data then samples.
%                This can be memory intensive for very large tall arrays.
%                Consider filtering first or using underlying datastore's preview for sparse.
%
% Outputs:
%   tbl        - MATLAB table with preview rows.

    p = inputParser;
    addRequired(p, 'ds', @(x) isa(x, 'matlab.io.Datastore') || istall(x));
    addParameter(p, 'Mode', 'head', @(x) ismember(lower(x), {'head', 'sparse'}));
    addParameter(p, 'N', getpref('DataImport', 'PreviewHeadN', 100), @(x) isnumeric(x) && isscalar(x) && x > 0);
    addParameter(p, 'Step', getpref('DataImport', 'PreviewSparseStep', 1000), @(x) isnumeric(x) && isscalar(x) && x > 0);
    parse(p, ds, varargin{:});

    mode = lower(p.Results.Mode);
    N = round(p.Results.N);
    step = round(p.Results.Step);
    tbl = table; % Initialize empty table

    try
        if isa(ds, 'tall')
            if strcmp(mode, 'head')
                fprintf('Previewing head of tall array (first %d rows).\n', N);
                tbl = gather(head(ds, N));
            elseif strcmp(mode, 'sparse')
                warning('previewData:SparseTallWarning', ...
                    'Sparse preview on a tall array requires gathering all data first, then sampling. This might be slow or memory-intensive. Consider operating on the underlying datastore or filtering first.');
                fprintf('Gathering tall array for sparse preview (step %d). This may take time...\n', step);
                full_tbl = gather(ds); % This can be very large
                if height(full_tbl) > 0
                    indices = 1:step:height(full_tbl);
                    tbl = full_tbl(indices, :);
                else
                    tbl = full_tbl; % Empty table
                end
                fprintf('Sparse preview complete. Selected %d rows.\n', height(tbl));
            end
        elseif isa(ds, 'matlab.io.Datastore')
            % Store original ReadSize and reset it later
            originalReadSize = ds.ReadSize;
            closerReadSize = onCleanup(@() set(ds, 'ReadSize', originalReadSize));

            if strcmp(mode, 'head')
                fprintf('Previewing head of datastore (first %d rows).\n', N);
                % For datastores, preview N rows directly if possible
                % Some datastores might not support reading arbitrary N easily without 'ReadSize'
                % A common way is to set ReadSize, read, then reset.
                % However, datastore's own preview method is better.
                if hasdata(ds)
                    reset(ds); % Ensure we start from the beginning
                    % Check if ds.SelectedVariableNames is set, as preview might ignore it
                    % For simple datastores (e.g., TabularTextDatastore), preview() is good.
                    try
                        tbl = preview(ds); % Default preview size
                        if height(tbl) > N
                            tbl = tbl(1:N,:);
                        elseif height(tbl) < N && N > originalReadSize && hasdata(ds)
                            % If default preview is too small, try reading N rows
                            reset(ds);
                            ds.ReadSize = N;
                            if hasdata(ds)
                                tbl_temp = read(ds);
                                if ~isempty(tbl_temp)
                                   tbl = tbl_temp;
                                end
                            end
                            reset(ds); % Reset again after read
                        end
                    catch ME_preview
                         warning('previewData:DatastorePreviewError', 'Datastore preview method failed: %s. Attempting manual read.', ME_preview.message);
                         reset(ds);
                         ds.ReadSize = N;
                         if hasdata(ds)
                            tbl = read(ds); % Read N rows
                         end
                         reset(ds);
                    end
                else
                    fprintf('Datastore has no data to preview.\n');
                end
            elseif strcmp(mode, 'sparse')
                fprintf('Previewing sparse sample of datastore (every %d-th row).\n', step);
                % Read all data in chunks and sample. This is more robust for various datastores.
                all_data_chunks = {};
                total_rows_read = 0;
                reset(ds); % Start from the beginning
                ds.ReadSize = 'file'; % Read entire file, or manage chunks if 'file' is too big

                if hasdata(ds)
                    % Temporarily change ReadSize for efficient full read if possible
                    % Or read in manageable chunks
                    originalReadSizeForSparse = ds.ReadSize;
                    ds.ReadSize = min(10000, originalReadSizeForSparse); % Sensible chunk size for sparse preview

                    temp_tbl_list = {};
                    while hasdata(ds)
                        chunk = read(ds);
                        temp_tbl_list{end+1} = chunk;
                        total_rows_read = total_rows_read + height(chunk);
                        if total_rows_read == 0 && ~hasdata(ds) % Read an empty chunk at EOF
                            break;
                        end
                    end
                    ds.ReadSize = originalReadSizeForSparse; % Restore
                    reset(ds);

                    if ~isempty(temp_tbl_list)
                        full_tbl = vertcat(temp_tbl_list{:});
                        if height(full_tbl) > 0
                            indices = 1:step:height(full_tbl);
                            tbl = full_tbl(indices, :);
                        else
                            tbl = full_tbl; % Empty table
                        end
                         fprintf('Sparse preview complete. Selected %d rows from %d total.\n', height(tbl), height(full_tbl));
                    else
                        fprintf('No data read for sparse preview.\n');
                    end
                else
                    fprintf('Datastore has no data for sparse preview.\n');
                end
            end
        end

        % Try to assign variable units if available from UserData
        if ~isempty(tbl) && isprop(ds, 'UserData') && isfield(ds.UserData, 'headerParserMeta') && ...
           isfield(ds.UserData.headerParserMeta, 'variableUnits') && ...
           ~isempty(ds.UserData.headerParserMeta.variableUnits)
            units = ds.UserData.headerParserMeta.variableUnits;
            if width(tbl) == length(units)
                try
                    tbl.Properties.VariableUnits = units;
                catch ME_units
                    warning('previewData:UnitAssignFailed', 'Failed to assign variable units to preview table: %s', ME_units.message);
                end
            else
                 warning('previewData:UnitMismatch', 'Number of units (%d) does not match table width (%d). Units not assigned.', length(units), width(tbl));
            end
        end

    catch ME
        warning('previewData:Error', 'Error during previewData: %s', ME.message);
        if isa(ds, 'matlab.io.Datastore'), reset(ds); end % Reset datastore on error
        tbl = table; % Return empty table on error
    end

    if isempty(tbl)
        fprintf('Preview resulted in an empty table.\n');
    else
        fprintf('Preview successful. Table size: %d x %d.\n', size(tbl,1), size(tbl,2));
    end
end
