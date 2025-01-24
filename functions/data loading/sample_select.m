function [selpath,spec_list] = sample_select
    % sample_select.m
    %
    % CU Boulder METALS Project
    % Comments updated: 01/13/2025
    % Samuel Hatton
    %
    %
    % Inputs
    %     None          Interactive dialog-based specimen selection
    % Outputs
    %     selpath       Selected directory path containing specimen data
    %     spec_list     List of selected specimen folders to process
    % Methodology
    %     1. Checks for previously saved selection
    %     2. If using previous: loads saved path and specimen list
    %     3. If new selection:
    %        - Opens folder selection dialog
    %        - Shows specimen list for user selection
    %        - Saves selection for future use
    % Dependencies
    %     None

    codeLoc = fileparts(which('sample_select.m'));
    idx = strfind(codeLoc,'METALS-CU');
    pth = codeLoc(1:idx+length('METALS-CU'));
    local_loc = pth + "local\";

    startLoc = pwd;

    addpath(local_loc)

    if exist('prev_selection.mat','file')
        load("prev_selection.mat");
        answer = questdlg("Use previous sample selction ([" + spec_list + "] from " + selpath + ") or select a new one?", "Folder selection","Previous","New","New");
    else
        answer = "no saved path";
    end
    
    if ~strcmp(answer,'Previous')
        % load("defaultPath.mat");
        % load("prev_selection.mat");
        % codeLoc = cd(selpath);
    % else
        answer = questdlg("Please select the 'Sample' folder you wish to process. For example, 'D:\DATA\METALS\Sample 15\'","Path Selection","Continue","Cancel","Continue");
        if strcmp(answer,"Continue")
            selpath = uigetdir;
            cd(selpath);

            spec_list = ls("Specimen*");
            [idx,tf] = listdlg("PromptString","Select the desired specimens from the list below.",'ListString',spec_list);
            if ~tf
                fprintf("No specimen selection made, defaulting to load all specimens in the sample folder./n")
            else
                spec_list = spec_list(idx,:);
            end

            % save defaultPath.mat selpath
            cd(local_loc)
            save prev_selection.mat selpath spec_list
            cd(startLoc)
        else
            warning("Press 'Continue' to select a new folder, or use the previous selection instead.")
            cd(startLoc)
        end
    end
end
