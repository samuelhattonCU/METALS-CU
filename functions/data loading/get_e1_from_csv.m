function data = get_e1_from_csv(filepath)
    % get_e1_from_csv.m
    %
    % CU Boulder METALS Project
    % Comments updated: 01/13/2025
    % Samuel Hatton
    %
    %
    % Inputs
    %     filepath      Path to CSV file exported from VIC-3D containing
    %                   inspection point data
    % Outputs
    %     data          Table containing e1 strain data from all inspection points
    %                   with point labels and frame index
    % Methodology
    %     1. Reads CSV file with multiple header lines
    %     2. Extracts inspection point data columns
    %     3. Identifies e1 strain columns
    %     4. Renames columns with point numbers
    %     5. Adds frame index column
    % Dependencies
    %     None

    data = readtable(filepath,"NumHeaderLines",2,"VariableNamesLine",2, "VariableDescriptionsLine",1);
    index = table2array(data(:,1));

    firstcol = find(string(data.Properties.VariableDescriptions) == "P0");
    data = data(:,firstcol:end);

    vars = data.Properties.VariableNames;
    vars = string(vars);

    locs = contains(vars,"e1_1");

    desc = string(data.Properties.VariableDescriptions);
    has_desc = desc ~= "";
    point_number = desc(has_desc);
    data = data(:,locs);

    varnames = string(data.Properties.VariableNames);
    for i = 1:width(data)
        nm = varnames(i);
        pnum = point_number(i);
        new_name = nm + "_" + pnum;
        varnames(i) = new_name;
    end
    data.Properties.VariableNames = cellstr(varnames);
    data.Properties.VariableDescriptions = cellstr(point_number(1:width(data)));


    data.index = index;
end
