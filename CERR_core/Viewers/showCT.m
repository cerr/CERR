function varargout = showCT(hAxis)
%"showCT"
%   Display a CT slice in CERR axis hAxis.  hAxis MUST have the
%   userdata property set up to CERR standards.
%
%   Checks the axisInfo.scanSets field in hAxis's userinfo field to
%   determine which CTs must be displayed, if any.
%
%JRA 12/7/04
%
%Usage:
%   function showCT(hAxis)
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

%Get info about the axis view.
hFig         = get(hAxis, 'parent');
%axisInfo     = get(hAxis, 'userdata');
axInd = stateS.handle.CERRAxis == hAxis;
axisInfo = stateS.handle.aI(axInd);
%coord        = axisInfo.coord;
%view         = axisInfo.view;
%scanSets     = axisInfo.scanSets;
[view,coord,scanSets] = getAxisInfo(hAxis,'view','coord','scanSets');

%Set to 1 if images may need to be refused.
imagesChanged = 0;

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

%Find image/scan data that needs to be removed: ie, no longer in the
%list of scans to display, calculated on a different coordinate, view,
%or transM.  Also find image/scan data that needs to have the image
%refreshed, but the underlying data is OK.  Flag these for redrawing.
toRemove = [];
for i=1:length(axisInfo.scanObj)
    sO = axisInfo.scanObj(i);
    scanSet = axisInfo.scanObj(i).scanSet;
    scanUID = ['c',repSpaceHyp(planC{indexS.scan}(scanSet).scanUID(max(1,end-61):end))];

    %wy if imageRegistration, refresh scans for diff computation
    if ~ismember(sO.scanSet, scanSets) || ~isequal(coord, sO.coord) || ~isequal(getTransM('scan', sO.scanSet, planC), sO.transM) || ~isequal(view, sO.view)
        imagesChanged = 1;
        %try
            delete(sO.handles); 
        %end
        toRemove = [toRemove;i];
        %If any doseObjs were drawn on this scan, tell them to refresh.
        for j=1:length(axisInfo.doseObj)
            if axisInfo.doseObj(j).scanBase == sO.scanSet;
                axisInfo.doseObj(j).redraw = 1;
            end
        end
    elseif ~isequal(sO.dispMode, [stateS.scanStats.CTLevel.(scanUID) stateS.scanStats.CTWidth.(scanUID)]) || stateS.imageRegistration  || stateS.CTDisplayChanged
        axisInfo.scanObj(i).redraw = 1;
        imagesChanged = 1;
        %try
            delete(sO.handles); 
        %end
        toRemove = [toRemove;i];
        for j=1:length(axisInfo.doseObj)
            if axisInfo.doseObj(j).scanBase == sO.scanSet;
                axisInfo.doseObj(j).redraw = 1;
            end
        end
    end
end
axisInfo.scanObj(toRemove) = [];

%Add a new image/scan data element for any scanNums that don't have one,
%and cache the calculated scan and its coordinates.
for i=1:length(scanSets)
    if isempty(axisInfo.scanObj)||(isfield(axisInfo.scanObj,'scanSet') && ~ismember(scanSets(i),[axisInfo.scanObj.scanSet]))
        numObjs = length(axisInfo.scanObj);
        [im, imageXVals, imageYVals, planC]        = getCTOnSlice(scanSets(i), coord, dim, planC);
        axisInfo.scanObj(numObjs+1).coord   = coord;
        axisInfo.scanObj(numObjs+1).data2M  = im;
        axisInfo.scanObj(numObjs+1).xV      = imageXVals;
        axisInfo.scanObj(numObjs+1).yV      = imageYVals;
        axisInfo.scanObj(numObjs+1).xMinMax = [min(imageXVals) max(imageXVals)];
        axisInfo.scanObj(numObjs+1).yMinMax = [min(imageYVals) max(imageYVals)];
        axisInfo.scanObj(numObjs+1).scanSet = scanSets(i);
        axisInfo.scanObj(numObjs+1).view    = view;
        axisInfo.scanObj(numObjs+1).transM  = getTransM('scan', scanSets(i), planC);
        axisInfo.scanObj(numObjs+1).redraw  = 1;
        axisInfo.scanObj(numObjs+1).handles = [];
    end
end

%Now iterate over scanObjs and display each one.
for i=1:length(axisInfo.scanObj)
    sO = axisInfo.scanObj(i);
    if sO.redraw
        %Flag as drawn
        axisInfo.scanObj(i).redraw = 0;

        %Get scan info.
        scanSet     = sO.scanSet;
        im          = sO.data2M;
        imageXVals  = sO.xV;
        imageYVals  = sO.yV;

        %If we are out of range with this coord, don't display.
        if isempty(im)
            axisInfo.scanObj(i).handles = [];
            axisInfo.scanObj(i).dispMode = [];
            %set(hAxis, 'userdata', axisInfo);
            stateS.handle.aI(axInd) = axisInfo;
            continue;
        end

        xLim = [imageXVals(1) imageXVals(end)];
        yLim = [imageYVals(1) imageYVals(end)];

        % Added DK to resolve the issue of moving and base data set windowing

        if stateS.imageRegistration %wy

            if axisInfo.scanObj(i).scanSet == stateS.imageRegistrationBaseDataset

                CTOffset    = planC{indexS.scan}(scanSet).scanInfo(1).CTOffset;
                %CTLevel     = stateS.optS.CTLevel + CTOffset;
                %CTWidth     = stateS.optS.CTWidth;
                %CTLow       = CTLevel - CTWidth/2;
                %CTHigh      = CTLevel + CTWidth/2;
                scanUID = ['c',repSpaceHyp(planC{indexS.scan}(scanSet).scanUID(max(1,end-61):end))];
                CTLevel     = stateS.scanStats.CTLevel.(scanUID) + CTOffset;
                CTWidth     = stateS.scanStats.CTWidth.(scanUID);
                CTLow       = CTLevel - CTWidth/2;
                CTHigh      = CTLevel + CTWidth/2;                
                %scanMin = stateS.scanStats.minScanVal.(scanUID);
                %scanMax = stateS.scanStats.maxScanVal.(scanUID);
                %CTLow = max(CTLow,scanMin);
                %CTHigh = min(CTHigh,scanMax);                
                clippedCT = clip(im, CTLow, CTHigh, 'limits');
                
%                 hFrame = stateS.handle.controlFrame;
%                 ud = get(hFrame, 'userdata');
%                 colorMapC = get(ud.handles.basedisplayModeColor,'string');
%                 colorMapVal = get(ud.handles.basedisplayModeColor,'value');
%                 map = CERRColorMap(colorMapC{colorMapVal});
%                 colormap(hAxis, map);

                %% DK for Scan color map change
                %                 clrVal = get(stateS.handle.BaseCMap,'value');
                %
                %                 switch num2str(clrVal)
                %                     case '1' % Gray
                %                         %wy Apply window and level by clipping CT.
                %                         clippedCT = clip(im, CTLow, CTHigh, 'limits');
                %
                %                     case '2' %copper
                %                         cmap = CERRColorMap('copper');
                %
                %                         clippedCT = (im - CTLow) / (CTHigh-CTLow)*(size(cmap,1)-1);
                %
                %                         clippedCT = clip(round(clippedCT(:)),1,size(cmap,1),'limits');
                %
                %                         clippedCT = reshape(cmap(clippedCT, 1:3),size(im,1),size(im,2),3);
                %
                %                     otherwise % case '3'(red) case '4'(green) case '5'(blue)
                %                          im = (im - CTLow) / (CTHigh-CTLow);
                %
                %                          im = clip(im, 0, 1, 'limits');
                %
                %                          clippedCT = repmat(zeros(size(im)), [1 1 3]);
                %
                %                         clippedCT(:,:,clrVal-2) = im;
                %                 end

            elseif axisInfo.scanObj(i).scanSet == stateS.imageRegistrationMovDataset

                CTOffset    = planC{indexS.scan}(scanSet).scanInfo(1).CTOffset;
                %CTLevel     = stateS.Mov.CTLevel + CTOffset;
                %CTWidth     = stateS.Mov.CTWidth;
                %CTLow       = CTLevel - CTWidth/2;
                %CTHigh      = CTLevel + CTWidth/2;
                scanUID = ['c',repSpaceHyp(planC{indexS.scan}(scanSet).scanUID(max(1,end-61):end))];
                CTLevel     = stateS.scanStats.CTLevel.(scanUID) + CTOffset;
                CTWidth     = stateS.scanStats.CTWidth.(scanUID);
                CTLow       = CTLevel - CTWidth/2;
                CTHigh      = CTLevel + CTWidth/2;                                
                %scanMin = stateS.scanStats.minScanVal.(scanUID);
                %scanMax = stateS.scanStats.maxScanVal.(scanUID);                
                %CTLow = max(CTLow,scanMin);
                %CTHigh = min(CTHigh,scanMax);                
                %wy Apply window and level by clipping CT.
                clippedCT = clip(im, CTLow, CTHigh, 'limits');
                             
            else
                
                return;

            end

            clippedCT = clippedCT - double(CTLow);
            clippedCT = clippedCT / double( CTHigh - CTLow);
            
            %set(hFig, 'renderer', 'openGL');
            
            %colormap(hAxis, 'gray');
            %map = CERRColorMap(stateS.scanStats.Colormap.(scanUID));
            %colormap(hAxis, map);

        else
            CTOffset    = planC{indexS.scan}(scanSet).scanInfo(1).CTOffset;
            scanUID = ['c',repSpaceHyp(planC{indexS.scan}(scanSet).scanUID(max(1,end-61):end))];
            CTLevel     = stateS.scanStats.CTLevel.(scanUID) + CTOffset;
            CTWidth     = stateS.scanStats.CTWidth.(scanUID);
            CTLow       = CTLevel - CTWidth/2;
            CTHigh      = CTLevel + CTWidth/2;
            %scanMin = stateS.scanStats.minScanVal.(scanUID);
            %scanMax = stateS.scanStats.maxScanVal.(scanUID);
            %CTLow = max(CTLow,scanMin);
            %CTHigh = max(CTLow,min(CTHigh,scanMax));

            %wy Apply window and level by clipping CT.
            clippedCT = clip(im, CTLow, CTHigh, 'limits');

            %set(hFig, 'renderer', 'zbuffer');
            
            % same colormap for all scans
            %colorMapC = get(stateS.handle.BaseCMap,'string');
            %colorMapVal = get(stateS.handle.BaseCMap,'value');
            %map = CERRColorMap(colorMapC{colorMapVal});
            
            map = CERRColorMap(stateS.scanStats.Colormap.(scanUID));
            colormap(hAxis, map);

        end       
        
        

        %colormap(hAxis, 'gray');
        

        if stateS.imageRegistration && stateS.imageRegistrationBaseDataset == scanSet && strcmpi(stateS.imageRegistrationBaseDatasetType, 'scan')
            alpha = 1;
        elseif stateS.imageRegistration && stateS.imageRegistrationMovDataset == scanSet && strcmpi(stateS.imageRegistrationBaseDatasetType, 'scan')
            alpha = stateS.doseAlphaValue.trans;
        else
            if ~isempty(axisInfo.doseSets)
                alpha = 1-stateS.doseAlphaValue.trans;
            else
                alpha = 1;
            end
        end

        [xM, yM] = meshgrid(xLim, yLim);

        zM = zeros(size(xM))-2;
        
        sz = size(clippedCT);
        if stateS.optS.sinc_filter_on_display && min(sz) < 512            
            new_sz = sz*2;
            clippedCT = updownsample(clippedCT, new_sz(2),new_sz(1),0,2);
        end
        hImage = surface(xM, yM, zM, 'faceColor', 'texturemap', 'cData', clippedCT, 'edgecolor', 'none', 'facealpha', alpha,'parent', hAxis, 'tag', 'CTImage', 'hittest', 'off');
        %x = linspace(xLim(1),xLim(2),length(clippedCT(1,:)));
        %y = linspace(yLim(1),yLim(2),length(clippedCT(:,1)));
        %hImage = imagesc(clippedCT, 'hittest', 'off', 'AlphaData',alpha*double(~isnan(clippedCT)),...
        %   'AlphaDataMapping','none','Xdata',x,'Ydata',y, 'parent', hAxis, 'tag', 'CTImage');

        
        if stateS.imageRegistration %wy
            set(hAxis, 'cLim', [0 1]);
        else
            set(hAxis, 'cLim', [CTLow-1e-3 CTHigh+1e-3]);
        end

        axisInfo.scanObj(i).handles = hImage;

        axisInfo.scanObj(i).dispMode =  [stateS.scanStats.CTLevel.(scanUID) stateS.scanStats.CTWidth.(scanUID)];

        imagesChanged = 1;

        %% Overlay another scan in contouring mode
        overLayFlag = 0;
        if stateS.contourState
            ud = stateS.handle.controlFrameUd ;
            overlayScanNum = get(ud.handles.overlayChoices,'value');
            contourScan = getAxisInfo(stateS.handle.CERRAxis(stateS.contourAxis),'scanSets');
            if overlayScanNum ~= contourScan
                overLayFlag = 1;
            end
        end

        if overLayFlag
            %overlayScanNum = 1;
            %appData = getappdata(stateS.handle.CERRAxis(1));
            %planC{indexS.scan}(overlayScanNum).transM = appData.transMList{overlayScanNum};

            alpha = stateS.doseAlphaValue.trans;
            [imOverlay, imageXValsOverlay, imageYValsOverlay] = getCTOnSlice(overlayScanNum, coord, dim, planC);
            CTOffset    = planC{indexS.scan}(overlayScanNum).scanInfo(1).CTOffset;
            CTLevel     = stateS.contourOvrlyOptS.center + CTOffset;
            CTWidth     = stateS.contourOvrlyOptS.width;
            CTLow       = CTLevel - CTWidth/2;
            CTHigh      = CTLevel + CTWidth/2;

            if ~isempty(imOverlay)
                %Apply window and level by clipping CT.
                imOverlay = clip(imOverlay, CTLow, CTHigh, 'limits');

                offset = 0;
                baseCTOffset = planC{indexS.scan}(scanSet).scanInfo(1).CTOffset;
                [cData3M, xLim, yLim] = CERRScanColorWash(hAxis, imOverlay, imageXValsOverlay, imageYValsOverlay, offset, im, imageXVals, imageYVals,dim, baseCTOffset);

                [xM, yM] = meshgrid(xLim, yLim);
                zM = repmat(0,size(xM))-2;
                if stateS.optS.sinc_filter_on_display
                    sz = size(cData3M(:,:,1));
                    if min(sz) <= 256
                        new_sz = sz*4;
                    else
                        new_sz = sz*2;
                    end
                    cDataUpSampled3M(:,:,1) = updownsample(cData3M(:,:,1), new_sz(2),new_sz(1),0,2);
                    cDataUpSampled3M(:,:,2) = updownsample(cData3M(:,:,2), new_sz(2),new_sz(1),0,2);
                    cDataUpSampled3M(:,:,3) = updownsample(cData3M(:,:,3), new_sz(2),new_sz(1),0,2);
                else
                    cDataUpSampled3M = cData3M;
                end
                hImage = surface(xM, yM, zM, 'faceColor', 'texturemap', 'cData', cDataUpSampled3M, 'edgecolor', 'none', 'facealpha', alpha, 'parent', hAxis, 'tag', 'DoseImage', 'hittest', 'off');

                axisInfo.scanObj(i).handles = [axisInfo.scanObj(i).handles hImage];
            end
        end
    end
end
%set(hAxis, 'userdata', axisInfo);
stateS.handle.aI(axInd) = axisInfo; 

if imagesChanged && stateS.imageRegistration && length(axisInfo.scanObj)>1 %wy
    %In case of 2 scans in one axis, fuse them.
    axisfusion(hAxis, stateS.optS.fusionDisplayMode, stateS.optS.fusionCheckSize);
    stateS.structsChanged = 1;
end

if nargout > 0
    varargout{1} = hImage;
else
    varargout = {};
end