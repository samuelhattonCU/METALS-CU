% script for looking at s23_3

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

%% Sample 23 Specimen 3

% load('local\S23_3.mat')
% vic_pip = data{1,1};
% inst_data = data{1,2};
% ext_data = data{1,3}; 
% targ_var = "ΔL/L0";
% targ_var_name = "Strain";
% idx_force_strain = sync_data(vic_pip,inst_data,ext_data,false,targ_var,targ_var_name);
% idx_force_disp = data{1,4};
% 
% 
% figure
% subplot(1,2,1)
% plot(idx_force_strain.Time,idx_force_strain.Force)
% xlabel("Time [$$sec$$]")
% ylabel("Force [$$N$$]")
% title("Force over Time")
% grid on
% grid minor
% yline(0)
% xlim([-40,2000])
% 
% subplot(1,2,2)
% plot(idx_force_strain.Time(idx_force_strain.Time >= 0),idx_force_strain.Strain(idx_force_strain.Time >= 0))
% ax = gca;
% ax.YAxis.Exponent = 0;
% ytickformat('%.3f')
% xlabel("Time [$$sec$$]")
% ylabel("Ext. Strain [$$\Delta L/L0$$]")
% title("Central Extensometer Strain over Time")
% grid on
% grid minor
% yline(0)
% xlim([-40,2000])
% 
% sgtitle("Elastic Relaxation 1 (S23-3)")
% 
% 
% figure
% subplot(1,2,1)
% plot(idx_force_strain.Time,idx_force_strain.Force)
% xlabel("Time [$$sec$$]")
% ylabel("Force [$$N$$]")
% xlim([-40,2000])
% title("Force over Time")
% grid on
% grid minor
% yline(0)
% 
% subplot(1,2,2)
% plot(idx_force_disp.Time(idx_force_disp.Time >= 0),idx_force_disp.Displacement(idx_force_disp.Time >= 0))
% ax = gca;
% ax.YAxis.Exponent = 0;
% ytickformat('%.3f')
% xlabel("Time [$$sec$$]")
% ylabel("Displacement [$$mm$$]")
% xlim([-40,2000])
% title("Central Extensometer Displacement over Time")
% grid on
% grid minor
% yline(0)
% 
% sgtitle("Elastic Relaxation 1 (S23-3)")

%% Sampel 21 Specimen 8

load("local\S21_8.mat")
load("local\s21_8_metadata.mat")

imid = [4, 5, 6, 330, 331, 338:10:1298, 1306, 1307, 1308:10:1428, 1433, 1434, 1435, 1438:10:2448, 2449]';

t = zeros(size(imid));
max_disp_idx = zeros(size(imid));

for i = 1:length(imid)
    f = find(frame_idx == imid(i));
    max_disp_idx(i) = f(end);
    t(i) = time(max_disp_idx(i));
end

vic_strt_idx = 105;

inst_data = data{1,2};
ext_data = data{1,3}; 
ext_data.Time = [t(1);t(1);t];

time_diff = ext_data.Time(vic_strt_idx);
ext_data.Time = ext_data.Time - time_diff;

zero_idx = find(ext_data.Time >= 0, 1);

idx = zeros(length(ext_data.Index(zero_idx:end)),1);
num_nans = 0;
for i = 1:length(ext_data.Index)
    if ext_data.Time(i) < 0
        num_nans = num_nans + 1;
    else
        tf = round(inst_data.Time,1) == round(ext_data.Time(i),1);
        if sum(tf) == 0
            error("No Matching Time for time")
        end
        locs = find(tf);
        idx(i - zero_idx + 1) = locs(1);
    end
end

buffer = nan(num_nans,1);
buffer_time = ext_data.Time(ext_data.Time < 0);
buffer_tab = table(buffer_time,buffer,buffer,buffer,'VariableNames',inst_data.Properties.VariableNames);

% grab only relevant instron data
inst_data_trunc = inst_data(idx,:);
inst_data_trunc = [buffer_tab;inst_data_trunc];

if ~(length(ext_data.Time) == length(inst_data_trunc.Time))
    error("Data matching failed to create tables of equal length")
end

instf = inst_data.Force + abs(inst_data.Force(1));
instd = inst_data.Displacement;
force = inst_data.Force;
disp = inst_data.Displacement;

clear data
data.Time = ext_data.Time;
data.Force = inst_data_trunc.Force;
data.Disp = ext_data.("ΔL");
data.Strain = ext_data.("ΔL/L0");


[peak_force, pk_idx] = max(data.Force);
peak_disp = data.Disp(pk_idx);

dd = data.Disp(end) - peak_disp;
df = data.Force(end) - peak_force;

dfdd = df/dd;

offset = abs(inst_data.Force(1));

figure
% plot(inst_data.Displacement,inst_data.Force + offset)
plot(inst_data.Displacement,inst_data.Force)
grid on
grid minor
xlabel("Displacement $$[mm]$$")
ylabel("Force [$$N$$]")
title("Plastic Relaxation (S21-8)")

x = [-.05 .05 .05 -.05] + peak_disp + .4;
% y = [1774, 1774, 764, 764] + offset;
y = [1774, 1774, 764, 764];



hold on
patch(x,y,'r','FaceAlpha',0.5)

x = [instd(16) instd(79) instd(79) instd(16)];
% y = [instf(16), instf(16), instf(79), instf(79)];

y = [force(16), force(16), force(79), force(79)];

% x = [data.Disp(107) data.Disp(108) data.Disp(108) data.Disp(107)];
% y = [data.Force(107) data.Force(108) data.Force(108) data.Force(107)];

E = (data.Force(108) - data.Force(107)) / (data.Disp(108) - data.Disp(107));

patch(x,y,'g','FaceAlpha',0.5)

legend("F-D Curve","$$\frac{\partial F}{\partial D} \approx " + string(round(dfdd)) + "$$ $$N/mm$$","$$\frac{\partial F}{\partial D} \approx " + string(round(E)) + "$$ $$N/mm$$",Location="best")




%%

figure
subplot(1,2,1)
% plot(inst_data.Time,inst_data.Force);
c = plot(data.Time,data.Force);
grid minor
grid on
xlim([-40,3100])
xlabel("Time [$$sec$$]")
ylabel("Force [$$N$$]")
title("Instron Force vs. Time")
yline(0)
hold on

x = [data.Time(pk_idx) data.Time(end) data.Time(end) data.Time(pk_idx)];
y = [peak_force peak_force data.Force(end) data.Force(end)];
p = patch(x,y,'r','FaceAlpha',0.5);
legend([c,p],"Force vs. Time", "$$\Delta F = " + string(round(df)) + "$$ $$N$$",Location="best")


subplot(1,2,2)
c = plot(ext_data.Time,ext_data.("ΔL"));
grid minor
grid on
xlim([-40,3100])
xlabel("Time [$$sec$$]")
ylabel("Displacement [$$mm$$]")
title("Extensometer Displacement vs. Time")
yline(0)

x = [data.Time(pk_idx) data.Time(end) data.Time(end) data.Time(pk_idx)];
y = [peak_disp peak_disp data.Disp(end) data.Disp(end)];
p = patch(x,y,'r','FaceAlpha',0.5);
legend([c,p],"Displacement vs. Time", "$$\Delta D = " + string(round(dd,3)) + "$$ $$mm$$",Location="best")

sgtitle("Plastic Relaxation (S21-8)")



%%

figure
subplot(1,2,1)
plot(inst_data.Time,inst_data.Force);
grid minor
grid on
xlim([-40,3100])
xlabel("Time [$$sec$$]")
ylabel("Force [$$N$$]")
title("Instron Force vs. Time")
yline(0)

subplot(1,2,2)
plot(ext_data.Time,ext_data.("ΔL/L0"))
grid minor
grid on
xlim([-40,3100])
xlabel("Time [$$sec$$]")
ylabel("Strain [$$\Delta L / L0$$]")
title("Extensometer Strain vs. Time")
yline(0)

sgtitle("Plastic Relaxation (S21-8)")


figure
subplot(1,2,1)
plot(inst_data.Time,inst_data.Force);
grid minor
grid on
xlim([-40,3100])
xlabel("Time [$$sec$$]")
ylabel("Force [$$N$$]")
title("Instron Force vs. Time")
yline(0)

subplot(1,2,2)
plot(ext_data.Time,ext_data.("ΔL"))
grid minor
grid on
xlim([-40,3100])
xlabel("Time [$$sec$$]")
ylabel("Displacement [$$mm$$]")
title("Extensometer Displacement vs. Time")
yline(0)

sgtitle("Plastic Relaxation (S21-8)")


%% Sample 23 Specimen 4


% load(".\local\S23_4.mat")
% vic_pip = data{1,1};
% inst_data = data{1,2};
% ext_data = data{1,3}; 
% targ_var = "ΔL/L0";
% targ_var_name = "Strain";
% idx_force_strain = sync_data(vic_pip,inst_data,ext_data,false,targ_var,targ_var_name);
% idx_force_disp = data{1,4};
% 
% figure
% subplot(1,2,1)
% plot(idx_force_strain.Time,idx_force_strain.Force)
% xlabel("Time [$$sec$$]")
% ylabel("Force [$$N$$]")
% title("Force over Time")
% grid on
% grid minor
% yline(0)
% xlim([-40,4300])
% 
% subplot(1,2,2)
% plot(idx_force_strain.Time(idx_force_strain.Time >= 0),idx_force_strain.Strain(idx_force_strain.Time >= 0))
% ax = gca;
% ax.YAxis.Exponent = 0;
% ytickformat('%.3f')
% xlabel("Time [$$sec$$]")
% ylabel("Ext. Strain [$$\Delta L/L0$$]")
% title("Central Extensometer Strain over Time")
% grid on
% grid minor
% yline(0)
% xlim([-40,4300])
% 
% sgtitle("Elastic Relaxation 2 (S23-4)")
% 
% 
% figure
% subplot(1,2,1)
% plot(idx_force_strain.Time,idx_force_strain.Force)
% xlabel("Time [$$sec$$]")
% ylabel("Force [$$N$$]")
% xlim([-40,4300])
% title("Force over Time")
% grid on
% grid minor
% yline(0)
% 
% subplot(1,2,2)
% plot(idx_force_disp.Time(idx_force_disp.Time >= 0),idx_force_disp.Displacement(idx_force_disp.Time >= 0))
% ax = gca;
% ax.YAxis.Exponent = 0;
% ytickformat('%.3f')
% xlabel("Time [$$sec$$]")
% ylabel("Displacement [$$mm$$]")
% xlim([-40,4300])
% title("Central Extensometer Displacement over Time")
% grid on
% grid minor
% yline(0)
% 
% sgtitle("Elastic Relaxation 2 (S23-4)")