function dualEnergyCTLabelerLayout(command,varargin)
% dualEnergyCTLabelerLayout
% Changes the display on CERR to the dual energy CT labeler mode.
% The "Tumor Enhanced" scan is linked with one of the dual energy CT scans.
%
% APA, 10/13/2017
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

global planC stateS
indexS = planC{end};

if length(planC{indexS.scan})<2
    warndlg('Need to have more than one scan to use this mode')
    return
end

switch lower(command)
    case 'init'
        if stateS.layout == 7
            doseCompare('exit');
        end
        if stateS.layout == 6
            scanCompare('exit');            
        end
        if stateS.layout == 9
            %return;
            perfDiffusion('exit');
        end
        if stateS.layout == 10
            %return;
            %dualEnergyCTLabelerLayout('exit');            
        end
        
        boneMetStructNum = 1;
        scanNameC = {planC{indexS.scan}.scanType};
        segScanIndex = find(strcmpi('Tumor Enhanced',scanNameC));
        ctScanIndex = find(strcmpi('PELVIS 110 KeV',scanNameC)); % change to '110 kev W / MARS' when coordinates are fixed
        assocScanNum = getStructureAssociatedScan(boneMetStructNum);
        if isempty(segScanIndex) || isempty(ctScanIndex) || assocScanNum ~= segScanIndex 
            warndlg('No matching scans');
            return;
        end
               
        if stateS.layout ~= 10
            stateS.Oldlayout = stateS.layout;
            stateS.layout = 10;
        end        
                
        % Set scans, doses, views
        setAxisInfo(stateS.handle.CERRAxis(1),'scanSets',segScanIndex,...
            'scanSelectMode', 'manual','doseSelectMode', 'manual','doseSets',[],...
            'structSelectMode','manual','structureSets',segScanIndex,'xRange',[],...
            'yRange',[],'view','transverse');
        linkC = {'Linked', stateS.handle.CERRAxis(1)};
        % Use stateS.handle.aI directly inistead of setAxisInfo since it
        % follows the linked axis.
        stateS.handle.aI(5).scanSets = ctScanIndex;
        stateS.handle.aI(5).doseSets = [];
        stateS.handle.aI(5).structureSets = ctScanIndex;
        stateS.handle.aI(5).scanSelectMode = 'manual';
        stateS.handle.aI(5).doseSelectMode = 'manual';
        stateS.handle.aI(5).xRange = linkC;
        stateS.handle.aI(5).yRange = linkC;
        stateS.handle.aI(5).view = linkC;
        stateS.handle.aI(5).coord = linkC;       

        orderV = [1 5 2 3 4];
        
        stateS.handle.CERRAxis = stateS.handle.CERRAxis(orderV);
        stateS.handle.CERRAxisLabel1 = stateS.handle.CERRAxisLabel1(orderV);
        stateS.handle.CERRAxisLabel2 = stateS.handle.CERRAxisLabel2(orderV);
        stateS.handle.CERRAxisLabel3 = stateS.handle.CERRAxisLabel3(orderV);
        stateS.handle.CERRAxisLabel4 = stateS.handle.CERRAxisLabel4(orderV);
        stateS.handle.CERRAxisScale1 = stateS.handle.CERRAxisScale1(orderV);
        stateS.handle.CERRAxisScale2 = stateS.handle.CERRAxisScale2(orderV);
        stateS.handle.CERRAxisTicks1 = stateS.handle.CERRAxisTicks1(orderV,:);
        stateS.handle.CERRAxisTicks2 = stateS.handle.CERRAxisTicks2(orderV,:);
        stateS.handle.CERRAxisPlnLocSdw = stateS.handle.CERRAxisPlnLocSdw(orderV);
        stateS.handle.CERRAxisPlnLoc = stateS.handle.CERRAxisPlnLoc(orderV);
        stateS.handle.aI = stateS.handle.aI(orderV);
        
        
        % Do not show plane locators
        %stateS.showPlaneLocators = 0;
        
        % Go to slice with structure
        axes(stateS.handle.CERRAxis(1))
        for i = 1:length(planC{indexS.structures}(boneMetStructNum).contour)
            if ~isempty(planC{indexS.structures}(boneMetStructNum).contour(i).segments)
                goto('SLICE',i)
                break;
            end
        end
        
        CERRRefresh
        
        
    case 'exit'
        %sliceCallBack('layout',stateS.Oldlayout)     
        delete([findobj('tag', 'spotlight_patch'); findobj('tag', 'spotlight_xcrosshair'); findobj('tag', 'spotlight_ycrosshair'); findobj('tag', 'spotlight_trail')]);
        CERRStatusString('');
        
        % Find and delete the duplicate (linked) views        
        for i = length(stateS.handle.CERRAxis):-1:1
            hAxis = stateS.handle.CERRAxis(i);
            view = stateS.handle.aI(i).view;            
            if iscell(view) % linked axes views are of type "cell"
                sliceCallBack('selectaxisview', hAxis, 'delete view');
            end            
        end
        % Get views for axes
        for i = 1:length(stateS.handle.CERRAxis)
            %viewC{i} = stateS.handle.aI(i).view;
            viewC{i} = getAxisInfo(stateS.handle.CERRAxis(i),'view');
        end
        
        transIndex = find(strcmpi('transverse',viewC));
        sagIndex = find(strcmpi('sagittal',viewC));
        corIndex = find(strcmpi('coronal',viewC));
        legIndex = find(strcmpi('legend',viewC));
        
        orderV = [transIndex(:)', sagIndex(:)', corIndex(:)', legIndex(:)'];
        
        stateS.handle.CERRAxis = stateS.handle.CERRAxis(orderV);
        stateS.handle.CERRAxisLabel1 = stateS.handle.CERRAxisLabel1(orderV);
        stateS.handle.CERRAxisLabel2 = stateS.handle.CERRAxisLabel2(orderV);
        stateS.handle.CERRAxisLabel3 = stateS.handle.CERRAxisLabel3(orderV);
        stateS.handle.CERRAxisLabel4 = stateS.handle.CERRAxisLabel4(orderV);
        stateS.handle.CERRAxisScale1 = stateS.handle.CERRAxisScale1(orderV);
        stateS.handle.CERRAxisScale2 = stateS.handle.CERRAxisScale2(orderV);
        stateS.handle.CERRAxisTicks1 = stateS.handle.CERRAxisTicks1(orderV,:);
        stateS.handle.CERRAxisTicks2 = stateS.handle.CERRAxisTicks2(orderV,:);
        stateS.handle.CERRAxisPlnLocSdw = stateS.handle.CERRAxisPlnLocSdw(orderV);
        stateS.handle.CERRAxisPlnLoc = stateS.handle.CERRAxisPlnLoc(orderV);
        stateS.handle.aI = stateS.handle.aI(orderV);
        %stateS.handle.CERRAxisPlaneLocator1 = stateS.handle.CERRAxisPlaneLocator1(orderV);
        %stateS.handle.CERRAxisPlaneLocator2 = stateS.handle.CERRAxisPlaneLocator2(orderV);
        
        for i = 1:length(stateS.handle.CERRAxis)
            setAxisInfo(stateS.handle.CERRAxis(i),'doseSets',stateS.doseSet,...
                'structureSets',stateS.structSet,'scanSets',stateS.scanSet,...
                'scanSelectMode', 'auto','doseSelectMode', 'auto',...
                'structSelectMode','auto');
            setappdata(stateS.handle.CERRAxis(i),'compareMode',[]);
        end
        stateS.layout = stateS.Oldlayout;
        stateS.Oldlayout = [];
        stateS.CTDisplayChanged = 1;
        sliceCallBack('resize');
        CERRRefresh
        %hScanCompare = findobj('tag','scanCompareMenu');
        %set(hScanCompare,'checked','off')        
        
end
