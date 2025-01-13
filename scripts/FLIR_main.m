% FLIR_main.m
%
% CU Boulder METALS Project
% Comments updated: 01/13/2025
% Samuel Hatton
%
%
% Purpose
%     Analysis script for FLIR thermal imaging data
%     Processes .tif files and creates temperature contour plots
% Usage
%     Run script to load and visualize FLIR thermal data
% Methodology
%     1. Loads FLIR .tif image files
%     2. Converts raw data to temperature (Celsius)
%     3. Creates contour plot with temperature colorbar
% Dependencies
%     load_tiff       Custom function

% Trying to do stuff with FLIR tiff files


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

addpath('..\functions\data loading\')

%%

% full_fname = "D:\S20-3 Tiffs\Sample 20-specimen 3-FLIR0-00000050_0.tif";
% full_fname = "C:\Users\hatto\OneDrive - UCB-O365\Summer 2024\METALS Documents\FLIR Stuff\Specimen 20-4-FLIR0-00001317_0.tif";
full_fname = "C:\Users\Samuel\OneDrive - UCB-O365\Summer 2024\METALS Documents\FLIR Stuff\Specimen 20-4-FLIR0-00001317_0.tif";
% norm_fname = "D:\S20-3 Tiffs\Sample 20-specimen 3-FCAL0-00000050_0.tif";

full_data = double(load_tiff(full_fname));
full_data = 0.1 * full_data; % 100k scale factor to get to Kelvin
full_data = full_data - 273.15; % convert from Kelvin to Celsius

% norm_data = load_tiff(norm_fname);

minTemp = double(min(min(full_data)));
maxTemp = double(max(max(full_data)));

figure
contourf(flipud(full_data),30)
% imshow(norm_data)
colormap("parula")
cb = colorbar;
ticks = cb.Ticks;
mint = double(min(min(full_data)));
maxt = double(max(max(full_data)));
cb.Ticks = linspace(mint,maxt,12);
cb.TickLabels = num2cell(round(linspace(minTemp,maxTemp,12)));
