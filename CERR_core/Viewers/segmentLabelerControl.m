function varargout = segmentLabelerControl(command, varargin)
%"segmentLabelerControl"
%   Master control function for Segment Labeling in CERR.
%

%Usage:
%   segmentLabelerControl('init')
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

% Default axis to the current axis
hAxis = stateS.handle.CERRAxis(1);

hFig = stateS.handle.CERRSliceViewer;

posFig = get(hFig, 'position');
posFig(1) = 0; posFig(2) = 0;

hFrame = stateS.handle.controlFrame;

posFrame = get(hFrame, 'position');

units = 'pixels';



switch command
    case 'segmentLabeler'
        switch (varargin{1})
            case 'init'
                % Get out of other modes, if any
                controlFrame('default');
                stateS.segmentLabelerState = 1;
                
                ud = get(hFrame, 'userdata');
                hAxis = stateS.handle.CERRAxis(1);
                hFig = stateS.handle.CERRSliceViewer;
                axInd = hAxis == stateS.handle.CERRAxis;
                axisInfo = stateS.handle.aI(axInd);
                
                scanSet = getStructureAssociatedScan(1);
                [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(axisInfo.scanSets));
                
                sliceNum = findnearest(axisInfo.coord, zV);
                axisInfo.coord         = zV(sliceNum);
                axisInfo.scanSets       = scanSet;
                
                numStructs = length(planC{indexS.structures});
                assocSacnV = getStructureAssociatedScan(1:numStructs);
                structsV = assocSacnV == scanSet;
                structNumV = find(structsV);
                if isempty(structNumV)
                    initStructNum = [];
                else
                    initStructNum = structNumV(1);
                end
                
                setappdata(hAxis, 'numRows',planC{indexS.scan}(scanSet).scanInfo(sliceNum).sizeOfDimension1);
                setappdata(hAxis, 'numCols',planC{indexS.scan}(scanSet).scanInfo(sliceNum).sizeOfDimension2);
                setappdata(hAxis, 'slStruct', initStructNum);
                
                % Get scan associated with the current axis and find out if
                % it has associated stuctures
                scanSet = stateS.handle.aI(stateS.currentAxis).scanSets;
                structIndx = getStructureSetAssociatedScan(scanSet);
                if isempty(structIndx)
                    
                    msgString = 'This scan has no associated structures, please select a different scan';
                    msgbox(msgString,'Confirm Window Selection');
                    return;
                    
                end
                
                
                %Title
                ud.handles.title = uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, 'position', absPos([.05 .94 .9 .05], posFrame), 'string', 'Segment Labeler', 'tag', 'segmentLabelerControlItem', 'horizontalAlignment', 'center', 'FontWeight', 'Bold');
                
                ud.handles.saveButton = uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', absPos([.1 .04 .35 .05], posFrame), 'string', 'Save', 'tag', 'segmentLabelerControlItem', 'callback', 'segmentLabelerControl(''segmentLabeler'', ''save'')');
                ud.handles.abortButton = uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', absPos([.55 .04 .35 .05], posFrame), 'string', 'Cancel', 'tag', 'segmentLabelerControlItem', 'callback', 'segmentLabelerControl(''segmentLabeler'', ''cancel'')');
                
                %Context Menu
                ud.handles.vMenu = uicontextmenu('Callback', 'segmentLabelerControl(''segmentLabeler'', ''update_menu'');', 'userdata', hAxis, 'Tag', 'SegmentLabelerMenu', 'parent', hFig, 'Visible', 'off', 'hittest', 'off');
                set(hAxis, 'UIContextMenu', ud.handles.vMenu);
                set(ud.handles.vMenu, 'Visible', 'off');
                
                %Controls to select Label Object to edit.
                ud.handles.objectText = uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, 'position', absPos([.05 .84 .25 .05], posFrame), 'string', 'Object:', 'tag', 'segmentLabelerControlItem', 'horizontalAlignment', 'left');
                ud.handles.objectPopup = uicontrol(hFig, 'style', 'popupmenu', 'units', units, 'position', absPos([.35 .84 .6 .05], posFrame), 'string', {'Select'}, 'tag', 'segmentLabelerControlItem', 'callback', 'segmentLabelerControl(''segmentLabeler'', ''selectLabelObject'')', 'enable', 'on');
                
                ud.handles.objectCreateButton  = uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', absPos([.6 .76 .35 .05], posFrame), 'string', 'Create', 'tag', 'segmentLabelerControlItem', 'callback', 'segmentLabelerControl(''segmentLabeler'', ''newObject'')');
                
                
                %Displays the associatedStruct for current Segment Label Object.
                ud.handles.assocStructText = uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, 'position', absPos([.05 .63 .25 .05], posFrame), 'string', 'Struct:', 'tag', 'segmentLabelerControlItem', 'horizontalAlignment', 'left');
                ud.handles.assocstructEdit  = uicontrol(hFig, 'style', 'edit', 'enable', 'off' , 'units', units, 'position', absPos([.37 .63 .55 .05], posFrame), 'string', 'No Structs', 'tag', 'segmentLabelerControlItem','enable', 'off', 'horizontalAlignment', 'left');
                
                
                %Controls to create new Label.
                ud.handles.labelNewEdit = uicontrol(hFig, 'style', 'edit', 'units', units, 'position', absPos([.35 .55 .6 .05], posFrame), 'string', '', 'tag', 'segmentLabelerControlItem', 'callback', 'segmentLabelerControl(''segmentLabeler'', ''renameLabel'')', 'enable', 'off', 'horizontalAlignment', 'left');
                ud.handles.labelNewText = uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, 'position', absPos([.05 .55 .26 .05], posFrame), 'string', 'Label:', 'tag', 'segmentLabelerControlItem', 'horizontalAlignment', 'left');
                
                ud.handles.labelNewButton  = uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', absPos([.6 .49 .35 .05], posFrame), 'string', 'New Label', 'tag', 'segmentLabelerControlItem','enable', 'off', 'callback', 'segmentLabelerControl(''segmentLabeler'', ''createLabel'')');
                
                ud.handles.labelList = uicontrol(hFig, 'style', 'listbox', 'units', units, 'position',absPos([.05 .20 .60 .25], posFrame),'string','Label List' ,'tag', 'segmentLabelerControlItem', 'Callback','segmentLabelerControl(''segmentLabeler'', ''populateList'')');
                
                for i=1:length(stateS.handle.CERRAxis)
                    setappdata(stateS.handle.CERRAxis(i),'oldCoord',getAxisInfo(stateS.handle.CERRAxis(i),'coord'))
                    
                end
                
                ud.handles.hV = gobjects(0);
                
                set(hFrame, 'userdata', ud);
                %                 segmentLabelerControl('segmentLabeler', 'refresh');
                
                
            case 'motionInFigure'
                %                 if (stateS.segmentLabelerState ==1)
                if ~isempty({planC{indexS.segmentLabel}.labelC})
                    % Get scan associated with the current axis
                    scanSet = stateS.handle.aI(stateS.currentAxis).scanSets;
                    
                    
                    
                    hAxis = stateS.handle.CERRAxis(1);
                    hV = stateS.handle.aI(1).lineHandlePool.lineV(stateS.handle.aI(1).structureGroup.handles);
                    
                    set(hV,'lineWidth',stateS.optS.structureThickness)
                    setappdata(hAxis, 'segmentSelected', 0)
                                       
                    
                    segToVoxIndexM = getappdata(hAxis, 'segToVoxIndexM');
                    currSegment = getCurrentSegment(segToVoxIndexM);
                                        
                    if (currSegment)                        
                        if (length(currSegment)>1)
                            %if(segmentMaskVal ==0)
                            return;
                        end
                        set(stateS.handle.aI(1).lineHandlePool.lineV...
                            (stateS.handle.aI(1).structureGroup.handles(currSegment)),'LineWidth',stateS.optS.structureThickness+2);
                       
                    end
                    
                end
                
                
            case 'update_menu'
                hAxis = stateS.handle.CERRAxis(1);
                hFig = stateS.handle.CERRSliceViewer;
                vMenu = gcbo;
                ud = get(hFrame, 'userdata');
                
                segToVoxIndexM = getappdata(hAxis, 'segToVoxIndexM');
                currSegment = getCurrentSegment(segToVoxIndexM);
                setappdata(hAxis,'currentSeg',currSegment)
                
                 %Wipe out old submenus.
                kids = get(ud.handles.vMenu, 'children');
                delete(kids);
                labelC = initLabelC;% saved in ud in beginning, when new label obj created or selected.   also initi context menu here and store handle to ud
                
                if ~isempty(planC{indexS.segmentLabel})
                    if (currSegment)   
                        for i=1:length(labelC)
                            m1 = uimenu(ud.handles.vMenu,'Label', [labelC{i}], 'Callback', 'segmentLabelerControl(''segmentLabeler'', ''labelAssigned'')', 'userdata', {hAxis, i}, 'Visible', 'on');
                            %                         uimenu(vMenu, 'Label', [labelC{i}], 'Callback', 'segmentLabelerControl(''segmentLabeler'', ''labelAssigned'')', 'userdata', {hAxis, i});
                            
                        end
                        
                        hAxis.UIContextMenu.Visible = 'on';
                        coord = get(hFig,'CurrentPoint');
                        hAxis.UIContextMenu.Position = coord(1:2);
                        
                        
                        
                    end
                end
                
            case 'labelAssigned'
                ud = get(hFrame, 'userdata');
                if isempty(ud)
                    return;
                end
                labelSelected = get(gcbo, 'Label');
                
                hAxis = stateS.handle.CERRAxis(1);
                
                % Scan, structure and slice index
                scanSet = getStructureAssociatedScan(1);
                % Scan, structure and slice index
                [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(scanSet));
                %Get the view/coord in case of linked axes.
                [view, coord] = getAxisInfo(hAxis, 'view', 'coord');
                
                sliceNum = findnearest(coord, zV);
     
                currentSeg = getappdata(hAxis,'currentSeg');
%                 currentObj = get(ud.handles.objectPopup, 'Value') - 1;
%                 if currentObj == 0
%                     return;
%                 end
                labelObjS = getappdata(hAxis,'labelObjS');
                
%                 strNum = getAssociatedStr(labelObjS.assocStructUID);
                %                 segToVoxIndexM = getappdata(hAxis, 'segToVoxIndexM');
                %                 currSegment = getCurrentSegment(segToVoxIndexM);
%                 segToVoxIndexM = getappdata(hAxis, 'segToVoxIndexM');
                %                 pointsM = planC{indexS.structures}(strNum).contour(slSlice).segments(currSegment).points;
                LabelC = initLabelC;
                ColorM = initColorM;
                labelObjS.valueS(sliceNum).segments(currentSeg).index =  find(strcmp(LabelC,labelSelected));
                labelColor = ColorM{find(strcmp(LabelC,labelSelected))};
                %                 ud.handles.hV(currsegment) = fill(pointsM(:,1), pointsM(:,2), labelColor);                
%                  ud.handles.hV = plot([colV, colV(1)],[rowV, rowV(1)],'rs-');
                set(ud.handles.hV(currentSeg),'Color',labelColor)
                ud.handles.hV(currentSeg).MarkerEdgeColor = 'none';
                ud.handles.hV(currentSeg).Visible = 'on';
                %                 ud.handles.hV = stateS.handle.aI(1).lineHandlePool.lineV(stateS.handle.aI(1).structureGroup.handles(currsegment)).Color;
                %                 set(stateS.handle.aI(1).lineHandlePool.lineV(stateS.handle.aI(1).structureGroup.handles(currsegment)),'color',labelColor);
                ud.handles.hV(currentSeg).HitTest = 'off'; %test if req
                set(hFrame, 'userdata', ud);
                setappdata(hAxis, 'labelObjS', labelObjS);
                
            case 'newObject'
                
                hAxis = stateS.handle.CERRAxis(stateS.currentAxis);
                prompt={'Enter the name of the Segment Label Object', 'Associated stucture number:'};
                name='New Segment Labeler Object';
                numlines=1;
                defaultanswer={'SL1','1'};
                ud = get(hFrame, 'userdata');
                scanSet = getAxisInfo(stateS.handle.CERRAxis(stateS.currentAxis),'scanSets');
                numSlices = size(getScanArray(planC{indexS.scan}(scanSet)), 3);
                
                options.Resize='on';
                options.WindowStyle='normal';
                options.Interpreter='tex';
                
                answer=inputdlg(prompt,name,numlines,defaultanswer,options);
                
                nSegmentLabelObjects = length(planC{indexS.segmentLabel});
                toAdd = nSegmentLabelObjects + 1;
                
                %Create a new nSegmentLabelObjects with selected associated structure.
                structNum = str2double(answer(2));
                if isempty(structNum)
                    return;
                end
                %add check for duplicates - just give warning message but
                %allow
                
                %Insert the new obj at the end of the list.
                newLabelObject = newSegmentLabel(structNum, planC);
                
                newLabelObject.labelUID = createUID('label');
                newLabelObject.assocStructUID = planC{indexS.structures}(structNum).strUID;
                newLabelObject.name = answer(1);
                planC{indexS.segmentLabel} = dissimilarInsert(planC{indexS.segmentLabel}, newLabelObject, toAdd);
                
                labelC = initLabelC;
                planC{indexS.segmentLabel}(end).labelC = labelC;
                
                strC = get(ud.handles.objectPopup, 'string');
                strC(end+1) = [newLabelObject.name];
                set(ud.handles.objectPopup, 'string', strC, 'enable', 'on');
                set(ud.handles.assocstructEdit, 'string', structNum, 'enable', 'off');
                %                  set(ud.handles.labelNewEdit, 'enable', 'on');
                %                  set(ud.handles.labelNewButton, 'enable', 'on');
                val = get(ud.handles.objectPopup, 'Value');
                set(ud.handles.objectPopup, 'Value', val+1);
%                 segmentLabelerControl('segmentLabeler', 'refresh')
                segmentLabelerControl('segmentLabeler', 'selectLabelObject')
                ud.assocScanSet = getStructureAssociatedScan(structNum);
                set(hFrame, 'userdata', ud);
                
                
            case 'createLabel'
                ud = get(hFrame, 'userdata');
                if isempty(ud)
                    return;
                end
                
                name = get(ud.handles.labelCreateEdit, 'string');
                
                %get current labelObject
                objNameC = get(ud.handles.objectPopup, 'string');
                
                
                planC{indexS.segmentLabel}(objUd.objNumsV(objNum)).objName = name;
                segmentLabelerControl('segmentLabeler', 'refresh')
                
            case 'selectLabelObject'
                
                ud = get(hFrame, 'userdata');
                if isempty(ud)
                    return;
                end
                if (size(ud.handles.hV) ~= 0)
                    delete(ud.handles.hV)
                end
                segToVoxIndexM = segmentToVoxel();
                
                %create context menu                
                %Wipe out old submenus.
                kids = get(ud.handles.vMenu, 'children');
                delete(kids);
                labelC = initLabelC;% saved in ud in beginning, when new label obj created or selected.   also initi context menu here and store handle to ud
                
                if ~isempty(planC{indexS.segmentLabel})
                    for i=1:length(labelC)
                        m1 = uimenu(ud.handles.vMenu,'Label', [labelC{i}], 'Callback', 'segmentLabelerControl(''segmentLabeler'', ''labelAssigned'')', 'userdata', {hAxis, i}, 'Visible', 'off');
                        %                         uimenu(vMenu, 'Label', [labelC{i}], 'Callback', 'segmentLabelerControl(''segmentLabeler'', ''labelAssigned'')', 'userdata', {hAxis, i});
                        
                    end
                end
                set(ud.handles.vMenu, 'Visible', 'off');
                %Setup axis for motion.
                set(hFig, 'WindowButtonMotionFcn', 'segmentLabelerControl(''segmentLabeler'', ''motionInFigure'');');
                set(hFig, 'doublebuffer', 'on');
                
                currentObj = get(ud.handles.objectPopup, 'Value') - 1;
                if currentObj == 0
                    return;
                end
                labelObjS = planC{indexS.segmentLabel}(currentObj);
                setappdata(hAxis, 'labelObjS', labelObjS);
                segmentLabelerControl('segmentLabeler', 'slcChange')
                segmentLabelerControl('segmentLabeler', 'refresh')
                
                return;
                
                
            case 'save'
                hAxis = stateS.handle.CERRAxis(1);
                
                
                
            case 'cancel'
                ud = get(hFrame, 'userdata');
                hControlFrameItemV = findobj('tag', 'segmentLabelerControlItem');
                delete(hControlFrameItemV);
                if (size(ud.handles.hV) ~= 0)
                    delete(ud.handles.hV)
                end
                %Finished labeling and wish to discard changes.
                hAxis = varargin{1};               
                                
                set(hFig, 'WindowButtonMotionFcn', '');
                stateS.segmentLabelerState = 0;             
               
                CERRStatusString('');
                
                %Re-enable right click menus;
                for i=1:length(stateS.handle.CERRAxis)
                    CERRAxisMenu(stateS.handle.CERRAxis(i));
                end                
                              
                try
                    hFrame = stateS.handle.controlFrame;
                    ud = get(hFrame, 'userdata');
                    delete(ud.handle.hV)
                end
                
                sliceCallBack('refresh');
                     
                hControlFrameItemV = findobj('tag', 'controlFrameItem');
                delete(hControlFrameItemV);
                controlFrame('default');
                
                
            case 'slcChange'
                hAxis = stateS.handle.CERRAxis(1);
                axInd = hAxis == stateS.handle.CERRAxis;
                axisInfoS = stateS.handle.aI(axInd);
                ud = get(hFrame, 'userdata');
                if isempty(ud)
                    return;
                end
                
                                             
                hV = gobjects(0);
                LabelC = initLabelC;
                ColorM = initColorM;
                
                %undo previous slice graphic handles first
                if (size(ud.handles.hV) ~= 0)
                    delete(ud.handles.hV)
                end
                currentObj = get(ud.handles.objectPopup, 'Value') - 1;
                if currentObj == 0
                    return;
                end
              
                segToVoxIndexM = segmentToVoxel();
%                 labelObjS = planC{indexS.segmentLabel}(currentObj);
                labelObjS = getappdata(hAxis,'labelObjS');
                strNum = getAssociatedStr(labelObjS.assocStructUID);
                ud.assocScanSet = getStructureAssociatedScan(strNum);
                [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(ud.assocScanSet));
                slcNum = findnearest(axisInfoS.coord, zV);
                
                if ~isempty(labelObjS)
                    
                    numSegs = length(planC{indexS.structures}(strNum).contour(slcNum).segments);
                    for i =1:numSegs
                        
                        pointsM = planC{indexS.structures}(strNum).contour(slcNum).segments(i).points;
                        %create plot object
                        if ~isempty(pointsM)
                            hV(i) = plot(pointsM(:,1), pointsM(:,2));
                            hV(i).Visible = 'off';
                        end
                                                
                    end
                                  
                end
                ud.handles.hV = hV;
                set(hFrame, 'userdata', ud);
                segmentLabelerControl('segmentLabeler', 'refresh')
                
                
                
            case 'refresh'
                %called when label object selected, and when slice changed.
                                
                hAxis = stateS.handle.CERRAxis(1);
                axInd = hAxis == stateS.handle.CERRAxis;
                axisInfo = stateS.handle.aI(axInd);
                ud = get(hFrame, 'userdata');
                if isempty(ud)
                    return;
                end
                ColorM = initColorM;
%                 currentObj = get(ud.handles.objectPopup, 'Value') - 1;
%                 if currentObj == 0
%                     return;
%                 end
                
                [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(axisInfo.scanSets));
                slcNum = findnearest(axisInfo.coord, zV);
                
                segToVoxIndexM = segmentToVoxel();
%                 labelObjS = planC{indexS.segmentLabel}(currentObj);
                labelObjS = getappdata(hAxis,'labelObjS');
                strNum = getAssociatedStr(labelObjS.assocStructUID);
                numSegs = length(planC{indexS.structures}(strNum).contour(slcNum).segments);
                
                %initialize all segments and assign color based on existing
                %index
                for i =1:numSegs
                    if ~isempty(labelObjS.valueS(slcNum).segments(i).index)
                        pointsM = planC{indexS.structures}(strNum).contour(slcNum).segments(i).points;
                        currentIndex = labelObjS.valueS(slcNum).segments(i).index;
                        labelColor = ColorM{currentIndex};
                        %hV(i) = fill(pointsM(:,1), pointsM(:,2), labelColor);
                        hV(i) = plot(pointsM(:,1), pointsM(:,2));
                        hV(i).HitTest = 'off';
%                         hV(i).MarkerFaceColor = labelColor;
                        
                    end
                end
                
                labelC = initLabelC;
                set(ud.handles.labelList,'string',labelC);
                
                return;
                
                
        end
        
end



%% function to get segment number for the new x,y point
function currentSeg = getCurrentSegment(segToVoxIndexM)
% Get the current point from mouse hover
global stateS planC
indexS = planC{end};
hAxis = stateS.handle.CERRAxis(1);
hFrame = stateS.handle.controlFrame;
ud = get(hFrame, 'userdata');
currentObj = get(ud.handles.objectPopup, 'Value') - 1;
if currentObj == 0
    return;
end

labelObjS = planC{indexS.segmentLabel}(currentObj);
cP = get(hAxis, 'currentPoint');
x = cP(1,1);
y = cP(1,2);

% Scan, structure and slice index
scanSet = getStructureAssociatedScan(1);
% Scan, structure and slice index
[xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(scanSet));
%Get the view/coord in case of linked axes.
[view, coord] = getAxisInfo(hAxis, 'view', 'coord');

sliceNum = findnearest(coord, zV);
scanNum = getAxisInfo(stateS.handle.CERRAxis(1),'scanSets');
% strNum = get(ud.handles.assocstructText, 'value');
strNum = getAssociatedStr(labelObjS.assocStructUID);

% numSegs = length(planC{indexS.structures}(strNum).contour(sliceNum).segments);
% disp(numSegs);
numRows = planC{indexS.scan}(scanNum).scanInfo(strNum).sizeOfDimension1;
numCols = planC{indexS.scan}(scanNum).scanInfo(strNum).sizeOfDimension2;


% To test which segment the current point belongs to
[r, c] = xytom(x, y, sliceNum, planC, scanNum);

r = round(r);
c = round(c);

% get the linear index
r(r<1) = 1;
c(c<1) = 1;
r(r>numRows) = numRows;
c(c>numCols) = numCols;
ind = sub2ind([numRows,numCols],r,c);



% Get values at this index
currentSeg = find(segToVoxIndexM(ind,:));

% if ~isempty(currentSeg)
%     structUID   = planC{indexS.structures}(strNum).structureName;
%     [rasterSegments, planC, isError]    = getRasterSegments(structUID);
%     [mask3M, uniqueSlices] = rasterToMask(rasterSegments, scanNum);
%     sliceMask = mask3M(:,:,sliceNum);
%     segmentMaskVal = sliceMask(ind);
%     setappdata(hAxis,'segmentMaskVal',segmentMaskVal)
%     
% end
%

%     sliceMask = mask3M(:,:,sliceNum);%add in ud this and matrix






%% function to create the segment to voxel index matrix
function segToVoxIndexM = segmentToVoxel()
global stateS planC
indexS = planC{end};
hFrame = stateS.handle.controlFrame;
ud = get(hFrame, 'userdata');
hAxis = stateS.handle.CERRAxis(1);

% if(~isempty(planC{indexS.segmentLabel}))


scanSet = getStructureAssociatedScan(1);
% Scan, structure and slice index
[xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(scanSet));
%Get the view/coord in case of linked axes.
[view, coord] = getAxisInfo(hAxis, 'view', 'coord');
if isempty(ud)
    return;
end
% scanSet = stateS.handle.aI(stateS.currentAxis).scanSets;
scanNum = getAxisInfo(stateS.handle.CERRAxis(1),'scanSets');
sliceNum = findnearest(coord, zV);
setappdata(hAxis, 'slSlice', sliceNum)
currentObj = get(ud.handles.objectPopup, 'Value') - 1;
if currentObj == 0
    return;
end
labelObjS = planC{indexS.segmentLabel}(currentObj);

strNum = getAssociatedStr(labelObjS.assocStructUID);

% Initialize a sparse matrix to record segment to voxel index

numSegs = length(planC{indexS.structures}(strNum).contour(sliceNum).segments);
numRows = planC{indexS.scan}(scanNum).scanInfo(strNum).sizeOfDimension1;
numCols = planC{indexS.scan}(scanNum).scanInfo(strNum).sizeOfDimension2;
numVoxs = numRows * numCols;
segToVoxIndexM = sparse(numVoxs,numSegs);

% Iterate over segments to populate the segment to voxel index matrix

for segNum = 1:numSegs
    pointsM = planC{indexS.structures}(strNum).contour(sliceNum).segments(segNum).points;
    if isempty(pointsM)
        continue;
    end
    [segRowV, segColV] = xytom(pointsM(:,1), pointsM(:,2), sliceNum, planC,scanNum);
    segRowV(segRowV<1) = 1;
    segColV(segColV<1) = 1;
    segRowV(segRowV>numRows) = numRows;
    segColV(segColV>numCols) = numCols;
    segM = polyFill(numRows, numCols, segRowV, segColV);
    segToVoxIndexM(:,segNum) = segM(:); %in ud, also slice mask.
end

setappdata(hAxis,'segToVoxIndexM',segToVoxIndexM)

%%
function segmentLabelS = newSegmentLabel(structNum, planC)
% - this should hapen for tempLabelObject, and save in planC when saving
global stateS

if ~exist('planC', 'var'); %wy
    global planC
end
hFrame = stateS.handle.controlFrame;
ud = get(hFrame, 'userdata');
indexS = planC{end};

scanSet = stateS.handle.aI(stateS.currentAxis).scanSets;

strNum = 1;

%Get the segmentLabeler template from initializeCERR.
segmentLabelS = initializeCERR('segmentLabel');

%Create and populate empty ValueS field.
try
    nSlices = size(getScanArray(planC{indexS.scan}(scanSet)), 3);
catch
    error('Cannot create new label if struct is not valid.');
    return
end

%Create empty name field.
segmentLabelName = '';

% segment.index = [];
% [valueS(1:nSlices).segment] = deal(segment);

%Assign these values to structure.
segmentLabelS(1).assocStructUID = planC{indexS.structures}(1).strUID;
segmentLabelS(1).labelUID       = createUID('label');
% segmentLabel(1).valueS         = valueS;
segmentLabelS(1).name           = segmentLabelName;

contourS = planC{indexS.structures}(structNum).contour;
for i = 1:nSlices
    contourS(i).segments = rmfield(contourS(i).segments,'points');
end
for i = 1:nSlices
    numSegs = length(planC{indexS.structures}(structNum).contour(i).segments);
    for j = 1:numSegs
        contourS(i).segments(j).index = [];
    end
end
segmentLabelS(1).valueS = contourS;
% planC{indexS.segmentLabel}(1).valueS = contourS;

function LabelC = initLabelC

LabelC = {
    'REAL_METASTESES', 'NORMAL_TISSUE', 'UNDETERMINED', 'MIXED'};

function ColorM = initColorM

ColorM = {
    'r'; 'g'; 'b'; 'm'};

