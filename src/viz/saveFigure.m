function method = saveFigure(fig, file, opts)
%SAVEFIGURE Save a figure to PNG robustly (MATLAB Online safe).
%   method = saveFigure(fig, file)
%   method = saveFigure(fig, file, Resolution=150)
%
%   Inputs
%     fig             - figure handle
%     file            - output path (.png)
%     opts.Resolution - dots per inch (default 150)
%   Output
%     method - "exportgraphics", "print" or "failed" (string)
%
%   MATLAB Online sometimes warns "Unable to generate graphics because of
%   system configuration or graphics resource constraint" when a figure is
%   exported before the browser has finished rendering it. This function
%   (1) forces rendering with drawnow, (2) tries exportgraphics twice,
%   (3) falls back to print, and (4) checks that the file really exists.
%   It never errors, so a failed image does not abort a long script.

arguments
    fig (1,1) matlab.ui.Figure
    file (1,1) string
    opts.Resolution (1,1) double {mustBePositive} = 150
end

if isfile(file)
    delete(file);
end
method = "failed";
for attempt = 1:2
    drawnow;
    pause(0.5 * attempt);
    try
        exportgraphics(fig, file, 'Resolution', opts.Resolution);
    catch err
        fprintf('saveFigure: exportgraphics attempt %d failed: %s\n', ...
            attempt, err.message);
    end
    if isfile(file)
        method = "exportgraphics";
        return
    end
end
try
    drawnow;
    print(fig, file, '-dpng', sprintf('-r%d', round(opts.Resolution)));
catch err
    fprintf('saveFigure: print failed: %s\n', err.message);
end
if isfile(file)
    method = "print";
else
    warning('saveFigure:failed', 'Could not save %s.', file);
end
end
