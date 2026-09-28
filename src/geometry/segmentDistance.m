function d = segmentDistance(a1, a2, b1, b2)
%SEGMENTDISTANCE Minimum distance between pairs of 2D line segments.
%   d = segmentDistance(a1, a2, b1, b2)
%
%   Inputs
%     a1, a2 - N x 2 end points of segments A
%     b1, b2 - N x 2 end points of segments B
%   Output
%     d - N x 1 distance between segment A(k) and segment B(k);
%         0 if they intersect.
%
%   For non-intersecting segments the minimum distance is attained at an
%   end point of one of them, so it is the smallest of four point-to-segment
%   distances.

arguments
    a1 (:,2) double
    a2 (:,2) double
    b1 (:,2) double
    b2 (:,2) double
end

d = min([pointSegment(a1, b1, b2), pointSegment(a2, b1, b2), ...
         pointSegment(b1, a1, a2), pointSegment(b2, a1, a2)], [], 2);
d(segmentsCross(a1, a2, b1, b2)) = 0;
end

% -------------------------------------------------------------------------
function d = pointSegment(p, s1, s2)
%POINTSEGMENT Distance from points p (Nx2) to segments s1-s2 (Nx2 each).
v = s2 - s1;
t = sum((p - s1) .* v, 2) ./ max(sum(v.^2, 2), eps);
t = min(max(t, 0), 1);
d = sqrt(sum((p - (s1 + t .* v)).^2, 2));
end

% -------------------------------------------------------------------------
function tf = segmentsCross(a1, a2, b1, b2)
%SEGMENTSCROSS True where segments properly intersect (strict sign test).
%   Touching/collinear cases give a zero point-to-segment distance anyway.
cross2 = @(u, v) u(:, 1) .* v(:, 2) - u(:, 2) .* v(:, 1);
o1 = cross2(a2 - a1, b1 - a1);
o2 = cross2(a2 - a1, b2 - a1);
o3 = cross2(b2 - b1, a1 - b1);
o4 = cross2(b2 - b1, a2 - b1);
tf = (o1 .* o2 < 0) & (o3 .* o4 < 0);
end
