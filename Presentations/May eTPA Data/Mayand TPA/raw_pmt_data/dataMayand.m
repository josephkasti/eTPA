clc; clear; close all;
% 1) Read the spreadsheet into a table
data = readmatrix('raw_pmt_data_2025-05-19_20-32-22_80.csv');

% 2) Extract data in PMT readings & Frequency Sweep
freq  = 1:length(data);
pmt_readings = data(:,1);
smooth_pmt = smooth(pmt_readings); % experimental - read more on docs

xLimits = [115000,135000];  % example: [1.2 1.8]
yLimits = [min(pmt_readings) max(pmt_readings)];  % example: [0 5]

% % 3) Plot
% figure;
% % plot(freq, pmt_readings,'LineWidth',1.2,'MarkerSize',5);
% plot(freq, pmt_readings);
% xlabel('Frequency (arbitrary unit, a.u.)');
% ylabel('PMT Voltage (a.u.)');
% % title('Rb-87 Two-Photon Absorption Spectrum');
% set(gca, 'FontSize', 16);
% xlim(xLimits);
% ylim(yLimits);

figure;
% plot(freq, pmt_readings,'LineWidth',1.2,'MarkerSize',5);
plot(freq, smooth_pmt,'LineWidth',1.2,'MarkerSize',5);
xlabel('Detuned Frequency MHz');
ylabel('PMT Voltage (a.u.)');
% title('Rb-87 Two-Photon Absorption Spectrum');
set(gca, 'FontSize', 18);
xlim(xLimits);
ylim(yLimits);