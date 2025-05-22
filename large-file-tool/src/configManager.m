% src/configManager.m
function varargout = configManager(action, varargin)
%CONFIGMANAGER Manage user preferences for DataImport toolkit.
%   CONFIGMANAGER('set', PREFNAME, PREFVALUE) sets a preference.
%   VALUE = CONFIGMANAGER('get', PREFNAME) gets a preference.
%   VALUE = CONFIGMANAGER('get', PREFNAME, DEFAULTVALUE) gets a preference,
%           returning DEFAULTVALUE if not set.
%   CONFIGMANAGER('init') initializes default preferences if not already set.
%   CONFIGMANAGER('list') lists all current 'DataImport' preferences.
%
% Supported Preferences (within 'DataImport' group):
%   'Delimiter'      - Character for CSV/TSV delimiter (default ',').
%   'NumHeaderLines' - Number of header lines to skip (default 0, or -1 for auto in some contexts).
%   'PreviewHeadN'   - Default number of rows for head preview (default 100).
%   'PreviewSparseStep' - Default step for sparse preview (default 1000).
%   'DefaultPlotXVar' - Default variable name for X-axis in plotData.
%   'DefaultPlotYVar' - Default variable name for Y-axis in plotData.
%   'Verbosity'      - Logging verbosity ('INFO', 'DEBUG', 'NONE'). (Not fully implemented in functions yet)
%
% Example:
%   configManager('set', 'Delimiter', '\t');
%   currentDelimiter = configManager('get', 'Delimiter');
%   configManager('init'); % Ensure defaults are set
%   configManager('list');

    prefGroup = 'DataImport';

    if nargin == 0
        action = 'list'; % Default action if called with no args
    end

    switch lower(action)
        case 'set'
            if nargin < 3
                error('configManager:NotEnoughArgsForSet', 'Usage: configManager(''set'', prefName, prefValue)');
            end
            prefName = varargin{1};
            prefValue = varargin{2};
            try
                setpref(prefGroup, prefName, prefValue);
                fprintf('Preference ''%s'' in group ''%s'' set to: ', prefName, prefGroup);
                disp(prefValue);
                if nargout > 0
                    varargout{1} = true;
                end
            catch ME
                warning('configManager:SetPrefError', 'Error setting preference ''%s'': %s', prefName, ME.message);
                if nargout > 0
                    varargout{1} = false;
                end
            end

        case 'get'
            if nargin < 2
                error('configManager:NotEnoughArgsForGet', 'Usage: configManager(''get'', prefName, [defaultValue])');
            end
            prefName = varargin{1};
            if nargin > 2
                defaultValue = varargin{2};
                prefValue = getpref(prefGroup, prefName, defaultValue);
            else
                prefValue = getpref(prefGroup, prefName); % Errors if not set and no default
            end
            if nargout > 0
                varargout{1} = prefValue;
            else
                disp(prefValue);
            end

        case 'init'
            fprintf('Initializing default preferences for group ''%s'' if not set...\n', prefGroup);
            defaults = {
                'Delimiter', ',', ...
                'NumHeaderLines', 0, ... % 0 means expect data from first line unless parser finds headers
                'PreviewHeadN', 100, ...
                'PreviewSparseStep', 1000, ...
                'DefaultPlotXVar', 'Time', ...
                'DefaultPlotYVar', 'Signal', ...
                'Verbosity', 'INFO' ...
            };

            for i = 1:2:length(defaults)
                prefName = defaults{i};
                defaultValue = defaults{i+1};
                if ~ispref(prefGroup, prefName)
                    setpref(prefGroup, prefName, defaultValue);
                    fprintf('  Set default for ''%s'': ', prefName); disp(defaultValue);
                else
                    fprintf('  Preference ''%s'' already exists: ', prefName); disp(getpref(prefGroup, prefName));
                end
            end
            fprintf('Default preference initialization complete.\n');
            if nargout > 0
                varargout{1} = true;
            end

        case 'list'
            fprintf('Current preferences in group ''%s'':\n', prefGroup);
            if ispref(prefGroup)
                prefs = getpref(prefGroup);
                if isstruct(prefs) && ~isempty(fieldnames(prefs))
                    disp(prefs);
                else
                    fprintf('  No preferences found in this group or group is not a struct.\n');
                end
            else
                fprintf('  Preference group ''%s'' does not exist.\n', prefGroup);
            end
            if nargout > 0
                if ispref(prefGroup)
                    varargout{1} = getpref(prefGroup);
                else
                    varargout{1} = struct();
                end
            end

        case 'clearallforgroup' % Utility, use with caution
            if ispref(prefGroup)
                rmpref(prefGroup);
                fprintf('All preferences for group ''%s'' have been cleared.\n', prefGroup);
            else
                fprintf('Preference group ''%s'' does not exist, nothing to clear.\n', prefGroup);
            end
             if nargout > 0
                varargout{1} = true;
            end

        otherwise
            error('configManager:UnknownAction', 'Unknown action: %s. Valid actions are ''set'', ''get'', ''init'', ''list''.', action);
    end
end
