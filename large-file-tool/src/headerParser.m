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
%       numHeaderLines - Integer, total number of lines to skip before data.
%       delimiter      - Char, the detected or specified delimiter.
%       dataStartLine  - Integer, 1-based index of the first data row.
%       isAmbiguous    - Logical, true if parsing might be ambiguous without user input.
%       errorMsg       - Char, error message if parsing failed.

    % Default values
    defaultNumHeaderLinesOpt = -1; % -1 for auto-detect content headers
    defaultDelimiter = getpref('DataImport', 'Delimiter', ',');
    defaultCommentStyles = {'%', '#'};

    p = inputParser;
    addRequired(p, 'filename', @(x) ischar(x) || isstring(x));
    addParameter(p, 'NumHeaderLines', defaultNumHeaderLinesOpt, @(x) isnumeric(x) && isscalar(x)); % Number of *content* header lines
    addParameter(p, 'Delimiter', defaultDelimiter, @(x) ischar(x) || isstring(x));
    addParameter(p, 'CommentStyle', defaultCommentStyles, @(x) iscellstr(x) || ischar(x) || isstring(x));
    parse(p, filename, varargin{:});

    filename = char(p.Results.filename);
    numContentHeaderLinesOpt = p.Results.NumHeaderLines; % Number of *content* (non-comment) header lines expected
    userSuppliedDelimiter = char(p.Results.Delimiter);
    commentStyles = cellstr(p.Results.CommentStyle);

    meta = struct(...
        'variableNames', {{}}, ...
        'variableUnits', {{}}, ...
        'commentLines', {{}}, ...
        'rawHeaderLines', {{}}, ...
        'numHeaderLines', 0, ...
        'delimiter', userSuppliedDelimiter, ...
        'dataStartLine', 1, ...
        'isAmbiguous', false, ...
        'errorMsg', '');

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

    linesToInspect = 20;
    inspectedLines = cell(linesToInspect, 1);
    actualLinesRead = 0;
    for i_read = 1:linesToInspect
        line = fgetl(fid);
        if ~ischar(line), break; end
        inspectedLines{i_read} = line;
        actualLinesRead = i_read;
    end
    inspectedLines = inspectedLines(1:actualLinesRead);

    if isempty(inspectedLines)
        meta.errorMsg = 'File is empty.';
        return;
    end

    % --- Delimiter Detection ---
    delimiter = userSuppliedDelimiter;
    if isempty(delimiter) || (numContentHeaderLinesOpt == -1 && isempty(userSuppliedDelimiter))
        potentialDelimiters = {',', '\t', ';', ' '};
        delimiterCounts = zeros(size(potentialDelimiters));
        nonCommentLineFoundForDelim = false;

        for i_line = 1:actualLinesRead
            currentLine = strtrim(inspectedLines{i_line});
            isComment = false;
            for cs_idx = 1:length(commentStyles)
                if startsWith(currentLine, commentStyles{cs_idx}), isComment = true; break; end
            end
            if ~isComment && ~isempty(currentLine)
                nonCommentLineFoundForDelim = true;
                for d_idx = 1:length(potentialDelimiters)
                    delimiterCounts(d_idx) = delimiterCounts(d_idx) + count(currentLine, potentialDelimiters{d_idx});
                end
            end
        end

        if nonCommentLineFoundForDelim && any(delimiterCounts > 0)
            [~, bestDelimiterIdx] = max(delimiterCounts);
            delimiter = potentialDelimiters{bestDelimiterIdx};
            if endsWith(lower(filename), '.tsv') % Prefer tab for .tsv files if counts are ambiguous
                tabIdx = find(strcmp(potentialDelimiters, sprintf('\t')));
                if ~isempty(tabIdx) && delimiterCounts(tabIdx) > 0
                    % If tab count is significant, or higher than comma for .tsv
                    commaIdx = find(strcmp(potentialDelimiters, ','));
                    if isempty(commaIdx) || delimiterCounts(tabIdx) >= delimiterCounts(commaIdx)
                        delimiter = sprintf('\t');
                    end
                end
            end
        elseif isempty(delimiter)
             delimiter = ',';
        end
    end
    meta.delimiter = delimiter;

    % --- Header, Comment, and Data Start Line Detection ---
    currentLineIdx = 0;
    initialCommentsCount = 0;
    contentHeadersParsedCount = 0;
    headerContentLinesForParsing = {}; % Actual lines for name/unit parsing

    % Phase 1: Skip all leading comment lines
    while currentLineIdx < actualLinesRead
        currentLineIdx = currentLineIdx + 1;
        lineContent = inspectedLines{currentLineIdx};
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
            initialCommentsCount = initialCommentsCount + 1;
        else
            % First non-comment line encountered, break from initial comment skipping
            break;
        end
    end

    firstNonCommentLineFileIdx = initialCommentsCount + 1;

    % Phase 2: Process content headers or auto-detect
    if numContentHeaderLinesOpt == 0 % User specified NO content headers
        meta.numHeaderLines = initialCommentsCount;
        meta.dataStartLine = firstNonCommentLineFileIdx;
        % headerContentLinesForParsing remains empty

    elseif numContentHeaderLinesOpt > 0 % User specified number of content headers
        currentLineIdx = firstNonCommentLineFileIdx -1; % Reset to line before first non-comment

        while currentLineIdx < actualLinesRead && contentHeadersParsedCount < numContentHeaderLinesOpt
            currentLineIdx = currentLineIdx + 1;
            lineContent = inspectedLines{currentLineIdx};
            trimmedLine = strtrim(lineContent);
            isComment = false; % Check for comments interspersed with content headers
            for cs_idx = 1:length(commentStyles)
                if startsWith(trimmedLine, commentStyles{cs_idx})
                    isComment = true;
                    break;
                end
            end
            if isComment
                meta.commentLines{end+1} = lineContent; % Add to overall comments
                % This comment line also contributes to lines skipped before data
            else
                headerContentLinesForParsing{end+1} = lineContent; %#ok<AGROW>
                contentHeadersParsedCount = contentHeadersParsedCount + 1;
            end
        end
        meta.numHeaderLines = currentLineIdx; % All lines up to this point are skipped
        meta.dataStartLine = meta.numHeaderLines + 1;
        if contentHeadersParsedCount < numContentHeaderLinesOpt && actualLinesRead > 0
             meta.isAmbiguous = true;
             meta.errorMsg = [meta.errorMsg, sprintf(' Expected %d content header lines after initial comments, found %d. ', numContentHeaderLinesOpt, contentHeadersParsedCount)];
        end

    else % Auto-detect content headers (numContentHeaderLinesOpt == -1)
        currentLineIdx = firstNonCommentLineFileIdx -1; % Reset to line before first non-comment

        while currentLineIdx < actualLinesRead
            currentLineIdx = currentLineIdx + 1;
            lineContent = inspectedLines{currentLineIdx};
            trimmedLine = strtrim(lineContent);

            % In auto-detect, we don't expect comments here, they should have been skipped.
            % If a line looks like data, we stop.
            if isLineNumeric(trimmedLine, delimiter) || isempty(trimmedLine) % Empty line also signals end of headers
                meta.dataStartLine = currentLineIdx;
                break;
            else % Non-numeric, non-empty, non-comment: treat as content header
                headerContentLinesForParsing{end+1} = lineContent; %#ok<AGROW>
                contentHeadersParsedCount = contentHeadersParsedCount + 1;
            end
        end
        meta.numHeaderLines = initialCommentsCount + contentHeadersParsedCount;
        if currentLineIdx == actualLinesRead && meta.dataStartLine == 1 % Loop finished, dataStartLine not updated
             meta.dataStartLine = meta.numHeaderLines + 1; % Data starts after all collected headers/comments
        end
        if isempty(headerContentLinesForParsing) && meta.numHeaderLines == initialCommentsCount && actualLinesRead > 0 && firstNonCommentLineFileIdx <= actualLinesRead
            % No textual headers found after initial comments, data starts right after initial comments
            meta.dataStartLine = firstNonCommentLineFileIdx;
            meta.numHeaderLines = initialCommentsCount;
        end
    end

    % Final safety checks and rawHeaderLines
    if actualLinesRead == 0
        meta.numHeaderLines = 0;
        meta.dataStartLine = 1;
    else
        meta.dataStartLine = min(meta.dataStartLine, actualLinesRead + 1);
        meta.numHeaderLines = max(0, meta.dataStartLine - 1);
    end

    if meta.numHeaderLines > 0 && meta.numHeaderLines <= actualLinesRead
        meta.rawHeaderLines = inspectedLines(1:meta.numHeaderLines);
    else
        meta.rawHeaderLines = {};
    end

    % --- Determine Number of Columns (numCols) ---
    numCols = 0;
    candidateCounts = [];
    if meta.dataStartLine <= actualLinesRead && ~isempty(strtrim(inspectedLines{meta.dataStartLine}))
        parts = strsplit(inspectedLines{meta.dataStartLine}, delimiter, 'CollapseDelimiters', false);
        candidateCounts(end+1) = length(parts);
    end
    for k_hclp = 1:length(headerContentLinesForParsing) % Use the actual parsed content header lines
        parts = strsplit(headerContentLinesForParsing{k_hclp}, delimiter, 'CollapseDelimiters', false);
        candidateCounts(end+1) = length(parts);
    end
    if isempty(candidateCounts) && actualLinesRead > 0
        if firstNonCommentLineFileIdx <= actualLinesRead
            line_k = strtrim(inspectedLines{firstNonCommentLineFileIdx});
             if ~isempty(line_k)
                parts = strsplit(line_k, delimiter, 'CollapseDelimiters', false);
                candidateCounts(end+1) = length(parts);
            end
        end
    end
    if ~isempty(candidateCounts), numCols = max(candidateCounts); end

    % --- Parse variableNames and variableUnits ---
    meta.variableNames = repmat({''}, 1, numCols);
    meta.variableUnits = repmat({''}, 1, numCols);

    if numCols > 0
        if ~isempty(headerContentLinesForParsing)
            namesLine = strtrim(headerContentLinesForParsing{1});
            names = strsplit(namesLine, delimiter, 'CollapseDelimiters', false);
            for k_name = 1:min(length(names), numCols)
                cleanName = strtrim(names{k_name});
                % Remove surrounding quotes if present (common in CSV headers)
                if startsWith(cleanName, '"') && endsWith(cleanName, '"') && length(cleanName) > 1
                    cleanName = cleanName(2:end-1);
                end
                meta.variableNames{k_name} = matlab.lang.makeValidName(cleanName);
                if isempty(meta.variableNames{k_name}), meta.variableNames{k_name} = sprintf('Var%d_empty',k_name); end
            end
        end
        if length(headerContentLinesForParsing) >= 2
            unitsLine = strtrim(headerContentLinesForParsing{2});
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

    % Generate VarN if names are still effectively empty
    if numCols > 0 && (all(cellfun(@isempty, meta.variableNames)) || all(startsWith(meta.variableNames, 'Var') & endsWith(meta.variableNames, '_empty')))
        for k_vn = 1:numCols
            meta.variableNames{k_vn} = sprintf('Var%d', k_vn);
        end
         % Reset ambiguity if VarN generation is the expected outcome
        if (numContentHeaderLinesOpt == 0) || (numContentHeaderLinesOpt == -1 && isempty(headerContentLinesForParsing))
            meta.isAmbiguous = false;
        elseif isempty(headerContentLinesForParsing) % Content headers were expected but not found/parsed
            meta.isAmbiguous = true;
        end
    end

    if isempty(meta.errorMsg) && numCols == 0 && actualLinesRead > 0 && ...
       ~(length(meta.commentLines) == actualLinesRead && initialCommentsCount == actualLinesRead)
        meta.errorMsg = 'Could not determine number of columns. File might be malformed or delimiter incorrect.';
        meta.isAmbiguous = true;
    end
end

% Helper function isLineNumeric (retained from previous version, ensure it's robust)
function isNum = isLineNumeric(line, delimiter)
    isNum = false;
    if isempty(strtrim(line)), return; end
    try
        parts = strsplit(line, delimiter, 'CollapseDelimiters', false);
        if isempty(parts) || (length(parts)==1 && isempty(strtrim(parts{1})))
            return;
        end
        numericParts = 0;
        validPartsChecked = 0;
        partsCheckedCount = 0;
        maxPartsToConsider = min(length(parts), 5);

        for i = 1:length(parts)
            if partsCheckedCount >= maxPartsToConsider && validPartsChecked > 0, break; end
            part = strtrim(parts{i});
            if isempty(part), continue; end
            validPartsChecked = validPartsChecked + 1;
            partsCheckedCount = partsCheckedCount +1;
            if any(strcmpi(part, {'NA', 'null', 'NaN', 'Inf', '-Inf'})) % Consider NaN/Inf strings as potentially numeric data
                 % Check if it's a "textual" NaN or a convertible one
                [~, status_nan_inf] = str2num(part); %#ok<ST2NM>
                if status_nan_inf, numericParts = numericParts + 1; end
                continue;
            end
            [val, status] = str2num(part); %#ok<ST2NM>
            if status && ~ischar(val)
                numericParts = numericParts + 1;
            end
        end
        if validPartsChecked > 0
            firstNonEmptyPart = '';
            for k_p = 1:length(parts)
                if ~isempty(strtrim(parts{k_p}))
                    firstNonEmptyPart = strtrim(parts{k_p});
                    break;
                end
            end
            if (numericParts / validPartsChecked >= 0.5)
                isNum = true;
            elseif numericParts > 0 && validPartsChecked > 0 && startsWithNumeric(firstNonEmptyPart)
                isNum = true;
            end
        end
    catch
        isNum = false;
    end
end

% Helper function startsWithNumeric (retained)
function flag = startsWithNumeric(str)
    if isempty(str), flag = false; return; end
    pat = '^[\+\-]?(((\d+\.?\d*)|(\d*\.?\d+))([eE][\+\-]?\d+)?)';
    m = regexp(str, pat, 'match', 'once');
    if ~isempty(m)
        if strcmp(m,'.') || strcmp(m,'+') || strcmp(m,'-') || strcmp(m,'+.') || strcmp(m,'-.')
            flag = false; return;
        end
        % Check if str2double converts it to a non-NaN number, or if it's 'NaN' or 'Inf' text
        val = str2double(m);
        if ~isnan(val) || strcmpi(m, 'NaN') || strcmpi(m, 'Inf') || strcmpi(m, '-Inf')
            flag = true;
        else
            flag = false;
        end
    else
        flag = false;
    end
end
