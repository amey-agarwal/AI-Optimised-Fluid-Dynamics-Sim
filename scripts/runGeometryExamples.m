%% Step 1 - Geometry examples
% Builds an example ("generic") design for each family on the coarse grid,
% prints feasibility and mask-area diagnostics, saves pictures to figures/,
% shows how an infeasible design is reported, and times the feasibility
% check that will run inside bayesopt's XConstraintFcn.
% Pictures: normal figures, or PNGs written with imwrite when isHeadless()
% is true (setpref('micromixer', 'headless', true)).

tStart = tic;
params = defaultParams("coarse");
paramsFine = defaultParams("fine");
figDir = params.paths.figures;
families = ["posts", "baffles", "zigzag"];
headless = isHeadless();
fprintf('\nGraphics mode: %s\n', string(ternary(headless, "headless (imwrite)", "figures")));

%% Example designs: diagnostics and pictures
badDesign = [4, 0.5, 0.4, 0, 1];
geoms = cell(1, numel(families) + 1);
fprintf('\n%-8s %-26s %-9s %-8s %-10s %-10s %-8s\n', 'family', 'design', ...
    'feasible', 'minGap', 'areaExact', 'areaMask', 'relErr');
for k = 1:numel(families)
    family = families(k);
    space = designSpace(family);
    geoms{k} = buildGeometry(family, space.example, params);
    geom = geoms{k};
    relErr = abs(geom.solidAreaMask - geom.solidAreaExact) / geom.solidAreaExact;
    fprintf('%-8s %-26s %-9d %-8.3f %-10.4f %-10.4f %-8.4f\n', family, ...
        mat2str(space.example, 3), geom.isFeasible, geom.feasibility.minGap, ...
        geom.solidAreaExact, geom.solidAreaMask, relErr);
end
geoms{end} = buildGeometry("posts", badDesign, params);
fprintf('\nInfeasible example %s -> feasible = %d, reason: %s\n', ...
    mat2str(badDesign), geoms{end}.isFeasible, geoms{end}.feasibility.reason);

names = [families, "infeasible"];
if headless
    stack = {};
    for k = 1:numel(geoms)
        rgb = renderGeometryImage(geoms{k});
        imwrite(rgb, fullfile(figDir, "geometry_" + names(k) + ".png"));
        stack = [stack, {rgb, 255 * ones(12, size(rgb, 2), 3, 'uint8')}]; %#ok<AGROW>
    end
    imwrite(vertcat(stack{1:end-1}), fullfile(figDir, "geometry_examples.png"));
    fprintf('  wrote geometry_<family>.png and geometry_examples.png via imwrite\n');
else
    fig = figure('Color', 'w', 'Position', [100 100 1200 820]);
    tl = tiledlayout(fig, numel(geoms), 1, 'TileSpacing', 'compact');
    figOne = figure('Color', 'w', 'Position', [100 100 1100 240]);
    axOne = axes(figOne);
    for k = 1:numel(geoms)
        plotGeometry(geoms{k}, 'Parent', nexttile(tl));
        cla(axOne);
        plotGeometry(geoms{k}, 'Parent', axOne);
        report(saveFigure(figOne, fullfile(figDir, "geometry_" + names(k) + ".png")), names(k));
    end
    close(figOne);
    report(saveFigure(fig, fullfile(figDir, "geometry_examples.png")), "examples");
end

%% Thin baffles: coarse vs fine mask (zoom on 2 <= x <= 4)
spaceBaffles = designSpace("baffles");
geomCoarse = buildGeometry("baffles", spaceBaffles.example, params);
geomFine = buildGeometry("baffles", spaceBaffles.example, paramsFine);
if headless
    % Same pixels per unit length on both grids: 10 px/cell coarse, 5 fine.
    top = renderGeometryImage(geomCoarse, 'Scale', 10, 'XLim', [2 4]);
    bottom = renderGeometryImage(geomFine, 'Scale', 5, 'XLim', [2 4]);
    imwrite([top; 255 * ones(12, size(top, 2), 3, 'uint8'); bottom], ...
        fullfile(figDir, "geometry_baffle_zoom.png"));
    fprintf('  wrote geometry_baffle_zoom.png via imwrite (top coarse, bottom fine)\n');
else
    figZoom = figure('Color', 'w', 'Position', [150 150 1000 520]);
    tlZ = tiledlayout(figZoom, 2, 1, 'TileSpacing', 'compact');
    for geomZ = {geomCoarse, geomFine}
        ax = nexttile(tlZ);
        plotGeometry(geomZ{1}, 'Parent', ax, 'Title', sprintf( ...
            'baffles, h = 1/%d: mask vs exact outline', round(1 / geomZ{1}.grid.h)));
        xlim(ax, [2.0 4.0]);
    end
    report(saveFigure(figZoom, fullfile(figDir, "geometry_baffle_zoom.png")), "baffle zoom");
end

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
function out = ternary(condition, a, b)
%TERNARY Return a if condition is true, otherwise b.
if condition
    out = a;
else
    out = b;
end
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
