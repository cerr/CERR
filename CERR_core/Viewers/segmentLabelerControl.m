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
hAxis = stateS.handle.CERRAxis(stateS.currentAxis);
%hAxis = stateS.handle.CERRAxis(1);
hFig = stateS.handle.CERRSliceViewer;
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
                
                ud = stateS.handle.controlFrameUd ;
          
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
                %ud.handles.objectPopup = uicontrol(hFig, 'style', 'popupmenu', 'units', units, 'position', absPos([.35 .84 .6 .05], posFrame), 'string', {'Select'}, 'tag', 'segmentLabelerControlItem', 'callback', 'segmentLabelerControl(''segmentLabeler'', ''selectLabelObject'')', 'enable', 'on');
                strC = {'Select',planC{indexS.segmentLabel}.name};
                ud.handles.objectPopup = uicontrol(hFig, 'style', 'popupmenu',...
                    'units', units, 'position', absPos([.35 .84 .6 .05], posFrame),...
                    'string', strC, 'tag', 'segmentLabelerControlItem',...
                    'callback', 'segmentLabelerControl(''segmentLabeler'', ''LabelObjectSelected'')',...
                    'enable', 'on');
                
                ud.handles.objectCreateButton  = uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', absPos([.6 .76 .35 .05], posFrame), 'string', 'Create', 'tag', 'segmentLabelerControlItem', 'callback', 'segmentLabelerControl(''segmentLabeler'', ''newObject'')');
                
                
                %Displays the associatedStruct for current Segment Label Object.
                ud.handles.assocStructText = uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, 'position', absPos([.05 .63 .25 .05], posFrame), 'string', 'Struct:', 'tag', 'segmentLabelerControlItem', 'horizontalAlignment', 'left');
                ud.handles.assocstructEdit  = uicontrol(hFig, 'style', 'edit', 'enable', 'off' , 'units', units, 'position', absPos([.37 .63 .55 .05], posFrame), 'string', 'No Structs', 'tag', 'segmentLabelerControlItem','enable', 'off', 'horizontalAlignment', 'left');
                
                
                %Controls to create new Label.
%                 ud.handles.labelNewEdit = uicontrol(hFig, 'style', 'edit', 'units', units, 'position', absPos([.35 .55 .6 .05], posFrame), 'string', '', 'tag', 'segmentLabelerControlItem', 'callback', 'segmentLabelerControl(''segmentLabeler'', ''renameLabel'')', 'enable', 'off', 'horizontalAlignment', 'left');
                ud.handles.labelNewText = uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, 'position', absPos([.05 .55 .26 .05], posFrame), 'string', 'Labels:', 'tag', 'segmentLabelerControlItem', 'horizontalAlignment', 'left');
                 
%                 ud.handles.labelNewButton  = uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', absPos([.6 .49 .35 .05], posFrame), 'string', 'New Label', 'tag', 'segmentLabelerControlItem','enable', 'off', 'callback', 'segmentLabelerControl(''segmentLabeler'', ''createLabel'')');
                 
                ud.handles.labelList = uicontrol(hFig, 'style', 'listbox',...
                    'units', units, 'position',absPos([.05 .30 .87 .25],...
                    posFrame),'string','Label List' ,'tag',...
                    'segmentLabelerControlItem',...
                    'Callback','segmentLabelerControl(''segmentLabeler'', ''LabelItemClicked'')');
                
                LabelC = initLabelC;
                ColorM = initColorM;
                
                pre = '<HTML><FONT color="';
                post = '</FONT></HTML>';
                
                listboxStr = cell(numel( LabelC ),1);
                
                for i = 1:numel(LabelC)
                    str = [pre rgb2hex( ColorM(i,:) ) '">' LabelC{i} post];
                    listboxStr{i} = str;
                end
                
                set(ud.handles.labelList,'string',listboxStr,'enable','on',...
                    'value',length(listboxStr))
                                
                ud.handles.hV = gobjects(0);
                
                set(hFrame, 'userdata', ud);
                
                
            case 'LabelItemClicked'
                
                % code to create/update labels here
                
                
            case 'motionInFigure'
                %                 if (stateS.segmentLabelerState ==1)
                hAxis = stateS.handle.CERRAxis(stateS.currentAxis);
                labelObjS = getappdata(hAxis,'labelObjS');
                if isempty(labelObjS)
                    return;
                end
                strNum = getAssociatedStr(labelObjS.assocStructUID);
                
                if planC{indexS.structures}(strNum).visible                    
                    
                    hV = stateS.handle.aI(stateS.currentAxis).lineHandlePool.lineV(stateS.handle.aI(stateS.currentAxis).structureGroup.handles);
                    
                    set(hV,'lineWidth',stateS.optS.structureThickness)
                    setappdata(hAxis, 'segmentSelected', 0)                                       
                    
                    segToVoxIndexM = getappdata(hAxis, 'segToVoxIndexM');
                    if isempty(segToVoxIndexM)
                        return;
                    end
                    [currSegment,xV,yV] = getCurrentSegment(segToVoxIndexM);
                                        
                    if (currSegment)       
                        hAxis.UIContextMenu.Visible = 'off';
                        if (length(currSegment)>1)
                            return;
                        end
                        set(stateS.handle.aI(stateS.currentAxis).lineHandlePool.lineV...
                            (stateS.handle.aI(stateS.currentAxis).structureGroup.handles(currSegment)),...
                            'LineWidth',stateS.optS.structureThickness+2);                       
                    end
                    
                end
                
                
            case 'update_menu'
                hAxis = stateS.handle.CERRAxis(stateS.currentAxis);
                hFig = stateS.handle.CERRSliceViewer;
                vMenu = gcbo;
                ud = get(hFrame, 'userdata');
                labelObjS = getappdata(hAxis,'labelObjS');
                if isempty(labelObjS)
                    return;
                end
                segToVoxIndexM = getappdata(hAxis, 'segToVoxIndexM');
                [currSegment,xV,yV] = getCurrentSegment(segToVoxIndexM);                
                setappdata(hAxis,'currentSeg',currSegment)
                
                 %Wipe out old submenus.
                 kids = get(ud.handles.vMenu, 'children');
                 delete(kids);
                 labelC = initLabelC;% saved in ud in beginning, when new label obj created or selected.   also initi context menu here and store handle to ud
                 
                 if (currSegment)
                     for i=1:length(labelC)
                         uimenu(ud.handles.vMenu,'Label', [labelC{i}], 'Callback',...
                             'segmentLabelerControl(''segmentLabeler'', ''labelAssigned'')',...
                             'userdata', {hAxis, i}, 'Visible', 'on');
                         
                     end                     
                     hAxis.UIContextMenu.Visible = 'on';
                     coord = get(hFig,'CurrentPoint');
                     hAxis.UIContextMenu.Position = coord(1:2);                     
                 end
                
            case 'labelAssigned'
                ud = get(hFrame, 'userdata');
                if isempty(ud)
                    return;
                end
                labelSelected = get(gcbo, 'Label');
                
                hAxis = stateS.handle.CERRAxis(stateS.currentAxis);
                labelObjS = getappdata(hAxis,'labelObjS');               
                
                strNum = getAssociatedStr(labelObjS.assocStructUID);
                
                % Scan, structure and slice index
                scanSet = getStructureAssociatedScan(strNum);
                % Scan, structure and slice index
                [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(scanSet));
                %Get the view/coord in case of linked axes.
                [view, coord] = getAxisInfo(hAxis, 'view', 'coord');
                
                sliceNum = findnearest(coord, zV);
     
                currentSeg = getappdata(hAxis,'currentSeg');
                LabelC = initLabelC;
                ColorM = initColorM;
                labelObjS.valueS(sliceNum).segments(currentSeg).index =  find(strcmp(LabelC,labelSelected));
                labelColor = ColorM(find(strcmp(LabelC,labelSelected)),:);
                set(ud.handles.hV(currentSeg),'MarkerFaceColor',labelColor);
                set(ud.handles.hV(currentSeg),'MarkerEdgeColor',labelColor);
                ud.handles.hV(currentSeg).Visible = 'on';
                ud.handles.hV(currentSeg).HitTest = 'off'; %test if req
                set(hFrame, 'userdata', ud);
                setappdata(hAxis, 'labelObjS', labelObjS);
                
            case 'newObject'
                
                prompt={'Enter the name of the Segment Label Object', 'Associated stucture number:'};
                name='New Segment Labeler Object';
                numlines=1;
                defaultanswer={'SegLabel 1','1'};
                ud = get(hFrame, 'userdata');
                
                options.Resize='on';
                options.WindowStyle='normal';
                options.Interpreter='tex';
                
                answer=inputdlg(prompt,name,numlines,defaultanswer,options);
                
                % get number of existing label objects
                nSegmentLabelObjects = length(planC{indexS.segmentLabel});
                                
                %Create a new nSegmentLabelObjects with selected associated structure.
                structNum = str2double(answer{2});
                if isempty(structNum)
                    return;
                end
                
                %Insert the new obj at the end of the list.
                newLabelObjectS = newSegmentLabel(structNum, planC);
                
                %newLabelObjectS.segLabelUID = createUID('seglabel');
                newLabelObjectS.assocStructUID = planC{indexS.structures}(structNum).strUID;
                newLabelObjectS.name = answer{1};
                                
                strC = {'Select',planC{indexS.segmentLabel}.name};
                strC{end+1} = newLabelObjectS.name;
                set(ud.handles.objectPopup, 'string', strC, 'enable', 'on');
                structureName = planC{indexS.structures}(structNum).structureName;
                set(ud.handles.assocstructEdit, 'string', structureName, 'enable', 'off');
                set(ud.handles.objectPopup, 'Value', nSegmentLabelObjects+2);
                ud.assocScanSet = getStructureAssociatedScan(structNum);
                set(hFrame, 'userdata', ud);
                setappdata(hAxis, 'labelObjS', newLabelObjectS);
                segmentLabelerControl('segmentLabeler', 'refresh')
                
            case 'createLabel'
                ud = get(hFrame, 'userdata');
                if isempty(ud)
                    return;
                end
                
                name = get(ud.handles.labelCreateEdit, 'string');                
                
                planC{indexS.segmentLabel}(objUd.objNumsV(objNum)).objName = name;
                segmentLabelerControl('segmentLabeler', 'refresh')
                
            case 'LabelObjectSelected'
                ud = get(hFrame, 'userdata');
                if isempty(ud)
                    return;
                end
                currentObj = get(ud.handles.objectPopup, 'Value') - 1;
                if currentObj == 0
                    return;
                end
                % Reassign strings if toggling from new unsaved object
                strC = {'Select',planC{indexS.segmentLabel}.name};
                set(ud.handles.objectPopup, 'string', strC, 'enable', 'on');                
                
                labelObjS = planC{indexS.segmentLabel}(currentObj);
                setappdata(hAxis, 'labelObjS', labelObjS);
                
                structNum = getAssociatedStr(labelObjS.assocStructUID);
                structureName = planC{indexS.structures}(structNum).structureName;
                set(ud.handles.assocstructEdit, 'string', structureName, 'enable', 'off');
                ud.assocScanSet = getStructureAssociatedScan(structNum);
                set(hFrame, 'userdata', ud);
                
                % delete old handles and create new ones
                segmentLabelerControl('segmentLabeler', 'refresh')
                
                
            case 'save'
                ud = get(hFrame, 'userdata');
                hAxis = stateS.handle.CERRAxis(stateS.currentAxis);
                labelObjS = getappdata(hAxis,'labelObjS');
                %save this to planC
                currentObj = get(ud.handles.objectPopup, 'Value') - 1;
                if currentObj == 0
                    return;
                end
                %planC{indexS.segmentLabel}(currentObj) = labelObjS;
                planC{indexS.segmentLabel} = dissimilarInsert...
                    (planC{indexS.segmentLabel}, labelObjS, currentObj);
                planC{indexS.segmentLabel}(currentObj).labelC = initLabelC;
                planC{indexS.segmentLabel}(currentObj).labelColorM = initColorM;
                
            case 'cancel'
                %Finished labeling and wish to discard changes.
                
                ud = get(hFrame, 'userdata');
                hControlFrameItemV = findobj('tag', 'segmentLabelerControlItem');
                delete(hControlFrameItemV);
                if (size(ud.handles.hV) ~= 0)
                    delete(ud.handles.hV)
                end                
                                
                set(hFig, 'WindowButtonMotionFcn', '');
                stateS.segmentLabelerState = 0;             
               
                CERRStatusString('');
                
                %Re-enable right click menus;
                for i=1:length(stateS.handle.CERRAxis)
                    CERRAxisMenu(stateS.handle.CERRAxis(i));
                end     
                setappdata(hAxis,'labelObjS','')
                setappdata(hAxis,'currentSeg','')
                setappdata(hAxis,'segmentSelected','')
                
                sliceCallBack('refresh');
                                     
                
            case 'refresh'
                %called when label object selected or slice changed.
                                
                hAxis = stateS.handle.CERRAxis(stateS.currentAxis);
                axInd = hAxis == stateS.handle.CERRAxis;
                axisInfo = stateS.handle.aI(axInd);
                ud = get(hFrame, 'userdata');
                if isempty(ud)
                    return;
                end
                ColorM = initColorM;               
                
                %undo previous slice graphic handles first
                if (size(ud.handles.hV) ~= 0)
                    delete(ud.handles.hV)
                    ud.handles.hV = [];
                end
                
                [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(axisInfo.scanSets));
                slcNum = findnearest(axisInfo.coord, zV);
                
                labelObjS = getappdata(hAxis,'labelObjS');
                if isempty(labelObjS)
                    return;
                end
                strNum = getAssociatedStr(labelObjS.assocStructUID);
                numSegs = length(planC{indexS.structures}(strNum).contour(slcNum).segments);
                
                % segToVoxIndexM = getappdata(hAxis,'segToVoxIndexM');
                segToVoxIndexM = segmentToVoxel();
                if isempty(segToVoxIndexM)
                    return;
                end
                setappdata(hAxis,'segToVoxIndexM',segToVoxIndexM)
                
                %initialize all segments and assign color based on existing
                %index
                hV = gobjects(0);
                for i =1:numSegs
                    %pointsM = planC{indexS.structures}(strNum).contour(slcNum).segments(i).points;
                    ind = find(segToVoxIndexM(:,i),1,'first');
                    [currSegment,xV,yV] = getCurrentSegment(segToVoxIndexM,ind);
                    
                    if isempty(xV)
                        continue
                    end
                    hV(i) = plot(hAxis, xV, yV, '.');
                    hV(i).HitTest = 'off';
                    hV(i).MarkerSize = 12;
                    hV(i).Visible = 'off';
                    currentIndex = labelObjS.valueS(slcNum).segments(i).index;
                    if ~isempty(currentIndex)
                        labelColor = ColorM(currentIndex,:);
                        hV(i).Visible = 'on';
                        hV(i).MarkerFaceColor = labelColor;
                        hV(i).MarkerEdgeColor = labelColor;
                    end
                end
                
                ud.handles.hV = hV;
                
                 %Wipe out old submenus.
                kids = get(ud.handles.vMenu, 'children');
                delete(kids);
                labelC = initLabelC; 
                
                for i=1:length(labelC)
                    uimenu(ud.handles.vMenu,'Label', [labelC{i}], 'Callback',...
                        'segmentLabelerControl(''segmentLabeler'', ''labelAssigned'')',...
                        'userdata', {hAxis, i}, 'Visible', 'on');
                end
                
                
                set(ud.handles.vMenu, 'Visible', 'off');
                
                %Setup axis for motion.
                set(hFig, 'WindowButtonMotionFcn', 'segmentLabelerControl(''segmentLabeler'', ''motionInFigure'');');
                set(hFig, 'doublebuffer', 'on');
                
                set(hFrame, 'userdata', ud);
                
                return;
                
                
        end
        
end



%% function to get segment number for the new x,y point
function [currentSeg,xV,yV] = getCurrentSegment(segToVoxIndexM, ind)
% Get the current point from mouse hover
global stateS planC
indexS = planC{end};

% Scan, structure and slice index
hAxis = stateS.handle.CERRAxis(stateS.currentAxis);
labelObjS = getappdata(hAxis,'labelObjS');

strNum = getAssociatedStr(labelObjS.assocStructUID);

scanSet = getStructureAssociatedScan(strNum);
% Scan, structure and slice index
[xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(scanSet));
%Get the view/coord in case of linked axes.
[view, coord] = getAxisInfo(hAxis, 'view', 'coord');

sliceNum = findnearest(coord, zV);
scanNum = getAxisInfo(stateS.handle.CERRAxis(1),'scanSets');

numRows = planC{indexS.scan}(scanNum).scanInfo(strNum).sizeOfDimension1;
numCols = planC{indexS.scan}(scanNum).scanInfo(strNum).sizeOfDimension2;

% Get current mouse location
if ~exist('ind','var')
    cP = get(hAxis, 'currentPoint');
    x = cP(1,1);
    y = cP(1,2);
    
    
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
    
end

% Get values at this index
currentSeg = find(segToVoxIndexM(ind,:));

% Handle overlapping segments
count = 0;
rcM = [];
xV = [];
yV = [];
for segNum = currentSeg
    count = count + 1;
    allSegIndV = segToVoxIndexM(:,segNum) == 1;
    [rV,cV] = ind2sub([numRows,numCols],find(allSegIndV));
    rcM{count} = [rV(:) cV(:)];
end
if length(rcM) > 1
    rcM = setxor(rcM{1},rcM{2}, 'rows');
elseif length(rcM) == 1
    overlapV = sum(segToVoxIndexM(allSegIndV,:),2) > 1;    
    rcM = rcM{1};
    rcM(overlapV,:) = [];
end
if ~isempty(rcM)
    rV = rcM(:,1);
    cV = rcM(:,2);
    sV = sliceNum * rV .^ 0;
    [xV,yV] = mtoxyz(rV,cV,sV,scanNum,planC);
end

%% function to create the segment to voxel index matrix
function segToVoxIndexM = segmentToVoxel()
global stateS planC
indexS = planC{end};
hFrame = stateS.handle.controlFrame;
ud = get(hFrame, 'userdata');
hAxis = stateS.handle.CERRAxis(stateS.currentAxis);

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
    segToVoxIndexM = [];
    return;
end
%labelObjS = planC{indexS.segmentLabel}(currentObj);
hAxis = stateS.handle.CERRAxis(stateS.currentAxis);
labelObjS = getappdata(hAxis,'labelObjS');
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

% setappdata(hAxis,'segToVoxIndexM',segToVoxIndexM)

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
segmentLabelS.segLabelUID       = createUID('seglabel');
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
    'REAL_METASTESES', 'NORMAL_TISSUE', 'UNDETERMINED', 'MIXED',''};

function ColorM = initColorM

% ColorM = {'r'; 'g'; 'b'; 'm'; 'gold', };
ColorM = [1 0 0; 0 1 0; 0 0 1; 1 0 1; 1 0.875 0; 0.5765 0.4392 0.8588;...
    1 0.5 0.314; 0.42 0.56 0.14; 0.86 0.075 0.24];

