function prePIP_loading()
    % prePIP_loading.m
    %
    % CU Boulder METALS Project
    % Comments updated: 01/13/2025
    % Samuel Hatton
    %
    %
    % Inputs
    %     None          Interactive specimen selection through sample_select
    % Outputs
    %     None          Saves data files for each specimen
    % Methodology
    %     1. Prompts user to select specimen folders
    %     2. For each specimen:
    %        - Loads extensometer and Instron data
    %        - Saves data to MAT file with specimen name
    % Dependencies
    %     sample_select    Custom function
    %     get_ext_data     Custom function
    %     get_inst_data    Custom function

    [selpath,spec_list] = sample_select;

    [specCount,~] = size(spec_list);
    for i = 1:specCount
        back = cd(selpath + "\" + spec_list(i,:) + "\Data Export");

        extData = get_ext_data;
        instData = get_inst_data;
        cd(back)
        uisave({'instData'},spec_list(i,:));
    end

    %%

    % % find frame index where sample starts moving
    % start_frame_number = extData.Index(find(table2array(extData(:,3)) > 0.01,1,'first'));
    %
    % % trim extData
    % extData = extData(extData.Index >= start_frame_number,:);
end
