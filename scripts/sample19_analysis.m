% want to quickly plot s19-9 fd graph

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

addpath('..\analysis and plotting\')

%% 19-9
fd2 = readtable("D:\DATA\METALS\Sample 19\Specimen 2\instron_MAPS15-mods_S19-2.csv","NumHeaderLines",8,"VariableNamesLine",7,"VariableUnitsLine",8);
fd = readtable("D:\DATA\METALS\Sample 19\Specimen 9\instron_MAPS15-mods_S19-9-COMBO.csv","NumHeaderLines",8,"VariableNamesLine",7,"VariableUnitsLine",8);
% fdplot(fd,"Sample 19-9, Symmetric MAPS Design");
figure
plot(fd.Displacement,fd.Force)
xlabel("Displacement (mm)")
ylabel("Force (N)")
title("Sample 19-9, Symmetric MAPS Design")
grid on
hold on
plot(fd2.Displacement,fd2.Force)
legend("S19-9 (Symmetric)","S19-2 (MAPS-15)")

