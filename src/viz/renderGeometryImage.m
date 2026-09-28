function rgb = renderGeometryImage(geom, opts)
%RENDERGEOMETRYIMAGE Draw the fluid-fraction mask as an RGB image (headless).
%   rgb = renderGeometryImage(geom)
%   rgb = renderGeometryImage(geom, Scale=5, XLim=[2 4])
%
%   Inputs
%     geom       - struct from buildGeometry
%     opts.Scale - pixels per grid cell (integer, default 5)
%     opts.XLim  - [xmin xmax] range to keep (units of W, default [0 L])
%   Output
%     rgb - uint8 image, top row = top wall. Grey-blue shading shows phiC
%           exactly as the solver sees it (one flat block per cell), red
%           pixels trace the exact obstacle outlines, dark bands are the
%           channel walls and dashed grey columns mark the mixing section.
%
%   Needs no graphics system: save with imwrite(rgb, 'file.png').

arguments
    geom (1,1) struct
    opts.Scale (1,1) double {mustBeInteger, mustBePositive} = 5
    opts.XLim (1,2) double = [0, geom.grid.L]
end

g = geom.grid;
s = opts.Scale;
hp = g.h / s;                                   % pixel size
xp = ((1:g.nx * s) - 0.5) * hp;                 % pixel-centre x
yp = ((1:g.ny * s)' - 0.5) * hp;                % pixel-centre y
solidColor = [0.35 0.37 0.42];
fluidColor = [0.93 0.96 1.00];

phi = repelem(geom.phiC, s, s);
rgb = phi .* reshape(fluidColor, 1, 1, 3) + (1 - phi) .* reshape(solidColor, 1, 1, 3);
assert(isequal(size(rgb), [g.ny * s, g.nx * s, 3]), 'renderGeometryImage:size', ...
    'Image size mismatch.');

[XP, YP] = meshgrid(xp, yp);
d = obstacleSignedDistance(geom.layout, XP, YP);
rgb = paint(rgb, abs(d) < 0.75 * hp, [0.85 0.10 0.10]);

dashed = mod(floor(yp / (4 * hp)), 2) == 0;
for xLine = [geom.layout.zigzag.x0, geom.layout.zigzag.x1]
    col = min(max(round(xLine / hp + 0.5), 1), numel(xp));
    mask = false(size(phi));
    mask(dashed, col) = true;
    rgb = paint(rgb, mask, [0.3 0.3 0.3]);
end

keep = xp >= opts.XLim(1) & xp <= opts.XLim(2);
rgb = flipud(rgb(:, keep, :));                  % row 1 = top of channel
band = repmat(reshape(solidColor, 1, 1, 3), max(2, round(0.06 / hp)), nnz(keep), 1);
rgb = uint8(round(255 * [band; rgb; band]));
end

% -------------------------------------------------------------------------
function img = paint(img, mask, color)
%PAINT Set the pixels where mask is true to an RGB color (values in [0,1]).
for k = 1:3
    channel = img(:, :, k);
    channel(mask) = color(k);
    img(:, :, k) = channel;
end
end
