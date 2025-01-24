function sample_mat_creator()
    % sample_mat_creator.m
    %
    % CU Boulder METALS Project
    % Comments updated: 01/13/2025
    % Samuel Hatton
    %
    %
    % Inputs
    %     None          Interactive specimen selection through sample_select
    % Outputs
    %     None          Creates MAT file with specimen data
    % Methodology
    %     1. Prompts user to select specimen folders
    %     2. Loads sample data for selected specimens
    %     3. Saves data and specimen count to MAT file
    % Dependencies
    %     sample_select    Custom function
    %     load_sample      Custom function

    [selpath,spec_list] = sample_select;
    [data,specCount] = load_sample(selpath,spec_list,1);

    uisave({'data','specCount'},'sample');

end


