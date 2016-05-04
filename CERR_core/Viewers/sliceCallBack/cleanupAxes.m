function cleanupAxes(hAxisV, axIndV)
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
    %aI = get(hAxisV(i), 'userdata');
    if exist('axIndV','var')
        axInd = axIndV(i);
    else
        axInd = stateS.handle.CERRAxis == hAxisV(i);
    end
    aI = stateS.handle.aI(axInd);
    view = aI.view;
    %view = getAxisInfo(hAxisV(i), 'view');
    
    if ~strcmpi(view, 'Legend')
        scanHandles     = [aI.scanObj.handles];
        doseHandles     = [aI.doseObj.handles];
        %structHandles   = vertcat(aI.structureGroup.handles);
        structHandles = [];
        miscHandles     = aI.miscHandles;
        planeLocHandles = [stateS.handle.CERRAxisPlnLoc{:}, stateS.handle.CERRAxisPlnLocSdw{:}];
        linePoolHandlesV = [aI.lineHandlePool.lineV aI.lineHandlePool.dotsV];
        
        allHandles = [reshape(scanHandles, 1, []) reshape(doseHandles, 1, [])...
            reshape(structHandles, 1, []) reshape(miscHandles, 1, []), planeLocHandles, linePoolHandlesV];
        
        % Do not clean-up ruler, doseQueryPt, scanQueryPt,
        % doseCTProfileLine, beamLine
        %allHandles = [allHandles findobj('tag', 'rulerLine','-or','tag','doseQueryPoint','-or','tag','scanQueryPoint','-or','tag', 'profileLine','-or','tag', 'scale','-or','tag','beamLine')'];
        allHandles = [allHandles stateS.handle.rulerLine',stateS.handle.doseQueryPoint',...
            stateS.handle.scanQueryPoint', stateS.handle.profileLine',...
            stateS.handle.beamLine',stateS.handle.CERRAxisLabel1,stateS.handle.CERRAxisLabel2,...
            stateS.handle.CERRAxisLabel3,stateS.handle.CERRAxisLabel4, stateS.handle.CERRAxisScale1,...
            stateS.handle.CERRAxisScale2, stateS.handle.CERRAxisTicks1(:)', stateS.handle.CERRAxisTicks2(:)'];
        toRemove = [];
        
        if isfield(stateS.optS,'blockmatch') && (stateS.optS.blockmatch == 1)
            allHandles = [allHandles, reshape(findobj('tag', 'blockmatchLine'), 1, [])];
            %toRemove = setdiff(kids, [allHandles reshape(findobj('tag', 'blockmatchLine'), 1, [])]);
        end
        if isfield(stateS.optS,'mirrscope') && (stateS.optS.mirrscope == 1)
            allHandles = [allHandles, reshape(findobj('tag', 'MirrorScope'), 1, [])];
            %toRemove = setdiff(kids, [allHandles reshape(findobj('tag', 'MirrorScope'), 1, [])]);
        end
        
        kids = get(hAxisV(i), 'children');
        
        if length(kids) > length(allHandles)
            toRemove = setdiff(kids,allHandles);
        end
        
        handlV = ishandle(toRemove);
        delete(toRemove(handlV));
        
    end
end
