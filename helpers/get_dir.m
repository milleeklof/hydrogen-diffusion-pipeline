function [final_folder, imagedir, files] = get_dir(fdir, fname)
    % Written by Ola Hartmann
    % Get folder
    % Input: fdir = directory, fname = pathway
    % Output: final_folder = pathway to directory, 
    % imagedir = pathway to images, files = struct with image files
    
% Copyright (c) 2026 Ola Hartmann
% Licensed under the MIT License (see LICENSE in the repository root).

    full_name = fullfile(fdir, fname);

    if exist(full_name, 'dir') == 0
        error('Folder NOT found:\n%s', full_name);
    else
        final_folder = full_name;
        disp('Folder found');

        [files, imagedir] = read_image_files(final_folder);
        fprintf('Number of image files: %d\n', length(files));
    end

end

function [files, imagedir] = read_image_files(final_folder)
    % Read image files from directory
    
    imagedir = fullfile(final_folder, 'Images');
    files = dir(fullfile(imagedir, '*.bmp'));

    if isempty(files)
        warning('No images found in %s', imagedir);
    end
end