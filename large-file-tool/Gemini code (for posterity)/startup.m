% startup.m
% This script should be placed in a directory that is on MATLAB's search path,
% or in the user's startup directory (see 'userpath' in MATLAB).
% Alternatively, users can run this script manually after opening MATLAB
% or add its containing directory to the path.

fprintf('Executing startup.m for DataImport Toolkit...\n');

% --- Add 'src' directory to path ---
% Assuming this startup.m file is in the project root, and .m files are in 'src/'
projectRoot = fileparts(mfilename('fullpath')); % Gets directory of this startup.m file
srcPath = fullfile(projectRoot, 'src');
testsPath = fullfile(projectRoot, 'tests'); % For test files

if isfolder(srcPath)
    addpath(srcPath);
    fprintf('Added ''%s'' to MATLAB path.\n', srcPath);
else
    warning('startup:srcNotFound', '''src'' directory not found at %s. Functions may not be available.', srcPath);
end

if isfolder(testsPath)
    addpath(testsPath); % Add tests path for running tests easily
    fprintf('Added ''%s'' to MATLAB path.\n', testsPath);
else
    warning('startup:testsNotFound', '''tests'' directory not found at %s.', testsPath);
end


% --- Initialize Default Preferences ---
% This ensures that the 'DataImport' preference group and its default
% values are created if they don't already exist.
try
    configManager('init');
catch ME
    warning('startup:configManagerInitFailed', ...
        'Failed to initialize preferences using configManager: %s\nEnsure configManager.m is in the src directory and on the path.', ...
        ME.message);
end

fprintf('DataImport Toolkit startup complete.\n');

% --- Optional: Run tests ---
% To automatically run tests on startup (can be slow):
% response = input('Do you want to run tests now? (y/n) [n]: ', 's');
% if lower(response) == 'y'
%     fprintf('Running tests...\n');
%     try
%         testResults = runtests(testsPath, 'OutputDetail', 1); % Adjust verbosity as needed
%         disp(testResults);
%     catch ME_test
%         warning('startup:runtestsFailed', 'Error running tests: %s', ME_test.message);
%     end
% else
%     fprintf('Skipping tests. You can run them manually using: runtests(''%s'')\n', testsPath);
% end

% --- Optional: Display Welcome Message or Help ---
% disp('Type ''help ingestData'', ''help runPipeline'', etc. for function details.');

clear projectRoot srcPath testsPath; % Clean up temporary variables
