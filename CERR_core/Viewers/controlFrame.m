function controlFrame(command, varargin)
%"controlFrame"
%   Draw the CERR control frame for different modules.
%
%   Current Modules include:
%       Contouring Tools
%       Colorwash Options
%       Isodose Options
%       Registration Tools
%
%   JRA 6/4/04
%   LM DK 12/16/04 Modified existing Image fusion tool. Added rotation button.
%                   Checker board function. and auto registeration.
%   WY 06/08/08 reimplement the image fusion and append registration analysis
%Usage:
%   controlFrame(module, command)
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

hFig = stateS.handle.CERRSliceViewer;

posFig = get(hFig, 'position');
posFig(1) = 0; posFig(2) = 0;

hFrame = stateS.handle.controlFrame;

posFrame = get(hFrame, 'position');

units = 'pixels';

switch command
    
    case 'default'
        %Nothing, clear the box.  Also clear stateS.mode items for any controlFrame modules.
        if stateS.contourState %~isempty(findobj('string', 'Contouring', 'tag', 'controlFrameItem'))            
            
            contourControl('revert');
            
        %elseif ~isempty(findobj('string', 'Colorbar Options', 'tag', 'controlFrameItem'))
            
        %elseif ~isempty(findobj('string', 'Isodose Line Options', 'tag','controlFrameItem'))
            
        elseif stateS.imageRegistration % ~isempty(findobj('string', 'Image Fusion', 'tag', 'controlFrameItem'))
            controlFrame('fusion','exit');
            stateS.imageRegistration = 0;
        elseif stateS.rotateView % ~isempty(findobj('string', 'Rotate View Planes', 'tag', 'controlFrameItem'))
            controlFrame('rotate_axis','quit');
            stateS.rotateView = 0;
        elseif stateS.anotationDisplay %  ~isempty(findobj('string', 'Significant Images', 'tag', 'controlFrameItem'))
            controlFrame('ANNOTATION','quit');
            stateS.anotationDisplay = 0;
         elseif stateS.segmentLabelerState %  ~isempty(findobj('string', 'SegmentLabeler', 'tag', 'controlFrameItem'))
            segmentLabelerControl('segmentLabeler','cancel');
            stateS.segmentLabelerState = 0;
        end
        
        try
            delete(findobj('tag', 'controlFrameItem'));
        end
        
        %set(hFrame, 'userdata', []);
        stateS.handle.controlFrameUd = [] ;
        
    case 'contour'
        switch (varargin{1})
            case 'init'
                %Clear old controlFrame.
                %delete(findobj('tag', 'controlFrameItem'));
                
                ud = stateS.handle.controlFrameUd; 

                %Create subframes to separate controls into 3 sets.
                ud.handles.subframe1 = uicontrol(hFig, 'style', 'frame', 'enable', 'inactive' , 'units', units, 'position', absPos([.05 .66 .9 .005], posFrame), 'string', 'Contouring', 'tag', 'controlFrameItem', 'horizontalAlignment', 'center', 'FontWeight', 'Bold');
                ud.handles.subframe2 = uicontrol(hFig, 'style', 'frame', 'enable', 'inactive' , 'units', units, 'position', absPos([.05 .46 .9 .005], posFrame), 'string', 'Contouring', 'tag', 'controlFrameItem', 'horizontalAlignment', 'center', 'FontWeight', 'Bold');
                
                %Title
                ud.handles.title = uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, 'position', absPos([.05 .94 .9 .05], posFrame), 'string', 'Contouring', 'tag', 'controlFrameItem', 'horizontalAlignment', 'center', 'FontWeight', 'Bold');
                
                %Controls to select structure to edit.
                ud.handles.structText = uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, 'position', absPos([.05 .89 .25 .05], posFrame), 'string', 'Struct:', 'tag', 'controlFrameItem', 'horizontalAlignment', 'left');
                ud.handles.structPopup = uicontrol(hFig, 'style', 'popupmenu', 'units', units, 'position', absPos([.35 .89 .6 .05], posFrame), 'string', 'No Structs', 'tag', 'controlFrameItem', 'callback', 'controlFrame(''contour'', ''selectStruct'')', 'enable', 'off');
                
                %Controls to rename selected structure.
                ud.handles.structRenameEdit = uicontrol(hFig, 'style', 'edit', 'units', units, 'position', absPos([.37 .83 .6 .05], posFrame), 'string', '', 'tag', 'controlFrameItem', 'callback', 'controlFrame(''contour'', ''renameStruct'')', 'enable', 'off', 'horizontalAlignment', 'left');
                ud.handles.structRenameText = uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, 'position', absPos([.05 .83 .26 .05], posFrame), 'string', 'Rename:', 'tag', 'controlFrameItem', 'horizontalAlignment', 'left');
                
                %Displays the associatedScan for current structure.
                ud.handles.assocScanText = uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, 'position', absPos([.05 .77 .25 .05], posFrame), 'string', 'Scan:', 'tag', 'controlFrameItem', 'horizontalAlignment', 'left');
                ud.handles.assocScanVal  = uicontrol(hFig, 'style', 'edit', 'enable', 'off' , 'units', units, 'position', absPos([.37 .77 .55 .05], posFrame), 'string', '1. CT Scan', 'tag', 'controlFrameItem', 'horizontalAlignment', 'left');
                
                %Select Contour Interpreted Type
                intrepLength = length(fieldnames(initROIInterpretedType));
                intrepNames =  fieldnames(initROIInterpretedType);
                
                ROIInterpretedType = cell(intrepLength+1,1);
                ROIInterpretedType{1} = 'Select';
                for i = 2:intrepLength+1
                    ROIInterpretedType{i} = intrepNames{i-1};
                end
                % Find index of "ORGAN" structure
                indOrgan = find(strcmp(ROIInterpretedType,'ORGAN'));
                ud.handles.ROIInterpretedText = uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, 'position', absPos([.04 .7 .28 .05], posFrame), 'string', 'Category:', 'tag', 'controlFrameItem', 'horizontalAlignment', 'left');
                ud.handles.ROIInterpretedType = uicontrol(hFig, 'style', 'popupmenu', 'enable', 'on' , 'units', units, 'position', absPos([.34 .7 .65 .05], posFrame), 'string', ROIInterpretedType, 'value', indOrgan(1), 'tag', 'controlFrameItem', 'horizontalAlignment', 'left', 'callback', 'controlFrame(''contour'', ''ROIIntrepretedType'')');
                
                %Controls for creation of new structures.
                ud.handles.asCopyOfCurrent  = uicontrol(hFig, 'style', 'radiobutton', 'value', 0, 'units', units, 'position', absPos([.04 .60 .65 .05], posFrame), 'string', 'As copy of current', 'tag', 'controlFrameItem', 'horizontalAlignment', 'left', 'callback', 'controlFrame(''contour'', ''asCopyOfCurrent'')');
                ud.handles.asBlank          = uicontrol(hFig, 'style', 'radiobutton', 'value', 1, 'units', units, 'position', absPos([.04 .555 .57 .05], posFrame), 'string', 'As new on scan', 'tag', 'controlFrameItem', 'horizontalAlignment', 'left', 'callback', 'controlFrame(''contour'', ''asBlank'')');
                for i=1:length(planC{indexS.scan})
                    scanStringC{i} = [num2str(i), ' ', planC{indexS.scan}(i).scanType];
                end                
                ud.handles.scanSelect       = uicontrol(hFig, 'style', 'popupmenu', 'enable', 'on' , 'units', units, 'position', absPos([.60 .555 .38 .05], posFrame), 'string', scanStringC, 'tag', 'controlFrameItem', 'horizontalAlignment', 'left', 'callback', 'controlFrame(''contour'', ''scanSelect'')','Enable','Off');
                scanSet = getAxisInfo(stateS.handle.CERRAxis(stateS.currentAxis),'scanSets');
                set(ud.handles.scanSelect, 'value',scanSet);                
                ud.handles.createNewText    = uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, 'position', absPos([.05 .48 .55 .05], posFrame), 'string', 'New Structure:', 'tag', 'controlFrameItem', 'horizontalAlignment', 'left');
                ud.handles.structNewButton  = uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', absPos([.6 .49 .35 .05], posFrame), 'string', 'Create', 'tag', 'controlFrameItem', 'callback', 'controlFrame(''contour'', ''newStruct'')');
                
                %Controls to select contouring mode.
                %ud.handles.modeText = uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, 'position', absPos([.05 .40 .35 .05], posFrame), 'string', 'Mode:', 'tag', 'controlFrameItem', 'horizontalAlignment', 'left');
                %ud.handles.modePopup = uicontrol(hFig, 'style', 'popupmenu', 'units', units, 'position', absPos([.40 .40 .55 .05], posFrame), 'string', {'Draw', 'Edit', 'Threshold', 'Reassign', 'EditGE','DrawBall'}, 'tag', 'controlFrameItem', 'callback', 'controlFrame(''contour'', ''selectMode'')', 'TooltipString', 'Select Mode. Shortcut Keys: ''D'', ''E'', ''T'', ''R''');
                
                %Controls to copy all contours sup/inf.
                %ud.handles.copyInfButton = uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', absPos([.1 .33 .35 .05], posFrame), 'string', 'Copy +Z', 'tag', 'controlFrameItem', 'callback', 'contourControl(''copyInf'')', 'TooltipString', 'Copy all segments towards +Z');
                %ud.handles.copySupButton = uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', absPos([.55 .33 .35 .05], posFrame), 'string', 'Copy -Z', 'tag', 'controlFrameItem', 'callback', 'contourControl(''copySup'')', 'TooltipString', 'Copy all segments towards -Z');
                
                %Control to delete selected segment.
                %ud.handles.delButton = uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', absPos([.1 .27 .8 .05], posFrame), 'string', 'Delete Selected Segment', 'tag', 'controlFrameItem', 'callback', 'controlFrame(''contour'', ''deleteStruct'')');
                
                %Controls to select reassignment structure.
                %ud.handles.reassignChoicesText = uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, 'position', absPos([.05 .20 .35 .05], posFrame), 'string', 'Move to:', 'tag', 'controlFrameItem', 'horizontalAlignment', 'left');
                %ud.handles.reassignChoices = uicontrol(hFig, 'style', 'popupmenu', 'BackgroundColor', [0 1 0], 'units', units, 'position', absPos([.42 .20 .55 .05], posFrame), 'string', 'NULL', 'value', 1, 'tag', 'controlFrameItem', 'callback', 'controlFrame(''contour'', ''selectStruct2'')', 'TooltipString', 'Structure to move contours to/from in reassign mode.');
                
                % Controls for Pencil, Brush and Eraser
                % AI 5/18/17 removed brush,eraser,slider
                ud.handles.pencil = uicontrol(hFig, 'style', 'togglebutton', 'units', units, 'position', absPos([.05 .36 .4 .08], posFrame), 'string', 'Pencil', 'tag', 'controlFrameItem', 'callback', 'controlFrame(''contour'',''toggleMode'',''pencil'')', 'TooltipString', 'Pencil');
                %ud.handles.brush = uicontrol(hFig, 'style', 'togglebutton', 'units', units, 'position', absPos([.35 .38 .28 .07], posFrame), 'string', 'Brush', 'tag', 'controlFrameItem', 'callback', 'controlFrame(''contour'',''toggleMode'',''brush'')', 'TooltipString', 'Brush');
                %ud.handles.eraser = uicontrol(hFig, 'style', 'togglebutton', 'units', units, 'position', absPos([.65 .38 .28 .07], posFrame), 'string', 'Eraser', 'tag', 'controlFrameItem', 'callback', 'controlFrame(''contour'',''toggleMode'',''eraser'')', 'TooltipString', 'Eraser');
                ud.handles.flex = uicontrol(hFig, 'style', 'togglebutton', 'units', units, 'position', absPos([.55 .36 .4 .08], posFrame), 'string', 'Brush/Eraser', 'tag', 'controlFrameItem', 'callback', 'controlFrame(''contour'',''toggleMode'',''flex'')', 'TooltipString', 'Toggle brush/eraser'); %Added
                ud.handles.threshold = uicontrol(hFig, 'style', 'togglebutton', 'units', units, 'position', absPos([.05 .26 .4 .08], posFrame), 'string', 'Threshold', 'tag', 'controlFrameItem', 'callback', 'controlFrame(''contour'',''toggleMode'',''threshold'')', 'TooltipString', 'Toggle threshold');
                
                % Get min/max brush size
                radius = min([planC{indexS.scan}(1).scanInfo(1).grid1Units,...
                    planC{indexS.scan}(1).scanInfo(1).grid2Units]);
                ud.minRadius = radius;
                ud.maxRadius = radius*50;
                % Slider to select brush or eraser size
                %ud.handles.brushSizeSlider = uicontrol(hFig, 'style', 'slider', ...
                %    'units', units, 'position', absPos([.1 .25 .8 .04], posFrame),...  %AI changed positions
                %    'tag', 'controlFrameItem', 'min', radius, 'max', radius*50, ...
                %    'value', radius*5, 'SliderStep', [radius radius*2],...
                %    'callback', 'controlFrame(''contour'',''setBrushSize'')');
                %ud.handles.brushSizeTxt = uicontrol(hFig, 'style', 'text',...
                %    'units', units, 'position', absPos([.05 .2 .3 .05], posFrame),...  
                %    'string', 'Size (cm):', 'tag', 'controlFrameItem',...
                %    'horizontalAlignment','right');             
                %ud.handles.brushSizeEdit = uicontrol(hFig, 'style', 'text',...
                %    'units', units, 'position', absPos([.39 .2 .3 .05], posFrame),...  
                %    'string', num2str(radius*5), 'tag', 'controlFrameItem',...
                %    'callback', 'controlFrame(''contour'',''setBrushSize'')');           
                
                %Controls to select overlaid scan.
                ud.handles.overlayText = uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, 'position', absPos([.05 .07 .25 .10], posFrame), 'string', 'Overlay Scan:', 'tag', 'controlFrameItem', 'horizontalAlignment', 'left');
                ud.handles.overlayChoices = uicontrol(hFig, 'style', 'popupmenu', 'units', units, 'position', absPos([.30 .12 .41 .05], posFrame), 'string', scanStringC, 'value', scanSet, 'tag', 'controlFrameItem', 'callback', 'controlFrame(''contour'', ''selectOverlayScan'')', 'TooltipString', 'Select Scan to overlay on the base scan.');
                ud.handles.overlayOptions = uicontrol(hFig, 'style', 'push', 'units', units, 'position', absPos([.72 .12 .26 .05], posFrame), 'string', 'Options', 'tag', 'controlFrameItem', 'callback', 'controlFrame(''contour'', ''selectOverlayOptions'',''init'')', 'TooltipString', 'Select display options for overlaid scan.');
                
                ud.handles.saveButton = uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', absPos([.1 .04 .35 .05], posFrame), 'string', 'Save', 'tag', 'controlFrameItem', 'callback', 'contourControl(''save'')');
                ud.handles.abortButton = uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', absPos([.55 .04 .35 .05], posFrame), 'string', 'Quit', 'tag', 'controlFrameItem', 'callback', 'contourControl(''revert'')');
                
                %Set the overlaid scan scme as that displayed at the start
                set(ud.handles.overlayChoices,'value',scanSet)
                
                stateS.handle.controlFrameUd = ud;
                for i=1:length(stateS.handle.CERRAxis)
                    setappdata(stateS.handle.CERRAxis(i),'oldCoord',getAxisInfo(stateS.handle.CERRAxis(i),'coord'))
                end
                controlFrame('contour', 'refresh');
                                
                
            case 'scanSelect'
                % Commented By Divya As it is not implemented
                
                %                 %Get and set list of existing scans.
                %                 ud = get(hFrame, 'userdata');
                %                 scanSelect = get(ud.handles.scanSelect,'value');
                %                 scanSets = getAxisInfo(stateS.handle.CERRAxis(1),'scanSets');
                %
                %                 % Set flag to check when uniformizing structure
                %                 if scanSelect ~= scanSets(1)
                %                     ud.AsBlankOn_flg = scanSelect;
                %                 end
                %                 set(hFrame, 'userdata', ud);
                %
                %                 % Change the structure's scan association
                %                 struct(1).associatedScan = scanSet;
                %                 struct(1).assocScanUID   = planC{indexS.scan}(scanSet).scanUID;
                
            case 'selectOverlayScan'
                ud = stateS.handle.controlFrameUd ;
                overlayScanNum = get(ud.handles.overlayChoices,'value');
                appData = getappdata(stateS.handle.CERRAxis(1));
                for i=1:length(planC{indexS.scan})
                    planC{indexS.scan}(overlayScanNum).transM = eye(4);
                end
                baseScan = getAxisInfo(stateS.handle.CERRAxis(1),'scanSets');
                if isempty(appData.transMList{baseScan})
                    TMbase = eye(4);
                else
                    TMbase = appData.transMList{baseScan};
                end
                if isempty(appData.transMList{overlayScanNum})
                    TMoverlay = eye(4);
                else
                    TMoverlay = appData.transMList{overlayScanNum};
                end
                planC{indexS.scan}(overlayScanNum).transM = inv(TMbase)*TMoverlay;
                scanUID = ['c',repSpaceHyp(planC{indexS.scan}(overlayScanNum).scanUID(max(1,end-61):end))];                
                stateS.contourOvrlyOptS.center = stateS.scanStats.CTLevel.(scanUID);
                stateS.contourOvrlyOptS.width  = stateS.scanStats.CTWidth.(scanUID);
                stateS.contourOvrlyOptS.colormap = 'Gray256';
                stateS.CTDisplayChanged = 1;
                CERRRefresh;
                
            case 'selectOverlayOptions'
                switch lower(varargin{2})
                    case 'init'
                        hFig = findobj('name','Overlaid Scan Options');
                        if ~isempty(hFig)
                            return;
                        end
                        ud = stateS.handle.controlFrameUd ;
                        position = [5 40 200 200];
                        hFig = figure('name','Overlaid Scan Options','numbertitle','off','menuBar','none',...
                            'position',position, 'doublebuffer', 'on','WindowStyle','normal',...
                            'resize','off','color',[0.9 0.9 0.9]);
                        ud.handle.ovrlayFig = hFig;
                        
                        %CREATE UICONTROLS FOR VARIOUS OPTIONS
                        units = 'normalized';
                        uicontrol(hFig,'style','text','String','Select Options for Overlaid Scan','units',units,'fontWeight','bold','position',[0.05 0.850 0.9 0.1]);
                        uicontrol(hFig,'style','frame','units', units, 'Position',[0.05 0.35 0.9 0.45]);
                        ud.handle.ovrlayWindowTxt       = uicontrol(hFig,'style','text','String','CT Window','units',units,'position',[0.1 0.65 0.3 0.1]);
                        ud.handle.ovrlayWindowChoices   = uicontrol(hFig,'style','popup','string',{stateS.optS.windowPresets.name},'units',units,'position',[0.45 0.65 0.4 0.1],'value',1, 'callback', 'controlFrame(''contour'', ''selectOverlayOptions'',''windowpreset'')');
                        ud.handle.ovrlayWindowCenterTxt = uicontrol(hFig,'style','text','string','Center','units',units,'position',[0.1 0.50 0.35 0.1]);
                        ud.handle.ovrlayWindowCenterEdt = uicontrol(hFig,'style','edit','string','0','units',units,'position',[0.1 0.40 0.35 0.1], 'callback', 'controlFrame(''contour'', ''selectOverlayOptions'',''setManualWindow'')');
                        ud.handle.ovrlayWindowWidthTxt  = uicontrol(hFig,'style','text','string','Width','units',units,'position',[0.55 0.50 0.35 0.1]);
                        ud.handle.ovrlayWindowWidthEdt  = uicontrol(hFig,'style','edit','string','300','units',units,'position',[0.55 0.40 0.35 0.1], 'callback', 'controlFrame(''contour'', ''selectOverlayOptions'',''setManualWindow'')');                        
                        colorbarStrC = {'Gray256','Copper','Red','Green','Blue','StarInterp','hotCold'};
                        ud.handle.ovrlayMapTxt          = uicontrol(hFig,'style','text','string','Colorbar','units',units,'position',[0.05 0.20 0.3 0.1]);
                        ud.handle.ovrlayMapChoices      = uicontrol(hFig,'style','popup','string',colorbarStrC,'units',units,'position',[0.40 0.20 0.45 0.1],'value',1, 'callback', 'controlFrame(''contour'', ''selectOverlayOptions'',''fieldClicked'')');
                        
                        ud.handle.ovrlayApply           = uicontrol(hFig,'style','push','string','Apply','units',units,'position',[0.25 0.05 0.20 0.1], 'callback', 'controlFrame(''contour'', ''selectOverlayOptions'',''apply'')');
                        ud.handle.ovrlayExit           = uicontrol(hFig,'style','push','string','Exit','units',units,'position',[0.55 0.05 0.20 0.1], 'callback', 'controlFrame(''contour'', ''selectOverlayOptions'',''exit'')');
                        
                        %set(hFrame,'userdata',ud)
                        stateS.handle.controlFrameUd = ud ;

                    case 'windowpreset'
                        ud = stateS.handle.controlFrameUd ;
                        windowPresetIndex = get(ud.handle.ovrlayWindowChoices,'value');
                        if windowPresetIndex > 1
                            set(ud.handle.ovrlayWindowCenterEdt,'String',num2str(stateS.optS.windowPresets(windowPresetIndex).center))
                            set(ud.handle.ovrlayWindowWidthEdt,'String',num2str(stateS.optS.windowPresets(windowPresetIndex).width))
                        end
                        set(ud.handle.ovrlayApply,'fontWeight','bold')
                        
                    case 'fieldclicked'
                        ud = stateS.handle.controlFrameUd ;
                        set(ud.handle.ovrlayApply,'fontWeight','bold')
                        
                    case 'setmanualwindow'
                        ud = stateS.handle.controlFrameUd ;
                        set(ud.handle.ovrlayWindowChoices,'value',1)
                        set(ud.handle.ovrlayApply,'fontWeight','bold')
                        
                    case 'apply'
                        ud = stateS.handle.controlFrameUd ;
                        
                        windowPresetIndex = get(ud.handle.ovrlayWindowChoices,'value');
                        if windowPresetIndex > 1
                            stateS.contourOvrlyOptS.center = stateS.optS.windowPresets(windowPresetIndex).center;
                            stateS.contourOvrlyOptS.width  = stateS.optS.windowPresets(windowPresetIndex).width;
                        else
                            stateS.contourOvrlyOptS.center = str2num(get(ud.handle.ovrlayWindowCenterEdt,'String'));
                            stateS.contourOvrlyOptS.width  = str2num(get(ud.handle.ovrlayWindowWidthEdt,'String'));
                        end
                        colorbarStrC = {'Gray256','Copper','Red','Green','Blue','StarInterp','hotCold'};
                        stateS.contourOvrlyOptS.colormap = colorbarStrC{get(ud.handle.ovrlayMapChoices,'Value')};
                        stateS.CTDisplayChanged = 1;
                        CERRRefresh;
                        set(ud.handle.ovrlayApply,'fontWeight','normal')
                        
                    case 'exit'
                        ud = stateS.handle.controlFrameUd ;
                        delete(ud.handle.ovrlayFig)
                        
                end
                
            case 'refresh'
                ud = stateS.handle.controlFrameUd ;
                if isempty(ud)
                    return;
                end
                
                %Get and set list of existing scans.
                imageSets = {};
                nScans = length(planC{indexS.scan});
                
                for i = 1:nScans
                    imageSets{end + 1} = [num2str(i) '. ' planC{indexS.scan}(i).scanInfo(1).imageType];
                end
                
                %Set the scan selection.
                set(ud.handles.scanSelect, 'string', imageSets);
                
                %By default disable reassign selection.
                %set(ud.handles.reassignChoices, 'enable', 'off');
                
                %By default color basic struct box gray.
                set(ud.handles.structPopup, 'BackgroundColor', get(ud.handles.structRenameEdit, 'backgroundcolor'));
                
                %Get numbered structure list.
                structs = {planC{indexS.structures}.structureName};
                assocScanV = getStructureAssociatedScan(1:length(planC{indexS.structures}));
                scanSet = getAxisInfo(stateS.handle.CERRAxis(stateS.contourAxis),'scanSets');
                scanSet = scanSet(1);
                structNumsV = find(assocScanV == scanSet);
                structs = structs(structNumsV);
                strUd.strNumsV = structNumsV;
                
                for i=1:length(structs)
                    numberedStructs{i} = [num2str(structNumsV(i)) '. ' structs{i}];
                end
                
                %Populate reassign selection in case structures changed.
                %try
                %    set(ud.handles.reassignChoices, 'String', numberedStructs);
                %end
                
                %Get and set scan list.
                if ~isempty(structs) %Test if there are any real structures.
                    set(ud.handles.structPopup, 'string', numberedStructs, 'enable', 'on', 'userdata',strUd);
                    val = get(ud.handles.structPopup, 'value');
                    set(ud.handles.structRenameEdit, 'string', structs{val}, 'enable', 'on');
                    set(ud.handles.assocScanVal, 'string', imageSets{getStructureAssociatedScan(structNumsV(val))});
                    if ~isempty(planC{indexS.structures}(structNumsV(val)).ROIInterpretedType)
                        interIndx = strmatch(planC{indexS.structures}(structNumsV(val)).ROIInterpretedType, fieldnames(initROIInterpretedType));
                        set(ud.handles.ROIInterpretedType,'value', interIndx+1);
                    end
                else
                    set(ud.handles.structPopup, 'string', 'No Structs', 'enable', 'off');
                    set(ud.handles.assocScanVal, 'string', 'No Structs');
                    set(ud.handles.structRenameEdit, 'string', '', 'enable', 'off');
                end
                
                return;
                
                mode = contourControl('getMode');
                if ~isempty(mode)
                    switch mode
                        case 'draw'
                            set(ud.handles.modePopup, 'Value', 1);
                        case 'drawBall'
                            set(ud.handles.modePopup, 'Value', 6);                            
                        case 'edit'
                            set(ud.handles.modePopup, 'Value', 2);
                        case 'thresh'
                            set(ud.handles.modePopup, 'Value', 3);
                        case 'reassign'
                            set(ud.handles.modePopup, 'Value', 4);
                            set(ud.handles.structPopup, 'BackgroundColor', [0 0 1]);
                            set(ud.handles.reassignChoices, 'enable', 'on');
                    end
                end
                
            case 'asBlank'
                ud = stateS.handle.controlFrameUd ;
                set(ud.handles.asCopyOfCurrent, 'value', 0);
                %%%%%%%%DK
                scanSet = getAxisInfo(stateS.handle.CERRSliceViewerAxis,'scanSets');
                %%%%%%%%%
                set(ud.handles.asBlank, 'value', 1);
                set(ud.handles.scanSelect, 'enable', 'on','value',scanSet);
                
            case 'asCopyOfCurrent'
                ud = stateS.handle.controlFrameUd ;
                set(ud.handles.asCopyOfCurrent, 'value', 1);
                set(ud.handles.asBlank, 'value', 0);
                set(ud.handles.scanSelect, 'enable', 'off');
                
            case 'selectMode'
                ud = stateS.handle.controlFrameUd ;
                
                structNum   = get(ud.handles.structPopup, 'value');
                
                strUd = get(ud.handles.structPopup, 'userdata');
                
                if isempty(strUd)
                    return;
                end
                
                structNum = strUd.strNumsV(structNum);
                
                scanNum = get(ud.handles.scanSelect, 'value');
                
                if length(varargin) < 2
                    mode = get(gcbo, 'value');
                else
                    mode = varargin{2};
                end
                switch mode
                    case 1
                        %Draw Mode.
                        contourControl('drawMode');
                    case 2
                        %Edit Mode.
                        planC{indexS.structures}(structNum).strUID          = createUID('structure');
                        planC{indexS.structures}(structNum).assocScanUID    = planC{indexS.scan}(scanNum).scanUID;
                        
                        contourControl('editMode');
                    case 3
                        %Threshold Mode
                        contourControl('threshMode');
                    case 4
                        %Reassign mode
                        contourControl('reassignMode');
                    case 5
                        %GE system styled Edit Mode
                        contourControl('editModeGE');
                    case 6
                        %Varian styled Ball/Draw Mode
                        contourControl('drawBall');
                        
                end
                
                controlFrame('contour', 'refresh');
                
                
                
            case 'toggleMode'
                
                % Save current slice
               contourControl('Save_Slice')
               
               ud = stateS.handle.controlFrameUd ;
                
                structNum   = get(ud.handles.structPopup, 'value');
                
                strUd = get(ud.handles.structPopup, 'userdata');
                
                if isempty(strUd)
                    return;
                end
                
                structNum = strUd.strNumsV(structNum);
                
                scanNum = get(ud.handles.scanSelect, 'value');
                
                % Set min/max brush size
                %set(ud.handles.brushSizeSlider,'min', 0.2, 'max', 2, ...
                %    'value', 0.2, 'SliderStep', [0.1 0.2])
                
                modeState = get(gcbo, 'value');
                
                %AI 5/18/17 Removed brush,eraser tools
                %set([ud.handles.pencil, ud.handles.brush, ud.handles.eraser],...
                %    'BackgroundColor',[0.8 0.8 0.8]);  
                set([ud.handles.pencil, ud.handles.flex, ud.handles.threshold],...
                    'BackgroundColor',[0.8 0.8 0.8]);  
                
                
                modeType = varargin{2};
                
                if modeState == 0
                   drawContour('noneMode',stateS.handle.CERRAxis(stateS.currentAxis)) 
                   return
                end                
                
                switch upper(modeType)
                    case 'PENCIL'                        
                        %set([ud.handles.flex ud.handles.brush, ud.handles.eraser],...
                        %    'Value',0)
                        set(ud.handles.flex,'Value',0)
                        set(ud.handles.threshold,'Value',0);
                        set(ud.handles.pencil,'BackgroundColor',[0.5 1 1])
                        %Draw Mode.
                        contourControl('drawMode');
                        
                    case 'BRUSH'                        
                        set([ud.handles.flex ud.handles.pencil, ud.handles.eraser],...
                            'Value',0)
                        set(ud.handles.brush,'BackgroundColor',[0.5 1 1])
                        %Varian styled Ball/Draw Mode
                        contourControl('drawBall');                        
                        
                    case 'ERASER'                        
                        set([ud.handles.flex ud.handles.pencil, ud.handles.brush],...
                            'Value',0)                        
                        set(ud.handles.eraser,'BackgroundColor',[0.5 1 1])
                        %Varian styled Ball/Draw Mode
                        contourControl('eraserBall');    
                        
                    %Added 'flex' mode
                    case 'FLEX'
                        %set([ud.handles.pencil, ud.handles.brush ud.handles.eraser],...
                        %    'Value',0)
                        set(ud.handles.pencil,'Value',0);
                        set(ud.handles.threshold,'Value',0);
                        set(ud.handles.flex,'BackgroundColor',[0.5 1 1])
                        %Flex mode
                        contourControl('flexSelMode');
                        
                    case 'THRESHOLD'
                        % See if the mask for initial seeds exists
                        %hAxis = stateS.handle.CERRAxis(stateS.currentAxis);
                        %maskM = getappdata(hAxis, 'contourMask');
                        maskM = stateS.contouringMetaDataS.contourMask;
                        if isempty(maskM) || (~isempty(maskM) && ~any(maskM(:)))
                            msgbox('Thresholding requires the initial contour. Please create an initial segmentation using the Pencil or the Brush.','Missing initial contour','modal')
                            set(ud.handles.threshold,'Value',0);
                            return;
                        end
                        set(ud.handles.pencil,'Value',0);
                        set(ud.handles.flex,'Value',0);
                        set(ud.handles.threshold,'BackgroundColor',[0.5 1 1])
                        %threshold mode
                        contourControl('thresholdMode');
                        
                    case 2 % switch to edit mode when contour is cliced in "draw" state
                        %Edit Mode.
                        planC{indexS.structures}(structNum).strUID          = createUID('structure');
                        planC{indexS.structures}(structNum).assocScanUID    = planC{indexS.scan}(scanNum).scanUID;
                        
                        contourControl('editMode');
                        
                end
                
                controlFrame('contour', 'refresh');

                
            case 'setBrushSize'
                %Get radius
                ud = stateS.handle.controlFrameUd ;
                if length(varargin) < 3
                    hAxis = stateS.handle.CERRAxis(stateS.currentAxis);
                    if isfield(stateS.contouringMetaDataS,'ballRadius')
                        radius = stateS.contouringMetaDataS.ballRadius;
                    else
                        radius = [];
                    end
                    if isempty(radius)
                       radius = 0.5;  %Initialize
                    end
                else
                    hAxis = varargin{2};
                    increment = varargin{3};
                    %hSlider  = ud.handles.brushSizeSlider;
                    %radius = hSlider.Value + increment;
                    radius = stateS.contouringMetaDataS.ballRadius + increment;
                    if radius>ud.maxRadius
                        radius = ud.maxRadius;
                    elseif radius<ud.minRadius
                        radius = ud.maxRadius;
                    end
                    %set(ud.handles.brushSizeSlider,'Value',radius);%AI 5/18/17
                end
                %radius = get(ud.handles.brushSizeSlider,'Value'); %Removed AI 5/18/17
                %Set brush size
                %set(ud.handles.brushSizeEdit,'String',radius)
                stateS.contouringMetaDataS.ballRadius = radius;
                
                %Update display radius
                ballH = stateS.contouringMetaDataS.hBall;
                angM = stateS.contouringMetaDataS.angles;
                cP = get(hAxis, 'currentPoint');
                xV = cP(1,1) + radius*angM(:,1);
                yV = cP(1,2) + radius*angM(:,2);                
                set(ballH,'xData',xV,'ydata',yV,'visible','on')
                
                
                
            case 'selectStruct'
                %A new structure has been selected.
                ud = stateS.handle.controlFrameUd ;
                if isempty(ud)
                    return;
                end
                strVal = get(gcbo, 'value');
                strUd = get(gcbo, 'userdata');
                if isempty(strUd)
                    return;
                end
                strNumsV = strUd.strNumsV;
                controlFrame('contour', 'refresh')
                %AI 5/18/17 Removed brush, eraser
                % Set pencil/eraser/brush to OFF
                %set([ud.handles.brush, ud.handles.eraser, ud.handles.pencil],...
                %    'Value',0,'BackgroundColor',[0.8 0.8 0.8])
                set([ud.handles.flex, ud.handles.pencil, ud.handles.threshold],...
                    'Value',0,'BackgroundColor',[0.8 0.8 0.8])
                contourControl('changeStruct', strNumsV(strVal));
                
            case 'selectStruct2'
                %A new structure2 has been selected.
                ud = stateS.handle.controlFrameUd ;
                if isempty(ud)
                    return;
                end
                str = get(gcbo, 'value');
                controlFrame('contour', 'refresh')
                contourControl('changeStruct2', str);
                
            case 'newStruct'
                %Create the new structure in plan and update GUI.
                ud = stateS.handle.controlFrameUd ;
                iscopy = get(ud.handles.asCopyOfCurrent, 'value');
                
                nStructs = length(planC{indexS.structures});
                toAdd = nStructs + 1;
                
                if iscopy %Copy the currently selected structure.
                    structNum   = get(ud.handles.structPopup, 'value');
                    strUd = get(ud.handles.structPopup, 'userdata');
                    structNum = strUd.strNumsV(structNum);
                    planC       = copyCERRStructure(structNum, planC);
                else %Create a new structure with selected associated scan.
                    %scanNum = get(ud.handles.scanSelect, 'value');
                    scanNum = stateS.contouringMetaDataS.ccScanSet; 

                    if isempty(ud)
                        return;
                    end
                    %Insert the new structure at the end of the list.
                    newStr = newCERRStructure(scanNum);
                    newStr.associatedScan = scanNum;
                    newStr.strUID = createUID('structure');
                    newStr.assocScanUID = planC{indexS.scan}(scanNum).scanUID;
                    newStr.structureName = 'New Structure';
                    planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStr, toAdd);
                end
                
                % Update the contourSlcLoadedM
                contourSlcLoadedM =  stateS.contouringMetaDataS.contourSlcLoadedM;
                contourSlcLoadedM(end+1,:) = false;
%                 setappdata(stateS.handle.CERRAxis(...
%                     stateS.contourAxis), 'contourSlcLoadedM',contourSlcLoadedM);
                stateS.contouringMetaDataS.contourSlcLoadedM = contourSlcLoadedM;

                [jnk, relStructNumV] = getStructureAssociatedScan(toAdd);
                set(ud.handles.structPopup, 'value', relStructNumV);
                controlFrame('contour', 'refresh')
                contourControl('changeStruct', toAdd);
                
            case 'renameStruct'
                %Structure has been renamed.
                ud = stateS.handle.controlFrameUd ;
                if isempty(ud)
                    return;
                end
                
                name = get(gcbo, 'string');
                strNum = get(ud.handles.structPopup, 'value');
                strUd = get(ud.handles.structPopup, 'userdata');
                
                %Check is this structure name already exists
                strNameC = get(ud.handles.structPopup, 'string');
                indMatch = strcmpi(name,strNameC);
                if any(indMatch) && find(indMatch) ~= strNum
                    CERRStatusString([name, ' structure already exists. Cannot rename this structure'])
                    return
                end
                
                CERRStatusString(['Renamed ',planC{indexS.structures}(strUd.strNumsV(strNum)).structureName, ' to ', name])
                planC{indexS.structures}(strUd.strNumsV(strNum)).structureName = name;
                controlFrame('contour', 'refresh')
                
            case 'ROIIntrepretedType'
                %Structure Category Set
                ud = stateS.handle.controlFrameUd ;
                if isempty(ud)
                    return;
                end
                
                strNum = get(ud.handles.structPopup, 'value');
                strUd = get(ud.handles.structPopup, 'userdata');
                ROIInterpretedTypeNum = get(ud.handles.ROIInterpretedType,'value') - 1;
                ROIInterpretedType = fieldnames(initROIInterpretedType);
                if ROIInterpretedTypeNum == 0 && ~isempty(strUd)
                    planC{indexS.structures}(strUd.strNumsV(strNum)).ROIInterpretedType = '';
                elseif ~isempty(strUd)
                    planC{indexS.structures}(strUd.strNumsV(strNum)).ROIInterpretedType = ROIInterpretedType{ROIInterpretedTypeNum};
                end
                controlFrame('contour', 'refresh')
                
            case 'deleteStruct'
                %Delete the current segment
                contourControl('deleteSegment');
        end
        
    case 'colorbar'
        switch varargin{1}
            case 'init'
                controlFrame('default');
                numDose = length(planC{indexS.dose});
                if numDose < 1
                    warndlg('Cannot initiate without Dose','ColorBar');
                    return
                end
                
                %Title
                ud.handles.title = uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, 'position', absPos([.05 .93 .9 .05],...
                    posFrame), 'string', 'Colorbar Options', 'tag', 'controlFrameItem', 'horizontalAlignment', 'center', 'FontWeight', 'Bold');
                
                %Colorbar Range
                ud.handles.CBRText = uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, 'position', ...
                    absPos([.05 .87 .9 .05], posFrame), 'string', 'Colorbar Range:', 'tag', 'controlFrameItem', 'horizontalAlignment', 'center');
                uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, 'position',...
                    absPos([.05 .82 .9 .05], posFrame), 'string', 'to', 'tag', 'controlFrameItem', ...
                    'horizontalAlignment', 'center');
                ud.handles.CBRLow  = uicontrol(hFig, 'style', 'edit', 'units', units, 'position', absPos([.05 .82 .4 .05], posFrame),...
                    'string', num2str(stateS.colorbarRange(1)), 'tag', 'controlFrameItem', 'callback', ...
                    'controlFrame(''colorbar'', ''field_clicked'')', 'enable', 'on');
                ud.handles.CBRHigh = uicontrol(hFig, 'style', 'edit', 'units', units, 'position', absPos([.55 .82 .4 .05], posFrame), ...
                    'string', num2str(stateS.colorbarRange(2)), 'tag', 'controlFrameItem', 'callback', ...
                    'controlFrame(''colorbar'', ''field_clicked'')', 'enable', 'on');
                %Dose Display Range
                ud.handles.DDRText = uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units,...
                    'position', absPos([.05 .72 .9 .05], posFrame), 'string', 'Dose Display Range:', 'tag',...
                    'controlFrameItem', 'horizontalAlignment', 'center');
                uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, ...
                    'position', absPos([.05 .67 .9 .05], posFrame), 'string', 'to', ...
                    'tag', 'controlFrameItem', 'horizontalAlignment', 'center');
                ud.handles.DDRLow  = uicontrol(hFig, 'style', 'edit', 'units', units, 'position', absPos([.05 .67 .4 .05], posFrame),...
                    'string', num2str(stateS.doseDisplayRange(1)), 'tag', 'controlFrameItem', 'callback',...
                    'controlFrame(''colorbar'', ''field_clicked'')', 'enable', 'on');
                ud.handles.DDRHigh = uicontrol(hFig, 'style', 'edit', 'units', units, 'position', absPos([.55 .67 .4 .05], posFrame),...
                    'string', num2str(stateS.doseDisplayRange(2)), 'tag', 'controlFrameItem', 'callback',...
                    'controlFrame(''colorbar'', ''field_clicked'')', 'enable', 'on');
                
                %Colorbar Selection
                colorbarChoices = stateS.optS.colorbarChoices;
                currentMap = stateS.optS.doseColormap;
                value = find(strcmpi(colorbarChoices, currentMap));
                ud.handles.CBSText = uicontrol(hFig, 'style', 'text', 'enable', 'inactive', 'units', units, ...
                    'position', absPos([.05 .57 .9 .05], posFrame), 'string', 'Colorbar Selection:', 'tag',...
                    'controlFrameItem', 'horizontalAlignment', 'center');
                ud.handles.CBSPopup= uicontrol(hFig, 'style', 'popupmenu', 'units', units, 'position', absPos([.05 .52 .9 .05], posFrame),...
                    'value', value, 'string', colorbarChoices, 'tag', 'controlFrameItem', 'horizontalAlignment', 'center', 'callback',...
                    'controlFrame(''colorbar'', ''field_clicked'')');
                
                SCBTipText = 'Do not rescale colorbar when changing doses.';
                ud.handles.SCBCheck = uicontrol(hFig, 'style', 'checkbox', 'units', units, 'position', absPos([.20 .42 .7 .05], posFrame),...
                    'string', 'Constant Colorbar', 'value', stateS.optS.staticColorbar, 'tag', 'controlFrameItem', 'horizontalAlignment',...
                    'center', 'callback', 'controlFrame(''colorbar'', ''field_clicked'')', 'tooltip', SCBTipText);
                
                NTTipText = 'Display a texture pattern over negative values.';
                ud.handles.negativeTexture = uicontrol(hFig, 'style', 'checkbox', 'units', units, ...
                    'position', absPos([.20 .35 .7 .05], posFrame), 'string', 'Negative Texture', ...
                    'value', stateS.optS.negativeTexture, 'tag', 'controlFrameItem', 'horizontalAlignment',...
                    'center', 'callback', 'controlFrame(''colorbar'', ''field_clicked'')', 'tooltip', NTTipText);
                
                dSCTipText = 'Use max color for both max and min.  Useful for viewing absolute value of negative dose.';
                ud.handles.doubleSidedColorbar = uicontrol(hFig, 'style', 'checkbox', 'units', units, ...
                    'position', absPos([.20 .28 .7 .05], posFrame), 'string', 'Two Headed Colorbar',...
                    'value', stateS.optS.doubleSidedColorbar, 'tag', 'controlFrameItem', ...
                    'horizontalAlignment', 'center', 'callback', 'controlFrame(''colorbar'', ''field_clicked'')', 'tooltip', dSCTipText);
                
                tZTipText = 'Display zero as transparent, instead as the color where zero falls on the colorbar.';
                ud.handles.transparentZerodose = uicontrol(hFig, 'style', 'checkbox', 'units', units,...
                    'position', absPos([.20 .21 .7 .05], posFrame), 'string', 'Zero is Transparent',...
                    'value', stateS.optS.transparentZeroDose, 'tag', 'controlFrameItem', ...
                    'horizontalAlignment', 'center', 'callback', 'controlFrame(''colorbar'', ''field_clicked'')', 'tooltip', tZTipText);
                
                SkinTipText = 'Only calculate and display dose inside the skin structure, if it exists.';
                ud.handles.calcDoseInSkin = uicontrol(hFig, 'style', 'checkbox', 'units', units,...
                    'position', absPos([.20 .14 .7 .05], posFrame), 'string', 'Zero Dose outside Skin', ...
                    'value', stateS.optS.calcDoseInsideSkinOnly, 'tag', 'controlFrameItem', 'horizontalAlignment', 'center',...
                    'callback', 'controlFrame(''colorbar'', ''field_clicked'')', 'tooltip', SkinTipText);
                
                ud.handles.applyButton = uicontrol(hFig, 'style', 'pushbutton', 'units', units,...
                    'position', absPos([.1 .05 .35 .05], posFrame), 'string', 'Apply', 'tag', 'controlFrameItem', 'callback',...
                    'controlFrame(''colorbar'', ''apply'')');
                ud.handles.cancelButton = uicontrol(hFig, 'style', 'pushbutton', 'units', units,...
                    'position', absPos([.55 .05 .35 .05], posFrame), 'string', 'Exit', 'tag', 'controlFrameItem',...
                    'callback', 'controlFrame(''colorbar'', ''cancel'')');
                
                stateS.handle.controlFrameUd = ud ;
                
            case 'refresh'
                ud = stateS.handle.controlFrameUd ;
                if isempty(ud)
                    return;
                end
                try
                    set(ud.handles.CBRLow, 'string', num2str(stateS.colorbarRange(1)));
                    set(ud.handles.CBRHigh, 'string', num2str(stateS.colorbarRange(2)));
                    set(ud.handles.DDRLow, 'string', num2str(stateS.doseDisplayRange(1)));
                    set(ud.handles.DDRHigh, 'string', num2str(stateS.doseDisplayRange(2)));
                    colorbarChoices = stateS.optS.colorbarChoices;
                    currentMap = stateS.optS.doseColormap;
                    value = find(strcmpi(colorbarChoices, currentMap));
                    set(ud.handles.CBSPopup, 'string', colorbarChoices, 'value', value);
                end
            case 'apply'
                ud = stateS.handle.controlFrameUd ;
                if isempty(ud)
                    return;
                end
                stateS.colorbarRange(1) = min(str2num(get(ud.handles.CBRLow, 'string')), str2num(get(ud.handles.CBRHigh, 'string')));
                stateS.colorbarRange(2) = max(str2num(get(ud.handles.CBRLow, 'string')), str2num(get(ud.handles.CBRHigh, 'string')));
                stateS.doseDisplayRange(1) = min(str2num(get(ud.handles.DDRLow, 'string')), str2num(get(ud.handles.DDRHigh, 'string')));
                stateS.doseDisplayRange(2) = max(str2num(get(ud.handles.DDRLow, 'string')), str2num(get(ud.handles.DDRHigh, 'string')));
                stateS.optS.doseColormap = stateS.optS.colorbarChoices{get(ud.handles.CBSPopup, 'value')};
                
                stateS.optS.staticColorbar = get(ud.handles.SCBCheck, 'value');
                stateS.optS.negativeTexture = get(ud.handles.negativeTexture, 'value');
                stateS.optS.doubleSidedColorbar = get(ud.handles.doubleSidedColorbar, 'value');
                stateS.optS.transparentZeroDose = get(ud.handles.transparentZerodose, 'value');
                stateS.optS.calcDoseInsideSkinOnly = get(ud.handles.calcDoseInSkin, 'value');
                
                stateS.doseDisplayChanged = 1;
                CERRColorBar('refresh', stateS.handle.doseColorbar.trans);
                CERRRefresh;
                
                set(ud.handles.applyButton, 'FontWeight', 'Normal');
                
            case 'field_clicked'
                ud = stateS.handle.controlFrameUd ;
                set(ud.handles.applyButton, 'FontWeight', 'Bold');
                
            case 'cancel'
                controlFrame('default');
        end
        
    case 'colorbarcompare'
        switch varargin{1}
            case 'init'
                controlFrame('default');
                %Title
                ud.handles.title = uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, 'position', absPos([.05 .93 .9 .05], posFrame), 'string', 'Colorbar Options', 'tag', 'controlFrameItem', 'horizontalAlignment', 'center', 'FontWeight', 'Bold');
                
                %Colorbar Range
                ud.handles.CBRText = uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, 'position', absPos([.05 .87 .9 .05], posFrame), 'string', 'Colorbar Range:', 'tag', 'controlFrameItem', 'horizontalAlignment', 'center');
                uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, 'position', absPos([.05 .82 .9 .05], posFrame), 'string', 'to', 'tag', 'controlFrameItem', 'horizontalAlignment', 'center');
                
                ud.handles.CBRLow  = uicontrol(hFig, 'style', 'edit', 'units', units, 'position', absPos([.05 .82 .4 .05], posFrame), 'string', num2str(stateS.colorbarRangeCompare(1)), 'tag', 'controlFrameItem', 'callback', 'controlFrame(''colorbarcompare'', ''field_clicked'')', 'enable', 'on');
                ud.handles.CBRHigh = uicontrol(hFig, 'style', 'edit', 'units', units, 'position', absPos([.55 .82 .4 .05], posFrame), 'string', num2str(stateS.colorbarRangeCompare(2)), 'tag', 'controlFrameItem', 'callback', 'controlFrame(''colorbarcompare'', ''field_clicked'')', 'enable', 'on');
                
                %Dose Display Range
                ud.handles.DDRText = uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, 'position', absPos([.05 .72 .9 .05], posFrame), 'string', 'Dose Display Range:', 'tag', 'controlFrameItem', 'horizontalAlignment', 'center');
                uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, 'position', absPos([.05 .67 .9 .05], posFrame), 'string', 'to', 'tag', 'controlFrameItem', 'horizontalAlignment', 'center');
                ud.handles.DDRLow  = uicontrol(hFig, 'style', 'edit', 'units', units, 'position', absPos([.05 .67 .4 .05], posFrame), 'string', num2str(stateS.doseDisplayRangeCompare(1)), 'tag', 'controlFrameItem', 'callback', 'controlFrame(''colorbarcompare'', ''field_clicked'')', 'enable', 'on');
                ud.handles.DDRHigh = uicontrol(hFig, 'style', 'edit', 'units', units, 'position', absPos([.55 .67 .4 .05], posFrame), 'string', num2str(stateS.doseDisplayRangeCompare(2)), 'tag', 'controlFrameItem', 'callback', 'controlFrame(''colorbarcompare'', ''field_clicked'')', 'enable', 'on');
                
                %Colorbar Selection
                colorbarChoices = stateS.optS.colorbarChoices;
                currentMap = stateS.optS.doseColormap;
                value = find(strcmpi(colorbarChoices, currentMap));
                ud.handles.CBSText = uicontrol(hFig, 'style', 'text', 'enable', 'inactive', 'units', units, 'position', absPos([.05 .57 .9 .05], posFrame), 'string', 'Colorbar Selection:', 'tag', 'controlFrameItem', 'horizontalAlignment', 'center');
                ud.handles.CBSPopup= uicontrol(hFig, 'style', 'popupmenu', 'units', units, 'position', absPos([.05 .52 .9 .05], posFrame), 'value', value, 'string', colorbarChoices, 'tag', 'controlFrameItem', 'horizontalAlignment', 'center', 'callback', 'controlFrame(''colorbarcompare'', ''field_clicked'')');
                
                SCBTipText = 'Do not rescale colorbar when changing doses.';
                ud.handles.SCBCheck = uicontrol(hFig, 'style', 'checkbox', 'units', units, 'position', absPos([.20 .42 .7 .05], posFrame), 'string', 'Constant Colorbar', 'value', stateS.optS.staticColorbar, 'tag', 'controlFrameItem', 'horizontalAlignment', 'center', 'callback', 'controlFrame(''colorbarcompare'', ''field_clicked'')', 'tooltip', SCBTipText);
                
                NTTipText = 'Display a texture pattern over negative values.';
                ud.handles.negativeTexture = uicontrol(hFig, 'style', 'checkbox', 'units', units, 'position', absPos([.20 .35 .7 .05], posFrame), 'string', 'Negative Texture', 'value', stateS.optS.negativeTexture, 'tag', 'controlFrameItem', 'horizontalAlignment', 'center', 'callback', 'controlFrame(''colorbarcompare'', ''field_clicked'')', 'tooltip', NTTipText);
                
                dSCTipText = 'Use max color for both max and min.  Useful for viewing absolute value of negative dose.';
                ud.handles.doubleSidedColorbar = uicontrol(hFig, 'style', 'checkbox', 'units', units, 'position', absPos([.20 .28 .7 .05], posFrame), 'string', 'Two Headed Colorbar', 'value', stateS.optS.doubleSidedColorbar, 'tag', 'controlFrameItem', 'horizontalAlignment', 'center', 'callback', 'controlFrame(''colorbarcompare'', ''field_clicked'')', 'tooltip', dSCTipText);
                
                tZTipText = 'Display zero as transparent, instead as the color where zero falls on the colorbar.';
                ud.handles.transparentZerodose = uicontrol(hFig, 'style', 'checkbox', 'units', units, 'position', absPos([.20 .21 .7 .05], posFrame), 'string', 'Zero is Transparent', 'value', stateS.optS.transparentZeroDose, 'tag', 'controlFrameItem', 'horizontalAlignment', 'center', 'callback', 'controlFrame(''colorbarcompare'', ''field_clicked'')', 'tooltip', tZTipText);
                
                SkinTipText = 'Only calculate and display dose inside the skin structure, if it exists.';
                ud.handles.calcDoseInSkin = uicontrol(hFig, 'style', 'checkbox', 'units', units, 'position', absPos([.20 .14 .7 .05], posFrame), 'string', 'Zero Dose outside Skin', 'value', stateS.optS.calcDoseInsideSkinOnly, 'tag', 'controlFrameItem', 'horizontalAlignment', 'center', 'callback', 'controlFrame(''colorbarcompare'', ''field_clicked'')', 'tooltip', SkinTipText);
                
                ud.handles.applyButton = uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', absPos([.1 .05 .35 .05], posFrame), 'string', 'Apply', 'tag', 'controlFrameItem', 'callback', 'controlFrame(''colorbarcompare'', ''apply'')');
                ud.handles.cancelButton = uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', absPos([.55 .05 .35 .05], posFrame), 'string', 'Exit', 'tag', 'controlFrameItem', 'callback', 'controlFrame(''colorbarcompare'', ''cancel'')');
                
                stateS.handle.controlFrameUd = ud ;
            case 'refresh'
                ud = stateS.handle.controlFrameUd ;
                if isempty(ud)
                    return;
                end
                try
                    set(ud.handles.CBRLow, 'string', num2str(stateS.colorbarRangeCompare(1)));
                    set(ud.handles.CBRHigh, 'string', num2str(stateS.colorbarRangeCompare(2)));
                    set(ud.handles.DDRLow, 'string', num2str(stateS.doseDisplayRangeCompare(1)));
                    set(ud.handles.DDRHigh, 'string', num2str(stateS.doseDisplayRangeCompare(2)));
                    colorbarChoices = stateS.optS.colorbarChoices;
                    currentMap = stateS.optS.doseColormap;
                    value = find(strcmpi(colorbarChoices, currentMap));
                    set(ud.handles.CBSPopup, 'string', colorbarChoices, 'value', value);
                end
                
            case 'apply'
                ud = stateS.handle.controlFrameUd ;
                if isempty(ud)
                    return;
                end
                stateS.colorbarRangeCompare(1) = min(str2num(get(ud.handles.CBRLow, 'string')), str2num(get(ud.handles.CBRHigh, 'string')));
                stateS.colorbarRangeCompare(2) = max(str2num(get(ud.handles.CBRLow, 'string')), str2num(get(ud.handles.CBRHigh, 'string')));
                stateS.doseDisplayRangeCompare(1) = min(str2num(get(ud.handles.DDRLow, 'string')), str2num(get(ud.handles.DDRHigh, 'string')));
                stateS.doseDisplayRangeCompare(2) = max(str2num(get(ud.handles.DDRLow, 'string')), str2num(get(ud.handles.DDRHigh, 'string')));
                stateS.optS.doseColormap = stateS.optS.colorbarChoices{get(ud.handles.CBSPopup, 'value')};
                
                stateS.optS.staticColorbar = get(ud.handles.SCBCheck, 'value');
                stateS.optS.negativeTexture = get(ud.handles.negativeTexture, 'value');
                stateS.optS.doubleSidedColorbar = get(ud.handles.doubleSidedColorbar, 'value');
                stateS.optS.transparentZeroDose = get(ud.handles.transparentZerodose, 'value');
                stateS.optS.calcDoseInsideSkinOnly = get(ud.handles.calcDoseInSkin, 'value');
                
                stateS.doseDisplayChanged = 1;
                CERRColorBar('refresh', stateS.handle.doseColorbar.trans);
                CERRColorBar('refresh', stateS.handle.doseColorbar.Compare); % also apply to comparison colorbar
                CERRRefresh;
                
                set(ud.handles.applyButton, 'FontWeight', 'Normal');
                
            case 'field_clicked'
                ud = stateS.handle.controlFrameUd ;
                set(ud.handles.applyButton, 'FontWeight', 'Bold');
                
            case 'cancel'
                controlFrame('default');
        end
        
    case 'isodose'
        if stateS.layout == 7
            colorbarFrameMin = stateS.colorbarFrameMinCompare;
            colorbarFrameMax =  stateS.colorbarFrameMaxCompare;
        else
            colorbarFrameMin = stateS.colorbarFrameMin;
            colorbarFrameMax =  stateS.colorbarFrameMax;
        end
        switch varargin{1}
            case 'init'
                numDose = length(planC{indexS.dose});
                if numDose < 1
                    warndlg('Cannot initiate without Dose','Isodose');
                    return
                end
                controlFrame('default');
                %Title
                ud.handles.title = uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units,...
                    'position', absPos([.05 .93 .9 .05], posFrame), 'string', 'Isodose Line Options', 'tag', ...
                    'controlFrameItem', 'horizontalAlignment', 'center', 'FontWeight', 'Bold');
                
                %Isodose Value Mode
                ud.handles.isoMode  = uicontrol(hFig, 'style', 'popupmenu', 'units', units,...
                    'position', absPos([.55 .87 .4 .05], posFrame), 'string', {'Auto', 'Manual'}, 'value', 1, 'tag',...
                    'controlFrameItem', 'horizontalAlignment', 'left', 'callback', 'controlFrame(''isodose'', ''field_clicked'')');
                uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units,'position', absPos([.05 .87 .4 .05], posFrame), 'string', 'Mode:', 'tag', ...
                    'controlFrameItem', 'horizontalAlignment', 'left');
                
                isoLevels = '';
                levels = stateS.optS.isodoseLevels;
                levels = sort(levels);
                for i =1:length(levels)
                    isoLevels = [isoLevels num2str(levels(i)) ' '];
                end
                
                ud.handles.isoValues= uicontrol(hFig, 'style', 'edit', 'units', units, 'position', absPos([.05 .66 .9 .13], posFrame),...
                    'string', isoLevels, 'tag', 'controlFrameItem', 'horizontalAlignment', 'left', 'callback', ...
                    'controlFrame(''isodose'', ''isoValues'')');
                uicontrol(hFig, 'style', 'text', 'enable', 'inactive', 'units', units, ...
                    'position', absPos([.05 .80 .9 .05], posFrame), 'string', 'Isodose Values:',...
                    'tag', 'controlFrameItem', 'horizontalAlignment', 'left');
                
                ud.handles.numAuto  = uicontrol(hFig, 'style', 'edit', 'units', units, 'position', absPos([.55 .59 .4 .05], posFrame),...
                    'string', num2str(stateS.optS.autoIsodoseLevels), 'tag', 'controlFrameItem', 'horizontalAlignment', 'left',...
                    'callback', 'controlFrame(''isodose'', ''autoIsodoseLevels'')');
                uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units,...
                    'position', absPos([.05 .59 .4 .05], posFrame), 'string', 'Auto Levels:', ...
                    'tag', 'controlFrameItem', 'horizontalAlignment', 'left');
                
                uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, ...
                    'position', absPos([.05 .52 .4 .05], posFrame), 'string', 'Auto Range:', ...
                    'tag', 'controlFrameItem', 'horizontalAlignment', 'left');
                
                
                ud.handles.maxDose  = uicontrol(hFig, 'style', 'radiobutton', 'units', units, 'position', absPos([.4 .52 .3 .05], posFrame),...
                    'string', 'Limits', 'tag', 'controlFrameItem', 'horizontalAlignment', 'left', 'callback',...
                    'controlFrame(''isodose'', ''maxDose'')');
                ud.handles.usrDose  = uicontrol(hFig, 'style', 'radiobutton', 'units', units, 'position', absPos([.7 .52 .28 .05], posFrame),...
                    'string', 'User', 'tag', 'controlFrameItem', 'horizontalAlignment', 'left', 'callback', ...
                    'controlFrame(''isodose'', ''usrDose'')');
                
                ud.handles.rangeMin  = uicontrol(hFig, 'style', 'edit', 'units', units, 'position', absPos([.05 .45 .4 .05], posFrame), ...
                    'string', '', 'tag', 'controlFrameItem', 'horizontalAlignment', 'left', 'callback', ...
                    'controlFrame(''isodose'', ''autoIsodoseLevels'')');
                ud.handles.rangeMax  = uicontrol(hFig, 'style', 'edit', 'units', units, 'position', absPos([.55 .45 .4 .05], posFrame),...
                    'string', '', 'tag', 'controlFrameItem', 'horizontalAlignment', 'left', 'callback', ...
                    'controlFrame(''isodose'', ''autoIsodoseLevels'')');
                
                if stateS.optS.autoIsodoseRangeMode == 1
                    set(ud.handles.maxDose, 'value', 1);
                    set(ud.handles.usrDose, 'value', 0);
                    set(ud.handles.rangeMin, 'string', num2str(colorbarFrameMin));
                    set(ud.handles.rangeMax, 'string', num2str(colorbarFrameMax));
                else
                    set(ud.handles.maxDose, 'value', 0);
                    set(ud.handles.usrDose, 'value', 1);
                    set(ud.handles.rangeMin, 'string', num2str(stateS.optS.autoIsodoseRange(1)));
                    set(ud.handles.rangeMax, 'string', num2str(stateS.optS.autoIsodoseRange(2)));
                end
                
                ud.handles.levelType= uicontrol(hFig, 'style', 'popupmenu', 'units', units, 'position', absPos([.55 .38 .4 .05], posFrame),...
                    'string', {'Absolute', 'Percent'}, 'value', 1, 'tag', 'controlFrameItem', 'horizontalAlignment', 'left', 'callback',...
                    'controlFrame(''isodose'', ''field_clicked'')');
                uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units,...
                    'position', absPos([.05 .38 .4 .05], posFrame), 'string', 'Level Type:',...
                    'tag', 'controlFrameItem', 'horizontalAlignment', 'left');
                
                ud.handles.doseType= uicontrol(hFig, 'style', 'popupmenu', 'enable', 'off', 'units', units, 'position', absPos([.32 .31 .25 .05], posFrame),...
                    'string', {'Max Dose', 'Mean Dose'}, 'value', 1, 'tag', 'controlFrameItem', 'horizontalAlignment', 'left', 'fontSize', 7, 'callback',...
                    'controlFrame(''isodose'', ''field_clicked'')');
                uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units,...
                    'position', absPos([.61 .31 .06 .05], posFrame), 'string', 'to',...
                    'tag', 'controlFrameItem', 'horizontalAlignment', 'center');
                ud.handles.structure= uicontrol(hFig, 'style', 'popupmenu', 'enable', 'off', 'units', units, 'position', absPos([.7 .31 .25 .05], posFrame),...
                    'string', ['Entire dose',{planC{indexS.structures}.structureName}], 'value', 1, 'tag', 'controlFrameItem', 'horizontalAlignment', 'left', 'fontSize', 7, 'callback',...
                    'controlFrame(''isodose'', ''field_clicked'')');
                uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units,...
                    'position', absPos([.05 .31 .25 .05], posFrame), 'string', 'Percent:',...
                    'tag', 'controlFrameItem', 'horizontalAlignment', 'left');
                
                ud.handles.lineThick= uicontrol(hFig, 'style', 'edit', 'units', units, 'position', absPos([.55 .24 .4 .05], posFrame),...
                    'string', num2str(stateS.optS.isodoseThickness), 'tag', 'controlFrameItem', 'horizontalAlignment', ...
                    'left', 'callback', 'controlFrame(''isodose'', ''lineThick'')');
                uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units,...
                    'position', absPos([.05 .24 .4 .05], posFrame), 'string', 'Line Thickness:',...
                    'tag', 'controlFrameItem', 'horizontalAlignment', 'left');
                
                ud.handles.matchColor= uicontrol(hFig, 'style', 'checkbox', 'units', units, 'position', absPos([.20 .19 .7 .05], posFrame),...
                    'string', 'Use Colorbar Colors', 'value', stateS.optS.isodoseUseColormap, 'tag', 'controlFrameItem', ...
                    'horizontalAlignment', 'center', 'callback', 'controlFrame(''isodose'', ''field_clicked'')');
                
                ud.handles.applyButton = uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', absPos([.1 .05 .35 .05], posFrame),...
                    'string', 'Apply', 'tag', 'controlFrameItem', 'callback', 'controlFrame(''isodose'', ''apply'')');
                ud.handles.cancelButton= uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', absPos([.55 .05 .35 .05], posFrame),...
                    'string', 'Exit', 'tag', 'controlFrameItem', 'callback', 'controlFrame(''isodose'', ''cancel'')');
                
                switch upper(stateS.optS.isodoseLevelMode)
                    case 'AUTO'
                        set(ud.handles.isoMode, 'value', 1);
                        set(ud.handles.isoValues, 'enable', 'off');
                        set(ud.handles.numAuto, 'enable', 'on');
                    case 'MANUAL'
                        set(ud.handles.isoMode, 'value', 2);
                        set(ud.handles.isoValues, 'enable', 'on');
                        set(ud.handles.numAuto, 'enable', 'off');
                end
                
                ud = stateS.handle.controlFrameUd ;
                controlFrame('isodose', 'refresh');
                
            case 'refresh'
                ud = stateS.handle.controlFrameUd ;
                if  get(ud.handles.levelType,'value') == 1 %Absolute
                    set(ud.handles.doseType,'enable','off')
                    set(ud.handles.structure,'enable','off')
                else %Percent
                    set(ud.handles.doseType,'enable','on')
                    set(ud.handles.structure,'enable','on')
                end
                switch get(ud.handles.isoMode, 'value')
                    case 1 %Auto
                        %Enable relevant, disable irrelevant UIs
                        set(ud.handles.isoValues, 'enable', 'off');
                        set(ud.handles.numAuto, 'enable', 'on');
                        set(ud.handles.maxDose, 'enable', 'on');
                        set(ud.handles.usrDose, 'enable', 'on');
                        
                        if get(ud.handles.maxDose, 'value') == 1
                            set(ud.handles.rangeMax, 'enable', 'off', 'string', num2str(colorbarFrameMax));
                            set(ud.handles.rangeMin, 'enable', 'off', 'string', num2str(colorbarFrameMin));
                        else
                            set(ud.handles.rangeMax, 'enable', 'on');
                            set(ud.handles.rangeMin, 'enable', 'on');
                        end
                        
                        numAuto = str2num(get(ud.handles.numAuto, 'string'));
                        minVal  = str2num(get(ud.handles.rangeMin, 'string'));
                        maxVal  = str2num(get(ud.handles.rangeMax, 'string'));
                        isodoseLevels = linspace(minVal,maxVal, numAuto+2);
                        isodoseLevels = isodoseLevels(2:end-1);
                        levelsString = '';
                        for i=1:length(isodoseLevels);
                            levelsString = [levelsString num2str(isodoseLevels(i)) ' '];
                        end
                        set(ud.handles.isoValues, 'string', levelsString);
                        
                    case 2 %Manual
                        %Enable relevant, disable irrelevant UIs
                        set(ud.handles.isoValues, 'enable', 'on');
                        set(ud.handles.numAuto, 'enable', 'off');
                        set(ud.handles.rangeMax, 'enable', 'off');
                        set(ud.handles.rangeMin, 'enable', 'off');
                        set(ud.handles.maxDose, 'enable', 'off');
                        set(ud.handles.usrDose, 'enable', 'off');
                end
                
            case 'field_clicked'
                controlFrame('isodose', 'refresh');
                
            case 'apply'
                ud = stateS.handle.controlFrameUd ;
                if isempty(ud)
                    return;
                end
                
                switch get(ud.handles.isoMode, 'value')
                    case 1 %Auto
                        stateS.optS.isodoseLevelMode = 'Auto';
                    case 2 %Manual
                        stateS.optS.isodoseLevelMode = 'Manual';
                end
                stateS.optS.isodoseLevels       = str2num(get(ud.handles.isoValues  , 'string'));
                stateS.optS.autoIsodoseLevels   = str2num(get(ud.handles.numAuto    , 'string'));
                stateS.optS.isodoseThickness    = str2num(get(ud.handles.lineThick  , 'string'));
                
                stateS.optS.isodoseUseColormap  =         get(ud.handles.matchColor , 'value');
                
                if get(ud.handles.maxDose, 'value') == 1
                    stateS.optS.autoIsodoseRangeMode = 1;
                else
                    stateS.optS.autoIsodoseRangeMode = 2;
                end
                
                stateS.optS.autoIsodoseRange = [str2num(get(ud.handles.rangeMin, 'string')) str2num(get(ud.handles.rangeMax, 'string'))];
                
                levelType = get(ud.handles.levelType, 'value');
                switch levelType
                    case 1 %Absolute
                        stateS.optS.isodoseLevelType = 'absolute';
                    case 2 %Percent
                        stateS.optS.isodoseLevelType = 'percent';
                        percentType = get(ud.handles.doseType, 'value');
                        stateS.optS.structureIndex = get(ud.handles.structure,'value');
                        if percentType == 1
                            stateS.optS.isodosePercentType = 'max';
                        else
                            stateS.optS.isodosePercentType = 'mean';
                        end
                end
                
                stateS.doseChanged = 1;
                stateS.doseDisplayChanged = 1;
                CERRRefresh;
                
            case 'cancel'
                controlFrame('default');
                
            case 'autoIsodoseLevels'
                ud = stateS.handle.controlFrameUd ;
                nLevels = str2num(get(ud.handles.numAuto, 'string'));
                if ~isempty(nLevels)
                    autoIsodoseLevels = clip(round(nLevels(1)), 1, Inf, 'limits');
                    set(ud.handles.numAuto, 'string', num2str(autoIsodoseLevels));
                end
                controlFrame('isodose', 'refresh');
                
            case 'usrDose'
                ud = stateS.handle.controlFrameUd ;
                set(ud.handles.maxDose, 'value', 0);
                controlFrame('isodose', 'refresh');
                
            case 'maxDose'
                ud = stateS.handle.controlFrameUd ;
                set(ud.handles.usrDose, 'value', 0);
                controlFrame('isodose', 'refresh');
                
            case 'isoValues'
                ud = stateS.handle.controlFrameUd ;
                levels = str2num(get(ud.handles.isoValues, 'string'));
                if isempty(levels)
                    set(ud.handles.isoValues, 'string', num2str(stateS.optS.isodoseLevels));
                end
                
            case 'lineThick'
                ud = stateS.handle.controlFrameUd ;
                thickness = str2num(get(ud.handles.lineThick, 'string'));
                if isempty(thickness)
                    set(ud.handles.lineThick, 'string', num2str(stateS.optS.isodoseThickness));
                else
                    set(ud.handles.lineThick, 'string', num2str(thickness(1)));
                end
        end
        
        %wy
    case 'clip'
        
        
        switch varargin{1}
            case 'init'
                controlFrame('default'); %clear the box
                
                ud.handles.regionButton = uicontrol(hFig, 'style', 'togglebutton', 'units', units, 'position',...
                    absPos([.1 .90 .80 .06], posFrame),'string', 'volume selection','tooltipstring','volume selection','callback',...
                    'controlFrame(''clip'', ''region'')','tag', 'controlFrameItem');
                
                ud.handles.saveButton = uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position',...
                    absPos([.1 .80 .80 .06], posFrame),'string', 'Generate Volume','tooltipstring','Generate Volume','callback',...
                    'controlFrame(''clip'', ''save'')','tag', 'controlFrameItem');
                
                ud.handles.exitButton = uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position',...
                    absPos([.1 .70 .80 .06], posFrame),'string', 'Exit','tooltipstring','exit','callback',...
                    'controlFrame(''clip'', ''exit'')','tag', 'controlFrameItem');
                stateS.handle.controlFrameUd = ud ;
                
            case 'region'
                button_state = get(gcbo,'Value');
                if button_state == get(gcbo,'Max')
                    stateS.clipState = 1;
                    CERRStatusString('Click/drag in axis. Right click to end.');
                    set(stateS.handle.CERRAxis, 'uicontextmenu', []);
                else
                    stateS.clipState = 0;
                    CERRStatusString('');
                    delete(findobj('tag', 'clipBox'));
                    plotedit('off');
                end
                
            case 'save'
                allLines = findobj('tag', 'clipBox', 'userdata', 'transverse');
                zLines =  findobj('tag', 'clipBox', 'userdata', 'sagittal');
                if isempty(allLines), return; end;
                xLim = get(allLines, 'xData');
                yLim = get(allLines, 'yData');
                
                if ~isempty(zLines), zLim = get(zLines, 'yData'); end;
                
                
                [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(stateS.scanSet));
                [xIndex0, jnk] = findnearest(xV, min(xLim));
                [xIndex1, jnk] = findnearest(xV, max(xLim));
                [yIndex0, jnk] = findnearest(yV, min(yLim));
                [yIndex1, jnk] = findnearest(yV, max(yLim));
                if ~isempty(zLines)
                    [zIndex0, jnk] = findnearest(zV, min(zLim));
                    [zIndex1, jnk] = findnearest(zV, max(zLim));
                else
                    zIndex0 = 1;
                    zIndex1 = size(planC{indexS.scan}(stateS.scanSet).scanArray, 3);
                end
                
                xRange = [xV(xIndex0) xV(xIndex1)]; %??????????????
                yRange = [yV(yIndex0) yV(yIndex1)]; %??????????????
                originXY = [min(xRange) min(yRange)];
                
                pScan = planC{indexS.scan}(stateS.scanSet);
                if isempty(zLines)
                    newVolume = pScan.scanArray(yIndex1:yIndex0, xIndex0:xIndex1, :);
                else
                    newVolume = pScan.scanArray(yIndex1:yIndex0, xIndex0:xIndex1, zIndex0:zIndex1);
                end
                planC{indexS.scan}(end+1).scanType = pScan.scanType;
                planC{indexS.scan}(end).scanArray = newVolume;
                planC{indexS.scan}(end).scanInfo = pScan.scanInfo(zIndex0:zIndex1);
                scanUID = createUID('scan');
                planC{indexS.scan}(end).scanUID = scanUID;
                
                for i = 1:length(planC{indexS.scan}(end).scanInfo)
                    
                    planC{indexS.scan}(end).scanInfo(i).sizeOfDimension1 = size(newVolume,1);
                    planC{indexS.scan}(end).scanInfo(i).sizeOfDimension2 = size(newVolume,2);
                    
                    if strcmpi(planC{indexS.scan}(end).scanInfo(i).scanType, 'CT')
                        planC{indexS.scan}(end).scanInfo(i).CTOffset = 1000;%-1*min(newVolume(:));
                    else
                        planC{indexS.scan}(end).scanInfo(i).CTOffset = 0;
                    end
                    
                    planC{indexS.scan}(end).scanInfo(i).xOffset = (xRange(1)+xRange(2))/2; %???????
                    planC{indexS.scan}(end).scanInfo(i).yOffset = (yRange(1)+yRange(2))/2;
                    
                    %                     scanInfo(i).zValue = ;
                end
                
                %                 planC = getRasterSegs(planC);
                planC = setUniformizedData(planC);
                
            case 'exit'
                stateS.clipState = 0;
                delete(findobj('tag', 'controlFrameItem'));
                
                for i=1:length(stateS.handle.CERRAxis)
                    hAxis       = stateS.handle.CERRAxis(i);
                    hOld = findobj(hAxis, 'tag', 'clipBox');
                    if ishandle(hOld)
                        delete(hOld);
                    end
                    oldMiscHandles = getAxisInfo(hAxis, 'miscHandles');
                    setAxisInfo(hAxis, 'miscHandles', setdiff(oldMiscHandles, [hOld]));
                end
                CERRRefresh;
                
        end
        
        %wy
    case 'refresh'
        
        ud = stateS.handle.controlFrameUd ;
        
        nScans = length(planC{indexS.scan});
        imageSets = {};
        for i = 1:nScans
            imageSets{end + 1} = ['Scan #' num2str(i) ' ' planC{indexS.scan}(i).scanInfo(1).imageType];
        end
        
        set(ud.handles.movingSet, 'string', imageSets, 'value', nScans);
        set(ud.handles.baseSet, 'string', imageSets, 'value', get(ud.handles.baseSet, 'value'));
        
        controlFrame('fusion', 'select_base_set');
        controlFrame('fusion', 'select_moving_set');
        
    case 'fusion'
        switch varargin{1}
            case 'init'
                if stateS.imageRegistration, return; end;

                if stateS.CTToggle == -1
                    hWarn = warndlg('Please turn on the scan');
                    waitfor(hWarn);
                    return;
                end
                
                controlFrame('default');
                
                if length(planC{planC{end}.scan}) < 2 & length(planC{planC{end}.dose})< 1
                    hWarn = warndlg('At least two scans or one scan and one dose are needed for image fusion.', 'Not enough data for fusion.');
                    waitfor(hWarn);
                    return;
                end
                
                clBarPos = get(stateS.handle.doseColorbar.trans,'position');
                clBarPosNew = clBarPos;
                clBarPosNew(4) = clBarPosNew(4) - 50;
                set(stateS.handle.doseColorbar.trans,'pos',clBarPosNew)
                
                colorbarShildBgClr = get(hFig,'color');
                
                %clear the control frame left tool bar;
                set(stateS.handle.CTSettingsFrame, 'visible', 'off');
                ctWindowObjs = findobj('Tag','CTWindow');
                set(ctWindowObjs, 'visible', 'off');
                set(stateS.handle.CTPreset, 'visible', 'off');
                set(stateS.handle.BaseCMap, 'visible', 'off');
                set(stateS.handle.CTWidth, 'visible', 'off');
                set(stateS.handle.CTLevel, 'visible', 'off');
                set(stateS.handle.CTLevelWidthInteractive, 'visible', 'off');
                set(stateS.handle.ScanTxtWindow,'visible','off')
                
                %tempControlPos = get(stateS.handle.controlFrame, 'pos');
                set(stateS.handle.controlFrame, 'pos', [0 0 195 600-270]);
                
                
                %move the zoom/slice buttons
                fPos = get(gcf, 'pos');
                dPos1 = [fPos(3)-250 -384   0 0];
                dPos2 = [fPos(3)-250 -384+8 0 0];
                
                %temploopTrans = get(stateS.handle.loopTrans, 'pos');
                %ud.handle.loopTransPos = temploopTrans;
                %set(stateS.handle.loopTrans, 'pos', dPos1+temploopTrans);
                
                %tempunloopTrans = get(stateS.handle.unloopTrans, 'pos');
                %ud.handle.unloopTransPos = tempunloopTrans;
                %set(stateS.handle.unloopTrans, 'pos', dPos1+tempunloopTrans);
                
                tempZoom = get(stateS.handle.zoom, 'pos');
                ud.handle.zoomPos = tempZoom;
                set(stateS.handle.zoom, 'pos', dPos1+tempZoom);
                
                tempresetZoom = get(stateS.handle.resetZoom, 'pos');
                ud.handle.resetZoomPos = tempresetZoom;
                set(stateS.handle.resetZoom, 'pos', dPos1+tempresetZoom);
                
                %temprulerTrans = get(stateS.handle.rulerTrans, 'pos');
                %ud.handle.rulerTransPos = temprulerTrans;
                %set(stateS.handle.rulerTrans, 'pos', dPos2+temprulerTrans);
                
                tempbuttonUp = get(stateS.handle.buttonUp, 'pos');
                ud.handle.buttonUpPos = tempbuttonUp;
                set(stateS.handle.buttonUp, 'pos', dPos1+tempbuttonUp);
                
                tempbuttonDwn = get(stateS.handle.buttonDwn, 'pos');
                ud.handle.buttonDwnPos = tempbuttonDwn;
                set(stateS.handle.buttonDwn, 'pos', dPos1+tempbuttonDwn);
                
                % hide the scan colorbar in fusion mode
                tempScanColorbar = get(stateS.handle.scanColorbar, 'pos');
                ud.handle.scanColorbarPos = tempScanColorbar;
                set(stateS.handle.scanColorbar, 'pos', [0 0 0.01 0.01]);
                
                
                %tempcapture = get(stateS.handle.capture, 'pos');
                %ud.handle.capturePos = tempcapture;
                %set(stateS.handle.capture, 'pos', dPos2+tempcapture);
                
                
                %                 % Set Color Bar Invisible
                uicontrol(hFig,'style','frame','position', [clBarPos(1)-5 clBarPos(2)-30 clBarPos(3)+9 clBarPos(4)+55],...
                    'tag', 'colorbarShild','Background',colorbarShildBgClr,'ForegroundColor',colorbarShildBgClr);
                
                % Set control toggling between base and moving scan
                %
                leftMarginWidth = 195; %obtained from from sliceCallback.m
                uicontrol(hFig,'style','toggle','units','pixels',...
                    'Position',[leftMarginWidth+10 490 25 20], 'tag','toggleBasMov',...
                    'string','B/M','fontWeight','normal','callBack','sliceCallBack(''toggleBaseMoving'');');
                if isdeployed
                    [I,map] = imread(fullfile(getCERRPath,'pics','Icons','lock.gif'),'gif');
                else
                    [I,map] = imread('lock.gif','gif');
                end
                lockImg = ind2rgb(I,map);
                uicontrol(hFig,'style','toggle','value',1,'units','pixels',...
                    'cdata',lockImg,'Position',[leftMarginWidth+10 460 25 20],...
                    'tag','toggleLockMoving','string','','fontWeight','normal',...
                    'callBack','sliceCallBack(''toggleLockMoving'');');
                
                %Which data is being registered?
                baseData     = stateS.imageRegistrationBaseDataset;
                baseDataType = stateS.imageRegistrationBaseDatasetType;
                movData      = stateS.imageRegistrationMovDataset;
                movDataType  = stateS.imageRegistrationMovDatasetType;
                
                stateS.optS.checkerBoard = 0;
                
                %wy
                stateS.optS.checkerBoard = 0;
                stateS.optS.difference = 0;
                stateS.optS.newchecker = 0;
                stateS.optS.mirror = 0;
                stateS.optS.showMirrorLocators = 0;
                stateS.optS.blockmatch = 0;
                stateS.optS.mirrorscope = 0;
                stateS.optS.mirrchecker = 0;
                stateS.optS.mirrorCheckerBoard = 0;
                %stateS.imageFusion.lockMoving = 1;
                %wy
                
                % change the label of the slider bar
                set(findobj('tag','sliderInit'),'visible','off');
                
                hSlider = findobj('tag','sliderInit');
                
                uicontrol(hFig,'units','pixels','Position',get(hSlider(1),'position'),'String','Base',...
                    'Style','text', 'enable', 'inactive','tag','sliderFusion','BackgroundColor',get(hSlider(1),'BackgroundColor'));
                uicontrol(hFig,'units','pixels','Position',get(hSlider(2),'position'),'String','Move',...
                    'Style','text', 'enable', 'inactive','tag','sliderFusion','BackgroundColor',get(hSlider(2),'BackgroundColor'));
                
                stateS.fusionTransM = 0; % added by DK for supporting CERRHotKeys for translation
                
                %Clear old controlFrame.
                delete(findobj('tag', 'controlFrameItem'));
                
                
                %Find scan and dose names for selection menus.
                stateS.toggle_rotation = 0;
                stateS.rotation_down = 0;
                imageSets = {}; doseSets = {};
                nScans = length(planC{indexS.scan});
                
                for i = 1:nScans
                    %imageSets{end + 1} = ['Scan # ' num2str(i) ': ' planC{indexS.scan}(i).scanInfo(1).imageType];
                    imageSets{end + 1} = ['Scan # ' num2str(i) ': ' planC{indexS.scan}(i).scanType];
                end
                
                allDataSets = imageSets;
                
                nDose = length(planC{indexS.dose});
                
                for i = 1:nDose
                    allDataSets{end + 1} = ['Dose # ' num2str(i) ': ' planC{indexS.dose}(i).fractionGroupID];
                end
                
                if nScans == 1 && nDose >= 1
                    stateS.imageRegistrationMovDataset = 1;
                    stateS.imageRegistrationMovDatasetType = 'dose';
                    movData      = stateS.imageRegistrationMovDataset;
                    movDataType  = stateS.imageRegistrationMovDatasetType;
                end
                
%                 %initial moving CTLevel and Window
%                 if ~isfield(stateS, 'Mov')
%                     scanNum = stateS.imageRegistrationMovDataset;
%                     dataType = stateS.imageRegistrationMovDatasetType;
%                     if strcmpi(dataType,'scan')
%                         CTLevel = 'temp';
%                         CTWidth = 'temp';
%                         if isfield(planC{indexS.scan}(scanNum).scanInfo(1),'DICOMHeaders') && isfield(planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders,'WindowCenter') && isfield(planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders,'WindowWidth')
%                             CTLevel = planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders.WindowCenter(end);
%                             CTWidth = planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders.WindowWidth(end);
%                         end
%                         if isnumeric(CTLevel) && isnumeric(CTWidth)
%                             stateS.Mov.CTLevel = CTLevel;
%                             stateS.Mov.CTWidth = CTWidth;
%                         else
%                             stateS.Mov.CTLevel = 0;
%                             stateS.Mov.CTWidth = 300;
%                         end
%                     else
%                         stateS.Mov.CTLevel = mean(planC{indexS.dose}(scanNum).doseArray(:));
%                         stateS.Mov.CTWidth = stateS.Mov.CTLevel*2;
%                     end
%                 end
                
                %Calculate which menu items are selected for registration.
                if strcmpi(baseDataType,'dose')
                    baseData = baseData + nScans;
                end
                if strcmpi(movDataType,'dose')
                    movData = movData + nScans;
                end
                
%                 switch lower(stateS.optS.fusionDisplayMode)
%                     case 'colorblend'
%                         dispMode = 1;
%                     case 'canny'
%                         dispMode = 2;
%                 end
                
                %---------data selection------------
                ud.handles.seperator0 = uicontrol(gcf,'style','frame','units','pixel', ...
                    'position',[0 600-5 leftMarginWidth 1],...
                    'tag', 'controlFrameItem');
                uicontrol(gcf, 'style', 'text', 'enable', 'inactive' , 'units', 'pixel', ...
                    'position', [0 600-28 leftMarginWidth-1 20], 'string', 'Data Selection', 'tag', 'controlFrameItem',...
                    'horizontalAlignment', 'center', 'FontWeight', 'Bold');
                
                %Select base set.
                dy = 1;
                uicontrol(gcf, 'style', 'text', 'enable', 'inactive' , 'units', 'pixel', ...
                    'position', [10 600-50-dy 50 20], 'string', 'Base:', ...
                    'tag', 'controlFrameItem', 'horizontalAlignment', 'left');
                ud.handles.baseSet = uicontrol(gcf, 'style', 'popupmenu', 'units', 'pixel', ...
                    'position', [60 600-45-dy 125 20], ...
                    'string', allDataSets, 'value', baseData,'tag', 'controlFrameItem', 'horizontalAlignment', 'left', ...
                    'callback', 'controlFrame(''fusion'', ''select_base_set'')');
                
                %base window frame
                dy = 2;
                uicolor = stateS.optS.UIColor;
                frameWidth = leftMarginWidth - 20;
                uicontrol(gcf,'units','pixels', 'string', '', 'BackgroundColor',uicolor, ...
                    'Position', [10 600-135-dy frameWidth 85],'Style','frame', 'Tag','controlFrameItem');
                %CT Window text
                uicontrol(gcf,'units','pixels','BackgroundColor',uicolor, ...
                    'Position',[20 600-75-dy (frameWidth-30)/2 20],'String','bWindow', 'Style','text', ...
                    'enable', 'inactive'  ,'Tag','controlFrameItem');
                %Scan ColorMap text
                uicontrol(gcf,'units','pixels','BackgroundColor',uicolor, ...
                    'Position',[(frameWidth-30)/2+20+10 600-75-dy (frameWidth-30)/2 20],'String','bColormap', ...
                    'Style','text', 'enable', 'inactive'  ,'Tag','controlFrameItem');
                %CT Center Text
                uicontrol(gcf,'units','pixels','BackgroundColor',uicolor, ...
                    'Position',[20 600-115-dy (frameWidth-30)/2 20], 'String','bCenter','Style','text', ...
                    'enable', 'inactive', 'Tag','controlFrameItem');
                %CT Width Text
                uicontrol(gcf,'units','pixels','BackgroundColor',uicolor, ...
                    'Position',[(frameWidth-30)/2+20+10 600-115-dy (frameWidth-30)/2 20], 'String','bWidth', ...
                    'Style','text', 'enable', 'inactive' ,'Tag','controlFrameItem');
                
                %Presets dropdown.
                stringPresetC = get(stateS.handle.CTPreset,'string');
                presetValue = get(stateS.handle.CTPreset,'value');                
                ud.handles.basePreset = uicontrol(gcf,'units','pixels', 'BackgroundColor',uicolor, ...
                    'Position',[20 600-90-dy (frameWidth-30)/2 20], 'String',stringPresetC, ...
                    'Style','popup','Tag','controlFrameItem', 'value', presetValue, ...
                    'callback','controlFrame(''fusion'', ''basepreset'')', ...
                    'tooltipstring','Select Preset Window');
                %Base Colormap Presets dropdown.
                stringCmapC = get(stateS.handle.BaseCMap,'string');
                cmapValue = get(stateS.handle.BaseCMap,'value');
                ud.handles.basedisplayModeColor = uicontrol(gcf,'units','pixels', 'BackgroundColor',uicolor, ...
                    'Position',[(frameWidth-30)/2+20+10 600-90-dy (frameWidth-30)/2 20], ...
                    'String',stringCmapC,'value',cmapValue,'Style','popup','Tag','controlFrameItem', ...
                    'callback','controlFrame(''fusion'', ''basecolormap'')','tooltipstring','Select Scan Color Map','Enable','On');
                %CTLevel edit box
                ud.handles.baseCTLevel = uicontrol(gcf,'units','pixels', 'BackgroundColor',uicolor, ...
                    'Position',[20 600-130-dy (frameWidth-30)/2 20], 'String',num2str(stateS.optS.CTLevel),'Style','edit', ...
                    'Tag','controlFrameItem', 'callback','controlFrame(''fusion'', ''basectlevel'')','tooltipstring','Change CT window center');
                %CT Width edit box.
                ud.handles.baseCTWidth = uicontrol(gcf,'units','pixels','BackgroundColor',uicolor, ...
                    'Position',[(frameWidth-30)/2+20+10 600-130-dy (frameWidth-30)/2 20], 'String',num2str(stateS.optS.CTWidth), ...
                    'Style','edit','Tag','controlFrameItem', 'callback','controlFrame(''fusion'', ''basectwidth'')', ...
                    'tooltipstring', 'Change CT window width');                
                
                
                %Select moving set.
                dy = 10;
                uicontrol(gcf, 'style', 'text', 'enable', 'inactive' , 'units', 'pixel',...
                    'position', [10 600-165-dy 50 20], 'string', 'Moving:', ...
                    'tag', 'controlFrameItem', 'horizontalAlignment', 'left');
                ud.handles.movingSet = uicontrol(gcf, 'style', 'popupmenu', 'units', 'pixel', ...
                    'position', [60 600-160-dy 125 20], 'string', allDataSets, 'value', movData, ...
                    'tag', 'controlFrameItem', 'horizontalAlignment', 'left',...
                    'callback', 'controlFrame(''fusion'', ''select_moving_set'')');
                
                frameWidth = leftMarginWidth - 20;
                uicontrol(gcf,'units','pixels', 'string', '', 'BackgroundColor',uicolor, ...
                    'Position', [10 600-250-dy frameWidth 85],'Style','frame', 'Tag','controlFrameItem');
                %CT Window text
                uicontrol(gcf,'units','pixels','BackgroundColor',uicolor, ...
                    'Position',[20 600-190-dy (frameWidth-30)/2 20],'String','mWindow', 'Style','text', ...
                    'enable', 'inactive'  ,'Tag','controlFrameItem');
                %Scan ColorMap
                uicontrol(gcf,'units','pixels','BackgroundColor',uicolor, ...
                    'Position',[(frameWidth-30)/2+20+10 600-190-dy (frameWidth-30)/2 20],'String','mColormap', ...
                    'Style','text', 'enable', 'inactive'  ,'Tag','controlFrameItem');
                %CT Center Text
                uicontrol(gcf,'units','pixels','BackgroundColor',uicolor, ...
                    'Position',[20 600-230-dy (frameWidth-30)/2 20], 'String','mCenter','Style','text', ...
                    'enable', 'inactive', 'Tag','controlFrameItem');
                %CT Width Text
                uicontrol(gcf,'units','pixels','BackgroundColor',uicolor, ...
                    'Position',[(frameWidth-30)/2+20+10 600-230-dy (frameWidth-30)/2 20], 'String','mWidth', ...
                    'Style','text', 'enable', 'inactive' ,'Tag','controlFrameItem');
                
                %Presets dropdown.
                ud.handles.MovPresets = uicontrol(hFig,'units','pixels','Position',[20 600-205-dy (frameWidth-30)/2 20],...
                    'String',stringPresetC,'value',presetValue,'Style','popup','Tag','controlFrameItem', ...
                    'callback','controlFrame(''fusion'', ''movpreset'')',...
                    'tooltipstring','Select Moving Data Preset Window');
                
                %Select display mode.
                ud.handles.displayModeColor= uicontrol(hFig, 'style', 'popupmenu', 'units', units, ...
                    'position', [(frameWidth-30)/2+20+10 600-205-dy (frameWidth-30)/2 20],...
                    'string', stringCmapC, 'value', cmapValue, ...
                    'tag', 'controlFrameItem', 'horizontalAlignment', 'left',...
                    'callback', 'controlFrame(''fusion'', ''movcolormap'')');
                
                %CTLevel edit box
                ud.handles.MovCTLevel = uicontrol(hFig,'units','pixels','Position',[20 600-245-dy (frameWidth-30)/2 20],...
                    'String',num2str(stateS.optS.CTLevel),'Style','edit','Tag','controlFrameItem', ...
                    'callback','controlFrame(''fusion'', ''movctlevel'')',...
                    'tooltipstring','Change Moving Data window center');
                
                %CT Width edit box.
                ud.handles.MovCTWidth = uicontrol(hFig,'units','pixels','Position',[(frameWidth-30)/2+20+10 600-245-dy (frameWidth-30)/2 20],...
                    'String',num2str(stateS.optS.CTWidth),'Style','edit','Tag','controlFrameItem', 'callback','controlFrame(''fusion'', ''movctwidth'')',...
                    'tooltipstring','Change Moving Data window width');
                
                
                % ______________________Registration _________________________________________________________________________________________
                %
                dy = 0.20;
                ud.handles.trackTxt = uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, ...
                    'position', absPos([.05 .56+dy .9 .05], posFrame), 'string', 'Registration', 'tag', 'controlFrameItem',...
                    'horizontalAlignment', 'center', 'FontWeight', 'Bold');
                
%                 ud.handles.RegButton = uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position',...
%                     absPos([.05 .52+dy .90 .05], posFrame),'string', 'Auto Registration','tooltipstring','Auto Registration', ...
%                     'callback', 'CERRRegistrationRigidSetup(''init'', guihandles)','tag', 'controlFrameItem');
                
                ud.handles.RegButton = uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position',...
                    absPos([.05 .52+dy .90 .05], posFrame),'string', 'Auto Rigid Register','tooltipstring','Auto Registration', ...
                    'callback', 'controlFrame(''fusion'', ''rigid_registration'')','tag', 'controlFrameItem');

                if isdeployed
                    [I,map] = imread(fullfile(getCERRPath,'pics','Icons','tool_rotate_3d.gif'),'gif');
                else
                    [I,map] = imread('tool_rotate_3d.gif','gif');
                end
                rotateImg = ind2rgb(I,map);
                
                ud.handles.rotateButton = uicontrol(hFig, 'style', 'togglebutton', 'cdata', rotateImg, 'units', units, 'position',...
                    absPos([.05 .46+dy .12 .05], posFrame),'tooltipstring','Rotate Image','callback',...
                    'controlFrame(''fusion'', ''toggle_rotation'')','tag', 'controlFrameItem');
                
                ud.handles.autoRegButton= uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', absPos([.2 .46+dy .75 .05], posFrame),...
                    'string', 'Auto Bounding', 'tag', 'controlFrameItem', 'callback', 'controlFrame(''fusion'', ''auto_registration'')');
                
                
                % ____________________Analysis ___________________________________________________________________________________________
                %
                ud.handles.seperator3 = uicontrol(hFig,'style','frame','units',units,'position',absPos([0 .44+dy 1 .002], posFrame),...
                    'tag', 'controlFrameItem');
                
                ud.handles.analyasisTxt = uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, ...
                    'position', absPos([.05 .38+dy .9 .05], posFrame), 'string', 'Analysis', 'tag', 'controlFrameItem',...
                    'horizontalAlignment', 'center', 'FontWeight', 'Bold');
                
                
                ud.handles.differToggle= uicontrol(hFig, 'style',  'togglebutton','units', units, 'position', absPos([.05 .34+dy .45 .05], posFrame),...
                    'string', 'Difference', 'tag', 'controlFrameItem', 'callback', 'controlFrame(''fusion'', ''difference'')', ... %'registerAnalysis(''difference'')',...
                    'tooltipstring','View 2 image difference', 'interrupt', 'off');
                
                
                % Mirror Checkerboard
                ud.handles.mirror_checkerToggle= uicontrol(hFig, 'style',  'togglebutton','units', units, 'position', absPos([.50 .34+dy .45 .05], posFrame),...
                    'string', 'Mirror ChkBd', 'tag', 'controlFrameItem', 'callback', 'controlFrame(''fusion'', ''mirror_checker_board'')',...
                    'tooltipstring','Mirror CheckerBoard', 'fontsize', 7, 'interrupt', 'off');
                
                %-------------------------
                ud.handles.checkerToggle= uicontrol(hFig, 'style',  'togglebutton','units', units, 'position', absPos([.05 .28+dy .45 .05], posFrame),...
                    'string', 'Blended ChkBd', 'tag', 'controlFrameItem', 'callback', 'controlFrame(''fusion'', ''checker_board'')',...
                    'tooltipstring','View Overlay in CheckerBoard', 'fontsize', 7, 'interrupt', 'off');
                
                %------------new checkerboard-------------
                ud.handles.newcheckerToggle= uicontrol(hFig, 'style',  'togglebutton','units', units, 'position', absPos([.50 .28+dy .45 .05], posFrame),...
                    'string', 'standard ChkBd', 'tag', 'controlFrameItem', 'callback', 'controlFrame(''fusion'', ''newchecker_board'')',...
                    'tooltipstring','View in CheckerBoard', 'fontsize', 7, 'interrupt', 'off');
                
                ud.handles.ckSizeText = uicontrol(hFig, 'style',  'text','units', units, 'position', absPos([.05 .205+dy .15 .05], posFrame),...
                    'string', 'Size:', 'tag', 'controlFrameItem', ...
                    'tooltipstring','CheckerBoard Size', 'visible', 'off');
                
                ud.handles.ckSizeValue = uicontrol(hFig, 'style',  'text','units', units, 'position', absPos([.17 .205+dy .09 .05], posFrame),...
                    'string', '4', 'tag', 'controlFrameItem', ...
                    'tooltipstring','CheckerBoard Size', 'visible', 'off');
                
                ud.handles.newcheckerSize= uicontrol(hFig, 'style',  'slider','units', units, 'position', absPos([.27 .22+dy .35 .04], posFrame),...
                    'string', 'CB Size', 'tag', 'controlFrameItem', 'min', 2, 'max', 20, 'sliderstep', [1 2], 'value', 4, ...
                    'BusyAction', 'cancel', 'Interruptible', 'off', ...
                    'tooltipstring','CheckerBoard Size', 'callback', 'controlFrame(''fusion'', ''checkerSlider'')', 'visible', 'off');
                
                ud.handles.mirrorcheckerOrientation = uicontrol(hFig, 'style','popupmenu','units', units, 'position', absPos([.65 .23+dy .3 .04], posFrame),...
                    'string', {'Left Mirror','Right Mirror'}, 'tag', 'controlFrameItem', 'value', 1, ...
                    'BusyAction', 'cancel', 'Interruptible', 'off', ...
                    'tooltipstring','Left/Right size mirror', 'callback', 'CERRRefresh', 'visible', 'off');
                
                ud.handles.mirrorcheckerMetricString = uicontrol(hFig, 'style','text','units', units, 'position', absPos([.05 .15+dy .15 .04], posFrame),...
                    'string', 'Metric', 'tag', 'controlFrameItem', ...
                    'BusyAction', 'cancel', 'Interruptible', 'off', ...
                    'tooltipstring','Metric for comparison', 'visible', 'off');
                
                ud.handles.mirrorcheckerMetricPopup = uicontrol(hFig, 'style','popupmenu','units', units, 'position', absPos([.25 .16+dy .25 .04], posFrame),...
                    'string', {'MI (Mutual Information)', 'MSE (Mean Squared Error)'}, 'tag', 'controlFrameItem', ...
                    'BusyAction', 'cancel', 'Interruptible', 'off', ...
                    'tooltipstring','Metric for comparison', 'callback', 'CERRRefresh', 'visible', 'off');
                
                %                 ud.handles.mirrorcheckerAxis = axes('units', units, 'position', absPos([.65 .15+dy .15 .04], posFrame), 'xTickLabel', [], 'yTickLabel', [], 'xTick', [], 'yTick', [], 'visible', 'on');
                %                 cM = CERRColorMap('starinterp');
                %                 nColors = size(cM,1);
                %                 tmpV    = nColors:-1:1;
                %                 cB      = ind2rgb(tmpV, cM);
                %                 imagesc([0 1],[0.5 0.5] ,cB, 'parent',ud.handles.mirrorcheckerAxis)
                
                %--------------mirror------------
                
                ud.handles.mirrorToggle= uicontrol(hFig, 'style',  'togglebutton','units', units, 'position', absPos([.05 .22+dy .45 .05], posFrame),...
                    'string', 'Image Mirror', 'tag', 'controlFrameItem', 'callback', 'controlFrame(''fusion'', ''imagemirror'')',...
                    'tooltipstring','image mirror', 'interrupt', 'off');
                ud.handles.mirrorScopeToggle= uicontrol(hFig, 'style',  'togglebutton','units', units, 'position', absPos([.5 .22+dy .45 .05], posFrame),...
                    'string', 'Mirror Scope', 'tag', 'controlFrameItem', 'callback', 'controlFrame(''fusion'', ''mirrorscope'')',...
                    'tooltipstring','mirror scope', 'interrupt', 'off');
                
                ud.handles.mirrScopeText = uicontrol(hFig, 'style',  'text','units', units, 'position', absPos([.05 .145+dy .25 .05], posFrame),...
                    'string', 'Size(cm):', 'tag', 'controlFrameItem', ...
                    'visible', 'off');
                
                ud.handles.mirrScopeValue = uicontrol(hFig, 'style',  'text','units', units, 'position', absPos([.30 .145+dy .1 .05], posFrame),...
                    'string', '10', 'tag', 'controlFrameItem', ...
                    'tooltipstring','mirror size value', 'visible', 'off');
                
                ud.handles.mirrScope= uicontrol(hFig, 'style',  'slider','units', units, 'position', absPos([.40 .16+dy .55 .04], posFrame),...
                    'string', 'Size', 'tag', 'controlFrameItem', 'min', 1, 'max', 25, 'sliderstep', [0.04 0.12], 'value', 10, ...
                    'BusyAction', 'cancel', 'Interruptible', 'off', ...
                    'tooltipstring','mirror scope size', 'callback', 'controlFrame(''fusion'', ''mirrorSlider'')', 'visible', 'off');
                
                %----------------blockmatch------------------
                ud.handles.blockMatchToggle= uicontrol(hFig, 'style',  'togglebutton','units', units, 'position', absPos([.05 .16+dy .9 .05], posFrame),...
                    'string', 'BlockMatch', 'tag', 'controlFrameItem', 'callback', 'controlFrame(''fusion'', ''blockmatch'')',...
                    'tooltipstring','block match comparison', 'interrupt', 'off', 'visible','off');
                
                %----------------mirrorcheckerboard------------------
                %                 ud.handles.mirrcheckerToggle= uicontrol(hFig, 'style',  'togglebutton','units', units, 'position', absPos([.1 .111 .8 .05], posFrame),...
                %                     'string', 'Mirror CheckerBoard', 'tag', 'controlFrameItem', 'callback', 'controlFrame(''fusion'', ''mirrchecker_board'')',...
                %                     'tooltipstring','View in CheckerBoard', 'interrupt', 'off');
                
                %               -----------------save, select, and copy---------------
                ud.handles.seperator3 = uicontrol(hFig,'style','frame','units',units,'position',absPos([0 .13+dy 1 .002], posFrame), ...
                    'tag', 'controlFrameItem');
                
                uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, ...
                    'position', absPos([.1 .06+dy .8 .05], posFrame), 'string', 'Transform Management', 'tag', 'controlFrameItem',...
                    'horizontalAlignment', 'center', 'FontWeight', 'Bold');
                
                ud.handles.saveTransM = uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', ...
                    absPos([.05 .02+dy .35 .05], posFrame), 'tooltipstring','save the current transform matrix', ...
                    'string', 'Save', 'tag', 'controlFrameItem', 'callback', 'controlFrame(''fusion'', ''saveTransM'')');
                
                ud.handles.selectTransM= uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', ...
                    absPos([.4 .02+dy .55 .05], posFrame), 'tooltipstring','select or delete a saved transform matrix', ...
                    'string', 'Select/Del', 'tag', 'controlFrameItem', 'callback', 'controlFrame(''fusion'', ''selectTransM'')');
                
                ud.handles.cancelTransM= uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', ...
                    absPos([.05 dy-.04 .3 .05], posFrame), 'tooltipstring','cancel the moving operation', ...
                    'string', 'Undo', 'tag', 'controlFrameItem', 'callback', 'controlFrame(''fusion'', ''cancelTransM'')');
                
                %Button to reset moving dataSet.
                ud.handles.copyToTransM = uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', ...
                    absPos([.35 dy-.04 .3 .05], posFrame), 'tooltipstring','copy current transform to other scanSet', ...
                    'string', 'copyTo', 'tag', 'controlFrameItem', 'callback', 'controlFrame(''fusion'', ''copyToTransM'')');
                
                ud.handles.resetMoving = uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', absPos([.65 dy-.04 .3 .05], posFrame),...
                    'string', 'Reset', 'tag', 'controlFrameItem', 'callback', 'controlFrame(''fusion'', ''resetMoving'')');
                
                ud.handles.exitButton= uicontrol(hFig, 'style', 'pushbutton', 'units', units, 'position', absPos([0.2 .02 0.6 .05], posFrame),...
                    'string', 'Exit', 'tag', 'controlFrameItem', 'callback', 'controlFrame(''fusion'', ''exit'')');
                % _________________________________________________________________________
                
                
                ud.clBarPos = clBarPos;
                stateS.handle.controlFrameUd = ud;
                controlFrame('fusion', 'select_base_set','init');
                controlFrame('fusion', 'select_moving_set','init');
                sliceCallBack('fusion_mode_on');
                
                
                %                 %Draw Legend.
                %                 for i=1:length(stateS.handle.CERRAxis)
                %                     hAxis = stateS.handle.CERRAxis(i);
                %                     view = getAxisInfo(hAxis, 'view');
                %                     if strcmpi(view, 'legend')
                %                         showCERRLegend(hAxis);
                %                     end
                %                 end
                
            case 'movpreset'
                ud = stateS.handle.controlFrameUd ;
                
                value = get(ud.handles.MovPresets, 'Value');
                
                %scanSet = getAxisInfo(stateS.handle.CERRAxis(stateS.currentAxis),'scanSets');
                %scanSet = scanSet(2);
                
                scanSet = stateS.imageRegistrationMovDataset;
                
                if value ~= 1
                    %stateS.Mov.CTLevel = stateS.optS.windowPresets(value).center;
                    %stateS.Mov.CTWidth = stateS.optS.windowPresets(value).width;
                    set(ud.handles.MovCTLevel, 'String', num2str(stateS.optS.windowPresets(value).center));
                    set(ud.handles.MovCTWidth, 'String', num2str(stateS.optS.windowPresets(value).width));
                    if strcmpi(stateS.imageRegistrationMovDatasetType,'scan')
                        scanUID = ['c',repSpaceHyp(planC{indexS.scan}(scanSet).scanUID(max(1,end-61):end))];
                        stateS.scanStats.CTLevel.(scanUID) = stateS.optS.windowPresets(value).center;
                        stateS.scanStats.CTWidth.(scanUID) = stateS.optS.windowPresets(value).width;
                    end
                end
                
                stateS.CTDisplayChanged = 1;
                
                if isempty(planC)
                    return
                end
                
                CERRRefresh;
                return
                
            case 'basepreset'
                ud = stateS.handle.controlFrameUd ;
                
                value = get(ud.handles.basePreset, 'Value');
                
                %scanSet = getAxisInfo(stateS.handle.CERRAxis(stateS.currentAxis),'scanSets');
                %scanSet = scanSet(2);
                
                scanSet = stateS.imageRegistrationBaseDataset;
                
                if value ~= 1
                    %stateS.Mov.CTLevel = stateS.optS.windowPresets(value).center;
                    %stateS.Mov.CTWidth = stateS.optS.windowPresets(value).width;
                    set(ud.handles.baseCTLevel, 'String', num2str(stateS.optS.windowPresets(value).center));
                    set(ud.handles.baseCTWidth, 'String', num2str(stateS.optS.windowPresets(value).width));
                    if strcmpi(stateS.imageRegistrationBaseDatasetType,'scan')
                        scanUID = ['c',repSpaceHyp(planC{indexS.scan}(scanSet).scanUID(max(1,end-61):end))];
                        stateS.scanStats.CTLevel.(scanUID) = stateS.optS.windowPresets(value).center;
                        stateS.scanStats.CTWidth.(scanUID) = stateS.optS.windowPresets(value).width;
                    end
                end
                
                stateS.CTDisplayChanged = 1;
                
                if isempty(planC)
                    return
                end
                
                CERRRefresh;
                return                
                
            case 'movctlevel'
                
                if strcmpi(stateS.imageRegistrationMovDatasetType,'scan')
                    ud = stateS.handle.controlFrameUd ;
                    
                    set(ud.handles.MovPresets, 'Value', 1);
                    
                    level = str2num(get(ud.handles.MovCTLevel,'String'));
                    
                    %stateS.Mov.CTLevel = str2num(str);
                    
                    %scanSet = getAxisInfo(stateS.handle.CERRAxis(stateS.currentAxis),'scanSets');
                    %scanSet = scanSet(2);
                    scanSet = stateS.imageRegistrationMovDataset;
                    scanUID = ['c',repSpaceHyp(planC{indexS.scan}(scanSet).scanUID(max(1,end-61):end))];
                    stateS.scanStats.CTLevel.(scanUID) = level;
                end
                
                stateS.CTDisplayChanged =1;
                
                CERRRefresh;
                return;
                
            case 'basectlevel'
                
                if strcmpi(stateS.imageRegistrationBaseDatasetType,'scan')

                    ud = stateS.handle.controlFrameUd ;
                    
                    set(ud.handles.basePreset, 'Value', 1);
                    
                    level = str2num(get(ud.handles.baseCTLevel,'String'));
                    
                    %stateS.Mov.CTLevel = str2num(str);
                    
                    %scanSet = getAxisInfo(stateS.handle.CERRAxis(stateS.currentAxis),'scanSets');
                    %scanSet = scanSet(2);
                    scanSet = stateS.imageRegistrationBaseDataset;
                    scanUID = ['c',repSpaceHyp(planC{indexS.scan}(scanSet).scanUID(max(1,end-61):end))];
                    stateS.scanStats.CTLevel.(scanUID) = level;
                end
                
                stateS.CTDisplayChanged =1;
                
                CERRRefresh;
                return;
                
            case 'movctwidth'
                
                if strcmpi(stateS.imageRegistrationMovDatasetType,'scan')
                    ud = stateS.handle.controlFrameUd ;
                    
                    set(ud.handles.MovPresets, 'Value', 1);
                    
                    width = str2num(get(ud.handles.MovCTWidth,'String'));
                    
                    %stateS.Mov.CTWidth = str2num(str);
                    
                    %scanSet = getAxisInfo(stateS.handle.CERRAxis(stateS.currentAxis),'scanSets');
                    %scanSet = scanSet(2);
                    scanSet = stateS.imageRegistrationMovDataset;
                    scanUID = ['c',repSpaceHyp(planC{indexS.scan}(scanSet).scanUID(max(1,end-61):end))];
                    stateS.scanStats.CTWidth.(scanUID) = width;
                end
                
                stateS.CTDisplayChanged =1;
                
                CERRRefresh;
                return
                
            case 'basectwidth'
                
                if strcmpi(stateS.imageRegistrationBaseDatasetType,'scan')
                    ud = stateS.handle.controlFrameUd ;
                    
                    set(ud.handles.basePreset, 'Value', 1);
                    
                    width = str2num(get(ud.handles.baseCTWidth,'String'));
                    
                    %stateS.Mov.CTWidth = str2num(str);
                    
                    %scanSet = getAxisInfo(stateS.handle.CERRAxis(stateS.currentAxis),'scanSets');
                    %scanSet = scanSet(2);
                    scanSet = stateS.imageRegistrationBaseDataset;
                    scanUID = ['c',repSpaceHyp(planC{indexS.scan}(scanSet).scanUID(max(1,end-61):end))];
                    stateS.scanStats.CTWidth.(scanUID) = width;
                end

                stateS.CTDisplayChanged =1;
                
                CERRRefresh;
                return                
                
                
            case 'movcolormap'
                if strcmpi(stateS.imageRegistrationMovDatasetType,'scan')
                    ud = stateS.handle.controlFrameUd ;
                    scanSet = stateS.imageRegistrationMovDataset;
                    scanUID = ['c',repSpaceHyp(planC{indexS.scan}(scanSet).scanUID(max(1,end-61):end))];
                    cmapStrC = get(ud.handles.displayModeColor,'String');
                    cmapVal = get(ud.handles.displayModeColor,'value');
                    stateS.scanStats.Colormap.(scanUID) = cmapStrC{cmapVal};
                    
                    stateS.CTDisplayChanged =1;
                end
                
                CERRRefresh;                
                return                               
                
                
            case 'basecolormap'
                if strcmpi(stateS.imageRegistrationBaseDatasetType,'scan')
                    ud = stateS.handle.controlFrameUd ;
                    scanSet = stateS.imageRegistrationBaseDataset;
                    scanUID = ['c',repSpaceHyp(planC{indexS.scan}(scanSet).scanUID(max(1,end-61):end))];
                    cmapStrC = get(ud.handles.basedisplayModeColor,'String');
                    cmapVal = get(ud.handles.basedisplayModeColor,'value');
                    stateS.scanStats.Colormap.(scanUID) = cmapStrC{cmapVal};
                    
                    stateS.CTDisplayChanged =1;
                end
                
                CERRRefresh;
                return
                
                
            case 'select_base_set'
                ud = stateS.handle.controlFrameUd ;
                baseSet = get(ud.handles.baseSet, 'value');
                stateS.imageRegistrationBaseDataset = baseSet;
                nScans = length(planC{indexS.scan});
                if baseSet <= nScans
                    stateS.imageRegistrationBaseDataset = baseSet;
                    stateS.imageRegistrationBaseDatasetType = 'scan';
                else
                    stateS.imageRegistrationBaseDataset = baseSet-nScans;
                    stateS.imageRegistrationBaseDatasetType = 'dose';
                end
                updateBaseLevelWidthHandles()
                if ~(length(varargin) == 2)
                    sliceCallBack('fusion_mode_on');
                end
                
                
            case 'select_moving_set'
                ud = stateS.handle.controlFrameUd ;
                movingSet = get(ud.handles.movingSet, 'value');
                nScans = length(planC{indexS.scan});
                if movingSet <= nScans
                    stateS.imageRegistrationMovDataset = movingSet;
                    stateS.imageRegistrationMovDatasetType = 'scan';
                else
                    stateS.imageRegistrationMovDataset = movingSet-nScans;
                    stateS.imageRegistrationMovDatasetType = 'dose';
                end
                
                updateMovLevelWidthHandles()
                
                if ~(length(varargin) == 2)
                    sliceCallBack('fusion_mode_on');
                end
                
                
                %wy backup the current transM
                try
                    if ~isfield(planC{indexS.(stateS.imageRegistrationMovDatasetType)}(stateS.imageRegistrationMovDataset), 'transM')
                        planC{indexS.(stateS.imageRegistrationMovDatasetType)}(stateS.imageRegistrationMovDataset).transM = eye(4);
                        planC{indexS.(stateS.imageRegistrationMovDatasetType)}(stateS.imageRegistrationMovDataset).transMCur = eye(4);
                    else
                        planC{indexS.(stateS.imageRegistrationMovDatasetType)}(stateS.imageRegistrationMovDataset).transMCur = planC{indexS.(stateS.imageRegistrationMovDatasetType)}(stateS.imageRegistrationMovDataset).transM;
                    end
                catch
                    disp('error');
                end
                
                
            case 'auto_registration'
                scanSetB = stateS.imageRegistrationBaseDataset;
                scanSetM = stateS.imageRegistrationMovDataset;
                
                COMB = getXYCOM(scanSetB,'base');
                COMM = getXYCOM(scanSetM,'move');
                
                deltaXYZ = COMB - COMM;
                
                newTransform = eye(4);
                
                newTransform(:,4) = [reshape(deltaXYZ, 3,1);1];
                
                oldTransM = getTransM(stateS.imageRegistrationMovDatasetType, scanSetM, planC);
                
                if isempty(oldTransM)
                    oldTransM = eye(4);
                end
                
                planC{indexS.(stateS.imageRegistrationMovDatasetType)}(scanSetM).transM = (newTransform * oldTransM);
                
                CERRRefresh;
                
            case 'rigid_registration'
                scanSetBase = stateS.imageRegistrationBaseDataset;
                scanSetMov = stateS.imageRegistrationMovDataset;
                [~,planC] = register_scans(planC, planC, scanSetBase, scanSetMov, 'RIGID PLASTIMATCH', [], [], []);
                %planC = register_scans(planC, planC, scanSetBase, scanSetMov, 'BSPLINE PLASTIMATCH', [], [], []);
                indexS = planC{end};
                %planC = warp_scan(planC{indexS.deform}(scanSetBase),scanSetMov,planC,planC);
                stateS.CTDisplayChanged = 1;
                CERRRefresh;
                
            case 'toggle_rotation'
                ud = stateS.handle.controlFrameUd ;
                hObject = ud.handles.rotateButton;
                
                button_state = get(hObject,'Value');
                
                if button_state == get(hObject,'Max')
                    % toggle button is pressed
                    stateS.toggle_rotation = 1;
                    
                    %[I,map] = imread('rotate_cursor','gif');
                    %I = double(I);
                    %I(find(I<1))= NaN;
                    %set(hFig,'Pointer','custom','PointerShapeCData',I,'PointerShapeHotSpot',[9 9]);
                    
                    %                     leftMarginWidth = 195; %from slicecallback;
                    %                     hSlider = findobj('tag','sliderInit');
                    %                     uicontrol(hFig, 'style',  'text','units', units, 'position', [leftMarginWidth+10 440 25 20],...
                    %                     'string', 'RS', 'tag', 'rotSpeedBar', 'BackgroundColor',get(hSlider(1),'BackgroundColor'), ...
                    %                     'tooltipstring','Rotation Speed', 'visible', 'on');
                    %
                    %                     uicontrol(hFig, 'style',  'slider','units', units, 'position', [leftMarginWidth+10 380 25 70],...
                    %                     'tag', 'rotSpeedBar', 'min', 10, 'max', 210, 'sliderstep', [0.05 0.1], ...
                    %                     'value', 100, 'tooltipstring','Rotation Speed', 'BackgroundColor',get(hSlider(1),'BackgroundColor'));
                    
                elseif button_state == get(hObject,'Min')
                    % toggle button is not pressed
                    stateS.toggle_rotation = 0;
                    %set(gcf,'Pointer','arrow');
                    delete(findobj('tag', 'rotSpeedBar'));
                    if stateS.rotation_down
                        stateS.rotation_down = 0;
                        CTImageRotation('up')
                        set(gcf,'Pointer','arrow');
                        delete(findobj('tag', 'rotSpeedBar'));
                    end
                end
                
            case 'display_mode'
                % change display mode to different color maps for moving set
                hAxes = stateS.handle.CERRAxis;
                modeNum = get(gcbo, 'value');
                stateS.optS.fusionDisplayMode = 'colorblend';
                
                for i=1:length(hAxes);
                    ud = get(hAxes(i), 'userdata');
                    for j=1:length(ud.scanObj);
                        ud.scanObj(j).redraw = 1;
                    end
                    set(hAxes(i), 'userdata', ud);
                    showCT(hAxes(i));
                    showDose(hAxes(i));
                end
                %change color of Base-Moving toggle-button
                udFrame = get(stateS.handle.controlFrame,'userdata');
                clrVal = get(udFrame.handles.displayModeColor,'value');
                clrM = [0 0 0; 1 0.8 0.5; 1 0 0; 0 1 0; 0 0 1; 0 1 0; 0 0 1];
                hToggleBaseMov = findobj('tag', 'toggleBasMov');
                if get(hToggleBaseMov,'value') == 1
                    set(hToggleBaseMov,'string','M','fontWeight','bold','foregroundColor',clrM(clrVal,:))
                    %set(hToggleBaseMov,'foregroundColor',clrM(clrVal,:))
                else
                    set(hToggleBaseMov,'string','B','fontWeight','bold','foregroundColor',[0 0 0]);
                    %set(hToggleBaseMov,'foregroundColor',[0 0 0])
                end
                %wy
            case 'saveTransM'
                if stateS.toggle_rotation
                    msgbox('Please get out of rotation mode before saving transformation','Rotation Active','modal');
                    return;
                end
                movingSet = indexS.(stateS.imageRegistrationMovDatasetType);
                setNum = stateS.imageRegistrationMovDataset;
                if ~isfield(planC{movingSet}(setNum), 'transM')
                    planC{movingSet}(setNum).transM = eye(4);
                    planC{movingSet}(setNum).transMCur = eye(4);
                    return;
                elseif isempty(planC{movingSet}(setNum).transM)
                    msgbox('The current transM is empty, saving is cancelled.','system message','warn');
                    return;
                end
                saved = 0;
                while 1
                    name = inputdlg('Enter the name:', 'Save the current transM');
                    if isempty(name), break; end;
                    name = strtrim(char(name));
                    if isempty(name), continue, end;
                    savedTran.name = name;
                    savedTran.transM = planC{movingSet}(setNum).transM;
                    if ~isfield(planC{movingSet}(setNum), 'savedtransM')
                        planC{movingSet}(setNum).savedtransM = savedTran;
                        saved = 1;
                        break;
                    end
                    if ~isempty(planC{movingSet}(setNum).savedtransM)
                        names = [];
                        for i=1:length(planC{movingSet}(setNum).savedtransM)
                            names{i} = planC{movingSet}(setNum).savedtransM(i).name;
                        end
                        ind = NaN;
                        for i=1:length(names)
                            if strcmpi(names{i}, name)
                                ind = i;
                                break;
                            end
                        end
                        if ~isnan(ind)
                            button = questdlg('this name already exists, do you want to overwrite it?','message');
                            switch lower(button)
                                case 'yes'
                                    planC{movingSet}(setNum).savedtransM(i) = savedTran;
                                    saved = 1;
                                    break;
                                case 'no'
                                    continue;
                                case 'cancel'
                                    break;
                            end
                        else
                            planC{movingSet}(setNum).savedtransM(end+1) = savedTran;
                            saved = 1;
                            break;
                        end
                    else
                        planC{movingSet}(setNum).savedtransM = savedTran;
                        saved = 1;
                        break;
                    end
                    
                end
                if (saved)
                    planC{movingSet}(setNum).transMCur = planC{movingSet}(setNum).transM;
                end
                
            case 'selectTransM'
                movingSet = indexS.(stateS.imageRegistrationMovDatasetType);
                setNum = stateS.imageRegistrationMovDataset;
                if ~isfield(planC{movingSet}(setNum), 'savedtransM')
                    msgbox('no saved transM found.','system message','warn');
                    return;
                end
                d = planC{movingSet}(setNum).savedtransM;
                str = {d.name};
                [selection,value] = seldellistdlg('PromptString','Select a transform:',...
                    'SelectionMode','single',...
                    'ListSize', [200, 300], ...
                    'Name', 'TransM selection', ...
                    'ListString',str, ...
                    'okstring', 'Select', ...
                    'cancelstring', 'Delete');
                if ~isempty(selection)&&(value == 1) %select transM
                    planC{movingSet}(setNum).transM = planC{movingSet}(setNum).savedtransM(selection).transM;
                    planC{movingSet}(setNum).transMCur = planC{movingSet}(setNum).transM;
                    CERRRefresh;
                end
                if ~isempty(selection)&&(value == 0) %delete transM
                    planC{movingSet}(setNum).savedtransM(selection) = [];
                    
                end
                
            case 'cancelTransM'
                movingSet = indexS.(stateS.imageRegistrationMovDatasetType);
                setNum = stateS.imageRegistrationMovDataset;
                if isfield(planC{movingSet}(setNum), 'transMCur')
                    planC{movingSet}(setNum).transM = planC{movingSet}(setNum).transMCur;
                end
                CERRRefresh;
                
            case 'copyToTransM'
                movingSet = indexS.(stateS.imageRegistrationMovDatasetType);
                setNum = stateS.imageRegistrationMovDataset;
                if ~isfield(planC{movingSet}(setNum), 'transM')
                    msgbox('The current transM is empty, operation is cancelled.','system message','warn');
                    return;
                end
                ud = stateS.handle.controlFrameUd ;
                str = get(ud.handles.movingSet, 'string');
                [selection,ok] = listdlg('PromptString','Select a scanSet:',...
                    'SelectionMode','single',...
                    'ListSize', [200, 300], ...
                    'Name', 'Copy To ...', ...
                    'ListString',str);
                if (~isempty(selection) && ok)
                    nScans = length(planC{indexS.scan});
                    if selection <= nScans
                        selectedSet = indexS.scan;
                    else
                        selectedSet = indexS.dose;
                        selection = selection-nScans;
                    end
                    planC{selectedSet}(selection).transM = planC{movingSet}(setNum).transM;
                    planC{selectedSet}(selection).transMCur = planC{movingSet}(selection).transM;
                end
                CERRRefresh;
                
            case 'resetMoving'
                setNum = stateS.imageRegistrationMovDataset;
                setType = stateS.imageRegistrationMovDatasetType;
                
                if strcmpi(setType, 'scan');
                    planC{indexS.scan}(setNum).transM = eye(4);
                    planC{indexS.scan}(setNum).transMCur = eye(4);
                elseif strcmpi(setType, 'dose');
                    planC{indexS.dose}(setNum).transM = eye(4);
                    planC{indexS.dose}(setNum).transMCur = eye(4);
                end
                CERRRefresh;
                
            case 'centerScan'
                hAxes = stateS.handle.CERRAxis;
                for i=1:length(planC{indexS.scan})
                    [xV{i}, yV{i}, zV{i}] = getScanXYZVals(planC{indexS.scan}(i));
                end
                
                scanSet = stateS.imageRegistrationScanset;
                planC{indexS.scan}(scanSet).transM = eye(4);
                CERRRefresh;
                
            case 'apply'
                hAxes = stateS.handle.CERRAxis;
                if any(stateS.fusionTransM)
                    trans2DM = stateS.fusionTransM;
                else
                    trans2DM = CTImageRotation('getTransM');
                end
                hAxis = varargin{2};
                axisInfo = get(hAxis, 'userdata');
                
                setNum = stateS.imageRegistrationMovDataset;
                setType = stateS.imageRegistrationMovDatasetType;
                
                deltaTransM = eye(4);
                try
                    switch axisInfo.view;
                        case 'transverse'
                            deltaTransM(1:2, 1:2) = trans2DM(1:2,1:2);
                            deltaTransM(1:2, 4) = trans2DM(1:2,3);
                        case 'sagittal'
                            deltaTransM(2:3, 2:3) = trans2DM(1:2,1:2);
                            deltaTransM(2:3, 4) = trans2DM(1:2,3);
                        case 'coronal'
                            deltaTransM([1 3], [1 3]) = trans2DM(1:2,1:2);
                            deltaTransM([1 3], 4) = trans2DM(1:2,3);
                    end
                catch
                    deltaTransM = eye(4);
                end
                if strcmpi(setType, 'scan');
                    if isfield(planC{indexS.scan}, 'transM') & ~isempty(planC{indexS.scan}(setNum).transM);
                        planC{indexS.scan}(setNum).transM = inv(deltaTransM) * planC{indexS.scan}(setNum).transM;
                        %planC{indexS.scan}(setNum).transMCur = inv(deltaTransM) * planC{indexS.scan}(setNum).transM;
                    else
                        planC{indexS.scan}(setNum).transM = inv(deltaTransM);
                        %planC{indexS.scan}(setNum).transMCur = inv(deltaTransM);
                        %                         doseNum = getScanAssociatedDose(setNum,'all');
                        %                         for i = 1:length(doseNum)
                        %                             planC{indexS.dose}(doseNum(i)).transM = inv(deltaTransM); %wy doseNum(i);
                        %                         end
                    end
                elseif strcmpi(setType, 'dose');
                    if isfield(planC{indexS.dose}, 'transM') & ~isempty(planC{indexS.dose}(setNum).transM);
                        planC{indexS.dose}(setNum).transM = inv(deltaTransM) * planC{indexS.dose}(setNum).transM;
                        %planC{indexS.dose}(setNum).transMCur = inv(deltaTransM) * planC{indexS.dose}(setNum).transM;
                    else
                        planC{indexS.dose}(setNum).transM = inv(deltaTransM);
                        %planC{indexS.dose}(setNum).transMCur = inv(deltaTransM);
                    end
                    stateS.CTDisplayChanged = 1;
                end
                
                %Display mutual information metric (Added by APA based on code by IEN)
                vw = getAxisInfo(hAxis,'view');
                switch upper(vw)
                    case 'CORONAL'
                        dim = 2;
                    case 'SAGITTAL'
                        dim = 1;
                    case 'TRANSVERSE'
                        dim = 3;
                    otherwise
                        return;
                end
                coord = getAxisInfo(hAxis,'coord');
                scanSets = getAxisInfo(hAxis,'scanSets');
                if length(scanSets)>1 %wy in case moving is dose
                    [slc1, sliceXVals1, sliceYVals1] = getCTOnSlice(scanSets(1), coord, dim, planC);
                    [slc2, sliceXVals2, sliceYVals2] = getCTOnSlice(scanSets(2), coord, dim, planC);
                    try
                        slc1(isnan(slc1)) = 0;
                        slc2(isnan(slc2)) = 0;
                        %Interpolate scan2 on scan1
                        slc2int1 = finterp2(sliceXVals2, sliceYVals2, slc2, sliceXVals1, sliceYVals1, 1, 0);
                        mi = get_mi(slc1,slc2int1,256);
                        CERRStatusString(['Mutual Information Metric = ',num2str(mi)])
                    catch
                        msgbox('mi error!');
                    end
                end
                CERRRefresh;
                
                %             case 'get_mutualInfo'
                %                 global stateS
                %                 ud = get(stateS.handle.CERRAxis(1),'userdata');
                %                 ud.scanObj.coord;
                %                 x=(planC{indexS.scan}(baseData ).scanArray(:,:,20));
                %                 y=(planC{indexS.scan}(movData).scanArray(:,:,20));
                %                 MI=get_mutualinfo(x,y,8);
                % %                  MI=get_mutualinfo(baseData,movData);
                %                 ud.handles.fusion = uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, ...
                %                     'position', absPos([.43 .48 .42 .05], posFrame),'string', num2str(MI), ...
                %                     'tag', 'controlFrameItem', 'horizontalAlignment', 'left');
                
            case 'checker_board'
                ud = stateS.handle.controlFrameUd ;
                hObject = ud.handles.checkerToggle;
                button_state = get(hObject,'Value');
                if button_state == get(hObject,'Max')
                    % toggle button is pressed
                    stateS.optS.checkerBoard = 1;
                    set(ud.handles.ckSizeText, 'visible', 'on');
                    set(ud.handles.ckSizeValue, 'visible', 'on');
                    set(ud.handles.newcheckerSize, 'visible', 'on');
                    
                    set(ud.handles.differToggle, 'enable', 'off');
                    set(ud.handles.mirror_checkerToggle, 'enable', 'off');
                    set(ud.handles.newcheckerToggle, 'enable', 'off');
                    set(ud.handles.mirrorToggle, 'visible', 'off');
                    set(ud.handles.mirrorScopeToggle, 'visible', 'off');
                    set(ud.handles.blockMatchToggle, 'visible', 'off');
                elseif button_state == get(hObject,'Min')
                    % toggle button is not pressed
                    stateS.optS.checkerBoard = 0;
                    set(ud.handles.ckSizeText, 'visible', 'off');
                    set(ud.handles.ckSizeValue, 'visible', 'off');
                    set(ud.handles.newcheckerSize, 'visible', 'off');
                    
                    set(ud.handles.differToggle, 'enable', 'on');
                    set(ud.handles.mirror_checkerToggle, 'enable', 'on');
                    set(ud.handles.newcheckerToggle, 'enable', 'on');
                    set(ud.handles.mirrorToggle, 'visible', 'on');
                    set(ud.handles.mirrorScopeToggle, 'visible', 'on');
                    %set(ud.handles.blockMatchToggle, 'visible', 'on'); %
                    %decommissioned until "MeanSquare2D_64" is fixed.
                end
                
                %                 if button_state == get(hObject,'Max')
                %                     % toggle button is pressed
                %                     stateS.optS.checkerBoard = 1;
                % %                     set(ud.handles.differToggle, 'visible', 'off');
                % %                     set(ud.handles.newcheckerToggle, 'visible', 'off');
                % %                     set(ud.handles.mirrorToggle, 'visible', 'off');
                % %                     set(ud.handles.mirrorScopeToggle, 'visible', 'off');
                % %                     set(ud.handles.blockMatchToggle, 'visible', 'off');
                %                     set(ud.handles.differToggle, 'enable', 'off');
                %                     set(ud.handles.newcheckerToggle, 'enable', 'off');
                %                     set(ud.handles.mirrorToggle, 'enable', 'off');
                %                     set(ud.handles.mirrorScopeToggle, 'enable', 'off');
                %                     set(ud.handles.blockMatchToggle, 'enable', 'off');
                %
                %                 elseif button_state == get(hObject,'Min')
                %                     % toggle button is not pressed
                %                     stateS.optS.checkerBoard = 0;
                % %                     set(ud.handles.differToggle, 'visible', 'on');
                % %                     set(ud.handles.newcheckerToggle, 'visible', 'on');
                % %                     set(ud.handles.mirrorToggle, 'visible', 'on');
                % %                     set(ud.handles.mirrorScopeToggle, 'visible', 'on');
                % %                     set(ud.handles.blockMatchToggle, 'visible', 'on');
                %                     set(ud.handles.differToggle, 'enable', 'on');
                %                     set(ud.handles.newcheckerToggle, 'enable', 'on');
                %                     set(ud.handles.mirrorToggle, 'enable', 'on');
                %                     set(ud.handles.mirrorScopeToggle, 'enable', 'on');
                %                     set(ud.handles.blockMatchToggle, 'enable', 'on');
                %                 end
                CERRRefresh;
                %wy
                %wy
            case 'difference'
                ud = stateS.handle.controlFrameUd ;
                hObject = ud.handles.differToggle;
                button_state = get(hObject,'Value');
                
                if button_state == get(hObject,'Max')
                    % toggle button is pressed
                    stateS.optS.difference = 1;
                    set(ud.handles.mirror_checkerToggle, 'enable', 'off');
                    set(ud.handles.checkerToggle, 'enable', 'off');
                    set(ud.handles.newcheckerToggle, 'enable', 'off');
                    set(ud.handles.mirrorToggle, 'enable', 'off');
                    set(ud.handles.mirrorScopeToggle, 'enable', 'off');
                    set(ud.handles.blockMatchToggle, 'enable', 'off');
                elseif button_state == get(hObject,'Min')
                    % toggle button is not pressed
                    stateS.optS.difference = 0;
                    set(ud.handles.mirror_checkerToggle, 'enable', 'on');
                    set(ud.handles.checkerToggle, 'enable', 'on');
                    set(ud.handles.newcheckerToggle, 'enable', 'on');
                    set(ud.handles.mirrorToggle, 'enable', 'on');
                    set(ud.handles.mirrorScopeToggle, 'enable', 'on');
                    set(ud.handles.blockMatchToggle, 'enable', 'on');
                end
                CERRRefresh;
                
                
            case 'newchecker_board'
                ud = stateS.handle.controlFrameUd ;
                hObject = ud.handles.newcheckerToggle;
                button_state = get(hObject,'Value');
                
                if button_state == get(hObject,'Max')
                    % toggle button is pressed
                    stateS.optS.newchecker = 1;
                    set(ud.handles.ckSizeText, 'visible', 'on');
                    set(ud.handles.ckSizeValue, 'visible', 'on');
                    set(ud.handles.newcheckerSize, 'visible', 'on');
                    
                    set(ud.handles.differToggle, 'enable', 'off');
                    set(ud.handles.mirror_checkerToggle, 'enable', 'off');
                    set(ud.handles.checkerToggle, 'enable', 'off');
                    set(ud.handles.mirrorToggle, 'visible', 'off');
                    set(ud.handles.mirrorScopeToggle, 'visible', 'off');
                    set(ud.handles.blockMatchToggle, 'visible', 'off');
                elseif button_state == get(hObject,'Min')
                    % toggle button is not pressed
                    stateS.optS.newchecker = 0;
                    set(ud.handles.ckSizeText, 'visible', 'off');
                    set(ud.handles.ckSizeValue, 'visible', 'off');
                    set(ud.handles.newcheckerSize, 'visible', 'off');
                    
                    set(ud.handles.differToggle, 'enable', 'on');
                    set(ud.handles.mirror_checkerToggle, 'enable', 'on');
                    set(ud.handles.checkerToggle, 'enable', 'on');
                    set(ud.handles.mirrorToggle, 'visible', 'on');
                    set(ud.handles.mirrorScopeToggle, 'visible', 'on');
                    set(ud.handles.blockMatchToggle, 'visible', 'on');
                end
                CERRRefresh;
                
                
                %             case 'mirrchecker_board'
                %                 ud = get(hFrame,'userdata');
                %                 hObject = ud.handles.mirrcheckerToggle;
                %                 button_state = get(hObject,'Value');
                %
                %                 scanSetM = stateS.imageRegistrationMovDataset;
                %                 scanSetF = stateS.imageRegistrationBaseDataset;
                % %                 if isequal(size(planC{indexS.scan}(scanSetF).scanArray), size(planC{indexS.scan}(scanSetM).scanArray))
                %
                %                     if button_state == get(hObject,'Max')
                %                         % toggle button is pressed
                %                         stateS.optS.mirrchecker = 1;
                %
                %                     elseif button_state == get(hObject,'Min')
                %                         % toggle button is not pressed
                %                         stateS.optS.mirrchecker = 0;
                %
                %                     end
                %                     CERRRefresh;
                % %                 end
                
            case 'mirror_checker_board'
                ud = stateS.handle.controlFrameUd ;
                hObject = ud.handles.mirror_checkerToggle;
                button_state = get(hObject,'Value');
                if button_state == get(hObject,'Max')
                    % toggle button is pressed
                    stateS.optS.mirrorCheckerBoard = 1;
                    set(ud.handles.ckSizeText, 'visible', 'on');
                    set(ud.handles.ckSizeValue, 'visible', 'on');
                    set(ud.handles.newcheckerSize, 'visible', 'on');
                    set(ud.handles.newcheckerSize, 'visible', 'on');
                    set(ud.handles.mirrorcheckerOrientation, 'visible', 'on');
                    set(ud.handles.mirrorcheckerMetricString, 'visible', 'on');
                    set(ud.handles.mirrorcheckerMetricPopup, 'visible', 'on');
                    %set(ud.handles.mirrorcheckerAxis, 'visible', 'on');
                    
                    set(ud.handles.differToggle, 'enable', 'off');
                    set(ud.handles.newcheckerToggle, 'enable', 'off');
                    set(ud.handles.checkerToggle, 'enable', 'off');
                    set(ud.handles.mirrorToggle, 'visible', 'off');
                    set(ud.handles.mirrorScopeToggle, 'visible', 'off');
                    set(ud.handles.blockMatchToggle, 'visible', 'off');
                    
                elseif button_state == get(hObject,'Min')
                    % toggle button is not pressed
                    stateS.optS.mirrorCheckerBoard = 0;
                    set(ud.handles.ckSizeText, 'visible', 'off');
                    set(ud.handles.ckSizeValue, 'visible', 'off');
                    set(ud.handles.newcheckerSize, 'visible', 'off');
                    set(ud.handles.mirrorcheckerOrientation, 'visible', 'off');
                    set(ud.handles.mirrorcheckerMetricString, 'visible', 'off');
                    set(ud.handles.mirrorcheckerMetricPopup, 'visible', 'off');
                    %set(ud.handles.mirrorcheckerAxis, 'visible', 'off');
                    
                    set(ud.handles.differToggle, 'enable', 'on');
                    set(ud.handles.newcheckerToggle, 'enable', 'on');
                    set(ud.handles.checkerToggle, 'enable', 'on');
                    set(ud.handles.mirrorToggle, 'visible', 'on');
                    set(ud.handles.mirrorScopeToggle, 'visible', 'on');
                    set(ud.handles.blockMatchToggle, 'visible', 'on');
                end
                
                CERRRefresh
                
                
            case 'checkerSlider'
                ud = stateS.handle.controlFrameUd ;
                set(ud.handles.ckSizeValue, 'string', num2str(floor(get(gcbo, 'value'))));
                CERRRefresh;
                
            case 'imagemirror'
                ud = stateS.handle.controlFrameUd ;
                hObject = ud.handles.mirrorToggle;
                button_state = get(hObject,'Value');
                
                %                 scanSetM = stateS.imageRegistrationMovDataset;
                %                 scanSetF = stateS.imageRegistrationBaseDataset;
                %                 if isequal(size(planC{indexS.scan}(scanSetF).scanArray), size(planC{indexS.scan}(scanSetM).scanArray))
                
                if button_state == get(hObject,'Max')
                    % toggle button is pressed
                    stateS.optS.mirror = 1;
                    %                         set(ud.handles.differToggle, 'visible', 'off');
                    %                         set(ud.handles.checkerToggle, 'visible', 'off');
                    %                         set(ud.handles.newcheckerToggle, 'visible', 'off');
                    %                         set(ud.handles.mirrorScopeToggle, 'visible', 'off');
                    %                         set(ud.handles.blockMatchToggle, 'visible', 'off');
                    set(ud.handles.differToggle, 'enable', 'off');
                    set(ud.handles.mirror_checkerToggle, 'enable', 'off');
                    set(ud.handles.checkerToggle, 'enable', 'off');
                    set(ud.handles.newcheckerToggle, 'enable', 'off');
                    set(ud.handles.mirrorScopeToggle, 'enable', 'off');
                    set(ud.handles.blockMatchToggle, 'enable', 'off');
                    
                    stateS.showPlaneLocators = 0;
                    
                    %[xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(stateS.imageRegistrationBaseDataset));
                    for i=1:length(stateS.handle.CERRAxis)
                        hAxis       = stateS.handle.CERRAxis(i);
                        [view, coord] = getAxisInfo(hAxis, 'view', 'coord');
                        
                        %scanSets = getAxisInfo(hAxis,'scanSets');
                        
                        xLimit = get(hAxis, 'xLim');
                        yLimit = get(hAxis, 'yLim');
                        
                        oldMiscHandles = getAxisInfo(hAxis, 'miscHandles');
                        
                        switch lower(view)
                            case 'transverse'
                                [slc1, xV, yV] = getCTOnSlice(stateS.imageRegistrationBaseDataset, coord, 3, planC);
                                ind = find(xV>=median(xV));
                                %ind = find(xV>=min(xV)+(max(xV)-min(xV))/2);
                                
                                stateS.handle.aI(i).axisFusion.MirrorScopeLocator = ...
                                    line([xV(ind(1)) xV(ind(1))], yLimit, [2 2], 'parent', hAxis, 'color', [1 1 1], 'tag', 'mirrorLocator', ...
                                    'buttondownfcn', 'controlFrame(''fusion'', ''mirrorLocatorClicked'')', ...
                                    'userdata', {'vert', 'transverse', ind(1)}, 'hittest', 'on');
                                
                            case 'sagittal'
                                [slc1, xV, yV] = getCTOnSlice(stateS.imageRegistrationBaseDataset, coord, 1, planC);
                                if (xV(2)>xV(1))
                                    ind = find(xV>=median(xV));
                                else
                                    ind = find(xV<=median(xV));
                                end
                                
                                stateS.handle.aI(i).axisFusion.MirrorScopeLocator = ...
                                    line([xV(ind(1)) xV(ind(1))], yLimit, [2 2], 'parent', hAxis, 'color', [1 1 1], 'tag', 'mirrorLocator', ...
                                    'buttondownfcn', 'controlFrame(''fusion'', ''mirrorLocatorClicked'')', ...
                                    'userdata', {'vert', 'sagittal', ind(1)}, 'hittest', 'on');
                                
                            case 'coronal'
                                [slc1, xV, yV] = getCTOnSlice(stateS.imageRegistrationBaseDataset, coord, 2, planC);
                                ind = find(xV>=median(xV));
                                
                                stateS.handle.aI(i).axisFusion.MirrorScopeLocator = ...
                                    line([xV(ind(1)) xV(ind(1))], yLimit, [2 2], 'parent', hAxis, 'color', [1 1 1], 'tag', 'mirrorLocator', ...
                                    'buttondownfcn', 'controlFrame(''fusion'', ''mirrorLocatorClicked'')', ...
                                    'userdata', {'vert', 'coronal', ind(1)}, 'hittest', 'on');
                            otherwise
                                continue;
                        end
                        
                        %hLines = findobj(hAxis, 'tag', 'mirrorLocator');
                        hLines = stateS.handle.aI(i).axisFusion.MirrorScopeLocator;
                        %Add new lines to the miscHandles axis field.
                        setAxisInfo(hAxis, 'miscHandles', [oldMiscHandles reshape(hLines, 1, [])]);
                        
                    end
                    
                    
                elseif button_state == get(hObject,'Min')
                    % toggle button is not pressed
                    stateS.optS.mirror = 0;
                    %                         set(ud.handles.differToggle, 'visible', 'on');
                    %                         set(ud.handles.checkerToggle, 'visible', 'on');
                    %                         set(ud.handles.newcheckerToggle, 'visible', 'on');
                    %                         set(ud.handles.mirrorScopeToggle, 'visible', 'on');
                    %                         set(ud.handles.blockMatchToggle, 'visible', 'on');
                    set(ud.handles.differToggle, 'enable', 'on');
                    set(ud.handles.mirror_checkerToggle, 'enable', 'on');
                    set(ud.handles.checkerToggle, 'enable', 'on');
                    set(ud.handles.newcheckerToggle, 'enable', 'on');
                    set(ud.handles.mirrorScopeToggle, 'enable', 'on');
                    set(ud.handles.blockMatchToggle, 'enable', 'off');
                    
                    stateS.showPlaneLocators = 1;
                    
                    for i=1:length(stateS.handle.CERRAxis)
                        hAxis       = stateS.handle.CERRAxis(i);
                        %hOld = findobj(hAxis, 'tag', 'mirrorLocator');
                        hOld = [];
                        if isfield(stateS.handle.aI(i).axisFusion,'MirrorScopeLocator')
                            hOld = stateS.handle.aI(i).axisFusion.MirrorScopeLocator;
                            if ishandle(hOld)
                                delete(hOld);
                            end
                        end
                        oldMiscHandles = getAxisInfo(hAxis, 'miscHandles');
                        setAxisInfo(hAxis, 'miscHandles', setdiff(oldMiscHandles, [hOld]));
                    end
                end
                CERRRefresh;
                %                 end
                
                
            case 'mirrorLocatorClicked'
                set(gcf, 'WindowButtonUpFcn', 'controlFrame(''fusion'', ''mirrorLocatorUnClicked'')');
                set(gcf, 'WindowButtonMotionFcn', 'controlFrame(''fusion'', ''mirrorLocatorMoving'')');
                setappdata(gcf, 'locMirrHandle', gcbo);
                return;
                
            case 'mirrorLocatorMoving'
                hLine = getappdata(gcf, 'locMirrHandle');
                hAxis = get(hLine, 'parent');
                
                %scanSets = getAxisInfo(hAxis,'scanSets');
                
                [view, coord] = getAxisInfo(hAxis, 'view', 'coord');
                
                ud = get(hLine, 'userdata');
                type = ud{1}; view = ud{2};
                cP = get(hAxis, 'currentpoint');
                switch type
                    case 'vert'
                        set(hLine, 'xData', [cP(1,1) cP(1,1)]);
                        currentPos = cP(1,1);
                    case 'horz'
                        set(hLine, 'yData', [cP(1,2) cP(1,2)]);
                        currentPos = cP(1,2);
                end
                
                %[xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(stateS.imageRegistrationBaseDataset));
                switch lower(view)
                    case 'transverse'
                        [slc1, xV, yV] = getCTOnSlice(stateS.imageRegistrationBaseDataset, coord, 3, planC);
                        ind = find(xV>=currentPos);
                    case 'sagittal'
                        [slc1, xV, yV] = getCTOnSlice(stateS.imageRegistrationBaseDataset, coord, 1, planC);
                        if (xV(1)>xV(2))
                            ind = find(xV<=currentPos);
                        else
                            ind = find(xV>=currentPos);
                        end
                    case 'coronal'
                        [slc1, xV, yV] = getCTOnSlice(stateS.imageRegistrationBaseDataset, coord, 2, planC);
                        ind = find(xV>=currentPos);
                end
                ud{3} = ind(1);
                set(hLine, 'userdata', ud);
                
                return;
                
            case 'mirrorLocatorUnClicked'
                set(gcf, 'WindowButtonUpFcn', '');
                set(gcf, 'WindowButtonMotionFcn', '');
                
                CERRRefresh;
                
            case 'mirrorscope'
                udf = stateS.handle.controlFrameUd ;
                hObject = udf.handles.mirrorScopeToggle;
                button_state = get(hObject,'Value');
                
                %scanSetM = stateS.imageRegistrationMovDataset;
                %scanSetF = stateS.imageRegistrationBaseDataset;
                %if isequal(size(planC{indexS.scan}(scanSetF).scanArray), size(planC{indexS.scan}(scanSetM).scanArray))
                
                if button_state == get(hObject,'Max')
                    % toggle button is pressed
                    stateS.optS.mirrorscope = 1;
                    
                    set(udf.handles.mirrScopeText, 'visible', 'on');
                    set(udf.handles.mirrScopeValue, 'visible', 'on');
                    r = floor(str2double(get(udf.handles.mirrScopeValue, 'string')));
                    set(udf.handles.mirrScope, 'visible', 'on');
                    
                    set(udf.handles.blockMatchToggle, 'visible', 'off');
                    
                    set(udf.handles.differToggle, 'enable', 'off');
                    set(udf.handles.mirror_checkerToggle, 'enable', 'off');
                    set(udf.handles.checkerToggle, 'enable', 'off');
                    set(udf.handles.newcheckerToggle, 'enable', 'off');
                    set(udf.handles.mirrorToggle, 'enable', 'off');
                    set(udf.handles.blockMatchToggle, 'enable', 'off');
                    stateS.showPlaneLocators = 0;
                    
                    %[xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(stateS.imageRegistrationBaseDataset));
                    ud = cell(1, 3);
                    ud = {};
                    for i=1:length(stateS.handle.CERRAxis)
                        hAxis       = stateS.handle.CERRAxis(i);
                        [view, coord] = getAxisInfo(hAxis, 'view', 'coord');
                        
                        %scanSets = getAxisInfo(hAxis,'scanSets');
                        
                        xLimit = get(hAxis, 'xLim');
                        yLimit = get(hAxis, 'yLim');
                        
                        oldMiscHandles = getAxisInfo(hAxis, 'miscHandles');
                        
                        switch lower(view)
                            case 'transverse'
                                [slc1, xV, yV] = getCTOnSlice(stateS.imageRegistrationBaseDataset, coord, 3, planC);
                                indX = find(xV>=median(xV));
                                indY = find(yV<=median(yV));
                                
                            case 'sagittal'
                                [slc1, xV, yV] = getCTOnSlice(stateS.imageRegistrationBaseDataset, coord, 1, planC);
                                indX = find(xV<=median(xV));
                                indY = find(yV>=median(yV));
                                
                            case 'coronal'
                                [slc1, xV, yV] = getCTOnSlice(stateS.imageRegistrationBaseDataset, coord, 2, planC);
                                indX = find(xV>=median(xV));
                                indY = find(yV>=median(yV));
                                
                            otherwise
                                continue;
                        end
                        
                        cx = xV(indX(1));
                        cy = yV(indY(1));
                        
                        t = -pi/2:pi/60:3*pi/2;
                        xVals = cx + r*cos(t);
                        yVals = cy + r*sin(t);
                        
                        xRange = [min(xVals(:)) max(xVals(:))];
                        yRange = [max(yVals(:)) min(yVals(:))];
                        
                        hBox = patch([xVals median(xRange)], [yVals max(yRange)], -2*ones(size(xVals,2)+1,1), [.86 .10 .10]);
                        stateS.handle.aI(i).axisFusion.MirrorScopePatch = hBox;
                        
                        ud{1} = [xRange yRange];
                        ud{2} = [xVals median(xRange)];
                        ud{3} = [yVals max(yRange)];
                        
                        set(hBox, 'Parent', hAxis, 'EdgeColor', [.10 .86 .10], ...
                            'Tag', 'MirrorScope', 'FaceColor', [.10 .10 .86], ...
                            'FaceAlpha', 0.1, 'LineWidth', 2, 'PickableParts', 'all',...
                            'ButtonDownFcn','controlFrame(''fusion'', ''mirrorScopeClicked'')', ...
                            'userdata', ud);
                        
                        %hBox = findobj(hAxis, 'tag', 'MirrorScope');
                        %Add new lines to the miscHandles axis field.
                        setAxisInfo(hAxis, 'miscHandles', [oldMiscHandles reshape(hBox, 1, [])]);
                        
                    end
                    
                elseif button_state == get(hObject,'Min')
                    % toggle button is not pressed
                    stateS.optS.mirrorscope = 0;
                    set(udf.handles.mirrScopeText, 'visible', 'off');
                    set(udf.handles.mirrScopeValue, 'visible', 'off');
                    set(udf.handles.mirrScope, 'visible', 'off');
                    
                    set(udf.handles.blockMatchToggle, 'visible', 'on');
                    
                    set(udf.handles.differToggle, 'enable', 'on');
                    set(udf.handles.mirror_checkerToggle, 'enable', 'on');
                    set(udf.handles.checkerToggle, 'enable', 'on');
                    set(udf.handles.newcheckerToggle, 'enable', 'on');
                    set(udf.handles.mirrorToggle, 'enable', 'on');
                    set(udf.handles.blockMatchToggle, 'enable', 'on');
                    stateS.showPlaneLocators = 1;
                    
                    for i=1:length(stateS.handle.CERRAxis)
                        hAxis       = stateS.handle.CERRAxis(i);
                        %hOld = findobj(hAxis, 'tag', 'MirrorScope');
                        if isfield(stateS.handle.aI(i).axisFusion,'MirrorScopePatch')
                            hOld = stateS.handle.aI(i).axisFusion.MirrorScopePatch;
                            if ishandle(hOld)
                                delete(hOld);
                            end
                        end
                        oldMiscHandles = getAxisInfo(hAxis, 'miscHandles');
                        setAxisInfo(hAxis, 'miscHandles', setdiff(oldMiscHandles, hOld));
                    end
                    
                end
                CERRRefresh;
                
                %end
                
            case 'mirrorSlider'
                ud = stateS.handle.controlFrameUd ;
                set(ud.handles.mirrScopeValue, 'string', num2str(floor(get(gcbo, 'value'))));
                controlFrame('fusion', 'mirrorscopefresh');
                %CERRRefresh;
                
            case 'mirrorscopefresh'
                %                 %delete(findobj('tag', 'MirrorScope'));
                %                 aiS = [stateS.handle.aI(:).axisFusion];
                %                 delete([aiS.MirrorScopePatch])
                %                 controlFrame('fusion', 'mirrorscope');
                % ============== NEW
                udf = stateS.handle.controlFrameUd ;
                r = floor(str2double(get(udf.handles.mirrScopeValue, 'string')));
                for i=1:length(stateS.handle.CERRAxis)
                    %hAxis       = stateS.handle.CERRAxis(i);
                    %[view, coord] = getAxisInfo(hAxis, 'view', 'coord');
                    
                    if ~isfield(stateS.handle.aI(i).axisFusion,'MirrorScopePatch')
                        continue;
                    end
                    
                    hScope = stateS.handle.aI(i).axisFusion.MirrorScopePatch;
                    ud = get(hScope,'userdata');
                    cx = mean(ud{2});
                    cy = mean(ud{3});

                    
                    t = -pi/2:pi/60:3*pi/2;
                    xVals = cx + r*cos(t);
                    yVals = cy + r*sin(t);
                    
                    xRange = [min(xVals(:)) max(xVals(:))];
                    yRange = [max(yVals(:)) min(yVals(:))];                    
                                       
                    ud{1} = [xRange yRange];
                    ud{2} = [xVals median(xRange)];
                    ud{3} = [yVals max(yRange)];
                    
                    set(hScope,'xData',[xVals median(xRange)],...
                        'yData',[yVals max(yRange)],...
                        'zData',-2*ones(size(xVals,2)+1,1),...
                        'userdata',ud)
                    
                end
                CERRRefresh;
                
            case 'mirrorScopeClicked'
                set(gcf, 'WindowButtonUpFcn', 'controlFrame(''fusion'', ''mirrorScopeUnClicked'')');
                set(gcf, 'WindowButtonMotionFcn', 'controlFrame(''fusion'', ''mirrorScopeMoving'')');
                %setappdata(gcf, 'scopeMirrHandle', gcbo);
                
                cP = get(gca, 'currentpoint');
                setappdata(gcf, 'clickPoint', cP);
                
                set(gcf,'Pointer','hand')
                
                stateS.optS.mirrorscope = 0;
                CERRRefresh;
                return;
                
            case 'mirrorScopeMoving'
                %hScope = getappdata(gcf, 'scopeMirrHandle');
                hScope = stateS.handle.aI(stateS.currentAxis).axisFusion.MirrorScopePatch;
                
                %                 %close the moving image when move the scope field;
                %                 hAxis = get(hScope, 'parent');
                %                 axisInfo = get(hAxis, 'userdata');
                %                 surfaces = [axisInfo.scanObj.handles];
                %                 set(surfaces(end), 'facealpha', 0);
                
                ud = get(hScope, 'userdata');
                xVals = ud{2};
                yVals = ud{3};
                
                clickPoint = getappdata(gcf, 'clickPoint');
                cP = get(gca, 'currentpoint');
                dx = cP(1,1) - clickPoint(1,1);
                dy = cP(1,2) - clickPoint(1,2);
                
                set(hScope, 'xData', xVals+dx, 'yData', yVals+dy);
                                
                return;
                
            case 'mirrorScopeUnClicked'
                set(gcf, 'WindowButtonUpFcn', '');
                set(gcf, 'WindowButtonMotionFcn', '');
                
                %hScope = getappdata(gcf, 'scopeMirrHandle');
                hScope = stateS.handle.aI(stateS.currentAxis).axisFusion.MirrorScopePatch;
                ud = get(hScope, 'userdata');
                
                ud{2} = get(hScope, 'xData');
                ud{3} = get(hScope, 'yData');
                ud{1} = [min(ud{2}) max(ud{2}) max(ud{3}) min(ud{3})];
                
                set(hScope, 'userdata', ud);
                
                stateS.optS.mirrorscope = 1;
                CERRRefresh;
                
            case 'blockmatch'
                ud = stateS.handle.controlFrameUd ;
                hObject = ud.handles.blockMatchToggle;
                button_state = get(hObject,'Value');
                
                %                 scanSetM = stateS.imageRegistrationMovDataset;
                %                 scanSetF = stateS.imageRegistrationBaseDataset;
                %                 if isequal(size(planC{indexS.scan}(scanSetF).scanArray), size(planC{indexS.scan}(scanSetM).scanArray))
                
                if button_state == get(hObject,'Max')
                    % toggle button is pressed
                    stateS.optS.blockmatch = 1;
                    %                         set(ud.handles.differToggle, 'visible', 'off');
                    %                         set(ud.handles.checkerToggle, 'visible', 'off');
                    %                         set(ud.handles.newcheckerToggle, 'visible', 'off');
                    %                         set(ud.handles.mirrorScopeToggle, 'visible', 'off');
                    %                         set(ud.handles.mirrorToggle, 'visible', 'off');
                    
                    set(ud.handles.differToggle, 'enable', 'off');
                    set(ud.handles.mirror_checkerToggle, 'enable', 'off');
                    set(ud.handles.checkerToggle, 'enable', 'off');
                    set(ud.handles.newcheckerToggle, 'enable', 'off');
                    set(ud.handles.mirrorScopeToggle, 'enable', 'off');
                    set(ud.handles.mirrorToggle, 'enable', 'off');
                    
                    stateS.showPlaneLocators = 0;
                    
                elseif button_state == get(hObject,'Min')
                    % toggle button is not pressed
                    stateS.optS.blockmatch = 0;
                    %                         set(ud.handles.differToggle, 'visible', 'on');
                    %                         set(ud.handles.checkerToggle, 'visible', 'on');
                    %                         set(ud.handles.newcheckerToggle, 'visible', 'on');
                    %                         set(ud.handles.mirrorScopeToggle, 'visible', 'on');
                    %                         set(ud.handles.mirrorToggle, 'visible', 'on');
                    set(ud.handles.differToggle, 'enable', 'on');
                    set(ud.handles.mirror_checkerToggle, 'enable', 'on');
                    set(ud.handles.checkerToggle, 'enable', 'on');
                    set(ud.handles.newcheckerToggle, 'enable', 'on');
                    set(ud.handles.mirrorScopeToggle, 'enable', 'on');
                    set(ud.handles.mirrorToggle, 'enable', 'on');
                    stateS.showPlaneLocators = 1;
                end
                CERRRefresh;
                %                 end
                
            case 'exit'
                
                if stateS.toggle_rotation
                    msgbox('Please get out of rotation mode before exiting image fusion','Rotation Active','modal');
                    return;
                end
                
                %recover the transM
                setNum = stateS.imageRegistrationMovDataset;
                movingSet = indexS.(stateS.imageRegistrationMovDatasetType);
                if isfield(planC{movingSet}(setNum), 'transMCur')
                    planC{movingSet}(setNum).transM = planC{movingSet}(setNum).transMCur;
                end
                
                % Set Color Bar Visible
                delete(findobj('tag', 'colorbarShild'));
                delete(findobj('tag', 'toggleBasMov'));
                delete(findobj('tag', 'toggleLockMoving'));
                
                stateS.doseToggle = 1;
                stateS.doseSetChanged = 1;
                stateS.CTDisplayChanged = 1;
                delete(findobj('tag','sliderFusion'));
                set(findobj('tag','sliderInit'),'visible','on');
                sliceCallBack('fusion_mode_off');
                delete(findobj('tag', 'controlFrameItem'));
                
                %wy
                stateS.optS.mirrorscope = 0;
                stateS.optS.blockmatch = 0;
                stateS.optS.mirror = 0;
                stateS.optS.newchecker = 0;
                stateS.optS.checkerboard = 0;
                stateS.optS.difference = 0;
                
                
                for i=1:length(stateS.handle.CERRAxis)
                    hAxis       = stateS.handle.CERRAxis(i);
                    %hOld = findobj(hAxis, 'tag', 'MirrorScope');
                    if isfield(stateS.handle.aI(i),'axisFusion') &&...
                            isfield(stateS.handle.aI(i).axisFusion,'MirrorScopePatch')
                        hOld = stateS.handle.aI(i).axisFusion.MirrorScopePatch;
                        if ishandle(hOld)
                            delete(hOld);
                        end
                    end
                    if isfield(stateS.handle.aI(i),'axisFusion') &&...
                            isfield(stateS.handle.aI(i).axisFusion,'MirrorScopeLocator')
                        hOld = stateS.handle.aI(i).axisFusion.MirrorScopeLocator;
                        %hOld = findobj(hAxis, 'tag', 'mirrorLocator');
                        if ishandle(hOld)
                            delete(hOld);
                        end
                        oldMiscHandles = getAxisInfo(hAxis, 'miscHandles');
                        setAxisInfo(hAxis, 'miscHandles', setdiff(oldMiscHandles, [hOld]));
                    end
                end
                
                delete(findobj('tag','rotSpeedBar'));
                
                set(hFig, 'renderer', 'zbuffer');
                %wy
                
                %recover the control frame left tool bar
                set(stateS.handle.CTSettingsFrame, 'visible', 'on');
                ctWindowObjs = findobj('Tag','CTWindow');
                set(ctWindowObjs, 'visible', 'on');
                set(stateS.handle.CTPreset, 'visible', 'on');
                set(stateS.handle.BaseCMap, 'visible', 'on');
                set(stateS.handle.CTWidth, 'visible', 'on');
                set(stateS.handle.CTLevel, 'visible', 'on');
                set(stateS.handle.CTLevelWidthInteractive, 'visible', 'on');
                set(stateS.handle.ScanTxtWindow,'visible','on')
                
                %set(stateS.handle.controlFrame, 'pos', tempControlPos);
                leftMarginWidth = 195;
                set(stateS.handle.controlFrame, 'pos', [0 0 leftMarginWidth 400]);
                
                ud = stateS.handle.controlFrameUd ;
                
                %move back the zoom/slice buttons
                %set(stateS.handle.loopTrans, 'pos', ud.handle.loopTransPos);
                %set(stateS.handle.unloopTrans, 'pos', ud.handle.unloopTransPos);
                set(stateS.handle.zoom, 'pos', ud.handle.zoomPos);
                set(stateS.handle.resetZoom, 'pos', ud.handle.resetZoomPos);
                %set(stateS.handle.rulerTrans, 'pos', ud.handle.rulerTransPos);
                set(stateS.handle.buttonUp, 'pos', ud.handle.buttonUpPos);
                set(stateS.handle.buttonDwn, 'pos', ud.handle.buttonDwnPos);
                set(stateS.handle.scanColorbar, 'pos', ud.handle.scanColorbarPos);
                
                %set(stateS.handle.capture, 'pos', ud.handle.capturePos);
                
                set(stateS.handle.doseColorbar.trans,'position',ud.clBarPos)
                set(gcf,'Pointer','arrow');
                CERRStatusString('')
                
        end
        
        
        
        % Callback to Rotate view-planes
    case 'rotate_axis'
        switch upper(varargin{1})
            case 'INIT'
                
                %open-up new GUI figure
                %figName = 'Rotate & Contour';
                %position = [30 50 300 400];
                %hFig = figure('tag','rotate_viewPlane','name',figName,'numbertitle','off','position',position,'units','normalized');
                %set(hFig,'menubar','none');
                %set(gca,'nextPlot','add','visible','off')
                
                controlFrame('default');
                %leftFrame = findobj(hFig,'Tag', 'leftMargin');
                %set([leftFrame hFrame],'visible','off')
                
                %Check for three views. If not, display message and exit
                % TO DO ----------
                
                %Clear old controlFrame.
                delete(findobj('tag', 'controlFrameItem'));
                
                %Title
                ud.handles.title = uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, ...
                    'position', absPos([.05 .93 .9 .05], posFrame), 'string', 'Rotate View Planes', 'tag', 'controlFrameItem',...
                    'horizontalAlignment', 'center', 'FontWeight', 'Bold');
                
                %create UI controls
                
                %rotate toggle button
                %funStateS.handle.rotate = uicontrol(hFig,'units', units, 'Position',absPos([.05 .87 0.8 .05], posFrame), 'Style', 'toggle', 'String', 'Rotate View', 'visible', 'on', 'callBack','controlFrame(''rotate_axis'',''rotateViewPlane'')','tag', 'controlFrameItem');
                %reset push button
                ud.handles.reset = uicontrol(hFig,'units', units, 'Position',absPos([.05 .8 0.8 .05], posFrame), 'Style', 'push', 'String', 'Reset View', 'visible', 'on', 'callBack','controlFrame(''rotate_axis'',''resetViewPlane'')','tag', 'controlFrameItem');
                %exit push button
                ud.handles.quit = uicontrol(hFig,'units', units, 'Position',absPos([.05 .73 0.8 .05], posFrame), 'Style', 'push', 'String', 'Quit', 'visible', 'on', 'callBack','controlFrame(''rotate_axis'',''quit'')','tag', 'controlFrameItem');
                %axis to display plane rotations
                %ud.handles.display_axis = axes('parent',hFig,'units', units, 'Position', absPos([.02 .4 1 .3], posFrame), 'xTickLabel', [], 'yTickLabel', [], 'xTick', [], 'yTick', [], 'zTick', [], 'visible', 'off','tag', 'controlFrameItem','nextPlot','add');
                %ud.handles.display_axis1 = uicontrol(hFig,'style','edit','units', units, 'Position', absPos([.05 .4 0.8 .25], posFrame),'visible', 'on','tag', 'controlFrameItem');
                
                %Get the center of rotation
                stateS.rotateView.xC = [];
                stateS.rotateView.yC = [];
                stateS.rotateView.zC = [];
                for i=1:length(stateS.handle.CERRAxis)
                    switch upper(getAxisInfo(stateS.handle.CERRAxis(i),'view'))
                        case 'TRANSVERSE'
                            stateS.rotateView.zC = getAxisInfo(stateS.handle.CERRAxis(i),'coord');
                        case 'SAGITTAL'
                            stateS.rotateView.xC = getAxisInfo(stateS.handle.CERRAxis(i),'coord');
                        case 'CORONAL'
                            stateS.rotateView.yC = getAxisInfo(stateS.handle.CERRAxis(i),'coord');
                    end
                end
                stateS.rotateView.TH = 0;
                stateS.rotateView.ALP = 0;
                stateS.rotateView.BET = 0;
                stateS.rotateMode = 1;
                
                stateS.CTDisplayChanged = 1;
                CERRRefresh
                hDisp = figure('position',[50 50 200 200],'name','Rotate Coordinate syatem','numbertitle','off','menubar','none','renderer','openGL');
                ud.handles.display_fig = hDisp;
                ud.handles.display_axis = axes('parent',hDisp,'units', 'normalized', 'Position', [0.05 0.05 0.9 0.9], 'xTickLabel', [], 'yTickLabel', [], 'xTick', [], 'yTick', [], 'zTick', [], 'visible', 'off','tag', 'controlFrameItem','nextPlot','add');
                stateS.handle.controlFrameUd = ud;
                controlFrame('rotate_axis','UPDATE_SPHERE')
                
            case 'ROTATEVIEWPLANE'
                value = get(gcbo,'value');
                if ~value
                    %set(stateS.handle.CERRSliceViewer,'WindowButtonDownFcn','','WindowButtonMotionFcn','','WindowButtonUpFcn','')
                    stateS.rotateMode = 0;
                    return;
                else
                    stateS.rotateMode = 1;
                end
                %set(stateS.handle.CERRSliceViewer,'WindowButtonDownFcn','rotateView(''down'')')
                
                
            case 'RESETVIEWPLANE'
                
                stateS.rotateView.TH = 0;
                stateS.rotateView.ALP = 0;
                stateS.rotateView.BET = 0;
                stateS.rotateView.xC = [];
                stateS.rotateView.yC = [];
                stateS.rotateView.zC = [];
                for i=1:length(stateS.handle.CERRAxis)
                    rotateCerrAxis(stateS.handle.CERRAxis(i))
                end
                stateS.CTDisplayChanged = 1;
                stateS.structsChanged = 1;
                stateS.doseDisplayChanged = 1;
                controlFrame('rotate_axis','UPDATE_SPHERE')
                CERRRefresh
                
            case 'DRAWCONTOUR' %% NOT FULLY IMPLEMENTED
                value = get(gcbo,'value');
                hAxis = stateS.handle.CERRAxis(stateS.currentAxis);
                if ~value
                    drawContour('quit', hAxis);
                    set(stateS.handle.CERRAxis,'ButtonDownFcn','sliceCallBack(''axisClicked'')')
                    stateS.contourState = 0;
                end
                set(funStateS.handle.rotate,'value',0)
                set(stateS.handle.CERRSliceViewer,'WindowButtonDownFcn','','WindowButtonMotionFcn','')
                stateS.contourState = 1;
                drawContour('axis', hAxis)
                stateS.contouringMetaDataS.mode = 'DRAW';
                stateS.contouringMetaDataS.ccScanSet = 1;
            case 'EXPORTCONTOUR' %% NOT FULLY IMPLEMENTED
                hAxis = stateS.handle.CERRAxis(stateS.currentAxis);
                C = drawContour('getContours', hAxis);
                [view_ax,coord] = getAxisInfo(hAxis,'view','coord');
                switch upper(view_ax)
                    case 'TRANSVERSE'
                        for i = 1:length(C)
                            temp = stateS.transM*[C{i} coord*ones(size(C{i},1),1) ones(size(C{i},1),1)]';
                            Contours{i} = temp(1:3,:);
                        end
                    case 'SAGITTAL'
                        for i = 1:length(C)
                            temp = stateS.transM*[coord*ones(size(C{i},1),1) C{i} ones(size(C{i},1),1)]';
                            Contours{i} = temp(1:3,:);
                        end
                    case 'CORONAL'
                        for i = 1:length(C)
                            temp = stateS.transM*[C{i}(:,1) coord*ones(size(C{i},1),1) C{i}(:,2) ones(size(C{i},1),1)]';
                            Contours{i} = temp(1:3,:);
                        end
                end
                
                [fname,pname] = uiputfile('*.mat','Save contours as');
                if isequal(fname,0) || isequal(pname,0)
                    return;
                end
                saveFile = fullfile(pname,fname);
                save(saveFile,'Contours')
                
            case 'UPDATE_SPHERE'
                ud = stateS.handle.controlFrameUd ;
                hAxis1 = ud.handles.display_axis;
                hDisp = ud.handles.display_fig;
                if ~ishandle(hDisp) || ~ishandle(hAxis1)
                    try, close(hDisp), end
                    hDisp = figure('position',[50 50 200 200],'name','Rotate Coordinate syatem','numbertitle','off','menubar','none','renderer','openGL');
                    ud.handles.display_fig = hDisp;
                    ud.handles.display_axis = axes('parent',hDisp,'units', 'normalized', 'Position', [0.05 0.05 0.9 0.9], 'xTickLabel', [], 'yTickLabel', [], 'xTick', [], 'yTick', [], 'zTick', [], 'visible', 'off','tag', 'controlFrameItem','nextPlot','add');
                    hAxis1 = ud.handles.display_axis;
                end
                cla(hAxis1)
                transM = stateS.transM;
                transM(1:3,4) = [0;0;0];
                %Transverse Plane
                th = pi/180*linspace(0,360,50);
                y = sin(th);
                x = cos(th);
                z = 0*y;
                [xTrans,yTrans,zTrans] = applyTransM(transM,x,y,z);
                [xSag,ySag,zSag] = applyTransM(transM,z,x,y);
                [xCor,yCor,zCor] = applyTransM(transM,x,z,y);
                
                %Plot sphere
                [X,Y,Z] = sphere(hAxis1,20);
                surf(X,Y,Z,Z.^0,'FaceAlpha',0.5,'EdgeAlpha',0.1,'parent',hAxis1);
                fill3(xTrans,yTrans,zTrans,'r','FaceAlpha',0.3,'parent',hAxis1)
                fill3(xCor,yCor,zCor,'r','FaceAlpha',0.3,'parent',hAxis1)
                %hold on, fill3(xSag,ySag,zSag,'r','FaceAlpha',0.3)
                
                origin = [0 0 0];
                [xAxis(1),xAxis(2),xAxis(3)]  = applyTransM(transM,0.6, 0, 0);
                [yAxis(1),yAxis(2),yAxis(3)]  = applyTransM(transM,0, 0.6, 0);
                [zAxis(1),zAxis(2),zAxis(3)]  = applyTransM(transM,0, 0, 0.6);
                vectarrow(origin,xAxis,hAxis1)
                text(xAxis(1)+0.2,xAxis(2),xAxis(3),'\bfx','parent',hAxis1,'color','b')
                vectarrow(origin,yAxis,hAxis1)
                text(yAxis(1),yAxis(2)+0.2,yAxis(3),'\bfy','parent',hAxis1,'color','b')
                vectarrow(origin,zAxis,hAxis1)
                text(zAxis(1),zAxis(2),zAxis(3)+0.2,'\bfz','parent',hAxis1,'color','b')
                view(hAxis1,3)
                set(hAxis1,'XMinorGrid','on','ZMinorGrid','on')
                set(hAxis1,'visible','on','xTickLabel', [], 'yTickLabel', [], 'zTickLabel', [], 'xTick', [], 'xTick', [],'yTick', [], 'zTick', [])
                xlabel(hAxis1,'x')
                ylabel(hAxis1,'y')
                zlabel(hAxis1,'z')
                axis(hAxis1,'equal')
                figure(ud.handles.display_fig)
                
                
            case 'QUIT'
                ud = stateS.handle.controlFrameUd ;
                buttonName = questdlg('Are you sure you want to quit?','Confirm Quit','Yes','No','No');
                if strcmpi(buttonName,'No')
                    return;
                end
                controlFrame('rotate_axis','RESETVIEWPLANE')
                %hAxis = stateS.handle.CERRAxis(stateS.currentAxis);
                %drawContour('quit', hAxis);
                %set(stateS.handle.CERRSliceViewer,'WindowButtonDownFcn','')
                stateS.CTDisplayChanged = 1;
                stateS.structsChanged = 1;
                stateS.doseDisplayChanged = 1;
                stateS.rotateMode = 0;
                delete(findobj('tag', 'controlFrameItem'));
                %leftFrame = findobj(hFig,'Tag', 'leftMargin');
                %set([leftFrame hFrame],'visible','on')
                close(ud.handles.display_fig)
                CERRRefresh                                
                
        end
        
    case 'ANNOTATION'
        ud = stateS.handle.controlFrameUd ;
        switch varargin{1}
            case 'init'
                
                if isempty(planC{indexS.GSPS})
                    herror=errordlg({'No annotations exist for this scan'},'Annotations NOT available','modal');
                    return;
                end
                %udAxis = get(stateS.handle.CERRAxis(1),'userdata');
                axView = getAxisInfo(stateS.handle.CERRAxis(1),'view');
                if ~strcmpi(axView,'transverse')
                    herror=errordlg({'Annotations can be shown only on Transverse Views','Please Select 1st view to be transverse for contouring'},'Not a transverse view','modal');
                    return
                end
                                
                % Build a list of scans and slices that are annotated                
                numSignificantSlcs = length(planC{indexS.GSPS});
                matchingSliceIndV = [];
                matchingGSPSIndV = [];
                sliceNumsC = cell(1,numSignificantSlcs);
                scanNumsC = sliceNumsC;
                
                for scanNum = 1:length(planC{indexS.scan})
                    for slcNum=1:length(planC{indexS.scan}(scanNum).scanInfo)
                        % SOPInstanceUIDc{slcNum} = planC{indexS.scan}(scanNum).scanInfo(slcNum).DICOMHeaders.SOPInstanceUID;
                        SOPInstanceUIDc{slcNum} = planC{indexS.scan}(scanNum).scanInfo(slcNum).sopInstanceUID;
                    end
                    for i=1:numSignificantSlcs
                        sliceNum = strmatch(planC{indexS.GSPS}(i).SOPInstanceUID, SOPInstanceUIDc, 'exact');
                        if isempty(sliceNumsC{i})
                            sliceNumsC{i} = sliceNum;
                        end
                        if ~isempty(sliceNum)
                            scanNumsC{i} = scanNum;
                        end
                        if ~isempty(sliceNum)
                            matchingSliceIndV = [matchingSliceIndV sliceNum];
                            matchingGSPSIndV = [matchingGSPSIndV i];
                        end
                    end
                end
                 
                ud.handles.annotText = uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, 'position', absPos([.05 .9 .9 .05], posFrame), 'string', 'Annotations', 'tag', 'controlFrameItem', 'horizontalAlignment', 'center','fontWeight','bold','fontsize',14);
                ud.handles.sliceText = uicontrol(hFig, 'style', 'text', 'enable', 'inactive' , 'units', units, 'position', absPos([.3 .70 .4 .15], posFrame), 'string', ['Image 1/',num2str(length(matchingSliceIndV))], 'tag', 'controlFrameItem', 'horizontalAlignment', 'center','fontsize',14);
                ud.handles.prevSlcPush = uicontrol(hFig, 'style', 'push', 'units', units, 'position', absPos([.05 .75 .2 .05], posFrame), 'string', '<<', 'tag', 'controlFrameItem', 'visible', 'on', 'callBack','controlFrame(''ANNOTATION'',''prevSlc'')', 'horizontalAlignment', 'center','fontsize',14);
                ud.handles.nextSlcPush = uicontrol(hFig, 'style', 'push', 'units', units, 'position', absPos([.8 .75 .15 .05], posFrame), 'string', '>>', 'tag', 'controlFrameItem', 'visible', 'on', 'callBack','controlFrame(''ANNOTATION'',''nextSlc'')', 'horizontalAlignment', 'center','fontsize',14);
                ud.handles.AnnotSelectTxt = uicontrol(hFig, 'style', 'text', 'enable', 'inactive', 'units', units, 'position', absPos([.05 .65 .35 .05], posFrame), 'string', 'Item #', 'tag', 'controlFrameItem', 'visible', 'on', 'horizontalAlignment', 'center','fontsize',14);
                ud.handles.AnnotSelect = uicontrol(hFig, 'style', 'popup', 'units', units, 'position', absPos([.4 .65 .55 .05], posFrame), 'string', '','value',1, 'tag', 'controlFrameItem', 'visible', 'on', 'callBack','controlFrame(''ANNOTATION'',''show'')', 'horizontalAlignment', 'center','fontsize',14);
                ud.handles.AnnotStat1 = uicontrol(hFig, 'style', 'text', 'enable', 'inactive', 'units', units, 'position', absPos([.06 .50 .9 .08], posFrame), 'string', '', 'tag', 'controlFrameItem', 'visible', 'on', 'horizontalAlignment', 'left','fontsize',14);
                ud.handles.quitPush = uicontrol(hFig, 'style', 'push', 'units', units, 'position', absPos([.35 .1 .3 .05], posFrame), 'string', 'Quit', 'tag', 'controlFrameItem', 'visible', 'on', 'callBack','controlFrame(''ANNOTATION'',''quit'')', 'horizontalAlignment', 'center','fontsize',14);
                
                ud.annotation.currentMatchingSlc = 1;
                ud.annotation.slicesNumsC = sliceNumsC;
                ud.annotation.matchingSliceIndV = matchingSliceIndV;
                ud.annotation.matchingGSPSIndV = matchingGSPSIndV;
                ud.annotation.scanNumsC = scanNumsC;
                
                ud.handles.hV = [];
                stateS.handle.controlFrameUd = ud;
                stateS.annotToggle = 1;
                controlFrame('ANNOTATION','updateAnnotationList')
                controlFrame('ANNOTATION','show',1)
                
            case 'prevSlc'
                if ud.annotation.currentMatchingSlc == 1
                    return;
                end
                ud.annotation.currentMatchingSlc = ud.annotation.currentMatchingSlc - 1;
                stateS.handle.controlFrameUd=ud;
                controlFrame('ANNOTATION','updateAnnotationList')
                controlFrame('ANNOTATION','show')
                
            case 'nextSlc'
                if ud.annotation.currentMatchingSlc == length(ud.annotation.matchingSliceIndV)
                    return;
                end
                ud.annotation.currentMatchingSlc = ud.annotation.currentMatchingSlc + 1;
                %set(hFrame, 'userdata', ud);
                stateS.handle.controlFrameUd = ud;
                controlFrame('ANNOTATION','updateAnnotationList')
                controlFrame('ANNOTATION','show')
                
            case 'updateAnnotationList'
                gspsNum = ud.annotation.matchingGSPSIndV(ud.annotation.currentMatchingSlc);
                graphicAnnotationTypeC{1} = 'None';
                for iGraphic = 1:length(planC{indexS.GSPS}(gspsNum).graphicAnnotationS)
                    graphicAnnotationTypeC{iGraphic} = planC{indexS.GSPS}(gspsNum).graphicAnnotationS(iGraphic).graphicAnnotationType;                    
                end
                set(ud.handles.AnnotSelect,'string',graphicAnnotationTypeC,'value',1)
                
            case 'show'
                
                scanNum = getAxisInfo(stateS.handle.CERRAxis(1),'scanSets');                
                Dims = size(planC{indexS.scan}(scanNum).scanArray);
                if numel(Dims) > 2
                    Dims(3:end) = [];
                end
                gridUnits = [planC{indexS.scan}(scanNum).scanInfo(1).grid1Units planC{indexS.scan}(scanNum).scanInfo(1).grid2Units];
                offset = [planC{indexS.scan}(scanNum).scanInfo(1).yOffset planC{indexS.scan}(scanNum).scanInfo(1).xOffset];
                
                %gspsNum = varargin{2};
                gspsNum = ud.annotation.matchingGSPSIndV(ud.annotation.currentMatchingSlc);
                sliceNum = ud.annotation.slicesNumsC{gspsNum};
                scanNum = ud.annotation.scanNumsC{gspsNum};
                axes(stateS.handle.CERRAxis(1));
                % Delete old plots
                delete(ud.handles.hV)
                % Toggle scan to match anotation
                setAxisInfo(stateS.handle.CERRAxis(1), 'scanSelectMode', 'manual', 'scanSets', scanNum);
                updateAxisRange(stateS.handle.CERRAxis(1),1,'scan');
                %sliceCallBack('refresh');      
                stateS.annotToggle = -1;
                % Toggle slice to match anotation
                goto('SLICE',sliceNum)
                stateS.annotToggle = 1;
                set(ud.handles.sliceText, 'String', ['Image ',num2str(ud.annotation.currentMatchingSlc),'/',num2str(length(ud.annotation.matchingSliceIndV))])
                % Get the patient position
                imgOriV = planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders.ImageOrientationPatient;
                xOffset = planC{indexS.scan}(scanNum).scanInfo(1).xOffset;
                yOffset = planC{indexS.scan}(scanNum).scanInfo(1).yOffset;
                
                % Vector of handles for annotations
                hV = [];                
                for iGraphic = 1:length(planC{indexS.GSPS}(gspsNum).graphicAnnotationS)
                    graphicAnnotationType = planC{indexS.GSPS}(gspsNum).graphicAnnotationS(iGraphic).graphicAnnotationType;
                    graphicAnnotationNumPts = planC{indexS.GSPS}(gspsNum).graphicAnnotationS(iGraphic).graphicAnnotationNumPts;
                    graphicAnnotationData = planC{indexS.GSPS}(gspsNum).graphicAnnotationS(iGraphic).graphicAnnotationData;
                    rowV = graphicAnnotationData(1:2:end)+1; % 0-index to 1-inxed
                    colV = graphicAnnotationData(2:2:end)+1;
                    [xV, yV] = mtoaapm(colV, rowV, Dims, gridUnits, offset);
                    %yShiftedV = double(-double(colV)+Dims(1));
                    %xShiftedV = double(rowV);
                    %yOffset = Dims(1)/2;
                    %xOffset = Dims(2)/2;                    
                    %xV = xShiftedV-xOffset;
                    %yV = yShiftedV-yOffset;                    
                    %xV = xV*gridUnits(2)+offset(2);
                    %yV = yV*gridUnits(1)+offset(1);
                    
                    %xV = 2*xOffset - xV;
                    
                    if max(abs((imgOriV(:) - [1 0 0 0 1 0]'))) < 1e-3
                        %HFS
                        % no flip needed
                    elseif max(abs((imgOriV(:) - [-1 0 0 0 1 0]'))) < 1e-3
                        %FFS
                        % no flip needed
                        % xV = 2*xOffset - xV;
                    elseif max(abs((imgOriV(:) - [-1 0 0 0 -1 0]'))) < 1e-3
                        %HFP
                        xV = 2*xOffset - xV;
                        yV = 2*yOffset - yV;
                    elseif max(abs((imgOri(:) - [1 0 0 0 -1 0]'))) < 1e-3    
                        %FFP    
                        yV = 2*yOffset - yV;
                    else
                        %Oblique
                        %skip
                    end
                  
                    if strcmpi(graphicAnnotationType,'POLYLINE')
                        hV = [hV, plot(xV,yV,'r','parent',stateS.handle.CERRAxis(1))];
                    elseif strcmpi(graphicAnnotationType,'ELLIPSE')
                        hV = [hV, plot(xV(1:2),yV(1:2),'r','linewidth',2,'parent',stateS.handle.CERRAxis(1))];
                        hV = [hV, plot(xV(3:4),yV(3:4),'r','linewidth',2,'parent',stateS.handle.CERRAxis(1))];                      
                    end
                    
                end
                
                % Highlight the selected Item
                if length(planC{indexS.GSPS}(gspsNum).graphicAnnotationS) > 0
                    
                    iGraphic = get(ud.handles.AnnotSelect,'value');
                    graphicAnnotationType = planC{indexS.GSPS}(gspsNum).graphicAnnotationS(iGraphic).graphicAnnotationType;
                    graphicAnnotationData = planC{indexS.GSPS}(gspsNum).graphicAnnotationS(iGraphic).graphicAnnotationData;
                    graphicAnnotationNumPts = planC{indexS.GSPS}(gspsNum).graphicAnnotationS(iGraphic).graphicAnnotationNumPts;
                    rowV = graphicAnnotationData(1:2:end) + 1; % 0-index  to 1-index
                    colV = graphicAnnotationData(2:2:end) + 1;
                    [xV, yV] = mtoaapm(colV, rowV, Dims, gridUnits, offset);
                    
                     if max(abs((imgOriV(:) - [1 0 0 0 1 0]'))) < 1e-3
                        %HFS
                        % no flip needed
                    elseif max(abs((imgOriV(:) - [-1 0 0 0 1 0]'))) < 1e-3
                        %FFS
                        % no flip needed
                        % xV = 2*xOffset - xV;
                    elseif max(abs((imgOriV(:) - [-1 0 0 0 -1 0]'))) < 1e-3
                        %HFP
                        xV = 2*xOffset - xV;
                        yV = 2*yOffset - yV;
                    elseif max(abs((imgOri(:) - [1 0 0 0 -1 0]'))) < 1e-3    
                        %FFP    
                        yV = 2*yOffset - yV;
                    else
                        %Oblique
                        %skip
                    end
                    
                    if strcmpi(graphicAnnotationType,'POLYLINE') && graphicAnnotationNumPts == 2
                        lineLen = sqrt((xV(1)-xV(2))^2 + (yV(1)-yV(2))^2);
                        set(ud.handles.AnnotStat1,'string',['Length = ',num2str(lineLen),' cm'])
                        hV = [hV, plot(xV,yV,'r','linewidth',2,'parent',stateS.handle.CERRAxis(1))];
                        
                    elseif strcmpi(graphicAnnotationType,'ELLIPSE')
                        lineLenAx1 = sqrt((xV(1)-xV(2))^2 + (yV(1)-yV(2))^2);
                        lineLenAx2 = sqrt((xV(3)-xV(4))^2 + (yV(3)-yV(4))^2);
                        EllipseArea = pi*lineLenAx1*lineLenAx2;
                        set(ud.handles.AnnotStat1,'string',['Area = ',num2str(EllipseArea), ' sq. cm'])
                        hV = [hV, plot(xV(1:2),yV(1:2),'r','linewidth',2,'parent',stateS.handle.CERRAxis(1))];
                        hV = [hV, plot(xV(3:4),yV(3:4),'r','linewidth',2,'parent',stateS.handle.CERRAxis(1))];
                    end
                    
                end
                
                % Display Text
                for iText = 1:length(planC{indexS.GSPS}(gspsNum).textAnnotationS)
                    showBoundingBoxFlag = false;
                    if isfield(planC{indexS.GSPS}(gspsNum).textAnnotationS(iText),'boundingBoxTopLeftHandCornerPt') ...
                            && ~isempty(planC{indexS.GSPS}(gspsNum).textAnnotationS(iText).boundingBoxTopLeftHandCornerPt)
                        showBoundingBoxFlag = true;
                    end
                    if showBoundingBoxFlag
                        leftTop = planC{indexS.GSPS}(gspsNum).textAnnotationS(iText).boundingBoxTopLeftHandCornerPt;
                        col = leftTop(1) + 1;
                        row = leftTop(2) + 1;
                        [xTopLeft, yTopLeft] = mtoaapm(row, col, Dims, gridUnits, offset);
                        rightBottom = planC{indexS.GSPS}(gspsNum).textAnnotationS(iText).boundingBoxBottomRightHandCornerPt;
                        col = rightBottom(1) + 1;
                        row = rightBottom(2) + 1;
                        [xRightBottom, yRightBottom] = mtoaapm(row, col, Dims, gridUnits, offset);
                    end
                    anchorPoint = planC{indexS.GSPS}(gspsNum).textAnnotationS(iText).anchorPoint;
                    col = anchorPoint(1) + 1;
                    row = anchorPoint(2) + 1;
                    [xAnchor, yAnchor] = mtoaapm(row, col, Dims, gridUnits, offset);
                    if ~isempty(planC{indexS.GSPS}(gspsNum).textAnnotationS(iText).unformattedTextValue)
                        if showBoundingBoxFlag
                            % Plot Box
                            hV = [hV, plot([xTopLeft xRightBottom xRightBottom xTopLeft xTopLeft],...
                                [yTopLeft yTopLeft yRightBottom yRightBottom yTopLeft],...
                                'm','linewidth',2,'parent',stateS.handle.CERRAxis(1))];
                            % Plot Anchor Point
                            hV = [hV, plot(xAnchor, yAnchor, 'mo', 'markerSize', 4,'parent',stateS.handle.CERRAxis(1))];
                            % Find distance between anchor point and the bounding box points
                            xV = [xTopLeft xRightBottom xRightBottom xTopLeft];
                            yV = [yTopLeft yTopLeft yRightBottom yRightBottom];
                            distV = (xV-xAnchor).^2 + (yV-yAnchor).^2;
                            [jnk,minInd] = min(distV);
                            hV = [hV, plot([xAnchor xV(minInd)], [yAnchor yV(minInd)], 'm', 'linewidth',2)];
                        end
                        posV = [xAnchor, yAnchor];
                        % posV = [min(xV),mean(yV)]; % when anchor point is not defined
                        hV = [hV, text('parent',stateS.handle.CERRAxis(1),'position',posV,...
                            'string',planC{indexS.GSPS}(gspsNum).textAnnotationS(iText).unformattedTextValue,...
                            'fontSize',8, 'units', 'data', 'color','y')];
                    end
                end
                
                ud.handles.hV = hV;
                stateS.handle.controlFrameUd = ud;
            case 'quit'

                delete(ud.handles.hV)
                controlFrame('default')   
                setAxisInfo(stateS.handle.CERRAxis(1), 'scanSelectMode', 'auto');
                stateS.annotToggle = -1;
                stateS.CTDisplayChanged = 1;
                CERRRefresh
        
        end
        
end

function pos = absPos(absPos, box)
%Convert from relative position to absolute position in pixels, given
%x,y,w,h of box and position within.

x = box(1); y = box(2);
w = box(3); h = box(4);

pos(1) = absPos(1) * w + x;
pos(2) = absPos(2) * h + y;
pos(3) = absPos(3) * w;
pos(4) = absPos(4) * h;

function fh=warp_image(f,A)
[h,w]=size(f);
[x,y]=meshgrid([1:h],[1:w]);
f_coord=[x(:),y(:),ones(h*w,1)];
fh_coord=f_coord*A;
xd=fh_coord(:,1); yd=fh_coord(:,2);
% apply interpolation
fh=reshape(bilinear_interpolation(double(f),xd,yd),w,h)';
return

function COM = getXYCOM(scanSet,command)
% written by DK
global planC stateS

indexS = planC{end};

switch upper(command)
    case 'BASE'
        type = stateS.imageRegistrationBaseDatasetType;
    case 'MOVE'
        type = stateS.imageRegistrationMovDatasetType;
end
switch upper(type)
    case 'SCAN'
        [xV, yV, zV] = getUniformScanXYZVals(planC{indexS.scan}(scanSet));
        transM = getTransM('scan', scanSet, planC);
    case 'DOSE'
        [xV, yV, zV] = getDoseXYZVals(planC{indexS.dose}(scanSet));
        transM = getTransM('dose', scanSet, planC);
end

COM(1,1) = mean(xV);
COM(2,1) = mean(yV);
COM(3,1) = mean(zV);
if ~isempty(transM) && ~isequal(transM,eye(4))
    [COM]= applyTransM(transM,COM');
    COM = COM';
end


function updateBaseLevelWidthHandles()
global stateS planC
indexS = planC{end};
baseSet = stateS.imageRegistrationBaseDataset;
scanUID = ['c',repSpaceHyp(planC{indexS.scan}(baseSet).scanUID(max(1,end-61):end))];

baseCTWidth = stateS.scanStats.CTWidth.(scanUID);
baseCTLevel = stateS.scanStats.CTLevel.(scanUID);
baseColormap = stateS.scanStats.Colormap.(scanUID);
basePreset = stateS.scanStats.windowPresets.(scanUID);

ud = stateS.handle.controlFrameUd;
set(ud.handles.baseCTLevel,'string',baseCTLevel);
set(ud.handles.baseCTWidth,'string', baseCTWidth);
set(ud.handles.basePreset,'value',basePreset);
stringC = get(ud.handles.basedisplayModeColor,'string');
movCormpmapIndex = find(strcmpi(baseColormap,stringC));
set(ud.handles.basedisplayModeColor,'value',movCormpmapIndex)
stateS.handle.controlFrameUd = ud;

function updateMovLevelWidthHandles()
global stateS planC
indexS = planC{end};
movSet = stateS.imageRegistrationMovDataset;
scanUID = ['c',repSpaceHyp(planC{indexS.scan}(movSet).scanUID(max(1,end-61):end))];

movCTWidth = stateS.scanStats.CTWidth.(scanUID);
movCTLevel = stateS.scanStats.CTLevel.(scanUID);
movColormap = stateS.scanStats.Colormap.(scanUID);
movPreset = stateS.scanStats.windowPresets.(scanUID);

ud = stateS.handle.controlFrameUd;
set(ud.handles.MovCTLevel,'string',movCTLevel);
set(ud.handles.MovCTWidth,'string',movCTWidth);
set(ud.handles.MovPresets,'value',movPreset);
stringC = get(ud.handles.displayModeColor,'string');
movCormpmapIndex = find(strcmpi(movColormap,stringC));
set(ud.handles.displayModeColor,'value',movCormpmapIndex)
stateS.handle.controlFrameUd = ud;

