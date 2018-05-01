function navigationMontage(arg, scanNum, varargin)
%"navigationMontage"
%   Sets up a montage of the CT scans.  The user can navigate to the slice
%   of choice by clicking on the thumbnail image.  Also indicates slices
%   with at least .5*maxDose in the current doseSet (in blue), the slice
%   with the maximum dose (in orange), and the slices containing structures
%   selected in the menu.
%
%JOD, 29 May 03
%JRA, 5 Jun 03, changed to case, fixed some calls and added function to highlight a given slice. Did some refactoring.
%JRA, 6 Jun 03, added function to outline high dose slices
%JRA, 12 Jun 03, several efficency problems addressed
%JRA, 29 Apr 04, Greatly sped up thumb generation, fixed handle issues.
%APA, 31 May 05, Added multiple scan support. Added a second input argument 'scanNum'
%
%Usage:
%   navigationMontage('init',scanNum);
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

global stateS;
global planC;

thumbWidth = 64;  %width of thumbnail views
indexS = planC{end};

% Get GUI fig handle
f = [];
if isfield(stateS.handle,'navigationMontage')
    f = stateS.handle.navigationMontage;
end

% Obtain the checked scanNum if no scanNum is passed
if ~exist('scanNum','var')
    hSwitchMenu = findobj('tag', 'switchScanMenu');
    scanItemListC = {hSwitchMenu.Children.Label};
    nGroupMenu = 0;
    selected = 0;
    
    while nGroupMenu < numel(hSwitchMenu.Children) && selected == 0
        
        nGroupMenu = nGroupMenu + 1;
        hGroupMenu = hSwitchMenu.Children(nGroupMenu);
        nSubMenu = 0;
        if(numel(hGroupMenu.Children)==0) %When no. scans < maxScansPerGroup
            hScan = hGroupMenu;
            selectedScan = strcmp({hScan.Checked},'on');
            selected = any(selectedScan);
        else
            while nSubMenu < numel(hGroupMenu.Children) && selected == 0
                nSubMenu = nSubMenu + 1;
                hSubMenu = hGroupMenu.Children(nSubMenu);
                if ~isempty(hSubMenu.Children)
                    hScan = hSubMenu.Children;
                else
                    hScan = hSubMenu;
                end
                selectedScan = strcmp({hScan.Checked},'on');
                selected = any(selectedScan);
            end
        end
    end
    
    scanTag = get(hScan(selectedScan),'Tag');
    scanNum = str2num(scanTag(9:end));
    
    if ~isempty(f)
        ud = get(f,'userdata');
        ud.scanNum = scanNum;
        ud.scanListC = scanItemListC;
        set(f,'userdata',ud);
        stateS.handle.navigationMontage = f;
    end
    
end

try
    numImagesAcross = planC{indexS.scan}(scanNum).thumbnails.numImagesAcross;
end

numSlices = length(planC{indexS.scan}(scanNum).scanInfo);

switch lower(arg)
    
    case 'redrawstructuremenu'
        ud = get(f,'userdata');
        drawMenu(f, planC,ud.scanNum)
        
    case 'newslice'
        ud = get(f,'userdata');
        slice = getNewSlice(ud.scanNum);
        [~, ~, zs] = getScanXYZVals(planC{indexS.scan}(ud.scanNum)); %New slice location
        
        % find this scan displayed on an axis
        viewC = cell(1,length(stateS.handle.CERRAxis));
        scanSetsV = zeros(1,length(stateS.handle.CERRAxis));
        for i=1:length(stateS.handle.CERRAxis)
            if ~ strcmpi(getAxisInfo(stateS.handle.CERRAxis(i),'view'),'legend') %Skip Legend axis
                [viewC{i}, scanSetsV(i)]=getAxisInfo(stateS.handle.CERRAxis(i),'view', 'scanSets');
            end
        end
        displayedAxisV = find(scanSetsV==ud.scanNum);
        
        if isempty(displayedAxisV)           % If the selected scan is not displayed on any axis
            activeAxis = stateS.currentAxis; % Display selected scan on active axis with view set to 'transverse'
            dispScan = scanSetsV(activeAxis);
            setAxisInfo(stateS.handle.CERRAxis(activeAxis),'view','transverse')
            setAxisInfo(stateS.handle.CERRAxis(activeAxis), 'coord', zs(slice));
            setAxisInfo(stateS.handle.CERRAxis(activeAxis),'scanSelectMode','auto');
            setAxisInfo(stateS.handle.CERRAxis(activeAxis),'structSelectMode','auto');
            axIdx = activeAxis;
        else                  
           % Switch to transverse display of selected scan if available
            dispIdx = strcmpi(viewC(displayedAxisV),'transverse');
            switchAxis = displayedAxisV(dispIdx);
            if ~any(dispIdx)               % If not, set axis showing selected scan to transverse view
                switchAxis = displayedAxisV(1);
                setAxisInfo(stateS.handle.CERRAxis(switchAxis),'view','transverse')
            else
                switchAxis = switchAxis(1);
            end
            dispScan = scanSetsV(switchAxis);
            setAxisInfo(stateS.handle.CERRAxis(switchAxis), 'coord', zs(slice));
            axIdx = switchAxis;
        end
        displayCoord = getAxisInfo(stateS.handle.CERRAxis(axIdx),'coord');
        
        %Update CERR Viewer display
        if dispScan==ud.scanNum
            sliceCallBack('refresh') %the montage actually gets updated when sliceCallBack calls this routine with the 'update' arg
            figure(f) % shift focus back to navigation figure
        else
            selectedStructsC = {ud.handle.navStructs.Children.Checked};
            changeScan = questdlg(['Switch display to scan ',num2str(ud.scanNum),'?'],'Scan display','Yes','No','Yes');
            if strcmp(changeScan,'Yes')
                sliceCallBack('SELECTSCAN',num2str(ud.scanNum));
                setAxisInfo(stateS.handle.CERRAxis(axIdx), 'coord', displayCoord);
                sliceCallBack('refresh')
                f = stateS.handle.navigationMontage;
                ud = get(f,'UserData');
                toDraw = false(1,length(selectedStructsC));
                toDraw(ud.strNum) = 1;
                drawDots(planC, ud.scanNum, stateS, f, toDraw);
            end
            [ud.handle.navStructs.Children.Checked] = deal(selectedStructsC{:});
        end
        
        set(f,'userdata',ud);
        stateS.handle.navigationMontage = f;
        return

    case 'structureselect'
        ud = get(f,'userdata');
        %%% CHANGED  AI 9/2/16 
        %%Leave out empty structures from list - AI 9/2/16
        emptyStructIdxC = arrayfun(@(x)isempty(x.rasterSegments),planC{indexS.structures},'un',0);
        structsV = find(~[emptyStructIdxC{:}]);
        structS = planC{indexS.structures}(structsV);
        toDraw = false(1,length(structS));
        structNum = varargin{1};
        hAssocScanV = ud.handle.navScans;
        %Get selected scan set
        selScan = strcmpi(get(hAssocScanV, 'Checked'), 'on');
        %Get current structure
        currentStruct = strcmp(ud.structListC{selScan},['structureItem', num2str(structNum)]);
        hStructItem = hAssocScanV(selScan).Children(currentStruct);
        if strcmpi(get(hStructItem, 'Checked'), 'off')
            set(hStructItem, 'Checked', 'on')
        else
            set(hStructItem, 'Checked', 'off')
        end
        hAssocScanV(selScan).Children(currentStruct) = hStructItem;
        
        %Identify ROI slices
        scanNum = hStructItem.UserData; 
        associatedScanNumV = getStructureAssociatedScan(structsV, planC);
        matchIdxV = find(associatedScanNumV == scanNum);
        strListC = strcat('structureItem',cellfun(@num2str,num2cell(structsV(matchIdxV)),'un',0));
        for i=1:length(strListC)
            idx = strcmp(strListC,get(hAssocScanV(selScan).Children(i),'Tag'));
            hStruct = hAssocScanV(selScan).Children(i);
            if strcmpi(get(hStruct, 'Checked'), 'on')
                toDraw(matchIdxV(idx))= 1;
            end
        end
        %Get selected structures
        structsSelected = strcmpi({hAssocScanV(selScan).Children.Checked},{'on'});
        ud.strNum = find(toDraw);
        set(f,'userdata',ud);
        
        %Display scan associated with selected structure
        if scanNum~=ud.scanNum && strcmpi(hStructItem.Checked,'on') 
        userSel = questdlg('Display navigation montage for scan associated with selected structure?','Switch scan',...
                           'Yes','No','No');
        if strcmp(userSel,'Yes')
                %stateS.handle.navigationMontage = f;
                stateS.showNavMontage = 0;
                navigationMontage('switchscan',scanNum);
                stateS.showNavMontage = 1;
                f = stateS.handle.navigationMontage;
                ud = get(f,'userdata');
        end
        end

        if any(structsSelected)
            [ud.handle.navScans(selScan).Children(structsSelected).Checked] = deal('on');
        end
        set(f,'userdata',ud); 
        drawDots(planC, ud.scanNum, stateS, f, toDraw);
        stateS.handle.navigationMontage = f;
        return;
        
    case {'right','left','up','down'}
        ud = get(f,'userdata');
        hAxis = stateS.handle.CERRAxis(stateS.currentAxis);
        [view, scanSets, lastcoord] = getAxisInfo(hAxis, 'view', 'scanSets', 'coord');
        if ~strcmp(upper(view),'TRANSVERSE')
            errordlg('Please Choose One of the Transverse Views to Navigate','CERR View-Plane Error')
        elseif scanSets~=ud.scanNum
            errordlg('Scan displayed on focussed view in CERR is different from navigation montage. Please choose the same scan to navigate.','CERR Scan Mismatch Error')
        else
            [xs, ys, zs] = getScanXYZVals(planC{indexS.scan}(scanSets(1)));
            switch lower(arg)
                case 'right'
                    newSlice=findnearest(zs,lastcoord) + 1;
                    if newSlice > numSlices
                        newSlice = 1;
                    end
                case 'left'
                    newSlice=findnearest(zs,lastcoord) - 1;
                    if newSlice < 1
                        newSlice = numSlices;
                    end
                case 'up'
                    newSlice=findnearest(zs,lastcoord)- numImagesAcross;
                    if newSlice < 1
                        newSlice = numSlices;
                    end
                case 'down'
                    newSlice=findnearest(zs,lastcoord)+ numImagesAcross;
                    if newSlice > numSlices
                        newSlice = 1;
                    end
            end
            setAxisInfo(hAxis, 'coord', zs(newSlice));
            sliceCallBack('refresh')
            figure(f) % shift focus back to navigation figure
        end
        return
        
    case 'update'  %slice has been changed elsewhere, wipe out current lines and redraw. Only redraw/calc high doses if dose changed.
        ud = get(f,'userdata');
        scanNum = ud.scanNum;
        try
            if(stateS.lastDoseThumbnailed == stateS.doseSet)
            else
                hV = findobj('tag','doseRangeThumbOutlines');
                delete(hV)
                navigationMontage('outlinehighdoses',scanNum);
            end
        catch
            hV = findobj('tag','doseRangeThumbOutlines');
            delete(hV)
            navigationMontage('outlinehighdoses',scanNum);
        end
        
        hV = findobj('tag', 'navigationLines');
        delete(hV)
        % find this scan displayed on an axis
        for i=1:length(stateS.handle.CERRAxis)
            [view, scanSets]=getAxisInfo(stateS.handle.CERRAxis(i),'view', 'scanSets');
            if strcmpi(view,'transverse') & scanSets==scanNum
                [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(scanNum));
                coord=getAxisInfo(stateS.handle.CERRAxis(i),'coord');
                slice=findnearest(zV,coord);
                navigationMontage('thumboutline', scanNum, slice, [1 1 1], 'navigationLines');
                break
            end
        end
        return
        
        %pass slicenum, color, and a tag. ie, navigationMontage('thumboutline', slice, [1 1 1], 'navigationLines')
        %and result is the outlining of the specificed slice with 4 lines of specificed color, by the given tag.
    case 'thumboutline'
        ud = get(f,'userdata');
        scanNum = ud.scanNum;
        slice = varargin{1};
        color = varargin{2};
        tag = varargin{3};
        across = planC{indexS.scan}(scanNum).thumbnails.numImagesAcross;
        down = planC{indexS.scan}(scanNum).thumbnails.numImagesDown;
        sliceRow = ceil(slice/across);
        sliceCol = slice - (sliceRow - 1) * across;
        im = planC{indexS.scan}(scanNum).thumbnails.montage;
        i = sliceCol;
        j = sliceRow;
        width = thumbWidth;
        h1 = line([(i-1) * width + 1 , (i-1) * width + width], [(j-1) * width + 1 , (j-1) * width + 1], 'parent', stateS.navInfo.Axes);
        h2 = line([(i-1) * width + 1 , (i-1) * width + 1], [(j-1) * width + 1 , (j-1) * width + width], 'parent', stateS.navInfo.Axes);
        h3 = line([(i-1) * width + 1 , (i-1) * width + width], [(j-1) * width + width , (j-1) * width + width], 'parent', stateS.navInfo.Axes);
        h4 = line([(i-1) * width + width , (i-1) * width + width], [(j-1) * width + 1 , (j-1) * width + width], 'parent', stateS.navInfo.Axes);
        set([h1, h2, h3, h4], 'tag', tag,'color', color,'linewidth',0.5);
        return;
        
    case 'outlinehighdoses'
        ud = get(f,'userdata');
        scanNum = ud.scanNum;
        currentDose = stateS.doseSet;
        stateS.lastDoseThumbnailed = currentDose;
        
        if isempty(currentDose)
            return;
        end
        if currentDose == 0
            return;
        end
        
        indexS = planC{end};
        maxDosePerDoseSlice = double(max(max(getDoseArray(planC{indexS.dose}(currentDose)))));
        maxDose = double(max(maxDosePerDoseSlice));
        
        %Find dose zValues inbetween which all slices have at least maxDose/2. Also find zValue with maxDose.
        firstZ = planC{indexS.dose}(currentDose).zValues(min(find([maxDosePerDoseSlice >= maxDose/2])));
        lastZ = planC{indexS.dose}(currentDose).zValues(max(find([maxDosePerDoseSlice >= maxDose/2])));
        maxZ = planC{indexS.dose}(currentDose).zValues(max(find([maxDosePerDoseSlice == maxDose])));
        
        %Find CT slice numbers corresponding to dose Z values
        firstIndex = min(find([planC{indexS.scan}(scanNum).scanInfo.zValue] >= firstZ));
        lastIndex = max(find([planC{indexS.scan}(scanNum).scanInfo.zValue] <= lastZ));
        [junk, maxIndex] = min(abs([planC{indexS.scan}(scanNum).scanInfo.zValue] - maxZ));
        
        %Draw thumboutlines for each slice.
        for i=firstIndex:lastIndex
            navigationMontage('thumboutline', scanNum, i, [0 0 .5], 'doseRangeThumbOutlines');
        end
        navigationMontage('thumboutline', scanNum,  maxIndex, [1 .5 0], 'doseRangeThumbOutlines');
        
        %If an offset is involved, find and highlight the most negative
        %slice, in green.
        if(isfield(planC{indexS.dose}, 'doseOffset') & ~isempty(planC{indexS.dose}(currentDose)))
            minDosePerDoseSlice = min(min(getDoseArray(planC{indexS.dose}(currentDose))));
            minDose = 0;
            minZ = planC{indexS.dose}(currentDose).zValues(max(find([minDosePerDoseSlice == minDose])));
            if isempty(minZ)
                minZ = planC{indexS.dose}(currentDose).zValues(end);
            end
            minIndex = min(find([planC{indexS.scan}(scanNum).scanInfo.zValue] >= minZ));
            navigationMontage('thumboutline', scanNum, minIndex, [0 1 0], 'doseRangeThumbOutlines');
        end
        return;
        
    case 'showbookmarks'
        ud = get(f,'userdata');
        scanNum = ud.scanNum;
        try
            bmarks = [planC{indexS.scan}(scanNum).scanInfo.bookmarked];
        catch
            [planC{indexS.scan}(scanNum).scanInfo.bookmarked] = deal(0);
            return;
        end
        delete(findobj('tag', 'bookmarkText'));
        slice = find(bmarks);
        
        across = planC{indexS.scan}(scanNum).thumbnails.numImagesAcross;
        down = planC{indexS.scan}(scanNum).thumbnails.numImagesDown;
        sliceRow = ceil(slice/across);
        sliceCol = slice - (sliceRow - 1) * across;
        i = sliceCol;
        j = sliceRow;
        width = thumbWidth;
        text([(i-1) * width + 2.5], [(j) * width + 1], 'b', 'color', [.8 .8 .8], 'verticalAlignment', 'bottom', 'tag', 'bookmarkText', 'parent', stateS.navInfo.Axes)
        navigationMontage('outlinehighdoses',scanNum);
        navigationMontage('update',scanNum);
        return;
        
    case 'clearbookmarks'
        ud = get(f,'userdata');
        try
            [planC{indexS.scan}(ud.scanNum).scanInfo.bookmarked] = deal(0);
        end
        navigationMontage('showbookmarks',ud.scanNum);
        return;
        
    case 'togglebookmark'
        % check if current scan is transverse corresponds to one displayed on nav
        % Montage, otherwise pop-up an error message
        aI = getAxisInfo(stateS.handle.CERRAxis(stateS.currentAxis));
        scanNum = aI.scanSets;
        %if aI.scanSets==scanNum & strcmpi(aI.view,'transverse')
        if strcmpi(aI.view,'transverse')
            zValue = aI.coord;
            [xs, ys, zs] = getScanXYZVals(planC{indexS.scan}(scanNum));
            sliceNum = findnearest(zs, zValue);
            try
                planC{indexS.scan}(scanNum).scanInfo(sliceNum).bookmarked = xor(planC{indexS.scan}(scanNum).scanInfo(sliceNum).bookmarked, 1);
            catch
                [planC{indexS.scan}(scanNum).scanInfo.bookmarked] = deal(0);
                planC{indexS.scan}(scanNum).scanInfo(sliceNum).bookmarked = xor(planC{indexS.scan}(scanNum).scanInfo(sliceNum).bookmarked, 1);
            end
            navigationMontage('showbookmarks',scanNum);
        else
            %errordlg('Current slice must be transverse and correspond to the scan displayed on montage')
            errordlg('Only transverse slice can be bookmarked')
        end
        
        return;
        
    case 'switchscan'
        previousScan = f.UserData.scanNum;
        navigationMontage('init',scanNum)
        %Mark scan as checked
        f = stateS.handle.navigationMontage;
%         hScanMenu = f.UserData.handle.switchScan; 
%         markSelectedScan(hScanMenu,previousScan,'Off')
%         markSelectedScan(hScanMenu,scanNum,'On') 
        sliceCallBack('refresh')
        stateS.handle.navigationMontage = f;
        return;
        
    case 'quit'
        stateS.showNavMontage = 0;
        closereq;
        
    otherwise
        
        %Have thumbnails been generated?
        try
            im = planC{indexS.scan}(scanNum).thumbnails.montage;
        catch   %create them
            
            w = planC{indexS.scan}(scanNum).scanInfo(1).sizeOfDimension1;
            
            scan3M = getScanArray(planC{indexS.scan}(scanNum));
            
            bar = waitbar(0,'Generate thumbnails of CT images...');
            sizV = size(scan3M(:,:,1));
            
            dim1 = planC{indexS.scan}(scanNum).scanInfo(1).sizeOfDimension1;
            dim2 = planC{indexS.scan}(scanNum).scanInfo(1).sizeOfDimension2;
            
            upsampleImage = 0;
            if mod(sizV(1),thumbWidth)~=0
                yi = linspace(1,sizV(1),sizV(1)-mod(sizV(1),thumbWidth)+thumbWidth);
                dim1 = sizV(1)-mod(sizV(1),thumbWidth)+thumbWidth;
                upsampleImage = 1;
            else
                yi = 1:sizV(1);
            end
            if mod(sizV(2),thumbWidth)~=0
                xi = linspace(1,sizV(2),sizV(2)-mod(sizV(2),thumbWidth)+thumbWidth);
                dim2 = sizV(2)-mod(sizV(2),thumbWidth)+thumbWidth;
                upsampleImage = 1;
            else
                xi = 1:sizV(2);
            end
            sample = [dim1 dim2]/thumbWidth;
            
            for i = 1 : numSlices
                %get ct data:
                ct = scan3M(:,:,i);
                if upsampleImage
                    ct = finterp2(1:sizV(2),1:sizV(1),double(ct),xi,yi,1,0);
                    ct = reshape(ct,[length(yi) length(xi)]);
                end
                smooth3M(:,:,i) = thumbImage(ct, sample);
                waitbar(i/numSlices,bar)
            end
            
            close(bar)
            
            [im, down, across] = CERRMontage(smooth3M);
            
            %put into the archive:
            
            planC{indexS.scan}(scanNum).thumbnails.montage = im;
            
            planC{indexS.scan}(scanNum).thumbnails.numImagesAcross = across;
            
            planC{indexS.scan}(scanNum).thumbnails.numImagesDown = down;
            
            if strcmpi(arg,'import')
                return
            end
        end
        
        %Set up montage window.
        across = ceil(numSlices^0.5);
        strNum = [];
        if isfield(stateS.handle,'navigationMontage') && isvalid(stateS.handle.navigationMontage);
            posFig = get(stateS.handle.navigationMontage,'position');
            if isfield(stateS.handle.navigationMontage.UserData,'strNum')
                strNum = stateS.handle.navigationMontage.UserData.strNum;
            end
            delete(stateS.handle.navigationMontage);
        end
        f = figure;
        set(f,'tag','navigationFigure','doublebuffer', 'on', 'CloseRequestFcn','navigationMontage(''quit'')')
        if ~exist('posFig','var')
        posFig = get(f,'position');
        end
        set(f,'position',[posFig(1),posFig(2),posFig(4),posFig(4)]);  %make it square.
        
        %pos = [0, 0, 1, 1];   %fill to boundary
        dim1 = planC{indexS.scan}(scanNum).scanInfo(1).sizeOfDimension1;
        dim2 = planC{indexS.scan}(scanNum).scanInfo(1).sizeOfDimension2;
        %pos = [(1-dim2/max([dim1 dim2]))/2 (1-dim1/max([dim1 dim2]))/2 dim2/max([dim1 dim2]) dim1/max([dim1 dim2])];
        [xV,yV,zV] = getScanXYZVals(planC{indexS.scan}(scanNum));
        dimRatio = abs((max(yV)-min(yV))/(max(xV)-min(xV)));
        if dimRatio < 1
            axis_width  = 1;
            axis_height = dimRatio;
            x_start = 0;
            y_start = 0.5-dimRatio/2;
        elseif dimRatio > 1
            axis_width  = dimRatio;
            axis_height = 1;
            x_start = 0.5-dimRatio/2;
            y_start = 0;
        else
            axis_width  = 1;
            axis_height = 1;
            x_start = 0;
            y_start = 0;
        end
        pos = [x_start y_start axis_width axis_height];
        hAxis = axes('position', pos, 'parent', f);
        %hAxis = axes('position', pos, 'parent', f,'nextPlot','add');
        
        handle = imagesc(im, 'parent', hAxis);
        %axis(hAxis,'image','off');
        axis(hAxis,'off')
        set(handle,'tag','navigationImage')
        set(hAxis,'nextPlot','add')
        
        map = CERRColorMap(stateS.optS.navigationMontageColormap);
        
        colormap(hAxis,map);
        
        %str = ['Navigation:  ' stateS.CERRFile];
        str = ['Navigation Montage for Scan:  ', num2str(scanNum)];
        
        set(f,'name',str,'numbertitle','off','menubar','none')
        
        ud.handle.thumbnails = handle;
        ud.handle.navAxis = hAxis;
        ud.scanNum = scanNum;
        ud.strNum = strNum;
        set(f,'userdata',ud);
        
        drawMenu(f, planC,scanNum);
        drawBookmarkMenu(f, planC,scanNum)
        hSwitchMenu = drawScanMenu(f,scanNum); %CHANGED
        stateS.navInfo.Axes = hAxis;
        set(handle,'buttondownfcn',['navigationMontage(''newSlice'',',num2str(scanNum),')'])
        stateS.handle.navigationMontage = f;
        % navigationMontage('update');
        navigationMontage('showbookmarks',scanNum);
        
        %Get structure list
        figMenuC = arrayfun(@(x) x.Tag,f.Children,'un',0);
        ud = get(f,'userdata');
        hNavStructs = f.Children(strcmp(figMenuC,'navigationstructs'));
        if ~isempty(hNavStructs)
        hAssocScan = ud.handle.navScans;
        structListC = {};
        if ~isempty(hAssocScan)
            for k = 1:numel(hAssocScan)
                structListC{k} = {hAssocScan(k).Children.Tag};
            end
        end
        ud.structListC = structListC;
        scanItemListC = {hNavStructs.Children.Label};
        ud.scanListC = scanItemListC;
        end
        ud.handle.navStructs = hNavStructs;
        f.Children(strcmp(figMenuC,'switchScanMenu')) = hSwitchMenu;
        ud.handle.switchScan = hSwitchMenu;
        set(f,'userdata',ud);
        stateS.handle.navigationMontage = f;
end


%-----------end main---------------------%

%--------------------------------%
function [im, down, across] = CERRMontage(smooth3M)

%Fix the size of the array:
n = size(smooth3M,3);

across = ceil(n^0.5);

if across * (across -1) >= n
    down = across -1 ;
else
    down = across;
end

height = size(smooth3M,1);
width = size(smooth3M,2);

%fill in:
im = zeros(height*down,width*across);
count = 0;
for i = 1 : down
    for j = 1 : across
        count = count + 1;
        if count <= n
            im((i-1) * height + 1 : (i-1) * height + height, (j-1) * width + 1 : (j-1) * width + width) = smooth3M(:,:,count);
        end
    end
end


%--------------------------------%
function [slice, sliceRow, sliceCol] = getNewSlice(scanNum)
%Get the image number from the mouse position

global stateS;
global planC;
indexS = planC{end};

across = planC{indexS.scan}(scanNum).thumbnails.numImagesAcross;

down = planC{indexS.scan}(scanNum).thumbnails.numImagesDown;

im = planC{indexS.scan}(scanNum).thumbnails.montage;

width = size(im,1)/down;

n = size(getScanArray(planC{indexS.scan}(scanNum)),3);

h = stateS.navInfo.Axes;
%set(h,'units','normalized')
p = get(h, 'currentpoint');
p = p(1,1:2);

col = p(1);
row = p(2);
sliceRow = ceil(row/width);
sliceCol = ceil(col/width);

slice = (sliceRow - 1) * across + sliceCol;

if slice > n
    slice = n;
    sliceCol = n - (sliceRow - 1) * across;
end

%-----------fini---------------------%
function drawMenu(hFigure, planC,scanNum)
indexS = planC{end};
ud = get(hFigure,'userdata');
hStructMenu = findobj('tag', 'navigationstructs');

%Leave out empty structures 
emptyStructIdxC = arrayfun(@(x)isempty(x.rasterSegments),planC{indexS.structures},'un',0);
structsV = find(~[emptyStructIdxC{:}]);
if isempty(structsV) %No structures available
    return
end


structS = planC{indexS.structures}(structsV);

%If structure list has changed or we arent initialized, redraw menu.
if ~isempty(hStructMenu) & isempty(setxor(get(hStructMenu, 'userdata'), {structS.structureName}))
    return;
else
    %Get list of structures 
    structuresC = {structS.structureName};
    %Get list of unique associated scans
    associatedScanNumV = getStructureAssociatedScan(structsV, planC);
    uqScanV = unique(associatedScanNumV,'stable');
    associatedScanType = {planC{indexS.scan}(uqScanV).scanType};
    %Main structures menu
    if isempty(hStructMenu)
        hStructMenu = uimenu(hFigure, 'label', 'Structures', 'tag', 'navigationstructs', 'callback', 'navigationMontage(''redrawStructureMenu'')');
    end
    set(hStructMenu, 'userdata', structuresC);
    delete(get(hStructMenu, 'children'));
    %Add menu listing structures grouped by scan type
    for i=1:numel(uqScanV)
        %Scan type
        hAssocScanV(i) = uimenu(hStructMenu, 'label',associatedScanType{i},...
        'callback',@setCheckedScan);
        matchIdxV = find(associatedScanNumV == uqScanV(i));
        %Associated structures
        for j = 1:numel(matchIdxV)
            uimenu(hAssocScanV(i),'label',structuresC{matchIdxV(j)},'userdata',uqScanV(i),...
                'callback', ['navigationMontage(''structureSelect'',' num2str(scanNum),',', num2str(structsV(matchIdxV(j))) ');'],...
                'tag', ['structureItem' num2str(structsV(matchIdxV(j)))]);
        end
    end

    ud.handle.navStructs = hStructMenu;
    ud.handle.navScans = hAssocScanV;

    set(hFigure,'userdata',ud);

end

function drawBookmarkMenu(hFigure, planC,scanNum)
indexS = planC{end};
hStructMenu = uimenu(hFigure, 'label', 'Bookmarks', 'tag', 'bookmarkMenu');
uimenu(hStructMenu, 'label', 'Clear all', 'callback', ['navigationMontage(''clearbookmarks'',',num2str(scanNum),')']);
uimenu(hStructMenu, 'label', 'Toggle on/off', 'callback', ['navigationMontage(''togglebookmark'',',num2str(scanNum),')']);

function hScanMenu = drawScanMenu(hFigure,scanNum)
hScanMenu = uimenu(hFigure, 'label', 'Switch Scan', 'tag', 'switchScanMenu');
addScansToMenu(hScanMenu,1,scanNum);
state = 'On';
hScanMenu = markSelectedScan(hScanMenu,scanNum,state);


function hScanMenu = markSelectedScan(hScanMenu,scanNum,state)
%Mark selected scan as 'checked'
subMenuNum = 0;
selected = 0;
while subMenuNum < numel(hScanMenu.Children) && selected == 0
    subMenuNum = subMenuNum + 1;
    if ~isempty(hScanMenu.Children(subMenuNum).Children)
        hSubMenu = hScanMenu.Children(subMenuNum).Children;
        selectedScan = strcmp({hSubMenu.Tag},['scanItem',num2str(scanNum)]);
        selected = any(selectedScan);
        if any(selected)
        set(hSubMenu(selectedScan),'checked',state);
        hScanMenu.Children(subMenuNum).Children = hSubMenu; 
        end
    else
        hSubMenu = hScanMenu.Children(subMenuNum);
        selectedScan = strcmp({hSubMenu.Tag},['scanItem',num2str(scanNum)]);
        selected = any(selectedScan);
        if any(selected)
        set(hSubMenu(selectedScan),'checked',state);
        hScanMenu.Children(subMenuNum) = hSubMenu;
        end
    end
end    

    
%--------------------------------%
function drawDots(planC, scanNum, stateS, hFigure, userData)
%Delete old structure dots and redraw all.
indexS = planC{end};
delete(findobj('tag', 'structureDot'));

enabledStructs = find(userData);

if isempty(enabledStructs)
    return;
end

across = planC{indexS.scan}(scanNum).thumbnails.numImagesAcross;
down = planC{indexS.scan}(scanNum).thumbnails.numImagesDown;
im = planC{indexS.scan}(scanNum).thumbnails.montage;

[imageY, imageX] = size(im);
thumbX = (imageX/(across));
thumbY = (imageY/(down));

dotSizeX = thumbX/10;
dotSizeY = thumbY/10;

[x,y,z] = size(getScanArray(planC{indexS.scan}(scanNum)));
for i=1:z
    numDots = 0;
    for j=1:length(enabledStructs)
        try
            emptyStructIdxC = arrayfun(@(x)isempty(x.rasterSegments),planC{indexS.structures},'un',0);
            structS = planC{indexS.structures}(~[emptyStructIdxC{:}]);
            if length(structS(enabledStructs(j)).contour(i).segments) > 1 | ~isempty(structS(enabledStructs(j)).contour(i).segments.points)
                %draw a dot
                x = mod(i-1, across) * thumbX;
                y = floor((i-1)/across) * thumbY;
                %color = getColor(enabledStructs(j), planC{indexS.CERROptions}.colorOrder);
                color = structS(enabledStructs(j)).structureColor;
                patch([2 2+dotSizeX 2+dotSizeX 2]+x+numDots*6, [2 2 2+dotSizeY 2+dotSizeY]+y, color, 'Tag', 'structureDot', 'parent', stateS.navInfo.Axes);
                numDots = numDots + 1;
            end
        end
    end
end


    function setCheckedScan(hObj,~)
        hAssocScanV = hObj.Parent.Children;
        set(hAssocScanV,'checked','off');
        set(hObj,'Checked','on');
        

 
