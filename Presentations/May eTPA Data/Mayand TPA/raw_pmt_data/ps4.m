clc; clear; close all;

% --- 1. Load and Prepare Data ---
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
zoom_peak_indices = (locs >= xLimits_indices(1) & locs <= xLimits_indices(2));
peak_locations_idx = locs(zoom_peak_indices); % Original "index" locations
peak_heights = pks(zoom_peak_indices);
num_peaks_found = length(peak_locations_idx);

if num_peaks_found ~= 4 
    error('Calibration failed: Expected 4 peaks, but found %d. Adjust MinPeakProminence/Distance.', num_peaks_found);
end

% --- 3. Calibrate to Relative Frequency (MHz) ---
f_peak_F2_F4 = 0.0;    % (This is peak 4)
f_peak_F2_F3 = -14.65; % (This is peak 3)
f_peak_F2_F2 = -26.3;  % (This is peak 2)

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
coeffs = polyfit(anchor_indices, anchor_freqs, 1);
m = coeffs(1);
b = coeffs(2);

% --- Create the Relative Frequency Axis ---
freq_axis_MHz = m * x_indices + b;
calibrated_peak_locations_MHz = m * peak_locations_idx + b;
calibrated_xLimits_MHz = m * xLimits_indices + b;


% --- 4. Plot 1: Relative Laser Frequency (MHz) ---
figure('Position', [100, 100, 1200, 700]);
plot(freq_axis_MHz, smooth_pmt, 'LineWidth', 1);
hold on;
plot(calibrated_peak_locations_MHz, peak_heights, 'rv', 'MarkerFaceColor', 'r', 'MarkerSize', 6);


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
ax = gca; ax.LineWidth = 1.5; box on; fig = gcf; fig.Color = [1,1,1];


% --- 5. Convert Frequency Axis to RELATIVE Wavelength (nm) ---

% --- Define physical constants ---
c_m_s = 299792458; % Speed of light (m/s)

% --- Correct reference frequency for 778.1 nm ---
f_ref_MHz = 385284566.37; % (Rb-87 F=2 -> F'=4)

% 1. Create the ABSOLUTE frequency axis (in MHz)
f_abs_MHz = freq_axis_MHz + f_ref_MHz;

% 2. Convert absolute frequency axis to absolute wavelength axis
lambda_nm_axis_ABSOLUTE = (c_m_s ./ f_abs_MHz) * 1e3;

% 3. Get the ABSOLUTE wavelength of our reference peak (peak 4)
% We know its relative freq is 0.0 (f_peak_F2_F4), so its abs freq is f_ref_MHz
lambda_ref_nm = (c_m_s / (f_ref_MHz * 1e6)) * 1e9; % This is our new "0"
% (lambda_ref_nm will be ~778.1009 nm)

% 4. Create the new RELATIVE wavelength axis
% This subtracts the reference wavelength from every point
lambda_nm_axis_RELATIVE = lambda_nm_axis_ABSOLUTE - lambda_ref_nm;

% 5. Calculate the new peak and limit locations on this relative axis
% First, get their absolute nm locations
calibrated_peak_locations_abs_nm = (c_m_s ./ (calibrated_peak_locations_MHz + f_ref_MHz)) * 1e3;
calibrated_xLimits_abs_nm = (c_m_s ./ (calibrated_xLimits_MHz + f_ref_MHz)) * 1e3;
% Then, make them relative
calibrated_peak_locations_REL_nm = calibrated_peak_locations_abs_nm - lambda_ref_nm;
calibrated_xLimits_REL_nm = calibrated_xLimits_abs_nm - lambda_ref_nm;


% --- 6. Plot 2: Relative Laser Wavelength (nm) ---
figure('Position', [100, 100, 1200, 700]);
% PLOT WITH THE NEW RELATIVE AXIS
plot(lambda_nm_axis_RELATIVE, smooth_pmt, 'LineWidth', 2.5);
hold on;
plot(calibrated_peak_locations_REL_nm, peak_heights, 'rv', 'MarkerFaceColor', 'r', 'MarkerSize', 6);

% Add labels
for k = 1:num_peaks_found
    label_str = peak_labels{k};
    text(calibrated_peak_locations_REL_nm(k), peak_heights(k) + y_offset, label_str, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
        'FontSize', 26, 'FontWeight', 'bold');
end

set(gca, 'FontSize', 34);

% Set x-limits using the new relative values
xlim([min(calibrated_xLimits_REL_nm), max(calibrated_xLimits_REL_nm)]);

ylabel('PMT Voltage (a.u.)');
% Set a dynamic X-label that shows the reference
xlabel('Detuning (nm) from 778.10658nm');

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