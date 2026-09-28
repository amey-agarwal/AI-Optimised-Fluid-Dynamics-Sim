function [isFeasible, info] = checkFeasibility(family, designVector, params)
%CHECKFEASIBILITY Analytical feasibility check of one design (no grid).
%   [isFeasible, info] = checkFeasibility(family, designVector, params)
%
%   Inputs
%     family       - "posts", "baffles", "zigzag" or "empty"
%     designVector - design variables in designSpace(family) order
%     params       - struct from defaultParams (geometry, feasibility)
%   Outputs
%     isFeasible - logical scalar, true iff info.constraint <= 0
%     info       - struct:
%        requiredGap  minimum allowed gap (params.feasibility.minGap)
%        minGap       smallest gap between solids or solid and wall
%                     (Inf if there are no obstacles; negative = overlap)
%        limitingGap  name of the gap type that sets minGap
%        gaps         struct with the smallest gap of each type
%        fitMargin    distance by which obstacles stay inside the mixing
%                     section (negative = they stick out)
%        inBounds     design inside the designSpace bounds
%        constraint   scalar, <= 0 iff feasible; this is the surrogateopt
%                     inequality value (units of W, clipped below at -1)
%        reason       plain-language explanation (string)
%
%   The check never builds a mask, so it is fast enough to be used for
%   thousands of candidate designs (bayesopt XConstraintFcn). Baffle-baffle
%   distances are exact rectangle-rectangle distances; post distances are
%   exact circle distances; the zigzag gap is a conservative lower bound.

arguments
    family (1,1) string {mustBeDesignFamily}
    designVector double
    params (1,1) struct
end

space = designSpace(family);
x = reshape(designVector, 1, []);
assert(numel(x) == numel(space.names), 'checkFeasibility:size', ...
    'Family "%s" expects %d design variables, got %d.', ...
    family, numel(space.names), numel(x));
boundsViolation = max([space.lower - x, x - space.upper, 0]);

layout = layoutObstacles(family, x, params);
g = params.geometry;
gaps = struct();
fitMargin = Inf;
if ~isempty(layout.circles)
    [gaps.postWall, gaps.postPost, fitC] = circleGaps(layout.circles, g);
    fitMargin = min(fitMargin, fitC);
end
if ~isempty(layout.rects.halfLength)
    [gaps.baffleTipWall, gaps.baffleBaffle, fitR] = rectGaps(layout.rects, g);
    fitMargin = min(fitMargin, fitR);
end
if layout.zigzag.active
    gaps.zigzagWidth = zigzagGap(layout.zigzag);
end

gapNames = fieldnames(gaps);
gapValues = cellfun(@(f) gaps.(f), gapNames);
if isempty(gapValues)
    minGap = Inf;
    limitingGap = "none";
else
    [minGap, idx] = min(gapValues);
    limitingGap = string(gapNames{idx});
end

requiredGap = params.feasibility.minGap;
constraint = max([requiredGap - minGap, -fitMargin, -1]);
if boundsViolation > 0
    constraint = max(constraint, boundsViolation);
end
isFeasible = constraint <= 0;

info.requiredGap = requiredGap;
info.minGap = minGap;
info.limitingGap = limitingGap;
info.gaps = gaps;
info.fitMargin = fitMargin;
info.inBounds = boundsViolation <= 0;
info.constraint = constraint;
info.reason = feasibilityReason(info);
end

% -------------------------------------------------------------------------
function [wallGap, pairGap, fitMargin] = circleGaps(C, g)
%CIRCLEGAPS Smallest post-wall and post-post gaps, and mixing-section fit.
xc = C(:, 1);
yc = C(:, 2);
r = C(:, 3);
wallGap = min([yc - r; 1 - yc - r]);
n = numel(r);
if n > 1
    D = hypot(xc - xc.', yc - yc.') - (r + r.');
    pairGap = min(D(triu(true(n), 1)));
else
    pairGap = Inf;
end
fitMargin = min(min(xc - r) - g.xMixStart, g.xMixEnd - max(xc + r));
end

% -------------------------------------------------------------------------
function [tipGap, pairGap, fitMargin] = rectGaps(R, g)
%RECTGAPS Baffle tip to opposite wall, baffle-baffle gaps, section fit.
nr = [-sin(R.angle), cos(R.angle)];
ht = R.halfThickness;
tipX = [R.tip(:, 1) + ht .* nr(:, 1), R.tip(:, 1) - ht .* nr(:, 1)];
tipY = [R.tip(:, 2) + ht .* nr(:, 2), R.tip(:, 2) - ht .* nr(:, 2)];
rootX = [R.root(:, 1) + ht .* nr(:, 1), R.root(:, 1) - ht .* nr(:, 1)];

bottom = R.side > 0;
gapBottomBaffles = 1 - max(tipY(bottom, :), [], 2);  % to the top wall
gapTopBaffles = min(tipY(~bottom, :), [], 2);        % to the bottom wall
tipGap = min([gapBottomBaffles; gapTopBaffles; Inf]);

allX = [tipX, rootX];
fitMargin = min(min(allX, [], 'all') - g.xMixStart, ...
                g.xMixEnd - max(allX, [], 'all'));

n = numel(ht);
pairGap = Inf;
if n > 1
    [cx, cy] = rectCorners(R);
    [I, J] = find(triu(true(n), 1));
    for e1 = 1:4
        n1 = mod(e1, 4) + 1;
        for e2 = 1:4
            n2 = mod(e2, 4) + 1;
            d = segmentDistance([cx(I, e1), cy(I, e1)], [cx(I, n1), cy(I, n1)], ...
                                [cx(J, e2), cy(J, e2)], [cx(J, n2), cy(J, n2)]);
            pairGap = min(pairGap, min(d));
        end
    end
end
end

% -------------------------------------------------------------------------
function gap = zigzagGap(zz)
%ZIGZAGGAP Conservative lower bound on the zigzag channel width.
%   Vertical width is >= 1 - a; the wall slope is bounded by
%   a*(1/ramp + 2/lambda), which converts vertical to normal width.
maxSlope = zz.a * (1 / zz.ramp + 2 / zz.lambda);
gap = (1 - zz.a) / sqrt(1 + maxSlope^2);
end

% -------------------------------------------------------------------------
function reason = feasibilityReason(info)
%FEASIBILITYREASON Plain-language summary of the feasibility result.
if ~info.inBounds
    reason = "design outside variable bounds";
elseif info.fitMargin < 0
    reason = sprintf("obstacles stick out of the mixing section by %.3f", ...
        -info.fitMargin);
elseif info.minGap < info.requiredGap
    reason = sprintf("%s gap %.3f < required %.3f", info.limitingGap, ...
        info.minGap, info.requiredGap);
else
    reason = "feasible";
end
reason = string(reason);
end
