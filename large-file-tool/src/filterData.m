% src/filterData.m
function filteredDsOrTable = filterData(ds, varargin)
%FILTERDATA Apply row, time, or function-handle filters to a datastore or tall array.
%   FILTERED_DS_OR_TABLE = FILTERDATA(DS, Name, Value, ...)
%
% Inputs:
%   ds         - MATLAB datastore or tall array.
% Name-Value Pairs:
%   'RowRange' - [start, end] numeric vector for 1-based row indexing.
%                For tall arrays, this applies to the conceptual full array.
%                For datastores, this gathers data then slices (can be memory intensive).
%   'TimeColumn' - Name of the time column (char/string) for 'TimeRange' filter.
%                  Required if 'TimeRange' is used. Assumes this column can be
%                  converted to datetime or is already duration/datetime.
%   'TimeRange'- [t_start, t_end] datetime or duration vector.
%                Filters rows where TimeColumn is within this range (inclusive).
%   'ZeroOffsetTimeColumn' - Name of a numeric time column (e.g. ms from start)
%                            to apply zero-offset to. The first value in this
%                            column (after other filters are applied) will be
%                            subtracted from all values in this column.
%                            If true (logical), it tries to find a column named 'Time'.
%   'Predicate'- Function handle for logical filtering (e.g., @(T) T.Signal > 5).
%                The function should take a table (or row of a table for rowfun)
%                and return a logical scalar or vector.
%   'OutputType' - 'tall' (default if input is tall), 'datastore' (default if input is datastore),
%                  or 'table' (gathers result).
%
% Outputs:
%   filteredDsOrTable - Filtered datastore, tall array, or table, based on 'OutputType'
%                       and input type. If filtering a datastore and output is 'datastore',
%                       it might return the original datastore if filters can't be applied
%                       directly to the datastore type (e.g. row range on a generic datastore).

    p = inputParser;
    addRequired(p, 'ds', @(x) isa(x, 'matlab.io.Datastore') || istall(x));
    addParameter(p, 'RowRange', [], @(x) isnumeric(x) && (isempty(x) || (numel(x)==2 && x(1) <= x(2) && x(1) >= 1)));
    addParameter(p, 'TimeColumn', '', @(x) ischar(x) || isstring(x));
    addParameter(p, 'TimeRange', [], @(x) isdatetime(x) || isduration(x) || (isnumeric(x) && (isempty(x) || numel(x)==2)));
    addParameter(p, 'ZeroOffsetTimeColumn', '', @(x) (ischar(x) || isstring(x)) || islogical(x));
    addParameter(p, 'Predicate', [], @(x) isa(x, 'function_handle'));

    defaultOutputType = 'inherit'; % Special value
    if istall(ds), defaultOutputType = 'tall';
    elseif isa(ds, 'matlab.io.Datastore'), defaultOutputType = 'datastore';
    end
    addParameter(p, 'OutputType', defaultOutputType, @(x) ismember(lower(x), {'tall', 'datastore', 'table', 'inherit'}));

    parse(p, ds, varargin{:});

    args = p.Results;
    outputType = lower(args.OutputType);
    if strcmp(outputType, 'inherit')
        if istall(ds), outputType = 'tall';
        elseif isa(ds, 'matlab.io.Datastore'), outputType = 'datastore';
        end
    end

    currentDs = ds; % Start with the input

    % --- Apply Predicate Filter ---
    if ~isempty(args.Predicate)
        fprintf('Applying predicate filter...\n');
        if istall(currentDs)
            try
                % For tall arrays, the predicate should work on the entire table structure
                % T.(VarName)
                currentDs = currentDs(args.Predicate(currentDs), :);
            catch ME
                warning('filterData:PredicateErrorTall', 'Error applying predicate to tall array: %s. Ensure predicate works with tall table syntax.', ME.message);
            end
        else % Datastore
            % For datastores, predicates are harder to apply directly without reading.
            % We might need to convert to tall, filter, then convert back or output table.
            warning('filterData:PredicateOnDatastore', 'Predicate filtering on a direct datastore is not directly supported by this function. Consider converting to tall array first or outputting as a table.');
            if strcmp(outputType, 'table') || strcmp(outputType, 'tall')
                currentDs = tall(currentDs); % Convert to tall to apply predicate
                currentDs = currentDs(args.Predicate(currentDs), :);
            else
                 fprintf('Predicate filter skipped for direct datastore output.\n');
            end
        end
        fprintf('Predicate filter application attempt complete.\n');
    end

    % --- Apply TimeRange Filter ---
    if ~isempty(args.TimeRange)
        if isempty(args.TimeColumn)
            warning('filterData:NoTimeColumn', 'TimeRange filter specified but TimeColumn is missing. Filter skipped.');
        else
            fprintf('Applying TimeRange filter on column: %s...\n', args.TimeColumn);
            timeColName = char(args.TimeColumn);

            % Ensure TimeRange is datetime for comparison if timeCol is datetime
            % This part needs robust handling of time column types.
            % Assuming timeColName exists in the (tall) array/table.

            if istall(currentDs)
                try
                    % Check if time column exists
                    varNames = currentDs.Properties.VariableNames;
                    if ~any(strcmp(varNames, timeColName))
                        error('Time column "%s" not found in tall array.', timeColName);
                    end

                    % Build the logical indexing expression dynamically
                    % This is tricky because the type of currentDs.(timeColName) can vary.
                    % Let's assume it's compatible with direct comparison after ensuring TimeRange is appropriate.

                    % If TimeRange is numeric (e.g. seconds, ms), assume column is also numeric.
                    % If TimeRange is datetime, assume column is datetime.

                    % Example for numeric time column and numeric range:
                    % currentDs = currentDs(currentDs.(timeColName) >= args.TimeRange(1) & currentDs.(timeColName) <= args.TimeRange(2), :);

                    % Example for datetime column and datetime range:
                    % currentDs = currentDs(currentDs.(timeColName) >= args.TimeRange(1) & currentDs.(timeColName) <= args.TimeRange(2), :);

                    % A more generic way to construct the filter:
                    filterCondition = currentDs.(timeColName) >= args.TimeRange(1) & currentDs.(timeColName) <= args.TimeRange(2);
                    currentDs = currentDs(filterCondition, :);

                catch ME
                    warning('filterData:TimeRangeErrorTall', 'Error applying TimeRange filter to tall array: %s. Ensure TimeColumn exists and types are compatible.', ME.message);
                end
            else % Datastore
                warning('filterData:TimeRangeOnDatastore', 'TimeRange filtering on a direct datastore is not directly supported. Consider converting to tall array or outputting as table.');
                 if strcmp(outputType, 'table') || strcmp(outputType, 'tall')
                    currentDs = tall(currentDs); % Convert to tall to apply filter
                     try
                        filterCondition = currentDs.(timeColName) >= args.TimeRange(1) & currentDs.(timeColName) <= args.TimeRange(2);
                        currentDs = currentDs(filterCondition, :);
                     catch ME_ds_tt
                         warning('filterData:TimeRangeErrorTallPostConvert', 'Error applying TimeRange filter after converting datastore to tall: %s.', ME_ds_tt.message);
                     end
                 else
                    fprintf('TimeRange filter skipped for direct datastore output.\n');
                 end
            end
            fprintf('TimeRange filter application attempt complete.\n');
        end
    end

    % --- Apply ZeroOffset to Time Column ---
    % This should ideally be applied *after* other filters if the "first timestamp"
    % means the first one in the *filtered* dataset.
    % If it means first in the *original* dataset, it's more complex with tall arrays.
    % For simplicity, this implementation applies it to the current state of currentDs.
    % This is best done when the data is gathered or is a table.

    zeroOffsetColName = '';
    if islogical(args.ZeroOffsetTimeColumn) && args.ZeroOffsetTimeColumn
        zeroOffsetColName = 'Time'; % Default to 'Time' if true
    elseif ischar(args.ZeroOffsetTimeColumn) || isstring(args.ZeroOffsetTimeColumn)
        zeroOffsetColName = char(args.ZeroOffsetTimeColumn);
    end

    if ~isempty(zeroOffsetColName)
        fprintf('Applying zero-offset to time column: %s...\n', zeroOffsetColName);
        if istall(currentDs)
            % For tall arrays, getting the 'first' value requires a gather or a specific tall op.
            % This is a simplified approach: if we are outputting a table anyway, do it then.
            % If output is tall, this is harder. A common pattern is to compute the offset
            % once using head(...,1) and then subtract.
            try
                firstVal = gather(head(currentDs.(zeroOffsetColName), 1));
                if ~isempty(firstVal) && isnumeric(firstVal)
                    currentDs.(zeroOffsetColName) = currentDs.(zeroOffsetColName) - firstVal;
                    fprintf('Zero-offset applied using first value: %f.\n', firstVal);
                else
                    warning('filterData:ZeroOffsetFirstValTall', 'Could not get first value or it was not numeric for zero-offset on tall array column: %s.', zeroOffsetColName);
                end
            catch ME
                warning('filterData:ZeroOffsetErrorTall', 'Error applying zero-offset to tall array: %s.', ME.message);
            end
        elseif isa(currentDs, 'table') % If already a table (e.g. from previous gather)
            try
                if any(strcmp(currentDs.Properties.VariableNames, zeroOffsetColName)) && height(currentDs) > 0
                    colData = currentDs.(zeroOffsetColName);
                    if isnumeric(colData)
                        firstVal = colData(1);
                        currentDs.(zeroOffsetColName) = colData - firstVal;
                        fprintf('Zero-offset applied to table column %s using first value: %f.\n', zeroOffsetColName, firstVal);
                    else
                        warning('filterData:ZeroOffsetNotNumericTable', 'Column %s is not numeric. Zero-offset skipped.', zeroOffsetColName);
                    end
                else
                     warning('filterData:ZeroOffsetColMissingTable', 'Column %s not found or table empty for zero-offset.', zeroOffsetColName);
                end
            catch ME
                 warning('filterData:ZeroOffsetErrorTable', 'Error applying zero-offset to table: %s.', ME.message);
            end
        else % Datastore
            warning('filterData:ZeroOffsetOnDatastore', 'Zero-offset on a direct datastore is complex. Best applied when data is gathered to a table or if output is table.');
            % If output is table, it will be handled after gather.
        end
        fprintf('Zero-offset application attempt complete.\n');
    end


    % --- Handle Output Type and RowRange ---
    % RowRange is tricky for datastores/tall arrays without gathering.
    % If RowRange is specified, it often implies a 'table' output or gathering.

    if strcmp(outputType, 'table')
        fprintf('Gathering data to table...\n');
        if istall(currentDs)
            try
                gatheredTable = gather(currentDs);
            catch ME_gather
                 error('filterData:GatherError', 'Failed to gather tall array to table: %s', ME_gather.message);
            end
        elseif isa(currentDs, 'matlab.io.Datastore')
            try
                reset(currentDs);
                currentDs.ReadSize = 'file'; % Attempt to read all
                gatheredTable = readall(currentDs); % Requires TabularTextDatastore or similar
                reset(currentDs);
            catch ME_readall
                 warning('filterData:ReadAllError', 'Failed to readall from datastore: %s. Attempting iterative read.', ME_readall.message);
                 reset(currentDs);
                 currentDs.ReadSize = 10000; % Chunk size
                 tblParts = {};
                 while hasdata(currentDs)
                     tblParts{end+1} = read(currentDs);
                 end
                 if isempty(tblParts)
                     gatheredTable = table;
                 else
                    try
                        gatheredTable = vertcat(tblParts{:});
                    catch ME_vertcat
                        error('filterData:VertcatError', 'Failed to concatenate table parts: %s', ME_vertcat.message);
                    end
                 end
                 reset(currentDs);
            end
        else % Already a table
            gatheredTable = currentDs;
        end
        currentDs = gatheredTable; % Now it's a table
        fprintf('Data gathered. Table size: %d x %d.\n', size(currentDs,1), size(currentDs,2));

        % Apply ZeroOffset again if it was requested and currentDs is now a table (if not done before)
         if ~isempty(zeroOffsetColName) && isa(currentDs, 'table') && ...
            ~(islogical(args.ZeroOffsetTimeColumn) && ~args.ZeroOffsetTimeColumn) % Check if it was actually requested
            fprintf('Re-applying zero-offset to time column: %s post-gather...\n', zeroOffsetColName);
             try
                if any(strcmp(currentDs.Properties.VariableNames, zeroOffsetColName)) && height(currentDs) > 0
                    colData = currentDs.(zeroOffsetColName);
                    if isnumeric(colData)
                        firstVal = colData(1);
                        currentDs.(zeroOffsetColName) = colData - firstVal;
                        fprintf('Zero-offset re-applied to table column %s using first value: %f.\n', zeroOffsetColName, firstVal);
                    else
                        warning('filterData:ZeroOffsetNotNumericTablePostGather', 'Column %s is not numeric. Zero-offset skipped post-gather.', zeroOffsetColName);
                    end
                elseif height(currentDs) > 0
                     warning('filterData:ZeroOffsetColMissingTablePostGather', 'Column %s not found for zero-offset post-gather.', zeroOffsetColName);
                end
            catch ME
                 warning('filterData:ZeroOffsetErrorTablePostGather', 'Error applying zero-offset to table post-gather: %s.', ME.message);
            end
         end


        % Apply RowRange filter if specified, now that we have a table
        if ~isempty(args.RowRange)
            fprintf('Applying RowRange filter: %d to %d.\n', args.RowRange(1), args.RowRange(2));
            try
                startIdx = max(1, args.RowRange(1));
                endIdx = min(height(currentDs), args.RowRange(2));
                if startIdx <= endIdx
                    currentDs = currentDs(startIdx:endIdx, :);
                else
                    currentDs = currentDs(1:0, :); % Empty table with same vars
                    warning('filterData:RowRangeInvalid', 'RowRange [%d, %d] is invalid for table of height %d. Result is empty.', args.RowRange(1), args.RowRange(2), height(gatheredTable));
                end
            catch ME
                warning('filterData:RowRangeErrorTable', 'Error applying RowRange to table: %s.', ME.message);
            end
            fprintf('RowRange filter applied. New table size: %d x %d.\n', size(currentDs,1), size(currentDs,2));
        end
        filteredDsOrTable = currentDs;

    elseif strcmp(outputType, 'tall')
        if ~istall(currentDs) && isa(currentDs,'matlab.io.Datastore') % If input was DS, convert to TALL
            currentDs = tall(currentDs);
        end
        % Apply RowRange for tall array using indexing (can be inefficient if not at end)
        if ~isempty(args.RowRange)
             warning('filterData:RowRangeTall', 'Applying RowRange to a tall array can be inefficient if not the final operation or if range is small. It might trigger computation.');
             try
                % Tall array indexing is 1-based.
                % This will create a new tall array representing the slice.
                currentDs = currentDs(args.RowRange(1):args.RowRange(2), :);
             catch ME
                 warning('filterData:RowRangeErrorTall', 'Error applying RowRange to tall array: %s.', ME.message);
             end
        end
        filteredDsOrTable = currentDs;

    elseif strcmp(outputType, 'datastore')
        if istall(currentDs)
            warning('filterData:TallToDatastore', 'Cannot convert a filtered tall array back to a datastore with filters applied. Returning the tall array instead or consider OutputType=''table''.');
            filteredDsOrTable = currentDs; % Return the tall array
        else % Input was datastore, output is datastore
            if ~isempty(args.RowRange) || ~isempty(args.Predicate) || ~isempty(args.TimeRange) || ~isempty(zeroOffsetColName)
                warning('filterData:FiltersOnDatastoreOutput', 'Filters like RowRange, Predicate, TimeRange, ZeroOffset are not applied directly to the output datastore. The original datastore (or a copy) is returned. For applied filters, use OutputType=''tall'' or ''table''.');
            end
            filteredDsOrTable = ds; % Return original datastore, filters not natively applied this way
        end
    else
        error('filterData:UnknownOutputType', 'Unknown OutputType specified.');
    end

    fprintf('Filtering complete. Output type: %s.\n', class(filteredDsOrTable));
    if isa(filteredDsOrTable, 'table')
        fprintf('Final table size: %d x %d.\n', size(filteredDsOrTable,1), size(filteredDsOrTable,2));
    elseif istall(filteredDsOrTable)
        disp('Filtered tall array properties:');
        disp(filteredDsOrTable.Properties);
    end
end
