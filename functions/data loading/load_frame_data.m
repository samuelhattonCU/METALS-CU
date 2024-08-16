function frame_data = load_frame_data(file_loc,frame_number)

    oldLoc = cd(file_loc);
    file_name = ls("*" + string(frame_number) + "_0.csv");
    frame_data = readtable(file_name(1,:));
    cd(oldLoc)

end