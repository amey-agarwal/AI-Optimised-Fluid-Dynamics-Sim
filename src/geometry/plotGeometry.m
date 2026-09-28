function ax = plotGeometry(geom, opts)
%PLOTGEOMETRY Draw the channel, the fluid-fraction mask and obstacle outlines.
%   ax = plotGeometry(geom)
%   ax = plotGeometry(geom, Parent=ax, ShowMask=true, Title="...")
%
%   Inputs
%     geom          - struct from buildGeometry
%     opts.Parent   - axes to draw into (default: new figure and axes)
%     opts.ShowMask - true: show phiC as an image with red outlines of the
%                     exact obstacles; false: solid grey obstacles only
%     opts.Title    - title text; default states family, design and
%                     feasibility
%   Output
%     ax - the axes handle
%
%   Lengths are in units of W; the dashed lines mark the mixing section.

arguments
    geom (1,1) struct
    opts.Parent = []
    opts.ShowMask (1,1) logical = true
    opts.Title (1,1) string = ""
end

ax = opts.Parent;
if isempty(ax)
    ax = axes(figure('Color', 'w'));
end
hold(ax, 'on');
g = geom.grid;
layout = geom.layout;
solidColor = [0.35 0.37 0.42];
fluidColor = [0.93 0.96 1.00];

if opts.ShowMask
    imagesc(ax, g.xc, g.yc, geom.phiC);
    colormap(ax, [linspace(solidColor(1), fluidColor(1), 64)', ...
                  linspace(solidColor(2), fluidColor(2), 64)', ...
                  linspace(solidColor(3), fluidColor(3), 64)']);
    clim(ax, [0 1]);
    faceColor = 'none';
    edgeColor = [0.85 0.1 0.1];
else
    faceColor = solidColor;
    edgeColor = 'none';
end

theta = linspace(0, 2*pi, 65);
for k = 1:size(layout.circles, 1)
    c = layout.circles(k, :);
    patch(ax, c(1) + c(3) * cos(theta), c(2) + c(3) * sin(theta), 'k', ...
        'FaceColor', faceColor, 'EdgeColor', edgeColor, 'LineWidth', 1);
end

[cx, cy] = rectCorners(layout.rects);
for k = 1:size(cx, 1)
    patch(ax, cx(k, :), cy(k, :), 'k', 'FaceColor', faceColor, ...
        'EdgeColor', edgeColor, 'LineWidth', 1);
end

if layout.zigzag.active
    xs = linspace(0, g.L, 2000);
    [yLow, yHigh] = zigzagWalls(xs, layout.zigzag);
    patch(ax, [xs, fliplr(xs)], [yLow, zeros(size(xs))], 'k', ...
        'FaceColor', faceColor, 'EdgeColor', edgeColor, 'LineWidth', 1);
    patch(ax, [xs, fliplr(xs)], [yHigh, ones(size(xs))], 'k', ...
        'FaceColor', faceColor, 'EdgeColor', edgeColor, 'LineWidth', 1);
end

% Channel walls as grey bands, drawn last so they hide anything inside them.
band = 0.06;
patch(ax, [0 g.L g.L 0], [-band -band 0 0], solidColor, 'EdgeColor', 'none');
patch(ax, [0 g.L g.L 0], [1 1 1+band 1+band], solidColor, 'EdgeColor', 'none');
xline(ax, [layout.zigzag.x0, layout.zigzag.x1], '--', 'Color', [0.3 0.3 0.3]);

axis(ax, 'equal');
set(ax, 'YDir', 'normal', 'Layer', 'top', 'FontSize', 11);
xlim(ax, [0 g.L]);
ylim(ax, [-band, 1 + band]);
xlabel(ax, 'x / W');
ylabel(ax, 'y / W');

titleText = opts.Title;
if titleText == ""
    titleText = sprintf('%s  %s  (%s)', geom.family, ...
        mat2str(geom.designVector, 3), geom.feasibility.reason);
end
title(ax, titleText, 'Interpreter', 'none');
hold(ax, 'off');
end
