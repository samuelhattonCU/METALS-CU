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
    sz = size(ext_data);
    if sz(2) == 5
        ext_data.Properties.VariableNames = ["Index","ΔL/L0","ΔL","L1","L0"];
        ext_data.Properties.VariableUnits = ["1","1","mm","mm","mm"];
    elseif sz(2) ==2
        ext_data.Properties.VariableNames = ["Index","ΔL"];
        ext_data.Properties.VariableUnits = ["1","mm"];
    else
        error("Extensometer data load failed: input table doesn't have the expected size (nx5 or nx2)")
    end
end