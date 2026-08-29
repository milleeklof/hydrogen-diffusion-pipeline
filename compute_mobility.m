function compute_mobility()

% =====================================
% LOAD f_therm_struct
% =====================================
data = load('f_therm_struct.mat');
f_therm_struct = data.f_therm_struct;

% =====================================
% CONSTANT
% =====================================
kB = 8.617333262145e-5; % eV/K

% =====================================
% FIND CSV
% =====================================
indir = 'diffusions';
files = dir(fullfile(indir, 'Dc_*.csv'));
if isempty(files)
    error('No Dc_*.csv files found in folder "%s".', indir);
end

figure(50); clf; hold on;

fprintf('\n========== MOBILITY ==========\n');

for i = 1:length(files)

    fname = files(i).name;

    % =====================================
    % PARSE TEMPERATURE
    % =====================================
    tok = regexp(fname, '_(\d+)C_(\d+)mbar', 'tokens');
    if isempty(tok)
        fprintf('Skipping %s (no temperature)\n', fname);
        continue;
    end

    T_C = str2double(tok{1}{1});
    T_K = T_C + 273.15;

    % =====================================
    % MATCH f_therm (ROBUST)
    % =====================================
    T_list = [f_therm_struct.T_C];
    [~, idx_T] = min(abs(T_list - T_C));

    f_data = f_therm_struct(idx_T);

    c_f     = f_data.concentration;
    f_therm = f_data.f_therm;

    % =====================================
    % READ DIFFUSION
    % =====================================
    T = readtable(fullfile(files(i).folder, fname));

    c_vec = T.c_H_M;
    Dc    = T.Dc_mean;

    % =====================================
    % INTERPOLATE f_therm
    % =====================================
    f_interp = interp1(c_f, f_therm, c_vec, 'pchip', NaN);

    % =====================================
    % COMPUTE MOBILITY
    % =====================================
    M = Dc ./ (f_interp * kB * T_K);

    % =====================================
    % FILTER (c >= 0.2)
    % =====================================
    valid = ~isnan(M) & M > 0 & c_vec >= 0.2;

    c_plot = c_vec(valid);
    M_plot = M(valid) / 1e-5;

    if isempty(c_plot)
        fprintf('%d°C: no points after cutoff\n', T_C);
        continue;
    end

    % =====================================
    % SCATTER
    % =====================================
    scatter(c_plot, M_plot, 20, 'filled', ...
        'DisplayName', sprintf('%d°C', T_C));

    fprintf('%d°C: %d points\n', T_C, length(c_plot));
end

% =====================================
% PLOT
% =====================================
xlabel('Concentration c [H/M]');
ylabel('Mobility M [10^{-5} cm^2/(eV·s)]');
title('Hydrogen mobility vs concentration (c ≥ 0.2)');
legend('Location','best');
grid on;
ax = gca;
ax.Box = 'on';
ax.LineWidth = 1.2;
ax.FontSize = 12;
ax.TickDir = 'out';

end