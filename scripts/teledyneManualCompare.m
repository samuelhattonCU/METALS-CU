% teledyneManualCompare.m
%
% 30 August 2024
% Samuel Hatton
%
%
% The goal here is to see if we and Akshat are close at all?

%% Housekeeping
clear; clc; close all;

% make plots pretty
set(groot,'defaultAxesTickLabelInterpreter','latex'); 
set(groot,'defaulttextinterpreter','latex');
set(groot,'defaultLegendInterpreter','latex');
set(groot,'defaultAxesFontSize',20);
set(groot,'defaultLineLineWidth',1.5);
set(groot,'defaultAxesBox','on')
set(groot,'defaultTextFontSize',16)

warning('off','MATLAB:handle_graphics:exceptions:SceneNode')

% Add paths to get functions, local .mats/.figs etc.
addpath("..\local\")
addpath("..\functions\analysis and plotting\")
addpath("..\functions\data loading\")

%% Load in Teledyne Data
% We want frame #120, the displacement here is the closest to 3.5 mm.

% load force-displacement:
fdtab = readtable("F:\DATA\METALS\Teledyne\DIC Data\DIC Data\VIC File\A2_RT-ForceDisp.csv","NumHeaderLines",2,"VariableNamesLine", 2);

% extract data:
force = fdtab.Force_N_;
displacement = fdtab.x_L_mm_;

% find where displacement stops shifting:
start = find(displacement < 0, 1, "last") + 1;

% trim early data:
force = force(start:end);
displacement = displacement(start:end);

% instantiate struct (for ease of use):
tele.force = force;
tele.displacement = displacement;

% show image?
% im = imread("F:\DATA\METALS\Teledyne\DIC Data\DIC Data\082224-01-0120_0.tif",'tif');
% imshow(im)

% Load frame 120 out data:
data = readtable("F:\DATA\METALS\Teledyne\DIC Data\DIC Data\VIC File\Exported Data\082224-01-0120_0.csv","NumHeaderLines",1,"VariableNamesLine",1);

% [data,perc_additional_er,perc_pts_ignored,cleaned_frame] = frame_cleaner(data)

% get frame size:
% min_x = min(data.x);
% max_x = max(data.x);
% min_y = min(data.y);
% max_y = max(data.y);
% 
% % akshat used a step size of 7 for this data:
% step = 7;
% 
% yvec = min_y:step:max_y;
% xvec = min_x:step:max_x;
% 
% % sz = [length(xvec),length(yvec)];
% 
% % if sz(1) * sz(2) ~= length(data.sigma)
% %     error("problem w/ sizing")
% % end
% 
% % reshape: 
% [xmat,ymat] = meshgrid(xvec,yvec');
% 
% % tele.x = reshape(data.x,sz);
% % tele.y = reshape(data.y,sz);
% % tele.Xp = reshape(data.Xp,sz);
% % tele.Yp = reshape(data.Yp,sz);
% % tele.e1 = reshape(data.e1,sz);
% 
% % missCount = sz(1) * sz(2) - length(data.sigma);
% e1 = NaN(sz);
% % try to extract e1 into a matrix?
% 
% for i = 1:length(data.e1)
%     xidx = find(data.x(i) == xvec);
%     yidx = find(data.y(i) == yvec);
%     e1(xidx,yidx) = data.e1(i);
% end

tele.Xp = col_to_mat(data,'Xp',true);
tele.Yp = col_to_mat(data,'Yp',true);
tele.e1 = col_to_mat(data,'e1',true);

figure
contourf(tele.Xp,tele.Yp,tele.e1)
% contourf(xmat',ymat',e1)

% for i = 1:length(xvec)
%     x = xvec(i);
%     for j = 1:length(yvec)
%         y = yvec(j);
%         if sum(data.x == x)
%             if sum(data.y == y)
%                 e1(i,j) = 
%             end
%         end
%     end
% end







