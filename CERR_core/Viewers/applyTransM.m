function [varargout] = applyTransM(varargin)
%"applyTransM"
%   Apply transformation matrix transM to points defined in xyz by xV, yV,
%   zV.  In order to run as fast as possible, first computes the rotation
%   component and then adds the translation portion of transM last.
%
%JRA 1/18/04
%
%Usage:
%   function [xT, yT, zT] = applyTransM(transM, xV, yV, zV);
%   function [pointsT]    = applyTransM(transM, pointsM);
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

%Parse input arguments.
if nargin == 2
    usingPointMatrix = 1;
    transM  = varargin{1};
    pointsM = varargin{2}';    
elseif nargin == 4
    usingPointMatrix = 0;
    transM  = varargin{1};
    xV      = varargin{2};
    yV      = varargin{3};
    zV      = varargin{4};    
    
    if length(xV) ~= length(yV) | length(xV) ~= length(zV)
        error('xV, yV, and zV must be vectors of the same length.');
    end    
    
    pointsM = [reshape(xV,[],1), reshape(yV,[],1) reshape(zV,[],1)]';    
    
else
    error('Invalid number of input arguments to applyTransM.');    
end

%If blank transformation matrix, return originals.
if isempty(transM)
    if usingPointMatrix
        varargout{1} = pointsM;
    else
        varargout{1} = xV;
        varargout{2} = yV;
        varargout{3} = zV;
    end
    return;
end

nPts = size(pointsM, 2);
%If no points passed in, return empty.
if nPts == 0
    if usingPointMatrix
        varargout{1} = [];
    else
        varargout{1} = [];
        varargout{2} = [];
        varargout{3} = [];
    end
    return;
end

%Split the rotation and translation portions of transM.  This is done for
%speed, to avoid allocating a 4th column of ones to pointsM.

%Rotation.
pointsM = transM(1:3,1:3) * pointsM;

%Translation.
pointsM(1,:) = pointsM(1,:) + transM(1,4);
pointsM(2,:) = pointsM(2,:) + transM(2,4);
pointsM(3,:) = pointsM(3,:) + transM(3,4);

if usingPointMatrix
    varargout{1} = pointsM';
else
    varargout{1} = pointsM(1,:);
    varargout{2} = pointsM(2,:);
    varargout{3} = pointsM(3,:);
end