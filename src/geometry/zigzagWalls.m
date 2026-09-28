function [yLow, yHigh] = zigzagWalls(x, zz)
%ZIGZAGWALLS Lower and upper wall heights of a zigzag channel.
%   [yLow, yHigh] = zigzagWalls(x, zz)
%
%   Inputs
%     x  - array of x positions (any size)
%     zz - zigzag struct from layoutObstacles: a, lambda, x0, x1, ramp,
%          active
%   Outputs (same size as x)
%     yLow  - fluid starts above this height (solid for y < yLow)
%     yHigh - fluid ends below this height   (solid for y > yHigh)
%
%   Both walls follow the same triangle wave z(x) in [-1, 1] (z(x0) = 0),
%   scaled by an envelope e(x) that ramps linearly from 0 to 1 over
%   zz.ramp at each end of the mixing section [x0, x1]:
%       yLow  = a*e*(1 + z)/2,   yHigh = 1 - a*e*(1 - z)/2
%   so the vertical channel width is 1 - a*e (0.7 at worst) and the
%   centreline swings by +-a/2. The ramps avoid a step in the walls at the
%   ends of the mixing section. Outside [x0, x1] both walls are flat.

arguments
    x double
    zz (1,1) struct
end

if ~zz.active
    yLow = zeros(size(x));
    yHigh = ones(size(x));
    return
end
phase = mod((x - zz.x0) / zz.lambda + 0.25, 1);
z = 1 - 4 * abs(phase - 0.5);                       % triangle wave
e = min(max(min(x - zz.x0, zz.x1 - x) / zz.ramp, 0), 1);
yLow = zz.a * e .* (1 + z) / 2;
yHigh = 1 - zz.a * e .* (1 - z) / 2;
end
