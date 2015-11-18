function e = hystThresh(e, g, thresh, conn)
%HYSTTHRESH carries out hysteresis thresholding, as for Canny
%   E = HYSTTHRESH(E, G, THRESH) takes a raw edge map, a gradient magnitude
%   array and a threshold or pair of thresholds, and returns a new edge map
%   wherever the gradient magnitude exceeds or equals the lower threshold
%   and is connected to a position where the gradient exceeds or equals the
%   higher threshold.
% 
%       E - a logical N-D array, giving the raw edge map
% 
%       G - the underlying array of gradients (or other values); should not
%       contain negative values; same size as E
% 
%       THRESH - a vector of the form [LOW HIGH] giving the lower and
%       higher thresholding values. If thresh is a scalar, simple
%       thresholding is carried out. Should contain positive values, with
%       HIGH > LOW.
% 
%   E = HYSTTHRESH(E, G, THRESH, CONN) allows the connectivity to be set.
% 
%       CONN - an integer giving the neighbourhood size to establish
%       connected regions. The default (if empty or omitted) is as for
%       IMRECONSTRUCT.
% 
% See also: canny, imreconstruct

ge = g .* e;

e = ge > thresh(1);     % simple thresholding, or lower bound

if ~isscalar(thresh)
    e2 = ge > thresh(2);
    if nargin < 4 || isempty(conn)
        e = imreconstruct(e2, e);
    else
        e = imreconstruct(e2, e, conn);
    end
end

end