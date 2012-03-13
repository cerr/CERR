function cleanupAxes(hAxisV)
%"cleanupAxes"
%   Examine userinfo handles and remove children that do not exist.
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

global stateS

for i=1:length(hAxisV)
    aI = get(hAxisV(i), 'userdata');
    view = getAxisInfo(hAxisV(i), 'view');
    if ~strcmpi(view, 'Legend')
        scanHandles = [aI.scanObj.handles];
        doseHandles = [aI.doseObj.handles];
        structHandles = vertcat(aI.structureGroup.handles);
        miscHandles = aI.miscHandles;

        allHandles = [reshape(scanHandles, 1, []) reshape(doseHandles, 1, []) reshape(structHandles, 1, []) reshape(miscHandles, 1, [])];
        kids = get(hAxisV(i), 'children');

        % Do not clean-up ruler, doseQueryPt, scanQueryPt, doseCTProfileLine
        allHandles = [allHandles findobj('tag', 'rulerLine','-or','tag','doseQueryPoint','-or','tag','scanQueryPoint','-or','tag', 'profileLine','-or','tag', 'scale','-or','tag','beamLine')'];        
        toRemove = setdiff(kids,allHandles);
        
        %wy
        try
            if (stateS.optS.blockmatch == 1)
                toRemove = setdiff(kids, [allHandles reshape(findobj('tag', 'blockmatchLine'), 1, [])]);
            end
            if (stateS.optS.mirrscope == 1)
                toRemove = setdiff(kids, [allHandles reshape(findobj('tag', 'MirrorScope'), 1, [])]);
            end
        end;
        %wy
        

        for j=1:length(toRemove)
            try
                delete(toRemove);
            end
        end
    end
end
