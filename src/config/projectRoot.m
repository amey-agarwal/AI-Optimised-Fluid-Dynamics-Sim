function root = projectRoot()
%PROJECTROOT Absolute path of the micromixer-opt project folder.
%   root = projectRoot() returns the folder that contains startup.m, found
%   from the location of this file (src/config/projectRoot.m), so it works
%   regardless of the current working directory.
%
%   Output
%     root - char vector, absolute path of the project root.

root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
end
