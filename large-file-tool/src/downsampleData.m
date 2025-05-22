% src/downsampleData.m
function dsDec = downsampleData(ds, varargin)
%DOWNSAMPLEDATA Decimate a datastore or tall array by stride or custom function.
%   DSDEC = DOWNSAMPLEDATA(DS, 'Stride', K) takes every K-th row.
%   DSDEC = DOWNSAMPLEDATA(DS, 'Func', FHANDLE) applies FHANDLE to DS.
%         The function FHANDLE should take a tall array/datastore and return
%         a downsampled version.
%
% Inputs:
%   ds          - MATLAB datastore or tall array.
% Name-Value Pairs:
%   'Stride'    - Decimation factor (integer >= 1). Default is 10.
%                 For tall arrays, this uses indexing (e.g., ds(1:Stride:end,:)).
%                 For datastores, it gathers all data then strides (memory intensive).
%   'Func'      - Custom downsampling function handle. If provided, 'Stride' is ignored.
%                 Example: @(d) LTTB(d, 'Time', 'Value', 1000) for LTTB downsampling.
%                 The function must be able to handle the type of 'ds'.
%   'OutputType' - 'tall' (default if input is tall), 'datastore' (if input is datastore and no func),
%                  or 'table' (gathers result, useful if func returns table).
%
% Outputs:
%   dsDec       - Downsampled datastore, tall array, or table.

    p = inputParser;
    addRequired(p, 'ds', @(x) isa(x, 'matlab.io.Datastore') || istall(x));
    addParameter(p, 'Stride', 10, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    addParameter(p, 'Func', [], @(x) isa(x, 'function_handle'));

    defaultOutputType = 'inherit';
    if istall(ds), defaultOutputType = 'tall';
    elseif isa(ds, 'matlab.io.Datastore'), defaultOutputType = 'datastore'; end
    addParameter(p, 'OutputType', defaultOutputType, @(x) ismember(lower(x), {'tall', 'datastore', 'table', 'inherit'}));

    parse(p, ds, varargin{:});

    args = p.Results;
    stride = round(args.Stride);
    customFunc = args.Func;
    outputType = lower(args.OutputType);

    if strcmp(outputType, 'inherit')
        if istall(ds), outputType = 'tall';
        elseif isa(ds, 'matlab.io.Datastore'), outputType = 'datastore'; end
    end

    currentDs = ds;

    if ~isempty(customFunc)
        fprintf('Applying custom downsampling function...\n');
        try
            dsDec = customFunc(currentDs);
            % If customFunc returns a table, and outputType is tall/datastore, this might be an issue.
            % For now, assume customFunc returns a compatible type or user wants its direct output.
            if isa(dsDec, 'table') && (strcmp(outputType, 'tall') || strcmp(outputType, 'datastore'))
                warning('downsampleData:FuncReturnsTable', 'Custom function returned a table. If tall/datastore output was expected, this might not be directly compatible. Returning table.');
                outputType = 'table'; % Override output type to table
            end
        catch ME
            error('downsampleData:CustomFuncError', 'Error executing custom downsampling function: %s', ME.message);
        end
        fprintf('Custom downsampling function applied. Output type: %s\n', class(dsDec));

    else % Stride-based downsampling
        fprintf('Applying stride-based downsampling (Stride = %d)...\n', stride);
        if stride == 1
            dsDec = currentDs; % No change
            fprintf('Stride is 1, no downsampling performed.\n');
            return;
        end

        if istall(currentDs)
            try
                % Tall array indexing for stride
                dsDec = currentDs(1:stride:end, :);
                if ~strcmp(outputType, 'tall') && ~strcmp(outputType, 'table')
                    warning('downsampleData:TallOutputMismatch', 'Stride on tall array results in a tall array. OutputType %s might not be directly applicable without gathering.', outputType);
                end
            catch ME
                error('downsampleData:StrideErrorTall', 'Error applying stride to tall array: %s', ME.message);
            end

        elseif isa(currentDs, 'matlab.io.Datastore')
            warning('downsampleData:StrideOnDatastore', 'Stride downsampling on a direct datastore requires reading all data first. This can be memory intensive. Consider converting to tall array or using a custom function that handles datastores efficiently.');
            try
                reset(currentDs);
                currentDs.ReadSize = 'file'; % Try to read all
                full_tbl = readall(currentDs);
                reset(currentDs);

                if height(full_tbl) > 0
                    indices = 1:stride:height(full_tbl);
                    dsDec = full_tbl(indices, :); % Result is a table
                else
                    dsDec = full_tbl; % Empty table
                end
                outputType = 'table'; % Stride on datastore results in a table here
            catch ME_readall
                 warning('downsampleData:ReadAllErrorForStride', 'Failed to readall from datastore for stride: %s. Attempting iterative read.', ME_readall.message);
                 reset(currentDs);
                 currentDs.ReadSize = 20000; % Chunk size
                 tblParts = {};
                 while hasdata(currentDs)
                     tblParts{end+1} = read(currentDs);
                 end
                 reset(currentDs);
                 if isempty(tblParts)
                     full_tbl = table;
                 else
                    try
                        full_tbl = vertcat(tblParts{:});
                    catch ME_v
                        error('downsampleData:VertcatErrorStride', 'Failed to concatenate table parts for stride: %s', ME_v.message);
                    end
                 end

                if height(full_tbl) > 0
                    indices = 1:stride:height(full_tbl);
                    dsDec = full_tbl(indices, :); % Result is a table
                else
                    dsDec = full_tbl; % Empty table
                end
                outputType = 'table'; % Stride on datastore results in a table here
            end
        else % Input is already a table
             if height(currentDs) > 0
                indices = 1:stride:height(currentDs);
                dsDec = currentDs(indices, :);
             else
                dsDec = currentDs; % Empty table
             end
             outputType = 'table';
        end
        fprintf('Stride downsampling complete.\n');
    end

    % Handle final output type
    if strcmp(outputType, 'table') && ~isa(dsDec, 'table')
        fprintf('Gathering downsampled data to table...\n');
        try
            dsDec = gather(dsDec);
        catch ME_gather
            error('downsampleData:GatherError', 'Failed to gather downsampled data to table: %s', ME_gather.message);
        end
        fprintf('Gathering complete.\n');
    elseif strcmp(outputType, 'tall') && ~istall(dsDec)
        if isa(dsDec, 'table')
            warning('downsampleData:TableToTall', 'Result of downsampling is a table. Converting to tall array as requested, but this might not be efficient if table is large.');
            try
                dsDec = tall(dsDec);
            catch ME_tall
                 error('downsampleData:TallConversionError', 'Failed to convert table to tall: %s', ME_tall.message);
            end
        else % E.g. datastore output from custom func
            warning('downsampleData:OutputTypeMismatchTall', 'Downsampled data is %s, but tall output requested. Returning as is.', class(dsDec));
        end
    elseif strcmp(outputType, 'datastore') && ~isa(dsDec, 'matlab.io.Datastore')
         warning('downsampleData:OutputTypeMismatchDatastore', 'Downsampled data is %s, but datastore output requested. This is usually not possible after processing. Returning as is.', class(dsDec));
    end

    fprintf('Downsampling process finished. Output type: %s.\n', class(dsDec));
    if isa(dsDec, 'table')
        fprintf('Downsampled table size: %d x %d.\n', size(dsDec,1), size(dsDec,2));
    end

end
