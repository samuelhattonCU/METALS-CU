% Compare between end of pull and end of relaxation to look for visable
% change in strain do to stress relaxation


%% Housekeeping
clear; clc; close all;

% make plots pretty
set(groot,'defaultAxesTickLabelInterpreter','latex'); 
set(groot,'defaulttextinterpreter','latex');
set(groot,'defaultLegendInterpreter','latex');
set(groot,'defaultAxesFontSize',20);
set(groot,'defaultLineLineWidth',1.5);
set(groot,'defaultAxesBox','on')
% set(groot,'defaultTextFontSize',16)

% Add paths to get functions, local .mats/.figs etc.
addpath("..\local\")
addpath("..\functions\analysis and plotting\")
addpath('..\functions\data loading\')

%% 

data140 = frame_cleaner(load_frame_data("C:\Users\hatto\OneDrive - UCB-O365\Summer 2024\METALS Documents\FLIR Stuff",140),true);
data1317 = frame_cleaner(load_frame_data("C:\Users\hatto\OneDrive - UCB-O365\Summer 2024\METALS Documents\FLIR Stuff",1317),true);

% compare_plot(data140,data1317,"e1",["S20-4 Frame 140","S20-4 Frame 1317"],"$$e_1$$","Relaxation Period Strain Difference")

ps140 = get_plot_stuff(data140,"e1",1,'Xp','Yp',true);
ps1317 = get_plot_stuff(data1317,"e1",1,'Xp','Yp',true);

absdif = abs(ps140.cdat - ps1317.cdat);

%%

figure
subplot(2,2,1)
hold on
contourf(ps140.xdat,ps140.ydat,ps140.cdat,50,EdgeColor="none")
cb = colorbar();
xlabel("Xp")
ylabel("Yp")

lim1 = clim();

title("Strain at End of Loading")

subplot(2,2,2)
hold on
contourf(ps1317.xdat,ps1317.ydat,ps1317.cdat,50,EdgeColor="none")
cb = colorbar();
xlabel("Xp")
ylabel("Yp")

lim2 = clim();

lims = [min(lim1(1),lim2(1)),max(lim1(2),lim2(2))];
subplot(2,2,1)
clim(lims)
subplot(2,2,2)
clim(lims)
colormap turbo

title("Strain after $$\approx$$ 4 min of Relaxation")

subplot(2,2,3)
ax3 = gca;
hold on

mu = mean(mean(absdif,'omitnan'),'omitnan');
title("Absolute Difference, $$|\Delta\varepsilon|$$, $$\overline{|\Delta\varepsilon|}$$ = " + string(round(mu,4)))

contourf(ps140.xdat,ps140.ydat,absdif,50,EdgeColor="none")
cb3 = colorbar();
xlabel("Xp")
ylabel("Yp")

sz = size(absdif);
[admax,adidx] = maxk(reshape(absdif,[1,sz(1)*sz(2)]),10);

t10x = ps140.xdat(adidx);
t10y = ps140.ydat(adidx);

s1 = scatter(t10x,t10y,75,'red');
legend(s1,"Largest delta $$\approx$$ " + string(100*round(max(admax),2)) + "\%")



subplot(2,2,4)
ax4 = gca;
hold on

nstd = 10;

z = absdif;
zstd = std(std(absdif,'omitnan'),'omitnan');
cutoff = nstd * max(zstd);

z(absdif > cutoff) = NaN;

contourf(ps140.xdat,ps140.ydat,z,50,EdgeColor="none")
cb4 = colorbar();
cb4.Limits = [0,cutoff];

mu = mean(mean(z,'omitnan'),'omitnan');
title("$$|\Delta\varepsilon|$$, Outliers Removed, $$\overline{|\Delta\varepsilon|}$$ = " + string(round(mu,4)));

lims = clim();
subplot(2,2,3)
clim(lims)
cb3.Ruler.Exponent = 0;
cb4.Ruler.Exponent = 0;

colormap(ax3,"cool")
colormap(ax4,"cool")