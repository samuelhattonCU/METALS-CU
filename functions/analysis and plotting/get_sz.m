function [sz,xvec,yvec] = get_sz(data,step)
    % get_sz.m
    %
    % CU Boulder METALS Project
    % Comments updated: 01/13/2025
    % Samuel Hatton
    %
    %
    % Inputs
    %     data          Structure containing x and y coordinate data
    %     step          (Optional) Step size for vector generation. Default = 5
    % Outputs
    %     sz            Size vector [length(xvec), length(yvec)]
    %     xvec          Vector of x coordinates with specified step size
    %     yvec          Vector of y coordinates with specified step size
    % Methodology
    %     1. Finds min/max values of x and y coordinates
    %     2. Creates vectors spanning coordinate ranges with specified step size
    %     3. Returns size vector and coordinate vectors
    % Dependencies
    %     None

    if ~exist("step",'var')
        step = 5;
    end
    % get frame size:
    min_x = min(data.x);
    max_x = max(data.x);
    min_y = min(data.y);
    max_y = max(data.y);

    % akshat used a step size of 7 for this data:
    % step = 7;

    yvec = min_y:step:max_y;
    xvec = min_x:step:max_x;

    sz = [length(xvec),length(yvec)];
end
