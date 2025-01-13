% creepmain.m
%
% CU Boulder METALS Project
% Comments updated: 01/13/2025
% Samuel Hatton
%
%
% Purpose
%     Analysis script for creep and relaxation behavior in mechanical testing
%     Compares strain changes between end of pull and end of relaxation
% Usage
%     Run script to generate plots and analysis of relaxation data

% Trying to come up with some stuff to present on creep/relaxation

% Compare between end of pull and end of relaxation to look for visable
% change in strain do to stress relaxation


%% Housekeeping
clear; clc; close all;

% make plots pretty
set(groot,'defaultAxesTickLabelInterpreter','latex');
set(groot,'defaulttextinterpreter','latex');
set(groot,'defaultLegendInterpreter','latex');
set(groot,'defaultAxesFontSize',12);
set(groot,'defaultLineLineWidth',1.2);
% warning('off','MATLAB:handle_graphics:exceptions:SceneNode')

% Add paths to get functions, local .mats/.figs etc.
addpath("..\local\")
addpath("..\functions\analysis and plotting\")
addpath('..\functions\data loading\')

%% FORCE from INSTRON

data = readtable("C:\Users\Samuel\OneDrive - UCB-O365\Summer 2024\METALS Documents\Relaxation\Sample 21.8_20241206_095617_1_1.csv", ...
    "NumHeaderLines",8,"VariableNamesLine",7,"VariableUnitsLine",8);

data.Force = data.Force - data.Force(1);

% FULL TIME
figure
subplot(2,2,1)
plot(data.Displacement,data.Force)

xlabel("Displacement $$[mm]$$")
ylabel("Force $$[N]$$")
grid on
grid minor

subplot(2,2,2)
plot(data.Time,data.Force)

xlabel("Time $$[sec]$$")
ylabel("Force $$[N]$$")
grid on
grid minor

subplot(2,1,2)
[~,linloc] = min(abs(data.Time - 1000));
p = polyfit(data.Time(linloc:end),data.Force(linloc:end),1);
slope = p(1);
% [pks,locs] = findpeaks(data.Force);
% scatter(data.Time(locs),pks,'x')

hold on
[mval,loc] = max(data.Force);
% plot(data.Time(loc),mval,'x')
plot(data.Time(loc:end),data.Force(loc:end))
f1 = fit(data.Time(loc:end),data.Force(loc:end),'exp2');

y = @(f,x) f.a * exp(f.b * x) + f.c * exp(f.d * x);
% y = @(f,x) f.a * exp(f.b * x);
t = data.Time(1): max(data.Time) + 120*60; % extrapolate two hours out
y1 = y(f1,t);
plot(t,y1,'--k')

plot(t(t>1000),polyval(p,t(t>1000)),'--r')

legend("Real Data","Exponential Projection","Linear Projection")

xlabel("Time $$[sec]$$")
ylabel("Force $$[N]$$")
grid on
grid minor

sgtitle("Static 5mm Displacement Relaxation Test")
%%
[fmax,loc] = max(data.Force);
fend = data.Force(end);
perc_drop = 100 * (fmax - fend) / fmax;
drop_time = data.Time(end) - data.Time(loc);
dt_min = drop_time/60;




%% PART TIME
range = 1:6000;
figure
subplot(1,2,1)
hold on
plot(data.Displacement(range),data.Force(range))

xlabel("Displacement $$[mm]$$")
ylabel("Force $$[N]$$")
grid on
grid minor

fmax = max(data.Force(range));
fmin = data.Force(range(end));

peakloc = find(data.Force == fmax);

yvec = [fmax fmax fmin fmin];

xmin = data.Displacement(peakloc);
xmax = data.Displacement(range(end));

xvec = [xmin-0.25 xmax+0.25 xmax+0.25 xmin-0.25];

fill(xvec,yvec,'r','FaceAlpha',0.2,'EdgeColor','r')

subplot(1,2,2)
hold on
plot(data.Time(range),data.Force(range))

xlabel("Time $$[sec]$$")
ylabel("Force $$[N]$$")
grid on
grid minor

sgtitle("Static 5mm Displacement Relaxation Test")

xmin = data.Time(peakloc);
xmax = data.Time(range(end));

xvec = [xmin xmax xmax xmin];

fill(xvec,yvec,'r','FaceAlpha',0.2,'EdgeColor','r')


%% Compare .out frames
% 4, 1307, 1433, 2449
data0004 = frame_cleaner(load_frame_data("F:\FLIR Stuff\Sample 21\Specimen 8",4),true); % first frame
data1307 = frame_cleaner(load_frame_data("F:\FLIR Stuff\Sample 21\Specimen 8",1307),true); % after heating
data1433 = frame_cleaner(load_frame_data("F:\FLIR Stuff\Sample 21\Specimen 8",1433),true); % end of loading
data2449 = frame_cleaner(load_frame_data("F:\FLIR Stuff\Sample 21\Specimen 8",2449),true); % end of test

%% Full Field Strain Comp

% compare_plot(data140,data1317,"e1",["S20-4 Frame 140","S20-4 Frame 1317"],"$$e_1$$","Relaxation Period Strain Difference")

ps1433 = get_plot_stuff(data1433,"e1",1,'Xp','Yp',true);
ps2449 = get_plot_stuff(data2449,"e1",1,'Xp','Yp',true);

% absdif = abs(ps1433.cdat - ps2449.cdat);
absdif = ps2449.cdat - ps1433.cdat;

figure
subplot(2,2,1)
hold on
contourf(ps1433.xdat,ps1433.ydat,ps1433.cdat,250,EdgeColor="none")
cb = colorbar();
xlabel("Xp")
ylabel("Yp")

lim1 = clim();

title("Strain at End of Loading")
colormap HSV

subplot(2,2,2)
hold on
contourf(ps2449.xdat,ps2449.ydat,ps2449.cdat,250,EdgeColor="none")
cb = colorbar();
xlabel("Xp")
ylabel("Yp")

lim2 = clim();

% lims = [min(lim1(1),lim2(1)),max(lim1(2),lim2(2))];
lims = [min(lim1(1),lim2(1)),0.3];
subplot(2,2,1)
box on
clim(lims)
subplot(2,2,2)
box on
clim(lims)
colormap HSV

title("Strain after $$\approx$$ 52 min of Relaxation")

subplot(2,2,3)
box on
ax3 = gca;
hold on

mu = mean(mean(abs(absdif),'omitnan'),'omitnan');
title("Difference, $$\Delta\varepsilon = \varepsilon_{t2} - \varepsilon_{t1}$$, $$\overline{|\Delta\varepsilon|}$$ = " + string(round(mu,4)))

contourf(ps1433.xdat,ps1433.ydat,absdif,50,EdgeColor="none")
cb3 = colorbar();
xlabel("Xp")
ylabel("Yp")

sz = size(absdif);
[admax,adidx] = maxk(reshape(abs(absdif),[1,sz(1)*sz(2)]),10);

t10x = ps1433.xdat(adidx);
t10y = ps1433.ydat(adidx);

s1 = scatter(t10x,t10y,75,'red');
legend(s1,"Largest delta $$\approx$$ " + string(100*round(max(admax),2)) + "\%","Location","best")



subplot(2,2,4)
% %%
% figure
ax4 = gca;
hold on

% nstd = 2;
%
% z = absdif;
% zstd = std(std(absdif,'omitnan'),'omitnan');
% cutoff = nstd * max(zstd);
%
% z(absdif > cutoff) = NaN;
z = absdif;
z(abs(absdif) > 0.05) = NaN;
x = z(abs(z) > 0.001);
contourf(ps1433.xdat,ps1433.ydat,z,50,EdgeColor="none")
cb4 = colorbar();
% cb4.Limits = [0,cutoff];

mu = mean(mean(abs(z),'omitnan'),'omitnan');
title("$$\Delta\varepsilon$$, Outliers Removed, $$\overline{|\Delta\varepsilon|}$$ = " + string(round(mu,4)));
xlabel("Xp")
ylabel("Yp")
box on
lims = clim();

subplot(2,2,3)
clim(lims)
cb3.Ruler.Exponent = 0;
cb4.Ruler.Exponent = 0;

colormap(ax3,"HSV")
colormap(ax4,"HSV")

sgtitle("Comparing Strain Before and After Relaxation")

%%
figure
subplot(3,1,1)
zh = histogram(abs(z),"EdgeAlpha",0.1);
legend("$$|\Delta \varepsilon | $$")
title("$$\overline{|\Delta\varepsilon|}$$ = " + string(round(mu,4)))
zh.Parent.XLim = [0,0.02];
subplot(3,1,2)
xh = histogram(abs(x),"EdgeAlpha",0.1);
legend("$$|\Delta \varepsilon | > 0.001 $$")
title("$$\overline{|\Delta\varepsilon|}$$ = " + string(round(mean(mean(abs(x),'omitnan'),'omitnan'),4)))
xh.Parent.XLim = [0,0.02];
subplot(3,1,3)
g = z(abs(z) > 0.0015);
gh = histogram(abs(g),"EdgeAlpha",0.1);
legend("$$|\Delta \varepsilon | > 0.0015 $$")
title("$$\overline{|\Delta\varepsilon|}$$ = " + string(round(mean(mean(abs(g),'omitnan'),'omitnan'),4)))
gh.Parent.XLim = [0,0.02];

%% plot change in total displacement
ps1433_V = get_plot_stuff(data1433,"V",1,'Xp','Yp',true);
ps2449_V = get_plot_stuff(data2449,"V",1,'Xp','Yp',true);

ps1433_U = get_plot_stuff(data1433,"U",1,'Xp','Yp',true);
ps2449_U = get_plot_stuff(data2449,"U",1,'Xp','Yp',true);

U1 = ps1433_U.cdat;
U2 = ps2449_U.cdat;

V1 = ps1433_V.cdat;
V2 = ps2449_V.cdat;

D1 = sqrt(U1.^2 + V1.^2);
D2 = sqrt(U2.^2 + V2.^2);

absdif = D2 - D1;

figure
subplot(2,2,1)
hold on
contourf(ps1433.xdat,ps1433.ydat,D1,250,EdgeColor="none")
cb = colorbar();
xlabel("Xp")
ylabel("Yp")

lim1 = clim();

title("Vertical Displacement at End of Loading")
colormap cool

subplot(2,2,2)
hold on
contourf(ps2449.xdat,ps2449.ydat,D2,250,EdgeColor="none")
cb = colorbar();
xlabel("Xp")
ylabel("Yp")

lim2 = clim();

% lims = [min(lim1(1),lim2(1)),max(lim1(2),lim2(2))];
lims = [min(lim1(1),lim2(1)),0.3];
subplot(2,2,1)
box on
clim(lims)
subplot(2,2,2)
box on
clim(lims)
colormap cool

title("Vertical Displacement after $$\approx$$ 52 min of Relaxation")

subplot(2,2,3)
box on
ax3 = gca;
hold on

mu = mean(mean((absdif),'omitnan'),'omitnan');
title("Difference, $$\Delta V= V_{t2} - V_{t1}$$, $$\overline{\Delta V}$$ = " + string(round(mu,4)))

contourf(ps1433.xdat,ps1433.ydat,absdif,50,EdgeColor="none")
cb3 = colorbar();
xlabel("Xp")
ylabel("Yp")

sz = size(absdif);
[admax,adidx] = maxk(reshape(abs(absdif),[1,sz(1)*sz(2)]),10);

t10x = ps1433.xdat(adidx);
t10y = ps1433.ydat(adidx);

s1 = scatter(t10x,t10y,75,'red');
legend(s1,"Largest delta $$\approx$$ " + string(100*round(max(admax),2)) + "\%","Location","best")



subplot(2,2,4)
% %%
% figure
ax4 = gca;
hold on

% nstd = 2;
%
% z = absdif;
% zstd = std(std(absdif,'omitnan'),'omitnan');
% cutoff = nstd * max(zstd);
%
% z(absdif > cutoff) = NaN;
z = absdif;
% z(abs(absdif) > 0.05) = NaN;
x = z(abs(z) > 0.001);
contourf(ps1433.xdat,ps1433.ydat,z,50,EdgeColor="none")
cb4 = colorbar();
% cb4.Limits = [0,cutoff];

mu = mean(mean((z),'omitnan'),'omitnan');
title("$$\Delta V$$, Outliers Removed, $$\overline{\Delta V}$$ = " + string(round(mu,4)));
xlabel("Xp")
ylabel("Yp")
box on
lims = clim();

subplot(2,2,3)
% clim(lims)
cb3.Ruler.Exponent = 0;
cb4.Ruler.Exponent = 0;

colormap(ax3,"cool")
colormap(ax4,"cool")

sgtitle("Comparing Vertical Displacement Before and After Relaxation")


%% Points over time

ptdat = get_e1_from_csv("F:\FLIR Stuff\Sample 21\Specimen 8\strain_over_time.csv");
ptdat = ptdat(1:end-1,:);
imid = [4, 5, 6, 330, 331, 338:10:1298, 1306, 1307, 1308:10:1428, 1433, 1434, 1435, 1438:10:2448, 2449]';
x = ptdat.index;


testdat = readtable("F:\FLIR Stuff\Sample 21\Specimen 8\Specimen 21.8.csv",NumHeaderLines=85,VariableNamesLine=1);

idx_vec = zeros(1,length(x));
for i = 1:length(x)
    idx_vec(i) = find(imid(i) == testdat.Count);
end

t = testdat.Time_0_1(idx_vec);
t = t-t(1);

%drop first three points:
ptdat = ptdat(4:end,:);
t = t(4:end);
t = t-t(1);

% st_time = testdat.Time_0_1(1);
% end_time = testdat.Time_0_1(end);
% t = linspace(st_time,end_time,length(x)) - st_time;

%% plot all
figure
hold on
c = distinguishable_colors(12);
for i = 1:12
    y = table2array(ptdat(:,i));
    idx = ~isnan(y);
    plot(t(idx),y(idx),'color',c(i,:))
    % plot(t(idx),y(idx))
end

xlabel("Time $$[sec]$$")
ylabel("Hencky $$e_1$$")

% legend("P" + string([2 5 6 8]),Location="best")
legend(ptdat.Properties.VariableDescriptions(1:12),'Location','best')
% legend("Upper Left", "Bottom Left","Upper Right","Bottom Right",Location="best")
grid on
grid minor
a = gca;
xlim1 = a.XLim;
ylim1 = a.YLim;
title("Strain Over Time at 12 Arm Bend Points")

%% plot target
targ = [5,7];
figure
hold on
c = distinguishable_colors(12);
for i = targ
    y = table2array(ptdat(:,i));
    idx = ~isnan(y);
    plot(t(idx),y(idx),'color',c(i,:))
    % plot(t(idx),y(idx))
end


xlabel("Time $$[sec]$$")
ylabel("Hencky $$e_1$$")

% legend("P" + string([2 5 6 8]),Location="best")
legend(ptdat.Properties.VariableDescriptions(targ),'Location','best')
% legend("Upper Left", "Bottom Left","Upper Right","Bottom Right",Location="best")
grid on
grid minor
xlim(xlim1)
ylim(ylim1)
title("Strain Over Time, Upper and Lower Inside Points")

% figure
% y = table2array(ptdat(:,5));
% idx = ~isnan(y);
% plot(t(idx),y(idx),'color',c(5,:))
%
% legend("P2",Location="best")
%
% xlabel("Time $$[sec]$$")
% ylabel("Hencky $$e_1$$")
% grid on
% grid minor

%% Cooling stats

y2 = table2array(ptdat(:,5));
y4 = table2array(ptdat(:,7));

cooling = t > 1010;
tcool = t(cooling);
coolrate_2 = diff(y2(cooling));
coolrate_4 = diff(y4(cooling));

figure
hold on
plot(tcool(2:end-1),100*coolrate_2(1:end-1))
plot(tcool(2:end-1),100*coolrate_4(1:end-1))

m2 = mean(100*coolrate_2(1:end-1),'omitnan');
m4 = mean(100*coolrate_4(1:end-1),'omitnan');
mtot = mean([m2,m4]);
grid minor
grid on
xlabel("Time $$[sec]$$")
ylabel("Strain Rate, $$[\%/sec]$$")
ylim([-.1,.1])


dat = ptdat(cooling,1:12);
datdiff = diff(dat);
datm = mean(mean(table2array(datdiff),2,'omitnan'),'omitnan');
yline(100 * datm,'--k')
legend("P2","P4","12 Pt. Mean")
title("Avg. Strain Relaxation Rate = " + string(100 * datm) + "$$\%/sec$$")


% figure
% plot(tcool(2:end),datm)
