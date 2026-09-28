function presets = fluidPresets(name)
%FLUIDPRESETS Dimensionless descriptions of the liquid pairs studied.
%   presets = fluidPresets()       returns a 5x1 struct array (all presets).
%   preset  = fluidPresets(name)   returns the single named preset.
%
%   Input
%     name - "all" (default) or one of "waterDye", "waterGlycerol",
%            "slowDiffuser", "unequalFlow", "moderateRe".
%   Output (struct fields, all dimensionless)
%     name            - preset name (string)
%     Re              - Reynolds number U*W*rho/muB (defined with liquid B)
%     Pe              - Peclet number U*W/D
%     viscosityRatio  - muA/muB (liquid A = c = 1 = lower inlet stream)
%     q               - flow-rate ratio Q_A/Q_B
%     muA, muB        - viscosities scaled by muB (muB = 1)
%     fluxFractionA   - fraction of the total flux carried by A, q/(1+q)
%     interfaceHeight - inlet height y0 below which c = 1, such that the
%                       parabolic profile carries fluxFractionA below y0
%     isExtension     - true if the preset goes beyond the core plan
%     peProvisional   - true if Pe may be lowered after the Step 3
%                       grid-refinement check
%     description     - short physical description

arguments
    name (1,1) string {mustBeValidPresetName} = "all"
end

presets = allPresets();
if name ~= "all"
    presets = presets([presets.name] == name);
end
end

% -------------------------------------------------------------------------
function list = allPresets()
%ALLPRESETS Build the full preset list (struct array, one row per preset).
list = [ ...
    makePreset("waterDye",      0.5, 500,  1,  1,    false, false, ...
        "Water with a dye tracer: equal viscosity, equal flow rates")
    makePreset("waterGlycerol", 0.1, 500,  20, 1,    false, false, ...
        "Glycerol-rich stream A is 20x more viscous than water stream B")
    makePreset("slowDiffuser",  0.5, 2000, 1,  1,    false, true, ...
        "Large, slowly diffusing solute (e.g. a protein); Pe provisional")
    makePreset("unequalFlow",   0.5, 500,  1,  0.25, false, false, ...
        "Stream A enters at a quarter of the flow rate of stream B")
    makePreset("moderateRe",    20,  500,  1,  1,    true,  false, ...
        "Faster flow where inertia starts to matter (extension)")];
end

% -------------------------------------------------------------------------
function p = makePreset(name, Re, Pe, viscosityRatio, q, isExtension, ...
                        peProvisional, description)
%MAKEPRESET Assemble one preset struct and its derived quantities.
p.name = name;
p.Re = Re;
p.Pe = Pe;
p.viscosityRatio = viscosityRatio;
p.q = q;
p.muA = viscosityRatio;
p.muB = 1;
p.fluxFractionA = q / (1 + q);
p.interfaceHeight = inletInterfaceHeight(p.fluxFractionA);
p.isExtension = isExtension;
p.peProvisional = peProvisional;
p.description = description;
end

% -------------------------------------------------------------------------
function y0 = inletInterfaceHeight(f)
%INLETINTERFACEHEIGHT Height y0 in [0,1] with flux fraction f below it.
%   For the parabolic inlet u(y) = 6*y*(1-y) (mean 1, width 1), the
%   cumulative flux is F(y) = 3*y^2 - 2*y^3, which rises monotonically from
%   0 to 1, so F(y0) = f has exactly one root in [0, 1].
if f <= 0
    y0 = 0;
elseif f >= 1
    y0 = 1;
else
    opts = optimset('TolX', 1e-14);
    y0 = fzero(@(y) 3*y.^2 - 2*y.^3 - f, [0, 1], opts);
end
end

% -------------------------------------------------------------------------
function mustBeValidPresetName(name)
%MUSTBEVALIDPRESETNAME Argument validator for the preset name.
valid = ["all", "waterDye", "waterGlycerol", "slowDiffuser", ...
         "unequalFlow", "moderateRe"];
if ~any(name == valid)
    error('fluidPresets:unknownPreset', ...
        'Unknown preset "%s". Valid names: %s.', name, strjoin(valid, ', '));
end
end
