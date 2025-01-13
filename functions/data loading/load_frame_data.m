function frame_data = load_frame_data(file_loc,frame_number)
    % load_frame_data.m
    %
    % CU Boulder METALS Project
    % Comments updated: 01/13/2025
    % Samuel Hatton
    %
    %
    % Inputs
    %     file_loc      Directory path containing frame data files
    %     frame_number  Frame number to load from CSV files
    % Outputs
    %     frame_data    Table containing DIC data for specified frame
    % Methodology
    %     1. Changes to specified directory
    %     2. Searches for CSV file matching frame number
    %     3. Loads data from matching file
    %     4. Returns to original directory
    % Dependencies
    %     None

    oldLoc = cd(file_loc);
    file_name = ls("*" + string(frame_number) + "_0.csv");
    frame_data = readtable(file_name(1,:));
    cd(oldLoc)

end
