function [left_sz, right_sz] = get_lr_sz(data)

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

% lminx = min(left.x);lmaxx = max(left.x); lminy = min(left.y);lmaxy=max(left.y);
% xlen = lmaxx-lminx;
% xlen = lmaxx-lminx + 1;
% ylen = lmaxy-lminy + 1;
% right = data(data.aoi == 4,:);
% ystep = unique(diff(left.y)); ystep = ystep(2);
% yvec = lminy:ystep:lmaxy;
% xstep = 5; xvec = lminx:xstep:lmaxx;
% xlen = length(xvec); ylen = length(yvec); count = ylen * xlen; count == length(left.x);
% maube = reshape(left.x,[xlen,ylen])';
% maubey = reshape(left.y,[xlen,ylen])';



