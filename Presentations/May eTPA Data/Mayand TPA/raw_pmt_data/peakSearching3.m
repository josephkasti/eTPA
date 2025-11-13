clc; clear; close all;

% --- 1. Load and Prepare Data ---
% (Using your original settings)
data = readmatrix('raw_pmt_data_2025-05-19_20-32-22_80.csv');
pmt_readings = data(:,1);
x_indices = (1:length(pmt_readings))';
smooth_level = 100;
prominence = 15;
xLimits_indices = [115000, 127000];
min_distance = 1000;

smooth_pmt = smoothdata(pmt_readings, 'movmean', smooth_level);

% --- 2. Find Peaks ---
[pks, locs] = findpeaks(smooth_pmt, 'MinPeakProminence', prominence, 'MinPeakDistance', min_distance);

% Filter peaks to be within the zoom region
zoom_peak_indices = (locs >= xLimits_indices(1) & locs <= xLimits_indices(2));
peak_locations_idx = locs(zoom_peak_indices); % Original "index" locations
peak_heights = pks(zoom_peak_indices);
num_peaks_found = length(peak_locations_idx);

if num_peaks_found ~= 4 
    error('Calibration failed: Expected 4 peaks, but found %d. Adjust MinPeakProminence/Distance.', num_peaks_found);
end

% --- 3. Calibrate to Relative Frequency (MHz) ---

% These are the known physical frequencies (Relative Laser, MHz)
% We set F=2 -> F'=4 as the 0.0 reference
f_peak_F2_F4 = 0.0;    % (This is peak 4)
f_peak_F2_F3 = -14.65; % (This is peak 3)
f_peak_F2_F2 = -26.3;  % (This is peak 2)
% (We ignore peak 1 for calibration, as it's not part of this group)

% We will perform a linear fit (polyfit) on our 3 trusted Rb-87 peaks
% This is more robust than using just 2 points.
anchor_indices = [
    peak_locations_idx(2); % Index for F=2->F'=2
    peak_locations_idx(3); % Index for F=2->F'=3
    peak_locations_idx(4)  % Index for F=2->F'=4
];
anchor_freqs = [
    f_peak_F2_F2;
    f_peak_F2_F3;
    f_peak_F2_F4
];

% Find the linear coefficients (m, b) where freq = m * index + b
coeffs = polyfit(anchor_indices, anchor_freqs, 1);
m = coeffs(1);
b = coeffs(2);

% Apply this transformation to ALL x-axis elements
freq_axis_MHz = m * x_indices + b;
calibrated_peak_locations_MHz = m * peak_locations_idx + b;
calibrated_xLimits_MHz = m * xLimits_indices + b;


% --- 4. Plot 1: Relative Laser Frequency (MHz) ---
% (This should reproduce your "good" plot)
figure('Position', [100, 100, 1200, 700]);
plot(freq_axis_MHz, smooth_pmt, 'LineWidth', 1);
hold on;
plot(calibrated_peak_locations_MHz, peak_heights, 'rv', 'MarkerFaceColor', 'r', 'MarkerSize', 6);

% Updated, physically correct labels
peak_labels = {
    'Rb-85 F=2→F''=3', % Peak 1
    'Rb-87 F=2→F''=2', % Peak 2
    'Rb-87 F=2→F''=3', % Peak 3
    'Rb-87 F=2→F''=4'  % Peak 4
    };
yLims = ylim;
y_offset = (yLims(2) - yLims(1)) * 0.04; 

for k = 1:num_peaks_found
    label_str = peak_labels{k};
    text(calibrated_peak_locations_MHz(k), peak_heights(k) + y_offset, label_str, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
        'FontSize', 17, 'FontWeight', 'bold');
end

set(gca, 'FontSize', 22);
xlim([min(calibrated_xLimits_MHz), max(calibrated_xLimits_MHz)]);
ylabel('PMT Voltage (a.u.)');
xlabel('Relative Laser Frequency (MHz)');
% (Your original styling)
ax = gca; ax.LineWidth = 1.5; box on; fig = gcf; fig.Color = [1,1,1];
ax.TickLength = [0 0];


% --- 5. Convert Frequency Axis to Wavelength (nm) ---

% Define physical constants
c_m_s = 299792458; % Speed of light (m/s)

% Absolute frequency (in MHz) of our reference (F=2 -> F'=4) peak
f_ref_MHz = 385284566.37; 

% Create the absolute frequency axis (in MHz)
f_abs_MHz = freq_axis_MHz + f_ref_MHz;

% Convert absolute frequency (MHz) to wavelength (nm)
% lambda = c / nu
% lambda_nm = (c_m_s / (f_abs_MHz * 1e6)) * 1e9
lambda_nm_axis = (c_m_s ./ f_abs_MHz) * 1e3; % Simplified math

% Calculate the peak locations and x-limits on the new axis
calibrated_peak_locations_nm = (c_m_s ./ (calibrated_peak_locations_MHz + f_ref_MHz)) * 1e3;
calibrated_xLimits_nm = (c_m_s ./ (calibrated_xLimits_MHz + f_ref_MHz)) * 1e3;


% --- 6. Plot 2: Absolute Laser Wavelength (nm) ---
figure('Position', [100, 100, 1200, 700]);
plot(lambda_nm_axis, smooth_pmt, 'LineWidth', 1);
hold on;
plot(calibrated_peak_locations_nm, peak_heights, 'rv', 'MarkerFaceColor', 'r', 'MarkerSize', 6);


% Add labels
for k = 1:num_peaks_found
    label_str = peak_labels{k};
    text(calibrated_peak_locations_nm(k), peak_heights(k) + y_offset, label_str, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
        'FontSize', 17, 'FontWeight', 'bold');
end

set(gca, 'FontSize', 22);

% Wavelength is inverse to frequency, so we must set X-limits this way
xlim([min(calibrated_xLimits_nm), max(calibrated_xLimits_nm)]);
% You may also want to reverse the axis to match the frequency plot
% set(gca, 'XDir', 'reverse')

ylabel('PMT Voltage (a.u.)');
xlabel('Absolute Laser Wavelength (nm)');
% (Your original styling

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