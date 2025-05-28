% data_import_api.m
% API function signatures for numeric data import and processing, with user preferences via MATLAB setpref/getpref.

function [data, headerNames, headerUnits] = read_numeric_file(filename, headerLines, delimiter)
% Reads a numeric data file with optional header lines.
% Inputs:
%   filename    - path to the text file
%   headerLines - number of header rows at top of file (0, 1, or 2)
%   delimiter   - character delimiter (e.g. ',', '\t', ' ')
%                If empty, loads default from preferences ("DataImport", "Delimiter").
%
% Outputs:
%   data        - numeric matrix of file contents (missing entries as NaN)
%   headerNames - 1×N cell array of column names ('' if missing)
%   headerUnits - 1×N cell array of units ('' if missing or headerLines<2)

    if nargin < 3 || isempty(delimiter)
        delimiter = getpref('DataImport', 'Delimiter', ',');
    end
    if nargin < 2 || isempty(headerLines)
        headerLines = getpref('DataImport', 'HeaderLines', 0);
    end

    % TODO: implement parsing logic:
    % 1) Read headerLines rows, split by delimiter
    % 2) Extract headerNames and headerUnits (pad missing with '')
    % 3) Read numeric data, filling missing entries with NaN
    data = []; headerNames = {}; headerUnits = {};
end

function headData = preview_head(data, N)
% Returns the first N rows of data (default N = 200).
    if nargin < 2 || isempty(N)
        N = 200;
    end
    headData = data(1:min(N,end), :);
end

function sparseData = preview_sparse(data, step)
% Returns every 'step'-th row of data (default step = 1000).
    if nargin < 2 || isempty(step)
        step = 1000;
    end
    sparseData = data(1:step:end, :);
end

function filteredData = filter_by_range(data, column, minVal, maxVal)
% Filters rows where data(:,column) is between minVal and maxVal (in seconds).
    mask = data(:,column) >= minVal & data(:,column) <= maxVal;
    filteredData = data(mask, :);
end

function export_to_csv(data, filename)
% Exports numeric data matrix to a CSV file.
    writematrix(data, filename);
end

%% User Preferences Wrappers
function save_user_pref(prefGroup, prefName, prefValue)
% Saves a user preference using MATLAB's setpref.
    setpref(prefGroup, prefName, prefValue);
end

function prefValue = load_user_pref(prefGroup, prefName, defaultValue)
% Loads a user preference using getpref, returns defaultValue if unset.
    prefValue = getpref(prefGroup, prefName, defaultValue);
end

%% Example: initialize default preferences on first use
if ~ispref('DataImport')
    addpref('DataImport', 'Delimiter', ',');
    addpref('DataImport', 'HeaderLines', 0);
end
