function ext_data = get_ext_data
    % assumes it's in a 'Data Export' directory already
    
    file_list = ls('*extensometer.csv');
    [l,~] = size(file_list);
    if l > 1
        cf = pwd;
        warning("More than one '*extensometer.csv' file found in target folder '" + string(cf) + "'");
    elseif isempty(file_list)
        cf = pwd;
        warning("No 'extensometer' file found in target folder '" + string(cf) + "'");
        ext_data = [];
        return
    end

    ext_data = readtable(file_list(1,:),'NumHeaderLines',2);
    ext_data.Properties.VariableNames = ["Index","ΔL/L0","ΔL","L1","L0"];
    ext_data.Properties.VariableUnits = ["1","1","mm","mm","mm"];
end