% plot temp over time hacky script

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

% dat = readtable("C:\Users\hatto\OneDrive - UCB-O365\Summer 2024\METALS Documents\FLIR Stuff\baseline_tempcurve.csv");
dat = readtable("C:\Users\Samuel\OneDrive - UCB-O365\Summer 2024\METALS Documents\FLIR Stuff\baseline_tempcurve.csv");
dat = dat(1:end-1,:);
dat.reltime = dat.reltime / 60;
figure
hold on
pc1 = plot(dat.reltime,dat.Rec_0006_seq_Cursor1_C__mean);
pc2 = plot(dat.reltime,dat.Rec_0006_seq_Cursor2_C__mean);
pc3 = plot(dat.reltime,dat.Rec_0006_seq_Cursor3_C__mean);
xlabel("Time [$$min$$]")
ylabel("Temp [$$C$$]")


idk = 64750;
% 

f1 = fit(dat.reltime(idk:end),dat.Rec_0006_seq_Cursor1_C__mean(idk:end),'exp2');
f2 = fit(dat.reltime(idk:end),dat.Rec_0006_seq_Cursor2_C__mean(idk:end),'exp2');
f3 = fit(dat.reltime(idk:end),dat.Rec_0006_seq_Cursor3_C__mean(idk:end),'exp2');

y = @(f,x) f.a * exp(f.b * x) + f.c * exp(f.d * x);
t = round(dat.reltime(idk)):.1:75;
y1 = y(f1,t);
y2 = y(f2,t);
y3 = y(f3,t);

fitp = plot(t,y1,'--k');
plot(t,y2,'--k')
% plot(t,y3,'--k')
rt = yline(dat.Rec_0006_seq_Cursor1_C__mean(1),'--');



maxT = max(dat.Rec_0006_seq_Cursor1_C__mean);
strt = find(dat.Rec_0006_seq_Cursor1_C__mean > maxT-5,1);


bands = [dat.reltime(1) dat.reltime(strt); ...
         dat.reltime(strt+1) dat.reltime(idk); ...
         dat.reltime(idk+1) 75];

xp = [bands fliplr(bands)];
yp = ([[1;1]*min(ylim); [1;1]*max(ylim)]*ones(1,size(bands,1))).';
grab = cell(1,3);
c = [1 0 0; 0 1 1; 0 0 1];
for k = 1:size(bands,1)                                                             
    grab{k} = patch(xp(k,:), yp(k,:), c(k,:)*0.75, 'FaceAlpha',0.25, 'EdgeColor',c(k,:)*0.75);
end

legend([pc1,pc2,pc3,fitp,rt,grab{1},grab{2},grab{3}],"Upper Left Arm","Upper Right Arm","Central Bottom","Exponential Fit","Room Temp $$\approx 23^\circ C$$","Heating $$\approx 11\;min$$","Steady State ($$262\pm 2.5^\circ C$$)","Cooling $$\approx 40\;min$$")
xlim([0,75])
title("Heating/Cooling Profile, $$T_{set} \approx 400^\circ C$$")
grid on
grid minor
hold off

% bands = [214 216; 221 223];                                                         % X-Coordinates Of Band Limits: [x(1,1) x(1,2); x(2,1) x(2,2)]
% figure
% plot(x, y)
% hold on
% xp = [bands fliplr(bands)];                                                         % X-Coordinate Band Definitions 
% yp = ([[1;1]*min(ylim); [1;1]*max(ylim)]*ones(1,size(bands,1))).';                  % Y-Coordinate Band Definitions
% for k = 1:size(bands,1)                                                             % Plot Bands
%     patch(xp(k,:), yp(k,:), [1 1 1]*0.25, 'FaceAlpha',0.5, 'EdgeColor',[1 1 1]*0.25)
% end
% hold off



% tp = fit(p,dat.reltime(idk):75,'exp1');
% plot(dat.reltime(idk):75,tp,'r--')
% figure
% plot(dat.reltime(idk):75,y(dat.reltime(idk):75))
% yline(dat.Rec_0006_seq_Cursor1_C__mean(1),'--')

