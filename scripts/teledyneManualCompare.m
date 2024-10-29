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

% %%
% imdata1 = imread("C:\Users\Samuel\Documents\GitHub\METALS-CU\spec4_189.png");
% I1 = rgb2gray(imdata1);
% % imdata2 = imread("C:\Users\Samuel\Documents\GitHub\METALS-CU\spec4_189 - Copy.png");
% imdata2 = imread("C:\Users\Samuel\Documents\GitHub\METALS-CU\spec4_104.png");
% I2 = rgb2gray(imdata2);
% %%
% m1 = getHoles("C:\Users\Samuel\Documents\GitHub\METALS-CU\spec4_189.png");
% % m2 = getHoles("C:\Users\Samuel\Documents\GitHub\METALS-CU\spec4_189 - Copy.png");
% m2 = getHoles("C:\Users\Samuel\Documents\GitHub\METALS-CU\spec4_104.png");
% 
% %%
% % I1 = double(I1);
% % I2 = double(I2);
% % I1(I1 == 0) = NaN;
% % I2(I2 == 0) = NaN;
% 
% figure
% subplot(1,2,1)
% imshow(I1);
% hold on
% plot(m1(1),m1(2),'rx')
% subplot(1,2,2)
% imshow(I2)
% hold on
% plot(m2(1),m2(2),'rx')
% 
% t = zeros(1,2);
% t(1) = m1(1) - m2(1);
% t(2) = m1(2) - m2(2);
% 
% figure
% subplot(1,2,1)
% imshow(imdata1);
% hold on
% im2 = imshow(I2);
% im2.AlphaData = 0.7;
% title("Before Translation")
% 
% subplot(1,2,2)
% imshow(imdata1)
% hold on
% im2 = imshow(I2);
% im2.AlphaData = 0.7;
% im2.XData = im2.XData + t(1);
% im2.YData = im2.YData + t(2);
% title("After Translation")
% 
% %%
% 
% % which is smaller?
% sz1 = size(I1);
% sz2 = size(I2);
% if sum(sz1 < sz2) == 2
%     % first image is smaller
% 
% else
%     % second image is smaller
% end

%% Load Data (~3.5mm VED): Teledyne #120, S18-3 #121
%% 1mm VED: Tele # 55 and S18-3 # 52

% read in csvs:
% RT_1 = readtable("F:\DATA\METALS\Comparisons\Specimen-teledyne-RT-1\Data Export\082224-01-0120_0.csv","NumHeaderLines",1,"VariableNamesLine",1);
% s18_3 = readtable("F:\DATA\METALS\Comparisons\Specimen-18-3\Data Export\sample18-specimen3-00000121_0.csv","NumHeaderLines",1,"VariableNamesLine",1);
RT_1 = readtable("F:\DATA\METALS\Comparisons\Specimen-teledyne-RT-1\Data Export\082224-01-0055_0.csv","NumHeaderLines",1,"VariableNamesLine",1);
s18_3 = readtable("F:\DATA\METALS\Comparisons\Specimen-18-3\Data Export\sample18-specimen3-00000052_0.csv","NumHeaderLines",1,"VariableNamesLine",1);

% extract matrices?
teledata.data = RT_1;
teledata.x = col_to_mat(teledata.data,'x',true);
teledata.y = col_to_mat(teledata.data,'y',true);
teledata.Xp = col_to_mat(teledata.data,'Xp',true);
teledata.Yp = col_to_mat(teledata.data,'Yp',true);
teledata.e1 = col_to_mat(teledata.data,'e1',true);
[teledata.sz,teledata.xvec,teledata.yvec] = get_sz(teledata.data,7);

cudata.data = s18_3;
cudata.x = col_to_mat(cudata.data,'x',true);
cudata.y = col_to_mat(cudata.data,'y',true);
cudata.Xp = col_to_mat(cudata.data,'Xp',true);
cudata.Yp = col_to_mat(cudata.data,'Yp',true);
cudata.e1 = col_to_mat(cudata.data,'e1',true);
[cudata.sz,cudata.xvec,cudata.yvec] = get_sz(cudata.data,7);

teledata.plt = get_plot_stuff(teledata.data,'e1',true,'Xp','Yp',true);
teledata.uplt = get_plot_stuff(teledata.data,'e1',true,'X','Y',true);
cudata.plt = get_plot_stuff(cudata.data,'e1',true,'Xp','Yp',true);
cudata.uplt = get_plot_stuff(cudata.data,'e1',true,'X','Y',true);

% figure
% subplot(1,2,1)
% plt = teledata.plt;
% contourf(plt.xdat,plt.ydat,plt.cdat)
% 
% subplot(1,2,2)
% plt = cudata.plt;
% contourf(plt.xdat,plt.ydat,plt.cdat)

% teledata.mp = round(getHoles([],teledata.e1));
% cudata.mp = round(getHoles([],cudata.e1));
% 
% teledata.mpXp = teledata.Xp(teledata.mp(2),teledata.mp(1));
% cudata.mpXp = cudata.Xp(cudata.mp(2),cudata.mp(1));
% teledata.mpYp = teledata.Yp(teledata.mp(2),teledata.mp(1));
% cudata.mpYp = cudata.Yp(cudata.mp(2),cudata.mp(1));

teledata.mp = getMid(teledata);
cudata.mp = getMid(cudata);

% f = figure;
% contourf(teledata.plt.xdat,teledata.plt.ydat,teledata.plt.cdat)
% roi = drawline;
% p1 = roi.Position([1,3]);
% p2 = roi.Position([2,4]);
% teledata.mp = [mean([p1(1),p2(1)]),mean([p1(2),p2(2)])];
% hold on
% scatter(teledata.mp(1),teledata.mp(2),25,'rx')
% close(f)
% 
% f = figure;
% contourf(cudata.plt.xdat,cudata.plt.ydat,cudata.plt.cdat)
% roi = drawline;
% p1 = roi.Position([1,3]);
% p2 = roi.Position([2,4]);
% cudata.mp = [mean([p1(1),p2(1)]),mean([p1(2),p2(2)])];
% hold on
% scatter(cudata.mp(1),cudata.mp(2),25,'rx')
% close(f)

%%

t = zeros(1,2);
t(1) = teledata.mp(1) - cudata.mp(1);
t(2) = teledata.mp(2) - cudata.mp(2);
% t(1) = teledata.mpXp - cudata.mpXp;
% t(2) = teledata.mpYp - cudata.mpYp;

figure
subplot(1,2,1)
contourf(teledata.uplt.xdat,teledata.uplt.ydat,teledata.uplt.cdat)
hold on
[~,im2] = contourf(cudata.uplt.xdat,cudata.uplt.ydat,cudata.uplt.cdat);
im2.FaceAlpha = 0.7;
title("Before Translation")

subplot(1,2,2)
contourf(teledata.uplt.xdat,teledata.uplt.ydat,teledata.uplt.cdat)
hold on
[~,im2] = contourf(cudata.uplt.xdat,cudata.uplt.ydat,cudata.uplt.cdat);
im2.FaceAlpha = 0.7;
im2.XData = im2.XData + t(1);
im2.YData = im2.YData + t(2);
title("After Translation")

%% 
% cu data is slightly larger matrix -> interpolate tele to match?

xq = cudata.data.X;
yq = cudata.data.Y;

x = teledata.data.X + t(1);
y = teledata.data.Y + t(2);
v = teledata.data.e1;

vq = griddata(x,y,v,xq,yq);
cudata.data.vq = vq;
teledata.vq = col_to_mat(cudata.data,'vq',true);

teledata.vplt = get_plot_stuff(cudata.data,'vq',true,'Xp','Yp',true);

% figure
% subplot(1,2,1)
% contourf(cudata.plt.xdat,cudata.plt.ydat,cudata.plt.cdat)
% subplot(1,2,2)
% contourf(teledata.vplt.xdat,teledata.vplt.ydat,teledata.vplt.cdat)

cudata.data.resids = abs(cudata.data.e1 - cudata.data.vq);
cudata.rplt = get_plot_stuff(cudata.data,'resids',true,'Xp','Yp',true);
figure
% levels = -.1:.01:.1;
[~,cf] = contourf(cudata.rplt.xdat,cudata.rplt.ydat,cudata.rplt.cdat,LineStyle='none');
c = colorbar();
lims = clim();

lvls = linspace(lims(1),lims(2),15);
cf.LevelList = lvls;

ticks = linspace(lims(1),lims(2),6);
c.Ticks = ticks;
c.TickLabels = compose('%4.3f',ticks);
% c.Ticks = -.1:.02:.1;
% title("Absolute Difference, $$e_1$$ at 3.5mm VED")
title("Absolute Difference, $$e_1$$ at 1mm VED")
xlabel("$$X_p$$, mm")
ylabel("$$Y_p$$, mm")
axis equal
%%

f = figure;
f.Position = [1,403,1916,464];

subplot(1,2,2)
[~,cf] = contourf(cudata.plt.xdat,cudata.plt.ydat,cudata.plt.cdat,LineStyle='none');
ll = cf.LevelList;
cf.LevelList = linspace(ll(1),ll(end),10);

c1 = colorbar();
xlabel("$$X_p$$, mm")
ylabel("$$Y_p$$, mm")
% title("CU S18-3, $$e_1$$, 3.5mm VED")
title("CU S18-3, $$e_1$$, 1mm VED")
axis equal
ax1 = gca;
lim1 = clim();

subplot(1,2,1)
contourf(teledata.plt.xdat,teledata.plt.ydat,teledata.plt.cdat,cf.LevelList,LineStyle='none')
c2 = colorbar();
% c2.Ticks = c1.Ticks;
% c2.TickLabels = c1.TickLabels;
xlabel("$$X_p$$, mm")
ylabel("$$Y_p$$, mm")
% title("Teledyne RT-1, $$e_1$$, 3.5mm VED")
title("Teledyne RT-1, $$e_1$$, 1mm VED")
axis equal
ax2 = gca;
lim2 = clim();

lims = [min(lim1(1),lim2(1)),max(lim1(2),lim2(2))];
clim(lims)
subplot(1,2,2)
clim(lims)

% set(ax1,'YLim',ax2.YLim)
ax2.YLim = ax1.YLim;
ax1.XLim = ax2.XLim;

ticks = linspace(lims(1),lims(2),6);
% ticks = c2.Ticks;
c2.Ticks = ticks;
c2.TickLabels = compose('%9.3f',ticks);
c1.Ticks = ticks;
% ticks = c1.Ticks;
c1.TickLabels = compose('%9.3f',ticks);

% tix = hcb.Ticks;                                            % Get Tick Values
% hcb.TickLabels = compose('%9.6f',tix);  

%%

figure
histogram(cudata.rplt.cdat)
set(gca,'YScale','log')
title("Absolute Difference, $$e_1$$, 3.5mm VED")
grid on
ylabel("Occurences")
xlabel("Residual Value")

% figure;subplot(1,2,1);histogram(teledata.plt.cdat);set(gca,'YScale','log');title("Teledyne RT-1, $$e_1$$, 3.5mm VED");ylabel("Occurances");xlabel("Value of $$e_1$$");
% subplot(1,2,2);histogram(cudata.plt.cdat);set(gca,'YScale','log');title("CU S18-3, $$e_1$$, 3.5mm VED");ylabel("Occurances");xlabel("Value of $$e_1$$")
% grid on
% subplot(1,2,1);grid on
% ylabel("Occurrences")
% subplot(1,2,2);ylabel("Occurrences")



%% COOL BUTTON STUFF, FOR ANOTHER TIME
% f = uifigure("Name","Translation Confirmation");
% ax = uiaxes(f);
% contourf(ax,teledata.plt.xdat,teledata.plt.ydat,teledata.plt.cdat)
% hold(ax,'on')
% [~,im2] = contourf(ax,cudata.plt.xdat,cudata.plt.ydat,cudata.plt.cdat);
% im2.FaceAlpha = 0.7;
% im2.XData = im2.XData + t(1);
% im2.YData = im2.YData + t(2);
% title(ax,"After Translation")
% 
% cnfrmbtn = uibutton(f);
% cnfrmbtn.Position = [50,350,150,22];
% cnfrmbtn.Text = "Confirm Translation";
% 
% dnybtn = uibutton(f);
% dnybtn.Position = [210,350,150,22];
% dnybtn.Text = "Redo Corner Selection";


%%
% f = figure;
% contourf(teledata.plt.xdat,teledata.plt.ydat,teledata.plt.cdat)
% roi = drawline;
% p1 = roi.Position([1,3]);
% p2 = roi.Position([2,4]);
% teledata.mp = [mean([p1(1),p2(1)]),mean([p1(2),p2(2)])];
% hold on
% scatter(mp(1),mp(2),25,'rx')
% close(f)
% 
% f = figure;
% contourf(cudata.plt.xdat,cudata.plt.ydat,cudata.plt.cdat)
% roi = drawline;
% p1 = roi.Position([1,3]);
% p2 = roi.Position([2,4]);
% cudata.mp = [mean([p1(1),p2(1)]),mean([p1(2),p2(2)])];
% hold on
% scatter(mp(1),mp(2),25,'rx')
% close(f)


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


