% src/headerParser.m
function meta = headerParser(filename, varargin)
%HEADERPARSER Detect and parse headers, units, and comments from a text file.
%   META = HEADERPARSER(FILENAME) attempts to automatically detect the
%   delimiter and header lines.
%
%   META = HEADERPARSER(FILENAME, 'NumHeaderLines', VAL, 'Delimiter', CHAR)
%   allows specifying the number of header lines and the delimiter.
%
% Outputs:
%   meta - Struct with fields:
%       variableNames  - 1xN cell array of char, column names.
%       variableUnits  - 1xN cell array of char, units for each column.
%       commentLines   - Cell array of char, full-line comments.
%       rawHeaderLines - Cell array of the original header lines.
%       numHeaderLines - Integer, number of lines treated as header/comments.
%       delimiter      - Char, the detected or specified delimiter.
%       dataStartLine  - Integer, 1-based index of the first data row.
%       isAmbiguous    - Logical, true if parsing might be ambiguous without user input.
%       errorMsg       - Char, error message if parsing failed.

    % Default values
    defaultNumHeaderLines = -1; % -1 for auto-detect
    defaultDelimiter = getpref('DataImport', 'Delimiter', ','); % Default from prefs or ','

    p = inputParser;
    addRequired(p, 'filename', @(x) ischar(x) || isstring(x));
    addParameter(p, 'NumHeaderLines', defaultNumHeaderLines, @(x) isnumeric(x) && isscalar(x));
    addParameter(p, 'Delimiter', defaultDelimiter, @(x) ischar(x) || isstring(x));
    addParameter(p, 'CommentStyle', {'%', '#'}, @(x) iscellstr(x) || ischar(x) || isstring(x)); % Common comment styles
    parse(p, filename, varargin{:});

    filename = char(p.Results.filename);
    numHeaderLinesOpt = p.Results.NumHeaderLines;
    delimiter = char(p.Results.Delimiter);
    commentStyles = cellstr(p.Results.CommentStyle);

    % Initialize output structure
    meta = struct(...
        'variableNames', {{}}, ...
        'variableUnits', {{}}, ...
        'commentLines', {{}}, ...
        'rawHeaderLines', {{}}, ...
        'numHeaderLines', 0, ...
        'delimiter', delimiter, ...
        'dataStartLine', 1, ...
        'isAmbiguous', false, ...
        'errorMsg', '');

    numCols = 0; % Initialize numCols

    if ~isfile(filename)
        meta.errorMsg = sprintf('File not found: %s', filename);
        warning('headerParser:FileNotFound', meta.errorMsg);
        return;
    end

    % Try to open the file
    fid = fopen(filename, 'rt');
    if fid == -1
        meta.errorMsg = sprintf('Could not open file: %s', filename);
        warning('headerParser:FileOpenError', meta.errorMsg);
        return;
    end
    closer = onCleanup(@() fclose(fid)); % Ensure file is closed

    % Read lines to infer structure if NumHeaderLines is not set or auto-detect
    % Let's read a few lines to inspect, e.g., up to 10 lines or until data seems to start
    linesToInspect = 20;
    inspectedLines = cell(linesToInspect, 1);
    actualLinesRead = 0;
    for i = 1:linesToInspect
        line = fgetl(fid);
        if ~ischar(line) % EOF
            break;
        end
        inspectedLines{i} = line;
        actualLinesRead = i;
    end
    inspectedLines = inspectedLines(1:actualLinesRead);

    if isempty(inspectedLines)
        meta.errorMsg = 'File is empty.';
        warning('headerParser:EmptyFile', meta.errorMsg);
        return;
    end

    % --- Delimiter Detection (if not specified or if auto was forced by numHeaderLinesOpt == -1) ---
    % Basic delimiter detection: count occurrences of common delimiters in non-comment lines
    if numHeaderLinesOpt == -1 || strcmp(delimiter, '') % Auto-detect delimiter if not set or if full auto mode
        potentialDelimiters = {',', '\t', ';', ' '};
        delimiterCounts = zeros(size(potentialDelimiters));
        nonCommentLineFound = false;
        for i = 1:actualLinesRead
            currentLine = strtrim(inspectedLines{i});
            isComment = false;
            for cs_idx = 1:length(commentStyles)
                if startsWith(currentLine, commentStyles{cs_idx})
                    isComment = true;
                    break;
                end
            end
            if ~isComment && ~isempty(currentLine)
                nonCommentLineFound = true;
                for d_idx = 1:length(potentialDelimiters)
                    delimiterCounts(d_idx) = delimiterCounts(d_idx) + length(strfind(currentLine, potentialDelimiters{d_idx}));
                end
            end
        end

        if nonCommentLineFound && any(delimiterCounts > 0)
            [~, bestDelimiterIdx] = max(delimiterCounts);
            meta.delimiter = potentialDelimiters{bestDelimiterIdx};
            delimiter = meta.delimiter; % Update local delimiter
        else
            % If no delimiters found or only comments, stick to preference or default comma
            meta.delimiter = getpref('DataImport', 'Delimiter', ',');
            delimiter = meta.delimiter;
            if ~nonCommentLineFound
                 meta.isAmbiguous = true; % Could be all comments or non-delimited data
            end
        end
    end


    % --- Header, Comment, and Data Start Line Detection ---
    currentLineIdx = 0;
    dataLinesFound = 0;
    potentialHeaderLines = {};
    firstNumericLineIdx = -1;

    for i = 1:actualLinesRead
        currentLineIdx = i;
        line = strtrim(inspectedLines{i});
        meta.rawHeaderLines{end+1} = inspectedLines{i}; % Store raw line

        % Check for comments
        isComment = false;
        for cs_idx = 1:length(commentStyles)
            if startsWith(line, commentStyles{cs_idx})
                meta.commentLines{end+1} = line;
                isComment = true;
                break;
            end
        end
        if isComment
            continue; % Move to next line
        end

        % If numHeaderLinesOpt is specified by user (and >= 0)
        if numHeaderLinesOpt >= 0
            if i <= numHeaderLinesOpt
                potentialHeaderLines{end+1} = line;
            else
                if firstNumericLineIdx == -1 && isLineNumeric(line, delimiter)
                    firstNumericLineIdx = i;
                end
                dataLinesFound = dataLinesFound + 1;
                if dataLinesFound >= 1 % Found first data line
                    break;
                end
            end
        else % Auto-detecting header lines
            if ~isLineNumeric(line, delimiter) && isempty(strtrim(line)) % Treat empty lines as non-data
                 potentialHeaderLines{end+1} = line; % Could be part of header or just blank
            elseif ~isLineNumeric(line, delimiter)
                potentialHeaderLines{end+1} = line; % Likely a header line
            else
                if firstNumericLineIdx == -1
                    firstNumericLineIdx = i;
                end
                dataLinesFound = dataLinesFound + 1;
                if dataLinesFound >= 1 % Found potential data, assume previous were headers/comments
                    break;
                end
            end
        end
    end

    % Determine dataStartLine
    if firstNumericLineIdx ~= -1
        meta.dataStartLine = firstNumericLineIdx;
    elseif numHeaderLinesOpt >= 0 % User specified header lines, data starts after them
        meta.dataStartLine = numHeaderLinesOpt + length(meta.commentLines) + 1;
        % Adjust if some of the numHeaderLinesOpt were actually comments
        trueHeaderCount = 0;
        processedUpTo = 0;
        tempRawHeaders = {};
        tempComments = {};
        for k=1:actualLinesRead
            l = strtrim(inspectedLines{k});
            isC = false;
            for cs_idx = 1:length(commentStyles)
                if startsWith(l, commentStyles{cs_idx})
                    tempComments{end+1} = l;
                    isC = true;
                    break;
                end
            end
            if ~isC
                tempRawHeaders{end+1} = inspectedLines{k};
                trueHeaderCount = trueHeaderCount + 1;
            end
            processedUpTo = k;
            if trueHeaderCount >= numHeaderLinesOpt && numHeaderLinesOpt > 0
                break;
            end
            if numHeaderLinesOpt == 0 && ~isC % Found a non-comment line, this must be data
                break;
            end
        end
        meta.dataStartLine = processedUpTo + 1;
        if numHeaderLinesOpt == 0 % if user said 0 header lines, data starts at first non-comment
         nonCommentIdx = 0;
         for k=1:actualLinesRead
            l = strtrim(inspectedLines{k});
            isC = false;
            for cs_idx = 1:length(commentStyles)
                if startsWith(l, commentStyles{cs_idx})
                    isC = true;
                    break;
                end
            end
            if ~isC
                nonCommentIdx = k;
                break;
            end
         end
         meta.dataStartLine = max(1, nonCommentIdx); % Ensure it's at least 1
        end

    else % No numeric lines found in inspection, assume data starts after all inspected non-comment lines
        meta.dataStartLine = length(potentialHeaderLines) + length(meta.commentLines) + 1;
        meta.isAmbiguous = true; % No clear data start
        meta.errorMsg = 'Could not reliably determine data start line; no numeric data found in initial inspection.';
    end

    % Refine rawHeaderLines to only include lines before dataStartLine
    if meta.dataStartLine > 1 && meta.dataStartLine <= actualLinesRead +1
        meta.rawHeaderLines = inspectedLines(1:meta.dataStartLine-1);
    elseif meta.dataStartLine == 1
        meta.rawHeaderLines = {};
    else % dataStartLine is beyond what we read, keep all inspected as potential headers/comments
        meta.rawHeaderLines = inspectedLines;
    end

    % Filter out comments from potentialHeaderLines for name/unit parsing
    actualHeadersForParsing = {};
    for i=1:length(potentialHeaderLines)
        isComment = false;
        for cs_idx = 1:length(commentStyles)
            if startsWith(strtrim(potentialHeaderLines{i}), commentStyles{cs_idx})
                isComment = true;
                break;
            end
        end
        if ~isComment && ~isempty(strtrim(potentialHeaderLines{i}))
             actualHeadersForParsing{end+1} = potentialHeaderLines{i};
        end
    end

    % If user specified NumHeaderLines, use that many from actualHeadersForParsing
    if numHeaderLinesOpt >= 0
        numToParse = min(numHeaderLinesOpt, length(actualHeadersForParsing));
        actualHeadersForParsing = actualHeadersForParsing(1:numToParse);
    end


    % Parse variableNames and variableUnits from actualHeadersForParsing
    if ~isempty(actualHeadersForParsing)
        % Try to determine number of columns from the first actual data line if available
        % This helps correctly size headerName/Unit arrays if headers are ragged
        numCols = 0;
        if meta.dataStartLine <= actualLinesRead
            firstDataContentLine = inspectedLines{meta.dataStartLine};
            if ~isempty(strtrim(firstDataContentLine)) % Ensure it's not an empty line mistaken for data
                 try
                    colsFromData = strsplit(firstDataContentLine, delimiter, 'CollapseDelimiters', false);
                    numCols = length(colsFromData);
                 catch
                    % if strsplit fails, maybe it's a very simple file
                    if ~contains(firstDataContentLine, delimiter)
                        numCols = 1;
                    end
                 end
            end
        end

        % If numCols still 0 (e.g. data not in inspectedLines, or empty data line)
        % use the longest header line to determine numCols
        if numCols == 0 && ~isempty(actualHeadersForParsing)
            for k=1:length(actualHeadersForParsing)
                try
                    colsFromHeader = strsplit(actualHeadersForParsing{k}, delimiter, 'CollapseDelimiters', false);
                    if length(colsFromHeader) > numCols
                        numCols = length(colsFromHeader);
                    end
                catch
                     if ~contains(actualHeadersForParsing{k}, delimiter) && numCols <1
                        numCols = 1;
                    end
                end
            end
        end
        if numCols == 0 && numHeaderLinesOpt == 0 % No headers, no data in preview to infer cols
            meta.isAmbiguous = true;
            % Try to infer from the first line if it was considered data but not numeric
             if actualLinesRead > 0 && meta.dataStartLine == 1
                try
                    colsFromFirst = strsplit(inspectedLines{1}, delimiter, 'CollapseDelimiters', false);
                    numCols = length(colsFromFirst);
                catch
                    if ~contains(inspectedLines{1}, delimiter)
                        numCols = 1;
                    end
                end
             end
             if numCols == 0 % Still zero, then it's truly unknown
                meta.errorMsg = [meta.errorMsg, ' Could not determine number of columns.'];
             end
        end


        meta.variableNames = repmat({''}, 1, numCols);
        meta.variableUnits = repmat({''}, 1, numCols);

        if numHeaderLinesOpt == 1 || (numHeaderLinesOpt == -1 && length(actualHeadersForParsing) == 1)
            % Single header line: assume it's names
            names = strsplit(actualHeadersForParsing{1}, delimiter, 'CollapseDelimiters', false);
            for k = 1:min(length(names), numCols)
                meta.variableNames{k} = strtrim(names{k});
            end
        elseif numHeaderLinesOpt >= 2 || (numHeaderLinesOpt == -1 && length(actualHeadersForParsing) >= 2)
            % Two (or more) header lines: assume first is names, second is units
            names = strsplit(actualHeadersForParsing{1}, delimiter, 'CollapseDelimiters', false);
            for k = 1:min(length(names), numCols)
                meta.variableNames{k} = strtrim(names{k});
            end
            units = strsplit(actualHeadersForParsing{2}, delimiter, 'CollapseDelimiters', false);
            for k = 1:min(length(units), numCols)
                meta.variableUnits{k} = strtrim(units{k});
            end
        end
    end

    % Final numHeaderLines is the count of lines before dataStartLine
    meta.numHeaderLines = meta.dataStartLine - 1;

    % If variableNames are all empty, try to generate generic ones like Var1, Var2...
    if all(cellfun(@isempty, meta.variableNames)) && numCols > 0
        meta.variableNames = arrayfun(@(i) sprintf('Var%d', i), 1:numCols, 'UniformOutput', false);
        if numHeaderLinesOpt == 0 % If user said no headers, this is expected.
            meta.isAmbiguous = false; % Not ambiguous if we generated VarNames for 0 headers
        else
            meta.isAmbiguous = true; % Ambiguous if headers were expected but not found/parsed
        end
    end

    % If after all this, dataStartLine implies no data lines were read in inspection,
    % it's ambiguous for datastore unless we tell it numHeaderLines explicitly.
    if meta.dataStartLine > actualLinesRead +1 && isempty(meta.errorMsg)
        meta.isAmbiguous = true;
        meta.errorMsg = 'All inspected lines appear to be headers or comments; data start is beyond initial inspection.';
    end

    % Set numHeaderLines for datastore based on what we determined,
    % this is the crucial value for ingestData.
    % It's the number of lines to skip, including comments before data.
    meta.numHeaderLines = meta.dataStartLine -1;


    % Check if user preference for NumHeaderLines matches detected if auto
    prefNumHeaderLines = getpref('DataImport', 'NumHeaderLines', 0);
    if numHeaderLinesOpt == -1 && meta.numHeaderLines ~= prefNumHeaderLines
        %fprintf('headerParser: Detected %d header lines, preference is %d.\n', meta.numHeaderLines, prefNumHeaderLines);
        % meta.isAmbiguous = true; % Could indicate a mismatch worth noting
    end

end

function isNum = isLineNumeric(line, delimiter)
%ISLINENUMERIC Helper function to check if a line appears to be numeric data.
    isNum = false;
    if isempty(strtrim(line)) % Empty lines are not numeric data
        return;
    end
    try
        parts = strsplit(line, delimiter, 'CollapseDelimiters', false);
        % Attempt to convert first few non-empty parts to numeric
        % If a significant portion can be converted, consider it numeric
        numericParts = 0;
        totalParts = 0;
        for i = 1:min(length(parts), 5) % Check up to 5 parts
            part = strtrim(parts{i});
            if ~isempty(part)
                totalParts = totalParts + 1;
                % Handle common non-numeric but valid in data like "NA", "NaN"
                if any(strcmpi(part, {'NA', 'NaN', 'Inf', '-Inf'}))
                    numericParts = numericParts + 1;
                    continue;
                end
                [~, status] = str2num(part); %#ok<ST2NM>
                if status
                    numericParts = numericParts + 1;
                end
            end
        end
        % Heuristic: if at least half of checked parts are numeric, or first part is numeric
        if totalParts > 0 && (numericParts / totalParts >= 0.5 || (numericParts > 0 && startsWithNumeric(strtrim(parts{1}))))
            isNum = true;
        % Special case: if only one "column" and it's numeric
        elseif totalParts == 1 && numericParts == 1
            isNum = true;
        end
    catch
        % Error during split or conversion, assume not numeric
        isNum = false;
    end
end

function flag = startsWithNumeric(str)
    if isempty(str)
        flag = false;
        return;
    end
    % Check if the string starts with a digit, or +/- followed by a digit.
    pat = '^[\+\-]?\d';
    flag = ~isempty(regexp(str, pat, 'once'));
end
