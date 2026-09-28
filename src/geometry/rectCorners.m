function [cx, cy] = rectCorners(rects)
%RECTCORNERS Corner coordinates of rotated rectangles.
%   [cx, cy] = rectCorners(rects)
%
%   Input
%     rects - struct from layoutObstacles with column arrays center (Nx2),
%             halfLength, halfThickness, angle [rad]
%   Outputs
%     cx, cy - N x 4 corner coordinates, ordered counter-clockwise, so
%              edge k runs from corner k to corner mod(k,4)+1.

arguments
    rects (1,1) struct
end

ax = [cos(rects.angle), sin(rects.angle)];     % along the baffle axis
nr = [-sin(rects.angle), cos(rects.angle)];    % across the baffle
signAlong = [1, -1, -1, 1];
signAcross = [1, 1, -1, -1];
cx = rects.center(:, 1) + rects.halfLength .* ax(:, 1) .* signAlong ...
    + rects.halfThickness .* nr(:, 1) .* signAcross;
cy = rects.center(:, 2) + rects.halfLength .* ax(:, 2) .* signAlong ...
    + rects.halfThickness .* nr(:, 2) .* signAcross;
end
