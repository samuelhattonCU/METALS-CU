% Attempt to get fatigue strains for Ankita


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

data = readtable("D:\6 rectangles.csv","NumHeaderLines",2,"VariableNamesLine",2);

targ = [1,11,23,35,47,59,71];
data = data(9:end,targ);

% figure
% plot(data.Index_1_,data.e1_1__Hencky)

n = length(data.e1_1__Hencky);
nbins = fix(n/20) + 1;
vec = zeros(nbins,6);

N = 152;

for i = 1:nbins-1
    vec(i,1) = max(data.e1_1__Hencky(20*(i-1) + 1:20*i));
end
vec(end,1) = max(data.e1_1__Hencky(20 * (nbins-1) + 1:end));

for i = 1:nbins-1
    vec(i,2) = max(data.e1_1__Hencky_1(20*(i-1) + 1:20*i));
end
vec(end,2) = max(data.e1_1__Hencky_1(20 * (nbins-1) + 1:end));

for i = 1:nbins-1
    vec(i,3) = max(data.e1_1__Hencky_2(20*(i-1) + 1:20*i));
end
vec(end,3) = max(data.e1_1__Hencky_2(20 * (nbins-1) + 1:end));

for i = 1:nbins-1
    vec(i,4) = max(data.e1_1__Hencky_3(20*(i-1) + 1:20*i));
end
vec(end,4) = max(data.e1_1__Hencky_3(20 * (nbins-1) + 1:end));

for i = 1:nbins-1
    vec(i,5) = max(data.e1_1__Hencky_4(20*(i-1) + 1:20*i));
end
vec(end,5) = max(data.e1_1__Hencky_4(20 * (nbins-1) + 1:end));

for i = 1:nbins-1
    vec(i,6) = max(data.e1_1__Hencky_5(20*(i-1) + 1:20*i));
end
vec(end,6) = max(data.e1_1__Hencky_5(20 * (nbins-1) + 1:end));


vec = vec ./ 152;
sumvec = sum(vec);

%%

figure
subplot(3,2,1)
plot((1:nbins)*20,vec(:,2),'x')
grid on
xlabel("Images")
ylabel("$$\varepsilon / N$$")
title("Point R1")
legend("$$\sum_{i=1}^{23} \frac{\varepsilon^i}{N} = $$" + sumvec(2),'Location','bestoutside')

subplot(3,2,2)
plot((1:nbins)*20,vec(:,1),'x')
grid on
xlabel("Images")
ylabel("$$\varepsilon / N$$")
title("Point R0")
legend("$$\sum_{i=1}^{23} \frac{\varepsilon^i}{N} = $$" + sumvec(1),'Location','bestoutside')

subplot(3,2,3)
plot((1:nbins)*20,vec(:,4),'x')
grid on
xlabel("Images")
ylabel("$$\varepsilon / N$$")
title("Point R3")
legend("$$\sum_{i=1}^{23} \frac{\varepsilon^i}{N} = $$" + sumvec(4),'Location','bestoutside')

subplot(3,2,4)
plot((1:nbins)*20,vec(:,3),'x')
grid on
xlabel("Images")
ylabel("$$\varepsilon / N$$")
title("Point R2")
legend("$$\sum_{i=1}^{23} \frac{\varepsilon^i}{N} = $$" + sumvec(3),'Location','bestoutside')

subplot(3,2,5)
plot((1:nbins)*20,vec(:,6),'x')
grid on
xlabel("Images")
ylabel("$$\varepsilon / N$$")
title("Point R5")
legend("$$\sum_{i=1}^{23} \frac{\varepsilon^i}{N} = $$" + sumvec(6),'Location','bestoutside')

subplot(3,2,6)
plot((1:nbins)*20,vec(:,5),'x')
grid on
xlabel("Images")
ylabel("$$\varepsilon / N$$")
title("Point R4")
legend("$$\sum_{i=1}^{23} \frac{\varepsilon^i}{N} = $$" + sumvec(5),'Location','bestoutside')

%%

figure
plot(sumvec,'x')
grid on
xticks(1:6)
xticklabels(["R1","RO","R3","R2","R5","R4"])
xlim([0,7])
ylabel("$$\sum_{i=1}^{23} \frac{\varepsilon^i}{N} = $$")
xlabel("Point")
title("Integral of Strain Over Cycles")