function space = designSpace(family)
%DESIGNSPACE Design variables, bounds and an example design for a family.
%   space = designSpace(family)
%
%   Input
%     family - "posts", "baffles", "zigzag" or "empty".
%   Output (struct, all lengths in units of the channel width W = 1)
%     family       - the family name
%     names        - 1xd string, variable names (order = design vector order)
%     lower, upper - 1xd double, bounds
%     isInteger    - 1xd logical, integer-valued variables
%     descriptions - 1xd string, plain-language meaning and units
%     example      - 1xd double, a feasible "generic" design of this family
%
%   Design vectors:
%     posts   [nRows, d, s, delta, postsPerRow]
%     baffles [nBaffles, l, s, theta]     (theta in degrees)
%     zigzag  [a, lambda]
%     empty   []                          (empty channel)

arguments
    family (1,1) string {mustBeDesignFamily}
end

switch family
    case "posts"
        names = ["nRows", "d", "s", "delta", "postsPerRow"];
        lower = [2, 0.1, 0.3, 0.0, 1];
        upper = [12, 0.5, 1.5, 0.5, 3];
        isInteger = [true, false, false, false, true];
        descriptions = ["number of post rows along the channel", ...
            "post diameter", "row pitch along x", ...
            "stagger: y-offset between neighbouring rows, fraction of in-row pitch (1+d)/(m+1)", ...
            "posts per row m, placed with equal gaps to each other and the walls"];
        example = [6, 0.3, 1.0, 0.3, 1];
    case "baffles"
        names = ["nBaffles", "l", "s", "theta"];
        lower = [2, 0.2, 0.3, -45];
        upper = [12, 0.8, 1.5, 45];
        isInteger = [true, false, false, false];
        descriptions = ["number of baffles (alternating walls)", ...
            "baffle length (fraction of width)", "baffle spacing along x", ...
            "tilt from wall normal [deg], positive leans downstream"];
        example = [6, 0.5, 1.0, 20];
    case "zigzag"
        names = ["a", "lambda"];
        lower = [0.0, 0.5];
        upper = [0.3, 3.0];
        isInteger = [false, false];
        descriptions = ["peak-to-peak centreline displacement of the wavy walls", ...
            "zigzag wavelength"];
        example = [0.2, 1.5];
    case "empty"
        names = strings(1, 0);
        lower = zeros(1, 0);
        upper = zeros(1, 0);
        isInteger = false(1, 0);
        descriptions = strings(1, 0);
        example = zeros(1, 0);
    otherwise
        error('designSpace:family', 'Unknown family "%s".', family);
end

space.family = family;
space.names = names;
space.lower = lower;
space.upper = upper;
space.isInteger = isInteger;
space.descriptions = descriptions;
space.example = example;
end
