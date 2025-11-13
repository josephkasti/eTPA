clc;
clear;
close all;
% --- 1) Load and Prepare Data ---
data = readmatrix('raw_pmt_data_2025-05-19_20-32-22_80.csv');
% data = readmatrix('raw_pmt_data_2025-05-19_20-00-20_100.csv');
pmt_readings = data(:,1);

x_indices = (1:length(pmt_readings))';
smoothing_windows = [100];
min_prominences = [15];
xLimits_indices = [115000,127000];
% xLimits_indices = [519000, 534000];
% xLimits_indices = [675000,710000];

min_distance = 1000;
num_smooth_levels = length(smoothing_windows);
num_prom_levels = length(min_prominences);
figure('Position', [100, 100, 1200, 700]); % [left, bottom, width, height]

plot_index = 1; % Counter for subplot position

for i = 1:num_smooth_levels
    current_window = smoothing_windows(i);
    smooth_pmt = smoothdata(pmt_readings, 'movmean', current_window);
    for j = 1:num_prom_levels

        current_prominence = min_prominences(j);
        [pks, locs] = findpeaks(smooth_pmt, 'MinPeakProminence', current_prominence, 'MinPeakDistance', min_distance);
        zoom_peak_indices = (locs >= xLimits_indices(1) & locs <= xLimits_indices(2));

        peak_locations = locs(zoom_peak_indices);
        peak_heights = pks(zoom_peak_indices);
        num_peaks_found = length(peak_locations);

        subplot(num_smooth_levels, num_prom_levels, plot_index);

        hold on;

        plot(x_indices, smooth_pmt, 'LineWidth', 1);
        plot(peak_locations, peak_heights, 'rv', 'MarkerFaceColor', 'r', 'MarkerSize', 6);
        
        plot(peak_locations, peak_heights, 'rv', 'MarkerFaceColor', 'r', 'MarkerSize', 6);

        peak_labels = {
            'F=1 → F''=3',
            'F=2 → F''=2',
            'F=2 → F''=3',
            'F=2 → F''=4'
            };

        yLims = ylim; % Get current y-axis limits
        y_offset = (yLims(2) - yLims(1)) * 0.04; % 4% of the total y-axis height
        if num_peaks_found == length(peak_labels)
            for k = 1:num_peaks_found
                label_str = peak_labels{k};

                text(peak_locations(k), peak_heights(k) + y_offset, label_str, ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'bottom', ...
                    'FontSize', 19, ...
                    'FontWeight', 'bold');
            end
        end

        set(gca, 'FontSize', 28);
        xlim(xLimits_indices);
        zoom_data_segment = smooth_pmt(xLimits_indices(1):xLimits_indices(2));
        ylim([min(zoom_data_segment) max(zoom_data_segment)*1.1]);

        if j == 1
            ylabel('PMT Voltage (a.u.)');
        end

        if i == num_smooth_levels
            xlabel('Data Point Index');
        end
        hold off;
        plot_index = plot_index + 1;
    end
end

% Get the handle to the current axes
ax = gca; 

% 1. Remove axis tick marks (while keeping labels)
ax.TickLength = [0 0];

% 2. Add a full black border
box on; % Turn the axes box 'on'
ax.BoxStyle = 'full'; 
ax.XColor = 'k'; % Set x-axis line color to black
ax.YColor = 'k'; % Set y-axis line color to black
ax.ZColor = 'k'; % Set z-axis line color to black
ax.LineWidth = 1.5; % Make the border line a little thicker

% 4. Set the FIGURE background (outside the plot) to white
fig = gcf;
fig.Color = [1, 1, 1];