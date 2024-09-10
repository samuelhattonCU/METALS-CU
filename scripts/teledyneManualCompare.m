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

%%
imdata1 = imread("C:\Users\Samuel\Documents\GitHub\METALS-CU\spec4_189.png");
I1 = rgb2gray(imdata1);
% imdata2 = imread("C:\Users\Samuel\Documents\GitHub\METALS-CU\spec4_189 - Copy.png");
imdata2 = imread("C:\Users\Samuel\Documents\GitHub\METALS-CU\spec4_104.png");
I2 = rgb2gray(imdata2);
%%
m1 = getHoles("C:\Users\Samuel\Documents\GitHub\METALS-CU\spec4_189.png");
% m2 = getHoles("C:\Users\Samuel\Documents\GitHub\METALS-CU\spec4_189 - Copy.png");
m2 = getHoles("C:\Users\Samuel\Documents\GitHub\METALS-CU\spec4_104.png");

%%
% I1 = double(I1);
% I2 = double(I2);
% I1(I1 == 0) = NaN;
% I2(I2 == 0) = NaN;

figure
subplot(1,2,1)
imshow(I1);
hold on
plot(m1(1),m1(2),'rx')
subplot(1,2,2)
imshow(I2)
hold on
plot(m2(1),m2(2),'rx')

t = zeros(1,2);
t(1) = m1(1) - m2(1);
t(2) = m1(2) - m2(2);

figure
subplot(1,2,1)
imshow(imdata1);
hold on
im2 = imshow(I2);
im2.AlphaData = 0.7;
title("Before Translation")

subplot(1,2,2)

hold on
im2 = imshow(I2);
im2.AlphaData = 0.7;
im2.XData = im2.XData + t(1);
im2.YData = im2.YData + t(2);
title("After Translation")

%%

% which is smaller?
sz1 = size(I1);
sz2 = size(I2);
if sum(sz1 < sz2) == 2
    % first image is smaller

else
    % second image is smaller
end

%%


% I = rgb2gray(imdata1);
% 
% Itf = I;
% sz = size(Itf);
% for i = 1:sz(1)*sz(2)
%     if I(i) ~= 0
%         Itf(i) = 0;
%     else
%         Itf(i) = 1;
%     end
% end
% 
% cc4 = bwconncomp(Itf,4);
% % sort by length to get the large cutout holes:
% list_length = zeros(1,cc4.NumObjects);
% for i = 1:cc4.NumObjects
%     list_length(i) = length(cc4.PixelIdxList{i});
% end
% [~,sort_idx] = sort(list_length); % smallest to largest
% hole_idx = cc4.PixelIdxList(sort_idx); 
% 
% imshow(label2rgb(labelmatrix(cc4),@copper,'c','shuffle'))
% 
% meds = NaN(cc4.NumObjects,2);
% for i = 1:cc4.NumObjects
%     [row,col] = ind2sub(sz,hole_idx{i});
%     x = median(row);
%     y = median(col);
%     meds(i,1) = x;
%     meds(i,2) = y;
%     % hold on
%     % scatter(y,x,50,'rx')
%     % text(y,x,"ROI " + string(i))
% end
% 
% 
% 
% holes = zeros(5,2);
% temp = NaN(size(meds));
% temp(:,1) = meds(:,2);
% temp(:,2) = meds(:,1);
% for i = 1:5
%     pt = drawpoint;
%     holes(i,:) = pt.Position;
%     k = dsearchn(temp,holes(i,:));
%     pt.Label = "ROI " + string(k) + ", hole " + string(i);
%     % pt.Label = "(" + holes(i,1) + "," + holes(i,2) + ")";
% end





%% Load in Teledyne Data
% We want frame #120, the displacement here is the closest to 3.5 mm.

% % load force-displacement:
% fdtab = readtable("F:\DATA\METALS\Teledyne\DIC Data\DIC Data\VIC File\A2_RT-ForceDisp.csv","NumHeaderLines",2,"VariableNamesLine", 2);
% 
% % extract data:
% force = fdtab.Force_N_;
% displacement = fdtab.x_L_mm_;
% 
% % find where displacement stops shifting:
% start = find(displacement < 0, 1, "last") + 1;
% 
% % trim early data:
% force = force(start:end);
% displacement = displacement(start:end);
% 
% % instantiate struct (for ease of use):
% tele.force = force;
% tele.displacement = displacement;
% 
% % show image?
% % im = imread("F:\DATA\METALS\Teledyne\DIC Data\DIC Data\082224-01-0120_0.tif",'tif');
% % imshow(im)

% % Load frame 120 out data:
% data = readtable("F:\DATA\METALS\Teledyne\DIC Data\DIC Data\VIC File\Exported Data\082224-01-0120_0.csv","NumHeaderLines",1,"VariableNamesLine",1);

% read in some of my old dat for now:
% data = readtable("F:\DATA\METALS\Sample 5\Specimen 1\Data Export\maybe304-00000120_0.csv","NumHeaderLInes",1,"variableNamesLine",1);


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
% %     e1(xidx,yidx) = data.e1(i);
% % end
% 
% tele.Xp = col_to_mat(data,'Xp',true);
% tele.Yp = col_to_mat(data,'Yp',true);
% tele.e1 = col_to_mat(data,'e1',true);
% 
% figure
% contourf(tele.Xp,tele.Yp,tele.e1)
% % contourf(xmat',ymat',e1)
% 
% % for i = 1:length(xvec)
% %     x = xvec(i);
% %     for j = 1:length(yvec)
% %         y = yvec(j);
% %         if sum(data.x == x)
% %             if sum(data.y == y)
% %                 e1(i,j) = 
% %             end
% %         end
% %     end
% % end
% 
% 
% 
% 
% 


