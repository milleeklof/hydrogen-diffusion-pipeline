% Copyright (c) 2026 Mille Eklöf
% Licensed under the MIT License (see LICENSE in the repository root).

function init_everything_xfit_deriv_noSG()

clc; clear;

% =====================================
% USER SETTINGS
% =====================================
fdir       = '/Users/milleeklof/Research/Experiment data';
active_run = 'N3B_abs125_1st';
           % 'N3A_abs150_1st';
           % 'N3B_abs125_1st';
           % 'N3C_abs150_1st';
           % 'N3D_abs75_1st';
           % 'N4B_abs175_1st';
           % 'N4D_abs100_1st';

p_ref      = 10;
max_pixel  = 250;
min_pixel  = 5;

polyOrder  = 2;
frame_x    = 51; % Can use a pretty large window
frame_t    = 5;

% =====================================
% LOAD RUN
% =====================================
runs = run_catalogue();
run  = runs.(active_run);

fprintf('Run: %s (%d C, %d mbar)\n', ...
    active_run, run.temperature, run.pressure);

% =====================================
% LOAD DATA
% =====================================
[final_folder, imagedir, files] = get_dir(fdir, run.fname);

Rec   = get_Rec(final_folder);
rect  = run.rect;

xchs  = rect(1):rect(2);
xx    = 7.27E-4 * xchs;
% xx    = 7.7E-4 * xchs; % OLD
t_arr = Rec(:,2);

% =====================================
% REFERENCE
% =====================================
[profile_ref, a1] = get_profile(imagedir, files, p_ref, rect, max_pixel, min_pixel);

% =====================================
% BUILD DATASET
% =====================================
p_end        = run.p_start + (run.p_count - 1)*run.p_stride;
indices      = run.p_start:run.p_stride:min(p_end, length(files));

nT = length(indices);
nx = length(xx);

TRM   = zeros(nT, nx);
C_raw = zeros(nT, nx);
T     = zeros(nT, 1);

disp('Building dataset...')

for k = 1:nT
    pnum = indices(k);

    [profile, ~] = get_profile(imagedir, files, pnum, rect, max_pixel, min_pixel);

    yy = calc_trm(profile, profile_ref);
    c  = trm_to_conc(yy);

    TRM(k,:)   = yy;
    C_raw(k,:) = c;

    if pnum <= length(t_arr)
        T(k) = t_arr(pnum);
    else
        warning('Using fallback time for pnum=%d', pnum);
        T(k) = pnum;
    end
end

disp('Done building dataset')

% =====================================
% FLIP
% =====================================
if run.flip
    TRM   = fliplr(TRM);
    C_raw = fliplr(C_raw);
end

% =====================================
% MONOTONIC TIME
% =====================================
if ~all(diff(T) > 0)
    warning('T not monotonic — fixing');
    [T, ia] = unique(T);

    TRM     = TRM(ia,:);
    C_raw   = C_raw(ia,:);
    indices = indices(ia);

    nT = length(T);
end

% =====================================
% SMOOTH ONLY IN X
% =====================================
disp('Smoothing in x...')

C = zeros(size(C_raw));

for ti = 1:nT
    C(ti,:) = sgolayfilt(C_raw(ti,:), polyOrder, frame_x);
end

disp('Done smoothing')

% =====================================
% DERIVATIVES
% =====================================
disp('Computing derivatives...')

x_vec = xx(:);
t_vec = T(:);

C_dx = zeros(size(C));
C_dt = zeros(size(C));

% ===== dC/dx =====
for ti = 1:nT
    C_dx(ti,:) = gradient(C(ti,:), x_vec);
end

% ===== raw dC/dt =====
for xi = 1:nx
    C_dt(:,xi) = gradient(C(:,xi), t_vec);
end

disp('Done computing derivatives')

% =====================================
% QUICK PREVIEW (ALL TIMES)
% =====================================
active_run_label = strrep(active_run, '_', '\_'); % escape underscores so they don't render as subscript

figure(10); clf; hold on;

for k = 1:nT
    plot(xx, TRM(k,:), '.');
end

title(sprintf('Transmission — %s', active_run_label));
xlabel('x (m)');
ylabel('Transmission');
grid on;


figure(11); clf; hold on;

for k = 1:nT
    plot(xx, C(k,:), '.');
end

title(sprintf('Concentration — %s', active_run_label));
xlabel('x (m)');
ylabel('C');
grid on;

% =====================================
% SANITY CHECK
% =====================================
fprintf('\n--- Sanity check ---\n');

fprintf('TRM:   [%d x %d]  [%.4f, %.4f]\n', size(TRM,1), size(TRM,2), min(TRM(:)), max(TRM(:)));
fprintf('C_raw: [%d x %d]  [%.4f, %.4f]\n', size(C_raw,1), size(C_raw,2), min(C_raw(:)), max(C_raw(:)));
fprintf('C:     [%d x %d]  [%.4f, %.4f]\n', size(C,1), size(C,2), min(C(:)), max(C(:)));
fprintf('C_dx:  [%d x %d]  [%.4e, %.4e]\n', size(C_dx,1), size(C_dx,2), min(C_dx(:)), max(C_dx(:)));
fprintf('C_dt:  [%d x %d]  [%.4e, %.4e]\n', size(C_dt,1), size(C_dt,2), min(C_dt(:)), max(C_dt(:)));

% =====================================
% SAVE
% =====================================
assignin('base','xx', xx);
assignin('base','T', T);
assignin('base','TRM', TRM);
assignin('base','C_raw', C_raw);
assignin('base','C', C);
assignin('base','C_dx', C_dx);
assignin('base','C_dt', C_dt);
assignin('base','indices', indices);

assignin('base','imagedir', imagedir);
assignin('base','files', files);
assignin('base','rect', rect);
assignin('base','a1', a1);

assignin('base','max_pixel', max_pixel);
assignin('base','min_pixel', min_pixel);

assignin('base','fname', run.fname);
assignin('base','active_run', active_run);

disp('INIT DONE')

end