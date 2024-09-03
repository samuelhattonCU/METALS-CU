function [sz,xvec,yvec] = get_sz(data,step)
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
