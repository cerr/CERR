function varargout = findnearest(vecV, value)
%"findnearest"
%   Returns the index of the value in vecV numerically closest to value.
%
%   If two output arguments are requested, returns both the index of the
%   nearest element above and below the passed value.  If value exactly
%   matches an element in vecV,  or if there is no higher or lower element, 
%   both indHigh and indLow take that index.
%
%   If in any situation two values in vecV match for the min or max value,
%   the first index is returned.
%
%JRA 11/17/04
%
%Usage:
%   function ind = findnearest(vecV, value)
%   function [indLow, indHigh] = findnearest(vecV, value)
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.

if nargout == 1;
    diffV = vecV - value;
    [minVal, varargout{1}] = min(abs(diffV));
elseif nargout == 2
    diffV = vecV - value;
    posV = diffV >= 0;    
    negV = diffV <= 0;
    [minVal, indMin] = min(diffV(posV));
    [maxVal, indMax] = max(diffV(negV));    
    findPosV = find(posV);
    findNegV = find(negV);    
    varargout{1} = findNegV(indMax);
    varargout{2} = findPosV(indMin);        
    if isempty(varargout{1})
        varargout{1} = varargout{2};
    elseif isempty(varargout{2})
        varargout{2} = varargout{1};        
    end
end
    