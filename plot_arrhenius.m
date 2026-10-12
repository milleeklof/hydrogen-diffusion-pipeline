% Copyright (c) 2026 Mille Eklöf
% Licensed under the MIT License (see LICENSE in the repository root).

function plot_arrhenius_new()

% =====================================
% USER SETTINGS
% =====================================
c_targets = [0.10, 0.20, 0.30];
c_tol     = 0.01;
c_min_plot = 0.056;

c_grid = 0:0.01:0.7;

kB = 8.617333262145e-5;  % eV/K

% =====================================
% FIND CSV (YOUR DATA)
% =====================================
indir = 'diffusions';
files = dir(fullfile(indir, 'Dc_*.csv'));
if isempty(files)
    error('No Dc_*.csv files found in folder "%s".', indir);
end

% =====================================
% LOAD YOUR DATA
% =====================================
all_data = struct();
n_valid  = 0;

for i = 1:length(files)

    fname = files(i).name;

    tok = regexp(fname, '_(\d+)C_\d+mbar', 'tokens');
    if isempty(tok)
        continue;
    end

    T_C = str2double(tok{1}{1});
    T_K = T_C + 273.15;

    T_data = readtable(fullfile(files(i).folder, fname));

    n_valid = n_valid + 1;

    all_data(n_valid).T_K = T_K;
    all_data(n_valid).x   = 1000/T_K;
    all_data(n_valid).c   = T_data.c_H_M;
    all_data(n_valid).Dc  = T_data.Dc_mean;
    all_data(n_valid).std = T_data.Dc_std;
end

% =====================================
% SORT TEMPERATURES
% =====================================
[~,idx] = sort([all_data.T_K]);
all_data = all_data(idx);

n_temp = length(all_data);
x_arr  = [all_data.x];

% =====================================
% FIGURE 1: ARRHENIUS
% =====================================
marker_list = {'o','s','d','^','v','>','<','p','h','x','+','*','.'};
n_markers   = length(marker_list);

figure(40); clf; hold on;

fprintf('\n========== Arrhenius ==========\n');

for ci = 1:length(c_targets)

    D_vec   = NaN(1,n_temp);
    std_vec = NaN(1,n_temp);

    for ti = 1:n_temp

        c_vec = all_data(ti).c;
        Dc    = all_data(ti).Dc;
        std   = all_data(ti).std;

        [dmin,idx_min] = min(abs(c_vec - c_targets(ci)));

        if dmin <= c_tol
            D_vec(ti)   = Dc(idx_min);
            std_vec(ti) = std(idx_min);
        end
    end

    valid = ~isnan(D_vec);

    if sum(valid) < 2
        continue;
    end

    x_fit = x_arr(valid);
    D_fit = D_vec(valid);

    p  = polyfit(x_fit, log(D_fit), 1);
    Ea = -p(1)*1000*kB;

    fprintf('c = %.2f -> Ea = %.4f eV\n', ...
        c_targets(ci), Ea);

    marker = marker_list{mod(ci-1,n_markers)+1};

    eb = errorbar( ...
        x_fit, ...
        D_fit, ...
        std_vec(valid), ...
        marker, ...
        'LineStyle','none', ...
        'DisplayName',sprintf('c = %.2f',c_targets(ci)));

    x_line = linspace(min(x_arr),max(x_arr),200);

    plot( ...
        x_line, ...
        exp(polyval(p,x_line)), ...
        '-', ...
        'Color',eb.Color, ...
        'HandleVisibility','off');
end

set(gca,'YScale','log');

xlabel('1000 / T [K^{-1}]');
ylabel('D_c [cm^2 s^{-1}]');

title('Arrhenius plot (V_{76}Zr_{12}Al_{12})');

legend;
grid on;
grid on;
ax = gca;
ax.Box = 'on';
ax.LineWidth = 1.2;
ax.FontSize = 12;
ax.TickDir = 'out';

% =====================================
% FIGURE 2: Ea(c) (YOUR DATA)
% =====================================
Ea_grid     = NaN(size(c_grid));
Ea_grid_err = NaN(size(c_grid));

for ci = 1:length(c_grid)

    c_target = c_grid(ci);

    D_vec = NaN(1,n_temp);

    for ti = 1:n_temp

        c_vec = all_data(ti).c;
        Dc    = all_data(ti).Dc;

        [dmin,idx_min] = min(abs(c_vec - c_target));

        if dmin <= c_tol
            D_vec(ti) = Dc(idx_min);
        end
    end

    valid = ~isnan(D_vec);

    if sum(valid) < 3
        continue;
    end

    x_fit = x_arr(valid);
    y_fit = log(D_vec(valid));

    [p,S] = polyfit(x_fit,y_fit,1);

    Ea = -p(1)*1000*kB;

    % =====================================
    % ERROR ON THE SLOPE
    % =====================================
    Rinv = inv(S.R);

    Cov = (Rinv*Rinv.') * (S.normr^2/S.df);

    slope_std = sqrt(Cov(1,1));

    Ea_std = slope_std * 1000 * kB;

    Ea_grid(ci)     = Ea;
    Ea_grid_err(ci) = Ea_std;
end

% =====================================
% LOAD Eact_data.csv
% =====================================
fprintf('\nLoading Eact_data.csv...\n');

fid = fopen('Eact_data.csv');

if fid == -1
    error('Could not open Eact_data.csv');
end

raw = textscan(fid,'%s','Delimiter','\n');
fclose(fid);

lines = raw{1};

c_old     = [];
Ea_old    = [];
Ea_olderr = [];

for i = 2:length(lines)

    line = lines{i};

    nums = regexp( ...
        line, ...
        '[-+]?\d*\.?\d+e[-+]?\d+|[-+]?\d*\.?\d+', ...
        'match');

    if length(nums) < 3
        continue;
    end

    c_val  = str2double(nums{1});
    Ea_val = str2double(nums{2});
    Ea_err = str2double(nums{3});

    if ~isnan(c_val) && ~isnan(Ea_val)

        c_old     = [c_old; c_val];
        Ea_old    = [Ea_old; Ea_val];
        Ea_olderr = [Ea_olderr; Ea_err];
    end
end

fprintf('Loaded %d points from Eact_data.csv\n', ...
    length(c_old));

% =====================================
% FIGURE 2: Ea(c)
% =====================================
figure(41); clf; hold on;

valid = ~isnan(Ea_grid) & (c_grid >= c_min_plot);

% =====================================
% YOUR DATA
% =====================================
errorbar( ...
    c_grid(valid), ...
    Ea_grid(valid), ...
    Ea_grid_err(valid), ...
    '.', ...
    'LineWidth',1.2, ...
    'DisplayName','V_{76}Zr_{12}Al_{12}');

% =====================================
% OLD DATA
% =====================================
old_valid = c_old >= c_min_plot;
errorbar( ...
    c_old(old_valid), ...
    Ea_old(old_valid), ...
    Ea_olderr(old_valid), ...
    'o', ...
    'LineWidth',1.5, ...
    'DisplayName','V_{80}Zr_{20}');

xlabel('c [H/M]');
ylabel('E_a [eV]');

title('Activation energy vs concentration');

legend('Location','best');
grid on;
ax = gca;
ax.Box = 'on';
ax.LineWidth = 1.2;
ax.FontSize = 12;
ax.TickDir = 'out';

set(gcf,'Color','w')

end