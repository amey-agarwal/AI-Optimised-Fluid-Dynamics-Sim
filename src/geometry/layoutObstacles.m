function layout = layoutObstacles(family, designVector, params)
%LAYOUTOBSTACLES Analytical obstacle descriptions for one design.
%   layout = layoutObstacles(family, designVector, params)
%
%   Inputs
%     family       - "posts", "baffles", "zigzag" or "empty"
%     designVector - design variables in designSpace(family) order;
%                    integer variables are rounded here
%     params       - struct from defaultParams (uses params.geometry)
%   Output (struct; every field exists for every family, empty if unused)
%     family, designVector (cleaned, 1 x d)
%     circles - N x 3 [xCentre, yCentre, radius]
%     rects   - struct of column arrays, one row per baffle:
%               center (Nx2), halfLength, halfThickness, angle (axis angle
%               from +x [rad]), root (Nx2, wall attachment point), tip
%               (Nx2), side (+1 bottom wall, -1 top wall), length
%     zigzag  - struct: active, a, lambda, x0, x1, ramp
%
%   Layout rules (all lengths in units of W = 1):
%     posts:   rows are centred on the middle of the mixing section with
%              pitch s. The m posts of a row are placed with EQUAL gaps
%              g = (1 - m*d)/(m+1) between posts and to both walls, i.e.
%              y_j = j*P - d/2 with in-row pitch P = (1 + d)/(m+1). Odd
%              rows move down and even rows up by delta*P/2, so the
%              relative offset between neighbouring rows is delta*P.
%     baffles: centred the same way with spacing s; odd baffles hang from
%              the bottom wall, even ones from the top wall; each leans
%              downstream by theta for theta > 0. The rectangle extends a
%              distance t into the wall so that tilted baffles stay
%              attached to the wall without a sliver gap.
%     zigzag:  see zigzagWalls.

arguments
    family (1,1) string {mustBeDesignFamily}
    designVector double
    params (1,1) struct
end

space = designSpace(family);
x = reshape(designVector, 1, []);
assert(numel(x) == numel(space.names), 'layoutObstacles:size', ...
    'Family "%s" expects %d design variables, got %d.', ...
    family, numel(space.names), numel(x));
x(space.isInteger) = round(x(space.isInteger));

g = params.geometry;
layout = emptyLayout(family, x, g);
switch family
    case "posts"
        layout.circles = postCircles(x, g);
    case "baffles"
        layout.rects = baffleRects(x, g);
    case "zigzag"
        layout.zigzag.a = x(1);
        layout.zigzag.lambda = x(2);
        layout.zigzag.active = x(1) > 0;
    case "empty"
        % no obstacles
end
end

% -------------------------------------------------------------------------
function layout = emptyLayout(family, x, g)
%EMPTYLAYOUT Layout with all fields present and no obstacles.
layout.family = family;
layout.designVector = x;
layout.circles = zeros(0, 3);
layout.rects = struct('center', zeros(0, 2), 'halfLength', zeros(0, 1), ...
    'halfThickness', zeros(0, 1), 'angle', zeros(0, 1), ...
    'root', zeros(0, 2), 'tip', zeros(0, 2), 'side', zeros(0, 1), ...
    'length', zeros(0, 1));
layout.zigzag = struct('active', false, 'a', 0, 'lambda', 1, ...
    'x0', g.xMixStart, 'x1', g.xMixEnd, 'ramp', g.zigzagRamp);
end

% -------------------------------------------------------------------------
function circles = postCircles(x, g)
%POSTCIRCLES Centres and radii of all posts, rows ordered along x.
nRows = x(1);
r = x(2) / 2;
s = x(3);
delta = x(4);
m = x(5);
xMid = (g.xMixStart + g.xMixEnd) / 2;
xRow = xMid + ((1:nRows) - (nRows + 1) / 2) * s;   % 1 x nRows
P = (1 + 2 * r) / (m + 1);                          % in-row pitch
yBase = (1:m)' * P - r;                             % m x 1, equal gaps
shift = delta * P / 2 * (-1).^(1:nRows);            % 1 x nRows
[Y, X] = ndgrid(yBase, xRow);                       % m x nRows
Y = Y + shift;                                      % shift each row
circles = [X(:), Y(:), repmat(r, m * nRows, 1)];
end

% -------------------------------------------------------------------------
function rects = baffleRects(x, g)
%BAFFLERECTS Rotated rectangles for alternating wall-mounted baffles.
n = x(1);
l = x(2);
s = x(3);
theta = x(4) * pi / 180;
t = g.baffleThickness;
xMid = (g.xMixStart + g.xMixEnd) / 2;

xRoot = xMid + ((1:n)' - (n + 1) / 2) * s;          % n x 1
side = ones(n, 1);
side(2:2:end) = -1;                                  % +1 bottom, -1 top
yRoot = (1 - side) / 2;                              % 0 bottom, 1 top
axisDir = [sin(theta) * ones(n, 1), side * cos(theta)]; % unit, root->tip

rects.root = [xRoot, yRoot];
rects.tip = rects.root + l * axisDir;
% Rectangle spans axis coordinate [-t, l] from the root, so its centre is
% at (l - t)/2 and its half-length is (l + t)/2.
rects.center = rects.root + ((l - t) / 2) * axisDir;
rects.halfLength = repmat((l + t) / 2, n, 1);
rects.halfThickness = repmat(t / 2, n, 1);
rects.angle = atan2(axisDir(:, 2), axisDir(:, 1));
rects.side = side;
rects.length = repmat(l, n, 1);
end
