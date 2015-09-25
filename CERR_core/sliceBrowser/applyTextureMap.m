function applyTextureMap(hSurf, texture, coord);
%"applyTextureMap"
%   Apply the passed 2D image to hSurf as a texture map, and shift the
%   location of hSurf to coordinate coord, based on the Tag of the surface.
%   Trans slices have their Z values set to coord, Cor slices have their y
%   values set to coord and Sag slices have their x values set to coord.
%
%JRA 06/29/05
%
%Usage:
%   applyTextureMap(hSurf, texture, coord);
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

surfaceTag = get(hSurf, 'Tag');
onesM = ones(2);

switch surfaceTag;
    case '3D_Trans_Slice'
        set(hSurf, 'zData', onesM*coord);
        set(hSurf, 'FaceColor', 'texture', 'cData', texture, 'ambientstrength', 1);
    case '3D_Cor_Slice'
        set(hSurf, 'yData', onesM*coord);        
        set(hSurf, 'FaceColor', 'texture', 'cData', texture, 'ambientstrength', 1);        
    case '3D_Sag_Slice'        
        set(hSurf, 'xData', onesM*coord);        
        set(hSurf, 'FaceColor', 'texture', 'cData', texture, 'ambientstrength', 1);        
end

hAxis = get(hSurf, 'parent');
hTrans = findobj(hAxis, 'Tag', '3D_Trans_Slice');
hSag = findobj(hAxis, 'Tag', '3D_Sag_Slice');
hCor = findobj(hAxis, 'Tag', '3D_Cor_Slice');

xLim = get(hTrans, 'xData');
yLim = get(hTrans, 'yData');
zLim = get(hSag, 'zData');

x   = get(hSag, 'xData');
y   = get(hCor, 'yData');
z   = get(hTrans, 'zData');


delete(findobj(hAxis, 'Tag', '3D_Divider_Line'));
line(xLim(1,:), y(1,:), z(1,:), 'color', [0 0 0], 'Tag', '3D_Divider_Line', 'parent', hAxis);
line(x(1,:), yLim(:,1), z(1,:), 'color', [0 0 0], 'Tag', '3D_Divider_Line', 'parent', hAxis);
line(x(1,:), y(1,:), zLim(1,:), 'color', [0 0 0], 'Tag', '3D_Divider_Line', 'parent', hAxis);

kids = get(hAxis, 'children');
set(kids, 'clipping', 'off');