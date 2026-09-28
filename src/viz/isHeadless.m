function tf = isHeadless()
%ISHEADLESS True if figures must be written without the graphics system.
%   tf = isHeadless()
%
%   Output
%     tf - logical. Read from the persistent MATLAB preference
%          'micromixer'/'headless' (default false). Preferences are stored in
%          prefdir, so in MATLAB Online the setting survives new sessions.
%
%   Switch on/off with:
%     setpref('micromixer', 'headless', true)    % write PNG/GIF via imwrite
%     setpref('micromixer', 'headless', false)   % normal figures
%   In headless mode, field-type pictures (masks, concentration) are drawn
%   pixel by pixel into RGB arrays and saved with imwrite, which needs no
%   rendering. Use this when the browser cannot render MATLAB Online figures.

tf = ispref('micromixer', 'headless') && logical(getpref('micromixer', 'headless'));
end
