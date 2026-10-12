function fcolor(nfig, a1, a5, stf, rect)
%
% Written by Ola Hartmann
%
% Inputs:
%   nfig = figure number
%   a1 = reference image
%   a5 = current image
%   stf = title
%   rect = the rectangle

% Copyright (c) 2026 Ola Hartmann
% Licensed under the MIT License (see LICENSE in the repository root).

    da1 = double(flipud(a1));
    da5 = double(flipud(a5));

    da52 = log(da5 ./ da1);

    figure(nfig)
    pcolor(da52); shading interp;
    colormap(jet);
    clim([-0.1 0.1]);
    colorbar();
    title(stf);
    hold on;

    img_h = size(da1,1);

    rectangle('Position',[rect(1), img_h - rect(4), rect(2)-rect(1), rect(4)-rect(3)],...
              'EdgeColor','w','LineWidth',2);

    hold off;
end