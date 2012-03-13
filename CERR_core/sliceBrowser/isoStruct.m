function p = isoStruct(structNum)
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

global planC
global stateS
indexS = planC{end};

maskM = getUniformStr(structNum);

[r,c,s] = find3d(maskM);

minR = min(r);
maxR = max(r);

minC = min(c);
maxC = max(c);

minS = min(s);
maxS = max(s);

[xV, yV, zV] = getUniformScanXYZVals(planC{3}(getStructureAssociatedScan(structNum)));

xV = xV(minC:maxC);
yV = yV(minR:maxR);
zV = zV(minS:maxS);

maskM = maskM(minR:maxR, minC:maxC, minS:maxS);

blah = isosurface(xV, yV, zV, maskM, .5);
p = patch(blah);

% colors = stateS.optS.colorOrder;
% color = getColor(structNum, colors, 'loop');
color = planC{indexS.structures}(structNum).structureColor;

set(p, 'FaceColor', color, 'EdgeColor', 'none', 'facealpha', .5, 'hittest', 'off');
camlight; lighting phong; set(gcf, 'renderer', 'opengl');


% blah = planC{indexS.structurePatch}{structNum};
% if isempty(blah)
%     p = [];
%     return;
% end
% p = patch(blah);
% % reducepatch(p, .1);
% 
% colors = stateS.optS.colorOrder;
% color = getColor(structNum, colors, 'loop');
% 
% set(p, 'FaceColor', color, 'EdgeColor', 'none', 'facealpha', .5, 'hittest', 'off');
% camlight; lighting phong; set(gcf, 'renderer', 'opengl');

