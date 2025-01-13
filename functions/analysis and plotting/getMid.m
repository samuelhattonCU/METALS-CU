function midpoint = getMid(data)
    % getMid.m
    %
    % CU Boulder METALS Project
    % Comments updated: 01/13/2025
    % Samuel Hatton
    %
    %
    % Inputs
    %     data          Structure containing uplt fields (xdat, ydat, cdat)
    %                   for contour visualization
    % Outputs
    %     midpoint      2-element vector [x,y] containing midpoint coordinates
    %                   calculated from user-selected corner points
    % Methodology
    %     1. Displays contour plot using provided data
    %     2. Prompts user to select 4 corner points interactively
    %     3. Calculates midpoint as average of corner coordinates
    % Dependencies
    %     None
    f = figure;
    contourf(data.uplt.xdat,data.uplt.ydat,data.uplt.cdat)
    title("Click the 4 corners of the middle area")

    corners = zeros(4,2);
    for i = 1:4
        pt = drawpoint;
        corners(i,:) = pt.Position;
    end
    close(f);

    mpx = mean(corners(:,1));
    mpy = mean(corners(:,2));
    midpoint = [mpx,mpy];

end
