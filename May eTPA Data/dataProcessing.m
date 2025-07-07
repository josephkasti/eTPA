clc; clear;
% 1) Read the spreadsheet into a table
data = readmatrix('NewFile2.csv');

% 2) Extract data in PMT readings & Frequency Sweep
freq  = data(:,1);
pmt_readings = data(:,2);
% smooth_pmt = smooth(pmt_readings); % experimental - read more on docs

% 4) Plot 
figure('Name','CH3 Data','Color','w');
plot(freq, pmt_readings,'LineWidth',1.2,'MarkerSize',5);
grid on;
xlabel('Sample Index');
ylabel('PMT Voltage');
title(['PMT Voltage vs. Frequency']);
