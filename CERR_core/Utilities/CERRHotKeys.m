function CERRHotKeys()
%Routing function called by all CERR figures on keypress
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

global planC stateS; %global is temporary, until stateS and planC are stored in figure userdata.

if ~isempty(planC) && iscell(planC)
    indexS = planC{end};
else
    return;
end

%get Tag of figure making callback.
figureName = get(gcbf, 'Tag');
keyPressed = get(gcbf, 'CurrentCharacter');
keyValue = uint8(keyPressed);
%
if isfield(stateS, 'currentKeyPress') && ~isempty(stateS.currentKeyPress)
    stateS.currentKeyPress = keyValue;
end

%if key pressed has no ASCII analogue, quit. He's dead Jim.
if(isempty(keyValue))
    return;
end

%Else, switch based on the key value.  If the same key has different
%effects depending on the figure it originates from, switch on the
%figureName to decide on action.
switch(keyValue)

    case {30, 119} %up arrow
        
        if stateS.layout == 6 && isempty(stateS.currentKeyPress)
            hAxis = gca;
            if ~ismember(hAxis,stateS.handle.CERRAxis);
                return;
            end
            translateScanOnAxis(hAxis, 'PREVSLICE')
            return;
        end
        switch(upper(figureName))
            case 'CERRSLICEVIEWER'
                sliceCallBack('ChangeSlc','PREVSLICE');
            case 'NAVIGATIONFIGURE'
                navigationMontage('up');
            otherwise
        end

    case {31, 115} %down arrow
        if stateS.layout == 6 && isempty(stateS.currentKeyPress)
            hAxis = gca;
            if ~ismember(hAxis,stateS.handle.CERRAxis);
                return;
            end
            translateScanOnAxis(hAxis, 'NEXTSLICE')
            return;
        end        
        switch(upper(figureName))
            case 'CERRSLICEVIEWER'
                sliceCallBack('ChangeSlc','NEXTSLICE');
            case 'NAVIGATIONFIGURE'
                navigationMontage('down');
            otherwise
        end

    case 28 %left arrow
        switch(upper(figureName))
            case 'NAVIGATIONFIGURE'
                navigationMontage('left');
            otherwise
        end

    case 29 %right arrow
        switch(upper(figureName))
            case 'NAVIGATIONFIGURE'
                navigationMontage('right');
            otherwise
        end
        
    case 66 %'B' Toggles bookmark on current Slice
        if isfield(stateS.handle,'navigationMontage')            
            navigationMontage('togglebookmark');
        end
        

    case 98 %'b' Cycles through bookmarked slices.
        try
            %sN = stateS.sliceNum;
            aI = getAxisInfo(stateS.handle.CERRAxis(stateS.currentAxis));
            scanSet = aI.scanSets;
            if strcmpi(aI.view,'transverse')
                zValue = aI.coord;
                [xs, ys, zs] = getScanXYZVals(planC{indexS.scan}(scanSet));
                sN = findnearest(zs, zValue);

                marked = find([planC{indexS.scan}(scanSet).scanInfo.bookmarked]);
                if ~isempty(marked)
                    newSlice = min(marked(marked > sN));
                    if isempty(newSlice)
                        newSlice = marked(1);
                    end
                    %stateS.sliceNum = newSlice;
                    setAxisInfo(stateS.handle.CERRAxis(stateS.currentAxis),'coord',zs(newSlice))
                    CERRRefresh;
                end
            else
                errordlg('Current slice must be transverse')
            end
        end
    case 96 % ` key, next to the 1.  Always calls LabBook.
        LabBookGui('CAPTURE');

    case 127 % delete key.  If in contour mode, deletes contour? think about it.        
        if isfield(stateS,'contourState') && stateS.contourState
            % delete all segments on the slice
            hAxis = stateS.handle.CERRAxis(stateS.contourAxis);
            contourControl('deleteAllSegments', hAxis)
        end

    case 122 % 'z' key, toggles zoom.
        %         val = get(stateS.handle.zoom, 'value');
        %         set(stateS.handle.zoom, 'value', xor(val, 1));
        sliceCallBack('TOGGLEZOOM');

    case 101 % 'e' key
        if ~isfield(stateS,'contourState') || ~stateS.contourState %Check for contouring mode
            return
        end
        contourControl('editMode');
        controlFrame('contour', 'refresh');

    case 100 % 'd' key
        if ~isfield(stateS,'contourState') || ~stateS.contourState %Check for contouring mode
            return
        end
        contourControl('drawMode');
        controlFrame('contour', 'refresh');

    case 27 % 'esc' key

    case 116 %'t' key
        if ~isfield(stateS,'contourState') || ~stateS.contourState %Check for contouring mode
            return
        end
        contourControl('threshMode');
        controlFrame('contour', 'refresh');

    case 114 %'r' key;
        if ~isfield(stateS,'contourState') || ~stateS.contourState %Check for contouring mode
            return
        end
        contourControl('reassignMode');
        controlFrame('contour', 'refresh');
        
%     case {76,108} % l or L key
%         val = get(stateS.handle.CTLevelWidthInteractive,'value');
%         if val == 0
%             set(stateS.handle.CTLevelWidthInteractive,'value',1);
%         else
%             set(stateS.handle.CTLevelWidthInteractive,'value',0);
%         end
%         sliceCallBack('TOGGLESCANWINDOWING');
        
    case 3 %'Ctrl + c' Copy contour from slice
        if ~isfield(stateS,'contourState') || ~stateS.contourState %Check for contouring mode
            return
        end
        axIdx = stateS.contourAxis;
        hAxis = stateS.handle.CERRAxis(axIdx);
        %Get source slice
        srcCoord = getAxisInfo(uint8(axIdx),'coord');
        scanSet = getAxisInfo(uint8(stateS.currentAxis), 'scanSets');
        [~, ~, zs] = getScanXYZVals(planC{indexS.scan}(scanSet));
        srcSlice = findnearest(srcCoord, zs);
        stateS.contouringMetaDataS.copySliceNum = srcSlice;
        contourMask = stateS.contouringMetaDataS.contourMask;
        stateS.contouringMetaDataS.copyMask = contourMask;
        ccStruct = stateS.contouringMetaDataS.ccStruct;
        CERRStatusString(sprintf('Copied structure: %d slice: %d.',ccStruct,srcSlice));
        
    case 22 %'Ctrl + v' Copy contour to slice
        if ~isfield(stateS,'contourState') || ~stateS.contourState %Check for contouring mode
            return
        end
        axIdx = stateS.contourAxis;
        hAxis = stateS.handle.CERRAxis(axIdx);
        %Get source slice
        srcSlice = stateS.contouringMetaDataS.copySliceNum;
        if isempty(srcSlice)
            return
        end
        
        %Get contours
        ccStruct = stateS.contouringMetaDataS.ccStruct;
        ccContours = stateS.contouringMetaDataS.ccContours;
        contourV = ccContours{ccStruct,srcSlice};
        if isempty(contourV)
            return
        end
        
        %Copy contours to dest slice
        [scanSet,destCoord] = getAxisInfo(uint8(stateS.currentAxis),'scanSets','coord');
        [~, ~, zs] = getScanXYZVals(planC{indexS.scan}(scanSet));
        destSlice = find(zs==destCoord);
        if size(ccContours,2)<destSlice
        ccContours{ccStruct, destSlice} = []; %Dest slice
        end
        stateS.contouringMetaDataS.ccContours = ccContours;
        stateS.contouringMetaDataS.contourV = contourV;
        contourControl('copySl',hAxis,destSlice);
        
    case {43,61} %'+' key to increase brush size in contouring mode
        if ~stateS.contourAxis %Check for contouring mode
            return
        end
        hAxis = stateS.handle.CERRAxis(stateS.currentAxis);
        %mode = getappdata(hAxis, 'mode');
        mode = stateS.contouringMetaDataS.mode;
        switch upper(mode)
            case {'FLEXSELMODE','FLEXMODE','DRAWINGBALL'}
                increment = min([planC{indexS.scan}(1).scanInfo(1).grid1Units,...
                    planC{indexS.scan}(1).scanInfo(1).grid2Units]);
                controlFrame('contour','setBrushSize',hAxis,increment);
            case 'THRESHOLD'
                %cP = get(hAxis, 'currentPoint');
                CpOld = stateS.contouringMetaDataS.thresholdStartPoint;
                maxLevel = stateS.contouringMetaDataS.maxLevel;
                contractionBias = stateS.contouringMetaDataS.ContractionBias;
                stateS.contouringMetaDataS.ContractionBias = max(-1,contractionBias - 0.05);

                %if cP(1,2) < CpOld(1,2)
                %    setappdata(hAxis, 'minLevel',minLevel-1);
                %else
                %    setappdata(hAxis, 'maxLevel',maxLevel+1);
                %end
                % getThresh(hAxis, CpOld(1,1), CpOld(1,2))
                getThreshold(hAxis);
        end
        
    case 45 %'-' key to decrease brush size in contouring mode
        if ~stateS.contourAxis %Check for contouring mode
            return
        end
        hAxis = stateS.handle.CERRAxis(stateS.currentAxis);
        mode = stateS.contouringMetaDataS.mode;
        switch upper(mode)
            case {'FLEXSELMODE','FLEXMODE','DRAWINGBALL'}
                decrement = -min([planC{indexS.scan}(1).scanInfo(1).grid1Units,...
                    planC{indexS.scan}(1).scanInfo(1).grid2Units]);
                controlFrame('contour','setBrushSize',hAxis,decrement);
            case 'THRESHOLD'
                %cP = get(hAxis, 'currentPoint');
                CpOld = stateS.contouringMetaDataS.thresholdStartPoint;
                
                maxLevel = stateS.contouringMetaDataS.maxLevel; 
                
                contractionBias = stateS.contouringMetaDataS.ContractionBias;
                
                stateS.contouringMetaDataS.ContractionBias = min(1,contractionBias + 0.05);

                %if cP(1,2) < CpOld(1,2)
                %    setappdata(hAxis, 'minLevel',minLevel-1);
                %else
                %    setappdata(hAxis, 'maxLevel',maxLevel+1);
                %end
                % getThresh(hAxis, CpOld(1,1), CpOld(1,2))
                getThreshold(hAxis);
        end
        
    case 2 %Ctrl+b Force set 'flex' mode to brush
        if ~stateS.contourAxis %Check for contouring mode
            return
        end
        hAxis = stateS.handle.CERRAxis(stateS.contourAxis);
        mode = stateS.contouringMetaDataS.mode;
        if strcmp(mode,'flexMode')
            contourControl('Save_Slice');
            contourControl('flexSelMode', 0);
        end
        
    case 5 %Ctrl+e Force set 'flex' mode to eraser
        if ~stateS.contourAxis %Check for contouring mode
            return
        end
        hAxis = stateS.handle.CERRAxis(stateS.contourAxis);
        mode = stateS.contouringMetaDataS.mode;
        if strcmp(mode,'flexMode')
            contourControl('Save_Slice');
            contourControl('flexSelMode', 1);
        end
end



% temporary, to test. create a separate function file
function getThresh(hAxis, x, y) % old function, replaced by getThreshold
%Sets the current segment to the contour of connected region x,y
global planC
global stateS
indexS = planC{end};
% [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(stateS.currentScan));
[scanSet,coord] = getAxisInfo(stateS.handle.CERRAxis(stateS.contourAxis),'scanSets','coord');
[xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(scanSet));
% [r, c, jnk] = xyztom(x,y,zeros(size(x)), planC);
[r, c, jnk] = xyztom(x,y,zeros(size(x)), scanSet, planC);
r = round(r);
c = round(c);
if r < 1 || r > length(yV) || c < 1 || c > length(xV)
    return;
end

% threshV = getappdata(hAxis, 'threshLevelV');
% minLevel = getappdata(hAxis, 'minLevel');
% maxLevel = getappdata(hAxis, 'maxLevel');
% %hImg =  findobj(hAxis, 'tag', 'CTImage');
% %imgM = get(hImg, 'cData');
% imgM = getappdata(hAxis, 'smoothImg');
% pixVal = imgM(r, c);
% ind1 = find(threshV > pixVal, 1, 'first');
% if isempty(ind1)
%     ind1 = length(threshV);
% end
% if isempty(minLevel)
%     minLevel = ind1 - 1;
%     setappdata(hAxis, 'minLevel', minLevel-1);
% end
% minLevel = max(1,minLevel);
% if isempty(maxLevel)
%     maxLevel = ind1;
%     setappdata(hAxis, 'maxLevel', maxLevel+1);
% end
% maxLevel = min(maxLevel,length(threshV));

% indAbove = max(1,ind1 - 1);
% indBelow = min(indAbove + currentLeveldiff,length(threshV));
% threshM = imgM >= threshV(indAbove) & imgM < threshV(indBelow);

% threshM = imgM >= threshV(minLevel) & imgM < threshV(maxLevel);
imgM = stateS.contouringMetaDataS.smoothImg;
ContractionBias = stateS.contouringMetaDataS.ContractionBias;

% maskM = false(length(yV), length(xV));
% delta = 2;
% [rM,cM] = meshgrid(r-delta:r+delta,c-delta:c+delta);
% maskM(rM(:),cM(:)) = 1;
maskM = stateS.contouringMetaDataS.InitialMask;

% delta = 50;
% threshM = false(size(imgM));
% threshM(r-delta:r+delta,c-delta:c+delta) = ...
%     activecontour(imgM(r-delta:r+delta,c-delta:c+delta), maskM(r-delta:r+delta,c-delta:c+delta), 30, 'Chan-Vese','ContractionBias',ContractionBias);
% threshM = activecontour(imgM, maskM, 30, 'Chan-Vese','ContractionBias',ContractionBias);
threshM = activecontour(imgM, maskM, 30, 'edge','ContractionBias',ContractionBias);

labelM = labelmatrix(bwconncomp(threshM,4));
labelVal = labelM(r,c);
ROI = labelM == labelVal;

% BW = roicolor(img,pixVal);
% L = bwlabel(BW, 4);
% region = L(r,c);

% ROI = L == region;
% [contour, sliceValues] = maskToPoly(ROI, 1, planC);
% get slceValues
sliceValues = findnearest(zV,coord);
[contr, sliceValues] = maskToPoly(ROI, sliceValues, scanSet, planC);
% if(length(contour.segments) > 1)
%     longestDist = 0;
%     longestSeg =  [];
%     for i = 1:length(contour.segments)
%         segmentV = contour.segments(i).points(:,1:2);
%         curveLength = 0;
%         for j = 1:size(segmentV,1) - 1
%             curveLength = curveLength + sepsq(segmentV(j,:)', segmentV(j+1,:)');
%         end
%         if curveLength > longestDist
%             longestDist = curveLength;
%             longestSeg = i;
%         end
%     end
%     segment = contour.segments(longestSeg).points(:,1:2);
% else
%     segment = contour.segments.points(:,1:2);
% end
segment = contr.segments(1).points(:,1:2);
contourV = {};
for seg = 1:length(contr.segments)
    if ~isempty(contr.segments(seg).points)
        contourV{seg} = contr.segments(seg).points;
    end
end
stateS.contouringMetaDataS.contourV = contourV;
stateS.contouringMetaDataS.contourMask = ROI;
stateS.contouringMetaDataS.segment = segment;

drawSegment(hAxis);


function getThreshold(hAxis)
%Sets the current segment to the contour of connected region x,y
global planC
global stateS
% indexS = planC{end};
% [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(stateS.currentScan));
%[scanSet,coord] = getAxisInfo(stateS.handle.CERRAxis(stateS.contourAxis),'scanSets','coord');
% [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(scanSet));
% [r, c, jnk] = xyztom(x,y,zeros(size(x)), planC);
% [r, c, jnk] = xyztom(x,y,zeros(size(x)), scanSet, planC);
% r = round(r);
% c = round(c);
% if r < 1 || r > length(yV) || c < 1 || c > length(xV)
%     return;
% end

imgM = stateS.contouringMetaDataS.smoothImg;
ContractionBias = stateS.contouringMetaDataS.ContractionBias;
scanSet = stateS.contouringMetaDataS.ccScanSet;
maskM = stateS.contouringMetaDataS.InitialMask;

% maskM = false(length(yV), length(xV));
% delta = 2;
% [rM,cM] = meshgrid(r-delta:r+delta,c-delta:c+delta);
% maskM(rM(:),cM(:)) = 1;
% threshM = false(size(maskM));
% threshM(r-100:r+100,c-100:c+100) = activecontour(imgM(r-100:r+100,c-100:c+100), maskM(r-100:r+100,c-100:c+100), 20, 'Chan-Vese','ContractionBias',ContractionBias);
% threshM = activecontour(imgM, maskM, 30, 'Chan-Vese','ContractionBias',ContractionBias);
threshM = activecontour(imgM, maskM, 30, 'edge','ContractionBias',ContractionBias);

labelM = labelmatrix(bwconncomp(threshM,4));
% labelVal = labelM(r,c);
labelToKeepV = unique(labelM(maskM));
labelToKeepV = labelToKeepV(labelToKeepV > 0);
segM = false(size(maskM));
for iLabel = 1:length(labelToKeepV)
    segM = segM | labelM == labelToKeepV(iLabel);
end

% get slceValues
%sliceValues = findnearest(zV,coord);
sliceValues = 1; % dummy, since 2d
contr = maskToPoly(segM, sliceValues, scanSet, planC);
segment = contr.segments(1).points(:,1:2);
contourV = {};
for seg = 1:length(contr.segments)
    if ~isempty(contr.segments(seg).points)
        contourV{seg} = contr.segments(seg).points;
    end
end
stateS.contouringMetaDataS.contourV = contourV;
stateS.contouringMetaDataS.contourMask = segM;
stateS.contouringMetaDataS.segment = segment;


drawSegment(hAxis);



function drawSegment(hAxis)
%Redraw the current segment associated with hAxis
hSegment = stateS.contouringMetaDataS.hSegment;
mode = stateS.contouringMetaDataS.mode;

%    delete(hSegment);
%end
%hSegment = [];

segment = stateS.contouringMetaDataS.segment;
if ~isempty(segment) && (strcmpi(mode, 'drawing') || strcmpi(mode, 'draw'))
    %hSegment = line(segment(:,1), segment(:,2), 'color', 'red', 'hittest', 'off', 'parent', hAxis, 'ButtonDownFcn', 'drawContour(''contourClicked'')');
    %setappdata(hAxis, 'hSegment', hSegment);
    set(hSegment,'XData',segment(:,1),'YData',segment(:,2), 'hittest', 'off')    
elseif ~isempty(segment)
    %hSegment = line(segment(:,1), segment(:,2), 'color', 'red', 'hittest', 'on', 'parent', hAxis, 'ButtonDownFcn', 'drawContour(''contourClicked'')');
    %setappdata(hAxis, 'hSegment', hSegment);
    set(hSegment,'XData',segment(:,1),'YData',segment(:,2), 'hittest', 'on')    
else
    %setappdata(hAxis, 'hSegment', []);
    if ishandle(hSegment)
        set(hSegment,'XData',0,'YData',0, 'hittest', 'off')
    end
end