function [isFeasible, constraint] = checkFeasibilityBatch(family, X, params)
%CHECKFEASIBILITYBATCH Feasibility of many designs (one per row of X).
%   [isFeasible, constraint] = checkFeasibilityBatch(family, X, params)
%
%   Inputs
%     family - "posts", "baffles", "zigzag" or "empty"
%     X      - n x d matrix, one design vector per row
%     params - struct from defaultParams
%   Outputs
%     isFeasible - n x 1 logical
%     constraint - n x 1 double, <= 0 iff feasible (see checkFeasibility)
%
%   This is the core of the bayesopt XConstraintFcn (Step 6 wraps it to
%   accept a table) and can be used directly for Latin-hypercube filtering.

arguments
    family (1,1) string {mustBeDesignFamily}
    X double
    params (1,1) struct
end

n = size(X, 1);
isFeasible = false(n, 1);
constraint = zeros(n, 1);
for k = 1:n
    [isFeasible(k), info] = checkFeasibility(family, X(k, :), params);
    constraint(k) = info.constraint;
end
end
