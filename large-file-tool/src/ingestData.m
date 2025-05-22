% src/ingestData.m
function ds = ingestData(filename, varargin)
%INGESTDATA Create a datastore for large CSV/TSV files, possibly tall.
%   DS = INGESTDATA(FILENAME) creates a datastore from FILENAME.
%   It uses headerParser to determine file structure if not specified.
%
%   DS = INGESTDATA(FILENAME, 'NumHeaderLines', VAL, 'Delimiter', CHAR, ...)
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

    p = inputParser;
    addRequired(p, 'filename', @(x) ischar(x) || isstring(x));
    addParameter(p, 'NumHeaderLines', getpref('DataImport', 'NumHeaderLines', -1), @isnumeric); % -1 for auto from headerParser
    addParameter(p, 'Delimiter', getpref('DataImport', 'Delimiter', ''), @(x) ischar(x) || isstring(x)); % '' for auto from headerParser
    addParameter(p, 'ReadVariableNames', [], @islogical); % Let headerParser decide if empty
    addParameter(p, 'SelectedVariableNames', {}, @iscellstr);
    addParameter(p, 'TreatAsMissing', 'NA', @(x) ischar(x) || isstring(x));
    addParameter(p, 'OutputType', 'tall', @(x) ismember(lower(x), {'tall', 'datastore'}));
    addParameter(p, 'TextscanFormats', {}, @iscellstr); % For explicit format strings
    addParameter(p, 'VariableNames', {}, @iscellstr);
    addParameter(p, 'VariableUnits', {}, @iscellstr);
    addParameter(p, 'HeaderLinesSource', [], @isnumeric); % For headerParser: line number of names
    addParameter(p, 'HeaderLinesUnits', [], @isnumeric); % For headerParser: line number of units

    parse(p, filename, varargin{:});

    filename = char(p.Results.filename);
    numHeaderLinesUser = p.Results.NumHeaderLines;
    delimiterUser = char(p.Results.Delimiter);
    readVarNamesUser = p.Results.ReadVariableNames;
    outputType = lower(p.Results.OutputType);

    % --- Use headerParser to get metadata ---
    parserArgs = {};
    if numHeaderLinesUser ~= -1 % User specified NumHeaderLines for ingestData
        parserArgs = [parserArgs, {'NumHeaderLines', numHeaderLinesUser}];
    else % Use preference if available and not -1 (auto)
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

    if ~isempty(meta.errorMsg)
        warning('ingestData:HeaderParseError', 'Header parsing failed or was ambiguous: %s. Using fallback settings for datastore.', meta.errorMsg);
        % Fallback if parser failed significantly
        numHeaderLinesForDS = max(0, numHeaderLinesUser); % Use user input or 0
        delimiterForDS = delimiterUser;
        if isempty(delimiterForDS), delimiterForDS = ','; end
        readVarNamesForDS = ~isempty(readVarNamesUser) && readVarNamesUser;
        varNamesForDS = p.Results.VariableNames;
    else
        numHeaderLinesForDS = meta.numHeaderLines;
        delimiterForDS = meta.delimiter;
        % Decide on ReadVariableNames for datastore
        if ~isempty(readVarNamesUser)
            readVarNamesForDS = readVarNamesUser;
        else
            % If headerParser found names (and numHeaderLinesOpt was not 0), set true
            % And the first line of actual headers is not empty
            readVarNamesForDS = numHeaderLinesForDS > 0 && ...
                                ~isempty(meta.variableNames) && ...
                                ~all(cellfun(@isempty, meta.variableNames)) && ...
                                ( (numHeaderLinesUser ~=0 ) || ... % if user specified >0 headers
                                  (numHeaderLinesUser == -1 && meta.numHeaderLines >0 && ~isempty(meta.rawHeaderLines) && ~isempty(strtrim(meta.rawHeaderLines{1}))) ... % or auto detect found headers
                                );
             % If user explicitly set NumHeaderLines to 0, ReadVariableNames should be false
             if numHeaderLinesUser == 0
                 readVarNamesForDS = false;
             end
        end
        varNamesForDS = meta.variableNames; % Use names from parser if not overridden
    end

    % Override with user-provided VariableNames if any
    if ~isempty(p.Results.VariableNames)
        varNamesForDS = p.Results.VariableNames;
        readVarNamesForDS = false; % If names are provided directly, datastore shouldn't read them
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
        % If SelectedVariableNames is used, and we provided VariableNames,
        % ensure they are consistent or let datastore handle it.
        % If ReadVariableNames was true, datastore will select from the read names.
    end

    if ~isempty(p.Results.TextscanFormats)
        dsOpts = [dsOpts, {'TextscanFormats', p.Results.TextscanFormats}];
    else
        % Try to infer TextscanFormats if not reading variable names and parser didn't provide enough
        % This is a basic attempt; for complex files, user should specify formats.
        if ~readVarNamesForDS && ~isempty(varNamesForDS)
            % Create a default format string of %q for all, then let datastore auto-type
            % or use %f for numeric-like columns if possible to infer from preview.
            % For simplicity now, let datastore auto-detect types if formats not given.
            % To improve: could run a preview, then set TextscanFormats.
        end
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
        return;
    end

    % Store metadata (parsed names/units) in UserData for later use if not directly in ds
    if ~isempty(meta) && isempty(meta.errorMsg)
        ds0.UserData.headerParserMeta = meta;
        if ~isempty(p.Results.VariableUnits)
             ds0.UserData.headerParserMeta.variableUnits = p.Results.VariableUnits;
        end
    elseif ~isempty(p.Results.VariableNames) || ~isempty(p.Results.VariableUnits)
        ds0.UserData.headerParserMeta = struct();
        ds0.UserData.headerParserMeta.variableNames = p.Results.VariableNames;
        ds0.UserData.headerParserMeta.variableUnits = p.Results.VariableUnits;
        ds0.UserData.headerParserMeta.delimiter = delimiterForDS;
        ds0.UserData.headerParserMeta.numHeaderLines = numHeaderLinesForDS;
    end


    % --- Convert to Tall Array if specified ---
    if strcmp(outputType, 'tall')
        try
            ds = tall(ds0);
            % Attempt to assign variable names to the tall array if they weren't read by datastore
            % but were determined by headerParser or provided by user.
            if ~readVarNamesForDS && ~isempty(varNamesForDS) && ~all(cellfun(@isempty, varNamesForDS))
                try
                    if width(ds) == length(varNamesForDS)
                        ds.Properties.VariableNames = varNamesForDS;
                    else
                        warning('ingestData:VarNameMismatch', ...
                            'Number of parsed/provided variable names (%d) does not match number of columns in tall array (%d). Names not assigned.', ...
                            length(varNamesForDS), width(ds));
                    end
                catch ME_vn
                     warning('ingestData:VarNameAssignError', 'Could not assign variable names to tall array: %s', ME_vn.message);
                end
            end
             % Assign units if available
            if isfield(ds0.UserData, 'headerParserMeta') && isfield(ds0.UserData.headerParserMeta, 'variableUnits') ...
                && ~isempty(ds0.UserData.headerParserMeta.variableUnits)
                try
                    if width(ds) == length(ds0.UserData.headerParserMeta.variableUnits)
                        ds.Properties.VariableUnits = ds0.UserData.headerParserMeta.variableUnits;
                    else
                         warning('ingestData:VarUnitMismatch', ...
                            'Number of parsed/provided variable units (%d) does not match number of columns in tall array (%d). Units not assigned.', ...
                            length(ds0.UserData.headerParserMeta.variableUnits), width(ds));
                    end
                catch ME_vu
                    warning('ingestData:VarUnitAssignError', 'Could not assign variable units to tall array: %s', ME_vu.message);
                end
            end


        catch ME_tall
            warning('ingestData:TallConversionError', 'Error converting datastore to tall array: %s. Returning datastore instead.', ME_tall.message);
            ds = ds0; % Return the datastore itself
        end
    else
        ds = ds0; % Return the datastore
    end

    fprintf('Ingestion complete. Output type: %s.\n', class(ds));
    if isa(ds, 'tall') && ~isempty(ds.Properties.VariableNames)
        disp('Variable names in tall array:');
        disp(ds.Properties.VariableNames);
    elseif isa(ds,'tabularconvertdatastore') && ~isempty(ds.VariableNames)
        disp('Variable names in datastore:');
        disp(ds.VariableNames);
    end

end
