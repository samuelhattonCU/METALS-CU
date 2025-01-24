function instron_data = get_inst_data
    % get_inst_data.m
    %
    % CU Boulder METALS Project
    % Comments updated: 01/13/2025
    % Samuel Hatton
    %
    %
    % Inputs
    %     None          Function searches current directory for data
    % Outputs
    %     instron_data  Table containing Instron test data loaded from CSV file
    %                   with force and displacement measurements
    % Methodology
    %     1. Searches current directory for 'instron_*.csv' files
    %     2. Warns if multiple files found
    %     3. Loads data from first matching file with specific header structure
    %     4. Returns empty array if no files found
    % Dependencies
    %     None

    % assumes it's in a 'Data Export' directory already

    file_list = ls('instron_*.csv');
    if isempty(file_list)
        here = pwd;
        disp("No Instron data files found in '" + string(here) + "', skipping.")
        instron_data = [];
        return
    end
    [l,~] = size(file_list);
    if l > 1
        cf = pwd;
        warning("More than one 'instron_*.csv' file found in target folder '" + string(cf) + "'");
    end
    warning off
    instron_data = readtable(file_list(1,:),'NumHeaderLines',8,"VariableNamesLine",7,"VariableUnitsLine",8);
    warning on
end
