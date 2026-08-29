% =====================================
% quick_inspection.m
% =====================================
function quick_inspection()

% =====================================
% LOAD FROM WORKSPACE
% =====================================
xx        = evalin('base', 'xx');
T         = evalin('base', 'T');
TRM       = evalin('base', 'TRM');
C_raw     = evalin('base', 'C_raw');
C         = evalin('base', 'C');
C_dx      = evalin('base', 'C_dx');
C_dt      = evalin('base', 'C_dt');

imagedir  = evalin('base', 'imagedir');
files     = evalin('base', 'files');
rect      = evalin('base', 'rect');
a1        = evalin('base', 'a1');
indices   = evalin('base', 'indices');

max_pixel = evalin('base', 'max_pixel');
min_pixel = evalin('base', 'min_pixel');

nT   = length(T);
xmin = min(xx);
xmax = max(xx);

% =====================================
% SETUP FIGUR
% =====================================
figure(1); clf;

% 4x2 layout
tl = tiledlayout(4, 2);
tl.TileSpacing = 'compact';
tl.Padding     = 'compact';

ax = gobjects(7,1);

for i = 1:7
    ax(i) = nexttile;
    grid(ax(i), 'on');

    if i ~= 1
        hold(ax(i), 'on');
        xlabel(ax(i), 'x (m)');
    end
end

% =====================================
% HISTORY STORAGE
% =====================================
C_history = [];

% =====================================
% LOOP THROUGH TIME STEPS (INTERACTIVE)
% =====================================
k = 1;
C_history = [];

while true

    if k < 1
        k = 1;
    elseif k > nT
        k = nT;
    end

    pnum  = indices(k);
    t_now = T(k);

    % =====================================
    % IMAGE
    % =====================================
    [~, a5] = get_profile(imagedir, files, pnum, rect, max_pixel, min_pixel);
    cla(ax(1)); axes(ax(1));
    fcolor(gcf, a1, a5, sprintf('t = %.1f s', t_now), rect);

    % =====================================
    % TRM
    % =====================================
    cla(ax(2));
    plot(ax(2), xx, TRM(k,:), '.');
    xlim(ax(2), [xmin xmax]);
    title(ax(2), 'TRM');

    % =====================================
    % C RAW
    % =====================================
    cla(ax(3));
    plot(ax(3), xx, C_raw(k,:), '.');
    xlim(ax(3), [xmin xmax]);
    title(ax(3), 'C raw');

    % =====================================
    % C SMOOTH + OVERLAY
    % =====================================
    cla(ax(4));
    hold(ax(4), 'on');
    plot(ax(4), xx, C_raw(k,:), '.', 'Color', [0.7 0.7 0.7]);
    plot(ax(4), xx, C(k,:), '-', 'LineWidth', 1.5);
    xlim(ax(4), [xmin xmax]);
    title(ax(4), 'C smooth');
    legend(ax(4), {'raw','smooth'}, 'Location','best');

    % =====================================
    % dC/dx
    % =====================================
    cla(ax(5));
    plot(ax(5), xx, C_dx(k,:), '.');
    xlim(ax(5), [xmin xmax]);
    yline(ax(5), 0, 'k--');
    title(ax(5), 'dC/dx');

    % =====================================
    % dC/dt
    % =====================================
    cla(ax(6));
    plot(ax(6), xx, C_dt(k,:), '.');
    xlim(ax(6), [xmin xmax]);
    yline(ax(6), 0, 'k--');
    title(ax(6), 'dC/dt');

    % =====================================
    % HISTORY (RESET IF WE JUMP)
    % =====================================
    if size(C_history,1) ~= k
        C_history = C(1:k,:);
    end

    cla(ax(7));
    hold(ax(7),'on');

    for i = 1:size(C_history,1)
        plot(ax(7), xx, C_history(i,:), '-');
    end

    xlim(ax(7), [xmin xmax]);
    title(ax(7), 'C history');

    % =====================================
    % TITLE
    % =====================================
    sgtitle(sprintf('k = %d/%d | t = %.1f s | image %d', ...
        k, nT, t_now, pnum));

    % =====================================
    % USER INPUT
    % =====================================
    user_input = input('Enter = next | number = jump | q = quit: ', 's');

    if isempty(user_input)
        k = k + 1;

    elseif strcmpi(user_input, 'q')
        break;

    else
        new_k = str2double(user_input);

        if ~isnan(new_k)
            k = round(new_k);
        else
            fprintf('Invalid input\n');
        end
    end
end