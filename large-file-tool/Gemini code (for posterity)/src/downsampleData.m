% src/downsampleData.m
function dsDec = downsampleData(ds, varargin)
%DOWNSAMPLEDATA Decimate a datastore, tall array, or table by stride or custom function.
%   DSDEC = DOWNSAMPLEDATA(DS, 'Stride', K) takes every K-th row.
%   DSDEC = DOWNSAMPLEDATA(DS, 'Func', FHANDLE) applies FHANDLE to DS.
%
% Inputs:
%   ds          - MATLAB datastore, tall array, or table. % MODIFIED
% Name-Value Pairs:
%   'Stride'    - Decimation factor (integer >= 1). Default is 10.
%   'Func'      - Custom downsampling function handle.
%   'OutputType' - 'tall', 'datastore', or 'table'.
%
% Outputs:
%   dsDec       - Downsampled datastore, tall array, or table.

    p = inputParser;
    % MODIFIED: Added istable(x) to the validation function for ds
    addRequired(p, 'ds', @(x) isa(x, 'matlab.io.Datastore') || istall(x) || istable(x));
    addParameter(p, 'Stride', 10, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    addParameter(p, 'Func', [], @(x) isa(x, 'function_handle'));

    defaultOutputType = 'inherit';
    % Determine default output type based on input
    if istall(ds), defaultOutputType = 'tall';
    elseif isa(ds, 'matlab.io.Datastore'), defaultOutputType = 'datastore';
    elseif istable(ds), defaultOutputType = 'table'; % If input is table, default output is table
    end
    addParameter(p, 'OutputType', defaultOutputType, @(x) ismember(lower(x), {'tall', 'datastore', 'table', 'inherit'}));

    parse(p, ds, varargin{:});

    args = p.Results;
    stride = round(args.Stride);
    customFunc = args.Func;
    outputType = lower(args.OutputType);

    if strcmp(outputType, 'inherit')
        if istall(ds), outputType = 'tall';
        elseif isa(ds, 'matlab.io.Datastore'), outputType = 'datastore';
        elseif istable(ds), outputType = 'table'; % Added for table input
        end
    end

    currentDs = ds; % This can now be a table directly

    if ~isempty(customFunc)
        fprintf('Applying custom downsampling function...\n');
        try
            dsDec = customFunc(currentDs);
            if isa(dsDec, 'table') && (strcmp(outputType, 'tall') || strcmp(outputType, 'datastore'))
                warning('downsampleData:FuncReturnsTable', 'Custom function returned a table. If tall/datastore output was expected, this might not be directly compatible. Returning table.');
                outputType = 'table';
            end
        catch ME
            error('downsampleData:CustomFuncError', 'Error executing custom downsampling function: %s', ME.message);
        end
        fprintf('Custom downsampling function applied. Output type: %s\n', class(dsDec));

    else % Stride-based downsampling
        fprintf('Applying stride-based downsampling (Stride = %d)...\n', stride);
        if stride == 1
            dsDec = currentDs;
            fprintf('Stride is 1, no downsampling performed.\n');
        elseif istall(currentDs)
            try
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
                currentDs.ReadSize = 'file';
                full_tbl = readall(currentDs);
                reset(currentDs);

                if height(full_tbl) > 0
                    indices = 1:stride:height(full_tbl);
                    dsDec = full_tbl(indices, :);
                else
                    dsDec = full_tbl;
                end
                outputType = 'table';
            catch ME_readall
                 warning('downsampleData:ReadAllErrorForStride', 'Failed to readall from datastore for stride: %s. Attempting iterative read.', ME_readall.message);
                 reset(currentDs);
                 currentDs.ReadSize = 20000;
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
                    dsDec = full_tbl(indices, :);
                else
                    dsDec = full_tbl;
                end
                outputType = 'table';
            end
        elseif istable(currentDs) % MODIFIED: Added direct handling for table input
             if height(currentDs) > 0
                indices = 1:stride:height(currentDs);
                dsDec = currentDs(indices, :);
             else
                dsDec = currentDs;
             end
             % If input was table and outputType is 'inherit' or 'table', it's already a table.
             % If outputType was 'tall', it will be handled below.
             if ~strcmp(outputType, 'table')
                 % outputType might be 'tall' or 'datastore' (though datastore is unlikely from table)
             else
                 outputType = 'table'; % Confirm output is table
             end
        else
            error('downsampleData:UnknownInputTypeForStride', 'Unknown input type for stride-based downsampling: %s', class(currentDs));
        end
        fprintf('Stride downsampling complete.\n');
    end

    % Handle final output type
    if strcmp(outputType, 'table') && ~istable(dsDec) %MODIFIED: istable instead of isa(dsDec, 'table')
        fprintf('Gathering downsampled data to table...\n');
        try
            dsDec = gather(dsDec); % This will error if dsDec is already a table not from tall/datastore
        catch ME_gather
            % If dsDec was already a table (e.g. from table input), gather is not needed and might error if it's not a tall/datastore
            if istable(dsDec)
                % It's already a table, no action needed for gather.
            else
                error('downsampleData:GatherError', 'Failed to gather downsampled data to table: %s', ME_gather.message);
            end
        end
        fprintf('Gathering complete.\n');
    elseif strcmp(outputType, 'tall') && ~istall(dsDec)
        if istable(dsDec) % MODIFIED: istable
            warning('downsampleData:TableToTall', 'Result of downsampling is a table. Converting to tall array as requested, but this might not be efficient if table is large.');
            try
                dsDec = tall(dsDec);
            catch ME_tall
                 error('downsampleData:TallConversionError', 'Failed to convert table to tall: %s', ME_tall.message);
            end
        else
            warning('downsampleData:OutputTypeMismatchTall', 'Downsampled data is %s, but tall output requested. Returning as is.', class(dsDec));
        end
    elseif strcmp(outputType, 'datastore') && ~isa(dsDec, 'matlab.io.Datastore')
         warning('downsampleData:OutputTypeMismatchDatastore', 'Downsampled data is %s, but datastore output requested. This is usually not possible after processing. Returning as is.', class(dsDec));
    end

    fprintf('Downsampling process finished. Output type: %s.\n', class(dsDec));
    if istable(dsDec) % MODIFIED: istable
        fprintf('Downsampled table size: %d x %d.\n', size(dsDec,1), size(dsDec,2));
    end
end
