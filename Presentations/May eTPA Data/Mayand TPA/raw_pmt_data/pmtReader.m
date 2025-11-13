clc; clear; close all;

data = readmatrix('raw_pmt_data_2025-05-19_20-32-22_80.csv');
pmt_readings = data(:,1);
x_indices = (1:length(pmt_readings))';
smooth_level = 100;
prominence = 15;

xLimits_indices = [115000,127000];
min_distance = 1000;
figure('Position', [100, 100, 1200, 700]);
smooth_pmt = smoothdata(pmt_readings, 'movmean', smooth_level);
[pks, locs] = findpeaks(smooth_pmt, 'MinPeakProminence', prominence, 'MinPeakDistance', min_distance);
zoom_peak_indices = (locs >= xLimits_indices(1) & locs <= xLimits_indices(2));
peak_locations = locs(zoom_peak_indices);
peak_heights = pks(zoom_peak_indices);
num_peaks_found = length(peak_locations);

peak_indices = peak_locations;
if length(peak_indices) ~= 4 % Check peaks
    error('Calibration failed: Expected 4 peaks, but found %d. Adjust MinPeakProminence/Distance.', length(peak_indices));
end

% Plot the smoothed data
plot(x_indices, smooth_pmt, 'LineWidth', 1);
hold on;
% Plot the found peaks
plot(peak_locations, peak_heights, 'rv', 'MarkerFaceColor', 'r', 'MarkerSize', 6);

peak_labels = {
    'F=1 → F''=3',
    'F=2 → F''=2',
    'F=2 → F''=3',
    'F=2 → F''=4'
    };
yLims = ylim; % Get current y-axis limits
y_offset = (yLims(2) - yLims(1)) * 0.04; % 4% of the total y-axis height

for k = 1:num_peaks_found
    label_str = peak_labels{k};
    text(peak_locations(k), peak_heights(k) + y_offset, label_str, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontSize', 19, ...
        'FontWeight', 'bold');
end
set(gca, 'FontSize', 28);
xlim(xLimits_indices);
ylabel('PMT Voltage (a.u.)');
xlabel('Data Point Index');
zoom_data_segment = smooth_pmt(xLimits_indices(1):xLimits_indices(2));
ylim([min(zoom_data_segment) max(zoom_data_segment)*1.1]);

ax = gca;
ax.TickLength = [0 0];
box on; % Turn the axes box 'on'
ax.BoxStyle = 'full'; % Use a full box (for 3D this is more relevant, but good practice)
ax.XColor = 'k'; % Set x-axis line color to black
ax.YColor = 'k'; % Set y-axis line color to black
ax.ZColor = 'k'; % Set z-axis line color to black (for 3D)
ax.LineWidth = 1.5; % Make the border line a little thicker
fig = gcf;
fig.Color = [1, 1, 1];