% mts_fatigue_main

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

% addpath('..\functions\data loading\')
addpath('../functions/data loading/')

%%

% Setup file path
datapath = '/media/sam/METALS extl/DATA/METALS/Fatigue/MTS/Sample 25/Data Export/';
addpath(datapath)
high_filename = "High frequency fatigue cycle - Data Acquisition 1 - (Timed).csv";
low_filename = "Low frequency fatigue cycle - Data Acquisition 1 - (Timed).csv";

% Read only the first few lines
fid = fopen(high_filename);
headers = fgetl(fid);      % Line 1: names
units   = fgetl(fid);      % Line 2: units
fclose(fid);

% Then create datastore skipping both lines
ds_high = tabularTextDatastore(high_filename, "NumHeaderLines", 2);
ds_high.VariableNames = strsplit(headers, ',');

% Read only the first few lines
fid = fopen(low_filename);
headers = fgetl(fid);      % Line 1: names
units   = fgetl(fid);      % Line 2: units
fclose(fid);

% Then create datastore skipping both lines
ds_low = tabularTextDatastore(low_filename, "NumHeaderLines", 2);
ds_low.VariableNames = strsplit(headers, ',');



% Limit columns tracked in the datastore
vars_to_keep = {'CycleCount', 'AxialDisplacement', 'AxialForce', 'RunningTime'};

ds_high.SelectedVariableNames = vars_to_keep;
ds_low.SelectedVariableNames = vars_to_keep;




prv_high = preview(ds_high)






% 
% % Create tall arrays:
% T_high = tall(ds_high);
% T_low = tall(ds_low);
% 
% % % Generate Source Column
% % T_high.Source = tall(repmat("High", height(T_high), 1));
% % T_low.Source = tall(repmat("Low", height(T_low), 1));
% % 
% % % Combine, flag, and sort data:
% T_all = [T_high; T_low];
% % T_all.hl = strcmp(T_all.Source,"High");
% T_all = sortrows(T_all, "CycleCount");
% % T_all.Source = [];
% 
% %%
% T_plot = gather(T_all(1:10000:end, ["AxialDisplacement","AxialForce"]));
% 
% figure
% plot(T_plot.AxialDisplacement,T_plot.AxialForce)
% 
% 
% 
% 
% 
% high = readtable("High frequency fatigue cycle - Data Acquisition 1 - (Timed).csv");
% low = readtable("Low frequency fatigue cycle - Data Acquisition 1 - (Timed).csv");
% 
% high{:,"Source"} = "High";
% low{:,"Source"} = "Low";
% 
% data = [high;low];
% data.hl = strcmp(data.Source,"High");

%%

% [~, idx] = sort(data.CycleCount);
% data = data(idx,:);

%%

% D = detrend(data.AxialForce);
% 
% L = data.AxialForce - D;

% figure
% plot(data.RunningTime,L)


%% Functions

function estimatedMB = estimateTallMemory(T)
% estimateTallMemory Estimate memory required to gather a tall array
%
% Usage:
%   estimatedMB = estimateTallMemory(T)
%
% Inputs:
%   T - A tall array (table or array)
%
% Outputs:
%   estimatedMB - Estimated memory usage in megabytes if T were gathered

    % Safety check
    if ~istall(T)
        error('Input must be a tall array.');
    end

    % Try to sample a chunk of the tall array (first 1000 rows)
    try
        sample = gather(T(1:1000, :));
    catch ME
        error('Failed to gather a sample from the tall array: %s', ME.message);
    end

    % Use 'whos' to get memory usage of sample
    info = whos('sample');
    bytesPerRow = info.bytes / height(sample);

    % Estimate total number of rows
    try
        nRows = gather(height(T));  % This is lightweight and doesn't materialize T
    catch ME
        error('Failed to evaluate height of the tall array: %s', ME.message);
    end

    % Estimate total memory
    estimatedBytes = bytesPerRow * nRows;
    estimatedMB = estimatedBytes / (1024^2);  % Convert to MB

    % Print estimate
    fprintf('Estimated memory required to gather tall array: %.2f MB\n', estimatedMB);
end
