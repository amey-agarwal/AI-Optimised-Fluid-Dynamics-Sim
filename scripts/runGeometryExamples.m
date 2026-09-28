%% Step 1 - Geometry examples
% Builds an example ("generic") design for each family on the coarse grid,
% prints feasibility and mask-area diagnostics, saves plots to figures/,
% shows how an infeasible design is reported, and times the feasibility
% check that will run inside bayesopt's XConstraintFcn.

tStart = tic;
params = defaultParams("coarse");
paramsFine = defaultParams("fine");
figDir = params.paths.figures;
families = ["posts", "baffles", "zigzag"];

%% Example designs: diagnostics and plots
fig = figure('Color', 'w', 'Position', [100 100 1200 820]);
tl = tiledlayout(fig, numel(families) + 1, 1, 'TileSpacing', 'compact');
fprintf('\n%-8s %-26s %-9s %-8s %-10s %-10s %-8s\n', 'family', 'design', ...
    'feasible', 'minGap', 'areaExact', 'areaMask', 'relErr');
for family = families
    space = designSpace(family);
    geom = buildGeometry(family, space.example, params);
    relErr = abs(geom.solidAreaMask - geom.solidAreaExact) / geom.solidAreaExact;
    fprintf('%-8s %-26s %-9d %-8.3f %-10.4f %-10.4f %-8.4f\n', family, ...
        mat2str(space.example, 3), geom.isFeasible, geom.feasibility.minGap, ...
        geom.solidAreaExact, geom.solidAreaMask, relErr);
    plotGeometry(geom, 'Parent', nexttile(tl));
    % Single-family image from its own figure (exporting one axes of a
    % tiled layout is what failed to render in MATLAB Online).
    figOne = figure('Color', 'w', 'Position', [100 100 1100 240]);
    plotGeometry(geom, 'Parent', axes(figOne));
    report(saveFigure(figOne, fullfile(figDir, "geometry_" + family + ".png")), family);
    close(figOne);
end

%% An infeasible design: overlapping posts
badDesign = [4, 0.5, 0.4, 0, 1];
geomBad = buildGeometry("posts", badDesign, params);
fprintf('\nInfeasible example %s -> feasible = %d, reason: %s\n', ...
    mat2str(badDesign), geomBad.isFeasible, geomBad.feasibility.reason);
plotGeometry(geomBad, 'Parent', nexttile(tl));
report(saveFigure(fig, fullfile(figDir, "geometry_examples.png")), "examples");

%% Thin baffles: coarse vs fine mask (zoom)
figZoom = figure('Color', 'w', 'Position', [150 150 1000 520]);
tlZ = tiledlayout(figZoom, 2, 1, 'TileSpacing', 'compact');
spaceBaffles = designSpace("baffles");
baffles = spaceBaffles.example;
for p = {params, paramsFine}
    geomZ = buildGeometry("baffles", baffles, p{1});
    ax = nexttile(tlZ);
    plotGeometry(geomZ, 'Parent', ax, 'Title', ...
        sprintf('baffles, %s grid (h = 1/%d): mask vs exact outline', ...
        p{1}.mode, p{1}.grid.cellsPerWidth));
    xlim(ax, [2.0 4.0]);
end
report(saveFigure(figZoom, fullfile(figDir, "geometry_baffle_zoom.png")), "baffle zoom");

%% Timing: feasibility check (XConstraintFcn workload) and mask build
rng(1);
nRandom = 2000;
fprintf('\n%-8s %-14s %-16s\n', 'family', 'feasibleFrac', 'ms per check');
for family = families
    X = randomDesigns(designSpace(family), nRandom);
    tCheck = tic;
    isFeasible = checkFeasibilityBatch(family, X, params);
    fprintf('%-8s %-14.3f %-16.4f\n', family, mean(isFeasible), ...
        1e3 * toc(tCheck) / nRandom);
end
spacePosts = designSpace("posts");
for p = {params, paramsFine}
    tBuild = tic;
    buildGeometry("posts", spacePosts.example, p{1});
    fprintf('buildGeometry (posts, %s): %.1f ms\n', p{1}.mode, 1e3 * toc(tBuild));
end
fprintf('\nFigures saved to %s\n', figDir);
fprintf('runGeometryExamples total runtime: %.2f s\n', toc(tStart));

% -------------------------------------------------------------------------
function report(method, name)
%REPORT Print how a figure was saved.
fprintf('  figure %-12s saved via: %s\n', name, method);
end

% -------------------------------------------------------------------------
function X = randomDesigns(space, n)
%RANDOMDESIGNS Uniform random designs inside the bounds (integers via randi).
d = numel(space.names);
X = space.lower + rand(n, d) .* (space.upper - space.lower);
for k = find(space.isInteger)
    X(:, k) = randi([space.lower(k), space.upper(k)], n, 1);
end
end
