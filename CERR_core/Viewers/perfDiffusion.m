function perfDiffusion(command,varargin)
% perfDiffusion
% changes the display on CERR to a perfusion / diffusion viewing mode if there 
% are more than two scans present. The scans are unlinked, so if
% you move one scan other does not move.
%
% 12/16/2015
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
            %perfDiffusion('exit');            
        end
        hCSV = stateS.handle.CERRSliceViewer;
        %hCSVA = stateS.handle.CERRSliceViewerAxis;
        hCSVA = stateS.handle.CERRAxis(1);

        numScans = length(planC{indexS.scan});
        if numScans < 2
            warndlg('Scan Comparison tool requires 2 or more scans');
            return          
        end
        
        if stateS.layout ~= 9
            stateS.Oldlayout = stateS.layout;
            stateS.layout = 9;
        end        
                
        % Go to slice with structure
        axes(stateS.handle.CERRAxis(1))
        for i = 1:length(planC{indexS.structures}(1).contour)
            if ~isempty(planC{indexS.structures}(1).contour(i).segments)
                goto('SLICE',i)
                break;
            end
        end
        
        % Set scans, doses, views
        setAxisInfo(stateS.handle.CERRAxis(1),'scanSets',1,'scanSelectMode', 'manual');
        setAxisInfo(stateS.handle.CERRAxis(2),'scanSets',3,...
            'scanSelectMode', 'manual','doseSelectMode', 'manual','doseSets',[],...
            'structureSets',2,'xRange',[],'yRange',[],...
            'view','transverse');
        linkC = {'Linked', stateS.handle.CERRAxis(2)};
        % Use stateS.handle.aI directly inistead of setAxisInfo since it
        % follows the linked axis.
        stateS.handle.aI(3).scanSets = 4;
        stateS.handle.aI(3).doseSets = [];
        stateS.handle.aI(3).structureSets = 2;
        stateS.handle.aI(3).scanSelectMode = 'manual';
        stateS.handle.aI(3).doseSelectMode = 'manual';
        stateS.handle.aI(3).xRange = linkC;
        stateS.handle.aI(3).yRange = linkC;
        stateS.handle.aI(3).view = linkC;
        stateS.handle.aI(3).coord = linkC;        
        setAxisInfo(stateS.handle.CERRAxis(5),'scanSets',6,...
            'scanSelectMode', 'manual','doseSelectMode',...
            'manual','doseSets',[],'structureSets',2,'xRange',[],'yRange',[],...
            'view','transverse');
%         linkC = {'Linked', stateS.handle.CERRAxis(5)};
%         stateS.handle.aI(6).scanSets = 5;
%         stateS.handle.aI(6).scanSelectMode = 'manual';
%         stateS.handle.aI(6).doseSelectMode = 'manual';
%         stateS.handle.aI(6).xRange = linkC;
%         stateS.handle.aI(6).yRange = linkC;
%         stateS.handle.aI(6).view = linkC;
%         stateS.handle.aI(6).coord = linkC;                
        setAxisInfo(stateS.handle.CERRAxis(6),'scanSets',5,...
            'scanSelectMode', 'manual','doseSelectMode',...
            'manual','doseSets',[],'structureSets',2,'xRange',[],...
            'yRange',[],'view','transverse');
        
        % Do not show plane locators
        stateS.showPlaneLocators = 0;
        
        % Got to the slice with structure
        for slc = 1:length(planC{indexS.structures}.contour)
            if ~isempty(planC{indexS.structures}.contour(slc).segments.points)
                setAxisInfo(stateS.handle.CERRAxis(1),'coord',...
                    planC{indexS.structures}.contour(slc).segments.points(1,3));
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
            if iscell(view)
                sliceCallBack('selectaxisview', hAxis, 'delete view');
            else
                viewC{i} = view;
            end            
        end
        
%         % Set Axes order
%         for i = 1:length(stateS.handle.CERRAxis)
%             viewC{i} = getAxisInfo(stateS.handle.CERRAxis(i),'view');
%         end
        
        transIndex = strmatch('transverse',viewC);
        sagIndex = strmatch('sagittal',viewC);
        corIndex = strmatch('coronal',viewC);
        legIndex = strmatch('legend',viewC);
        
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
                'structureSets',stateS.structSet,'scanSets',stateS.scanSet);
            setappdata(stateS.handle.CERRAxis(i),'compareMode',[]);
        end
        stateS.layout = stateS.Oldlayout;
        stateS.Oldlayout = [];
        sliceCallBack('resize');
        %CERRRefresh
        %hScanCompare = findobj('tag','scanCompareMenu');
        %set(hScanCompare,'checked','off')        
        
end
