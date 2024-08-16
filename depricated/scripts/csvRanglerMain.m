%csvRanglerMain

%% Housekeeping
clear; clc; close all;

% make plots pretty
set(groot,'defaultAxesTickLabelInterpreter','latex'); 
set(groot,'defaulttextinterpreter','latex');
set(groot,'defaultLegendInterpreter','latex');
set(groot,'defaultAxesFontSize',12);
set(groot,'defaultLineLineWidth',1.2);

% %% Get target info
% % answer = questdlg("Choose new file?","File selection","Yes","No","No");
% % if strcmp(answer,"Yes")
% %     [file,location] = uigetfile('.csv');
% %     save prev_choice.mat file location
% % else
% %     load prev_choice.mat
% % end
% 
% %% Load in data
% 
% cl = cd(location);
% % data = readmatrix(file);
% data = readtable(file);
% cd(cl)

%% Load stuff

% dat01 = readtable("F:\DATA\METALS\Sample 15\Specimen 1\Data Export\spray-00000001_0.csv");
% dat30 = readtable("F:\DATA\METALS\Sample 15\Specimen 1\Data Export\spray-00000030_0.csv");
% dat60 = readtable("F:\DATA\METALS\Sample 15\Specimen 1\Data Export\spray-00000060_0.csv");
% dat100 = readtable("F:\DATA\METALS\Sample 15\Specimen 1\Data Export\spray-00000100_0.csv");
% dat150 = readtable("F:\DATA\METALS\Sample 15\Specimen 1\Data Export\spray-00000150_0.csv");
% dat200 = readtable("F:\DATA\METALS\Sample 15\Specimen 1\Data Export\spray-00000200_0.csv");

% dat01 = readtable("F:\DATA\METALS\Sample 7\Specimen 1\Data Export\Steel2-00000001_0.csv");
% dat30 = readtable("F:\DATA\METALS\Sample 7\Specimen 1\Data Export\Steel2-00000030_0.csv");
% dat60 = readtable("F:\DATA\METALS\Sample 7\Specimen 1\Data Export\Steel2-00000060_0.csv");
% dat100 = readtable("F:\DATA\METALS\Sample 7\Specimen 1\Data Export\Steel2-00000100_0.csv");
% dat150 = readtable("F:\DATA\METALS\Sample 7\Specimen 1\Data Export\Steel2-00000150_0.csv");
% dat200 = readtable("F:\DATA\METALS\Sample 7\Specimen 1\Data Export\Steel2-00000200_0.csv");
% dat400 = readtable("F:\DATA\METALS\Sample 7\Specimen 1\Data Export\Steel2-00000400_0.csv");
% dat600 = readtable("F:\DATA\METALS\Sample 7\Specimen 1\Data Export\Steel2-00000600_0.csv");
% dat800 = readtable("F:\DATA\METALS\Sample 7\Specimen 1\Data Export\Steel2-00000800_0.csv");
% dat1000 = readtable("F:\DATA\METALS\Sample 7\Specimen 1\Data Export\Steel2-00001000_0.csv");
% dat1200 = readtable("F:\DATA\METALS\Sample 7\Specimen 1\Data Export\Steel2-00001200_0.csv");

%%

% dat200_15 = readtable("F:\DATA\METALS\Sample 15\Specimen 1\Data Export\spray-00000200_0.csv");
% dat200_7 = readtable("F:\DATA\METALS\Sample 7\Specimen 1\Data Export\Steel2-00000200_0.csv");
% 
% figure
% hold on
% scatter(dat200_7.Xp,dat200_7.Yp,10,'r','.')
% scatter(dat200_15.Xp,dat200_15.Yp,10,'b','.')
% legend("S7-1","S15-1")
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 200")
% colorbar
% clim(lims)
% axis square

%%
% dat1_15_1 = readtable("F:\DATA\METALS\Sample 15\Specimen 1\Data Export\spray-00000001_0.csv");
% [np_1_15_1,~] = size(dat1_15_1);
% dat1_15_2 = readtable("F:\DATA\METALS\Sample 15\Specimen 2\Data Export\vic-sample15-specimen2-00000001_0.csv");
% [np_1_15_2,~] = size(dat1_15_2);
% dat1_15_3 = readtable("F:\DATA\METALS\Sample 15\Specimen 3\Data Export\vic-sample15-specimen3-00000001_0.csv");
% [np_1_15_3,~] = size(dat1_15_3);
% dat1_15_4 = readtable("F:\DATA\METALS\Sample 15\Specimen 4\Data Export\vic-sample15-specimen4-00000001_0.csv");
% [np_1_15_4,~] = size(dat1_15_4);
% dat1_15_5 = readtable("F:\DATA\METALS\Sample 15\Specimen 5\Data Export\vic-sample15-specimen5-00000001_0.csv");
% [np_1_15_5,~] = size(dat1_15_5);
% dat1_7_1 = readtable("F:\DATA\METALS\Sample 7\Specimen 1\Data Export\Steel2-00000001_0.csv");
% [np_1_7_1,~] = size(dat1_7_1);
% figure
% hold on
% scatter(dat1_7_1.Xp,dat1_7_1.Yp,10,'.')
% scatter(dat1_15_1.Xp,dat1_15_1.Yp,10,'.')
% scatter(dat1_15_2.Xp,dat1_15_2.Yp,10,'.')
% scatter(dat1_15_3.Xp,dat1_15_3.Yp,10,'.')
% scatter(dat1_15_4.Xp,dat1_15_4.Yp,10,'.')
% scatter(dat1_15_5.Xp,dat1_15_5.Yp,10,'.')
% legend("S7-1, " + string(np_1_7_1) + " points","S15-1, " + string(np_1_15_1) + " points","S15-2, " + string(np_1_15_2) + " points","S15-3, " + string(np_1_15_3) + " points","S15-4, " + string(np_1_15_4) + " points","S15-5, " + string(np_1_15_5) + " points")
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 1")
% % colorbar
% % clim(lims)
% axis square

%%
oldLoc = pwd;
answer = questdlg("Please select the 'Sample' folder you wish to process. For example, 'D:\DATA\METALS\Sample 15\'","Path Selection","Continue","Cancel","Continue");
if strcmp(answer,"Continue")
    target = uigetdir;
    cd(target);
    
    spec_list = ls("Specimen*");
    [idx,tf] = listdlg("PromptString","Select the desired specimens from the list below.",'ListString',spec_list);
    if ~tf
        fprintf("No specimen selection made, defaulting to load all specimens in the sample folder./n")
    else
        spec_list = spec_list(idx,:);
    end

    % save defaultPath.mat selpath
    % save prev_selection.mat target spec_list
else
    warning("Press 'Continue' to select a new folder, or use the previous selection instead.")
end


% target = "F:\DATA\METALS\Sample 3";
cd(target);
% spec_list = ls("Specimen*");
[spec_count,~] = size(spec_list);

num_points = zeros(spec_count,1);
num_points_dropped_cell = cell(spec_count,1);
mean_sigma_cell = cell(spec_count,1);
for i = 1:spec_count
    back = cd(spec_list(i,:) + "\Data Export");
    file_list = ls("*_0.csv");
    [file_count,~] = size(file_list);
    huh = 1:10:file_count;
    num_points_dropped = zeros(length(huh),1);
    mean_sigma = zeros(length(huh),1);
    c = 1;
    for j = huh
        fprintf("Working on " + spec_list(i,:) + ", frame " + string(j-1) + "/" + string(file_count -1) + "\n")
        data = readtable(file_list(j,:));
        l = length(data.sigma);
        bad = data.sigma == -1;
        unique_bad = unique(data.x(bad));
        n = sum(bad);
        dups = n-length(unique_bad);

        % num_points_dropped(c) = sum();

        if l ~= num_points(i)
            num_points(i) = l;
        end
        num_points_dropped(c) = 100*length(unique_bad)/(l-dups);
        mean_sigma(c) = mean(data.sigma(data.sigma ~= -1));
        c = c+1;
    end
    num_points_dropped_cell{i} = num_points_dropped;
    mean_sigma_cell{i} = mean_sigma;
    cd(back)
end
fprintf("Done lol\n")
cd(oldLoc)

%%

% figure
% hold on
% for i = 1:spec_count
%     y = num_points_dropped_cell{i};
%     plot(y);
% end
% legend(spec_list)
% ylabel("$$\#$$ Dropped Points")

figure
hold on
for i = 1:spec_count
    y = num_points_dropped_cell{i};
    % plot((y/num_points(i))*100);
    plot(num_points_dropped_cell{i})
end
legend(spec_list)
ylabel("$$\%$$ of Points Dropped")

figure
hold on
for i = 1:spec_count
    y = mean_sigma_cell{i};
    plot(y)
end
legend(spec_list)
ylabel("Mean Sigma")

%%

% target = "F:\DATA\METALS\Sample 7\Specimen 1\Data Export";
% oldLoc = cd(target);
% file_list = ls("*_0.csv");
% [file_count,~] = size(file_list);
% 
% num_points_dropped = zeros(file_count,1);
% for i = 1:file_count
%     data = readtable(file_list(i,:));
%     num_points_dropped(i) = sum(data.sigma == -1);
% end
% 
% x = 0:file_count-1;
% figure
% plot(x,num_points_dropped)
% title("Sample 7, Specimen 1 Number of Points Dropped Per Frame")
% ylabel("$$\#$$ Points Dropped")
% xlabel("Frame ID $$\#$$") 
% 
% cd(oldLoc)

%%

% target = "F:\DATA\METALS\Sample 15\Specimen 1\Data Export";
% oldLoc = cd(target);
% file_list = ls("*_0.csv");
% [file_count,~] = size(file_list);
% 
% num_points_dropped = zeros(file_count,1);
% for i = 1:file_count
%     data = readtable(file_list(i,:));
%     num_points_dropped(i) = sum(data.sigma == -1);
% end
% 
% x = 0:file_count-1;
% figure
% plot(x,num_points_dropped)
% title("Sample 15, Specimen 1 Number of Points Dropped Per Frame")
% ylabel("$$\#$$ Points Dropped")
% xlabel("Frame ID $$\#$$") 
% 
% cd(oldLoc)




%% plot?

% lims = [min([dat50.e1;dat150.e1]), max([dat50.e1;dat150.e1])];
% 
% figure
% subplot(1,3,1)
% image(imread("F:\DATA\METALS\Sample 15\Specimen 1\Data Export\aoi_ref_image.png"))
% axis square
% set(gca,'Ytick',[]) 
% set(gca,'Xtick',[])
% 
% subplot(1,3,2)
% scatter(dat50.Xp,dat50.Yp,10,dat50.e1,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 50")
% colorbar
% clim(lims)
% axis square
% 
% subplot(1,3,3)
% scatter(dat150.Xp,dat150.Yp,10,dat150.e1,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 150")
% colorbar
% clim(lims)
% axis square
% 
% sgtitle("Sample 15 Specimen 1, $$e_{xx}$$, Deformed Points")

% % % lims = [min([dat01.sigma;dat30.sigma;dat60.sigma;dat100.sigma;dat150.sigma;dat200.sigma]), max([dat01.sigma;dat30.sigma;dat60.sigma;dat100.sigma;dat150.sigma;dat200.sigma])];
% % % 
% % % figure
% % % colormap parula
% % % subplot(2,3,1)
% % % scatter(dat01.Xp,dat01.Yp,10,dat01.sigma,'.')
% % % grid minor
% % % xlabel("X")
% % % ylabel("Y")
% % % title("Frame 1")
% % % colorbar
% % % clim(lims)
% % % axis square
% % % 
% % % subplot(2,3,2)
% % % scatter(dat30.Xp,dat30.Yp,10,dat30.sigma,'.')
% % % grid minor
% % % xlabel("X")
% % % ylabel("Y")
% % % title("Frame 30")
% % % colorbar
% % % clim(lims)
% % % axis square
% % % 
% % % subplot(2,3,3)
% % % scatter(dat60.Xp,dat60.Yp,10,dat60.sigma,'.')
% % % grid minor
% % % xlabel("X")
% % % ylabel("Y")
% % % title("Frame 60")
% % % colorbar
% % % clim(lims)
% % % axis square
% % % 
% % % subplot(2,3,4)
% % % scatter(dat100.Xp,dat100.Yp,10,dat100.sigma,'.')
% % % grid minor
% % % xlabel("X")
% % % ylabel("Y")
% % % title("Frame 100")
% % % colorbar
% % % clim(lims)
% % % axis square
% % % 
% % % subplot(2,3,5)
% % % scatter(dat150.Xp,dat150.Yp,10,dat150.sigma,'.')
% % % grid minor
% % % xlabel("X")
% % % ylabel("Y")
% % % title("Frame 150")
% % % colorbar
% % % clim(lims)
% % % axis square
% % % 
% % % subplot(2,3,6)
% % % scatter(dat200.Xp,dat200.Yp,10,dat200.sigma,'.')
% % % grid minor
% % % xlabel("X")
% % % ylabel("Y")
% % % title("Frame 200")
% % % colorbar
% % % clim(lims)
% % % axis square
% % % 
% % % sgtitle("Sample 15 Specimen 1, $$sigma$$, Deformed Points")
% % % 
% % % lims = [min([dat01.eyy;dat30.eyy;dat60.eyy;dat100.eyy;dat150.eyy;dat200.eyy]), max([dat01.eyy;dat30.eyy;dat60.eyy;dat100.eyy;dat150.eyy;dat200.eyy])];
% % % 
% % % figure
% % % colormap parula
% % % subplot(2,3,1)
% % % scatter(dat01.Xp,dat01.Yp,10,dat01.eyy,'.')
% % % grid minor
% % % xlabel("X")
% % % ylabel("Y")
% % % title("Frame 1")
% % % colorbar
% % % clim(lims)
% % % axis square
% % % 
% % % subplot(2,3,2)
% % % scatter(dat30.Xp,dat30.Yp,10,dat30.eyy,'.')
% % % grid minor
% % % xlabel("X")
% % % ylabel("Y")
% % % title("Frame 30")
% % % colorbar
% % % clim(lims)
% % % axis square
% % % 
% % % subplot(2,3,3)
% % % scatter(dat60.Xp,dat60.Yp,10,dat60.eyy,'.')
% % % grid minor
% % % xlabel("X")
% % % ylabel("Y")
% % % title("Frame 60")
% % % colorbar
% % % clim(lims)
% % % axis square
% % % 
% % % subplot(2,3,4)
% % % scatter(dat100.Xp,dat100.Yp,10,dat100.eyy,'.')
% % % grid minor
% % % xlabel("X")
% % % ylabel("Y")
% % % title("Frame 100")
% % % colorbar
% % % clim(lims)
% % % axis square
% % % 
% % % subplot(2,3,5)
% % % scatter(dat150.Xp,dat150.Yp,10,dat150.eyy,'.')
% % % grid minor
% % % xlabel("X")
% % % ylabel("Y")
% % % title("Frame 150")
% % % colorbar
% % % clim(lims)
% % % axis square
% % % 
% % % subplot(2,3,6)
% % % scatter(dat200.Xp,dat200.Yp,10,dat200.eyy,'.')
% % % grid minor
% % % xlabel("X")
% % % ylabel("Y")
% % % title("Frame 200")
% % % colorbar
% % % clim(lims)
% % % axis square
% % % 
% % % sgtitle("Sample 15 Specimen 1, $$e_{yy}$$, Deformed Points")

%%



% lims = [min([dat200.exx;dat400.exx;dat600.exx;dat800.exx;dat1000.exx;dat1200.exx]), max([dat200.exx;dat400.exx;dat600.exx;dat800.exx;dat1000.exx;dat1200.exx])];
% 
% figure
% colormap turbo
% subplot(2,3,1)
% scatter(dat01.Xp,dat01.Yp,10,dat01.exx,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 1")
% colorbar
% clim(lims)
% axis square
% 
% subplot(2,3,2)
% scatter(dat30.Xp,dat30.Yp,10,dat30.exx,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 30")
% colorbar
% clim(lims)
% axis square
% 
% subplot(2,3,3)
% scatter(dat60.Xp,dat60.Yp,10,dat60.exx,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 60")
% colorbar
% clim(lims)
% axis square
% 
% subplot(2,3,4)
% scatter(dat100.Xp,dat100.Yp,10,dat100.exx,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 100")
% colorbar
% clim(lims)
% axis square
% 
% subplot(2,3,5)
% scatter(dat150.Xp,dat150.Yp,10,dat150.exx,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 150")
% colorbar
% clim(lims)
% axis square
% 
% subplot(2,3,6)
% scatter(dat200.Xp,dat200.Yp,10,dat200.exx,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 200")
% colorbar
% clim(lims)
% axis square
% 
% sgtitle("Sample 7 Specimen 1, $$e_{xx}$$, Deformed Points")
% 
% 
% 
% 
% figure
% colormap turbo
% subplot(2,3,1)
% scatter(dat200.Xp,dat200.Yp,10,dat200.exx,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 200")
% colorbar
% clim(lims)
% axis square
% 
% subplot(2,3,2)
% scatter(dat400.Xp,dat400.Yp,10,dat400.exx,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 400")
% colorbar
% clim(lims)
% axis square
% 
% subplot(2,3,3)
% scatter(dat600.Xp,dat600.Yp,10,dat600.exx,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 600")
% colorbar
% clim(lims)
% axis square
% 
% subplot(2,3,4)
% scatter(dat800.Xp,dat800.Yp,10,dat800.exx,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 800")
% colorbar
% clim(lims)
% axis square
% 
% subplot(2,3,5)
% scatter(dat1000.Xp,dat1000.Yp,10,dat1000.exx,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 1000")
% colorbar
% clim(lims)
% axis square
% 
% subplot(2,3,6)
% scatter(dat1200.Xp,dat1200.Yp,10,dat1200.exx,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 1200")
% colorbar
% clim(lims)
% axis square
% 
% sgtitle("Sample 7 Specimen 1, $$e_{xx}$$, Deformed Points")
% 
% 
% 
% figure
% colormap turbo
% subplot(2,3,1)
% scatter(dat200.X,dat200.Y,10,dat200.exx,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 200")
% colorbar
% clim(lims)
% axis square
% 
% subplot(2,3,2)
% scatter(dat400.X,dat400.Y,10,dat400.exx,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 400")
% colorbar
% clim(lims)
% axis square
% 
% subplot(2,3,3)
% scatter(dat600.X,dat600.Y,10,dat600.exx,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 600")
% colorbar
% clim(lims)
% axis square
% 
% subplot(2,3,4)
% scatter(dat800.X,dat800.Y,10,dat800.exx,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 800")
% colorbar
% clim(lims)
% axis square
% 
% subplot(2,3,5)
% scatter(dat1000.X,dat1000.Y,10,dat1000.exx,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 1000")
% colorbar
% clim(lims)
% axis square
% 
% subplot(2,3,6)
% scatter(dat1200.X,dat1200.Y,10,dat1200.exx,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 1200")
% colorbar
% clim(lims)
% axis square
% 
% sgtitle("Sample 7 Specimen 1, $$e_{xx}$$, Original Points")
% 
% %%
% 
% lims = [min([dat01.sigma;dat30.sigma;dat60.sigma;dat100.sigma;dat150.sigma;dat200.sigma]), max([dat01.sigma;dat30.sigma;dat60.sigma;dat100.sigma;dat150.sigma;dat200.sigma])];
% 
% figure
% colormap parula
% subplot(2,3,1)
% scatter(dat01.Xp,dat01.Yp,10,dat01.sigma,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 1")
% colorbar
% clim(lims)
% axis square
% 
% subplot(2,3,2)
% scatter(dat30.Xp,dat30.Yp,10,dat30.sigma,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 30")
% colorbar
% clim(lims)
% axis square
% 
% subplot(2,3,3)
% scatter(dat60.Xp,dat60.Yp,10,dat60.sigma,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 60")
% colorbar
% clim(lims)
% axis square
% 
% subplot(2,3,4)
% scatter(dat100.Xp,dat100.Yp,10,dat100.sigma,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 100")
% colorbar
% clim(lims)
% axis square
% 
% subplot(2,3,5)
% scatter(dat150.Xp,dat150.Yp,10,dat150.sigma,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 150")
% colorbar
% clim(lims)
% axis square
% 
% subplot(2,3,6)
% scatter(dat200.Xp,dat200.Yp,10,dat200.sigma,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 200")
% colorbar
% clim(lims)
% axis square
% 
% sgtitle("Sample 7 Specimen 1, $$sigma$$, Deformed Points")
% 
% lims = [min([dat200.sigma;dat400.sigma;dat600.sigma;dat800.sigma;dat1000.sigma;dat1200.sigma]), max([dat200.sigma;dat400.sigma;dat600.sigma;dat800.sigma;dat1000.sigma;dat1200.sigma])];
% 
% %%
% 
% figure
% colormap parula
% subplot(2,3,1)
% scatter(dat200.Xp,dat200.Yp,10,dat200.sigma,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 200")
% colorbar
% clim(lims)
% axis square
% 
% subplot(2,3,2)
% scatter(dat400.Xp,dat400.Yp,10,dat400.sigma,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 400")
% colorbar
% clim(lims)
% axis square
% 
% subplot(2,3,3)
% scatter(dat600.Xp,dat600.Yp,10,dat600.sigma,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 600")
% colorbar
% clim(lims)
% axis square
% 
% subplot(2,3,4)
% scatter(dat800.Xp,dat800.Yp,10,dat800.sigma,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 800")
% colorbar
% clim(lims)
% axis square
% 
% subplot(2,3,5)
% scatter(dat1000.Xp,dat1000.Yp,10,dat1000.sigma,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 1000")
% colorbar
% clim(lims)
% axis square
% 
% subplot(2,3,6)
% scatter(dat1200.Xp,dat1200.Yp,10,dat1200.sigma,'.')
% grid minor
% xlabel("X")
% ylabel("Y")
% title("Frame 1200")
% colorbar
% clim(lims)
% axis square
% 
% sgtitle("Sample 7 Specimen 1, $$sigma$$, Deformed Points")
