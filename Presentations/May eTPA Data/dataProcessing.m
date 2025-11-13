clc; clear; close all;
% 1) Read the spreadsheet into a table
data = readmatrix('NewFile2.csv');

% 2) Extract data in PMT readings & Frequency Sweep
freq  = data(:,1);
pmt_readings = data(:,2);
smooth_pmt = smooth(pmt_readings); % experimental - read more on docs

% xLimits = [220 1060];  % example: [1.2 1.8]
yLimits = [min(pmt_readings) max(pmt_readings)];  % example: [0 5]

% % 3) Plot
% figure;
% % plot(freq, pmt_readings,'LineWidth',1.2,'MarkerSize',5);
% plot(freq, pmt_readings,'LineWidth',1.2,'MarkerSize',5);
% xlabel('Frequency (arbitrary unit, a.u.)');
% ylabel('PMT Voltage (a.u.)');
% % title('Rb-87 Two-Photon Absorption Spectrum');
% set(gca, 'FontSize', 16);
% xlim(xLimits);
% ylim(yLimits);

figure;
% plot(freq, pmt_readings,'LineWidth',1.2,'MarkerSize',5);
plot(freq, smooth_pmt,'LineWidth',1.2,'MarkerSize',5);
xlabel('Sample Index');
ylabel('PMT Voltage (a.u.)');
% title('Rb-87 Two-Photon Absorption Spectrum');
set(gca, 'FontSize', 18);
% xlim(xLimits);
ylim(yLimits);