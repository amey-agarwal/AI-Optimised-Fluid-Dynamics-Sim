classdef ScaffoldTest < matlab.unittest.TestCase
    %SCAFFOLDTEST Sanity checks for the Step 0 scaffold.
    %   Verifies the path setup, the grid sizes in defaultParams, the
    %   feasibility gap rule, and the values/derived fields of fluidPresets.
    %   Run with:  results = runtests('tests')

    methods (TestClassSetup)
        function addSourcePath(testCase)
            % Put src/ on the path for the duration of the tests, so the
            % tests also work if startup.m has not been run.
            root = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(root, 'src'), 'IncludingSubfolders', true));
        end
    end

    methods (Test)
        function projectRootContainsStartup(testCase)
            testCase.verifyTrue(isfile(fullfile(projectRoot(), 'startup.m')));
        end

        function coarseGrid(testCase)
            p = defaultParams("coarse");
            testCase.verifyEqual(p.grid.h, 1/24, 'AbsTol', 1e-15);
            testCase.verifyEqual([p.grid.nx, p.grid.ny], [240, 24]);
        end

        function fineGrid(testCase)
            p = defaultParams("fine");
            testCase.verifyEqual(p.grid.h, 1/48, 'AbsTol', 1e-15);
            testCase.verifyEqual([p.grid.nx, p.grid.ny], [480, 48]);
        end

        function defaultModeIsCoarse(testCase)
            p = defaultParams();
            testCase.verifyEqual(p.mode, "coarse");
        end

        function invalidModeErrors(testCase)
            threw = false;
            try
                defaultParams("medium");
            catch
                threw = true;
            end
            testCase.verifyTrue(threw);
        end

        function minGapIsModeIndependent(testCase)
            pCoarse = defaultParams("coarse");
            pFine = defaultParams("fine");
            gap = pCoarse.feasibility.minGap;
            testCase.verifyEqual(gap, 0.125, 'AbsTol', 1e-15);
            testCase.verifyEqual(pFine.feasibility.minGap, gap);
        end

        function allPresetsPresent(testCase)
            presets = fluidPresets();
            expected = ["waterDye", "waterGlycerol", "slowDiffuser", ...
                        "unequalFlow", "moderateRe"];
            testCase.verifyEqual(reshape([presets.name], 1, []), expected);
        end

        function waterGlycerolValues(testCase)
            p = fluidPresets("waterGlycerol");
            testCase.verifyEqual([p.Re, p.Pe, p.viscosityRatio, p.q], ...
                                 [0.1, 500, 20, 1]);
            testCase.verifyEqual([p.muA, p.muB], [20, 1]);
        end

        function interfaceHeightEqualFlow(testCase)
            % q = 1 -> half the flux below y0 -> y0 = 0.5 by symmetry.
            p = fluidPresets("waterDye");
            testCase.verifyEqual(p.interfaceHeight, 0.5, 'AbsTol', 1e-12);
        end

        function interfaceHeightUnequalFlow(testCase)
            % q = 0.25 -> A carries 20% of the flux below y0.
            p = fluidPresets("unequalFlow");
            y0 = p.interfaceHeight;
            testCase.verifyEqual(p.fluxFractionA, 0.2, 'AbsTol', 1e-15);
            testCase.verifyEqual(3*y0^2 - 2*y0^3, 0.2, 'AbsTol', 1e-10);
            testCase.verifyLessThan(y0, 0.5);
        end

        function unknownPresetErrors(testCase)
            threw = false;
            try
                fluidPresets("honey");
            catch
                threw = true;
            end
            testCase.verifyTrue(threw);
        end
    end
end
