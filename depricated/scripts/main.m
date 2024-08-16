% main
% for testing stuff

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

% cd ..\'Instron Data'\
cd ..\'Instron Data'\'Physics Batches'\
% cd ..\'Instron Data'\'physics vs rmwj'\
% addpath('..\Instron Data\')
fileList = ls('*.csv');
[numFiles,~] = size(fileList);

addpath('C:\Users\hatto\OneDrive - UCB-O365\Summer 2024\MATLAB Code')

dataArray = cell(numFiles,2);

fprintf("Files Loaded: \n")
hurb = [3 2 3; 3 2 3; 3 2 3; 3 2 3; 6 5 6; 6 5 6];
for i = 1:numFiles
    fileName = fileList(i,:);
    data = instron_csv_parser(fileName,hurb(i,1),hurb(i,2),hurb(i,3));
    dataArray{i,1} = data;
    dataArray{i,2} = fileName;
    fprintf("\t %d) %s \n", i, fileName)
end

% for i = 1:numFiles
%     data = dataArray{i,1};
%     titleStr = dataArray{i,2};
%     fdplot(data,titleStr,1);
% end

%%
figure
hold on
Legend = cell(numFiles,1);
for i = 1:numFiles
    data = dataArray{i,1};
    Legend{i} = dataArray{i,2};
    plot(data.Displacement,data.Force)
end
% Legend = {"Al6061 CP","Al6061","Metal 1 CP","Metal 1","Metal 2 CP","Metal 2","Metal 3 CP","Metal 3"};
legend(Legend,Location="best")
grid minor
xlabel("Displacement (mm)")
ylabel("Force (N)")

    


%%

% figure
% hold on
% for i = 1:numFiles
%     data = dataArray{i,1};
%     plot(data.Displacement,data.Force);
% end
% 
% grid minor
% xlabel("Displacement (mm)")
% ylabel("Force (N)")
% legend("Test 1","Test 2","Test 3", "Test 4",Location="best")
% title("Repeatable Aluminum 6061 Tests")
% 
% ax1=gca;
% 
% ax2 = axes('Position',[.3,.3,.15,.2]);
% box on
% hold on
% for i = 1:3
%     data = dataArray{i,1};
%     plot(data.Displacement(1:45),data.Force(1:45))
% end
% grid minor
% 
% ax3 = axes('Position',[.5,.3,.15,.2]);
% box on
% hold on
% for i = 1:4
%     data = dataArray{i,1};
%     plot(data.Displacement(1:45),data.Force(1:45))
% end
% grid minor

% x = data.Displacement;
% y = data.Force;
% 
% [peaks,idx] = findpeaks(y,1);
% 
% pk1 = peaks(1);
% pk1idx = idx(1);
% 
% p = polyfit(x(1:pk1idx),y(1:pk1idx),1);
% xfit = x(1:pk1idx);
% yfit = polyval(p,xfit);
% 
% peakTime = data.Time(pk1idx);
% 
% figure
% subplot(2,1,1)
% hold on
% 
% plot(x,y)
% scatter(x(pk1idx),y(pk1idx))
% plot(xfit,yfit)
% 
% grid minor
% xlabel("Displacement (mm)")
% ylabel("Force (N)")
% 
% subplot(2,1,2)
% hold on
% 
% x = data.Time;
% 
% plot(x,y)
% scatter(x(pk1idx),y(pk1idx))
% plot(x(1:pk1idx),yfit)
% 
% grid minor
% xlabel("Time (s)")
% ylabel("Force (N)")










%%


cd ..\..\'MATLAB Code'\