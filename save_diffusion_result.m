% Copyright (c) 2026 Mille Eklöf
% Licensed under the MIT License (see LICENSE in the repository root).

function save_diffusion_result()

% =====================================
% LOAD FROM WORKSPACE
% =====================================
Dc_results = evalin('base', 'Dc_results');
active_run = evalin('base', 'active_run');

% =====================================
% LOAD RUN INFO
% =====================================
runs = run_catalogue();
run  = runs.(active_run);

temperature = run.temperature;
pressure    = run.pressure;

fprintf('Run: %s | %d C | %d mbar\n', ...
    active_run, temperature, pressure);

% =====================================
% CHECK
% =====================================
if ~isfield(Dc_results, 'name')
    error('Dc_results is missing the field "name"');
end

fprintf('>>> Saving profile: %s\n', Dc_results.name);

% =====================================
% EXTRACT DATA
% =====================================
c  = Dc_results.c_mean(:);
mn = Dc_results.Dc_mean(:);
st = Dc_results.Dc_std(:);

% =====================================
% TABLE
% =====================================
T_out = table(c, mn, st, ...
    'VariableNames', {'c_H_M', 'Dc_mean', 'Dc_std'});

% =====================================
% FILENAME
% =====================================
outdir = 'diffusions';
if ~exist(outdir, 'dir')
    mkdir(outdir);
end

filename = fullfile(outdir, sprintf('Dc_%s_%dC_%dmbar_%s.csv', ...
    active_run, temperature, pressure, Dc_results.name));

% =====================================
% SAVE
% =====================================
writetable(T_out, filename);

fprintf('Saved: %s\n', filename);

end