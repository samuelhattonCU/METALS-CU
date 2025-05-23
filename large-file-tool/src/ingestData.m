% src/ingestData.m
function [ds, dsMeta] = ingestData(filename, varargin)
%INGESTDATA Create a datastore for large CSV/TSV files, possibly tall.
%   [DS, DSMETA] = INGESTDATA(FILENAME) creates a datastore from FILENAME
%   and returns the datastore DS and a metadata structure DSMETA.
%   It uses headerParser to determine file structure if not specified.
%
%   [DS, DSMETA] = INGESTDATA(FILENAME, 'NumHeaderLines', VAL, 'Delimiter', CHAR, ...)
%   allows specifying options for datastore creation.
%
%   Optional Name-Value Pairs:
%     'NumHeaderLines': Number of *content* header lines (e.g. for names, units).
%                       If -1 (default), headerParser attempts auto-detection.
%                       If 0, explicitly no content headers, data from line after initial comments.
%     'Delimiter': Delimiter character. If empty (default), uses headerParser or preference.
%     'ReadVariableNames': Logical. If not specified (default empty), behavior is:
%                          - true if headerParser found valid variableNames AND numHeaderLinesForDS > 0.
%                          - false if headerParser found no names, or numHeaderLinesForDS is 0,
%                            or if 'VariableNames' NV-pair is provided by user.
%                          User can override this logic by explicitly passing true/false.
%     'SelectedVariableNames': Cell array of variable names to read.
%     'TreatAsMissing': Text to treat as missing, e.g., 'NA'. Default 'NA'.
%     'OutputType': 'tall' (default) or 'datastore'.
%     'VariableNames': Directly provide variable names (cellstr). Overrides headerParser names.
%     'VariableUnits': Directly provide variable units (cellstr). Overrides headerParser units.
%
% Outputs:
%   ds - MATLAB datastore or tall table, depending on 'OutputType'.
%   dsMeta - Structure containing metadata from headerParser (variableNames,
%            variableUnits, delimiter, numHeaderLinesTotal, dataStartLine, etc.).

    p = inputParser;
    addRequired(p, 'filename', @(x) ischar(x) || isstring(x));
    addParameter(p, 'NumHeaderLines', -1, @isnumeric); % User's desired number of *content* headers (names, units)
    addParameter(p, 'Delimiter', '', @(x) ischar(x) || isstring(x));
    addParameter(p, 'ReadVariableNames', [], @islogical); % Let logic below decide if empty
    addParameter(p, 'SelectedVariableNames', {}, @iscellstr);
    addParameter(p, 'TreatAsMissing', 'NA', @(x) ischar(x) || isstring(x));
    addParameter(p, 'OutputType', 'tall', @(x) ismember(lower(x), {'tall', 'datastore'}));
    addParameter(p, 'TextscanFormats', {}, @iscellstr);
    addParameter(p, 'VariableNames', {}, @iscellstr); % User override for names
    addParameter(p, 'VariableUnits', {}, @iscellstr); % User override for units
    % 'HeaderLinesSource' and 'HeaderLinesUnits' are not directly used by datastore,
    % but headerParser might use them if it were more complex.
    % For now, NumHeaderLines covers the content header lines.

    parse(p, filename, varargin{:});

    filename = char(p.Results.filename);
    numContentHeaderLinesUserOpt = p.Results.NumHeaderLines; % User's desired *content* header lines
    delimiterUserOpt = char(p.Results.Delimiter);
    readVarNamesUserOpt = p.Results.ReadVariableNames; % User's explicit true/false for ReadVariableNames
    outputType = lower(p.Results.OutputType);

    % --- Use headerParser to get metadata ---
    parserArgs = {};
    % Pass user's NumHeaderLines option to headerParser
    parserArgs = [parserArgs, {'NumHeaderLines', numContentHeaderLinesUserOpt}];

    if ~isempty(delimiterUserOpt)
        parserArgs = [parserArgs, {'Delimiter', delimiterUserOpt}];
    else
        % If user didn't specify, headerParser will use its default/preference or detect
        parserArgs = [parserArgs, {'Delimiter', getpref('DataImport','Delimiter',',')}];
    end

    dsMeta = headerParser(filename, parserArgs{:});

    if ~isempty(dsMeta.errorMsg) && ~strcmpi(dsMeta.errorMsg, 'File is empty.')
        warning('ingestData:HeaderParseWarning', 'Header parsing issue: %s. Proceeding with parsed/default values for datastore.', dsMeta.errorMsg);
    elseif isempty(dsMeta.errorMsg) && dsMeta.isAmbiguous
        warning('ingestData:HeaderParseAmbiguous', 'Header parsing was ambiguous. Review dsMeta and datastore properties.');
    end

    % Override with user-provided names/units if given
    if ~isempty(p.Results.VariableNames)
        dsMeta.variableNames = p.Results.VariableNames;
        if length(dsMeta.variableNames) ~= length(dsMeta.variableUnits) && ~isempty(dsMeta.variableUnits)
             dsMeta.variableUnits = repmat({''},1, length(dsMeta.variableNames)); % Reset units if names changed length
        elseif isempty(dsMeta.variableUnits) && ~isempty(dsMeta.variableNames)
             dsMeta.variableUnits = repmat({''},1, length(dsMeta.variableNames));
        end
    end
    if ~isempty(p.Results.VariableUnits)
        dsMeta.variableUnits = p.Results.VariableUnits;
        if length(dsMeta.variableNames) ~= length(dsMeta.variableUnits) && ~isempty(dsMeta.variableNames)
            % This case is tricky; names usually dictate columns.
            % If units length doesn't match names, units might be misaligned.
            warning('ingestData:UserUnitNameMismatch', 'User-provided VariableUnits length does not match VariableNames length. Units might be misaligned.');
        end
    end


    % --- Configure Datastore Options ---
    numHeaderLinesForDS_actual = dsMeta.numHeaderLinesTotal; % Total lines to skip (comments + content headers)
    delimiterForDS_actual = dsMeta.delimiter;

    % Determine ReadVariableNames for datastore
    if ~isempty(readVarNamesUserOpt) % User explicitly set it
        readVarNamesForDS_actual = readVarNamesUserOpt;
    else % Auto-determine based on headerParser results and user overrides
        if ~isempty(p.Results.VariableNames) % User provided names, so datastore should not read them
            readVarNamesForDS_actual = false;
        elseif dsMeta.numContentHeaderLinesDetected > 0 && ~isempty(dsMeta.variableNames) && ~all(cellfun(@isempty, dsMeta.variableNames))
            % If headerParser found content headers and extracted names
            readVarNamesForDS_actual = true;
        else
            readVarNamesForDS_actual = false; % Default to false if no clear headers/names found by parser
        end
    end

    % If ReadVariableNames is false, we might need to provide VariableNames to the datastore
    % This is especially true if headerParser generated Var1, Var2, etc.
    varNamesForDS_param = {};
    if ~readVarNamesForDS_actual && ~isempty(dsMeta.variableNames) && ~all(cellfun(@isempty, dsMeta.variableNames))
        varNamesForDS_param = dsMeta.variableNames;
    end

    dsOpts = {filename};
    dsOpts = [dsOpts, {'TreatAsMissing', p.Results.TreatAsMissing}];
    dsOpts = [dsOpts, {'Delimiter', delimiterForDS_actual}];
    dsOpts = [dsOpts, {'NumHeaderLines', numHeaderLinesForDS_actual}]; % This is total lines to skip
    dsOpts = [dsOpts, {'ReadVariableNames', readVarNamesForDS_actual}];

    if ~readVarNamesForDS_actual && ~isempty(varNamesForDS_param)
        dsOpts = [dsOpts, {'VariableNames', varNamesForDS_param}];
    end

    if ~isempty(p.Results.SelectedVariableNames)
        dsOpts = [dsOpts, {'SelectedVariableNames', p.Results.SelectedVariableNames}];
    end

    if ~isempty(p.Results.TextscanFormats)
        dsOpts = [dsOpts, {'TextscanFormats', p.Results.TextscanFormats}];
    end

    % --- Create Datastore ---
    try
        fprintf('Creating datastore with NumHeaderLines (total to skip): %d, Delimiter: ''%s'', ReadVariableNames: %d\n', ...
            numHeaderLinesForDS_actual, delimiterForDS_actual, readVarNamesForDS_actual);
        if ~readVarNamesForDS_actual && ~isempty(varNamesForDS_param)
            fprintf('Providing VariableNames to datastore explicitly.\n');
        end

        ds0 = datastore(dsOpts{:});

        % If ReadVariableNames was false, but ds0 still got default names (Var1, etc.)
        % AND we have better names from headerParser (which could also be Var1, Var2 if it generated them)
        % ensure dsMeta reflects the names that will actually be used.
        if ~readVarNamesForDS_actual && ~isempty(ds0.VariableNames)
            % If user provided names, those are in dsMeta.variableNames already.
            % If headerParser provided names (even generated ones), those are in dsMeta.variableNames.
            % This step ensures dsMeta.variableNames is consistent with what ds0 ends up with if we didn't provide them.
            % However, if varNamesForDS_param was used, ds0.VariableNames should match it.
            if isempty(varNamesForDS_param) && ~isequal(dsMeta.variableNames, ds0.VariableNames)
                 % This might happen if headerParser found no names, and we didn't provide any,
                 % so datastore generated its own Var1, Var2...
                 dsMeta.variableNames = ds0.VariableNames;
                 if length(dsMeta.variableUnits) ~= length(dsMeta.variableNames)
                     dsMeta.variableUnits = repmat({''}, 1, length(dsMeta.variableNames));
                 end
            end
        elseif readVarNamesForDS_actual && ~isempty(ds0.VariableNames)
            % Datastore read names, update dsMeta if they differ (e.g. due to auto-modification)
            if ~isequal(dsMeta.variableNames, ds0.VariableNames)
                fprintf('Datastore modified variable names. Updating metadata.\n');
                dsMeta.variableNames = ds0.VariableNames;
                 if length(dsMeta.variableUnits) ~= length(dsMeta.variableNames)
                     dsMeta.variableUnits = repmat({''}, 1, length(dsMeta.variableNames));
                 end
            end
        end

    catch ME
        warning('ingestData:DatastoreCreationError', 'Error creating datastore: %s. Check file format and options.', ME.message);
        fprintf('Attempted datastore options:\n');
        disp(dsOpts');
        ds = [];
        % dsMeta is already initialized, but ensure error is propagated if not already there
        if isempty(dsMeta.errorMsg), dsMeta.errorMsg = ME.message; end
        return;
    end

    % Handle empty file case: datastore is created, but will read as empty.
    if strcmpi(dsMeta.errorMsg, 'File is empty.')
        if strcmp(outputType, 'tall')
            try
                % Create an empty tall table with variable names if known
                if ~isempty(dsMeta.variableNames) && ~all(cellfun(@isempty, dsMeta.variableNames))
                    % Create a 0-row table with the correct variable names
                    emptyTbl = cell2table(cell(0, length(dsMeta.variableNames)), 'VariableNames', dsMeta.variableNames);
                    ds = tall(emptyTbl);
                else
                    ds = tall(table()); % Generic empty tall table
                end
            catch ME_empty_tall
                warning('ingestData:EmptyTallError', 'Could not create empty tall array: %s. Returning empty table.', ME_empty_tall.message);
                ds = table();
            end
        else % outputType is 'datastore'
            ds = ds0; % Return the empty datastore
        end
        fprintf('Ingestion complete (empty file). Output type: %s.\n', class(ds));
        return;
    end


    % --- Convert to Tall Array if specified ---
    if strcmp(outputType, 'tall')
        try
            tallDs = tall(ds0);

            % Ensure variable names and units from dsMeta are on the tall array
            % (especially if ds0 had default Var1, Var2 names but dsMeta has better ones)
            if ~isempty(dsMeta.variableNames) && ~all(cellfun(@isempty, dsMeta.variableNames))
                if width(tallDs) == length(dsMeta.variableNames)
                    tallDs.Properties.VariableNames = dsMeta.variableNames;
                else
                    warning('ingestData:VarNameMismatchTallFinal', ...
                        'Number of metadata variable names (%d) does not match tall array width (%d). Names not assigned.', ...
                        length(dsMeta.variableNames), width(tallDs));
                end
            end

            if ~isempty(dsMeta.variableUnits) && ~all(cellfun(@isempty, dsMeta.variableUnits))
                if width(tallDs) == length(dsMeta.variableUnits)
                    try
                        tallDs.Properties.VariableUnits = dsMeta.variableUnits;
                    catch ME_units
                         warning('ingestData:VarUnitAssignErrorTallFinal', 'Could not assign variable units to tall array: %s', ME_units.message);
                    end
                else
                     warning('ingestData:VarUnitMismatchTallFinal', ...
                        'Number of metadata variable units (%d) does not match tall array width (%d). Units not assigned.', ...
                        length(dsMeta.variableUnits), width(tallDs));
                end
            end
            ds = tallDs;
        catch ME_tall
            warning('ingestData:TallConversionError', 'Error converting datastore to tall array: %s. Returning datastore instead.', ME_tall.message);
            ds = ds0; % Fallback to returning the datastore
            % Ensure dsMeta reflects the datastore's actual names if tall conversion failed
            if ~isempty(ds0.VariableNames) && ~isequal(dsMeta.variableNames, ds0.VariableNames)
                dsMeta.variableNames = ds0.VariableNames;
                 if length(dsMeta.variableUnits) ~= length(dsMeta.variableNames)
                     dsMeta.variableUnits = repmat({''}, 1, length(dsMeta.variableNames));
                 end
            end
        end
    else % OutputType is 'datastore'
        ds = ds0;
        % Ensure dsMeta reflects the datastore's actual names
        if ~isempty(ds0.VariableNames) && ~isequal(dsMeta.variableNames, ds0.VariableNames)
            dsMeta.variableNames = ds0.VariableNames;
            if length(dsMeta.variableUnits) ~= length(dsMeta.variableNames)
                 dsMeta.variableUnits = repmat({''}, 1, length(dsMeta.variableNames));
            end
        end
    end

    fprintf('Ingestion complete. Output type: %s.\n', class(ds));
    if isa(ds, 'tall') && isprop(ds,'Properties') && ~isempty(ds.Properties.VariableNames)
        disp('Variable names in tall array:');
        disp(ds.Properties.VariableNames);
    elseif isa(ds,'matlab.io.datastore.TabularTextDatastore') && isprop(ds, 'VariableNames') && ~isempty(ds.VariableNames)
        disp('Variable names in datastore:');
        disp(ds.VariableNames);
    end
end
