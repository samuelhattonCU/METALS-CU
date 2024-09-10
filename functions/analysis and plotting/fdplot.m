function f = fdplot(data,titleStr,plotTime)
%{
    Samuel Hatton for METALS project
    6/3/24
    
    Plots force-displacement plots
    
    Inputs:
        data        table data type containing the test data, variable 
                    names and units
        titleStr    Optional title string
        plotTime    T/F should time be plotted or not. Default FALSE
    
    Outputs:
        f       A figure object 
    Dependencies:

%}

% make plots pretty
% set(groot,'defaultAxesTickLabelInterpreter','latex'); 
% set(groot,'defaulttextinterpreter','latex');
% set(groot,'defaultLegendInterpreter','latex');
% set(groot,'defaultAxesFontSize',14);
% set(groot,'defaultLineLineWidth',1.4);
% set(groot,'defaultAxesBox','on')
% set(groot,'defaultFontSize',14)

warning('off','MATLAB:handle_graphics:exceptions:SceneNode')

if ~exist('plotTime','var')
    plotTime = 0;
end

x = data.Displacement;
y = data.Force;

% Finding peaks works well for simply linear responses, MAPS samples are
% not linear, generally have 2 linear regions
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


% Find "change points" and use them to get linear regions
% ipts = findchangepts(data.Force,"MaxNumChanges",5);
% 
% region1 = 1:ipts(1);
% region2 = ipts(3):ipts(4);
% 
% p1 = polyfit(x(region1),y(region1),1);
% p2 = polyfit(x(region2),y(region2),1);
% 
% yfit1 = polyval(p1,x);
% yfit2 = polyval(p2,x);


% Alternative method to find linear regions:
[pks,locs] = findpeaks(data.Force);
[~,idx] = max(pks);
loc = locs(idx);
[TF,S1,S2] = ischange(data.Force(1:loc),'linear',MaxNumChanges=1);

ipt = find(TF);

region1 = 1:ipt;
region2 = ipt+1:loc;
% region2 = ipts(3):ipts(4);
x1 = x(region1);
y1 = y(region1);
x2 = x(region2);
y2 = y(region2);

p1 = polyfit(x1,y1,1);
p2 = polyfit(x2,y2,1);

% p2(2) = p2(2) - p1(2);
% p1(2) = p1(2) - p1(2);

yfit1 = polyval(p1,x1);
yfit2 = polyval(p2,x2);


f = figure;
if plotTime
    subplot(2,1,1)
end
hold on

plot(x,y)

plot(x1,yfit1)
plot(x2,yfit2)

grid minor
xlabel("Displacement (mm)")
ylabel("Force (N)")
legend("Data",...
    "Slope $\approx$ " + round(p1(1),2) + " $N/mm$",...
    "Slope $\approx$ " + round(p2(1),2) + " $N/mm$",...
    Location="best")
title("Force vs. Displacement")

if exist("titleStr",'var')
    % titleStr = "Force vs. Displacement";
    title(titleStr)
else
    title("Force vs. Displacement")
end

if plotTime
    subplot(2,1,2)
    hold on
    
    x = data.Time;
    x1 = x(region1);
    x2 = x(region2);
    
    plot(x,y)
    
    % plot(x1,yfit1)
    % plot(x2,yfit2)
   
    grid minor
    xlabel("Time (s)")
    ylabel("Force (N)")
    % legend("Data",...
        % "Slope $\approx$ " + round(p1(1),2) + " $N/s$",...
        % "Slope $\approx$ " + round(p2(1),2) + " $N/s$",...
        % Location="best")
    legend("Data",'Location','best')
    title("Force vs. Time")
end
