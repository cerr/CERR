function varargout = doseManagementGui(command, varargin)
%"doseManagementGui" GUI
%   Create a GUI to manage doses.
%
%   JRA 2/27/04
%
%Usage:
%   doseManagementGui()
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

%The cursed globals. Need em.
global planC stateS
indexS = planC{end};

%Use a static window size, by pixels.  Do not allow resizing.
screenSize = get(0,'ScreenSize');
y = 380;
x = 640;
units = 'normalized';

%Height of a single row of text.
rowHeight = .06;

%If no command given, default to init.
if ~exist('command') | isempty(command)
    command = 'init';
end

%Find handle of the gui figure.
h = findobj('tag', 'doseManagementGui');

%Set framecolor for uicontrols and pseudoframes.
frameColor = [0.8314 0.8157 0.7843];

switch upper(command)
    case 'INIT'
        %If gui doesnt exist, create it, else refresh it.
        if isempty(h)
            %Set up a new GUI window.
            h = figure('doublebuffer', 'on', 'units', 'pixels', 'position',[(screenSize(3)-x)/2 (screenSize(4)-y)/2 x y], 'MenuBar', 'none', 'NumberTitle', 'off', 'resize', 'off', 'Tag', 'doseManagementGui', 'Color', [.75 .75 .75], 'WindowButtonUpFcn', 'doseManagementGui(''FIGUREBUTTONUP'')');
            stateS.handle.doseManagementFig = h;
            set(h, 'Name','Dose Management');

            %Create pseudo frames.
            axes('Position', [.02 .05 + (rowHeight + .02) .96 .87 - (rowHeight + .02)/2], 'color', frameColor, 'ytick',[],'xtick',[], 'box', 'on');
            line([.5 .5], [0 1], 'color', 'black');
            axes('Position', [.02 .03 .96 rowHeight+.02], 'color', frameColor, 'ytick',[],'xtick',[], 'box', 'on');

            %Create controls for displaying the GUI status.
            ud.handles.status = uicontrol(h, 'units', units, 'string', 'Status:', 'Position', [.04 .03 .05 rowHeight], 'Style', 'text', 'BackgroundColor', frameColor);
            ud.handles.status = uicontrol(h, 'units', units, 'string', '', 'Position', [.1 .03 .8 rowHeight], 'Style', 'text', 'HorizontalAlignment', 'left', 'foregroundcolor', 'red', 'BackgroundColor', frameColor);
            ud.currentDose = 1;
            ud.doseBlock = 1;
            set(h, 'userdata', ud);
        end
        doseManagementGui('refresh', h);
        figure(h);

    case 'REFRESHFIELDS'
        %Refresh the field list for the current dose.
        ud = get(h, 'userdata');
        doseNum = ud.currentDose;
        set(ud.handles.name, 'string', planC{indexS.dose}(doseNum).fractionGroupID);
        set(ud.handles.units, 'string', planC{indexS.dose}(doseNum).doseUnits);
        [dA, isCompress, isRemote] = getDoseArray(doseNum, planC);
        if isCompress
            set(ud.handles.compbutton, 'string', 'Decompress');
            set(ud.handles.storageMethod, 'string', 'Memory, Compressed');
        else
            set(ud.handles.compbutton, 'string', 'Compress');
        end

        if isRemote
            set(ud.handles.remotebutton, 'string', 'Use Memory');
            set(ud.handles.storageMethod, 'string', 'On Disk');
        else
            set(ud.handles.remotebutton, 'string', 'Use Disk');
        end

        if ~isCompress & ~isRemote
            set(ud.handles.storageMethod, 'string', 'Memory');
        end
        set(ud.handles.maxdose, 'string', ud.maxDoses{doseNum});
        doseSize = getByteSize(planC{indexS.dose}(doseNum));
        set(ud.handles.dosesize, 'string', [num2str(doseSize/(1024*1024), '%6.2f') 'MB']);

    case 'REFRESH'
        %Recreate and redraw the entire doseManagementGui.
        if isempty(h)
            return;
        end

        %Save the current figure so focus can be returned.
        hOld = gcf;

        %Focus on doseManagementGui for the moment.
        set(0, 'CurrentFigure', h);
        ud = get(h, 'userdata');
        try
            %Scrap all old buttons and axes.
            delete(ud.handles.thumbaxis);
            delete(ud.handles.name);
            delete(ud.handles.dosesize);
            delete(ud.handles.storageMethod);
            delete(ud.handles.maxdose);
            delete(ud.handles.units);
            delete(ud.handles.compbutton);
            delete(ud.handles.copybutton);
            delete(ud.handles.delbutton);
            ud.handles.thumbaxis = [];
            ud.handles.name = [];
            ud.handles.dosesize = [];
            ud.handles.storageMethod = [];
            ud.handles.maxdose = [];
            ud.handles.units = [];
            ud.handles.compbutton = [];
            ud.handles.copybutton = [];
            ud.handles.delbutton = [];
        end   
        
        i = 1;

        txtLeft = .05;
        textWidth = .13;
        fieldLeft = .35;
        fieldWidth = .13;

        %Make text to describe uicontrols.
        uicontrol(h, 'units',units,'Position',[txtLeft 1-.15 textWidth rowHeight],'String', 'Edit Dose name:', 'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor,'TooltipString','Change/Edit dose name string');
        uicontrol(h, 'units',units,'Position',[txtLeft 1-.21 textWidth rowHeight],'String', 'RAM Used:', 'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor,'TooltipString','Memory used');
        uicontrol(h, 'units',units,'Position',[txtLeft 1-.27 textWidth rowHeight],'String', 'Storage Method:', 'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor,'TooltipString','Tells if dose is stored on disk OR RAM');
        uicontrol(h, 'units',units,'Position',[txtLeft 1-.33 textWidth rowHeight],'String', 'Max Dose:', 'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor,'TooltipString','Maximum Dose Value');
        uicontrol(h, 'units',units,'Position',[txtLeft 1-.39 textWidth rowHeight],'String', 'Units:', 'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor,'TooltipString','Dose Units');
        uicontrol(h, 'units',units,'Position',[0.24 1-.39 textWidth rowHeight],'String', 'Scale by:', 'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'TooltipString', 'Scale Factor');

        %Make uicontrols for managing the doses, and displaying info.
        ud.handles.name          = uicontrol(h, 'units',units,'Position',[fieldLeft-fieldWidth 1-.15+.02 fieldWidth*2 rowHeight-.01],'String','', 'Style', 'edit', 'callback', 'doseManagementGui(''NAMEFIELD'');', 'userdata', i, 'horizontalAlignment', 'right','TooltipString','Change/Edit dose name string');
        ud.handles.dosesize      = uicontrol(h, 'units',units,'Position',[fieldLeft 1-.21 fieldWidth rowHeight],'String', '',  'Style', 'text', 'horizontalAlignment', 'right', 'BackgroundColor', frameColor,'TooltipString','Memory used');
        ud.handles.storageMethod = uicontrol(h, 'units',units,'Position',[fieldLeft-.05 1-.27 fieldWidth+.05 rowHeight],'String', '',  'Style', 'text', 'horizontalAlignment', 'right', 'BackgroundColor', frameColor,'TooltipString','Tells if dose is stored on disk OR RAM');
        ud.handles.maxdose       = uicontrol(h, 'units',units,'Position',[fieldLeft 1-.33+.02 fieldWidth rowHeight-.01],'String', '', 'Style', 'edit', 'callback', 'doseManagementGui(''DOSESCALE'');', 'userdata', i, 'horizontalAlignment', 'right','TooltipString','Maximum Dose Value');
        %ud.handles.units         = uicontrol(h, 'units',units,'Position',[fieldLeft 1-.39 fieldWidth rowHeight],'String', '',  'Style', 'text', 'horizontalAlignment', 'right', 'BackgroundColor', frameColor);
        ud.handles.units         = uicontrol(h, 'units',units,'Position',[0.1 1-.39+0.02 fieldWidth-0.02 rowHeight-0.01],'String', '',  'Style', 'edit', 'callBack','doseManagementGui(''UNITFIELD'');','horizontalAlignment', 'left','TooltipString','Dose Units');
        ud.handles.scale         = uicontrol(h, 'units',units,'Position',[fieldLeft 1-.39+0.02 fieldWidth rowHeight-0.01],'String', '',  'Style', 'edit', 'callBack','doseManagementGui(''SCALEBYFACTOR'');', 'horizontalAlignment', 'left','TooltipString','Scale Factor');

        ud.handles.remotebutton  = uicontrol(h, 'units',units,'Position',[fieldLeft 1-.59 fieldWidth rowHeight],'String', 'Make Remote', 'Style', 'pushbutton', 'callback', 'doseManagementGui(''REMOTE'');', 'userdata', i,'TooltipString','Store Dose Remotely, save memory used');
        ud.handles.compbutton    = uicontrol(h, 'units',units,'Position',[fieldLeft 1-.67 fieldWidth rowHeight],'String', 'Compress', 'Style', 'pushbutton', 'callback', 'doseManagementGui(''COMPRESS'');', 'userdata', i,'TooltipString','Compress Remote Dose');
%         ud.handles.copybutton    = uicontrol(h, 'units',units,'Position',[fieldLeft 1-.75 fieldWidth rowHeight],'String','Save', 'Style', 'pushbutton', 'callback', 'doseManagementGui(''SAVE'');', 'userdata', i);
        ud.handles.delbutton     = uicontrol(h, 'units',units,'Position',[fieldLeft 1-.83 fieldWidth rowHeight],'String','Delete', 'Style', 'pushbutton', 'callback', 'doseManagementGui(''DELETE'');', 'userdata', i,'TooltipString','Delete Dose Permantely/ Save Plan to take effect');

        ud.handles.previewAxis   = axes('position', [txtLeft 1-.83 .25 .25*x/y], 'parent', h, 'box', 'on', 'ytick', [], 'xtick', [], 'buttondownfcn', 'doseManagementGui(''PREVIEWBUTTONDOWN'')');
        ud.handles.previewSliceNum = uicontrol(h, 'units',units,'Position',[fieldLeft-0.03 1-.47 fieldWidth rowHeight],'String', '',  'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor);

        text(.5, .6, 'After selecting a dose, ', 'fontsize', 8, 'hittest', 'off', 'parent', ud.handles.previewAxis, 'horizontalAlignment', 'center');
        text(.5, .5, 'click and drag mouse up', 'fontsize', 8, 'hittest', 'off', 'parent', ud.handles.previewAxis, 'horizontalAlignment', 'center');
        text(.5, .4, 'and down here to preview.', 'fontsize', 8, 'hittest', 'off', 'parent', ud.handles.previewAxis, 'horizontalAlignment', 'center');

        % Create Prev and Next Buttons        
        nDoses = length(planC{indexS.dose});
        if nDoses > 9
            ud.handles.prev = uicontrol(h, 'units',units,'Position',[fieldLeft+0.18 1-.86 0.1 rowHeight],'String','<--', 'Style', 'pushbutton', 'callback', 'doseManagementGui(''PREV_BLOCK'');', 'TooltipString','Show Previous Set of Doses','fontWeight','bold');
            ud.handles.next = uicontrol(h, 'units',units,'Position',[fieldLeft+0.5 1-.86 0.1 rowHeight],'String','-->', 'Style', 'pushbutton', 'callback', 'doseManagementGui(''NEXT_BLOCK'');', 'TooltipString','Show Next Set of Doses','fontWeight','bold');
            uicontrol(h, 'units',units,'Position',[fieldLeft+0.3 1-.86 0.18 rowHeight+0.01],'String','Use these buttons to view more doses', 'Style', 'text', 'fontSize',8,'fontWeight','normal', 'BackgroundColor', frameColor);
        end        
        
        set(h, 'userdata', ud);
        set(0, 'CurrentFigure', hOld);
        
        doseManagementGui('REFRESH_THUMBS')

    case 'PREV_BLOCK'
        ud = get(h, 'userdata');
        if ud.doseBlock == 1
            return;
        end
        ud.doseBlock = ud.doseBlock - 1;   
        set(h, 'userdata', ud);
        doseManagementGui('REFRESH_THUMBS')        
        
    case 'NEXT_BLOCK'
        ud = get(h, 'userdata');
        nDoses = length(planC{indexS.dose});
        maxDoseBlocks = ceil(nDoses/9);
        if ud.doseBlock == maxDoseBlocks
            return;
        end
        ud.doseBlock = ud.doseBlock + 1;     
        set(h, 'userdata', ud);
        doseManagementGui('REFRESH_THUMBS')
                      
    case 'REFRESH_THUMBS'
        
        ud = get(h, 'userdata');
        if isfield(ud.handles,'thumbaxis')
            try %To handle double-clicks on next and previous buttons
                delete(ud.handles.thumbaxis);
            catch
                %return
            end
        end

        nDoses      = length(planC{indexS.dose});

        dosesToDisplayV = (ud.doseBlock-1)*9+1:min(nDoses,ud.doseBlock*9);
        nDoses = length(dosesToDisplayV);
        
        if ud.currentDose > max(dosesToDisplayV)
            ud.currentDose = max(dosesToDisplayV);
        elseif ud.currentDose < min(dosesToDisplayV)
            ud.currentDose = min(dosesToDisplayV);
        end        

        %Downsample colormap, redraws much faster.
        cM = CERRColorMap(stateS.optS.doseColormap);
        n  = size(cM, 1);
        newSize = 32;
        interval = (n-1) / 32;
        b = interp1(1:n, cM(:,1), 1:interval:n);
        c = interp1(1:n, cM(:,2), 1:interval:n);
        d = interp1(1:n, cM(:,3), 1:interval:n);
        ud.cM = [b' c' d'];
        
        %Setup thumbnail pane, with NxN axes.
        dx = 1/x; %pixel width in x,
        dy = 1/y; %pixel width in y, for margins.
        %thumbRegion = [.52 .17 .44 .75];
        thumbRegion = [.52 .23 .44 .70];
        subPlotSize = max(1,ceil(sqrt(nDoses)));
        dh = thumbRegion(4)/subPlotSize;
        dw = thumbRegion(3)/subPlotSize;
        ud.handles.thumbaxis = [];
        for i =1:subPlotSize^2
            row = subPlotSize - ceil(i/subPlotSize) + 1;
            col = mod(i-1,subPlotSize)+1;
            ud.handles.thumbaxis(i) = axes('position', [thumbRegion(1) + dw*(col-1) thumbRegion(2) + dh*(row-1) dw-dx dh-dy], 'box', 'on');
            set(ud.handles.thumbaxis(i), 'ytick',[],'xtick',[], 'color', 'black');
            colormap(ud.handles.thumbaxis(i), ud.cM);
        end

        maxDose = [];
        for i=1:nDoses
            set(ud.handles.thumbaxis(i), 'ButtonDownFcn', ['doseManagementGui(''CHANGEDOSE'', ' num2str(dosesToDisplayV(i)) ');']);
            maxDose{dosesToDisplayV(i)} = num2str(drawThumb(ud.handles.thumbaxis(i), planC, dosesToDisplayV(i), h));
            ud.previewSlice(dosesToDisplayV(i)) = 1; %%%%%%%%%%%%%%%%%
        end
        
        ud.maxDoses = maxDose;
        
        try
            set(ud.handles.previewAxis,'nextPlot','add')
            set(ud.handles.thumbaxis,'nextPlot','add')
        end
        
        set(h,'userdata',ud)        
        
        if ~isempty(maxDose)
            doseManagementGui('REFRESHFIELDS');
        end
        
        
        
    case 'PREVIEWBUTTONDOWN'
        %Button clicked in the preview window.
        ud = get(h, 'userdata');
        ud.previewDown = 1;
        set(h, 'WindowButtonMotionFcn', 'doseManagementGui(''PREVIEWMOTION'')');
        set(h, 'userdata', ud)

    case 'FIGUREBUTTONUP'
        %Mouse up, if in preview window disable motion fcn.
        ud = get(h, 'userdata');
        if ~isfield(ud, 'previewDown') | ud.previewDown == 1;
            ud.previewDown = 0;
            set(h, 'WindowButtonMotionFcn', '');
            set(h, 'userdata', ud);
        end

    case 'PREVIEWMOTION'
        %Motion in the preview, with mouse down. Change preview slice.
        ud = get(h, 'userdata');
        cp = get(h, 'currentpoint');
        if isfield(ud, 'previewY')
            if ud.previewY > cp(2)
                ud.previewSlice(ud.currentDose) = ud.previewSlice(ud.currentDose)+1;%min(ud.previewSlice(ud.currentDose)+1, size(getDoseArray(ud.currentDose), 3));
                set(h, 'userdata', ud);
                doseManagementGui('refreshpreviewandfields');
            elseif ud.previewY < cp(2)
                ud.previewSlice(ud.currentDose) = ud.previewSlice(ud.currentDose)-1;%max(ud.previewSlice(ud.currentDose)-1,1);
                set(h, 'userdata', ud);
                doseManagementGui('refreshpreviewandfields');
            end
            ud = get(h, 'userdata');
            ud.previewY = cp(2);
        else
            ud.previewY = cp(2);
        end
        set(h, 'userdata', ud);

    case 'REFRESHPREVIEWANDFIELDS'
        %Refresh both the preview and the fields.  Not modular with RefreshFields
        %to ensure that only one call to getDoseArray is made.
        ud = get(h, 'userdata');
        try
            set(ud.handles.previewAxis,'nextPlot','replace')
            set(ud.handles.thumbaxis,'nextPlot','replace')
        end
        doseNum = ud.currentDose;
        bdf = get(ud.handles.previewAxis, 'buttondownfcn');
        [dA, isCompress, isRemote] = getDoseArray(doseNum, planC);
        minSlice = 1;
        maxSlice = size(dA, 3);
        previewSlice = clip(ud.previewSlice(doseNum), minSlice, maxSlice, 'limits');
        ud.previewSlice(doseNum) = previewSlice;
        set(ud.handles.previewSliceNum, 'string', num2str(previewSlice));
        maxDose = str2num(ud.maxDoses{doseNum});
        cLim =  [0 maxDose];
        if maxDose == 0;
            cLim = [0 1];
        end
        imagesc(dA(:,:,previewSlice), 'parent', ud.handles.previewAxis, 'hittest', 'off');
        set(ud.handles.previewAxis, 'buttondownfcn', bdf, 'box', 'on', 'ytick', [], 'xtick', [], 'CLim', cLim);
        set(h, 'userdata', ud);

        %Refresh fields as well.
        set(ud.handles.name, 'string', planC{indexS.dose}(doseNum).fractionGroupID);
        set(ud.handles.units, 'string', planC{indexS.dose}(doseNum).doseUnits);
        if isCompress
            set(ud.handles.compbutton, 'string', 'Decompress');
            set(ud.handles.storageMethod, 'string', 'Memory, Compressed');
        else
            set(ud.handles.compbutton, 'string', 'Compress');
        end

        if isRemote
            set(ud.handles.remotebutton, 'string', 'Use Memory');
            set(ud.handles.storageMethod, 'string', 'On Disk');
        else
            set(ud.handles.remotebutton, 'string', 'Use Disk');
        end

        if ~isCompress & ~isRemote
            set(ud.handles.storageMethod, 'string', 'Memory');
        end

        %Refresh borders.        
        set(ud.handles.thumbaxis, 'xcolor', 'black', 'ycolor', 'black');
        set(ud.handles.thumbaxis(doseNum - (ud.doseBlock-1)*9), 'xcolor', 'yellow', 'ycolor', 'yellow');

        set(ud.handles.maxdose, 'string', ud.maxDoses{doseNum});
        doseSize = getByteSize(planC{indexS.dose}(doseNum));
        set(ud.handles.dosesize, 'string', [num2str(doseSize/(1024*1024), '%6.2f') 'MB']);

        set(ud.handles.previewAxis,'nextPlot','add')
        set(ud.handles.thumbaxis,'nextPlot','add')

    case 'CHANGEDOSE'
        %New dose has been clicked on.
        ud = get(h, 'userdata');
        oldDose = ud.currentDose;
        newDose = varargin{1};
        ud.currentDose = newDose;
        set(h, 'userdata', ud);
        doseManagementGui('refreshpreviewandfields');

    case 'NAMEFIELD'
        %Dose name has changed, update in planC.
        ud = get(h, 'userdata');
        doseNum = ud.currentDose;
        doseUID = planC{indexS.dose}(doseNum).doseUID;
        oldString = planC{indexS.dose}(doseNum).fractionGroupID;
        string = get(gcbo, 'string');
        
%       Check for duplicate or blank names.
        if (length(string) == 0)
            warndlg('The dose name cannot be blank. Please enter a name.', 'Warning','modal');
            return;
        end
        if ~strcmp(oldString, string)
            for i = 1:length(planC{indexS.dose})
                if ischar(planC{indexS.dose}(1,i).fractionGroupID)
                    idString = planC{indexS.dose}(1,i).fractionGroupID;
                else
                    idString = num2str(planC{indexS.dose}(1,i).fractionGroupID);
                end
                if strcmpi(idString, string) && ~strcmp(idString, oldString)
                    warndlg('That plan name is already in use. Please choose another name.', 'Warning','modal');
                    return;
                end
            end
            for i = 1:length(planC{indexS.DVH}) 
                if ischar(planC{indexS.DVH}(1,i).planIDOfOrigin)
                    idString = planC{indexS.DVH}(1,i).planIDOfOrigin;
                else
                    idString = num2str(planC{indexS.DVH}(1,i).planIDOfOrigin);
                end
                if strcmpi(idString, string) && ~strcmp(idString, oldString)
                    warndlg('That plan name is already in use. Please choose another name.', 'Warning','modal');
                    return;
                end
            end
        end
        
        planC{indexS.dose}(doseNum).fractionGroupID = string;
        statusString = ['Renamed dose number ' num2str(doseNum) ' from ''' oldString ''' to ''' string '''.'];
        doseManagementGui('status', statusString);        

%       Write new fractionGroupID to beam geometry
        for i = 1:length(planC{indexS.beamGeometry}) 
            if ischar(planC{indexS.beamGeometry}(1,i).fractionGroupID)
                idString = planC{indexS.beamGeometry}(1,i).fractionGroupID;
            else
                idString = num2str(planC{indexS.beamGeometry}(1,i).fractionGroupID);
            end
            if strcmp(idString, oldString)
                planC{indexS.beamGeometry}(1,i).fractionGroupID = string;
            end
        end
        
%       Write new fractionGroupID to DVH as fractionIDOfOrigin
        for i = 1:length(planC{indexS.DVH}) 
            if ischar(planC{indexS.DVH}(1,i).fractionIDOfOrigin)
                idString = planC{indexS.DVH}(1,i).fractionIDOfOrigin;
            else
                idString = num2str(planC{indexS.DVH}(1,i).fractionIDOfOrigin);
            end
            if strcmp(idString, oldString)
                planC{indexS.DVH}(1,i).fractionIDOfOrigin = string;
            end
            
            try
                if strcmpi(planC{indexS.DVH}(1,i).assocDoseUID, doseUID) && ...
                        ~isempty(planC{indexS.DVH}(1,i).planIDOfOrigin)
                    planC{indexS.DVH}(1,i).planIDOfOrigin = string;
                end
            end
        end
        
    case 'UNITFIELD'
        %Dose units have changed, update in planC.
        ud = get(h, 'userdata');
        doseNum = ud.currentDose;
        oldString = planC{indexS.dose}(doseNum).doseUnits;
        string = get(gcbo, 'string');
        planC{indexS.dose}(doseNum).doseUnits = string;
        statusString = ['Renamed units of dose number ' num2str(doseNum) ' from ''' oldString ''' to ''' string '''.'];
        doseManagementGui('status', statusString);

    case 'STATUS'
        %Display passed string in status bar.
        statusString = varargin{1};
        ud = get(gcbf, 'userdata');
        h = ud.handles.status;
        set(h, 'string', statusString);
        drawnow

    case 'COMPRESS'
        %Compress/decompress selected dose.
        ud = get(h, 'userdata');
        doseNum = ud.currentDose;
        doseName = planC{indexS.dose}(doseNum).fractionGroupID;

        if ~isCompressed(planC{indexS.dose}(doseNum).doseArray)
            statusString = ['Compressing dose number ' num2str(doseNum) ', ''' doseName ''' please wait...'];
            doseManagementGui('status', statusString);
            planC{indexS.dose}(doseNum).doseArray = compress(getDoseArray(doseNum, planC));
            drawThumb(ud.handles.thumbaxis(doseNum), planC, doseNum, h);
            statusString = ['Compressed dose number ' num2str(doseNum)  ', ''' doseName '''.'];
            doseManagementGui('status', statusString);
            set(ud.handles.compbutton, 'string', 'Decompress');
        else
            statusString = ['Decompressing dose number ' num2str(doseNum) ', ''' doseName ''', please wait...'];
            doseManagementGui('status', statusString);
            %Use getDoseArray and not decompress to use the cached value.
            planC{indexS.dose}(doseNum).doseArray = getDoseArray(doseNum, planC);
            maxDose = drawThumb(ud.handles.thumbaxis(doseNum), planC, doseNum, h);
            %Update the maxDoses value, but be sure to get a fresh ud since
            %a user could have clicked during compression.
            ud = get(h, 'userdata');
            ud.maxDoses{doseNum} = num2str(maxDose);
            set(h, 'userdata', ud);
            statusString = ['Decompressed dose number ' num2str(doseNum)  ', ''' doseName '''.'];
            doseManagementGui('status', statusString);
            set(ud.handles.compbutton, 'string', 'Compress');
        end
        doseManagementGui('refreshpreviewandfields');

    case 'REMOTE'
        %Make/unmake selected dose remote.
        ud = get(h, 'userdata');
        doseNum = ud.currentDose;
        doseName = planC{indexS.dose}(doseNum).fractionGroupID;

        doseUID = planC{indexS.dose}(doseNum).doseUID;

        if isLocal(planC{indexS.dose}(doseNum).doseArray)
            statusString = ['Writing to disk dose number ' num2str(doseNum) ', ''' doseName ''' please wait...'];
            doseManagementGui('status', statusString);
            [fpath,fname] = fileparts(stateS.CERRFile);
            %planC{indexS.dose}(doseNum).doseArray = setRemoteVariable(getDoseArray(doseNum, planC), 'LOCAL',[fpath,'\',fname,'_store'],['doseArray_',doseName,'.mat']);
            planC{indexS.dose}(doseNum).doseArray = setRemoteVariable(getDoseArray(doseNum, planC), 'LOCAL',fullfile(fpath,[fname,'_store']),['doseArray_',doseUID,'.mat']);
            drawThumb(ud.handles.thumbaxis(doseNum), planC, doseNum, h);
            statusString = ['Wrote to disk dose number ' num2str(doseNum)  ', ''' doseName '''.'];
            doseManagementGui('status', statusString);
            set(ud.handles.remotebutton, 'string', 'Use Memory');
            uiwait(msgbox(['doseArray stored in folder ',fullfile(fpath,[fname,'_store']),'Note the Location','modal']))

        else
            statusString = ['Reading from disk dose number ' num2str(doseNum) ', ''' doseName ''', please wait...'];
            doseManagementGui('status', statusString);

            remotePath = planC{indexS.dose}(doseNum).doseArray.remotePath;
            filenam = planC{indexS.dose}(doseNum).doseArray.filename;
            %Use getDoseArray and not decompress to use the cached value.
            planC{indexS.dose}(doseNum).doseArray = getDoseArray(doseNum, planC);
            
            stateS.reqdRemoteFiles(strcmp(fullfile(remotePath,filenam),stateS.reqdRemoteFiles)) = [];            
            delete(fullfile(remotePath,filenam))
            
            %remove remote storage directory if it is empty
            dirRemoteS = dir(remotePath);
            if ~any(~cellfun('isempty',strfind({dirRemoteS.name},'.mat')))
                rmdir(remotePath)
            end
            maxDose = drawThumb(ud.handles.thumbaxis(doseNum), planC, doseNum, h);
            statusString = ['Read from disk dose number ' num2str(doseNum)  ', ''' doseName '''.'];
            doseManagementGui('status', statusString);
            set(ud.handles.remotebutton, 'string', 'Use Disk');

            %Update the maxDoses value, but be sure to get a fresh ud since
            %a user could have clicked during remote writing to disk.
            ud = get(h, 'userdata');
            ud.maxDoses{doseNum} = num2str(maxDose);
            set(h, 'userdata', ud);
        end
        doseManagementGui('refreshpreviewandfields');

    case 'SAVE'
        %Open dialog to save dose array as .mat file.
        ud = get(h, 'userdata');
        doseNum = ud.currentDose;
        doseName = planC{indexS.dose}(doseNum).fractionGroupID;
        [filename, pathname] = uiputfile('*.mat', ['Save (uncompressed) dose array number ' num2str(doseNum) ' as:']);
        if filename==0
            return;
        end
        dose3D = getDoseArray(doseNum, planC);
        save(fullfile(pathname, filename), 'dose3D');
        statusString = ['Saved dose number ' num2str(doseNum) ', ''' doseName ''' to ' [filename '.mat'] '.'];
        doseManagementGui('status', statusString);

    case 'DELETE'
        %Delete selected dose.  If being displayed, verify deletion with user.
        ud = get(h, 'userdata');
        doseNum = ud.currentDose;
        doseName = planC{indexS.dose}(doseNum).fractionGroupID;

        refreshViewer = 0;
        axesV = checkDisplayedDoses(doseNum);
        if ~isempty(axesV)
            choice = questdlg('One or more CERR axes are currently displaying this dose.  If you delete it, these axes will be set to display no dose.  Proceed?', 'Continue?', 'Continue', 'Abort', 'Continue');
            if strcmpi(choice, 'Abort')
                statusString = ['Delete aborted.'];
                doseManagementGui('status', statusString);
                return;
            else
                %Set the axes dose value to null.
                setAxisDoseToNull(axesV);
            end
        end

        if stateS.doseSet == doseNum
            stateS.doseSet = [];
        end
        del = questdlg(['Are you sure you want to delete dose number' num2str(doseNum) ', ''' doseName '''?'], 'Continue?', 'Continue', 'Abort', 'Continue');
        if strcmpi(del, 'Continue')
            statusString = ['Deleted dose number ' num2str(doseNum) ', ''' doseName '''.'];
            doseManagementGui('status', statusString);
            planC{indexS.dose}(doseNum) = [];
            %If dose below displayed dose deleted, its number has changed.
            if doseNum < stateS.doseSet
                stateS.doseSet = stateS.doseSet - 1;
            end
            refreshViewer = 1;
            updateAxesForDeletedDose(doseNum);
            doseManagementGui;
        else
        end
               
        % Delete colorbar children if plan contains no dose 
        if length(planC{indexS.dose}) == 0
            delete(get(stateS.handle.doseColorbar.trans, 'children'));
        end
        
        %Refresh CERR axes in the case of changed dose sets.
        if refreshViewer
            sliceCallBack('refresh');
        end

    case 'DOSESCALE'
        ud          = get(h, 'userdata');
        doseNum     = ud.currentDose;
        doseName    = planC{indexS.dose}(doseNum).fractionGroupID;
        newMaxDose  = str2num(get(gcbo, 'string'));

        %Get the dose array and its compression state.
        [dA, isCompress, isRemote] = getDoseArray(doseNum, planC);

        maxDose = max(dA(:));
        if maxDose == 0
            set(gcbo, 'string', '0')
            statusString = ['Unable to rescale all zero dose distribution.'];
            doseManagementGui('status', statusString);
            return;
        end

        doseManagementGui('status', 'Rescaling dose, please wait...');

        if isCompress | isRemote
            statusString = ['Rescaling compressed or remote dose can take a moment, please wait...'];
            doseManagementGui('status', statusString);
        end

        %Perform the rescale.
        dA = dA *  (1/maxDose * newMaxDose);

        oldDoseUID = planC{indexS.dose}(doseNum).doseUID;

        % set new dose UID
        planC{indexS.dose}(doseNum).doseUID = createUID('DOSE');
        
        % update doseArray in dose struct. 
        planC = setDoseArray(doseNum, dA, planC);

        % remove old remote file if it exists
        if ~isLocal(planC{indexS.dose}(doseNum).doseArray)
            if ~ismember(fullfile(planC{indexS.dose}(doseNum).doseArray.remotePath,['doseArray_',oldDoseUID,'.mat']),stateS.reqdRemoteFiles)
                delete(fullfile(planC{indexS.dose}(doseNum).doseArray.remotePath,['doseArray_',oldDoseUID,'.mat']))
            end
        end

        statusString = ['Rescaled dose number ' num2str(doseNum) ', ''' doseName ''' from [0 ' num2str(maxDose) '] Gy to [0 ' num2str(newMaxDose) '] Gy.'];
        ud.maxDoses{doseNum} = num2str(newMaxDose);
        set(h, 'userdata', ud);

        % update dose UID's for CERR axes
        for i = 1:length(stateS.handle.CERRAxis)
            if getAxisInfo(stateS.handle.CERRAxis(i),'doseSets') == doseNum
                setAxisInfo(stateS.handle.CERRAxis(i),'doseSets',doseNum)
            end
        end
        
        stateS.doseSetChanged = 1;
        stateS.CTDisplayChanged = 1;
        CERRRefresh
        doseManagementGui('status', statusString);

    case 'SCALEBYFACTOR'
        ud          = get(h, 'userdata');
        doseNum     = ud.currentDose;
        doseName    = planC{indexS.dose}(doseNum).fractionGroupID;
        scale       = str2num(get(gcbo, 'string'));
        if isempty(scale) | ~isnumeric(scale)
            return
        end

        %Get the dose array and its compression state.
        [dA, isCompress, isRemote] = getDoseArray(doseNum, planC);

        doseManagementGui('status', 'Scaling dose, please wait...');

        if isCompress | isRemote
            statusString = ['Scaling compressed or remote dose can take a moment, please wait...'];
            doseManagementGui('status', statusString);
        end

        %Perform the rescale.
        dA = dA *  scale;
        set(ud.handles.maxdose,'string',num2str(max(dA(:))))

        statusString = ['Rescaled dose number ' num2str(doseNum) ', ''' doseName ''' by a factor of ' num2str(scale)];

        oldDoseUID = planC{indexS.dose}(doseNum).doseUID;

        % set new dose UID
        planC{indexS.dose}(doseNum).doseUID = createUID('DOSE');
        
        % update doseArray in dose struct. 
        planC = setDoseArray(doseNum, dA, planC);
        
        % remove old remote file if it exists
        if ~isLocal(planC{indexS.dose}(doseNum).doseArray)
            if ~ismember(fullfile(planC{indexS.dose}(doseNum).doseArray.remotePath,['doseArray_',oldDoseUID,'.mat']),stateS.reqdRemoteFiles)
                delete(fullfile(planC{indexS.dose}(doseNum).doseArray.remotePath,['doseArray_',oldDoseUID,'.mat']))
            end
        end

        ud.maxDoses{doseNum} = num2str(str2num(ud.maxDoses{doseNum})*scale);
        set(h, 'userdata', ud);

        % update dose UID's for CERR axes
        for i = 1:length(stateS.handle.CERRAxis)
            if  getAxisInfo(stateS.handle.CERRAxis(i),'doseSets') == doseNum
                setAxisInfo(stateS.handle.CERRAxis(i),'doseSets',doseNum)
            end
        end
        
        stateS.doseSetChanged = 1;
        stateS.CTDisplayChanged = 1;
        CERRRefresh
        doseManagementGui('status', statusString);

    case 'QUIT'
        close;
end

return;

function nBytes = getByteSize(data)
%"getByteSize"
%Returns the number of bytes in the passed data
infoStruct = whos('data');
nBytes = infoStruct.bytes;
return;

function maxDose = drawThumb(hAxis, planC, index, hFigure)
%"drawThumb"
%In passed dose array, find slice with highest dose and draw in hAxis.
%Also denote the index in the corner.  If compressed show compressed.
set(hFigure, 'CurrentAxes', hAxis);
toDelete = get(hAxis, 'children');
delete(toDelete);

%Get the dose array and its compression state.
[dA, isCompress, isRemote] = getDoseArray(index, planC);

bdf = get(hAxis, 'buttondownfcn');

maxDose = arrayMax(dA);
maxLoc = find(dA == maxDose);
[r,c,s] = ind2sub(size(dA), maxLoc(1));
thumbImage = dA(:,:,s(1));
imagesc(thumbImage, 'hittest', 'off', 'parent', hAxis);
set(hAxis, 'ytick',[],'xtick',[]);
if isCompress & isRemote
    text(.1, .1, 'Compressed', 'units', 'normalized', 'fontsize', 8, 'color', 'black', 'horizontalAlignment', 'left', 'hittest', 'off', 'parent', hAxis);
    text(.1, .2, 'Remote', 'units', 'normalized', 'fontsize', 8, 'color', 'black', 'horizontalAlignment', 'left', 'hittest', 'off', 'parent', hAxis);
elseif isRemote
    text(.1, .1, 'Remote', 'units', 'normalized', 'fontsize', 8, 'color', 'black', 'horizontalAlignment', 'left', 'hittest', 'off', 'parent', hAxis);
elseif isCompress
    text(.1, .1, 'Compressed', 'units', 'normalized', 'fontsize', 8, 'color', 'black', 'horizontalAlignment', 'left', 'hittest', 'off', 'parent', hAxis);
end


xLim = get(hAxis, 'xlim');
yLim = get(hAxis, 'ylim');
x = (xLim(2) - xLim(1)) * .87 + xLim(1);
y = (yLim(2) - yLim(1)) * .15 + yLim(1);
text(x, y, num2str(index), 'fontsize', 8, 'color', 'white', 'hittest', 'off', 'parent', hAxis);
set(hAxis, 'buttondownfcn', bdf);
axis ij;
drawnow;
return;

function [nAxesV] = checkDisplayedDoses(doseNum)
%"checkDisplayedDoses"
%   Check to see if any CERR axes are displaying the requested dose num.
%   Returns the numbers of any axes that are.

global planC stateS

nAxesV = [];

%Iterate over axes.
for i=1:length(stateS.handle.CERRAxis)
    %Get axis info for this axis.
    %aI = get(stateS.handle.CERRAxis(i), 'userdata');
    aI = stateS.handle.aI(i);
    if ismember(doseNum, aI.doseSets)
        nAxesV = union(nAxesV, i);
    end
end
return;

function setAxisDoseToNull(nAxesV)
%"setAxisDoseToNull"
%   Sets the passed axis number's userdata doseUID fields to null if they
%   were using 'manual'.

global planC stateS

%Iterate over axes.
for i=1:length(nAxesV)
    %Get axis info for this axis.
    %aI = get(stateS.handle.CERRAxis(nAxesV(i)), 'userdata');
    aI = stateS.handle.aI(nAxesV(i));
    if strcmpi(aI.doseSelectMode, 'manual');
        aI.doseSets = [];
        stateS.handle.aI(nAxesV(i)) = aI;
    end
end
return;

function updateAxesForDeletedDose(delIndex)
%"updateAxesForDeletedDose"
%   Shifts all doseNums being displayed in CERR axes to account for deleted
%   dose distributions, given the number of the deleted dose.

global planC stateS
indexS = planC{end};

nAxesV = [];

%Iterate over axes.
for i=1:length(stateS.handle.CERRAxis)
    %Get axis info for this axis.
    %aI = get(stateS.handle.CERRAxis(i), 'userdata');
    aI = stateS.handle.aI(i);

    % DK
    aI.doseSets = aI.doseSets(aI.doseSets > delIndex) - 1;
%     doseSet = getAssociatedDose(aI.doseSets);
%     doseSet = doseSet(doseSet > delIndex)- 1;
%     if doseSet~=0
%         aI.doseSets = planC{indexS.dose}(doseSet).doseSets;
%     else
%         aI.doseSets = [];
%     end
    % DK

    stateS.handle.aI(i) = aI;
end
return;
