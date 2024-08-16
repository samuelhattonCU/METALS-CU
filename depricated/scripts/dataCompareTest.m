
%% Housekeeping
clear; clc; close all;

% make plots pretty
set(groot,'defaultAxesTickLabelInterpreter','latex'); 
set(groot,'defaulttextinterpreter','latex');
set(groot,'defaultLegendInterpreter','latex');
set(groot,'defaultAxesFontSize',12);
set(groot,'defaultLineLineWidth',1.2);
% warning('off','MATLAB:handle_graphics:exceptions:SceneNode')

%% Code

% load data
instData = instron_csv_parser("C:\Users\hatto\OneDrive - UCB-O365\Summer 2024\DATA\Sample 3\Specimen 2\Data Export\MAPS15_sample3_specimen2_al6061.csv");
extData = vicExtensometer_csv_parser("C:\Users\hatto\OneDrive - UCB-O365\Summer 2024\DATA\Sample 3\Specimen 2\Data Export\S3_2_extensometer_deltaL.csv");

% find where force starts
tf = ischange(diff(instData.Force));
idx = find(tf);
inst_st_pt = idx(1);

% trim Instron data:
instData = instData(inst_st_pt:end,:);

% zero Instron Time:
instData.Time = instData.Time - instData.Time(1);

% find where extensometer starts to change:
idx = find(diff(extData.x_L_L0_1_) >= 0.0001);
vic_st_pt = idx(1);

% trim vic extensometer data:
extData = extData(vic_st_pt:end,:);

% Generate frame time:
fps = 5; % Hz
ts = 1/fps; % sec
extData.Time = (0:ts:(length(extData.Index_1_)*ts-ts))';

% trim extensometer data based on length of instron data:
endTime = instData.Time(end);
extData = extData(extData.Time <= endTime,:);

% create truncated instron data that matches 1to1 w/ ext. data
idx = zeros(length(extData.Time),1);
for i = 1:length(extData.Time)
    tf = round(instData.Time,1) == floor((extData.Time(i))*10)/10;
    if sum(tf) == 0
        error("No Matching Time for time " + string(extData.Time(i)))
    end
    locs = find(tf);
    idx(i) = locs(1);
end

instData = instData(idx,:);

% outTab = table('VariableNames',["Index [1]", "DIC Displacement (35 mm GL) [mm]", "Force (N)-Experiement"]);

% create export force/disp csv file
outTab = table(extData.Index_1_, extData.x_L_mm_, instData.Force);
outTab.Properties.VariableNames = {'Index [1]','DIC Displacement (35 mm GL) [mm]','Force (N)-Experiment',};
if extData.Index_1_(1) ~= 0
    zerosTab = table(0,0,0,'VariableNames',{'Index [1]','DIC Displacement (35 mm GL) [mm]','Force (N)-Experiment',});
    outTab = [zerosTab;outTab];
end

% Plot?
disp = extData.x_L_mm_;
force = instData.Force;
figure
plot(disp,force)
xlabel("Displacement [mm]")
ylabel("Force [N]")




