% =====================================
% stenlund_inspection.m
% =====================================
function stenlund_inspection()

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

Nt = length(t);
Nx = length(x);

% =====================================
% SELECT TIME STEP
% =====================================
fprintf('\nTime steps available: 1 -> %d\n', Nt);
ti = input('Select time index ti: ');

C_t    = C(ti,:)';
dcdx_t = C_dx(ti,:)';
dcdt_t = C_dt(ti,:)';

% =====================================
% FIX NaN IN dC/dt
% =====================================
if any(isnan(dcdt_t))
    fprintf('WARNING: %d NaN in dC/dt at this time step\n', sum(isnan(dcdt_t)));
    dcdt_t(isnan(dcdt_t)) = 0;
end

% =====================================
% WINDOW-BASED CUTOFF
% =====================================
grad_cutoff    = 0.3;   % adjust as needed
window         = 9;
half           = floor(window/2);
threshold_hits = 7;

cutoff_idx = Nx; % fallback

for i = (1+half):(Nx-half)

    segment = dcdx_t(i-half : i+half);

    count = sum(abs(segment) < grad_cutoff);

    if count >= threshold_hits
        cutoff_idx = i;
        break;
    end
end

fprintf('\n--- CUTOFF DEBUG ---\n');
fprintf('grad_cutoff   = %.4f\n', grad_cutoff);
fprintf('window        = %d\n', window);
fprintf('threshold_hits= %d\n', threshold_hits);
fprintf('cutoff_idx    = %d / %d\n', cutoff_idx, Nx);
fprintf('x_cutoff      = %.4f m\n', x(cutoff_idx));

% =====================================
% SETUP FIGUR
% =====================================
figure(2); clf;

tl = tiledlayout(3,1);
tl.TileSpacing = 'compact';
tl.Padding     = 'compact';

% ----- C(x)
ax1 = nexttile;
plot(ax1, x, C_t, 'b-', 'LineWidth', 1.5);
ylabel(ax1, 'C [H/M]');
title(ax1, sprintf('C(x) at t = %.1f s', t(ti)));
xline(ax1, x(cutoff_idx), 'k--', 'Label', 'x_{cut}');
grid(ax1, 'on'); hold(ax1, 'on');

% ----- dC/dx
ax2 = nexttile;
plot(ax2, x, dcdx_t, 'r-', 'LineWidth', 1.5);
ylabel(ax2, 'dC/dx');
title(ax2, 'dC/dx(x)');
yline(ax2, 0, 'k--');
xline(ax2, x(cutoff_idx), 'k--');
grid(ax2, 'on'); hold(ax2, 'on');

% ----- dC/dt
ax3 = nexttile;
plot(ax3, x, dcdt_t, 'g-', 'LineWidth', 1.5);
ylabel(ax3, 'dC/dt');
title(ax3, 'dC/dt(x)');
yline(ax3, 0, 'k--');
xline(ax3, x(cutoff_idx), 'k--');
xlabel(ax3, 'x (m)');
grid(ax3, 'on'); hold(ax3, 'on');

% =====================================
% INTERAKTIV LOOP
% =====================================
fprintf('\nPress ENTER to step along x (1 -> %d)...\n', cutoff_idx-1);

h_line1 = []; h_line2 = []; h_area = []; h_point = [];

for xi = 1:cutoff_idx-1

    % Clear old handles
    if ~isempty(h_line1) && isvalid(h_line1); delete(h_line1); end
    if ~isempty(h_line2) && isvalid(h_line2); delete(h_line2); end
    if ~isempty(h_area)  && isvalid(h_area);  delete(h_area);  end
    if ~isempty(h_point) && isvalid(h_point); delete(h_point); end

    % =====================================
    % INTEGRAL (ONLY up to cutoff)
    % =====================================
    x_int    = x(xi:cutoff_idx);
    dcdt_int = dcdt_t(xi:cutoff_idx);

    integral  = trapz(x_int, dcdt_int);
    numerator = -integral;
    denominator = dcdx_t(xi);

    if abs(denominator) < 1e-10
        Dc = NaN;
    else
        Dc = numerator / denominator;
    end

    c = C_t(xi);

    % =====================================
    % VISUALISERING
    % =====================================
    h_line1 = xline(ax2, x(xi), 'b-', 'LineWidth', 2);
    h_line2 = xline(ax3, x(xi), 'b-', 'LineWidth', 2);

    h_area = area(ax3, x_int, dcdt_int, ...
        'FaceAlpha', 0.3, 'FaceColor', 'g', 'EdgeColor', 'none');

    h_point = plot(ax1, x(xi), C_t(xi), 'ro', ...
        'MarkerSize', 8, 'MarkerFaceColor', 'r');

    % =====================================
    % PRINT
    % =====================================
    fprintf('\n--- xi = %d ---\n', xi);
    fprintf('x        = %.4f m\n', x(xi));
    fprintf('C        = %.4f H/M\n', c);
    fprintf('dC/dx    = %.4e\n', denominator);
    fprintf('Integral = %.4e\n', integral);

    if isnan(Dc)
        fprintf('D_c      = NaN (dC/dx too small)\n');
    else
        fprintf('D_c      = %.4e cm^2/s\n', Dc);
    end

    pause;
end

fprintf('\nDone!\n');

end