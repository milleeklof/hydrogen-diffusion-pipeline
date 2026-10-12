% Copyright (c) 2026 Mille Eklöf
% Licensed under the MIT License (see LICENSE in the repository root).

function plot_all_diffusion()

% =====================================
% SETTINGS
% =====================================
profile_filter = '';  % plot only this profile, '' = all

% =====================================
% FIND ALL CSV FILES
% =====================================
indir = 'diffusions';
files = dir(fullfile(indir, 'Dc_*.csv'));
if isempty(files)
    error('No Dc_*.csv files found in folder "%s".', indir);
end

fprintf('Found %d csv files:\n', length(files));
for i = 1:length(files)
    fprintf('  %s\n', files(i).name);
end

% =====================================
% PLOT
% =====================================
figure(20); clf; hold on;

% store label data first
x_all = [];
y_all = [];
labels = {};
colors = {};

for i = 1:length(files)
    fname = files(i).name;

    % Filter
    if ~isempty(profile_filter) && ~contains(fname, profile_filter)
        continue;
    end

    % Temperature parsing
    tok = regexp(fname, '(\d+)C_(\d+)mbar', 'tokens');
    if isempty(tok)
        fprintf('Could not parse temperature/pressure from: %s\n', fname);
        temp_label = fname;
    else
        temp_C     = tok{1}{1};
        press_mbar = tok{1}{2};
        %temp_label = sprintf('%s°C, %s mbar', temp_C, press_mbar);
        temp_label = sprintf('%s°C', temp_C);
    end

    % Read data
    T = readtable(fullfile(files(i).folder, fname));

    scale = 1e-6;
    % Plot
    eb = errorbar(T.c_H_M, T.Dc_mean/scale, T.Dc_std/scale, '.', ...
        'LineWidth', 1.5, 'MarkerSize', 10, ...
        'DisplayName', temp_label);

    % ===== ROBUST last point =====
    valid = ~isnan(T.Dc_mean);
    if ~any(valid)
        continue;
    end

    x_last = T.c_H_M(find(valid,1,'last'));
    y_last = T.Dc_mean(find(valid,1,'last'))/scale;

    % Store for later plotting
    x_all(end+1) = x_last;
    y_all(end+1) = y_last;
    labels{end+1} = temp_label;
    colors{end+1} = eb.Color;
end

% =====================================
% AXIS & STYLING
% =====================================
ax = gca;
%ax.YAxis.Exponent = -6;

xlabel('Concentration c [H/M]');
ylabel('D_c [10^{-6} cm^2 s^{-1}]');
title(sprintf('Diffusion coefficients %s', strrep(profile_filter, '_', '\_')));
%legend('Location', 'best');
grid on;

grid on;
ax = gca;
ax.Box = 'on';
ax.LineWidth = 1.2;
ax.FontSize = 12;
ax.TickDir = 'out';

% =====================================
% EXPAND X-LIM (CRITICAL)
% =====================================
xlim auto
xl = xlim;
x_range = xl(2) - xl(1);

xlim([xl(1), xl(2) + 0.15*x_range])

% =====================================
% DRAW LABELS AFTERWARD
% =====================================
for i = 1:length(x_all)
    text(x_all(i) + 0.02*x_range, y_all(i), ...
        sprintf('  %s', labels{i}), ...
        'FontSize', 9, ...
        'Color', colors{i}, ...
        'VerticalAlignment','middle', ...
        'HorizontalAlignment','left');
end

end