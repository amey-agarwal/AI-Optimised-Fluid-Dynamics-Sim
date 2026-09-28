function geom = buildGeometry(family, designVector, params)
%BUILDGEOMETRY Fluid-fraction masks on the MAC grid for one design.
%   geom = buildGeometry(family, designVector, params)
%
%   Inputs
%     family       - "posts", "baffles", "zigzag" or "empty"
%     designVector - design variables in designSpace(family) order
%     params       - struct from defaultParams
%   Output (struct)
%     family, designVector, layout (from layoutObstacles), grid (makeGrid)
%     phiC (ny x nx)    fluid fraction at cell centres (1 fluid, 0 solid)
%     phiU (ny x nx+1)  fluid fraction at u-faces
%     phiV (ny+1 x nx)  fluid fraction at v-faces
%     isFeasible, feasibility (outputs of checkFeasibility)
%     solidAreaMask   sum(1 - phiC)*h^2, solid area seen by the grid
%     solidAreaExact  analytical solid area inside the channel
%
%   The mask is phi = clamp(0.5 + dist/w, 0, 1), with dist the signed
%   distance to the nearest solid and w = maskSmoothCells*h. This linear
%   ramp is centred on the true surface, so for straight edges the ramp's
%   extra solid on one side cancels the missing solid on the other, and the
%   solid area is preserved. The solver sees a smooth transition one cell
%   wide instead of a staircase. phi is evaluated directly at every
%   staggered location instead of being interpolated, so the Brinkman
%   drag on u and v uses the exact local fraction.
%   Infeasible designs are still built (for plotting); check isFeasible.

arguments
    family (1,1) string {mustBeDesignFamily}
    designVector double
    params (1,1) struct
end

mac = makeGrid(params);
layout = layoutObstacles(family, designVector, params);
[isFeasible, feasibility] = checkFeasibility(family, designVector, params);
w = params.geometry.maskSmoothCells * mac.h;

[XC, YC] = meshgrid(mac.xc, mac.yc);
[XU, YU] = meshgrid(mac.xf, mac.yc);
[XV, YV] = meshgrid(mac.xc, mac.yf);
phiC = rampFraction(obstacleSignedDistance(layout, XC, YC), w);
phiU = rampFraction(obstacleSignedDistance(layout, XU, YU), w);
phiV = rampFraction(obstacleSignedDistance(layout, XV, YV), w);

assert(isequal(size(phiC), [mac.ny, mac.nx]), 'buildGeometry:phiC', ...
    'phiC must be ny x nx.');
assert(isequal(size(phiU), [mac.ny, mac.nx + 1]), 'buildGeometry:phiU', ...
    'phiU must be ny x (nx+1).');
assert(isequal(size(phiV), [mac.ny + 1, mac.nx]), 'buildGeometry:phiV', ...
    'phiV must be (ny+1) x nx.');

geom.family = family;
geom.designVector = layout.designVector;
geom.layout = layout;
geom.grid = mac;
geom.phiC = phiC;
geom.phiU = phiU;
geom.phiV = phiV;
geom.isFeasible = isFeasible;
geom.feasibility = feasibility;
geom.solidAreaMask = sum(1 - phiC, 'all') * mac.h^2;
geom.solidAreaExact = exactSolidArea(layout);
end

% -------------------------------------------------------------------------
function phi = rampFraction(d, w)
%RAMPFRACTION Fluid fraction from signed distance d with ramp width w.
phi = min(max(0.5 + d / w, 0), 1);
end

% -------------------------------------------------------------------------
function area = exactSolidArea(layout)
%EXACTSOLIDAREA Analytical solid area inside 0 <= y <= 1 (feasible designs).
%   Posts: sum of pi*r^2. Baffles: l*t each; the part of the rectangle
%   inside the wall is excluded exactly. Its cut line lies at a slant, but
%   it removes the same area as a straight cut at the root. Zigzag: the
%   lower and upper solids add up to a*e(x), whose integral over the
%   trapezoidal envelope is a*(x1 - x0 - ramp).
area = sum(pi * layout.circles(:, 3).^2);
area = area + sum(layout.rects.length .* 2 .* layout.rects.halfThickness);
zz = layout.zigzag;
if zz.active
    area = area + zz.a * (zz.x1 - zz.x0 - zz.ramp);
end
end
