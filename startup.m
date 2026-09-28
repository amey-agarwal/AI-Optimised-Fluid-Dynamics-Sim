%STARTUP Set up the micromixer-opt project in the current MATLAB session.
%   Run from the project root:   >> startup
%   - adds every src/ subfolder and scripts/ to the MATLAB path
%   - creates the gitignored results/ and figures/ folders if missing
%   - prints the MATLAB release, the required toolboxes (installed and
%     licensed), key functions, parallel-pool availability and the
%     available VideoWriter profiles.
%   Nothing expensive is started (in particular, no parallel pool).

micromixerStartup();

% -------------------------------------------------------------------------
function micromixerStartup()
%MICROMIXERSTARTUP Path setup plus environment report (no inputs/outputs).
root = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(root, 'src')));
addpath(fullfile(root, 'scripts'));
for folder = ["results", "figures"]
    target = fullfile(root, folder);
    if ~isfolder(target)
        mkdir(target);
    end
end

fprintf('\n===== micromixer-opt startup report =====\n');
fprintf('Project root : %s\n', root);
fprintf('MATLAB       : %s (R%s)\n', version, version('-release'));
fprintf('Platform     : %s, computational threads: %d\n', ...
    computer, maxNumCompThreads);
reportReleaseFeatures();
reportToolboxes();
reportParallel();
reportVideoProfiles();
fprintf('==========================================\n');
fprintf('Next: results = runtests(''tests'')\n\n');
end

% -------------------------------------------------------------------------
function reportReleaseFeatures()
%REPORTRELEASEFEATURES Warn about release-dependent features we rely on.
features = { ...
    'R2019b', 'arguments blocks'; ...
    'R2022a', 'exportgraphics(..., ''Append'', true) for GIFs'; ...
    'R2022b', 'codeIssues'; ...
    'R2023b', 'gitclone / gitrepo'};
fprintf('\nRelease-dependent features:\n');
for k = 1:size(features, 1)
    ok = ~isMATLABReleaseOlderThan(features{k, 1});
    fprintf('  [%s] %-45s (needs %s)\n', okText(ok), features{k, 2}, ...
        features{k, 1});
end
end

% -------------------------------------------------------------------------
function reportToolboxes()
%REPORTTOOLBOXES Print installed/licensed status and key function checks.
%   Each row: product name, license feature name, functions we will use.
toolboxes = { ...
    'Statistics and Machine Learning Toolbox', 'Statistics_Toolbox', ...
        {'bayesopt', 'fitrgp', 'fitrensemble', 'lhsdesign', 'shapley', ...
         'lime', 'plotPartialDependence'}; ...
    'Optimization Toolbox', 'Optimization_Toolbox', {'optimoptions'}; ...
    'Global Optimization Toolbox', 'GADS_Toolbox', ...
        {'surrogateopt', 'paretosearch'}; ...
    'Parallel Computing Toolbox', 'Distrib_Computing_Toolbox', ...
        {'gcp', 'parpool'}};
v = ver;
installedNames = {v.Name};
fprintf('\nToolboxes:\n');
for k = 1:size(toolboxes, 1)
    name = toolboxes{k, 1};
    isInstalled = any(strcmp(installedNames, name));
    isLicensed = logical(license('test', toolboxes{k, 2}));
    fns = toolboxes{k, 3};
    missing = fns(cellfun(@(f) isempty(which(f)), fns));
    fprintf('  %-42s installed: %-3s licensed: %-3s', name, ...
        okText(isInstalled), okText(isLicensed));
    if isempty(missing)
        fprintf(' functions: all found\n');
    else
        fprintf(' MISSING functions: %s\n', strjoin(missing, ', '));
    end
end
end

% -------------------------------------------------------------------------
function reportParallel()
%REPORTPARALLEL Report whether a parallel pool could be used (no pool start).
fprintf('\nParallel:\n');
if isempty(which('canUseParallelPool'))
    fprintf('  canUseParallelPool not available -> code will run serially\n');
    return
end
try
    canUse = canUseParallelPool();
catch err
    canUse = false;
    fprintf('  canUseParallelPool errored: %s\n', err.message);
end
fprintf('  canUseParallelPool: %s\n', okText(canUse));
end

% -------------------------------------------------------------------------
function reportVideoProfiles()
%REPORTVIDEOPROFILES List VideoWriter profiles; flag MPEG-4 availability.
profiles = VideoWriter.getProfiles();
names = {profiles.Name};
fprintf('\nVideoWriter profiles: %s\n', strjoin(names, ', '));
fprintf('  MPEG-4 available: %s\n', okText(any(strcmp(names, 'MPEG-4'))));
end

% -------------------------------------------------------------------------
function txt = okText(flag)
%OKTEXT Convert a logical flag to 'yes' or 'no' for printing.
if flag
    txt = 'yes';
else
    txt = 'no';
end
end
