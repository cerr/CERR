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


global stateS
global planC
indexS = planC{end};

xVals = {}; yVals = {}; zVals = {};
for i=1:length(stateS.handle.CERRAxis)
    hAxis       = stateS.handle.CERRAxis(i);
    [view, coord] = getAxisInfo(hAxis, 'view', 'coord');

    switch lower(view)
        case 'transverse'
            zVals{i} = coord;
        case 'sagittal'
            xVals{i} = coord;
        case 'coronal'
            yVals{i} = coord;
    end
end

for i=1:length(stateS.handle.CERRAxis)
    hAxis = stateS.handle.CERRAxis(i);
    [view, coord] = getAxisInfo(hAxis, 'view', 'coord');

    horizLimit = get(hAxis, 'xLim');
    vertiLimit = get(hAxis, 'yLim');

    hOld = findobj(hAxis, 'tag', 'planeLocator');
    delete(hOld);

    hOldShadow = findobj(hAxis, 'tag', 'planeLocatorShadow');
    delete(hOldShadow);

    %Remove old plane locator handles from axis miscHandles.
    oldMiscHandles = getAxisInfo(hAxis, 'miscHandles');
    setAxisInfo(hAxis, 'miscHandles', setdiff(oldMiscHandles, [hOld;hOldShadow]));

    %Draw plane locators.  For each locator draw 2 lines: first a thick
    %black line and then a thinner white line on top of it.  This is so
    %that the locator is visible regardless of the background color it
    %is being displayed on.

    if stateS.showPlaneLocators

        switch lower(view)
            case 'transverse'
                for j=1:length(xVals)
                    if ~isempty(xVals{j}) & isequal(planeLocatorLastCall, thisCallTime)
                        line([xVals{j} xVals{j}], vertiLimit, [2 2], 'parent', hAxis, 'color', [0 0 0], 'tag', 'planeLocatorShadow', 'userdata', {'vert', 'trans', j}, 'hittest', 'off', 'erasemode', 'xor', 'linewidth', 2);
                        line([xVals{j} xVals{j}], vertiLimit, [2 2], 'parent', hAxis, 'color', [1 1 1], 'tag', 'planeLocator', 'buttondownfcn', 'sliceCallBack(''locatorClicked'')', 'userdata', {'vert', 'trans', j}, 'hittest', 'on', 'erasemode', 'xor');
                    end
                end
                for j=1:length(yVals)
                    if ~isempty(yVals{j}) & isequal(planeLocatorLastCall, thisCallTime)
                        line(horizLimit, [yVals{j} yVals{j}], [2 2], 'parent', hAxis, 'color', [0 0 0], 'tag', 'planeLocatorShadow', 'userdata', {'horz', 'trans', j}, 'hittest', 'off', 'erasemode', 'xor', 'linewidth', 2);
                        line(horizLimit, [yVals{j} yVals{j}], [2 2], 'parent', hAxis, 'color', [1 1 1], 'tag', 'planeLocator', 'buttondownfcn', 'sliceCallBack(''locatorClicked'')', 'userdata', {'horz', 'trans', j}, 'hittest', 'on', 'erasemode', 'xor');
                    end
                end

            case 'sagittal'
                for j=1:length(yVals)
                    if ~isempty(yVals{j}) & isequal(planeLocatorLastCall, thisCallTime)
                        line([yVals{j} yVals{j}], vertiLimit, [2 2], 'parent', hAxis, 'color', [0 0 0], 'tag', 'planeLocatorShadow', 'userdata', {'vert', 'sag', j}, 'hittest', 'off', 'erasemode', 'xor', 'linewidth', 2);
                        line([yVals{j} yVals{j}], vertiLimit, [2 2], 'parent', hAxis, 'color', [1 1 1], 'tag', 'planeLocator', 'buttondownfcn', 'sliceCallBack(''locatorClicked'')', 'userdata', {'vert', 'sag', j}, 'hittest', 'on', 'erasemode', 'xor');
                    end
                end
                for j=1:length(zVals)
                    if ~isempty(zVals{j}) & isequal(planeLocatorLastCall, thisCallTime)
                        line(horizLimit, [zVals{j} zVals{j}], [2 2], 'parent', hAxis, 'color', [0 0 0], 'tag', 'planeLocatorShadow', 'userdata', {'horz', 'sag', j}, 'hittest', 'off', 'erasemode', 'xor', 'linewidth', 2);
                        line(horizLimit, [zVals{j} zVals{j}], [2 2], 'parent', hAxis, 'color', [1 1 1], 'tag', 'planeLocator', 'buttondownfcn', 'sliceCallBack(''locatorClicked'')', 'userdata', {'horz', 'sag', j}, 'hittest', 'on', 'erasemode', 'xor');
                    end
                end

            case 'coronal'
                for j=1:length(xVals)
                    if ~isempty(xVals{j}) & isequal(planeLocatorLastCall, thisCallTime)
                        line([xVals{j} xVals{j}], vertiLimit, [2 2],'parent', hAxis, 'color', [0 0 0], 'tag', 'planeLocatorShadow', 'userdata', {'vert', 'cor', j}, 'hittest', 'off', 'erasemode', 'xor', 'linewidth', 2);
                        line([xVals{j} xVals{j}], vertiLimit, [2 2],'parent', hAxis, 'color', [1 1 1], 'tag', 'planeLocator', 'buttondownfcn', 'sliceCallBack(''locatorClicked'')', 'userdata', {'vert', 'cor', j}, 'hittest', 'on', 'erasemode', 'xor');
                    end
                end
                for j=1:length(zVals)
                    if ~isempty(zVals{j}) & isequal(planeLocatorLastCall, thisCallTime)
                        line(horizLimit, [zVals{j} zVals{j}], [2 2], 'parent', hAxis, 'color', [0 0 0], 'tag', 'planeLocatorShadow', 'userdata', {'horz', 'cor', j}, 'hittest', 'on', 'erasemode', 'xor', 'linewidth', 2);
                        line(horizLimit, [zVals{j} zVals{j}], [2 2], 'parent', hAxis, 'color', [1 1 1], 'tag', 'planeLocator', 'buttondownfcn', 'sliceCallBack(''locatorClicked'')', 'userdata', {'horz', 'cor', j}, 'hittest', 'on', 'erasemode', 'xor');
                    end
                end
        end
    end

    hLines = findobj(hAxis, 'tag', 'planeLocator');
    hShadows = findobj(hAxis, 'tag', 'planeLocatorShadow');

    %Add new lines to the miscHandles axis field.
    setAxisInfo(hAxis, 'miscHandles', [oldMiscHandles reshape(hLines, 1, []) reshape(hShadows, 1, [])]);

end

sliceCallBack('focus', stateS.handle.CERRAxis(stateS.currentAxis));