function mustBeDesignFamily(family)
%MUSTBEDESIGNFAMILY Argument validator: family must be a known design family.
%   Valid families: "posts", "baffles", "zigzag", "empty" (no obstacles).
%   Use in arguments blocks:  family (1,1) string {mustBeDesignFamily}

valid = ["posts", "baffles", "zigzag", "empty"];
if ~any(string(family) == valid)
    error('micromixer:unknownFamily', ...
        'Unknown design family "%s". Valid families: %s.', ...
        string(family), strjoin(valid, ', '));
end
end
