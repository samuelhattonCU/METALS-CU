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

%% Load Data

data = readtable('/home/sam/eyrie/Documents/METALS/DATA/1kN Load Cell/1kn_hang_test_1.csv', ...
    'HeaderLines', 3, ...
    'VariableNamesLine', 2, ...
    'VariableUnitsLine', 3);
data.Force = data.Force;
data.Properties.VariableUnits{3} = '(N)';

% Create scatter plot with transparency
figure
scatter(data.Time, data.Force, 50, 'filled', 'MarkerFaceAlpha', 0.1)
% plot(data.Time,data.Force, '--')
hold on

% Find linear fit
p = polyfit(data.Time, data.Force, 1);
trend_line = polyval(p, data.Time);

% Plot trend line
plot(data.Time, trend_line, 'r-', 'LineWidth', 2)

% Add labels and title
xlabel('Time (s)')
ylabel('Force (N)')
title('Force vs Time with Linear Trend')

% Add drift rate to legend
drift_rate = p(1); % N/s
legend({'Raw Data', sprintf('Linear Trend (%.3f N/hr)', drift_rate * 60 * 60)})

grid on
hold off








