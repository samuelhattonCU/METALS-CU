% frfrmain.m
%
% DEPRECATED
%
% CU Boulder METALS Project
% Comments updated: 01/13/2025
% Samuel Hatton
%
%
% Purpose
%     Analysis script for force-displacement relationships
%     Compares data across multiple specimen orientations
% Usage
%     Run script to generate force vs displacement plots
% Methodology
%     1. Selects sample group using interactive dialog
%     2. Loads test data for selected specimens
%     3. Creates force vs displacement plots
%     4. Optional: Calculates averages across orientations
% Dependencies
%     sample_select    Custom function
%     load_sample      Custom function
%     av_across_specs  Custom function

%% Housekeeping
clear; clc; close all;

% make plots pretty
set(groot,'defaultAxesTickLabelInterpreter','latex');
set(groot,'defaulttextinterpreter','latex');
set(groot,'defaultLegendInterpreter','latex');
set(groot,'defaultAxesFontSize',12);
set(groot,'defaultLineLineWidth',1.2);
% warning('off','MATLAB:handle_graphics:exceptions:SceneNode')

%% Select a Sample Group to analyse

[selpath,spec_list] = sample_select;

%% Load testwide Data

[data,specCount] = load_sample(selpath,spec_list,1);

%% Hmm

%% Do some force disp analysis

figure
hold on
for i = 1:specCount
    fdtab = data{i,4};
    plot(fdtab.Displacement,fdtab.Force)
end
spec_names = cell2mat(data(:,5));
legend(spec_names,Location="southeast")
xlabel("Displacement [mm]")
ylabel("Force [N]")
grid minor
% ylim([0,14000])


% [o1_disp_av,o1_force_av] = av_across_specs(data,1:3);
% [o2_disp_av,o2_force_av] = av_across_specs(data,5:6);
% [o3_disp_av,o3_force_av] = av_across_specs(data,7:9);
%
% figure
% hold on
% plot(o1_disp_av,o1_force_av)
% plot(o2_disp_av,o2_force_av)
% plot(o3_disp_av,o3_force_av)
%
% spec_names = ["Orientation 1","Orientation 2","Orientation 3"];
% legend(spec_names,Location="southeast")
% xlabel("Displacement [mm]")
% ylabel("Force [N]")
% grid minor
% ylim([0,14000])
% title("Orientation Averages")



% %% Return to code directory
% cd(codeLoc)


%%

