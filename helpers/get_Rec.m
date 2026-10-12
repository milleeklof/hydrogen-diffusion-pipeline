function Rec = get_Rec(final_folder)
    % Written by Ola Hartmann
    % Get Rec data
    % Input: final_folder = pathway to data
    % Output: Rec = Rec data
    
% Copyright (c) 2026 Ola Hartmann
% Licensed under the MIT License (see LICENSE in the repository root).

    disp('Reading Rec data...');

    rpath = fullfile(final_folder, 'Rectangular ROI Data.lvm');

    if exist(rpath, 'file') ~= 2
        error('File NOT found:\n%s', rpath);
    end

    Rec = importdata(rpath);
    disp("Data imported")
end