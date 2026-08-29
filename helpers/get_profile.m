function [profile, a1] = get_profile(imagedir, files, pnum, rect, max_pixel, min_pixel)
    % Written by Ola Hartmann
    % Get transmission profile I, avg of pixels in y-axis of rect and
    % filter out bad pixels
    % Input: pnum = frame to extratct profile, rect = RoI
    % Output: profile = array with I-values for each pixel in rect i x-axis
    % a1 = image
    
    name = fullfile(imagedir, files(pnum).name);
    a1 = imread(name);

    x1 = rect(1); x2 = rect(2); % x-axis
    y1 = rect(3); y2 = rect(4); % y-axis

    sub = double(a1(y1:y2, x1:x2)); % Rectangle

    mask = (sub < max_pixel) & (sub > min_pixel); % Filter out to bright and to dark pixels

    profile = sum(mask .* sub) ./ sum(mask); % Masked mean, takes avg of y-column
    profile = profile';
end