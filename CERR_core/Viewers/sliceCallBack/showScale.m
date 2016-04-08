function showScale(hAxis, i)
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
global planC

% check for comparemode if selected
compareMode = getappdata(hAxis,'compareMode');

pos = get(hAxis, 'position');
wid = pos(3); hgt = pos(4);

[scanSet, doseSet, viewType, coord] = getAxisInfo(uint8(i), 'scanSets', 'doseSets', 'view', 'coord');

scanText = ['S: ' sprintf('%d',scanSet)];
doseText = ['D: ' sprintf('%d',doseSet)];

if isempty(coord);
    set(stateS.handle.CERRAxisLabel1(i), 'string', '', 'visible', 'on', 'color', [0 0 0], 'hittest', 'off');
    set(stateS.handle.CERRAxisLabel2(i), 'string', '', 'visible', 'on', 'color', [0 0 0], 'hittest', 'off');
    return;
end

if ~isempty(scanSet)
    indexS = planC{end};
    [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(scanSet(1)));
else
    %warning('No Scan Selected')
    return
end

if stateS.currentAxis == i;
    color = [0.5 1 0.5];
else
    color = [0.9 0.9 0.5];
end
if stateS.contourAxis == i
    color = [1 0 0];
end
%try
    transM = getTransM('scan', scanSet(1), planC);
%catch
    %transM = [];
%end
if ~isempty(transM) || isequal(transM,eye(4))
    [nCoordX nCoordY nCoordZ] = applyTransM(inv(transM),coord,coord,coord);

else
    nCoordX = coord;
    nCoordY = coord;
    nCoordZ = coord;
end


switch viewType
    case 'transverse'
        viewTxt        = 'Tra: '; dim1 = 'z: '; dim2 = '\Deltax:'; dim3 = '\Deltay:';
        if isempty(zV)
            numSlices = []; zVal = [];
        else
            sliceNum    = findnearest(zV, nCoordZ);
            numSlices   = sprintf('%d',size(getScanArray(planC{indexS.scan}(scanSet(1))), 3));
            %xLim        = get(hAxis, 'xLim');
            %deltaX      = num2str(xLim(2) - xLim(1), '%0.4g');
            %yLim        = get(hAxis, 'yLim');
            %deltaY      = num2str(yLim(2) - yLim(1), '%0.4g');
            zVal        = sprintf('%.2f',coord);
            stateS.transverse.ZCoord = str2double(zVal);
%             %Show 5cm bar to display zoom-level
%             len = 5; %cm
%             dx = xLim(2)-xLim(1);
%             xStart = xLim(1) + dx * 0.05;
%             xEnd = xStart + len;
%             dy = yLim(2)-yLim(1);
%             yStart = yLim(1) + dy * 0.05;
%             yEnd = yStart + len;
%             %Delete previous handles
% %             hScale = findobj(hAxis,'tag','scale');
% %             delete(hScale)
% %             line([xStart xEnd], [yStart yStart], [2 2], 'parent', hAxis, 'color', 'y', 'tag', 'scale', 'hittest', 'off');
% %             line([xStart xStart], [yStart yEnd], [2 2], 'parent', hAxis, 'color', 'y', 'tag', 'scale', 'hittest', 'off');
%             xAll = linspace(xStart,xEnd,6);
%             yAll = linspace(yStart,yEnd,6);
% %             if wid/dx < 6 || hgt/dy < 6
% %                 line([xAll(6) xAll(6)], [yStart-dy*0.005 yStart+dy*0.005], [2 2], 'parent', hAxis, 'color', 'y', 'tag', 'scale', 'hittest', 'off');
% %                 line([xStart-dx*0.005 xStart+dx*0.005], [yAll(6) yAll(6)], [2 2], 'parent', hAxis, 'color', 'y', 'tag', 'scale', 'hittest', 'off');
% %                 text('parent', hAxis, 'string', '5', 'position', [xAll(6) yStart-dy*0.02 0], 'color', 'y', 'units', 'data', 'visible', 'on','fontSize',8, 'tag', 'scale');
% %                 text('parent', hAxis, 'string', '5', 'position', [xStart-dx*0.02 yAll(6) 0], 'color', 'y', 'units', 'data', 'visible', 'on','fontSize',8, 'tag', 'scale');
% %             else
% %                 for iS = 2:length(xAll)
% %                     line([xAll(iS) xAll(iS)], [yStart-dy*0.005 yStart+dy*0.005], [2 2], 'parent', hAxis, 'color', 'y', 'tag', 'scale', 'hittest', 'off');
% %                     line([xStart-dx*0.005 xStart+dx*0.005], [yAll(iS) yAll(iS)], [2 2], 'parent', hAxis, 'color', 'y', 'tag', 'scale', 'hittest', 'off');
% %                     text('parent', hAxis, 'string', num2str(iS-1), 'position', [xAll(iS) yStart-dy*0.02 0], 'color', 'y', 'units', 'data', 'visible', 'on','fontSize',8, 'tag', 'scale');
% %                     text('parent', hAxis, 'string', num2str(iS-1), 'position', [xStart-dx*0.02 yAll(iS) 0], 'color', 'y', 'units', 'data', 'visible', 'on','fontSize',8, 'tag', 'scale');
% %                 end
% %             end
%             %text('parent', hAxis, 'string', 'cm', 'position', [xStart-dx*0.02 yStart-dy*0.02 0], 'color', 'y', 'units', 'data', 'visible', 'on','fontSize',8, 'tag', 'scale','rotation',0);
        end

    case 'sagittal'
        viewTxt        = 'Sag: ';  dim1 = 'x: '; dim2 = '\Deltay:'; dim3 = '\Deltaz:';
        if isempty(xV)
            numSlices = []; zVal = [];
        else
            sliceNum    = findnearest(xV, nCoordX);
            numSlices   = sprintf('%d',size(getScanArray(planC{indexS.scan}(scanSet(1))), 1));
            %xLim        = get(hAxis, 'xLim');
            %deltaX      = num2str(xLim(2) - xLim(1), '%0.4g');
            %yLim        = get(hAxis, 'yLim');
            %deltaY      = num2str(yLim(2) - yLim(1), '%0.4g');
            zVal        = sprintf('%.2f',coord);
            stateS.sagittal.ZCoord = str2double(zVal);
%             %Show 5cm bar to display zoom-level
%             len = 5; %cm
%             dx = xLim(2)-xLim(1);
%             xStart = xLim(2) - dx * 0.05;
%             xEnd = xStart - len;
%             dy = yLim(2)-yLim(1);
%             yStart = yLim(2) - dy * 0.05;
%             yEnd = yStart - len;
%             %Delete previous handles
% %             hScale = findobj(hAxis,'tag','scale');
% %             delete(hScale)
% %             line([xStart xEnd], [yStart yStart], [2 2], 'parent', hAxis, 'color', 'y', 'tag', 'scale', 'hittest', 'off');
% %             line([xStart xStart], [yStart yEnd], [2 2], 'parent', hAxis, 'color', 'y', 'tag', 'scale', 'hittest', 'off');         
%             xAll = linspace(xStart,xEnd,6);
%             yAll = linspace(yStart,yEnd,6);
% %             if wid/dx < 6 || hgt/dy < 6
% %                 line([xAll(6) xAll(6)], [yStart-dy*0.005 yStart+dy*0.005], [2 2], 'parent', hAxis, 'color', 'y', 'tag', 'scale', 'hittest', 'off');
% %                 line([xStart-dx*0.005 xStart+dx*0.005], [yAll(6) yAll(6)], [2 2], 'parent', hAxis, 'color', 'y', 'tag', 'scale', 'hittest', 'off');
% %                 text('parent', hAxis, 'string', '5', 'position', [xAll(6) yStart+dy*0.02 0], 'color', 'y', 'units', 'data', 'visible', 'on','fontSize',8, 'tag', 'scale');
% %                 text('parent', hAxis, 'string', '5', 'position', [xStart+dx*0.02 yAll(6) 0], 'color', 'y', 'units', 'data', 'visible', 'on','fontSize',8, 'tag', 'scale');
% %             else
% %                 for iS = 2:length(xAll)
% %                     line([xAll(iS) xAll(iS)], [yStart-dy*0.005 yStart+dy*0.005], [2 2], 'parent', hAxis, 'color', 'y', 'tag', 'scale', 'hittest', 'off');
% %                     line([xStart-dx*0.005 xStart+dx*0.005], [yAll(iS) yAll(iS)], [2 2], 'parent', hAxis, 'color', 'y', 'tag', 'scale', 'hittest', 'off');
% %                     text('parent', hAxis, 'string', num2str(iS-1), 'position', [xAll(iS) yStart+dy*0.02 0], 'color', 'y', 'units', 'data', 'visible', 'on','fontSize',8, 'tag', 'scale');
% %                     text('parent', hAxis, 'string', num2str(iS-1), 'position', [xStart+dx*0.02 yAll(iS) 0], 'color', 'y', 'units', 'data', 'visible', 'on','fontSize',8, 'tag', 'scale');
% %                 end
% %             end
%             %text('parent', hAxis, 'string', 'cm', 'position', [xStart+dx*0.02 yStart+dy*0.02 0], 'color', 'y', 'units', 'data', 'visible', 'on','fontSize',8, 'tag', 'scale','rotation',0);            
        end

    case 'coronal'
        viewTxt        = 'Cor: ';  dim1 = 'y: '; dim2 = '\Deltax:'; dim3 = '\Deltaz:';
        if isempty(yV)
            numSlices = []; zVal = [];
        else
            sliceNum    = findnearest(yV, nCoordY);
            numSlices   = sprintf('%d',size(getScanArray(planC{indexS.scan}(scanSet(1))), 2));
            %xLim        = get(hAxis, 'xLim');
            %deltaX      = num2str(xLim(2) - xLim(1), '%0.4g');
            %yLim        = get(hAxis, 'yLim');
            %deltaY      = num2str(yLim(2) - yLim(1), '%0.4g');
            zVal        = sprintf('%.2f',coord);
            stateS.coronal.ZCoord = str2double(zVal);
%             %Show 5cm bar to display zoom-level
%             len = 5; %cm
%             dx = xLim(2)-xLim(1);
%             xStart = xLim(1) + dx * 0.05;
%             xEnd = xStart + len;
%             dy = yLim(2)-yLim(1);
%             yStart = yLim(2) - dy * 0.05;
%             yEnd = yStart - len;
%             %Delete previous handles
% %             hScale = findobj(hAxis,'tag','scale');
% %             delete(hScale)
% %             line([xStart xEnd], [yStart yStart], [2 2], 'parent', hAxis, 'color', 'y', 'tag', 'scale', 'hittest', 'off');
% %             line([xStart xStart], [yStart yEnd], [2 2], 'parent', hAxis, 'color', 'y', 'tag', 'scale', 'hittest', 'off');         
%             xAll = linspace(xStart,xEnd,6);
%             yAll = linspace(yStart,yEnd,6);
% %             if wid/dx < 6 || hgt/dy < 6
% %                 line([xAll(6) xAll(6)], [yStart-dy*0.005 yStart+dy*0.005], [2 2], 'parent', hAxis, 'color', 'y', 'tag', 'scale', 'hittest', 'off');
% %                 line([xStart-dx*0.005 xStart+dx*0.005], [yAll(6) yAll(6)], [2 2], 'parent', hAxis, 'color', 'y', 'tag', 'scale', 'hittest', 'off');
% %                 text('parent', hAxis, 'string', '5', 'position', [xAll(6) yStart+dy*0.02 0], 'color', 'y', 'units', 'data', 'visible', 'on','fontSize',8, 'tag', 'scale');
% %                 text('parent', hAxis, 'string', '5', 'position', [xStart-dx*0.02 yAll(6) 0], 'color', 'y', 'units', 'data', 'visible', 'on','fontSize',8, 'tag', 'scale');
% %             else
% %                 for iS = 2:length(xAll)
% %                     line([xAll(iS) xAll(iS)], [yStart-dy*0.005 yStart+dy*0.005], [2 2], 'parent', hAxis, 'color', 'y', 'tag', 'scale', 'hittest', 'off');
% %                     line([xStart-dx*0.005 xStart+dx*0.005], [yAll(iS) yAll(iS)], [2 2], 'parent', hAxis, 'color', 'y', 'tag', 'scale', 'hittest', 'off');
% %                     text('parent', hAxis, 'string', num2str(iS-1), 'position', [xAll(iS) yStart+dy*0.02 0], 'color', 'y', 'units', 'data', 'visible', 'on','fontSize',8, 'tag', 'scale');
% %                     text('parent', hAxis, 'string', num2str(iS-1), 'position', [xStart-dx*0.02 yAll(iS) 0], 'color', 'y', 'units', 'data', 'visible', 'on','fontSize',8, 'tag', 'scale');
% %                 end
% %             end
%             %text('parent', hAxis, 'string', 'cm', 'position', [xStart-dx*0.02 yStart+dy*0.02 0], 'color', 'y', 'units', 'data', 'visible', 'on','fontSize',8, 'tag', 'scale','rotation',0);            
        end

    case 'legend'
        set(stateS.handle.CERRAxisLabel1(i), 'string', 'Legend', 'visible', 'on', 'color', color, 'hittest', 'off','position',[0.02 0.98 0]);
        return;
    otherwise
        return;
end

% APA commented for RIVIEW - begin

% set(stateS.handle.CERRAxisScale1(i),'xData',[xStart xEnd], 'yData', [yStart yStart],'visible','on')
% set(stateS.handle.CERRAxisScale2(i),'xData',[xStart xStart], 'yData', [yStart yEnd],'visible','on')

% set(stateS.handle.CERRAxisLabel3(i),'position',[xEnd yStart+dy*0.02 0],'visible','on');
% set(stateS.handle.CERRAxisLabel4(i),'position',[xStart-dx*0.02 yEnd 0],'visible','on');
% for j = 1:size(stateS.handle.CERRAxisTicks1,2)
%     set(stateS.handle.CERRAxisTicks1(i,j),'xData',[xAll(j) xAll(j)], 'yData', [yStart-dy*0.0025 yStart+dy*0.0025],'visible','on')
%     set(stateS.handle.CERRAxisTicks2(i,j),'xData',[xStart-dx*0.0025 xStart+dx*0.0025], 'yData', [yAll(j) yAll(j)],'visible','on')
% end

if wid < 100 || hgt < 100
    set(stateS.handle.CERRAxisLabel1(i), 'string', [viewTxt '        ' compareMode], 'visible', 'on', 'color', color, 'hittest', 'off','position',[0.02 0.98 0]);
    set(stateS.handle.CERRAxisLabel2(i),'string','');
else
    viewTxt = [viewTxt sprintf('%d',sliceNum) '/' numSlices '          ' compareMode];
    %         set(stateS.handle.CERRAxisLabel(i), 'string', {[viewTxt num2str(sliceNum) '/' numSlices], [dim1 zVal 'cm'], [dim2 deltaX 'cm'], [dim3 deltaY 'cm']}, 'visible', 'on', 'erasemode', 'none', 'color', color, 'hittest', 'off');
    set(stateS.handle.CERRAxisLabel1(i), 'string', {viewTxt, [dim1 zVal 'cm']}, 'visible', 'on', 'color', color, 'hittest', 'off','position',[0.02 0.98 0]);
    
    set(stateS.handle.CERRAxisLabel2(i), 'string', {scanText, doseText}, 'visible', 'on', 'color', color, 'hittest', 'off');
end

% kids = get(hAxis, 'children');
% index1 = find(kids == stateS.handle.CERRAxisLabel1(i));
% kids(index1) = [];
% index2 = find(kids == stateS.handle.CERRAxisLabel2(i));
% kids(index2) = [];
% index3 = ismember(kids, findobj(hAxis,'tag', 'scale'));
% kids(index3) = [];
% set(hAxis, 'children', [findobj(hAxis,'tag', 'scale');stateS.handle.CERRAxisLabel1(i);stateS.handle.CERRAxisLabel2(i);kids]);


% %%%%%% APA commented to test whether this is needed?
% kids = get(hAxis, 'children');
% index1 = kids == stateS.handle.CERRAxisLabel1(i);
% %kids(index1) = [];
% index2 = kids == stateS.handle.CERRAxisLabel2(i);
% %kids(index2) = [];
% %scaleKids = findobj(hAxis,'tag', 'scale');
% %index3 = ismember(kids, scaleKids);
% %kids(index3) = [];
% index3 = kids == stateS.handle.CERRAxisLabel3(i);
% index4 = kids == stateS.handle.CERRAxisLabel4(i);
% index5 = kids == stateS.handle.CERRAxisScale1(i);
% index6 = kids == stateS.handle.CERRAxisScale2(i);
% % index7 = ismember(kids, stateS.handle.CERRAxisTicks1(i,:));
% % index8 = ismember(kids, stateS.handle.CERRAxisTicks2(i,:));
% index7 = zeros(length(kids),1);
% index8 = index7;
% for j = 1:size(stateS.handle.CERRAxisTicks1,2)
%     index7 = index7 | kids == stateS.handle.CERRAxisTicks1(i,j);
%     index8 = index8 | kids == stateS.handle.CERRAxisTicks2(i,j);
% end
% 
% reOrderedKids = kids;
% index = index1 | index2 | index3 | index4 | index5 | index6 | index7 | index8;
% reOrderedKids(index) = [stateS.handle.CERRAxisLabel1(i) stateS.handle.CERRAxisLabel2(i) stateS.handle.CERRAxisLabel3(i) stateS.handle.CERRAxisLabel4(i) stateS.handle.CERRAxisScale1(i) stateS.handle.CERRAxisScale2(i) stateS.handle.CERRAxisTicks1(i,:) stateS.handle.CERRAxisTicks2(i,:)];
% numFilled = sum(index);
% reOrderedKids(numFilled+1:end) = kids(~index);
% 
% %%%%%% APA commented to test whether this is needed? ends

%set(hAxis, 'children', reOrderedKids);


% APA commented for RIVIEW - end
