% import disparate csv's and combine, extracting the e1 hencky strain for
% every point in each csv
%%
clear;clc;close all;
%% Load Data from the instron

path = "C:\Users\Sandro\Desktop\Ankita\Accelerated fatigue testing\Fatigue Test\Fatigue Test (0.2 mm per sec)Fatigue demo test\";
f5_path = path + "Fatigue 5\Set II\Strain points_Fatigue 5(12.3).csv";
f6_path = path + "Fatigue 6\Crack tracking points_Fatigue 6(13.2).csv";
f8_path = path + "Fatigue 8\Strain points_Fatigue 8 (13.4).csv";
f9_path = path + "Fatigue 9\Strain points_Fatigue 9 (13.5).csv";

%%
f5_data = get_e1_from_csv(f5_path);
f6_data = get_e1_from_csv(f6_path);
f8_data = get_e1_from_csv(f8_path);
f9_data = get_e1_from_csv(f9_path);

%% Plot P0, P1, P2,P4 for individual test

% Fatigue 5
figure
x5o = f5_data.index;
y5o = f5_data.e1_1__Hencky_1_P0;
p5o = plot(x5o,y5o);
xlim([0,2700]);
ylim([-0.01,.05]);
xline(1091,'--k','LineWidth',1);
hold on
y51 = f5_data.e1_1__Hencky_2_P1;
p51 = plot(x5o,y51);
y52 = f5_data.e1_1__Hencky_3_P2;
p52 = plot(x5o,y52);
y53 = f5_data.e1_1__Hencky_4_P3;
p53 = plot(x5o, y53);
y54 = f5_data.e1_1__Hencky_5_P4;
p54 = plot (x5o,y54);
hold off
grid minor
grid on
legend([p5o,p51,p52,p53,p54],"Po","P1","P2","P3","P4")
title("Fatigue 5 [Dmax=0.15 mm, Dmin=0.02 mm, Dmax/Dmin = 7.5, T = 1.3 sec]")
xlabel("Image Index")
ylabel("e_1 henckey")
%%
% Fatigue 6_First element_R
subplot(3,1,1);
x6o = f6_data.index;
y6o = f6_data.e1_1__Hencky_1_P0;
p6o = plot(x6o,y6o);
xlim([0,3200]);
ylim([-0.05,.2]);
xline(1086,'--k','LineWidth',1);
xline(1565,'r','LineWidth',1);
hold on
y61 = f6_data.e1_1__Hencky_2_P1;
p61 = plot(x6o,y61);
y62 = f6_data.e1_1__Hencky_8_P2;
p62 = plot(x6o,y62);
y63 = f6_data.e1_1__Hencky_9_P3;
p63 = plot(x6o, y63);
y64 = f6_data.e1_1__Hencky_10_P4;
p64 = plot(x6o,y64);
hold off
grid minor
grid on
legend([p6o,p61,p62,p63,p64],"Po","P1","P2","P3","P4")
title("Fatigue 6 [Dmax=0.5 mm, Dmin=0.05 mm, Dmax/Dmin = 10, T = 4.5 sec]")

% Fatigue 6_second element_R
subplot(3,1,2);
x6o = f6_data.index;
y65 = f6_data.e1_1__Hencky_11_P5;
p65 = plot(x6o,y65);
xlim([0,3200]);
ylim([-0.05,.2]);
xline(1552,'--k','LineWidth',1);
xline(1805,'r','LineWidth',1);
hold on
y66 = f6_data.e1_1__Hencky_12_P6;
p66 = plot(x6o,y66);
y67 = f6_data.e1_1__Hencky_13_P7;
p67 = plot(x6o,y67);
y68 = f6_data.e1_1__Hencky_14_P8;
p68 = plot(x6o, y68);
y69 = f6_data.e1_1__Hencky_15_P9;
p69 = plot(x6o,y69);
hold off
grid minor
grid on
legend([p65,p66,p67,p68,p69],"P5","P6","P7","P8","P9")

% Fatigue 6_third element_R
subplot(3,1,3);
x6o = f6_data.index;
y610 = f6_data.e1_1__Hencky_3_P10;
p610 = plot(x6o,y610);
xlim([0,3200]);
ylim([-0.05,.2]);
xline(1685,'--k','LineWidth',1);
hold on
y611 = f6_data.e1_1__Hencky_4_P11;
p611 = plot(x6o,y611);
y612 = f6_data.e1_1__Hencky_5_P12;
p612 = plot(x6o,y612);
y613 = f6_data.e1_1__Hencky_6_P13;
p613 = plot(x6o, y613);
y614 = f6_data.e1_1__Hencky_7_P14;
p614 = plot(x6o,y614);
hold off
grid minor
grid on
legend([p610,p611,p612,p613,p614],"P10","P11","P12","P13","P14")
xlabel("Image Index")
ylabel("e_1 henckey")

%%
% Fatigue 8_First element_L
subplot(3,2,1);
x8o = f8_data.index;
y816 = f8_data.e1_1__Hencky_9_P16;
p816 = plot(x8o,y816);
xlim([0,350]);
ylim([-0.01,.15]);
xline(207,'--k','LineWidth',1);
hold on
y817 = f8_data.e1_1__Hencky_10_P17;
p817 = plot(x8o,y817);
y818 = f8_data.e1_1__Hencky_11_P18;
p818 = plot(x8o,y818);
y83 = f8_data.e1_1__Hencky_12_P19;
p83 = plot(x8o, y83);
y820 = f8_data.e1_1__Hencky_14_P20;
p820 = plot(x8o,y820);
hold off
grid minor
grid on
legend([p816,p817,p818,p83,p820],"P16","P17","P18","P19","P20")
title("Fatigue 8 [Dmax=1 mm, Dmin=0.2 mm, Dmax/Dmin = 5, T = 8 sec]")
xlabel("Image Index")
ylabel("e_1 henckey")

% Fatigue 8_First element_R
subplot(3,2,2);
x8o = f8_data.index;
y8o = f8_data.e1_1__Hencky_1_P0;
p8o = plot(x8o,y8o);
xlim([0,350]);
ylim([-0.01,.15]);
xline(154,'--k','LineWidth',1);
xline(307,'r','LineWidth',1);
hold on
y81 = f8_data.e1_1__Hencky_2_P1;
p81 = plot(x8o,y81);
y82 = f8_data.e1_1__Hencky_13_P2;
p82 = plot(x8o,y82);
y83 = f8_data.e1_1__Hencky_21_P3;
p83 = plot(x8o, y83);
y84 = f8_data.e1_1__Hencky_22_P4;
p84 = plot(x8o,y84);
hold off
grid minor
grid on
legend([p8o,p81,p82,p83,p84],"Po","P1","P2","P3","P4")
xlabel("Image Index")
ylabel("e_1 henckey")

% Fatigue 8_Second element_L
subplot(3,2,3);
x8o = f8_data.index;
y821 = f8_data.e1_1__Hencky_15_P21;
p821 = plot(x8o,y821);
xlim([0,350]);
ylim([-0.01,.15]);
xline(234,'--k','LineWidth',1);
hold on
y822 = f8_data.e1_1__Hencky_16_P22;
p822 = plot(x8o,y822);
y823 = f8_data.e1_1__Hencky_17_P23;
p823 = plot(x8o,y823);
hold off
grid minor
grid on
legend([p821,p822,p823],"P21","P22","P23")
xlabel("Image Index")
ylabel("e_1 henckey")

% Fatigue 8_Second element_R
subplot(3,2,4);
x8o = f8_data.index;
y85 = f8_data.e1_1__Hencky_23_P5;
p810 = plot(x8o,y85);
xlim([0,350]);
ylim([-0.01,.15]);
xline(207,'--k','LineWidth',1);
xline(307,'r','LineWidth',1);
hold on
y86 = f8_data.e1_1__Hencky_24_P6;
p811 = plot(x8o,y86);
y812 = f8_data.e1_1__Hencky_25_P7;
p812 = plot(x8o,y812);
y88 = f8_data.e1_1__Hencky_26_P8;
p88 = plot(x8o, y88);
y814 = f8_data.e1_1__Hencky_27_P9;
p814 = plot(x8o,y814);
hold off
grid minor
grid on
legend([p810,p811,p812,p88,p814],"P5","P6","P7","P8","P9")
xlabel("Image Index")
ylabel("e_1 henckey")

% Fatigue 8_Third element_L
subplot(3,2,5);
x8o = f8_data.index;
y824 = f8_data.e1_1__Hencky_18_P24;
p824 = plot(x8o,y824);
xlim([0,350]);
ylim([-0.01,.15]);
xline(287,'--k','LineWidth',1);
hold on
y825 = f8_data.e1_1__Hencky_19_P25;
p825 = plot(x8o,y825);
y826 = f8_data.e1_1__Hencky_20_P26;
p826 = plot(x8o,y826);
hold off
grid minor
grid on
legend([p824,p825,p826],"P24","P25","P26")
xlabel("Image Index")
ylabel("e_1 henckey")

% Fatigue 8_Third element_R
subplot(3,2,6);
x8o = f8_data.index;
y810 = f8_data.e1_1__Hencky_3_P10;
p810 = plot(x8o,y85);
xlim([0,350]);
ylim([-0.01,.15]);
xline(252,'--k','LineWidth',1);
xline(328,'r','LineWidth',1);
hold on
y811 = f8_data.e1_1__Hencky_4_P11;
p811 = plot(x8o,y811);
y812 = f8_data.e1_1__Hencky_5_P12;
p812 = plot(x8o,y812);
y813 = f8_data.e1_1__Hencky_6_P13;
p813 = plot(x8o, y813);
y814 = f8_data.e1_1__Hencky_7_P14;
p814 = plot(x8o,y814);
y815 = f8_data.e1_1__Hencky_8_P15;
p815 = plot(x8o,y815);
hold off
grid minor
grid on
legend([p810,p811,p812,p813,p814,p815],"P10","P11","P12","P13","P14","P15")
xlabel("Image Index")
ylabel("e_1 henckey")



%%
% Fatigue 9_First element_R
subplot(3,2,2);
x9o = f9_data.index;
y9o = f9_data.e1_1__Hencky_1_P0;
p9o = plot(x9o,y9o);
xlim([0,800]);
ylim([-0.01,.2]);
xline(65,'--k','LineWidth',1);
xline(731,'r','LineWidth',1);
hold on
y91 = f9_data.e1_1__Hencky_2_P1;
p91 = plot(x9o,y91);
y92 = f9_data.e1_1__Hencky_10_P2;
p92 = plot(x9o,y92);
y93 = f9_data.e1_1__Hencky_11_P3;
p93 = plot(x9o, y93);
y94 = f9_data.e1_1__Hencky_12_P4;
p94 = plot(x9o,y94);
hold off
grid minor
grid on
legend([p9o,p91,p92,p93,p94],"Po","P1","P2","P3","P4")
title("Fatigue 9 [Dmax=0.75 mm, Dmin=0.3 mm, Dmax/Dmin = 2.5, T = 4.5 sec]")

% Fatigue 9_Second element_R
subplot(3,2,4);
x9o = f9_data.index;
y95 = f9_data.e1_1__Hencky_13_P5;
p95 = plot(x9o,y95);
xlim([0,800]);
ylim([-0.01,.2]);
xline(573,'--k','LineWidth',1);
hold on
y96 = f9_data.e1_1__Hencky_14_P6;
p96 = plot(x9o,y96);
y97 = f9_data.e1_1__Hencky_15_P7;
p97 = plot(x9o,y97);
y98 = f9_data.e1_1__Hencky_16_P8;
p98 = plot(x9o, y98);
y99 = f9_data.e1_1__Hencky_17_P9;
p99 = plot(x9o,y99);
hold off
grid minor
grid on
legend([p95,p96,p97,p98,p99],"P5","P6","P7","P8","P9")

% Fatigue 9_Third element_L
subplot(3,2,5);
x9o = f9_data.index;
y915 = f9_data.e1_1__Hencky_8_P15;
p915 = plot(x9o,y915);
xlim([0,800]);
ylim([-0.01,.2]);
xline(702,'--k','LineWidth',1);
hold on
y916 = f9_data.e1_1__Hencky_9_P16;
p916 = plot(x9o,y916);
hold off
grid minor
grid on
legend([p915,p916],"P15","P16")
ylabel("e_1 henckey")

% Fatigue 9_Third element_R
subplot(3,2,6);
x9o = f9_data.index;
y910 = f9_data.e1_1__Hencky_3_P10;
p910 = plot(x9o,y910);
xlim([0,800]);
ylim([-0.01,.2]);
xline(655,'--k','LineWidth',1);
hold on
y911 = f9_data.e1_1__Hencky_4_P11;
p911 = plot(x9o,y911);
y912 = f9_data.e1_1__Hencky_5_P12;
p912 = plot(x9o,y912);
y913 = f9_data.e1_1__Hencky_6_P13;
p913 = plot(x9o, y913);
y914 = f9_data.e1_1__Hencky_7_P14;
p914 = plot(x9o,y914);
hold off
grid minor
grid on
legend([p910,p911,p912,p913,p914],"P10","P11","P12","P13","P14")
xlabel("Image Index")


%% Plotting P0 of all the tests
figure
subplot(5,1,1);
sgtitle('Variation of strain along the crack propogation on first vertical element for different tests')
x5 = f5_data.index;
y5 = f5_data.e1_1__Hencky_1_P0;
p5 = plot (x5,y5);
xlim([0,2700]);
ylim([-0.05,.15]);
xline(1091,'--','LineWidth',2,'Color',p5.Color);
hold on
x6 = f6_data.index;
y6 = f6_data.e1_1__Hencky_1_P0;
p6 = plot(x6,y6);
xline(1086,'--','LineWidth',2,'color',p6.Color);
xline(1565,'linewidth',2,'Color',p6.Color);
x8 = f8_data.index;
y8 = f8_data.e1_1__Hencky_1_P0;
p8 = plot(x8,y8);
xline(154,'--','LineWidth',2,'Color',p8.Color);
xline(308,'linewidth',2,'Color',p8.Color);
x9 = f9_data.index;
y9 = f9_data.e1_1__Hencky_1_P0;
p9 = plot(x9, y9);
xline(65,'--','LineWidth',2,'color',p9.Color);
xline(731,'linewidth',2,'Color',p9.Color);
hold off
grid minor
grid on
ylabel("Hencky e_1")
legend([p5,p6,p8,p9],"Fatigue 5","Fatigue 6","Fatigue 8","Fatigue 9")
%% %Plotting P1 of all the tests
subplot(5,1,2);
x5 = f5_data.index;
y5 = f5_data.e1_1__Hencky_2_P1;
p5 = plot (x5,y5);
xlim([0,2700]);
ylim([-0.05,.15]);
xline(1091,'--','LineWidth',2,'Color',p5.Color);
hold on
x6 = f6_data.index;
y6 = f6_data.e1_1__Hencky_2_P1;
p6 = plot(x6,y6);
xline(1086,'--','LineWidth',2,'color',p6.Color);
xline(1565,'linewidth',2,'Color',p6.Color);
x8 = f8_data.index;
y8 = f8_data.e1_1__Hencky_2_P1;
p8 = plot(x8,y8);
xline(154,'--','LineWidth',2,'Color',p8.Color);
xline(308,'linewidth',2,'Color',p8.Color);
x9 = f9_data.index;
y9 = f9_data.e1_1__Hencky_2_P1;
p9 = plot(x9, y9);
xline(65,'--','LineWidth',2,'color',p9.Color);
xline(731,'linewidth',2,'Color',p9.Color);
hold off
grid minor
grid on
ylabel("Hencky e_1")
%%  %Plotting P2 of all the tests
subplot(5,1,3);
x5 = f5_data.index;
y5 = f5_data.e1_1__Hencky_3_P2;
p5 = plot (x5,y5);
xlim([0,2700]);
ylim([-0.05,.15]);
xline(1091,'--','LineWidth',2,'Color',p5.Color);
hold on
x6 = f6_data.index;
y6 = f6_data.e1_1__Hencky_8_P2;
p6 = plot(x6,y6);
xline(1086,'--','LineWidth',2,'color',p6.Color);
xline(1565,'linewidth',2,'Color',p6.Color);
x8 = f8_data.index;
y8 = f8_data.e1_1__Hencky_13_P2;
p8 = plot(x8,y8);
xline(154,'--','LineWidth',2,'Color',p8.Color);
xline(308,'linewidth',2,'Color',p8.Color);
x9 = f9_data.index;
y9 = f9_data.e1_1__Hencky_10_P2;
p9 = plot(x9, y9);
xline(65,'--','LineWidth',2,'color',p9.Color);
xline(731,'linewidth',2,'Color',p9.Color);
hold off
grid minor
grid on
xlabel("Index")
ylabel("Hencky e_1")
%%  %Plotting P3 of all the tests
subplot(5,1,4);
x5 = f5_data.index;
y5 = f5_data.e1_1__Hencky_4_P3;
p5 = plot(x5,y5);
xlim([0,2700]);
ylim([-0.05,.15]);
xline(1091,'--','LineWidth',2,'Color',p5.Color);
hold on
x6 = f6_data.index;
y6 = f6_data.e1_1__Hencky_9_P3;
p6 = plot(x6,y6);
xline(1086,'--','LineWidth',2,'color',p6.Color);
xline(1565,'linewidth',2,'Color',p6.Color);
x8 = f8_data.index;
y8 = f8_data.e1_1__Hencky_21_P3;
p8 = plot(x8,y8);
xline(154,'--','LineWidth',2,'Color',p8.Color);
xline(308,'linewidth',2,'Color',p8.Color);
x9 = f9_data.index;
y9 = f9_data.e1_1__Hencky_11_P3;
p9 = plot(x9, y9);
xline(65,'--','LineWidth',2,'color',p9.Color);
xline(731,'linewidth',2,'Color',p9.Color);
hold off
grid minor
grid on
ylabel("Hencky e_1")
%%  %Plotting P4 of all the tests
subplot(5,1,5);
x5 = f5_data.index;
y5 = f5_data.e1_1__Hencky_5_P4;
p5 = plot (x5,y5);
xlim([0,2700]);
ylim([-0.05,.15]);
xline(1091,'--','LineWidth',2,'Color',p5.Color);
hold on
x6 = f6_data.index;
y6 = f6_data.e1_1__Hencky_10_P4;
p6 = plot(x6,y6);
xline(1086,'--','LineWidth',2,'color',p6.Color);
xline(1565,'linewidth',2,'Color',p6.Color);
x8 = f8_data.index;
y8 = f8_data.e1_1__Hencky_22_P4;
p8 = plot(x8,y8);
xline(154,'--','LineWidth',2,'Color',p8.Color);
xline(308,'linewidth',2,'Color',p8.Color);
x9 = f9_data.index;
y9 = f9_data.e1_1__Hencky_12_P4;
p9 = plot(x9, y9);
xline(65,'--','LineWidth',2,'color',p9.Color);
xline(731,'linewidth',2,'Color',p9.Color);
hold off
grid minor
grid on
ylabel("Hencky e_1")
xlabel("Index")


