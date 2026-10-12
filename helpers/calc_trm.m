function trm = calc_trm(profile, profile_ref)
    % Written by Ola Hartmann
    % Calculate transmission profile (including prefactor lamda/4*pi*t0)
    % Output: trm = array of transmission values with length of rect x-axis
    
% Copyright (c) 2026 Ola Hartmann
% Licensed under the MIT License (see LICENSE in the repository root).

    %%% Configuration %%%
    lamda = 450; % nm, wavelength of light from diode
    t0 = 70; % nm, thickness of sample
    
    % Calculation
    trm = lamda / (4*pi*t0) * log(profile ./ profile_ref); % With prefactor!

end