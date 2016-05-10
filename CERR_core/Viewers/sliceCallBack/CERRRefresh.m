function CERRRefresh()
%           EFFECTIVELY, THIS IS THE REFRESH FUNCTION!
%   This point is reached by the callbacks which need to update
%   any or all of the axes.  Flags are checked to determine which
%   axes require refreshing.
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


%---------------------------Update Axes--------------------------%
%If no plan is loaded, take no action to redraw axes.
global planC
global stateS
indexS = planC{end};

if ~stateS.planLoaded
    return;
end

% Turn dose off for scan comparison mode
if stateS.layout == 6;
    stateS.doseToggle = -1;
end

%If doseSet changed, update labels and colorbar.
if stateS.doseSetChanged & stateS.doseToggle == 1
    if stateS.layout == 7
        for i = 1:length(stateS.handle.CERRAxis)-4
            doseSet = getAxisInfo(stateS.handle.CERRAxis(4+i),'doseSets');
            dose3M = getDoseArray(doseSet(1));
            doseArrayMaxValue(i) = max(dose3M(:));
            doseArrayMinValue(i) = min(dose3M(:));
        end
        stateS.doseArrayMaxValueCompare = max(doseArrayMaxValue);
        stateS.doseDisplayRangeCompare= [min(doseArrayMinValue) stateS.doseArrayMaxValueCompare];
        stateS.colorbarRangeCompare = stateS.doseDisplayRangeCompare ;

        CERRColorBar('init',stateS.handle.doseColorbar.Compare);
    end
    if ~isempty(stateS.doseSet)
        
        if stateS.layout == 8
            
            offset = 0;
            
        else
            
            ID = planC{indexS.dose}(stateS.doseSet(1)).fractionGroupID;
            description = planC{indexS.dose}(stateS.doseSet(1)).doseDescription;
            
            ID = fixDisplayString(ID);
            description = fixDisplayString(description);
            dose3M = getDoseArray(stateS.doseSet(1));
            stateS.doseChanged = 1;
            
            hID = stateS.handle.fractionGroupIDTrans;
            hDescr = stateS.handle.doseDescriptionTrans;
            set(hID,'String',ID);
            set(hDescr,'String',description);
            
            
            stateS.doseArrayMaxValue = max(dose3M(:));
            clear dose3M
            offset = 0;
            try
                if(~isempty(planC{indexS.dose}(stateS.doseSet(1)).doseOffset))
                    offset = planC{indexS.dose}(stateS.doseSet(1)).doseOffset;
                end
            end
            
        end
        
        if ~isfield(stateS, 'colorbarRange') || ~stateS.optS.staticColorbar
            if offset > 0
                stateS.doseDisplayRange    = [min([-offset, -(stateS.doseArrayMaxValue - offset)]), max([offset, stateS.doseArrayMaxValue - offset])];
                stateS.colorbarRange       = stateS.doseDisplayRange;
            else
                stateS.doseDisplayRange    = [0 stateS.doseArrayMaxValue];
                stateS.colorbarRange       = stateS.doseDisplayRange;
            end
        end
        
        if ~isempty(isempty(stateS.optS.colorbarMin)) && ~isempty(stateS.optS.colorbarMax)
            stateS.colorbarRange = [stateS.optS.colorbarMin stateS.optS.colorbarMax];
        end

        CERRColorBar('init', stateS.handle.doseColorbar.trans);

        controlFrame('colorbar', 'refresh');
    end
end

if stateS.doseToggle == -1
    stateS.colorbarRange = [0 1];
    stateS.doseDisplayRange = [0 1];
    if stateS.layout == 7
        stateS.colorbarRangeCompare = [0 1];
        stateS.doseDisplayRangeCompare = [0 1];
    end
end

%Check flags to determine what actions need to be taken for each axis.
%For each axis, check type and display proper image(s).
for i=uint8(1:length(stateS.handle.CERRAxis))
    hAxis       = stateS.handle.CERRAxis(i);
    [axisView] = getAxisInfo(i, 'view');

%     if stateS.imageRegistration
%         if ispc
%             opengl software;
%         end
%         delete(findobj('parent', hAxis, 'type', 'surface'));
%         delete(findobj('parent', hAxis, 'type', 'hggroup'));
%     end
    %Set the orientation of each axis.
    switch axisView
        case 'transverse'
            set(hAxis, 'ydir', 'normal');
            set(hAxis, 'xdir', 'normal');
        case 'sagittal'
            set(hAxis, 'ydir', 'reverse');
            set(hAxis, 'xdir', 'reverse');
        case 'coronal'
            set(hAxis, 'ydir', 'reverse');
            set(hAxis, 'xdir', 'normal');
    end

    [scanSelectMode, doseSelectMode, structSelectMode] = getAxisInfo(i, 'scanSelectMode', 'doseSelectMode', 'structSelectMode');
    %If axis is displaying default, get scanSet from stateS.
    if strcmpi(scanSelectMode, 'auto');
        setAxisInfo(i, 'scanSets', stateS.scanSet);
    end
    if strcmpi(doseSelectMode, 'auto');
        setAxisInfo(i, 'doseSets', stateS.doseSet);
    end
    if strcmpi(structSelectMode, 'auto');
        setAxisInfo(i, 'structureSets', stateS.structSet);
    end

    if stateS.doseToggle == -1
        setAxisInfo(i, 'doseSets', []);
    end
    if stateS.CTToggle == -1
        setAxisInfo(i, 'scanSets', []);
    end
    if stateS.structToggle == -1
        setAxisInfo(i, 'structureSets', []);
    end
    %If the x/y range is not defined, use auto axis.

    xRange = getAxisInfo(i, 'xRange');
    yRange = getAxisInfo(i, 'yRange');
    if isempty(xRange) || isempty(yRange)
        updateAxisRange(hAxis,0);
        zoomToXYRange(hAxis);
        %         axis(hAxis, 'equal', 'auto');
    end
    switch axisView
        case {'transverse','sagittal','coronal'}

            showCT(hAxis);
            showDose(hAxis);
            showStructures(hAxis);
            showScale(hAxis, i);
            showBeams(hAxis);
            if stateS.annotToggle == 1
                controlFrame('ANNOTATION','show')
            end
    end

    % Cleanup each axis to delete unwanted graphics.
    % this has been taken out of commission since the scan,struct, profile
    % etc. handles are now tightly controlled by storing them to stateS.
    % Consider re-enabling if we run into any unexpected graphics display errors.
    % cleanupAxes(hAxis,i);

    %Check and set range variable if needed.
    xRange = getAxisInfo(i, 'xRange');
    yRange = getAxisInfo(i, 'yRange');
    if isempty(xRange) || isempty(yRange)
        setAxisInfo(i, 'xRange', get(hAxis, 'xLim'));
        setAxisInfo(i, 'yRange', get(hAxis, 'yLim'));
        zoomToXYRange(hAxis);
    end

%     %     Reset the Axis to new xRange and yRange
%     zoomToXYRange(hAxis);

    %Make sure everything is drawn in the right order.
    %setChildDrawOrder(hAxis);
end
removeCERRHandle('mask');

stateS.structsChanged = 0;

%Redraw (or hide) locators
showPlaneLocators;

% if stateS.gridState
%     sliceCallBack('toggleRuler');
% end

if stateS.doseQueryState
    sliceCallBack('DOSEQUERYMOTION','NoCurrentPt')
end
if stateS.scanQueryState
    scanQuery('SCANQUERYMOTION','NoCurrentPt')
end
if stateS.doseProfileState
    sliceCallBack('DOSEPROFILEMOTION','NoCurrentPt')
end

%Set visibility of contours, try since visible may not be defined.
%try
%    contourVisibility;
%end

%Draw Legend.
for i=uint8(1:length(stateS.handle.CERRAxis))
    hAxis = stateS.handle.CERRAxis(i);
    view = getAxisInfo(i, 'view');
    if strcmpi(view, 'legend')
        showCERRLegend(hAxis);
    end
    %try % This is added for the Film QA Tool DK %% 03-18-08 %%
    %    showFilmPoints(hAxis);
    %end
end
    
% if ~isfield(stateS,'webtrev') || ~stateS.webtrev.isOn
% end

if(isempty(stateS.gridState))  %Ruler was on, first toggle it off, then back on to recalculate values and redraw.
    stateS = callGrid('revert', stateS.gridState);
    stateS = callGrid('revert', stateS.gridState);
end

%update montage:
if stateS.showNavMontage
    navigationMontage('update');
end

%Inform contouring code that slice changed if contourState is 1.  This
%must be done after cleanupAxes, since cleanupAxes clears lines drawn
%by the contour code.
if stateS.contourState && (stateS.currentAxis == stateS.contourAxis)
    contourControl('changeSlice');
end

%Draw structure comparison masks
if isfield(stateS,'structCompare')
    hFig = findobj('name','Agreement Histogram');
    if ~isempty(hFig)
        ud = get(hFig,'userdata');
        XData = get(ud.hLine,'XData');
        showComparisonMask(stateS.structCompare.structAll,max(1e-5,XData(1)))
    else
        showComparisonMask(stateS.structCompare.structAll,1e-5)
    end
end

stateS.doseSetChanged     = 0;
stateS.doseDisplayChanged = 0;
stateS.CTDisplayChanged   = 0;
return