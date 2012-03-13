function [hTrans, hCor, hSag] = drawXYZPlanes(hAxis, xLim, yLim, zLim)
%"drawXYZPlanes"
%   Draws planes in hAxis that span the x,y,z space defined by xLim, yLim,
%   zLim, and returns their handles for further use.
%
%JRA 6/29/05
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
%
%Usage:
%   [hTrans, hCor, hSag] = drawXYZPlanes(hAxis, xLim, yLim, zLim)

set(hAxis, 'nextplot', 'add');

[xM, yM, zM] = meshgrid(xLim, yLim, 1);
hTrans = surface(xM, yM, zM);
set(hTrans, 'Tag', '3D_Trans_Slice');

[xM, yM, zM] = meshgrid(xLim, 1, zLim);
hCor = surf('xData', reshape(xM, [2 2]), 'yData', reshape(yM, [2 2]), 'zData', reshape(zM, [2 2]), 'cData', [1 1; 1 1]);
set(hCor, 'Tag', '3D_Cor_Slice');

[xM, yM, zM] = meshgrid(1, yLim, zLim);
hSag = surf('xData', reshape(xM, [2 2]), 'yData', reshape(yM, [2 2]), 'zData', reshape(zM, [2 2]), 'cData', [1 1; 1 1]);
set(hSag, 'Tag', '3D_Sag_Slice');
