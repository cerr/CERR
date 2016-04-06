function showPlaneLocators()
%Show locators planes in all CERR axes.
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

global planeLocatorLastCall

thisCallTime = now;

if isempty(planeLocatorLastCall)
    planeLocatorLastCall = thisCallTime;
else
    if thisCallTime > planeLocatorLastCall
        planeLocatorLastCall = thisCallTime;
    end
end


global stateS planC

set([stateS.handle.CERRAxisPlnLoc{:}],'visible','off')
set([stateS.handle.CERRAxisPlnLocSdw{:}],'visible','off')
if ~isfield(stateS,'showPlaneLocators') || ~stateS.showPlaneLocators
    return;
end

xAxVals = {}; yAxVals = {}; zAxVals = {};
for i=uint8(1:length(stateS.handle.CERRAxis))
    hAxis       = stateS.handle.CERRAxis(i);
    [view, coord] = getAxisInfo(i, 'view', 'coord');

    switch lower(view)
        case 'transverse'
            zAxVals{i} = coord;
        case 'sagittal'
            xAxVals{i} = coord;
        case 'coronal'
            yAxVals{i} = coord;
    end
end

if stateS.MLVersion < 8.4
    inActiveCol = [0.9 0.9 0.5];
    activeCol = [0.5 1 0.5];
else
    inActiveCol = [0.9 0.9 0.5];
    activeCol = [0.5 1 0.5];
end

for i=uint8(1:length(stateS.handle.CERRAxis))
    
    % Plane Locator count
    count = 0;
    
    hAxis = stateS.handle.CERRAxis(i);
    [view, coord] = getAxisInfo(i, 'view', 'coord');

    horizLimit = get(hAxis, 'xLim');
    vertiLimit = get(hAxis, 'yLim');
    
    switch lower(view)
        case 'transverse'
            xVals = xAxVals;
            yVals = yAxVals;
            viewTxt = 'trans';
            
        case 'sagittal'
            xVals = yAxVals;
            yVals = zAxVals;
            viewTxt = 'sag';
            
        case 'coronal'
            xVals = xAxVals;
            yVals = zAxVals;
            viewTxt = 'cor';
            
        case 'legend'
            continue;
    end
    
    
    for j=1:length(xVals)
        if ~isempty(xVals{j}) && isequal(planeLocatorLastCall, thisCallTime)
            count = count + 1;
            set(stateS.handle.CERRAxisPlnLocSdw{i}(count),'XData',[xVals{j} xVals{j}],...
                'YData', vertiLimit,'visible','on', 'LineWidth', 1);
            if stateS.currentAxis == j
                set(stateS.handle.CERRAxisPlnLoc{i}(count),'XData',[xVals{j} xVals{j}],...
                    'YData', vertiLimit, 'Color', activeCol, 'userdata',...
                    {'vert', viewTxt, j},'visible','on', 'LineWidth', 1);
            else
                set(stateS.handle.CERRAxisPlnLoc{i}(count),'XData',[xVals{j} xVals{j}],...
                    'YData', vertiLimit, 'Color', inActiveCol, 'userdata',...
                    {'vert', viewTxt, j},'visible','on', 'LineWidth', 1);
            end
        end
    end
    for j=1:length(yVals)
        if ~isempty(yVals{j}) && isequal(planeLocatorLastCall, thisCallTime)
            count = count + 1;
            set(stateS.handle.CERRAxisPlnLocSdw{i}(count),'XData',horizLimit,...
                'YData', [yVals{j} yVals{j}],'visible','on', 'LineWidth', 1);            
            if stateS.currentAxis == j
                set(stateS.handle.CERRAxisPlnLoc{i}(count),'XData',horizLimit,...
                    'YData', [yVals{j} yVals{j}], 'Color', activeCol, 'userdata',...
                    {'horz', viewTxt, j},'visible','on', 'LineWidth', 1);
            else
                set(stateS.handle.CERRAxisPlnLoc{i}(count),'XData',horizLimit,...
                    'YData', [yVals{j} yVals{j}], 'Color', inActiveCol, 'userdata',...
                    {'horz', viewTxt, j},'visible','on', 'LineWidth', 1);
            end
        end
    end
    
    numPlanLocs = length(stateS.handle.CERRAxisPlnLoc{i});
    set(stateS.handle.CERRAxisPlnLocSdw{i}(count+1:numPlanLocs),'visible','off')
    set(stateS.handle.CERRAxisPlnLoc{i}(count+1:numPlanLocs),'visible','off')    
    %setAxisInfo(hAxis, 'planeLocHandles', planeLocHandlesV)
    
    %hLines = findobj(hAxis, 'tag', 'planeLocator');
    %hShadows = findobj(hAxis, 'tag', 'planeLocatorShadow');

    %Add new lines to the miscHandles axis field.
    %setAxisInfo(hAxis, 'miscHandles', [oldMiscHandles reshape(hLines, 1, []) reshape(hShadows, 1, [])]);

end

%sliceCallBack('focus', stateS.handle.CERRAxis(stateS.currentAxis));