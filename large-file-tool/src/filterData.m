% src/filterData.m
function filteredDsOrTable = filterData(ds, varargin)
%FILTERDATA Apply row, time, or function-handle filters to a datastore, tall array, or table.
%   FILTERED_DS_OR_TABLE = FILTERDATA(DS, Name, Value, ...)
%
% Inputs:
%   ds         - MATLAB datastore, tall array, or table. % MODIFIED
% Name-Value Pairs:
%   'RowRange' - [start, end] numeric vector for 1-based row indexing.
%   'TimeColumn' - Name of the time column (char/string) for 'TimeRange' filter.
%   'TimeRange'- [t_start, t_end] datetime or duration vector.
%   'ZeroOffsetTimeColumn' - Name of a numeric time column to zero-offset.
%   'Predicate'- Function handle for logical filtering.
%   'OutputType' - 'tall', 'datastore', or 'table'.
%
% Outputs:
%   filteredDsOrTable - Filtered datastore, tall array, or table.

    p = inputParser;
    % MODIFIED: Added istable(x) to the validation function for ds
    addRequired(p, 'ds', @(x) isa(x, 'matlab.io.Datastore') || istall(x) || istable(x));
    addParameter(p, 'RowRange', [], @(x) isnumeric(x) && (isempty(x) || (numel(x)==2 && x(1) <= x(2) && x(1) >= 1)));
    addParameter(p, 'TimeColumn', '', @(x) ischar(x) || isstring(x));
    addParameter(p, 'TimeRange', [], @(x) isdatetime(x) || isduration(x) || (isnumeric(x) && (isempty(x) || numel(x)==2)));
    addParameter(p, 'ZeroOffsetTimeColumn', '', @(x) (ischar(x) || isstring(x)) || islogical(x));
    addParameter(p, 'Predicate', [], @(x) isa(x, 'function_handle'));

    defaultOutputType = 'inherit';
    if istall(ds), defaultOutputType = 'tall';
    elseif isa(ds, 'matlab.io.Datastore'), defaultOutputType = 'datastore';
    elseif istable(ds), defaultOutputType = 'table'; % If input is table, default output is table
    end
    addParameter(p, 'OutputType', defaultOutputType, @(x) ismember(lower(x), {'tall', 'datastore', 'table', 'inherit'}));

    parse(p, ds, varargin{:});

    args = p.Results;
    outputType = lower(args.OutputType);
    if strcmp(outputType, 'inherit')
        if istall(ds), outputType = 'tall';
        elseif isa(ds, 'matlab.io.Datastore'), outputType = 'datastore';
        elseif istable(ds), outputType = 'table'; % Added for table input
        end
    end

    currentDs = ds; % This can now be a table directly

    % --- Apply Predicate Filter ---
    if ~isempty(args.Predicate)
        fprintf('Applying predicate filter...\n');
        if istall(currentDs)
            try
                currentDs = currentDs(args.Predicate(currentDs), :);
            catch ME
                warning('filterData:PredicateErrorTall', 'Error applying predicate to tall array: %s. Ensure predicate works with tall table syntax.', ME.message);
            end
        elseif istable(currentDs) % MODIFIED: Added direct handling for table
            try
                currentDs = currentDs(args.Predicate(currentDs), :);
            catch ME
                 warning('filterData:PredicateErrorTable', 'Error applying predicate to table: %s.', ME.message);
            end
        else % Datastore
            warning('filterData:PredicateOnDatastore', 'Predicate filtering on a direct datastore is not directly supported by this function. Consider converting to tall array first or outputting as a table.');
            if strcmp(outputType, 'table') || strcmp(outputType, 'tall')
                currentDs = tall(currentDs);
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

            if istall(currentDs)
                try
                    varNames = currentDs.Properties.VariableNames;
                    if ~any(strcmp(varNames, timeColName))
                        error('Time column "%s" not found in tall array.', timeColName);
                    end
                    filterCondition = currentDs.(timeColName) >= args.TimeRange(1) & currentDs.(timeColName) <= args.TimeRange(2);
                    currentDs = currentDs(filterCondition, :);
                catch ME
                    warning('filterData:TimeRangeErrorTall', 'Error applying TimeRange filter to tall array: %s. Ensure TimeColumn exists and types are compatible.', ME.message);
                end
            elseif istable(currentDs) % MODIFIED: Added direct handling for table
                try
                    varNames = currentDs.Properties.VariableNames;
                    if ~any(strcmp(varNames, timeColName))
                        error('Time column "%s" not found in table.', timeColName);
                    end
                    filterCondition = currentDs.(timeColName) >= args.TimeRange(1) & currentDs.(timeColName) <= args.TimeRange(2);
                    currentDs = currentDs(filterCondition, :);
                catch ME
                    warning('filterData:TimeRangeErrorTable', 'Error applying TimeRange filter to table: %s.', ME.message);
                end
            else % Datastore
                warning('filterData:TimeRangeOnDatastore', 'TimeRange filtering on a direct datastore is not directly supported. Consider converting to tall array or outputting as table.');
                 if strcmp(outputType, 'table') || strcmp(outputType, 'tall')
                    currentDs = tall(currentDs);
                     try
                        varNames = currentDs.Properties.VariableNames; % Check after converting
                        if ~any(strcmp(varNames, timeColName))
                             error('Time column "%s" not found in tall array (converted from datastore).', timeColName);
                        end
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
    zeroOffsetColName = '';
    if islogical(args.ZeroOffsetTimeColumn) && args.ZeroOffsetTimeColumn
        zeroOffsetColName = 'Time';
    elseif ischar(args.ZeroOffsetTimeColumn) || isstring(args.ZeroOffsetTimeColumn)
        zeroOffsetColName = char(args.ZeroOffsetTimeColumn);
    end

    if ~isempty(zeroOffsetColName)
        fprintf('Applying zero-offset to time column: %s...\n', zeroOffsetColName);
        if istall(currentDs)
            try
                % Check if column exists before trying to access it
                if ~any(strcmp(currentDs.Properties.VariableNames, zeroOffsetColName))
                     warning('filterData:ZeroOffsetColMissingTall', 'Column %s not found for zero-offset in tall array.', zeroOffsetColName);
                else
                    firstVal = gather(head(currentDs.(zeroOffsetColName), 1));
                    if ~isempty(firstVal) && isnumeric(firstVal)
                        currentDs.(zeroOffsetColName) = currentDs.(zeroOffsetColName) - firstVal;
                        fprintf('Zero-offset applied using first value: %f.\n', firstVal);
                    else
                        warning('filterData:ZeroOffsetFirstValTall', 'Could not get first value or it was not numeric for zero-offset on tall array column: %s.', zeroOffsetColName);
                    end
                end
            catch ME
                warning('filterData:ZeroOffsetErrorTall', 'Error applying zero-offset to tall array: %s.', ME.message);
            end
        elseif istable(currentDs) % MODIFIED: Direct handling for table
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
                elseif height(currentDs) > 0 % Only warn if table is not empty
                     warning('filterData:ZeroOffsetColMissingTable', 'Column %s not found for zero-offset in table.', zeroOffsetColName);
                end
            catch ME
                 warning('filterData:ZeroOffsetErrorTable', 'Error applying zero-offset to table: %s.', ME.message);
            end
        else % Datastore
            warning('filterData:ZeroOffsetOnDatastore', 'Zero-offset on a direct datastore is complex. Best applied when data is gathered to a table or if output is table.');
        end
        fprintf('Zero-offset application attempt complete.\n');
    end

    % --- Handle Output Type and RowRange ---
    if strcmp(outputType, 'table')
        if ~istable(currentDs) % If not already a table (i.e., it's tall or datastore)
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
                    currentDs.ReadSize = 'file';
                    gatheredTable = readall(currentDs);
                    reset(currentDs);
                catch ME_readall
                     warning('filterData:ReadAllError', 'Failed to readall from datastore: %s. Attempting iterative read.', ME_readall.message);
                     reset(currentDs);
                     currentDs.ReadSize = 10000;
                     tblParts = {};
                     while hasdata(currentDs)
                         chunk = read(currentDs);
                         if isempty(chunk), break; end
                         tblParts{end+1} = chunk;
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
            else % Should not happen given input validation, but as a safeguard
                gatheredTable = currentDs; % Assume it's already a table if not tall/datastore
            end
            currentDs = gatheredTable;
            fprintf('Data gathered. Table size: %d x %d.\n', size(currentDs,1), size(currentDs,2));
        end % else currentDs is already a table

        % Apply ZeroOffset again if it was requested and currentDs is now a table (if not done before on a table)
        % This ensures it's applied if the input was tall/datastore and output is table.
         if ~isempty(zeroOffsetColName) && istable(currentDs) && ...
            ~(islogical(args.ZeroOffsetTimeColumn) && ~args.ZeroOffsetTimeColumn)
            % Check if it was already applied (e.g. if input was table and it was done above)
            % This re-application is mainly for when input was tall/DS and output is table.
            % A more sophisticated check might be needed if the first value could change due to other filters.
            % For now, assume if it's a table now, and ZeroOffset was requested, apply it.
            fprintf('Applying/Re-applying zero-offset to time column: %s post-gather/table conversion...\n', zeroOffsetColName);
             try
                if any(strcmp(currentDs.Properties.VariableNames, zeroOffsetColName)) && height(currentDs) > 0
                    colData = currentDs.(zeroOffsetColName);
                    if isnumeric(colData)
                        firstVal = colData(1);
                        currentDs.(zeroOffsetColName) = colData - firstVal;
                        fprintf('Zero-offset applied/re-applied to table column %s using first value: %f.\n', zeroOffsetColName, firstVal);
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
                startIdx = max(1, round(args.RowRange(1))); % Ensure integer and >= 1
                endIdx = min(height(currentDs), round(args.RowRange(2))); % Ensure integer
                if startIdx <= endIdx
                    currentDs = currentDs(startIdx:endIdx, :);
                else
                    currentDs = currentDs(1:0, :);
                    warning('filterData:RowRangeInvalid', 'RowRange [%d, %d] is invalid for table of height %d. Result is empty.', args.RowRange(1), args.RowRange(2), height(currentDs));
                end
            catch ME
                warning('filterData:RowRangeErrorTable', 'Error applying RowRange to table: %s.', ME.message);
            end
            fprintf('RowRange filter applied. New table size: %d x %d.\n', size(currentDs,1), size(currentDs,2));
        end
        filteredDsOrTable = currentDs;

    elseif strcmp(outputType, 'tall')
        if ~istall(currentDs)
            if isa(currentDs,'matlab.io.Datastore')
                currentDs = tall(currentDs);
            elseif istable(currentDs) % Convert table to tall if requested
                 currentDs = tall(currentDs);
            end
        end
        if ~isempty(args.RowRange)
             warning('filterData:RowRangeTall', 'Applying RowRange to a tall array can be inefficient if not the final operation or if range is small. It might trigger computation.');
             try
                startIdx = max(1, round(args.RowRange(1)));
                % For tall arrays, end index can be 'end' or a large number.
                % If RowRange(2) is very large, it effectively means to the end.
                % However, direct indexing like N:M is preferred.
                % Tall array indexing handles out-of-bounds for end index gracefully if it's beyond actual length.
                endIdx = round(args.RowRange(2));
                if startIdx <= endIdx % Basic check, though tall array handles large endIdx
                    currentDs = currentDs(startIdx:endIdx, :);
                else
                    % Create an empty tall array with same properties
                    props = currentDs.Properties.VariableNames;
                    if ~isempty(props)
                        emptyData = cell(1,length(props)); % Create one row of empty cells
                        for k_empty=1:length(props), emptyData{k_empty} = []; end
                        emptyTT = cell2table(emptyData, 'VariableNames', props);
                        currentDs = tall(emptyTT(1:0,:)); % Empty tall table
                    else
                        currentDs = tall(table()); % Generic empty tall table
                    end
                     warning('filterData:RowRangeInvalidTall', 'RowRange [%d, %d] is invalid. Result is empty tall array.', args.RowRange(1), args.RowRange(2));
                end
             catch ME
                 warning('filterData:RowRangeErrorTall', 'Error applying RowRange to tall array: %s.', ME.message);
             end
        end
        filteredDsOrTable = currentDs;

    elseif strcmp(outputType, 'datastore')
        if istall(currentDs) || istable(currentDs)
            warning('filterData:ConversionToDatastore', 'Cannot convert a filtered tall array or table back to a datastore with filters applied. Returning the input as is or consider OutputType=''table'' or ''tall''.');
            filteredDsOrTable = ds; % Return original input if conversion not feasible
        else % Input was datastore, output is datastore
            if ~isempty(args.RowRange) || ~isempty(args.Predicate) || ~isempty(args.TimeRange) || ~isempty(zeroOffsetColName)
                warning('filterData:FiltersOnDatastoreOutput', 'Filters like RowRange, Predicate, TimeRange, ZeroOffset are not applied directly to the output datastore. The original datastore (or a copy) is returned. For applied filters, use OutputType=''tall'' or ''table''.');
            end
            filteredDsOrTable = ds;
        end
    else
        error('filterData:UnknownOutputType', 'Unknown OutputType specified.');
    end

    fprintf('Filtering complete. Output type: %s.\n', class(filteredDsOrTable));
    if istable(filteredDsOrTable)
        fprintf('Final table size: %d x %d.\n', size(filteredDsOrTable,1), size(filteredDsOrTable,2));
    elseif istall(filteredDsOrTable) && ~isempty(filteredDsOrTable.Properties.VariableNames) % Check if it's a valid tall table
        disp('Filtered tall array properties:');
        try
            disp(filteredDsOrTable.Properties);
        catch
            disp('Could not display properties of filtered tall array (might be empty or invalid).');
        end
    end
end
