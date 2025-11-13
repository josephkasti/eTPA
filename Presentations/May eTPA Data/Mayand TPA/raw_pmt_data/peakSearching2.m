clc; clear; close all;

%% ---------------- 1) Load & smooth ----------------
fname = 'raw_pmt_data_2025-05-19_20-32-22_80.csv';
raw = readmatrix(fname);
p = raw(:,1);                               % PMT column
N = numel(p);
idx = (1:N)';

smooth_win = 100;                           % movmean(100) like before
p_s = smoothdata(p, 'movmean', smooth_win);

%% ---------------- 2) Find candidate peaks ----------------
% restrict to your usual zoom window to avoid side structure
zoom_idx = [115000, 127000];
[pks_all, locs_all] = findpeaks(p_s, ...
    'MinPeakProminence', 15, ...
    'MinPeakDistance',   1000);

in = (locs_all>=zoom_idx(1) & locs_all<=zoom_idx(2));
locs = locs_all(in);
pks  = pks_all(in);
[locs, order] = sort(locs); pks = pks(order);

if numel(locs) < 4
    error('Expected at least 4 peaks in the zoom region; found %d.', numel(locs));
end

%% ---------------- 3) Identify the Rb-87 trio automatically ----------------
% Among all groups of 3 peaks, choose the group with the SMALLEST index span.
% Those three are the closely spaced Rb-87 (F''=2,3,4); the remaining one is Rb-85.
best_span = inf; best_triplet = [];
for a = 1:numel(locs)-2
    for b = a+1:numel(locs)-1
        for c = b+1:numel(locs)
            span = locs(c) - locs(a);
            if span < best_span
                best_span = span;
                best_triplet = [a b c];
            end
        end
    end
end

rb87_idx = best_triplet;                     % indices into locs/pks
other_idx = setdiff(1:numel(locs), rb87_idx);% Rb-85 candidate(s) — expect one

% Sort the Rb-87 triplet by index (left→right)
[~,ord3] = sort(locs(rb87_idx));
rb87_idx = rb87_idx(ord3);

% Map the rightmost Rb-87 peak to F'=4 (0 MHz), then leftwards: F'=3, F'=2
% After sorting left→right: rb87_idx = [F'=2, F'=3, F'=4]
rb87_known_MHz = [-26.3, -14.65, 0.0];       % literature spacings relative to F'=4

%% ---------------- 4) Linear calibration (MHz = m*index + b) ----------------
x3 = locs(rb87_idx);
f3 = rb87_known_MHz(:);
p_lin = polyfit(x3, f3, 1);
m = p_lin(1); b = p_lin(2);
f_axis = m*idx + b;
f_peaks = m*locs + b;

%% ---------------- 5) Sub-sample peak centers (Lorentzian if available) ----
% Fit small windows around the 3 Rb-87 peaks + the extra (Rb-85) peak.
W = 1200;                                    % half-window in indices
labels = strings(numel(locs),1);
labels(rb87_idx(1)) = "Rb-87 F=2→F′=2";
labels(rb87_idx(2)) = "Rb-87 F=2→F′=3";
labels(rb87_idx(3)) = "Rb-87 F=2→F′=4";
if ~isempty(other_idx)
    labels(other_idx(1)) = "Rb-85 F=2→F′=3";
end

% Lorentz model
lorentz = @(p, x) p(4) + p(1)*(p(3).^2 ./ ((x - p(2)).^2 + p(3).^2));
have_optim = ~isempty(ver('optim'));

fit_center = nan(size(locs));
fit_gamma  = nan(size(locs));
for k = 1:numel(locs)
    i0 = locs(k);
    iL = max(1, i0-W); iR = min(N, i0+W);
    xf = f_axis(iL:iR);
    yf = p_s(iL:iR);

    % initial guesses
    A0   = max(yf)-median(yf);
    x0_0 = f_peaks(k);
    % gamma guess ~ width across ~20 samples in frequency units
    step = 20;
    if i0-step>=1 && i0+step<=N
        g0 = abs(f_axis(i0+step)-f_axis(i0-step))/2;
    else
        g0 = 1;
    end
    y00 = median(yf);

    if have_optim
        % lsqcurvefit attempt
        try
            p0 = [A0, x0_0, max(g0,1e-3), y00];
            lb = [0,   x0_0-200,  1e-6, -Inf];
            ub = [Inf, x0_0+200,  Inf,  Inf];
            pfit = lsqcurvefit(lorentz, p0, xf, yf, lb, ub, optimoptions('lsqcurvefit','Display','off'));
            fit_center(k) = pfit(2);
            fit_gamma(k)  = abs(pfit(3));
            continue
        catch
            % fall through to quadratic refine
        end
    end

    % Quadratic refine near the discrete max if fit fails / toolbox absent
    [~,imax] = max(yf);
    if imax>1 && imax<numel(yf)
        xq = xf(imax-1:imax+1); yq = yf(imax-1:imax+1);
        % y = ax^2+bx+c  -> vertex at -b/(2a)
        M = [xq.^2, xq, ones(3,1)]; abc = M\yq(:);
        a=abc(1); bq=abc(2);
        xc = -bq/(2*a);
        fit_center(k) = xc;
    else
        fit_center(k) = x0_0;
    end
end

%% ---------------- 6) Build a tidy table ----------------
exp_vals = nan(size(locs));
exp_vals(rb87_idx) = rb87_known_MHz;
delta = fit_center - exp_vals;

T = table(labels, exp_vals, fit_center, delta, ...
    'VariableNames', {'Peak','Expected_MHz','Measured_MHz','Delta_MHz'});

disp('---- Calibration from Rb-87 trio (F′=2,3,4) ----');
fprintf('Linear map: f [MHz] = m * index + b  ->  m = %.6f MHz/index,  b = %.3f MHz\n', m, b);
disp(T);

% Print the inferred Rb-85 offset if present
if ~isempty(other_idx)
    k85 = other_idx(1);
    fprintf('Inferred Rb-85 peak position: %.2f MHz relative to Rb-87 F′=4.\n', fit_center(k85));
end

%% ---------------- 7) Plot ----------------
figure('Position',[100 100 1200 600]);
plot(f_axis, p_s, 'LineWidth', 1); hold on;
scatter(fit_center, p_s(locs), 65, 'v', 'filled');

% label peaks
yoff = range(p_s(zoom_idx(1):zoom_idx(2)))*0.05;
for k = 1:numel(locs)
    text(fit_center(k), p_s(locs(k))+yoff, labels(k), ...
        'HorizontalAlignment','center','FontSize',17,'FontWeight','bold');
end
xlabel('Relative Laser Frequency (MHz), '); ylabel('PMT Voltage (a.u.)');

xlim([min(f_axis(zoom_idx(1):zoom_idx(2))), max(f_axis(zoom_idx(1):zoom_idx(2)))]);
set(gca,'TickLength',[0 0],'LineWidth',1.2,'FontSize',22,'Box','on');

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
