function d = obstacleSignedDistance(layout, X, Y)
%OBSTACLESIGNEDDISTANCE Signed distance to the nearest solid (fluid > 0).
%   d = obstacleSignedDistance(layout, X, Y)
%
%   Inputs
%     layout - struct from layoutObstacles
%     X, Y   - query point coordinates (same size, units of W)
%   Output
%     d - same size as X: distance to the nearest solid surface, positive
%         in the fluid, negative inside a solid, +Inf with no obstacles.
%         The channel walls y = 0 and y = 1 are NOT included; the solver
%         imposes them as boundary conditions.
%
%   Posts and baffles use exact distance functions (circle, rotated box).
%   Zigzag walls use the VERTICAL distance to the wall curve; with a linear
%   mask ramp of one cell this makes the solid area of every grid column
%   exact (see buildGeometry).

arguments
    layout (1,1) struct
    X double
    Y double {mustBeEqualSize(X, Y)}
end

d = inf(size(X));
C = layout.circles;
for k = 1:size(C, 1)
    d = min(d, hypot(X - C(k, 1), Y - C(k, 2)) - C(k, 3));
end

R = layout.rects;
for k = 1:numel(R.halfLength)
    ca = cos(R.angle(k));
    sa = sin(R.angle(k));
    dx = X - R.center(k, 1);
    dy = Y - R.center(k, 2);
    qAlong = abs(dx * ca + dy * sa) - R.halfLength(k);
    qAcross = abs(-dx * sa + dy * ca) - R.halfThickness(k);
    dBox = hypot(max(qAlong, 0), max(qAcross, 0)) + min(max(qAlong, qAcross), 0);
    d = min(d, dBox);
end

if layout.zigzag.active
    [yLow, yHigh] = zigzagWalls(X, layout.zigzag);
    d = min(d, min(Y - yLow, yHigh - Y));
end
end

% -------------------------------------------------------------------------
function mustBeEqualSize(a, b)
%MUSTBEEQUALSIZE Validator: a and b must have identical sizes.
if ~isequal(size(a), size(b))
    error('obstacleSignedDistance:size', 'X and Y must have the same size.');
end
end
