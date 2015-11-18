function t = fractile(x, f)
%FRACTILE finds fractiles of a distribution
%   T = FRACTILE(X, F) finds a value T for which a fraction F of the
%   elements of X are less than T. A fractile is like a centile, except
%   that the argument is a fraction rather then a percentage.
% 
%   Linear interpolation is used between data points. The minimum and
%   maximum values in X are returned for F=0 and F=1 respectively. F may be
%   a matrix; the result is the corresponding matrix of fractiles.

% Note on the algorithm:
% Forming a histogram seems to take as long as SORT, but sort is much
% simpler, since histogramming always needs to be used recursively to work
% with uneven distributions. However, for very large amounts of data it may
% be worthwhile to look at providing a recursive histogram method.

validateattributes(x, {'numeric'}, {});
validateattributes(f, {'numeric'}, {'>=' 0 '<=' 1});

x = sort(x(:));
n = numel(x);
fn = n * f(:);      % the ideal index into sorted g

i = floor(fn + 0.5);        % index of value just less than f

ga = x(max(i, 1));
gb = x(min(i+1, n));

r = fn + 0.5 - i;
t = (1-r) .* ga + r .* gb;    % interpolate

t = reshape(t, size(f));

end