function c = trm_to_conc(trm)
% Written by Ola Hartmann

% Copyright (c) 2026 Ola Hartmann
% Licensed under the MIT License (see LICENSE in the repository root).

persistent yy_grid c_grid

if isempty(yy_grid)
    data = load('cubic_calibration.mat');
    p = data.polyfit_150_cubic;
    c_grid  = linspace(0, 1, 2000);
    yy_grid = polyval(p, c_grid);
end

% Negative transmission = noise around zero = c near 0
% Clamp to valid range
trm_clamped = max(min(yy_grid), min(max(yy_grid), trm));
c = interp1(yy_grid, c_grid, trm_clamped, 'pchip');
end