classdef GeometryTest < matlab.unittest.TestCase
    %GEOMETRYTEST Tests for layoutObstacles, checkFeasibility, buildGeometry.
    %   Covers: post positions, rejection of overlapping / too-close /
    %   out-of-section designs, exact baffle distances, mask sizes and
    %   values, and mask solid area vs analytical area.

    properties
        coarse
        fine
    end

    methods (TestClassSetup)
        function setup(testCase)
            root = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(root, 'src'), 'IncludingSubfolders', true));
            testCase.coarse = defaultParams("coarse");
            testCase.fine = defaultParams("fine");
        end
    end

    methods (Test)
        % ------------------------------------------------ post positions
        function postsSitWhereExpected(testCase)
            % 4 rows, d = 0.2, pitch 1, delta = 0.5, 1 post per row:
            % rows centred on x = 5 -> x = 3.5, 4.5, 5.5, 6.5;
            % in-row pitch P = (1 + 0.2)/2 = 0.6, shift = 0.5*0.6/2 = 0.15,
            % so odd rows sit at y = 0.35 and even rows at y = 0.65.
            L = layoutObstacles("posts", [4, 0.2, 1.0, 0.5, 1], testCase.coarse);
            expected = [3.5 0.35 0.1; 4.5 0.65 0.1; 5.5 0.35 0.1; 6.5 0.65 0.1];
            testCase.verifyEqual(L.circles, expected, 'AbsTol', 1e-12);
        end

        function twoPostsPerRow(testCase)
            % P = (1 + 0.2)/3 = 0.4 -> y = 0.4 - 0.1 = 0.3 and 0.8 - 0.1 = 0.7
            L = layoutObstacles("posts", [3, 0.2, 1.0, 0, 2], testCase.coarse);
            testCase.verifySize(L.circles, [6, 3]);
            testCase.verifyEqual(unique(round(L.circles(:, 2), 12))', [0.3, 0.7], 'AbsTol', 1e-12);
            testCase.verifyEqual(unique(L.circles(:, 1))', [4, 5, 6], 'AbsTol', 1e-12);
        end

        function threePostsHaveEqualGaps(testCase)
            % m = 3, d = 0.15: gap to walls = gap between posts = 0.1375
            [ok, info] = checkFeasibility("posts", [2, 0.15, 1.0, 0, 3], testCase.coarse);
            testCase.verifyTrue(ok);
            testCase.verifyEqual(info.gaps.postWall, 0.1375, 'AbsTol', 1e-12);
            testCase.verifyEqual(info.gaps.postPost, 0.1375, 'AbsTol', 1e-12);
        end

        function integerVariablesAreRounded(testCase)
            L = layoutObstacles("posts", [3.8, 0.2, 1.0, 0, 1.2], testCase.coarse);
            testCase.verifyEqual(L.designVector([1 5]), [4, 1]);
            testCase.verifySize(L.circles, [4, 3]);
        end

        function wrongLengthErrors(testCase)
            testCase.verifyError(@() layoutObstacles("posts", [1 2 3], ...
                testCase.coarse), 'layoutObstacles:size');
        end

        % ------------------------------------------------- feasibility
        function overlappingPostsRejected(testCase)
            % rows 0.4 apart with d = 0.5 overlap by 0.1
            [ok, info] = checkFeasibility("posts", [4, 0.5, 0.4, 0, 1], testCase.coarse);
            testCase.verifyFalse(ok);
            testCase.verifyEqual(info.minGap, -0.1, 'AbsTol', 1e-12);
            testCase.verifyEqual(info.limitingGap, "postPost");
        end

        function gapThresholdRespected(testCase)
            % gap 0.10 < 0.125 rejected; gap 0.15 accepted
            [okTight, infoTight] = checkFeasibility("posts", [2, 0.3, 0.40, 0, 1], testCase.coarse);
            [okWide, infoWide] = checkFeasibility("posts", [2, 0.3, 0.45, 0, 1], testCase.coarse);
            testCase.verifyFalse(okTight);
            testCase.verifyEqual(infoTight.minGap, 0.10, 'AbsTol', 1e-12);
            testCase.verifyTrue(okWide);
            testCase.verifyEqual(infoWide.minGap, 0.15, 'AbsTol', 1e-12);
        end

        function postTooCloseToWallRejected(testCase)
            % P = 0.75, shift 0.1875 -> y = 0.3125 with r = 0.25: gap 0.0625
            [ok, info] = checkFeasibility("posts", [2, 0.5, 1.0, 0.5, 1], testCase.coarse);
            testCase.verifyFalse(ok);
            testCase.verifyEqual(info.limitingGap, "postWall");
        end

        function tooLongArrayRejected(testCase)
            % 12 rows at pitch 1.5 span 16.5 > mixing section length 8
            [ok, info] = checkFeasibility("posts", [12, 0.3, 1.5, 0, 1], testCase.coarse);
            testCase.verifyFalse(ok);
            testCase.verifyLessThan(info.fitMargin, 0);
            testCase.verifySubstring(char(info.reason), 'mixing section');
        end

        function outOfBoundsRejected(testCase)
            [ok, info] = checkFeasibility("posts", [4, 0.6, 1.0, 0, 1], testCase.coarse);
            testCase.verifyFalse(ok);
            testCase.verifyFalse(info.inBounds);
            testCase.verifyGreaterThan(info.constraint, 0);
        end

        function baffleDistancesExact(testCase)
            % Vertical baffles, l = 0.8, s = 0.3: tip gap 0.2 exactly,
            % face-to-face gap between neighbours 0.3 - 0.05 = 0.25.
            [ok, info] = checkFeasibility("baffles", [2, 0.8, 0.3, 0], testCase.coarse);
            testCase.verifyTrue(ok);
            testCase.verifyEqual(info.gaps.baffleTipWall, 0.2, 'AbsTol', 1e-12);
            testCase.verifyEqual(info.gaps.baffleBaffle, 0.25, 'AbsTol', 1e-12);
        end

        function tiltedCrowdedBafflesRejected(testCase)
            [ok, info] = checkFeasibility("baffles", [6, 0.8, 0.3, 45], testCase.coarse);
            testCase.verifyFalse(ok);
            testCase.verifyEqual(info.limitingGap, "baffleBaffle");
        end

        function positiveAngleLeansDownstream(testCase)
            L = layoutObstacles("baffles", [2, 0.5, 1.0, 20], testCase.coarse);
            testCase.verifyEqual(L.rects.side', [1, -1]);
            testCase.verifyTrue(all(L.rects.tip(:, 1) > L.rects.root(:, 1)));
            testCase.verifyEqual(L.rects.root(:, 2)', [0, 1]);
        end

        function zigzagAlwaysFeasibleAtBoundsCorners(testCase)
            space = designSpace("zigzag");
            for a = [space.lower(1), space.upper(1)]
                for lambda = [space.lower(2), space.upper(2)]
                    testCase.verifyTrue(checkFeasibility("zigzag", [a, lambda], ...
                        testCase.coarse), sprintf('a=%g lambda=%g', a, lambda));
                end
            end
        end

        function examplesAreFeasible(testCase)
            for family = ["posts", "baffles", "zigzag", "empty"]
                space = designSpace(family);
                [ok, info] = checkFeasibility(family, space.example, testCase.coarse);
                testCase.verifyTrue(ok, family + ": " + info.reason);
            end
        end

        function batchMatchesSingle(testCase)
            X = [4, 0.5, 0.4, 0, 1; 6, 0.3, 1.0, 0.3, 1; 12, 0.3, 1.5, 0, 1];
            [okBatch, cBatch] = checkFeasibilityBatch("posts", X, testCase.coarse);
            for k = 1:size(X, 1)
                [ok, info] = checkFeasibility("posts", X(k, :), testCase.coarse);
                testCase.verifyEqual(okBatch(k), ok);
                testCase.verifyEqual(cBatch(k), info.constraint);
            end
            testCase.verifyEqual(okBatch', [false, true, false]);
        end

        % ------------------------------------------------------- masks
        function maskSizesAndRange(testCase)
            geom = buildGeometry("posts", [6, 0.3, 1.0, 0.3, 1], testCase.coarse);
            g = geom.grid;
            testCase.verifySize(geom.phiC, [g.ny, g.nx]);
            testCase.verifySize(geom.phiU, [g.ny, g.nx + 1]);
            testCase.verifySize(geom.phiV, [g.ny + 1, g.nx]);
            for phi = {geom.phiC, geom.phiU, geom.phiV}
                testCase.verifyGreaterThanOrEqual(min(phi{1}, [], 'all'), 0);
                testCase.verifyLessThanOrEqual(max(phi{1}, [], 'all'), 1);
            end
        end

        function emptyChannelIsAllFluid(testCase)
            geom = buildGeometry("empty", [], testCase.coarse);
            testCase.verifyTrue(all(geom.phiC == 1, 'all'));
            testCase.verifyTrue(all(geom.phiU == 1, 'all'));
            testCase.verifyTrue(all(geom.phiV == 1, 'all'));
            % zigzag with a = 0 is also the empty channel
            geomZ = buildGeometry("zigzag", [0, 1.5], testCase.coarse);
            testCase.verifyTrue(all(geomZ.phiC == 1, 'all'));
        end

        function postCentreSolidFarFieldFluid(testCase)
            geom = buildGeometry("posts", [4, 0.2, 1.0, 0.5, 1], testCase.coarse);
            g = geom.grid;
            [~, i] = min(abs(g.xc - 3.5));
            [~, j] = min(abs(g.yc - 0.35));   % first-row post at (3.5, 0.35)
            testCase.verifyEqual(geom.phiC(j, i), 0);
            [~, i0] = min(abs(g.xc - 0.5));
            [~, j0] = min(abs(g.yc - 0.5));
            testCase.verifyEqual(geom.phiC(j0, i0), 1);
        end

        function maskAreaPosts(testCase)
            testCase.verifyMaskArea("posts", [6, 0.3, 1.0, 0.3, 1], 0.02, 0.02);
            testCase.verifyMaskArea("posts", [8, 0.15, 0.8, 0, 3], 0.03, 0.02);
        end

        function maskAreaBaffles(testCase)
            % t = 0.05 is only 1.2 coarse cells thick: looser coarse tolerance
            testCase.verifyMaskArea("baffles", [6, 0.5, 1.0, 20], 0.05, 0.03);
            testCase.verifyMaskArea("baffles", [4, 0.7, 1.5, 0], 0.05, 0.03);
        end

        function maskAreaZigzag(testCase)
            testCase.verifyMaskArea("zigzag", [0.2, 1.5], 0.01, 0.01);
            testCase.verifyMaskArea("zigzag", [0.3, 0.5], 0.02, 0.01);
        end
    end

    methods
        function verifyMaskArea(testCase, family, x, tolCoarse, tolFine)
            % Relative error of the mask solid area on both grids.
            for pair = {{testCase.coarse, tolCoarse}, {testCase.fine, tolFine}}
                params = pair{1}{1};
                tol = pair{1}{2};
                geom = buildGeometry(family, x, params);
                testCase.assertTrue(geom.isFeasible, geom.feasibility.reason);
                relErr = abs(geom.solidAreaMask - geom.solidAreaExact) / geom.solidAreaExact;
                testCase.verifyLessThan(relErr, tol, sprintf( ...
                    '%s %s (%s): mask %.5f vs exact %.5f', family, ...
                    mat2str(x), params.mode, geom.solidAreaMask, geom.solidAreaExact));
            end
        end
    end
end
