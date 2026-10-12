% Copyright (c) 2026 Mille Eklöf
% Licensed under the MIT License (see LICENSE in the repository root).

function calculate_diffusion_adaptive_xmax()

disp('RUNNING: ADAPTIVE DIFFUSION');

% =====================================
% USER SETTINGS
% =====================================
grad_threshold = 1e-4;
Dc_max         = 1e-4;

grad_cutoff    = 0.3;   % important (adjust as needed)
window         = 9;
half           = floor(window/2);
threshold_hits = 7;

% =====================================
% RESET WORKSPACE
% =====================================
assignin('base','Dc_results', []);

% =====================================
% LOAD FROM WORKSPACE
% =====================================
xx   = evalin('base', 'xx');
T    = evalin('base', 'T');
C    = evalin('base', 'C');
C_dx = evalin('base', 'C_dx');
C_dt = evalin('base', 'C_dt');

x  = xx(:);
t  = T(:);

Nx = length(x);
Nt = length(t);

C_mat    = C';
dcdx_mat = C_dx';
dcdt_mat = C_dt';

% =====================================
% DEBUG
% =====================================
total_points = 0;
used_points  = 0;

c_list  = [];
Dc_list = [];

% =====================================
% LOOP
% =====================================
for ti = 1:Nt

    dcdt_col = dcdt_mat(:, ti);
    dcdx_col = dcdx_mat(:, ti);

    if any(isnan(dcdt_col)) || any(isnan(dcdx_col))
        continue;
    end

    % =====================================
    % WINDOW-BASED CUTOFF
    % =====================================
    x_end_idx = Nx; % fallback

    for i = (1+half):(Nx-half)

        segment = dcdx_col(i-half : i+half);

        count = sum(abs(segment) < grad_cutoff);

        if count >= threshold_hits
            x_end_idx = i;
            break;
        end
    end

    % DEBUG: show cutoff occasionally
    if mod(ti, round(Nt/10)) == 0 || ti == 1
        fprintf('t=%d → cutoff idx=%d (x=%.4f)\n', ti, x_end_idx, x(x_end_idx));
    end

    % =====================================
    % INTEGRAL (TRUNCATED)
    % =====================================
    x_sub    = x(1:x_end_idx);
    dcdt_sub = dcdt_col(1:x_end_idx);

    cum       = cumtrapz(x_sub, dcdt_sub);
    cum_total = cum(end);

    % =====================================
    % X LOOP (TRUNCATED)
    % =====================================
    for xi = 1:x_end_idx-1

        total_points = total_points + 1;

        numerator   = -(cum_total - cum(xi));
        denominator = dcdx_col(xi);

        if abs(denominator) < grad_threshold
            continue;
        end

        Dc = numerator / denominator;
        c  = C_mat(xi, ti);

        if isnan(c) || isnan(Dc) || Dc <= 0 || Dc > Dc_max
            continue;
        end

        used_points = used_points + 1;

        c_list  = [c_list;  c];
        Dc_list = [Dc_list; Dc];
    end
end

% =====================================
% DEBUG OUTPUT
% =====================================
fprintf('\n=====================================\n');
fprintf('TOTAL POINTS: %d\n', total_points);
fprintf('USED POINTS:  %d\n', used_points);
fprintf('USED %%:       %.2f %%\n', 100*used_points/max(total_points,1));
fprintf('=====================================\n');

% =====================================
% BINNING
% =====================================
c_edges   = linspace(0, 0.75, 60);
c_centers = (c_edges(1:end-1) + c_edges(2:end)) / 2;

Dc_mean = NaN(size(c_centers));
Dc_std  = NaN(size(c_centers));

for k = 1:length(c_centers)
    in_bin = c_list >= c_edges(k) & c_list < c_edges(k+1);
    if sum(in_bin) > 5
        Dc_mean(k) = mean(Dc_list(in_bin));
        Dc_std(k)  = std(Dc_list(in_bin)) / sqrt(sum(in_bin));
    end
end

% =====================================
% OVERWRITE STRUCT
% =====================================
Dc_results = struct();

Dc_results.name    = 'C_adaptive';
Dc_results.c_raw   = c_list;
Dc_results.Dc_raw  = Dc_list;
Dc_results.c_mean  = c_centers;
Dc_results.Dc_mean = Dc_mean;
Dc_results.Dc_std  = Dc_std;

assignin('base', 'Dc_results', Dc_results);

fprintf('>>> Saving Dc_results from: %s\n', mfilename);

% =====================================
% PLOT
% =====================================
figure(11); clf;

scatter(c_list, Dc_list, 5, [0.7 0.7 0.7], 'filled', ...
    'MarkerFaceAlpha', 0.15, 'MarkerEdgeAlpha', 0.15);
hold on;

errorbar(c_centers, Dc_mean, Dc_std, 'r.-', ...
    'LineWidth', 1.5, 'MarkerSize', 10);

ax = gca;
ax.YAxis.Exponent = -6;

ylim([0 10e-6]);
yticks(0:1e-6:10e-6);

xlabel('Concentration c [H/M]');
ylabel('D_c [cm^2/s]');
title('Diffusion (adaptive cutoff)');
grid on;

end