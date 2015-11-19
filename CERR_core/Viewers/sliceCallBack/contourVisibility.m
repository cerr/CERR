function contourVisibility()
%Make contours whose visible flag is off hidden.
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

global planC stateS

indexS = planC{end};

for i=1:length(planC{indexS.structures})
    if ~isfield(planC{indexS.structures}, 'visible') || isempty(planC{indexS.structures}(i).visible)
        planC{indexS.structures}(i).visible = 1;
    end
end
vis = [planC{indexS.structures}.visible];

sGv = [];
for i = uint8(1:length(stateS.handle.CERRAxis))
    sG = getAxisInfo(i,'structureGroup');
    sGv = [sGv; sG.handles];
end

contours = findobj(sGv,'tag', 'structContour');

ud = get(contours, 'userdata');
if iscell(ud)
    ud = [ud{:}];
end
structNum = [ud.structNum];
tf = ismember(structNum, find(vis));
set(contours(~tf), 'visible', 'off');
set(contours(tf), 'visible', 'on');

if stateS.optS.structureDots
    contourDots = findobj(sGv,'tag', 'structContourDots');
    udCD = get(contourDots, 'userdata');
    udCD = [udCD{:}];
    structNumCD = udCD;
    tf = ismember(structNumCD, find(vis));
    set(contourDots(~tf), 'visible', 'off');
    set(contourDots(tf), 'visible', 'on');
end
return;
