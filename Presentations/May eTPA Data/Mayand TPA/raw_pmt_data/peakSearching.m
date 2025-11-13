clc;
clear;
close all;

% --- 1) Load and Prepare Data ---
data = readmatrix('raw_pmt_data_2025-05-19_20-32-22_80.csv');
% data = readmatrix('raw_pmt_data_2025-05-19_20-00-20_100.csv');
pmt_readings = data(:,1);
x_indices = (1:length(pmt_readings))';

% --- 2) DEFINE PARAMETERS TO ITERATE ---
%
% ** These are the "knobs" you can turn **
%
% Add or change values here to test different smoothing levels
smoothing_windows = [100];
% Add or change values here to test different peak sensitivities
min_prominences = [15];


% ** Set your search window (x-axis limits) **
% I've kept your original window, but you can widen it here.
xLimits_indices = [115000,127000];  % example: [1.2 1.8]
% xLimits_indices = [519000, 534000];
% xLimits_indices = [675000,710000];
min_distance = 1000; % Minimum index separation between peaks

num_smooth_levels = length(smoothing_windows);
num_prom_levels = length(min_prominences);

figure('Position', [100, 100, 1200, 700]); % [left, bottom, width, height]

plot_index = 1; % Counter for subplot position

for i = 1:num_smooth_levels
    current_window = smoothing_windows(i);

    % --- Apply Smoothing ---
    % This is the most time-consuming step
    fprintf('Applying smoothing with window: %d...\n', current_window);
    smooth_pmt = smoothdata(pmt_readings, 'movmean', current_window);

    for j = 1:num_prom_levels
        current_prominence = min_prominences(j);

        % --- Find Peaks ---
        fprintf('  Finding peaks with prominence: %d\n', current_prominence);
        [pks, locs] = findpeaks(smooth_pmt, 'MinPeakProminence', current_prominence, 'MinPeakDistance', min_distance);

        % --- Filter peaks to be within the xLimits ---
        zoom_peak_indices = (locs >= xLimits_indices(1) & locs <= xLimits_indices(2));
        peak_locations = locs(zoom_peak_indices);
        peak_heights = pks(zoom_peak_indices);

        num_peaks_found = length(peak_locations);

        % --- Create a subplot for this combination ---
        subplot(num_smooth_levels, num_prom_levels, plot_index);
        hold on;

        % Plot the smoothed data
        plot(x_indices, smooth_pmt, 'LineWidth', 2);

        % Plot the found peaks
        plot(peak_locations, peak_heights, 'rv', 'MarkerFaceColor', 'r', 'MarkerSize', 6);

        peak_labels = {
            'F=1 → F''=3',
            'F=2 → F''=2',
            'F=2 → F''=3',
            'F=2 → F''=4'
            };

        % 2. Calculate a small vertical offset to place text above markers
        %    (This uses the y-axis limits to scale the offset nicely)
        yLims = ylim; % Get current y-axis limits
        y_offset = (yLims(2) - yLims(1)) * 0.04; % 4% of the total y-axis height

        % 3. Loop through each peak and add the text
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

        % Auto-adjust y-limits for the zoomed region
        zoom_data_segment = smooth_pmt(xLimits_indices(1):xLimits_indices(2));
        ylim([min(zoom_data_segment) max(zoom_data_segment)*1.1]);

        % Add labels only to the outer plots
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

fprintf('Iteration complete.\n');

% Get the handle to the current axes
ax = gca; 

% 1. Remove axis tick marks (while keeping labels)
ax.TickLength = [0 0];

% 2. Add a full black border
box on; % Turn the axes box 'on'
ax.BoxStyle = 'full'; % Use a full box (for 3D this is more relevant, but good practice)
ax.XColor = 'k'; % Set x-axis line color to black
ax.YColor = 'k'; % Set y-axis line color to black
ax.ZColor = 'k'; % Set z-axis line color to black (for 3D)
ax.LineWidth = 1.5; % Make the border line a little thicker
fig = gcf;
fig.Color = [1, 1, 1];