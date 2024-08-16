function [left_sz, right_sz] = get_lr_sz(data)
% get_lr_sz.m
% 
% CU Boulder METALS Project
% Comments updated: 16 August 2024
% Samuel Hatton
% 
% Inputs
%     data        A Matlab Table representation of a .csv file containing 
%                 all the data export from VIC-3D for a single image frame. 
%                 Must include '.aoi' column.
% Outputs
%     left_sz     A 1x2 vector containing the number of [rows, columns]
%                 that will fit all of the data points in rows of the input
%                 'data' table that have an '.aoi' value of 3 (left).
%     right_sz    A 1x2 vector containing the number of [rows, columns]
%                 that will fit all of the data points in rows of the input
%                 'data' table that have an '.aoi' value of 4 (right).
% 
% Methodology
%     Utilizes the '.aoi' flag to determine left vs. right data. Uses the
%     '.x' and '.y' columns to determin bounds on the data, and then assumes
%     a 5 point step between data points to determine how many rows (x
%     values) and columns (y values) the output matrix needs to have. This
%     operation is done for both left and right datasets, and then the size
%     values are output.
    
    % Separate out left and right specimen sides
    
    left = data(data.aoi == 3,:);
    right = data(data.aoi == 4,:);
    
    % determine matrix side lengths for the left of specimen
    left_minx = min(left.x);
    left_maxx = max(left.x);
    left_miny = min(left.y);
    left_maxy = max(left.y);
    
    % left_xlen = left_maxx - left_minx + 1;
    % left_ylen = left_maxy - left_miny + 1;
    
    % left_ystep = unique(diff(left.y));
    left_ystep = 5;
    % left_ystep = left_ystep(2); % the first is the step between top, bottom? 2nd is the normal step. Could use groupcounts instead if more robustness is needed
    % left_xstep = unique(diff(left.x));
    % left_xstep = left_xstep(2);
    left_xstep = 5;
    %%%%% HARD CODING to simplify, I think the step is always 5 cause those
    %%%%% are our settings in VIC-3D, we're doing 21 pixel areas at 5 pixel
    %%%%% spacing.
    
    left_yvec = left_miny:left_ystep:left_maxy;
    left_xvec = left_minx:left_xstep:left_maxx;
    
    left_ylen = length(left_yvec);
    left_xlen = length(left_xvec);
    
    left_sz = [left_xlen,left_ylen];
    
    % determine matrix side lengths for the right of specimen
    right_minx = min(right.x);
    right_maxx = max(right.x);
    right_miny = min(right.y);
    right_maxy = max(right.y);
    
    % right_xlen = right_maxx - right_minx + 1;
    % right_ylen = right_maxy - right_miny + 1;
    
    right_ystep = unique(diff(right.y));
    right_ystep = right_ystep(2); % the first is the step between top, bottom? 2nd is the normal step. Could use groupcounts instead if more robustness is needed
    right_xstep = unique(diff(right.x));
    right_xstep = right_xstep(2);
    
    right_yvec = right_miny:right_ystep:right_maxy;
    right_xvec = right_minx:right_xstep:right_maxx;
    
    right_ylen = length(right_yvec);
    right_xlen = length(right_xvec);
    
    right_sz = [right_xlen,right_ylen];

end



