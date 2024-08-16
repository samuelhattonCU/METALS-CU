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

%%

% load sample15.mat
% 
% spec1_fd = data{1,4};
% spec2_fd = data{2,4};
% spec3_fd = data{3,4};
% spec5_fd = data{4,4};
% spec6_fd = data{5,4};
% spec7_fd = data{6,4};
% spec8_fd = data{7,4};
% spec9_fd = data{8,4};
% 
% target_displacements = [0.3,3.5];
% target_frame = zeros(specCount,2);
% for i = 1:specCount
%     target_frame(i,:) = find_frame(data{i,4},target_displacements);
% end
% 
% % target_im = [30 121; 23 112; 31 1210; 34 124];
% 
% %% Load Specimen 1
% 
% [s11,s11er] = frame_cleaner(load_frame_data(data{1,6},target_frame(1,1)));
% [s12,s12er] = frame_cleaner(load_frame_data(data{1,6},target_frame(1,2)));
% 
% %% Load Specimen 2
% 
% [s21,s21er] = frame_cleaner(load_frame_data(data{2,6},target_frame(2,1)));
% [s22,s22er] = frame_cleaner(load_frame_data(data{2,6},target_frame(2,2)));
% 
% %% Load Specimen 3
% 
% [s31,s31er] = frame_cleaner(load_frame_data(data{3,6},target_frame(3,1)));
% [s32,s32er] = frame_cleaner(load_frame_data(data{3,6},target_frame(3,2)));
% 
% %% Load Specimen 5
% 
% [s51,s51er,s5oer] = frame_cleaner(load_frame_data(data{4,6},target_frame(4,1)));
% [s52,s52er] = frame_cleaner(load_frame_data(data{4,6},target_frame(4,2)));
% 
% %% Load Specimen 6
% 
% [s61,s61er] = frame_cleaner(load_frame_data(data{5,6},target_frame(5,1)));
% [s62,s62er] = frame_cleaner(load_frame_data(data{5,6},target_frame(5,2)));
% 
% %% Load Specimen 7
% 
% [s71,s71er,s7oer] = frame_cleaner(load_frame_data(data{6,6},target_frame(6,1)));
% [s72,s72er] = frame_cleaner(load_frame_data(data{6,6},target_frame(6,2)));
% 
% %% Load Specimen 8
% 
% [s81,s81er,s8oer] = frame_cleaner(load_frame_data(data{7,6},target_frame(7,1)));
% [s82,s82er] = frame_cleaner(load_frame_data(data{7,6},target_frame(7,2)));
% 
% %% Load Specimen 9
% 
% [s91,s91er,s9oer] = frame_cleaner(load_frame_data(data{8,6},target_frame(8,1)));
% [s92,s92er] = frame_cleaner(load_frame_data(data{8,6},target_frame(8,2)));
% 
% %%
% 
% save sample15_frames.mat
% clear
%%

load sample15_frames.mat

%% Compare "Orientation 1"

% compare_plot(s21,s31,'eyy',["Specimen 2","Specimen 3"], "$$e_{yy}$$", "Sample 15, Specs. 2 $$\&$$ 3, 0.3mm",s21er,s31er)
% compare_plot(s22,s32,'eyy',["Specimen 2","Specimen 3"], "$$e_{yy}$$", "Sample 15, Specs. 2 $$\&$$ 3, 3.5mm",s22er,s32er)

fd_comp_plot(spec2_fd,spec3_fd,["S\#15-2","S\#15-3"], "Specimens S\#15-2 and S\#15-3, Orientation 1",12);

%% Compare "Orientation 2"

% compare_plot(s51,s61,'eyy',["Specimen 5","Specimen 6"], "$$e_{yy}$$", "Sample 15, Specs. 5 $$\&$$ 6, 0.3mm",s51er,s61er)
% compare_plot(s52,s62,'eyy',["Specimen 5","Specimen 6"], "$$e_{yy}$$", "Sample 15, Specs. 5 $$\&$$ 6, 3.5mm",s52er,s62er)

fd_comp_plot(spec5_fd,spec6_fd,["S\#15-5","S\#15-6"], "Specimens S\#15-5 and S\#15-6, Orientation 2",2);

%% Compare "Orientation 3"

% compare_plot(s81,s91,'eyy',["Specimen 8","Specimen 9"], "$$e_{yy}$$", "Sample 15, Specs. 8 $$\&$$ 9, 0.3mm",s81er,s91er)
% compare_plot(s82,s92,'eyy',["Specimen 8","Specimen 9"], "$$e_{yy}$$", "Sample 15, Specs. 8 $$\&$$ 9, 3.5mm",s82er,s92er)

fd_comp_plot(spec5_fd,spec6_fd,["S\#15-8","S\#15-9"], "Specimens S\#15-8 and S\#15-9, Orientation 3",2);

%% Compare 1 v 2

% compare_plot(s21,s51,'eyy',["Specimen 2","Specimen 5"], "$$e_{yy}$$", "Sample 15, Specs. 2 (Or. 1) $$\&$$ 5 (Or. 2), 0.3mm",s21er,s51er)
% compare_plot(s22,s52,'eyy',["Specimen 2","Specimen 5"], "$$e_{yy}$$", "Sample 15, Specs. 2 (Or. 1) $$\&$$ 5 (Or. 2), 3.5mm",s22er,s52er)

fd_comp_plot(spec2_fd,spec5_fd,["S\#15-2","S\#15-5"], "Specimens S\#15-2 (Orientation 1) and S\#15-5 (Orientation 2,$$+90^\circ$$)",4);


%% Compare 1 v 3

% compare_plot(s21,s81,'eyy',["Specimen 2","Specimen 8"], "$$e_{yy}$$", "Sample 15, Specs. 2 (Or. 1) $$\&$$ 8 (Or. 3), 0.3mm",s21er,s81er)
% compare_plot(s22,s82,'eyy',["Specimen 2","Specimen 8"], "$$e_{yy}$$", "Sample 15, Specs. 2 (Or. 1) $$\&$$ 8 (Or. 3), 3.5mm",s22er,s82er)

fd_comp_plot(spec2_fd,spec8_fd,["S\#15-2","S\#15-8"], "Specimens S\#15-2 (Orientation 1) and S\#15-8 (Orientation 3,$$+45^\circ$$)",2);

%% Compare 2 v 3

% compare_plot(s51,s81,'eyy',["Specimen 5","Specimen 8"], "$$e_{yy}$$", "Sample 15, Specs. 5 (Or. 2) $$\&$$ 8 (Or. 3), 0.3mm",s51er,s81er,s5oer,s8oer)
% compare_plot(s52,s82,'eyy',["Specimen 5","Specimen 8"], "$$e_{yy}$$", "Sample 15, Specs. 5 (Or. 2) $$\&$$ 8 (Or. 3), 3.5mm",s52er,s82er,s5oer,s8oer)

fd_comp_plot(spec5_fd,spec8_fd,["S\#15-5","S\#15-8"], "Specimens S\#15-5 (Orientation 2, $$+90^\circ$$) and S\#15-8 (Orientation 3,$$+45^\circ$$)",2);

%% Compare spray paint vs. speckle

% compare_plot(s71,s81,'eyy',["Spray Paint","2-Pass Stamp"], "$$e_{yy}$$", "Specimens S\#15-7 $$\&$$ S\#15-8, 0.3mm",s71er,s81er,s7oer,s8oer);
compare_plot(s72,s82,'eyy',["Spray Paint","2-Pass Stamp"], "$$e_{yy}$$", "Specimens S\#15-7 $$\&$$ S\#15-8, 3.5mm",s72er,s82er,s7oer,s8oer);
fd_comp_plot(spec7_fd,spec8_fd,["S\#15-7","S\#15-8"], "Specimens S\#15-7 and S\#15-8 ",2);

% compare_plot(s81,s91,'eyy',["2-Pass Stamp","3-Pass Stamp"], "$$e_{yy}$$", "Specimens S\#15-8 $$\&$$ S\#15-9, 0.3mm",s81er,s91er,s8oer,s9oer);
% compare_plot(s82,s92,'eyy',["2-Pass Stamp","3-Pass Stamp"], "$$e_{yy}$$", "Specimens S\#15-8 $$\&$$ S\#15-9, 3.5mm",s82er,s92er,s8oer,s9oer);
% fd_comp_plot(spec8_fd,spec9_fd,["S\#15-8","S\#15-9"], "Specimens S\#15-8 and S\#15-9 ",2);

%% Each orientation fd

o1.Force = mean([spec1_fd.Force,spec2_fd.Force,spec3_fd.Force],2);
o1.Displacement = mean([spec1_fd.Displacement,spec2_fd.Displacement,spec3_fd.Displacement],2);

o2.Force = mean([spec5_fd.Force(1:398),spec6_fd.Force],2);
o2.Displacement = mean([spec5_fd.Displacement(1:398),spec6_fd.Displacement],2);

o3.Force = mean([spec7_fd.Force(1:400),spec8_fd.Force,spec9_fd.Force],2);
o3.Displacement = mean([spec7_fd.Displacement(1:400),spec8_fd.Displacement,spec9_fd.Displacement],2);

% o1.Force = 

figure
subplot(1,2,1)
hold on

p1 = plot(spec1_fd.Displacement,spec1_fd.Force,'k');
plot(spec2_fd.Displacement,spec2_fd.Force,'k')
plot(spec3_fd.Displacement,spec3_fd.Force,'k')

p2 = plot(spec5_fd.Displacement,spec5_fd.Force,'r');
plot(spec6_fd.Displacement,spec6_fd.Force,'r')

p3 = plot(spec7_fd.Displacement,spec7_fd.Force,'b');
plot(spec8_fd.Displacement,spec8_fd.Force,'b')
plot(spec9_fd.Displacement,spec9_fd.Force,'b')

legend([p1,p2,p3],"0 Degrees","90 Degrees", "45 Degrees",Location="southeast")
grid on
ax = gca;
ax.GridLineWidth = 1.5;

xlabel("Displacement [mm]")
ylabel("Force [N]")
title("Individual Specimens")

subplot(1,2,2)
hold on
plot(o1.Displacement,o1.Force,'k')
plot(o2.Displacement,o2.Force,'r')
plot(o3.Displacement,o3.Force,'b')

legend("0 Degrees","90 Degrees", "45 Degrees",Location="southeast")
grid on
ax = gca;
ax.GridLineWidth = 1.5;

xlabel("Displacement [mm]")
ylabel("Force [N]")
title("Group Averages")

sgtitle("Sample 15, Aluminum 6061 Orientation Variability Tests")

fd_comp_plot(o1,o2,["0 Degrees","90 Degrees"],"Orientation Comparison, $$0^\circ$$ vs. $$90^\circ$$",2);
fd_comp_plot(o1,o3,["0 Degrees","45 Degrees"],"Orientation Comparison, $$0^\circ$$ vs. $$45^\circ$$",2);
fd_comp_plot(o3,o2,["45 Degrees","90 Degrees"],"Orientation Comparison, $$45^\circ$$ vs. $$90^\circ$$",2);


%%

% get spec 1 csvs:
% oldLoc = cd(selpath + "\" +string(data{1,5}) + "\Data Export");
% file_name = ls("*30_0.csv");
% spec1_r1 = readtable(file_name(1,:));
% file_name = ls("*121_0.csv");
% spec1_r2 = readtable(file_name(1,:));
% cd(oldLoc)
% 
% % repeat for spec 2:
% oldLoc = cd(selpath + "\" +string(data{2,5}) + "\Data Export");
% file_name = ls("*23_0.csv");
% spec2_r1 = readtable(file_name(1,:));
% file_name = ls("*112_0.csv");
% spec2_r2 = readtable(file_name(1,:));
% cd(oldLoc)
% 
% % repeat for spec 3:
% oldLoc = cd(selpath + "\" +string(data{3,5}) + "\Data Export");
% file_name = ls("*31_0.csv");
% spec3_r1 = readtable(file_name(1,:));
% file_name = ls("*121_0.csv");
% spec3_r2 = readtable(file_name(1,:));
% cd(oldLoc)
% 
% % spec 9:
% oldLoc = cd(selpath + "\" +string(data{9,5}) + "\Data Export");
% file_name = ls("*34_0.csv");
% spec9_r1 = readtable(file_name(1,:));
% file_name = ls("*124_0.csv");
% spec9_r2 = readtable(file_name(1,:));
% cd(oldLoc)
% 
% %%
% l = length(spec1_r1.sigma);
% s1_r1_bad = spec1_r1.sigma == -1;
% n = sum(s1_r1_bad);
% 
% spec1_r1_perc = 100 * n/l;
% 
% l = length(spec2_r1.sigma);
% n = sum(spec2_r1.sigma == -1);
% 
% spec2_r1_perc = 100 * n/l;
% 
% l = length(spec3_r1.sigma);
% n = sum(spec3_r1.sigma == -1);
% 
% spec3_r1_perc = 100 * n/l;
% 
% %%
% figure
% % subplot(2,3,1)
% scatter(spec1_r1.Xp(~s1_r1_bad),spec1_r1.Yp(~s1_r1_bad),10,spec1_r1.sigma(~s1_r1_bad),'.')
% 
% % subplot(2,3,2)
% % scatter(spec2_r1.Xp,spec2_r1.Yp,10,spec2_r1.sigma,'.')
% % 
% % subplot(2,3,3)
% % scatter(spec3_r1.Xp,spec3_r1.Yp,10,spec3_r1.sigma,'.')
% % 
% % subplot(2,3,4)
% % scatter(spec1_r2.Xp,spec1_r2.Yp,10,spec1_r2.sigma,'.')
% % 
% % subplot(2,3,5)
% % scatter(spec2_r2.Xp,spec2_r2.Yp,10,spec2_r2.sigma,'.')
% % 
% % subplot(2,3,6)
% % scatter(spec3_r2.Xp,spec3_r2.Yp,10,spec3_r2.sigma,'.')
% 
% 
% %%
% figure
% subplot(2,3,1)
% scatter(spec1_r1.Xp,spec1_r1.Yp,10,spec1_r1.sigma,'.')
% 
% subplot(2,3,2)
% scatter(spec2_r1.Xp,spec2_r1.Yp,10,spec2_r1.sigma,'.')
% 
% subplot(2,3,3)
% scatter(spec3_r1.Xp,spec3_r1.Yp,10,spec3_r1.sigma,'.')
% 
% subplot(2,3,4)
% scatter(spec1_r2.Xp,spec1_r2.Yp,10,spec1_r2.sigma,'.')
% 
% subplot(2,3,5)
% scatter(spec2_r2.Xp,spec2_r2.Yp,10,spec2_r2.sigma,'.')
% 
% subplot(2,3,6)
% scatter(spec3_r2.Xp,spec3_r2.Yp,10,spec3_r2.sigma,'.')

