function mac = makeGrid(params)
%MAKEGRID Coordinates of the uniform staggered (MAC) grid.
%   mac = makeGrid(params)
%
%   Input
%     params - struct from defaultParams (uses params.grid, params.geometry)
%   Output (struct, lengths in units of W)
%     h, nx, ny, L, W
%     xc (1 x nx)     cell-centre x      (pressure, concentration, phiC)
%     yc (ny x 1)     cell-centre y
%     xf (1 x nx+1)   vertical-face x    (u-velocity lives at (xf, yc))
%     yf (ny+1 x 1)   horizontal-face y  (v-velocity lives at (xc, yf))
%
%   Array convention used everywhere in this project: rows = y (index j),
%   columns = x (index i), so a cell-centred field is ny x nx and can be
%   plotted directly with imagesc(xc, yc, field) and axis xy.
%     u : ny     x (nx+1)
%     v : (ny+1) x nx
%     p : ny     x nx

arguments
    params (1,1) struct
end

mac.h = params.grid.h;
mac.nx = params.grid.nx;
mac.ny = params.grid.ny;
mac.L = params.geometry.L;
mac.W = params.geometry.W;
mac.xc = ((1:mac.nx) - 0.5) * mac.h;
mac.yc = ((1:mac.ny)' - 0.5) * mac.h;
mac.xf = (0:mac.nx) * mac.h;
mac.yf = (0:mac.ny)' * mac.h;
end
