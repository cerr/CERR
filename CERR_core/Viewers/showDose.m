function showDose(hAxis)
%"showDose"
%   Display a dose distribution in hAxis, a CERR axis which must have
%   proper "axisInfo" userdata which determines certain display variables
%   as well as the coordinate, view angle, etc.
%
%JRA 11/18/04
%
%Usage:
%   function showDose(hAxis, view, recalcDose)
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

%Extract information from axis.
hFig            = get(hAxis, 'parent');
%axisInfo        = get(hAxis, 'userdata');
axInd = stateS.handle.CERRAxis == hAxis;
axisInfo = stateS.handle.aI(axInd);
%coord        = axisInfo.coord;
%view         = axisInfo.view;
%doseSets     = axisInfo.doseSets;
[view,coord,doseSets] = getAxisInfo(hAxis,'view','coord','doseSets');

set(hAxis, 'nextplot', 'add');

%Set dim or return if not a scan view.
switch upper(view)
    case 'CORONAL'
        dim = 2;
    case 'SAGITTAL'
        dim = 1;
    case 'TRANSVERSE'
        dim = 3;
    otherwise
        return;
end

% if length(planC{indexS.dose}) < 1
%     return;
% end

%Save current CERR settings for dose display to compare in a moment.
CERRDoseDisplayMode.type = stateS.optS.dosePlotType;
CERRDoseDisplayMode.alpha = stateS.doseAlphaValue.trans;

if strcmpi(get(hAxis,'tag'),'doseCompareAxes')
    CERRDoseDisplayMode.colorbarRange = stateS.colorbarRangeCompare;
    CERRDoseDisplayMode.doseDisplayRange = stateS.doseDisplayRangeCompare;
    doseDisplayRange = stateS.doseDisplayRangeCompare;
else
    CERRDoseDisplayMode.colorbarRange = stateS.colorbarRange;
    CERRDoseDisplayMode.doseDisplayRange = stateS.doseDisplayRange;
    doseDisplayRange = stateS.doseDisplayRange;
end

CERRDoseDisplayMode.CTWidth          = stateS.optS.CTWidth;
CERRDoseDisplayMode.CTLevel          = stateS.optS.CTLevel;

%Find image/dose data that needs to be removed: ie, no longer in the
%list of doses to display, calculated on a different coordinate, view,
%or transM.  Also find image/dose data that needs to have the image
%refreshed, but the underlying data is OK.  Flag these for redrawing.
toRemove = [];
for i=1:length(axisInfo.doseObj)
    dO = axisInfo.doseObj(i);
    if ~ismember(dO.doseSet, doseSets) || ~isequal(coord, dO.coord) || ~isequal(getTransM('dose', dO.doseSet, planC), dO.transM) | ~isequal(view, dO.view)|stateS.CTDisplayChanged
        try, delete(dO.handles); end
        toRemove = [toRemove;i];
    elseif stateS.imageRegistration || ~isequal(dO.dispMode, CERRDoseDisplayMode) || axisInfo.doseObj(i).redraw || stateS.doseDisplayChanged  % APA: check for stateS.doseDisplayChanged ?
        if strcmpi(stateS.imageRegistrationBaseDatasetType,'dose') && stateS.imageRegistrationBaseDataset == axisInfo.doseObj(i).doseSet
            CERRDoseDisplayMode.alpha = 1 - stateS.doseAlphaValue.trans;
        elseif strcmpi(stateS.imageRegistrationMovDatasetType,'dose') && stateS.imageRegistrationMovDataset == axisInfo.doseObj(i).doseSet
            CERRDoseDisplayMode.alpha = stateS.doseAlphaValue.trans;
        end        
        axisInfo.doseObj(i).dispMode = CERRDoseDisplayMode;
        axisInfo.doseObj(i).redraw = 1;
        try, delete(dO.handles); end
        axisInfo.doseObj(i).handles = [];
    end
end
axisInfo.doseObj(toRemove) = [];

%Add a new image/dose data element for any doseNums that don't have one,
%and cache the calculated dose and its coordinates.
for i=1:length(doseSets)
    if isempty(axisInfo.doseObj) || ~ismember(doseSets(i), [axisInfo.doseObj(:).doseSet])
        compareMode  =  getappdata(hAxis,'compareMode');
        numObjs = length(axisInfo.doseObj);
        [im, imageXVals, imageYVals]        = calcDoseSlice(doseSets(i), coord, dim, planC, compareMode, stateS.optS.doseInterpolationMethod);
        axisInfo.doseObj(numObjs+1).coord   = coord;
        axisInfo.doseObj(numObjs+1).data2M  = im;
        axisInfo.doseObj(numObjs+1).xV      = imageXVals;
        axisInfo.doseObj(numObjs+1).yV      = imageYVals;
        axisInfo.doseObj(numObjs+1).xMinMax = [min(imageXVals) max(imageXVals)];
        axisInfo.doseObj(numObjs+1).yMinMax = [min(imageYVals) max(imageYVals)];
        axisInfo.doseObj(numObjs+1).doseUID = planC{indexS.dose}(doseSets(i)).doseUID;
        axisInfo.doseObj(numObjs+1).doseSet = doseSets(i);
        axisInfo.doseObj(numObjs+1).scanBase= [];
        axisInfo.doseObj(numObjs+1).view    = view;
        axisInfo.doseObj(numObjs+1).transM  = getTransM('dose', doseSets(i), planC);
        axisInfo.doseObj(numObjs+1).dispMode= CERRDoseDisplayMode;
        axisInfo.doseObj(numObjs+1).redraw  = 1;
    end
end

imagesChanged = 0;

%Now iterate over doseObjs and display each one.
for j=1:length(axisInfo.doseObj)
    dO = axisInfo.doseObj(j);
    if dO.redraw
        %Flag as drawn
        dO.redraw = 0;

        %Move to next doseObj if no dose to display.
        if isempty(dO.data2M)
            continue;
        end

        switch upper(dO.dispMode.type)
            case 'ISODOSE'
                if stateS.layout == 7
                    colorbarFrameMin = stateS.colorbarFrameMinCompare;
                    colorbarFrameMax =  stateS.colorbarFrameMaxCompare;
                else
                    colorbarFrameMin = stateS.colorbarFrameMin;
                    colorbarFrameMax =  stateS.colorbarFrameMax;
                end

                if strcmpi(stateS.optS.isodoseLevelMode, 'auto')
                    numAuto  = stateS.optS.autoIsodoseLevels;
                    isoRange = stateS.optS.autoIsodoseRange;
                    if stateS.optS.autoIsodoseRangeMode == 1
                        minVal  = colorbarFrameMin;
                        maxVal  = colorbarFrameMax;
                    else
                        minVal  = isoRange(1);
                        maxVal  = isoRange(2);
                    end
                    isodoseLevels = linspace(minVal,maxVal, numAuto+2);
                    isodoseLevels = isodoseLevels(2:end-1);
                    stateS.optS.isodoseLevels = isodoseLevels;
                end

                isodoseLevels = stateS.optS.isodoseLevels;
                type = stateS.optS.isodoseLevelType;                
                if strcmp(type,'percent')
                    structureIndex = stateS.optS.structureIndex;
                    if strcmpi(stateS.optS.isodosePercentType,'max')
                        if structureIndex == 1
                            contourLevels = isodoseLevels * stateS.doseArrayMaxValue / 100;
                            stateS.optS.isodoseNormalizVal = stateS.doseArrayMaxValue;
                        else
                            max_dose = maxDose(planC, structureIndex-1, stateS.doseSet, 'Absolute');
                            stateS.optS.isodoseNormalizVal = max_dose;
                            contourLevels = isodoseLevels * max_dose / 100;
                        end
                    else      
                        if structureIndex == 1
                            dA = getDoseArray(stateS.doseSet,planC);
                            mean_dose = mean(dA(:));                            
                            contourLevels = isodoseLevels * mean_dose / 100;
                        else
                            mean_dose = meanDose(planC, structureIndex-1, stateS.doseSet, 'Absolute');                            
                            contourLevels = isodoseLevels * mean_dose / 100;
                            stateS.optS.isodoseNormalizVal = mean_dose;
                        end
                    end
                elseif strcmp(type,'absolute')
                    contourLevels = isodoseLevels;
                end

                doseM = dO.data2M;
                imageXVals = dO.xV;
                imageYVals = dO.yV;

                dSet = dO.doseSet;
                if isfield(planC{indexS.dose}(dSet), 'doseOffset') && ~isempty(planC{indexS.dose}(dSet).doseOffset)
                    offset = planC{indexS.dose}(dSet).doseOffset;
                    doseM = doseM - offset;
                end

%                 %Contour command syntax requires one level to be duplicated: else it
%                 %interprets this as a request for N levels to be autodetermined.
%                 if length(contourLevels) == 1
%                     contourLevels = [contourLevels contourLevels];
%                 end
% 
%                 plotParam = getPlotInfo;
%                 if ~isempty(plotParam)
%                     [c, hDoseV] = contour(plotParam, hAxis, imageXVals, imageYVals, doseM, double(contourLevels), '-');
%                 else
%                     [c, hDoseV] = contour(hAxis,imageXVals, imageYVals, doseM, double(contourLevels), '-');
%                 end
%                 set(hDoseV, 'tag', 'isodoseContour', 'parent', hAxis, 'hittest', 'off');                
%                 dO.handles = hDoseV;

%                 lastLevel = -1;
%                 isodoseLevels = stateS.optS.isodoseLevels;
                for i = 1 : length(contourLevels)
                    level = contourLevels(i);
                    [c, h] = contour(hAxis,imageXVals, imageYVals, doseM, [contourLevels(i) contourLevels(i)], '-');
                    %h = hDoseV(i);
                    set(h, 'tag', 'isodoseContour', 'parent', hAxis, 'hittest', 'off', 'userdata',level);
                    dO.handles(i) = h;                    
                    %level = get(h,'userdata');
                    %loc = find([level == contourLevels]);
                    loc = i;

                    set(h,'linewidth',stateS.optS.isodoseThickness)
                    if stateS.optS.isodoseUseColormap
                        c = CERRColorMap(stateS.optS.doseColormap);
                        lowerBound = doseDisplayRange(1);
                        upperBound = doseDisplayRange(2);
                        outofbounds = (level <= lowerBound) | (level >= upperBound);
                        if outofbounds
                            set(h, 'visible', 'off');
                        end
                        lowerBound = stateS.colorbarRange(1);
                        upperBound = stateS.colorbarRange(2);
                        if ~(lowerBound == 0 && upperBound == 0)
                            percentBelow = (stateS.colorbarRange(1) - colorbarFrameMin) / (stateS.colorbarRange(2) - stateS.colorbarRange(1));
                            percentAbove = (colorbarFrameMax - stateS.colorbarRange(2)) / (stateS.colorbarRange(2) - stateS.colorbarRange(1));
                            nElements = size(c, 1);
                            lowVal = c(1,:);
                            hiVal = c(end,:);

                            c = [repmat(lowVal, [round(percentBelow*nElements),1]);c;repmat(hiVal, [round(percentAbove*nElements),1])];
                        end
                        relativeLevel = ((level-(colorbarFrameMin))/(colorbarFrameMax - colorbarFrameMin)) * (size(c,1) + 0.5);
                        relativeLevel = clip(round(relativeLevel), 1, size(c,1), 'limits');
                        set(h, 'Color', c(relativeLevel,:));

                    else
                        set(h,'Color', getColor(loc, stateS.optS.colorOrder));
                    end

%                     if level ~= lastLevel
%                         if ~isfield(stateS.handle, 'isodoseLegendTrans')
%                             stateS.handle.isodoseLegendTrans = [];
%                             stateS.handle.isodoseLabelsTrans = {};
%                         end
%                         stateS.handle.isodoseLegendTrans = [stateS.handle.isodoseLegendTrans(:); h];
%                         str = num2str(level);
% 
%                         if strcmpi(stateS.optS.isodoseLevelType,'percent')
%                             n = 5;
%                             percent = contourLevels(loc);
%                             if length(str) >= n
%                                 str = str(1:n);
%                                 str = [str ' Gy, (' num2str(percent) '%)'];
%                             else
%                                 str = [str ' Gy, (' num2str(percent) '%)'];
%                             end
%                         else
%                             str = [str ' Gy'];
%                         end
%                         stateS.handle.isodoseLabelsTrans  = {stateS.handle.isodoseLabelsTrans{:}, str};
%                         lastLevel = level;
%                     end
                end
                axisInfo.doseObj(j) = dO;
                %set(hAxis, 'userdata', axisInfo);
                stateS.handle.aI(axInd) = axisInfo;

                return;

            case 'COLORWASH'
                axisInfo.doseObj(j) = dO;
                
                doseSet = axisInfo.doseObj(j).doseSet;
                hFrame = stateS.handle.controlFrame;
                ud = stateS.handle.controlFrameUd ;

                stateS.doseFusionColormap = '';
                colormapIndex = [];
                if stateS.imageRegistration && strcmpi(stateS.imageRegistrationBaseDatasetType,'dose') && stateS.imageRegistrationBaseDataset == doseSet
                    colormapIndex = get(ud.handles.basedisplayModeColor,'value');
                elseif stateS.imageRegistration && strcmpi(stateS.imageRegistrationMovDatasetType,'dose') && stateS.imageRegistrationMovDataset == doseSet
                    colormapIndex = get(ud.handles.displayModeColor,'value');
                end             
                if ~isempty(colormapIndex) && colormapIndex == 1
                    stateS.doseFusionColormap = 'gray';
                elseif ~isempty(colormapIndex) && colormapIndex == 2
                    stateS.doseFusionColormap = 'copper';
                elseif ~isempty(colormapIndex) && colormapIndex == 3
                    stateS.doseFusionColormap = 'red';
                elseif ~isempty(colormapIndex) && colormapIndex == 4
                    stateS.doseFusionColormap = 'green';
                elseif ~isempty(colormapIndex) && colormapIndex == 5
                    stateS.doseFusionColormap = 'blue';
                elseif ~isempty(colormapIndex) && colormapIndex == 6
                    stateS.doseFusionColormap = 'starinterp';
                end
                
                %First display dose by itself.
                dose2M    = dO.data2M;
                doseXVals = dO.xV;
                doseYVals = dO.yV;
                doseSet   = dO.doseSet;

                %Extract offset value early
                offset = 0;

                if isfield(planC{indexS.dose}, 'doseOffset') && ~isempty(planC{indexS.dose}(doseSet).doseOffset)

                    offset = planC{indexS.dose}(doseSet).doseOffset;
                end

                if stateS.imageRegistration
                   
                    
                    if (stateS.imageRegistrationBaseDataset == doseSet && strcmpi(stateS.imageRegistrationBaseDatasetType, 'dose')) || (stateS.imageRegistrationMovDataset == doseSet && strcmpi(stateS.imageRegistrationMovDatasetType, 'dose'))
                        alpha = dO.dispMode.alpha;
                        stateS.doseFusionAlpha = dO.dispMode.alpha;
                        scanSet = getDoseAssociatedScan(doseSet);
                    else
                        alpha = stateS.doseAlphaValue.trans;
                        stateS.doseFusionAlpha = alpha;
                        scanSet = axisInfo.scanSets;
                    end 
                    
                    [cData3M, xLim, yLim] = CERRDoseColorWash(hAxis, dose2M, doseXVals, doseYVals, offset, [], [], [], scanSet);

                    [xM, yM] = meshgrid(xLim, yLim);

                    zM = zeros(size(xM))-2;

                    hImage = surface(xM, yM, zM, 'faceColor', 'texturemap', 'cData', cData3M, 'edgecolor', 'none', 'facealpha', alpha, 'parent', hAxis, 'tag', 'DoseImage', 'hittest', 'off');

                    axisInfo.doseObj(j).scanBase= [];

                   
                else
                    CTImages = [];
                    if ~isempty(axisInfo.scanObj)
                        CTImages = find(~isempty(axisInfo.scanObj.handles));
                    end

                    if isempty(dose2M)
                        return;
                    end

                    if ~isempty(CTImages)
                        for i=1:length(CTImages);

                            hCTImage = axisInfo.scanObj(CTImages(i)).handles;
                            %get the 1st image in case of contouring mode

                            hCTImage = hCTImage(1);

                            scanSet = axisInfo.scanObj(CTImages(i)).scanSet;

                            CT2M = get(hCTImage, 'cData');
                            
                            CTXVals = axisInfo.scanObj(CTImages(i)).xV;
                            
                            CTYVals = axisInfo.scanObj(CTImages(i)).yV;
                            
                            % Downsample CT2M to original resolution
                            sz = [length(CTYVals), length(CTXVals)];
                            new_sz = size(CT2M);
                            
                            if stateS.optS.sinc_filter_on_display                                
                                CT2M = updownsample(CT2M, new_sz(2),new_sz(1),0,2);
                                CTXVals = linspace(CTXVals(1),CTXVals(end),new_sz(2));
                                CTYVals = linspace(CTYVals(1),CTYVals(end),new_sz(1));
                            end
                            
                            [cData3M, xLim, yLim] = CERRDoseColorWash(hAxis, dose2M, doseXVals, doseYVals, offset, CT2M, CTXVals, CTYVals, scanSet);
                            
                            % Upsample based on sinc flag
                            if stateS.optS.sinc_filter_on_display && ~all(new_sz==sz)
                                %sz = size(cData3M(:,:,1));
                                %if min(sz) <= 256
                                %    new_sz = sz*4;
                                %else
                                %    new_sz = sz*2;
                                %end
                                cDataUpSampled3M(:,:,1) = updownsample(cData3M(:,:,1), new_sz(2),new_sz(1),0,2);
                                cDataUpSampled3M(:,:,2) = updownsample(cData3M(:,:,2), new_sz(2),new_sz(1),0,2);
                                cDataUpSampled3M(:,:,3) = updownsample(cData3M(:,:,3), new_sz(2),new_sz(1),0,2);
                            else
                                cDataUpSampled3M = cData3M;
                            end
                            
                            maxCdata = max(cDataUpSampled3M(:));
                            if maxCdata > 1
                                cDataUpSampled3M = cDataUpSampled3M/maxCdata;
                            end
                            
                            %hImage = image(cDataUpSampled3M, 'XData', xLim, 'YData', yLim, 'hittest', 'off', 'tag', 'DoseImage', 'parent', hAxis, 'visible', 'on');
                            
                            %%% Draw surface instead of image
                            %[xM, yM] = meshgrid(xLim, yLim);
                            xM = [xLim;xLim];
                            yM = [yLim',yLim'];                            
                            zM = [-2 -2; -2 -2];
                            
                            hImage = surface(xM, yM, zM, 'faceColor', 'texturemap', 'cData', cDataUpSampled3M, 'edgecolor', 'none', 'facealpha', 1,'parent', hAxis, 'tag', 'DoseImage', 'hittest', 'off');                            
                            
                            clear cDataUpSampled3M
                            axisInfo.doseObj(j).scanBase = scanSet;
                        end
                    else
                        
                        scanSet = [];
                        [cData3M, xLim, yLim] = CERRDoseColorWash(hAxis, dose2M, doseXVals, doseYVals,  offset, [], [], [], scanSet);
                        
                        if stateS.imageRegistrationBaseDataset == doseSet && strcmpi(stateS.imageRegistrationBaseDatasetType, 'dose')
                            alpha = 1;
                        else
                            alpha = stateS.doseAlphaValue.trans;
                        end
                        
                        [xM, yM] = meshgrid(xLim, yLim);
                        
                        zM = repmat(0,size(xM))-2;
                        
                        hImage = surface(xM, yM, zM, 'faceColor', 'texturemap', 'cData', cData3M, 'edgecolor', 'none', 'facealpha', alpha, 'parent', hAxis, 'tag', 'DoseImage', 'hittest', 'off');

                        %hImage = image(cData3M, 'XData', xLim, 'YData', yLim, 'hittest', 'off', 'tag', 'DoseImage', 'parent', hAxis, 'visible', 'on');


                        axisInfo.doseObj(j).scanBase= [];
                    end
                end
                axisInfo.doseObj(j).handles = hImage;
        end
    end
end

if ~isempty(axisInfo.scanObj) && (isempty(axisInfo.doseObj) || ...
        (~isempty(axisInfo.doseObj) && isempty(axisInfo.doseObj.data2M))) ...
        && ~stateS.imageRegistration && ~isempty(axisInfo.scanObj.handles)
    %axisInfo.scanObj.handles.FaceAlpha = 1;
    set(axisInfo.scanObj.handles,'FaceAlpha',1);
end


%set(hAxis, 'userdata', axisInfo);
stateS.handle.aI(axInd) = axisInfo;
