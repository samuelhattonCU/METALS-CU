%% Housekeeping
clear; clc; close all;

% make plots pretty
set(groot,'defaultAxesTickLabelInterpreter','latex'); 
set(groot,'defaulttextinterpreter','latex');
set(groot,'defaultLegendInterpreter','latex');
set(groot,'defaultAxesFontSize',14);
set(groot,'defaultLineLineWidth',1.5);
set(groot,'defaultAxesBox','on')
set(groot,'defaultTextFontSize',16)

% warning('off','MATLAB:handle_graphics:exceptions:SceneNode')

% Add paths to get functions, local .mats/.figs etc.
addpath("..\local\")
addpath("..\functions\analysis and plotting\")
addpath("..\functions\data loading\")

%%

load sample18.mat
data18 = data;
specCount18 = specCount;
load sample3_spec3.mat
data3_3 = data;
clear specCount data;

spec2_fd = data18{1,4};
spec3_fd = data18{2,4};
spec4_fd = data18{3,4};
spec5_fd = data18{4,4};
spec6_fd = data18{5,4};

target_displacements = [0.3,3.5];
target_frame = zeros(specCount18,2);
for i = 1:specCount18
    target_frame(i,:) = find_frame(data18{i,4},target_displacements);
end

% target_im = [31 126; 29 122; 32 126];

%% Load sample 3 specimen 3

[s331,s331er,s33oer] = frame_cleaner(load_frame_data(data3_3{1,6},23));
[s332,s332er] = frame_cleaner(load_frame_data(data3_3{1,6},117));

%% Specimen 2

[s21,s21er,s2oer] = frame_cleaner(load_frame_data(data18{1,6},target_frame(1,1)));
[s22,s22er] = frame_cleaner(load_frame_data(data18{1,6},target_frame(1,2)));

%% Specimen 3

[s31,s31er,s3oer] = frame_cleaner(load_frame_data(data18{2,6},target_frame(2,1)));
[s32,s32er] = frame_cleaner(load_frame_data(data18{2,6},target_frame(2,2)));

%% Specimen 4

[s41,s41er,s4oer] = frame_cleaner(load_frame_data(data18{3,6},target_frame(3,1)));
[s42,s42er] = frame_cleaner(load_frame_data(data18{3,6},target_frame(3,2)));

%% Specimen 5

[s51,s51er,s5oer] = frame_cleaner(load_frame_data(data18{4,6},target_frame(4,1)));
[s52,s52er] = frame_cleaner(load_frame_data(data18{4,6},target_frame(4,2)));

%% Specimen 6

[s61,s61er,s6oer] = frame_cleaner(load_frame_data(data18{5,6},target_frame(5,1)));
[s62,s62er] = frame_cleaner(load_frame_data(data18{5,6},target_frame(5,2)));

%%
% 
% save sample18_frames.mat

%%

% load sample18_frames.mat

%% Compare standard MAPS-15 w/ skinny w/ holes

% compare_plot(s331,s21,'eyy',["S\#3-3, Standard MAPS-15","S\#18-2, MAPS-15 with Small Tabs"],"$$e_{yy}$$","Samples at 0.3mm",s331er,s21er)
% compare_plot(s332,s22,'eyy',["S\#3-3, Standard MAPS-15","S\#18-2, MAPS-15 with Small Tabs"],"$$e_{yy}$$","Standard MAPS-15 vs. MAPS-15 w/ Small Grip Tabs",s332er,s22er,s33oer,s2oer,5)
% 
load s3-3-fd.mat
s3_3_fd = instData;

l = length(spec2_fd.Displacement);
force = zeros(l,1);
displacement = zeros(l,1);
for i = 1:l
    targ = spec2_fd.Displacement(i);

    dif = abs(targ - s3_3_fd.Displacement);
    [~,idx] = min(dif);

    force(i) = s3_3_fd.Force(idx);
    displacement(i) = s3_3_fd.Displacement(idx);


    % vari(i) = abs(spec2_fd.Force(i) - s3_3_fd.Force(idx));
    % percVar(i) = 100 * vari(i) / abs(spec2_fd.Force(i));
    % var(i) = abs(s3_3_fd.Force(idx) - spec2_fd.Force(i));
    % percVar(i) = 100 * var(i) / abs(s3_3_fd.Force(idx));
end
s3_3_fd = table(force,displacement,'VariableNames',["Force","Displacement"]);

fd_comp_plot(spec2_fd,s3_3_fd,["S\#3-3, Standard MAPS-15","S\#18-2, Small Tabs"],"Standard MAPS-15 vs. MAPS-15 w/ Small Grip Tabs",4,7);

% figure
% subplot(1,2,1)
% hold on
% plot(s3_3_fd.Displacement,s3_3_fd.Force,'blue')
% plot(spec2_fd.Displacement,spec2_fd.Force,'red')
% yline(0,'k')
% legend("S\#3-3, Standard MAPS-15","S\#18-2, Small Tabs",Location="northwest")
% xlabel("Displacement [mm]")
% ylabel("Force [N]")
% title("Force vs. Displacement")
% 
% 
% 
% plt_me = find(spec2_fd.Displacement < 6.2,1,'last');
% 
% subplot(1,2,2)
% yyaxis left
% plot(spec2_fd.Displacement(1:plt_me),vari(1:plt_me))
% xlabel("Displacement [mm]")
% ylabel("Variance [N]")
% % hold on
% yyaxis right
% plot(spec2_fd.Displacement(3:plt_me),percVar(3:plt_me))
% ylabel("Percent Variance")
% title("Variance Between Tests")
% sgtitle("Standard MAPS-15 vs. MAPS-15 w/ Small Grip Tabs")

%% Skinny holes vs. Skinny no holes
compare_plot(s21,s31,'eyy', ["Specimen 2","Specimen 3"], "$$e_{yy}$$", "Sample 18, Specs. 2 $$\&$$ 3, 0.3mm",s21er,s31er)
compare_plot(s22,s32,'eyy', ["S\#18-2, Holes","S\#18-3, No Holes"], "$$e_{yy}$$", "Small Grip Tab MAPS-15, Holes vs. No Holes",s22er,s32er,s2oer,s3oer)

fd_comp_plot(spec2_fd,spec3_fd,["S\#18-2, Small Tabs w/ Holes","S\#18-3, Small Tabs, No Holes"],"Small Grip Tab MAPS-15, Holes vs. No Holes",2,6);

% figure
% subplot(1,2,1)
% hold on
% plot(spec2_fd.Displacement,spec2_fd.Force,'blue')
% plot(spec3_fd.Displacement,spec3_fd.Force,'red');
% yline(0,'k')
% legend("S\#18-2, Small Tabs w/ Holes","S\#18-3, Small Tabs, No Holes",Location="best")
% xlabel("Displacement [mm]")
% ylabel("Force [N]")
% title("Force vs. Displacement")
% 
% subplot(1,2,2)
% 
% l = length(spec3_fd.Displacement);
% V = var([spec2_fd.Force(1:l)';spec3_fd.Force']);
% vari = abs(spec2_fd.Force(1:l) - spec3_fd.Force);
% percVar = 100 * V ./ abs(spec3_fd.Force);
% 
% plt_me = find(spec3_fd.Displacement <= 6,1,'last');
% 
% yyaxis left
% plot(spec3_fd.Displacement(1:plt_me),V(1:plt_me))
% ylabel("Variance [N]")
% 
% yyaxis right
% plot(spec3_fd.Displacement(2:plt_me),percVar(2:plt_me))
% ylabel("Percent Variance")
% xlabel("Displacement [mm]")
% title("Variance Between Tests")
% 
% sgtitle("Small Grip Tab MAPS-15, Holes vs. No Holes")

%% Compare two "identical" tests, 3 and 4

compare_plot(s31,s41,'eyy', ["Specimen 3","Specimen 4"],"$$e_{yy}$$","Sample 18, Specs. 3 $$\&$$ 4, 0.3mm",s31er,s41er)
compare_plot(s32,s42,'eyy', ["Specimen 3","Specimen 4"],"$$e_{yy}$$","Sample 18, Specs. 3 $$\&$$ 4, 3.5mm",s32er,s42er,s3oer,s4oer)

fd_comp_plot(spec4_fd,spec3_fd,["S\#18-4","S\#18-3"],"Specimens S\#18-3 and S\#18-4, Both MAPS-15, Thin Grips, No Holes",2,6);

% figure
% subplot(1,2,1)
% hold on
% plot(spec3_fd.Displacement,spec3_fd.Force,'blue')
% plot(spec4_fd.Displacement,spec4_fd.Force,'red')
% yline(0,'k')
% legend("S\#18-3","S\#18-4",Location="best")
% xlabel("Displacement [mm]")
% ylabel("Force [N]")
% title("Force vs. Displacement")
% grid on
% box on
% 
% subplot(1,2,2)
% 
% cmap = colororder();
% 
% l = length(spec3_fd.Displacement(spec3_fd.Displacement <= 6));
% absDif = abs(spec3_fd.Force(1:l) - spec4_fd.Force(1:l));
% meanAbsDif = mean(absDif);
% percDif = 100 * absDif ./ abs(spec3_fd.Force(1:l));
% yyaxis left
% plot(spec3_fd.Displacement(1:l),absDif)
% yline(meanAbsDif,'--','LineWidth',1.2,'Color',cmap(1,:))
% ylabel("Absolute Difference [N]")
% 
% yyaxis right
% plot(spec3_fd.Displacement(2:l),percDif(2:end))
% meanPercDif = mean(percDif(2:end));
% yline(meanPercDif,'--','LineWidth',1.2,'Color',cmap(2,:))
% legend("Absolute Difference","Mean: " + string(round(meanAbsDif,2)) + " N", "Percent Difference","Mean: " + string(round(meanPercDif,2)) + "\%")
% ylabel("Percent Difference")
% xlabel("Displacement [mm]")
% title("Absolute Difference Between Tests")
% grid("on")
% box on
% 
% sgtitle("Specimens S\#18-3 and S\#18-4, Both MAPS-15, Thin Grips, No Holes")


%% CP vs. Thick CP
% todo: determine which spec to compare with 18-5 and/or 18-6

%% Thick CP vs. "normal"



%%

% compare_plot(s31,s32,'eyy', ["Spec. 3", "Spec. 3 Later"],"$$e_{yy}$$","Sample 18, Spec 3 at 0.3 and 3.5 mm")


%% Compare 3, 4

% figure
% 
% subplot(2,2,1)
% [l,r] = get_plot_stuff(s31,'eyy');
% hold on
% contourf(l.xdat,l.ydat,l.cdat)
% contourf(r.xdat,r.ydat,r.cdat)
% cb = colorbar();
% ylabel(cb,"$$e_{yy}$$",FontSize=16,Rotation=270,Interpreter="latex")
% xlabel("Xp")
% ylabel("Yp")
% title("Specimen 3, 0.3mm")
% 
% subplot(2,2,2)
% [l,r] = get_plot_stuff(s41,'eyy');
% hold on
% contourf(l.xdat,l.ydat,l.cdat)
% contourf(r.xdat,r.ydat,r.cdat)
% cb = colorbar();
% ylabel(cb,"$$e_{yy}$$",FontSize=16,Rotation=270,Interpreter="latex")
% xlabel("Xp")
% ylabel("Yp")
% title("Specimen 4, 0.3mm")
% 
% var = spec4_r1.eyy(1:length(spec3_r1.eyy)) - spec3_r1.eyy;
% perc_var = 100 * var./spec4_r1.eyy(1:length(spec3_r1.eyy));
% rms_e = rmse(spec4_r1.eyy(1:length(spec3_r1.eyy)),spec3_r1.eyy);
% % var = s41_dirty.eyy(1:length(s31_dirty.eyy)) - s31_dirty.eyy;
% % perc_var = 100 * var./s41_dirty.eyy(1:length(s31_dirty.eyy));
% % rms_e = rmse(s41_dirty.eyy(1:length(s31_dirty.eyy)),s31_dirty.eyy);
% 
% 
% 
% subplot(2,2,3)
% scatter(spec3_r1.X,spec3_r1.Y,10,var,'.')
% % scatter(s31_dirty.X,s31_dirty.Y,10,var,'.')
% colorbar
% title("Specimens 3 $$\&$$ 4, $$e_{yy}$$ Variance")
% xlabel("$$X_p$$")
% ylabel("$$Y_p$$")
% 
% subplot(2,2,4)
% scatter(spec3_r1.X,spec3_r1.Y,10,perc_var,'.')
% % scatter(s31_dirty.X,s31_dirty.Y,10,perc_var,'.')
% colorbar
% title("Specimens 3 $$\&$$ 4, $$e_{yy}$$ $$\%$$ Variance")
% xlabel("$$X_p$$")
% ylabel("$$Y_p$$")
% 
% sgtitle("")

% lim = [min([spec3_r1.sigma;spec3_r2.sigma;spec4_r1.sigma;spec4_r1.sigma]),max([spec3_r1.sigma;spec3_r2.sigma;spec4_r1.sigma;spec4_r1.sigma])];
% 
% figure
% subplot(2,2,1)
% scatter(spec3_r1.Xp,spec3_r1.Yp,10,spec3_r1.sigma,'.')
% xlabel("Xp")
% ylabel("Yp")
% title("Specimen 3, 0.3mm displacement")
% colorbar
% clim(lim)
% 
% subplot(2,2,2)
% scatter(spec3_r2.Xp,spec3_r2.Yp,10,spec3_r2.sigma,'.')
% xlabel("Xp")
% ylabel("Yp")
% title("Specimen 3, 3.5mm displacement")
% colorbar
% clim(lim)
% 
% subplot(2,2,3)
% scatter(spec4_r1.Xp,spec4_r1.Yp,10,spec4_r1.sigma,'.')
% xlabel("Xp")
% ylabel("Yp")
% title("Specimen 4, 0.3mm displacement")
% colorbar
% clim(lim)
% 
% subplot(2,2,4)
% scatter(spec4_r2.Xp,spec4_r2.Yp,10,spec4_r2.sigma,'.')
% xlabel("Xp")
% ylabel("Yp")
% title("Specimen 4, 3.5mm displacement")
% colorbar
% clim(lim)

% figure
% 
% lims = [min([spec3_r1.eyy;spec4_r1.eyy]),max([spec3_r1.eyy;spec4_r1.eyy])];
% 
% subplot(3,2,1)
% scatter(spec3_r1.Xp,spec3_r1.Yp,10,spec3_r1.eyy,'.');
% % scatter(s31_dirty.Xp,s31_dirty.Yp,10,s31_dirty.eyy,'.');
% colorbar
% clim(lims)
% title("Specimen 3, 0.3mm")
% xlabel("$$X_p$$")
% ylabel("$$Y_p$$")
% 
% subplot(3,2,2)
% % scatter(spec4_r1.Xp,spec4_r1.Yp,10,spec4_r1.eyy,'.');
% scatter(spec4_r1.Xp(1:5:length(spec4_r1.Xp)),spec4_r1.Yp(1:5:length(spec4_r1.Xp)),10,spec4_r1.eyy(1:5:length(spec4_r1.Xp)),'.');
% % scatter(s41_dirty.Xp,s41_dirty.Yp,10,s41_dirty.eyy,'.');
% colorbar
% clim(lims)
% title("Specimen 4, 0.3mm")
% xlabel("$$X_p$$")
% ylabel("$$Y_p$$")
% 
% subplot(3,2,3)
% hold on
% plot(spec3_fd.Displacement,spec3_fd.Force)
% plot(spec4_fd.Displacement,spec4_fd.Force)
% xlabel("Displacement [mm]")
% ylabel("Force [N]")
% legend("Specimen 3", "Specimen 4")
% title("Instron Force vs. Virt. Extensometer")
% 
% subplot(3,2,4)
% plot(spec3_fd.Displacement,spec4_fd.Force(1:length(spec3_fd.Force)) - spec3_fd.Force)
% title("Specimens 3 $$\&$$ 4, Force Variance")
% xlabel("Displacement [mm]")
% ylabel("Variance [N]")
% 
% 
% 
% var = spec4_r1.eyy(1:length(spec3_r1.eyy)) - spec3_r1.eyy;
% perc_var = 100 * var./spec4_r1.eyy(1:length(spec3_r1.eyy));
% rms_e = rmse(spec4_r1.eyy(1:length(spec3_r1.eyy)),spec3_r1.eyy);
% % var = s41_dirty.eyy(1:length(s31_dirty.eyy)) - s31_dirty.eyy;
% % perc_var = 100 * var./s41_dirty.eyy(1:length(s31_dirty.eyy));
% % rms_e = rmse(s41_dirty.eyy(1:length(s31_dirty.eyy)),s31_dirty.eyy);
% 
% 
% 
% subplot(3,2,5)
% scatter(spec3_r1.X,spec3_r1.Y,10,var,'.')
% % scatter(s31_dirty.X,s31_dirty.Y,10,var,'.')
% colorbar
% title("Specimens 3 $$\&$$ 4, $$e_{yy}$$ Variance")
% xlabel("$$X_p$$")
% ylabel("$$Y_p$$")
% 
% subplot(3,2,6)
% scatter(spec3_r1.X,spec3_r1.Y,10,perc_var,'.')
% % scatter(s31_dirty.X,s31_dirty.Y,10,perc_var,'.')
% colorbar
% title("Specimens 3 $$\&$$ 4, $$e_{yy}$$ $$\%$$ Variance")
% xlabel("$$X_p$$")
% ylabel("$$Y_p$$")
% 
% % subplot(4,2,7)
% % scatter(spec3_r1.X,spec3_r1.Y,10,rms_e,'.')
% % colorbar
% % title("Specimens 3 $$\&$$ 4, $$e_{yy}$$ RMSE")
% % xlabel("$$X_p$$")
% % ylabel("$$Y_p$$")
% % 
% % subplot(4,2,8)
% % histogram(var)
% % colorbar
% % title("Specimens 3 $$\&$$ 4, $$e_{yy}$$ Variance Histogram")
% % xlabel("Variance")
% % ylabel("Occurances")

