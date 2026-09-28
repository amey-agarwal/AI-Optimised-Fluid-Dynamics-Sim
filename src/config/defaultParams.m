function params = defaultParams(mode)
%DEFAULTPARAMS Default geometric, numerical and objective parameters.
%   params = defaultParams()      returns coarse-mode parameters.
%   params = defaultParams(mode)  with mode = "coarse" or "fine".
%
%   Input
%     mode   - "coarse": h = 1/24, used inside optimisation loops.
%              "fine"  : h = 1/48, used for final results and videos.
%   Output
%     params - struct with fields mode, geometry, grid, flow, scalar,
%              coupling, feasibility, objective, paths.
%
%   Units (everything is dimensionless):
%     length    scaled by the channel width W        -> W = 1
%     velocity  scaled by the mean inlet velocity U  -> U = 1
%     time      scaled by W/U
%     pressure  scaled by muB*U/W (viscous scaling, natural for Re <= 20)
%     viscosity scaled by muB, the viscosity of liquid B (upper stream)
%   The physics enters only through Re, Pe, viscosityRatio and q, which
%   live in fluidPresets.m, not here.

arguments
    mode (1,1) string {mustBeMember(mode, ["coarse", "fine"])} = "coarse"
end

params.mode = mode;

% ---------------------------------------------------------------- geometry
params.geometry.W = 1;                          % channel width
params.geometry.L = 10;                         % channel length
params.geometry.xMixStart = 1;                  % mixing section start
params.geometry.xMixEnd = params.geometry.L - 1;% mixing section end
params.geometry.baffleThickness = 0.05;         % fixed baffle thickness
params.geometry.maskSmoothCells = 1;            % mask edge width [cells]
params.geometry.zigzagRamp = 0.5;               % amplitude ramp length at
                                                % each end of a zigzag

% -------------------------------------------------------------------- grid
% h is defined through an integer number of cells per width so that nx
% and ny are exact integers (no floating-point rounding of L/h).
switch mode
    case "coarse"
        cellsPerWidth = 24;
    case "fine"
        cellsPerWidth = 48;
    otherwise
        error('defaultParams:mode', 'Unknown mode "%s".', mode);
end
params.grid.cellsPerWidth = cellsPerWidth;
params.grid.h = params.geometry.W / cellsPerWidth;
params.grid.nx = params.geometry.L * cellsPerWidth;   % cells along x
params.grid.ny = params.geometry.W * cellsPerWidth;   % cells along y
assert(params.grid.nx == round(params.grid.nx) && ...
       params.grid.ny == round(params.grid.ny), ...
       'defaultParams:grid', 'L/h and W/h must be integers.');

% -------------------------------------------------------------------- flow
params.flow.picardTol = 1e-6;       % relative velocity change to stop
params.flow.picardMaxIter = 100;    % report non-convergence beyond this
params.flow.picardRelax = 1.0;      % under-relaxation (1 = none)
params.flow.brinkmanAlpha = 1e6;    % penalisation drag; verified in Step 2
params.flow.solidVelocityTol = 1e-3;% required max |u| inside solids
params.flow.outletPressure = 0;     % pressure reference at the outlet

% ------------------------------------------------------------------ scalar
params.scalar.cfl = 0.5;            % explicit advection CFL limit
params.scalar.limiter = "vanLeer";  % flux limiter for 2nd-order advection
params.scalar.steadyTol = 1e-6;     % relative change per unit time to stop
params.scalar.maxFlowThroughs = 8;  % max march time in units of L/U

% ---------------------------------------------------------------- coupling
params.coupling.tol = 1e-3;         % change in outlet mixing index to stop
params.coupling.maxOuter = 6;       % max flow <-> concentration iterations

% ------------------------------------------------------------- feasibility
% The minimum gap must be >= 0.1 AND >= 3 grid cells. The grid-cell rule
% is evaluated on the COARSE grid in both modes so the feasible design set
% is identical in coarse and fine mode (an optimum found in coarse mode is
% guaranteed to be feasible when re-evaluated in fine mode).
params.feasibility.minGapAbs = 0.1;
params.feasibility.minGapCells = 3;
params.feasibility.referenceH = 1/24;
params.feasibility.minGap = max(params.feasibility.minGapAbs, ...
    params.feasibility.minGapCells * params.feasibility.referenceH);

% --------------------------------------------------------------- objective
% J = -M_out + wP*log(dpNorm) + wD*deadZoneFraction   (to be minimised)
params.objective.wP = 0.05;
params.objective.wD = 0.5;
params.objective.deadZoneSpeed = 0.01;  % |u| below this counts as dead

% ------------------------------------------------------------------- paths
root = projectRoot();
params.paths.root = root;
params.paths.results = fullfile(root, 'results');
params.paths.figures = fullfile(root, 'figures');
end
