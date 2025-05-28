% src/headerParser.m
function meta = headerParser(filename, varargin)
%HEADERPARSER Detect and parse headers, units, and comments from a text file.
%   META = HEADERPARSER(FILENAME) attempts to automatically detect the
%   delimiter and header lines.
%
%   META = HEADERPARSER(FILENAME, 'NumHeaderLines', VAL, 'Delimiter', CHAR)
%   allows specifying the number of header lines (for names/units, after comments)
%   and the delimiter.
%
% Outputs:
%   meta - Struct with fields:
%       variableNames  - 1xN cell array of char, column names.
%       variableUnits  - 1xN cell array of char, units for each column.
%       commentLines   - Cell array of char, full-line comments from the header block.
%       rawHeaderLines - Cell array of the original header lines (comments + content headers).
%       numHeaderLinesTotal - Integer, total number of lines to skip before data (includes all comments and content headers).
%       delimiter      - Char, the detected or specified delimiter.
%       dataStartLine  - Integer, 1-based index of the first data row.
%       isAmbiguous    - Logical, true if parsing might be ambiguous without user input.
%       errorMsg       - Char, error message if parsing failed.
%       numContentHeaderLinesDetected - Number of actual content header lines found.

    % Default values
    defaultNumContentHeaderLinesOpt = -1; % -1 for auto-detect content headers
    defaultDelimiter = getpref('DataImport', 'Delimiter', ',');
    defaultCommentStyles = {'%', '#'};

    p = inputParser;
    addRequired(p, 'filename', @(x) ischar(x) || isstring(x));
    addParameter(p, 'NumHeaderLines', defaultNumContentHeaderLinesOpt, @(x) isnumeric(x) && isscalar(x)); % User's expectation for *content* header lines
    addParameter(p, 'Delimiter', defaultDelimiter, @(x) ischar(x) || isstring(x));
    addParameter(p, 'CommentStyle', defaultCommentStyles, @(x) iscellstr(x) || ischar(x) || isstring(x));
    parse(p, filename, varargin{:});

    filename = char(p.Results.filename);
    numContentHeaderLinesOpt = p.Results.NumHeaderLines; % User's view of how many content headers (names, units)
    userSuppliedDelimiter = char(p.Results.Delimiter);
    commentStyles = cellstr(p.Results.CommentStyle);

    meta = struct(...
        'variableNames', {{}}, ...
        'variableUnits', {{}}, ...
        'commentLines', {{}}, ...
        'rawHeaderLines', {{}}, ...
        'numHeaderLinesTotal', 0, ... % Total lines to skip (comments + content headers)
        'delimiter', userSuppliedDelimiter, ...
        'dataStartLine', 1, ...
        'isAmbiguous', false, ...
        'errorMsg', '', ...
        'numContentHeaderLinesDetected', 0); % Actual content lines found

    if ~isfile(filename)
        meta.errorMsg = sprintf('File not found: %s', filename);
        warning('headerParser:FileNotFound', meta.errorMsg);
        return;
    end

    fid = fopen(filename, 'rt');
    if fid == -1
        meta.errorMsg = sprintf('Could not open file: %s', filename);
        warning('headerParser:FileOpenError', meta.errorMsg);
        return;
    end
    closer = onCleanup(@() fclose(fid));

    linesToInspect = 20; % Max lines to read for inspection
    inspectedLines = cell(linesToInspect, 1);
    actualLinesRead = 0;
    for i_read = 1:linesToInspect
        line = fgetl(fid);
        if ~ischar(line), break; end % EOF
        inspectedLines{i_read} = line;
        actualLinesRead = i_read;
    end
    inspectedLines = inspectedLines(1:actualLinesRead);

    if isempty(inspectedLines)
        meta.errorMsg = 'File is empty.';
        % numHeaderLinesTotal remains 0, dataStartLine remains 1
        return;
    end

    % --- Delimiter Detection ---
    delimiter = userSuppliedDelimiter;
    if isempty(delimiter) || (numContentHeaderLinesOpt == -1 && isempty(userSuppliedDelimiter)) % Auto-detect delimiter if not specified or if auto-detecting headers
        potentialDelimiters = {',', sprintf('\t'), ';', ' '}; % Tab as char
        delimiterCounts = zeros(size(potentialDelimiters));
        nonCommentLineFoundForDelim = false;
        firstNonCommentLineContent = '';

        for i_line = 1:actualLinesRead
            currentLine = strtrim(inspectedLines{i_line});
            isComment = false;
            for cs_idx = 1:length(commentStyles)
                if startsWith(currentLine, commentStyles{cs_idx}), isComment = true; break; end
            end
            if ~isComment && ~isempty(currentLine)
                if ~nonCommentLineFoundForDelim
                    firstNonCommentLineContent = currentLine; % Store first non-comment line for delimiter check
                end
                nonCommentLineFoundForDelim = true;
                % Count delimiters on first few non-comment, non-numeric lines
                if ~isLineNumeric(currentLine, ',') && ~isLineNumeric(currentLine,sprintf('\t')) % Heuristic: count on presumed header lines
                    for d_idx = 1:length(potentialDelimiters)
                        delimiterCounts(d_idx) = delimiterCounts(d_idx) + count(currentLine, potentialDelimiters{d_idx});
                    end
                end
            end
            if nonCommentLineFoundForDelim && i_line > 5 && ~isLineNumeric(currentLine, ',') && ~isLineNumeric(currentLine,sprintf('\t')) % Stop after a few header-like lines
                 break;
            end
        end

        if nonCommentLineFoundForDelim && any(delimiterCounts > 0)
            [~, bestDelimiterIdx] = max(delimiterCounts);
            delimiter = potentialDelimiters{bestDelimiterIdx};
        elseif nonCommentLineFoundForDelim && ~isempty(firstNonCommentLineContent) % Fallback: check first non-comment line if counts are zero (e.g. single column)
             for d_idx = 1:length(potentialDelimiters)
                if contains(firstNonCommentLineContent, potentialDelimiters{d_idx})
                    delimiter = potentialDelimiters{d_idx}; % Simplistic: take first found
                    break;
                end
            end
        end
        % If still no delimiter, stick to user-supplied (empty) or default from preferences later
        if isempty(delimiter), delimiter = defaultDelimiter; end
    end
    meta.delimiter = delimiter;


    % --- Header, Comment, and Data Start Line Detection ---
    currentFileIdx = 0;
    initialCommentBlockLines = 0;
    contentHeaderLinesContent = {}; % Store the actual content of lines identified as content headers

    % Phase 1: Identify initial block of comments
    while currentFileIdx < actualLinesRead
        currentFileIdx = currentFileIdx + 1;
        lineContent = inspectedLines{currentFileIdx};
        trimmedLine = strtrim(lineContent);
        isComment = false;
        for cs_idx = 1:length(commentStyles)
            if startsWith(trimmedLine, commentStyles{cs_idx})
                isComment = true;
                break;
            end
        end
        if isComment
            meta.commentLines{end+1} = lineContent;
            initialCommentBlockLines = initialCommentBlockLines + 1;
        else
            % First non-comment line encountered
            break;
        end
    end

    % At this point, currentFileIdx is on the first non-comment line, or actualLinesRead + 1 if all were comments.
    % initialCommentBlockLines is the count of these initial comments.

    if currentFileIdx > actualLinesRead && initialCommentBlockLines == actualLinesRead
        % All lines inspected were comments
        meta.numHeaderLinesTotal = actualLinesRead;
        meta.dataStartLine = actualLinesRead + 1;
        meta.isAmbiguous = true; % No data found
        meta.errorMsg = 'File contains only comment lines or is empty after comments.';
        % variableNames and variableUnits remain empty
        return;
    end

    % Phase 2: Determine content headers based on numContentHeaderLinesOpt or auto-detection
    if numContentHeaderLinesOpt == 0 % User explicitly states no content headers
        meta.numContentHeaderLinesDetected = 0;
        meta.numHeaderLinesTotal = initialCommentBlockLines;
        meta.dataStartLine = initialCommentBlockLines + 1;

    elseif numContentHeaderLinesOpt > 0 % User specified a number of content header lines
        tempContentHeaderLines = 0;
        lineIdxForContentHeaders = currentFileIdx; % Start from the first non-comment line

        while lineIdxForContentHeaders <= actualLinesRead && tempContentHeaderLines < numContentHeaderLinesOpt
            lineContent = inspectedLines{lineIdxForContentHeaders};
            trimmedLine = strtrim(lineContent);
            isInterspersedComment = false;
            for cs_idx = 1:length(commentStyles)
                if startsWith(trimmedLine, commentStyles{cs_idx})
                    isInterspersedComment = true;
                    break;
                end
            end

            if isInterspersedComment
                meta.commentLines{end+1} = lineContent; % Add to overall comments
                % This comment line also contributes to lines skipped before data
            else
                contentHeaderLinesContent{end+1} = lineContent; %#ok<AGROW>
                tempContentHeaderLines = tempContentHeaderLines + 1;
            end
            lineIdxForContentHeaders = lineIdxForContentHeaders + 1;
        end
        meta.numContentHeaderLinesDetected = tempContentHeaderLines;
        meta.numHeaderLinesTotal = lineIdxForContentHeaders - 1; % All lines up to this point (initial comments + content headers + interspersed comments)
        meta.dataStartLine = meta.numHeaderLinesTotal + 1;

        if meta.numContentHeaderLinesDetected < numContentHeaderLinesOpt
            meta.isAmbiguous = true;
            meta.errorMsg = [meta.errorMsg, sprintf('Expected %d content header lines, found %d. ', numContentHeaderLinesOpt, meta.numContentHeaderLinesDetected)];
        end

    else % Auto-detect content headers (numContentHeaderLinesOpt == -1)
        lineIdxForAutoDetect = currentFileIdx; % Start from the first non-comment line

        while lineIdxForAutoDetect <= actualLinesRead
            lineContent = inspectedLines{lineIdxForAutoDetect};
            trimmedLine = strtrim(lineContent);

            isInterspersedComment = false; % Should not happen if Phase 1 was effective, but check
            for cs_idx = 1:length(commentStyles)
                if startsWith(trimmedLine, commentStyles{cs_idx})
                    isInterspersedComment = true;
                    break;
                end
            end

            if isInterspersedComment
                 meta.commentLines{end+1} = lineContent;
                 % This line will be skipped
            elseif isempty(trimmedLine) || isLineNumeric(trimmedLine, delimiter)
                % Empty line or numeric line signals end of headers
                break;
            else
                % Non-comment, non-empty, non-numeric: treat as content header
                contentHeaderLinesContent{end+1} = lineContent; %#ok<AGROW>
                meta.numContentHeaderLinesDetected = meta.numContentHeaderLinesDetected + 1;
            end
            lineIdxForAutoDetect = lineIdxForAutoDetect + 1;
        end
        meta.numHeaderLinesTotal = lineIdxForAutoDetect - 1;
        meta.dataStartLine = lineIdxForAutoDetect;

        if meta.numContentHeaderLinesDetected == 0 && meta.dataStartLine <= actualLinesRead
            % No content headers found, data starts after initial comments
            meta.numHeaderLinesTotal = initialCommentBlockLines;
            meta.dataStartLine = initialCommentBlockLines + 1;
        end
    end

    % Ensure dataStartLine is at least 1 and not beyond file limits
    meta.dataStartLine = max(1, meta.dataStartLine);
    if actualLinesRead > 0 % Only adjust if file was not empty
      meta.dataStartLine = min(meta.dataStartLine, actualLinesRead + 1); % Cannot start after EOF+1
      meta.numHeaderLinesTotal = meta.dataStartLine -1; % Recalculate total skipped lines
    else % File was empty or became empty after reading
        meta.numHeaderLinesTotal = 0;
        meta.dataStartLine = 1;
    end


    % Store raw header lines (all lines before dataStartLine)
    if meta.numHeaderLinesTotal > 0 && meta.numHeaderLinesTotal <= actualLinesRead
        meta.rawHeaderLines = inspectedLines(1:meta.numHeaderLinesTotal);
    end

    % --- Determine Number of Columns (numCols) ---
    numCols = 0;
    if ~isempty(contentHeaderLinesContent)
        parts = strsplit(contentHeaderLinesContent{1}, delimiter, 'CollapseDelimiters', false);
        numCols = length(parts);
    elseif meta.dataStartLine <= actualLinesRead % Try to infer from first data line if no content headers
        firstDataLineContent = strtrim(inspectedLines{meta.dataStartLine});
        if ~isempty(firstDataLineContent)
            parts = strsplit(firstDataLineContent, delimiter, 'CollapseDelimiters', false);
            numCols = length(parts);
        end
    end

    if numCols == 0 && actualLinesRead > 0 && meta.dataStartLine <= actualLinesRead
        % Fallback if still no columns, e.g. file with only comments and then one empty line before EOF
        % or file with only one column and no clear delimiter usage in headers
        meta.isAmbiguous = true;
        meta.errorMsg = [meta.errorMsg, 'Could not reliably determine number of columns. '];
    end


    % --- Parse variableNames and variableUnits from contentHeaderLinesContent ---
    meta.variableNames = repmat({''}, 1, numCols);
    meta.variableUnits = repmat({''}, 1, numCols);

    if numCols > 0
        if meta.numContentHeaderLinesDetected >= 1
            namesLine = strtrim(contentHeaderLinesContent{1});
            names = strsplit(namesLine, delimiter, 'CollapseDelimiters', false);
            for k_name = 1:min(length(names), numCols)
                cleanName = strtrim(names{k_name});
                if startsWith(cleanName, '"') && endsWith(cleanName, '"') && length(cleanName) > 1
                    cleanName = cleanName(2:end-1);
                end
                % Ensure names are valid MATLAB identifiers, but store potentially modified ones
                % The ingestData function will handle final assignment to table/tall properties
                meta.variableNames{k_name} = cleanName;
            end
        end
        if meta.numContentHeaderLinesDetected >= 2
            unitsLine = strtrim(contentHeaderLinesContent{2});
            units = strsplit(unitsLine, delimiter, 'CollapseDelimiters', false);
            for k_unit = 1:min(length(units), numCols)
                 cleanUnit = strtrim(units{k_unit});
                if startsWith(cleanUnit, '"') && endsWith(cleanUnit, '"') && length(cleanUnit) > 1
                    cleanUnit = cleanUnit(2:end-1);
                end
                meta.variableUnits{k_unit} = cleanUnit;
            end
        end
    end

    % If no actual variable names were parsed (e.g. numContentHeaderLinesOpt=0 or auto-detect found none)
    % and we have columns, generate VarN.
    if numCols > 0 && all(cellfun(@isempty, meta.variableNames))
        for k_vn = 1:numCols
            meta.variableNames{k_vn} = sprintf('Var%d', k_vn);
        end
        if numContentHeaderLinesOpt == 0 % If user said no headers, this is not ambiguous
             meta.isAmbiguous = false;
        elseif numContentHeaderLinesOpt == -1 && meta.numContentHeaderLinesDetected == 0
             meta.isAmbiguous = false; % Auto-detect found no headers, this is expected
        end
    end

    % Final check for ambiguity if no data lines were found in the inspected portion
    if meta.dataStartLine > actualLinesRead && actualLinesRead > 0
        meta.isAmbiguous = true;
        meta.errorMsg = [meta.errorMsg, 'No data lines found within the inspected part of the file. '];
    end

end

% Helper function isLineNumeric
function isNum = isLineNumeric(line, delimiter)
    isNum = false;
    if isempty(strtrim(line)), return; end % Empty lines are not numeric data lines
    try
        parts = strsplit(line, delimiter, 'CollapseDelimiters', false);
        if isempty(parts) || all(cellfun(@isempty, strtrim(parts))) % All parts are empty or whitespace
            return;
        end

        numericPartsCount = 0;
        checkedPartsCount = 0;
        maxPartsToCheck = min(length(parts), 5); % Check up to 5 non-empty parts

        for i = 1:length(parts)
            part = strtrim(parts{i});
            if isempty(part), continue; end % Skip empty parts

            checkedPartsCount = checkedPartsCount + 1;

            % Check for common non-numeric placeholders often found in data
            if any(strcmpi(part, {'NA', 'N/A', 'null', 'NaN', 'Inf', '-Inf', '--', '-', ''}))
                % Consider these as "data-like" rather than purely textual headers
                % For NaN/Inf, str2double will handle them. For others, treat as numeric-like for this check.
                [~, status] = str2double(part);
                if status % if it's a convertible NaN/Inf
                    numericPartsCount = numericPartsCount + 1;
                elseif any(strcmpi(part, {'NA', 'N/A', 'null', '--', '-'})) % Treat specific text missing values as data-like
                    numericPartsCount = numericPartsCount + 1;
                end
                continue;
            end

            % Attempt to convert to number
            [val, status] = str2double(part);
            if status && ~ischar(val) % status is true if conversion is successful
                numericPartsCount = numericPartsCount + 1;
            end
            if checkedPartsCount >= maxPartsToCheck, break; end
        end

        if checkedPartsCount == 0 % Line might have had delimiters but no content between them
            isNum = false;
        else
            % Heuristic: if a good portion of non-empty parts are numeric, it's likely a data line
            if (numericPartsCount / checkedPartsCount) >= 0.6 % More than half are numeric
                isNum = true;
            % Heuristic: if the very first non-empty part is purely numeric (and not just '+', '-', '.')
            elseif numericPartsCount > 0 && checkedPartsCount > 0
                firstNonEmptyPart = '';
                for k_p=1:length(parts)
                    if ~isempty(strtrim(parts{k_p}))
                        firstNonEmptyPart = strtrim(parts{k_p});
                        break;
                    end
                end
                if ~isempty(firstNonEmptyPart) && startsWithNumeric(firstNonEmptyPart)
                    isNum = true;
                end
            end
        end
    catch
        isNum = false; % Error during parsing suggests it's not a simple numeric line
    end
end

% Helper function startsWithNumeric
function flag = startsWithNumeric(str)
    if isempty(str), flag = false; return; end
    % Regex to match a number at the start, including scientific notation, optional sign.
    % Allows for just "." if followed by digits, or digits followed by "."
    pat = '^[\+\-]?(((\d+\.?\d*)|(\d*\.?\d+))([eE][\+\-]?\d+)?)';
    m = regexp(str, pat, 'match', 'once');
    if ~isempty(m)
        % Avoid matching only a sign or only a dot if it's not part of a valid number
        if strcmp(m, '.') || strcmp(m,'+') || strcmp(m,'-') || strcmp(m,'+.') || strcmp(m,'-.')
             % Check if the original string *is* just that, or if there's more
             if length(str) > length(m) && isstrprop(str(length(m)+1),'digit')
                 % e.g. ".1" is valid, but "." is not.
                 % This case is tricky, str2double handles it better.
             else
                flag = false; return;
             end
        end
        % Use str2double to confirm if the matched part is a valid number
        val = str2double(m);
        if ~isnan(val) % str2double returns NaN for non-numeric strings (unless it's 'NaN' itself)
            flag = true;
        else % It could be 'NaN' or 'Inf' text
            if any(strcmpi(m, {'NaN', 'Inf', '-Inf'}))
                flag = true;
            else
                flag = false;
            end
        end
    else
        flag = false;
    end
end

