function frameNum = find_frame(fd,target_disp)
    % find_frame.m
    %
    % CU Boulder METALS Project
    % Comments updated: 01/13/2025
    % Samuel Hatton
    %
    %
    % Inputs
    %     fd            Force-displacement data structure containing Index and
    %                   Displacement fields
    %     target_disp   Target displacement value(s) to find corresponding frames
    % Outputs
    %     frameNum      Frame numbers corresponding to the target displacement(s)
    % Methodology
    %     For each target displacement value, finds the closest matching
    %     displacement in the force-displacement data. Returns the frame index
    %     that corresponds to the closest displacement value.
    % Dependencies
    %     None


    d = fd.Displacement;

    [r,c] = size(target_disp);
    frameNum = zeros(r,c);

    for i = 1:r
        for j = 1:c
            td = target_disp(i,j);
            idx = find(d>td,1,"first");

            if (td - d(idx-1)) < (d(idx) - td)
                idx = idx-1;
            end

            frameNum(i,j) = fd.Index(idx);
        end
    end

end
