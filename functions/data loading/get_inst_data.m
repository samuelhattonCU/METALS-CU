function instron_data = get_inst_data
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