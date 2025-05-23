% src/ingestData.m
function [ds, dsMeta] = ingestData(filename, varargin) % MODIFIED: Added dsMeta output
%INGESTDATA Create a datastore for large CSV/TSV files, possibly tall.
%   [DS, DSMETA] = INGESTDATA(FILENAME) creates a datastore from FILENAME
%   and returns the datastore DS and a metadata structure DSMETA.
%   It uses headerParser to determine file structure if not specified.
%
%   [DS, DSMETA] = INGESTDATA(FILENAME, 'NumHeaderLines', VAL, 'Delimiter', CHAR, ...)
%   allows specifying options for datastore creation.
%
%   Optional Name-Value Pairs:
%     'NumHeaderLines': Number of header lines. If not provided, uses
%                       headerParser or 'DataImport' preference.
%     'Delimiter': Delimiter character. If not provided, uses
%                  headerParser or 'DataImport' preference.
%     'ReadVariableNames': Logical, passed to datastore. If not specified,
%                          determined based on headerParser results.
%     'SelectedVariableNames': Cell array of variable names to read.
%     'TreatAsMissing': Text to treat as missing, e.g., 'NA'. Default 'NA'.
%     'OutputType': 'tall' (default) or 'datastore'.
%     'VariableNames': Directly provide variable names (cellstr).
%     'VariableUnits': Directly provide variable units (cellstr).
%
% Outputs:
%   ds - MATLAB datastore or tall table, depending on 'OutputType'.
%   dsMeta - Structure containing metadata from headerParser (variableNames,
%            variableUnits, delimiter, numHeaderLines, etc.).

    p = inputParser;
    addRequired(p, 'filename', @(x) ischar(x) || isstring(x));
    addParameter(p, 'NumHeaderLines', getpref('DataImport', 'NumHeaderLines', -1), @isnumeric);
    addParameter(p, 'Delimiter', getpref('DataImport', 'Delimiter', ''), @(x) ischar(x) || isstring(x));
    addParameter(p, 'ReadVariableNames', [], @islogical);
    addParameter(p, 'SelectedVariableNames', {}, @iscellstr);
    addParameter(p, 'TreatAsMissing', 'NA', @(x) ischar(x) || isstring(x));
    addParameter(p, 'OutputType', 'tall', @(x) ismember(lower(x), {'tall', 'datastore'}));
    addParameter(p, 'TextscanFormats', {}, @iscellstr);
    addParameter(p, 'VariableNames', {}, @iscellstr);
    addParameter(p, 'VariableUnits', {}, @iscellstr);
    addParameter(p, 'HeaderLinesSource', [], @isnumeric);
    addParameter(p, 'HeaderLinesUnits', [], @isnumeric);

    parse(p, filename, varargin{:});

    filename = char(p.Results.filename);
    numHeaderLinesUser = p.Results.NumHeaderLines;
    delimiterUser = char(p.Results.Delimiter);
    readVarNamesUser = p.Results.ReadVariableNames;
    outputType = lower(p.Results.OutputType);

    % --- Use headerParser to get metadata ---
    parserArgs = {};
    if numHeaderLinesUser ~= -1
        parserArgs = [parserArgs, {'NumHeaderLines', numHeaderLinesUser}];
    else
        prefNumHeaders = getpref('DataImport','NumHeaderLines',0);
        if prefNumHeaders ~= -1
             parserArgs = [parserArgs, {'NumHeaderLines', prefNumHeaders}];
        end
    end

    if ~isempty(delimiterUser)
        parserArgs = [parserArgs, {'Delimiter', delimiterUser}];
    else
        prefDelim = getpref('DataImport','Delimiter',',');
         parserArgs = [parserArgs, {'Delimiter', prefDelim}];
    end

    meta = headerParser(filename, parserArgs{:});

    if ~isempty(meta.errorMsg) && ~strcmp(meta.errorMsg, 'File is empty.')
        warning('ingestData:HeaderParseError', 'Header parsing failed or was ambiguous: %s. Using fallback settings for datastore.', meta.errorMsg);
        numHeaderLinesForDS = max(0, numHeaderLinesUser);
        delimiterForDS = delimiterUser;
        if isempty(delimiterForDS), delimiterForDS = ','; end
        readVarNamesForDS = ~isempty(readVarNamesUser) && readVarNamesUser;
        varNamesForDS = p.Results.VariableNames;
    else
        numHeaderLinesForDS = meta.numHeaderLines;
        delimiterForDS = meta.delimiter;

        if ~isempty(readVarNamesUser)
            readVarNamesForDS = readVarNamesUser;
        else
            readVarNamesForDS = numHeaderLinesForDS > 0 && ...
                                ~isempty(meta.variableNames) && ...
                                ~all(cellfun(@isempty, meta.variableNames)) && ...
                                ( (numHeaderLinesUser ~=0 ) || ...
                                  (numHeaderLinesUser == -1 && meta.numHeaderLines >0 && ~isempty(meta.rawHeaderLines) && ~isempty(strtrim(meta.rawHeaderLines{1}))) ...
                                );
             if numHeaderLinesUser == 0
                 readVarNamesForDS = false;
             end
        end
        varNamesForDS = meta.variableNames;
    end

    if ~isempty(p.Results.VariableNames)
        varNamesForDS = p.Results.VariableNames;
        readVarNamesForDS = false;
    end

    % --- Configure Datastore Options ---
    dsOpts = {filename};
    dsOpts = [dsOpts, {'TreatAsMissing', p.Results.TreatAsMissing}];
    dsOpts = [dsOpts, {'Delimiter', delimiterForDS}];
    dsOpts = [dsOpts, {'NumHeaderLines', numHeaderLinesForDS}];

    if readVarNamesForDS
        dsOpts = [dsOpts, {'ReadVariableNames', true}];
    else
        dsOpts = [dsOpts, {'ReadVariableNames', false}];
        if ~isempty(varNamesForDS) && ~all(cellfun(@isempty, varNamesForDS))
            dsOpts = [dsOpts, {'VariableNames', varNamesForDS}];
        end
    end

    if ~isempty(p.Results.SelectedVariableNames)
        dsOpts = [dsOpts, {'SelectedVariableNames', p.Results.SelectedVariableNames}];
    end

    if ~isempty(p.Results.TextscanFormats)
        dsOpts = [dsOpts, {'TextscanFormats', p.Results.TextscanFormats}];
    end

    % --- Create Datastore ---
    try
        fprintf('Creating datastore with NumHeaderLines: %d, Delimiter: ''%s'', ReadVariableNames: %d\n', ...
            numHeaderLinesForDS, delimiterForDS, readVarNamesForDS);
        if ~readVarNamesForDS && ~isempty(varNamesForDS) && ~all(cellfun(@isempty, varNamesForDS))
            fprintf('Providing VariableNames to datastore.\n');
        end

        ds0 = datastore(dsOpts{:});
    catch ME
        warning('ingestData:DatastoreCreationError', 'Error creating datastore: %s. Check file format and options.', ME.message);
        fprintf('Attempted datastore options:\n');
        disp(dsOpts');
        ds = [];
        dsMeta = struct(); % Return empty struct for meta on error
        return;
    end

    % --- Prepare metadata structure for output ---
    % MODIFIED: This section no longer tries to write to ds0.UserData
    % Instead, it populates dsMeta which is returned by the function.
    dsMeta = struct(...
        'variableNames', {{}}, ...
        'variableUnits', {{}}, ...
        'commentLines', {{}}, ...
        'rawHeaderLines', {{}}, ...
        'numHeaderLines', numHeaderLinesForDS, ...
        'delimiter', delimiterForDS, ...
        'dataStartLine', numHeaderLinesForDS + 1, ...
        'isAmbiguous', true, ...
        'errorMsg', '');

    if ~isempty(meta) && isempty(meta.errorMsg)
        dsMeta = meta; % Use the rich meta from headerParser
        if ~isempty(p.Results.VariableUnits)
            dsMeta.variableUnits = p.Results.VariableUnits;
        end
        dsMeta.numHeaderLines = numHeaderLinesForDS; % Ensure these match datastore config
        dsMeta.delimiter = delimiterForDS;
    elseif ~isempty(p.Results.VariableNames) || ~isempty(p.Results.VariableUnits)
        dsMeta.variableNames = p.Results.VariableNames;
        dsMeta.variableUnits = p.Results.VariableUnits;
        dsMeta.isAmbiguous = false;
    else
        if ~isempty(meta) && ~isempty(meta.errorMsg)
            dsMeta.errorMsg = meta.errorMsg;
        else
            dsMeta.errorMsg = 'No detailed header information determined or provided by user.';
        end
    end

    % --- Convert to Tall Array if specified ---
    if strcmp(outputType, 'tall')
        try
            tallDs = tall(ds0); % Use a new variable name

            finalVarNamesToAssign = dsMeta.variableNames; % Use dsMeta
            finalVarUnitsToAssign = dsMeta.variableUnits; % Use dsMeta

            if ~readVarNamesForDS && ~isempty(finalVarNamesToAssign) && ~all(cellfun(@isempty, finalVarNamesToAssign))
                try
                    if width(tallDs) == length(finalVarNamesToAssign)
                        tallDs.Properties.VariableNames = finalVarNamesToAssign;
                    else
                        warning('ingestData:VarNameMismatchTall', ...
                            'Number of determined variable names (%d) does not match number of columns in tall array (%d). Names not assigned to tall array.', ...
                            length(finalVarNamesToAssign), width(tallDs));
                    end
                catch ME_vn
                     warning('ingestData:VarNameAssignErrorTall', 'Could not assign variable names to tall array: %s', ME_vn.message);
                end
            end

            if ~isempty(finalVarUnitsToAssign) && ~all(cellfun(@isempty, finalVarUnitsToAssign))
                try
                    if width(tallDs) == length(finalVarUnitsToAssign)
                        tallDs.Properties.VariableUnits = finalVarUnitsToAssign;
                    else
                         warning('ingestData:VarUnitMismatchTall', ...
                            'Number of determined variable units (%d) does not match number of columns in tall array (%d). Units not assigned to tall array.', ...
                            length(finalVarUnitsToAssign), width(tallDs));
                    end
                catch ME_vu
                    warning('ingestData:VarUnitAssignErrorTall', 'Could not assign variable units to tall array: %s', ME_vu.message);
                end
            end
            ds = tallDs; % Assign to the main output 'ds'
        catch ME_tall
            warning('ingestData:TallConversionError', 'Error converting datastore to tall array: %s. Returning datastore instead.', ME_tall.message);
            ds = ds0;
        end
    else
        ds = ds0;
    end

    fprintf('Ingestion complete. Output type: %s.\n', class(ds));
    if isa(ds, 'tall') && ~isempty(ds.Properties.VariableNames)
        disp('Variable names in tall array:');
        disp(ds.Properties.VariableNames);
    elseif isa(ds,'matlab.io.datastore.TabularTextDatastore') && isprop(ds, 'VariableNames') && ~isempty(ds.VariableNames)
        disp('Variable names in datastore:');
        disp(ds.VariableNames);
    end
end
