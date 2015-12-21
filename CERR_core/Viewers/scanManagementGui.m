function scanManagementGui(command, varargin)
%"scanManagementGui" GUI
%   Create a GUI to manage doses.
%
%   APA 11/21/05
%
%Usage:
%   scanManagementGui()
%  based on doseManagementGui.m by JRA
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
if ~exist('command','var') || (exist('command','var') && isempty(command))
    command = 'init';
end

%Find handle of the gui figure.
h = findobj('tag', 'scanManagementGui');

%Set framecolor for uicontrols and pseudoframes.
frameColor = [0.8314 0.8157 0.7843];

switch upper(command)
    case 'INIT'
        %If gui doesnt exist, create it, else refresh it.
        if isempty(h)
            %Set up a new GUI window.
            h = figure('doublebuffer', 'on', 'units', 'pixels', 'position',[(screenSize(3)-x)/2 (screenSize(4)-y)/2 x y], 'MenuBar', 'none', 'NumberTitle', 'off', 'resize', 'off', 'Tag', 'scanManagementGui', 'Color', [.75 .75 .75], 'WindowButtonUpFcn', 'scanManagementGui(''FIGUREBUTTONUP'')');
            stateS.handle.doseManagementFig = h;
            set(h, 'Name','Scan Management');


            %Create pseudo frames.
            axes('Position', [.02 .05 + (rowHeight + .02) .96 .87 - (rowHeight + .02)/2], 'color', frameColor, 'ytick',[],'xtick',[], 'box', 'on');
            line([.5 .5], [0 1], 'color', 'black');
            axes('Position', [.02 .03 .96 rowHeight+.02], 'color', frameColor, 'ytick',[],'xtick',[], 'box', 'on');

            %Create controls for displaying the GUI status.
            ud.handles.status = uicontrol(h, 'units', units, 'string', 'Status:', 'Position', [.04 .03 .05 rowHeight], 'Style', 'text', 'BackgroundColor', frameColor);
            ud.handles.status = uicontrol(h, 'units', units, 'string', '', 'Position', [.1 .03 .8 rowHeight], 'Style', 'text', 'HorizontalAlignment', 'left', 'foregroundcolor', 'red', 'BackgroundColor', frameColor);
            ud.currentScan = 1;
            set(h, 'userdata', ud);
        end
        scanManagementGui('refresh', h);
        figure(h);

    case 'REFRESHFIELDS'
        %Refresh the field list for the current scan.
        ud = get(h, 'userdata');
        scanNum = ud.currentScan;
        set(ud.handles.name, 'string', planC{indexS.scan}(scanNum).scanType);
        %         set(ud.handles.units, 'string', planC{indexS.scan}(scanNum).scanUnits);
        [dA, isCompress, isRemote] = getScanArray(scanNum, planC);
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
        %         set(ud.handles.maxscan, 'string', ud.maxDoses{scanNum});
        scanSize = getByteSize(planC{indexS.scan}(scanNum));
        set(ud.handles.scansize, 'string', [num2str(scanSize/(1024*1024), '%6.2f') 'MB']);
        % ESpezi MAY 2013
        % refresh scan date and time
        if isfield(planC{indexS.scan}(scanNum).scanInfo(1),'DICOMHeaders')
            scanDate = '';
            if isfield(planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders,'AcquisitionDate')
                scanDate = planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders.AcquisitionDate;
            end
            if ~isempty(scanDate)
                set(ud.handles.scanDate, 'string', datestr(datenum(scanDate,'yyyymmdd'),2));
            else
                set(ud.handles.scanDate, 'string', scanDate);
            end
            scanTime = '';
            if isfield(planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders,'AcquisitionTime')
                scanTime = planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders.AcquisitionTime;
            end
            if ~isempty(scanTime)
                [token, remain] = strtok(num2str(scanTime),'.');
                if ~isempty(strfind(token,':'))
                    [~,aqTime] = strtok(datestr(datenum(token,'HH:MM:SS')));
                else
                    [~,aqTime] = strtok(datestr(datenum(token,'HHMMSS')));
                end
                set(ud.handles.scanTime, 'string', aqTime);
            else
                set(ud.handles.scanTime, 'string', scanTime);
            end
        else
            % RTOG scan
            scanDate = planC{indexS.scan}(scanNum).scanInfo(1).scanDate;
            set(ud.handles.scanDate, 'string', scanDate);
        end
        
            
    case 'REFRESH'
        %Recreate and redraw the entire scanManagementGui.
        if isempty(h)
            return;
        end

        %Save the current figure so focus can be returned.
        hFig = gcf;

        %Focus on scanManagementGui for the moment.
        set(0, 'CurrentFigure', h);
        ud = get(h, 'userdata');
        try
            %Scrap all old buttons and axes.
            delete(ud.handles.thumbaxis);
            delete(ud.handles.name);
            delete(ud.handles.scansize);
            delete(ud.handles.storageMethod);
            % Espezi MAY 2013
            delete(ud.handles.scanDate);
            delete(ud.handles.scanTime);
            %delete(ud.handles.maxscan);
            %delete(ud.handles.units);
            delete(ud.handles.compbutton);
            delete(ud.handles.copybutton);
            delete(ud.handles.delbutton);
            ud.handles.thumbaxis = [];
            ud.handles.name = [];
            ud.handles.scansize = [];
            ud.handles.storageMethod = [];
            % Espezi MAY 2013
            ud.handles.scanDate = [];
            ud.handles.scanTime = [];
            %ud.handles.maxscan = [];
            %ud.handles.units = [];
            ud.handles.compbutton = [];
            ud.handles.copybutton = [];
            ud.handles.delbutton = [];
        end

        nScans      = length(planC{indexS.scan});
        if ud.currentScan > nScans
            ud.currentScan = nScans;
        end

        %Downsample colormap, redraws much faster.
        % cM = CERRColorMap(stateS.optS.doseColormap);
        cM = CERRColorMap('gray');
        ud.cM = cM;

        %         n  = size(cM, 1);
        %         newSize = 32;
        %         interval = (n-1) / 32;
        %         b = interp1(1:n, cM(:,1), 1:interval:n);
        %         c = interp1(1:n, cM(:,2), 1:interval:n);
        %         d = interp1(1:n, cM(:,3), 1:interval:n);
        %         ud.cM = [b' c' d'];

        %Setup thumbnail pane, with NxN axes.
        dx = 1/x; %pixel width in x,
        dy = 1/y; %pixel width in y, for margins.
        thumbRegion = [.52 .17 .44 .75];
        subPlotSize = ceil(sqrt(nScans));
        dh = thumbRegion(4)/subPlotSize;
        dw = thumbRegion(3)/subPlotSize;
        for i=1:subPlotSize^2
            row = subPlotSize - ceil(i/subPlotSize) + 1;
            col = mod(i-1,subPlotSize)+1;
            ud.handles.thumbaxis(i) = axes('position', [thumbRegion(1) + dw*(col-1) thumbRegion(2) + dh*(row-1) dw-dx dh-dy]);
            set(ud.handles.thumbaxis(i), 'ytick',[],'xtick',[], 'color', 'black', 'box', 'on', 'xcolor', 'white', 'ycolor', 'white');
            colormap(ud.handles.thumbaxis(i), ud.cM);
        end

        for i=1:nScans
            set(ud.handles.thumbaxis(i), 'ButtonDownFcn', ['scanManagementGui(''CHANGESCAN'', ' num2str(i) ');']);
            maxScan{i} = num2str(drawThumb(ud.handles.thumbaxis(i), planC, i, h));
            ud.previewSlice(i) = 1; %%%%%%%%%%%%%%%%%
        end

        txtLeft = .05;
        textWidth = .13;
        fieldLeft = .35;
        fieldWidth = .13;

        %Make text to describe uicontrols.
        uicontrol(h, 'units',units,'Position',[txtLeft 1-.15 textWidth rowHeight],'String', 'Scan name:', 'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor);
        uicontrol(h, 'units',units,'Position',[txtLeft 1-.21 textWidth rowHeight],'String', 'RAM Used:', 'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor);
        uicontrol(h, 'units',units,'Position',[txtLeft 1-.27 textWidth rowHeight],'String', 'Storage Method:', 'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor);
        % ESpezi MAY 2013
        uicontrol(h, 'units',units,'Position',[txtLeft 1-.33 textWidth rowHeight],'String', 'Acquisition date:', 'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor);
        uicontrol(h, 'units',units,'Position',[txtLeft 1-.39 textWidth rowHeight],'String', 'Acquisition time:', 'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor);
        % No max Scan needed like max Dose
        %         uicontrol(h, 'units',units,'Position',[txtLeft 1-.33 textWidth rowHeight],'String', 'Max Dose:', 'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor);
        %         uicontrol(h, 'units',units,'Position',[txtLeft 1-.39 textWidth rowHeight],'String', 'Units:', 'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor);

        %Make uicontrols for managing the scans, and displaying info.
        ud.handles.name          = uicontrol(h, 'units',units,'Position',[fieldLeft-fieldWidth 1-.15+.02 fieldWidth*2 rowHeight-.01],'String','', 'Style', 'edit', 'callback', 'scanManagementGui(''NAMEFIELD'');', 'userdata', i, 'horizontalAlignment', 'right');
        ud.handles.scansize      = uicontrol(h, 'units',units,'Position',[fieldLeft 1-.21 fieldWidth rowHeight],'String', '',  'Style', 'text', 'horizontalAlignment', 'right', 'BackgroundColor', frameColor);
        ud.handles.storageMethod = uicontrol(h, 'units',units,'Position',[fieldLeft-.05 1-.27 fieldWidth+.05 rowHeight],'String', '',  'Style', 'text', 'horizontalAlignment', 'right', 'BackgroundColor', frameColor);
        ud.handles.scanDate = uicontrol(h, 'units',units,'Position',[fieldLeft-.05 1-.33 fieldWidth+.05 rowHeight],'String', '',  'Style', 'text', 'horizontalAlignment', 'right', 'BackgroundColor', frameColor);
        ud.handles.scanTime = uicontrol(h, 'units',units,'Position',[fieldLeft-.05 1-.39 fieldWidth+.05 rowHeight],'String', '',  'Style', 'text', 'horizontalAlignment', 'right', 'BackgroundColor', frameColor);
        % No max Scan needed like max Dose
        %         ud.handles.maxdose       = uicontrol(h, 'units',units,'Position',[fieldLeft 1-.33+.02 fieldWidth rowHeight-.01],'String', '', 'Style', 'edit', 'callback', 'scanManagementGui(''DOSESCALE'');', 'userdata', i, 'horizontalAlignment', 'right');
        %         ud.handles.units         = uicontrol(h, 'units',units,'Position',[fieldLeft 1-.39 fieldWidth rowHeight],'String', '',  'Style', 'text', 'horizontalAlignment', 'right', 'BackgroundColor', frameColor);

        ud.handles.remotebutton  = uicontrol(h, 'units',units,'Position',[fieldLeft 1-.59 fieldWidth rowHeight],'String', 'Make Remote', 'Style', 'pushbutton', 'callback', 'scanManagementGui(''REMOTE'');', 'userdata', i);
        ud.handles.compbutton    = uicontrol(h, 'units',units,'Position',[fieldLeft 1-.67 fieldWidth rowHeight],'String', 'Compress', 'Style', 'pushbutton', 'callback', 'scanManagementGui(''COMPRESS'');', 'userdata', i);
        ud.handles.copybutton    = uicontrol(h, 'units',units,'Position',[fieldLeft 1-.75 fieldWidth rowHeight],'String','Save', 'Style', 'pushbutton', 'callback', 'scanManagementGui(''SAVE'');', 'userdata', i);
        % Scan cannot be deleted
        ud.handles.delbutton     = uicontrol(h, 'units',units,'Position',[fieldLeft 1-.83 fieldWidth rowHeight],'String','Delete', 'Style', 'pushbutton', 'callback', 'scanManagementGui(''DELETE'');', 'userdata', i);

        ud.handles.previewAxis   = axes('position', [txtLeft 1-.83 .25 .25*x/y], 'parent', h, 'box', 'on', 'ytick', [], 'xtick', [], 'buttondownfcn', 'scanManagementGui(''PREVIEWBUTTONDOWN'')');
        ud.handles.previewSliceNum = uicontrol(h, 'units',units,'Position',[fieldLeft-0.03 1-.47 fieldWidth rowHeight],'String', '',  'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor);

        text(.5, .6, 'After selecting a scan, ', 'fontsize', 8, 'hittest', 'off', 'parent', ud.handles.previewAxis, 'horizontalAlignment', 'center');
        text(.5, .5, 'click and drag mouse up', 'fontsize', 8, 'hittest', 'off', 'parent', ud.handles.previewAxis, 'horizontalAlignment', 'center');
        text(.5, .4, 'and down here to preview.', 'fontsize', 8, 'hittest', 'off', 'parent', ud.handles.previewAxis, 'horizontalAlignment', 'center');

        ud.maxScans = maxScan;
        set(h, 'userdata', ud);
        set(0, 'CurrentFigure', hFig);

        if ~isempty(maxScan)
            scanManagementGui('REFRESHFIELDS');
        end        

    case 'PREVIEWBUTTONDOWN'
        %Button clicked in the preview window.
        ud = get(h, 'userdata');
        ud.previewDown = 1;
        set(h, 'WindowButtonMotionFcn', 'scanManagementGui(''PREVIEWMOTION'')');
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
                ud.previewSlice(ud.currentScan) = ud.previewSlice(ud.currentScan)+1;%min(ud.previewSlice(ud.currentDose)+1, size(getDoseArray(ud.currentDose), 3));
                set(h, 'userdata', ud);
                scanManagementGui('refreshpreviewandfields');
            elseif ud.previewY < cp(2)
                ud.previewSlice(ud.currentScan) = ud.previewSlice(ud.currentScan)-1;%max(ud.previewSlice(ud.currentDose)-1,1);
                set(h, 'userdata', ud);
                scanManagementGui('refreshpreviewandfields');
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
        scanNum = ud.currentScan;
        bdf = get(ud.handles.previewAxis, 'buttondownfcn');
        [dA, isCompress, isRemote] = getScanArray(scanNum, planC);
        minSlice = 1;
        maxSlice = size(dA, 3);
        previewSlice = clip(ud.previewSlice(scanNum), minSlice, maxSlice, 'limits');
        ud.previewSlice(scanNum) = previewSlice;
        set(ud.handles.previewSliceNum, 'string', num2str(previewSlice));
        maxScan = str2num(ud.maxScans{scanNum});
        cLim =  [0 maxScan];
        if maxScan == 0;
            cLim = [0 1];
        end
        imagesc(dA(:,:,previewSlice), 'parent', ud.handles.previewAxis, 'hittest', 'off');
        set(ud.handles.previewAxis, 'buttondownfcn', bdf, 'box', 'on', 'ytick', [], 'xtick', [], 'CLim', cLim);
        set(h, 'userdata', ud);

        %Refresh fields as well.
        set(ud.handles.name, 'string', planC{indexS.scan}(scanNum).scanType);
        %         set(ud.handles.units, 'string', planC{indexS.scan}(scanNum).scanUnits);
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
        set(ud.handles.thumbaxis, 'xcolor', 'white', 'ycolor', 'white');
        set(ud.handles.thumbaxis(scanNum), 'xcolor', 'yellow', 'ycolor', 'yellow');

        %         set(ud.handles.maxscan, 'string', ud.maxDoses{doseNum});
        scanSize = getByteSize(planC{indexS.scan}(scanNum));
        set(ud.handles.scansize, 'string', [num2str(scanSize/(1024*1024), '%6.2f') 'MB']);
        
        % ESpezi MAY 2013
        % refresh scan date and time 
        if isfield(planC{indexS.scan}(scanNum).scanInfo(1),'DICOMHeaders')
            scanDate = '';
            if isfield(planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders,'AcquisitionDate')
                scanDate = planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders.AcquisitionDate;
            end
            if ~isempty(scanDate)
                set(ud.handles.scanDate, 'string', datestr(datenum(scanDate,'yyyymmdd'),2));
            else
                set(ud.handles.scanDate, 'string', scanDate);
            end
            scanTime = '';
            if isfield(planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders,'AcquisitionTime')
                scanTime = planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders.AcquisitionTime;
            end
            if ~isempty(scanTime)
                [token, remain] = strtok(num2str(scanTime),'.');
                if ~isempty(strfind(token,':'))
                    [~,aqTime] = strtok(datestr(datenum(token,'HH:MM:SS')));
                else
                    [~,aqTime] = strtok(datestr(datenum(token,'HHMMSS')));
                end
                set(ud.handles.scanTime, 'string', aqTime);
            else
                set(ud.handles.scanTime, 'string', scanTime);
            end
        else
            % RTOG scan
            scanDate = planC{indexS.scan}(scanNum).scanInfo(1).scanDate;
            set(ud.handles.scanDate, 'string', scanDate);
        end

    case 'CHANGESCAN'
        %New scan has been clicked on.
        ud = get(h, 'userdata');
        newScan = varargin{1};
        ud.currentScan = newScan;
        set(h, 'userdata', ud);
        scanManagementGui('refreshpreviewandfields');

    case 'NAMEFIELD'
        %Dose name has changed, update in planC.
        ud = get(h, 'userdata');
        scanNum = ud.currentScan;
        oldString = planC{indexS.scan}(scanNum).scanType;
        string = get(gcbo, 'string');
        planC{indexS.scan}(scanNum).scanType = string;
        statusString = ['Renamed scan number ' num2str(scanNum) ' from ''' oldString ''' to ''' string '''.'];
        scanManagementGui('status', statusString);

    case 'STATUS'
        %Display passed string in status bar.
        statusString = varargin{1};
        ud = get(gcbf, 'userdata');
        h = ud.handles.status;
        set(h, 'string', statusString);

    case 'COMPRESS'
        %Compress/decompress selected scan.
        ud = get(h, 'userdata');
        scanNum = ud.currentScan;
        scanName = planC{indexS.scan}(scanNum).scanType;

        if ~isCompressed(planC{indexS.scan}(scanNum).scanArray)
            statusString = ['Compressing scan number ' num2str(scanNum) ', ''' scanName ''' please wait...'];
            scanManagementGui('status', statusString);
            planC{indexS.scan}(scanNum).scanArray = compress(getScanArray(scanNum, planC));
            drawThumb(ud.handles.thumbaxis(scanNum), planC, scanNum, h);
            statusString = ['Compressed scan number ' num2str(scanNum)  ', ''' scanName '''.'];
            scanManagementGui('status', statusString);
            set(ud.handles.compbutton, 'string', 'Decompress');
        else
            statusString = ['Decompressing scan number ' num2str(scanNum) ', ''' scanName ''', please wait...'];
            scanManagementGui('status', statusString);
            %Use getScanArray and not decompress to use the cached value.
            planC{indexS.scan}(scanNum).scanArray = getScanArray(scanNum, planC);
            maxScan = drawThumb(ud.handles.thumbaxis(scanNum), planC, scanNum, h);
            %Update the maxScans value, but be sure to get a fresh ud since
            %a user could have clicked during compression.
            ud = get(h, 'userdata');
            ud.maxScans{scanNum} = num2str(maxScan);
            set(h, 'userdata', ud);
            statusString = ['Decompressed scan number ' num2str(scanNum)  ', ''' scanName '''.'];
            scanManagementGui('status', statusString);
            set(ud.handles.compbutton, 'string', 'Compress');
        end
        scanManagementGui('refreshpreviewandfields');

    case 'REMOTE'
        %Make/unmake selected dose remote.
        ud = get(h, 'userdata');
        scanNum = ud.currentScan;
        scanName = planC{indexS.scan}(scanNum).scanType;

        scanUID = planC{indexS.scan}(scanNum).scanUID;

        if isLocal(planC{indexS.scan}(scanNum).scanArray)
            statusString = ['Writing to disk scan number ' num2str(scanNum) ', ''' scanName ''' please wait...'];
            scanManagementGui('status', statusString);
            [fpath,fname] = fileparts(stateS.CERRFile);
            planC{indexS.scan}(scanNum).scanArray = setRemoteVariable(getScanArray(scanNum, planC), 'LOCAL',fullfile(fpath,[fname,'_store']),['scanArray_',scanUID,'.mat']);
            % Also make remote the scanArraySuperior and scanArrayInferior matrices
            planC{indexS.scan}(scanNum).scanArraySuperior = setRemoteVariable(getScanArraySuperior(scanNum, planC), 'LOCAL',fullfile(fpath,[fname,'_store']),['scanArraySuperior_',scanUID,'.mat']);
            planC{indexS.scan}(scanNum).scanArrayInferior = setRemoteVariable(getScanArrayInferior(scanNum, planC), 'LOCAL',fullfile(fpath,[fname,'_store']),['scanArrayInferior_',scanUID,'.mat']);
            drawThumb(ud.handles.thumbaxis(scanNum), planC, scanNum, h);
            statusString = ['Wrote to disk scan number ' num2str(scanNum)  ', ''' scanName '''.'];
            scanManagementGui('status', statusString);
            set(ud.handles.remotebutton, 'string', 'Use Memory');
            uiwait(msgbox(['scanArray stored in folder ',fullfile(fpath,[fname,'_store']),'. Note the Location'],'modal'));
        else
            statusString = ['Reading from disk scan number ' num2str(scanNum) ', ''' scanName ''', please wait...'];
            scanManagementGui('status', statusString);

            remotePath = planC{indexS.scan}(scanNum).scanArray.remotePath;
            filenam = planC{indexS.scan}(scanNum).scanArray.filename;
            stateS.reqdRemoteFiles(strcmp(fullfile(remotePath,filenam),stateS.reqdRemoteFiles)) = [];            
            
            remotePathSup = planC{indexS.scan}(scanNum).scanArraySuperior.remotePath;
            filenameSup = planC{indexS.scan}(scanNum).scanArraySuperior.filename;
            stateS.reqdRemoteFiles(strcmp(fullfile(remotePathSup,filenameSup),stateS.reqdRemoteFiles)) = [];
            
            remotePathInf = planC{indexS.scan}(scanNum).scanArrayInferior.remotePath;
            filenameInf = planC{indexS.scan}(scanNum).scanArrayInferior.filename;
            stateS.reqdRemoteFiles(strcmp(fullfile(remotePathInf,filenameInf),stateS.reqdRemoteFiles)) = [];
            
            planC{indexS.scan}(scanNum).scanArray = getScanArray(scanNum,planC);
            planC{indexS.scan}(scanNum).scanArraySuperior = getScanArraySuperior(scanNum, planC);
            planC{indexS.scan}(scanNum).scanArrayInferior = getScanArrayInferior(scanNum, planC);
            
            if ~ismember(fullfile(remotePath,filenam),stateS.reqdRemoteFiles)
                delete(fullfile(remotePath,filenam))
            end
            if ~ismember(fullfile(remotePathSup,filenameSup),stateS.reqdRemoteFiles)
                delete(fullfile(remotePathSup,filenameSup))
            end
            if ~ismember(fullfile(remotePathInf,filenameInf),stateS.reqdRemoteFiles)
                delete(fullfile(remotePathInf,filenameInf))
            end
            
            %remove remote storage directory if it is empty
            dirRemoteS = dir(remotePath);
            if ~any(~cellfun('isempty',strfind({dirRemoteS.name},'.mat')))
                rmdir(remotePath)
            end
            
            maxScan = drawThumb(ud.handles.thumbaxis(scanNum), planC, scanNum, h);
            statusString = ['Read from disk scan number ' num2str(scanNum)  ', ''' scanName '''.'];
            scanManagementGui('status', statusString);
            set(ud.handles.remotebutton, 'string', 'Use Disk');

            %Update the maxDoses value, but be sure to get a fresh ud since
            %a user could have clicked during remote writing to disk.
            ud = get(h, 'userdata');
            ud.maxScans{scanNum} = num2str(maxScan);
            set(h, 'userdata', ud);
        end
        scanManagementGui('refreshpreviewandfields');

    case 'SAVE'
        %Open dialog to save dose array as .mat file.
        ud = get(h, 'userdata');
        scanNum = ud.currentScan;
        scanName = planC{indexS.scan}(scanNum).scanType;
        [filename, pathname] = uiputfile('*.mat', ['Save (uncompressed) scan array number ' num2str(scanNum) ' as:']);
        if filename==0
            return;
        end
        scan3D = getScanArray(scanNum, planC);
        save(fullfile(pathname, filename), 'scan3D');
        statusString = ['Saved scan number ' num2str(scanNum) ', ''' scanName ''' to ' [filename '.mat'] '.'];
        scanManagementGui('status', statusString);

    case 'DELETE'
        %Delete selected scan.  If being displayed, verify deletion with user.
        ud = get(h, 'userdata');
        scanNum = ud.currentScan;
        scanName = planC{indexS.scan}(scanNum).scanType;

        refreshViewer = 0;
        axesV = checkDisplayedScans(scanNum);
        if ~isempty(axesV)
            choice = questdlg('One or more CERR axes are currently displaying this scan.  If you delete it, these axes will be set to display no scan.  Proceed?', 'Continue?', 'Continue', 'Abort', 'Continue');
            if strcmpi(choice, 'Abort')
                statusString = ['Delete aborted.'];
                scanManagementGui('status', statusString);
                return;
            else
                %Set the axes scan value to null.
                setAxisScanToNull(axesV);
            end
        end

        if stateS.scanSet == scanNum
            stateS.scanSet = 1;
        end
        del = questdlg(['Are you sure you want to delete scan number' num2str(scanNum) ', ''' scanName ''' and the associated structures?'], 'Continue?', 'Continue', 'Abort', 'Continue');
        if strcmpi(del, 'Continue')
            statusString = ['Deleted scan number ' num2str(scanNum) ', ''' scanName '''.'];
            scanManagementGui('status', statusString);
            %Delete the structures associated with this scan
            assocScanV = getStructureAssociatedScan(1:length(planC{indexS.structures}), planC);
            structToDelete = find(assocScanV == scanNum);
            planC{indexS.structures}(structToDelete) = [];
            %Delete structureArray
            %indAssoc = find(strcmpi({planC{indexS.structureArray}.assocScanUID},planC{indexS.scan}(scanNum).scanUID));
            %planC{indexS.structureArray}(indAssoc) = [];
            if ~isempty(structToDelete)
                planC{indexS.structureArray}(scanNum) = [];
            end
            stateS.structsChanged = 1;
            %Update doses associated with this scan            
            while ~isempty(find(strcmpi({planC{indexS.dose}.assocScanUID},planC{indexS.scan}(scanNum).scanUID)))
                indAssoc = find(strcmpi({planC{indexS.dose}.assocScanUID},planC{indexS.scan}(scanNum).scanUID));
                n = indAssoc(1);
                transM = getTransM(planC{indexS.dose}(n),planC);
                planC{indexS.dose}(n).assocScanUID = [];
                planC{indexS.dose}(n).transM = transM;                
            end
            %Delete the scan
            planC{indexS.scan}(scanNum) = [];      
            stateS.structSet = [];
            
            %If scan below displayed scan deleted, its number has changed.
            if scanNum < stateS.scanSet
                stateS.scanSet = stateS.scanSet - 1;
                stateS.structSet = stateS.scanSet;
            end
            refreshViewer = 1;
            updateAxesForDeletedScan(scanNum);
            scanManagementGui;
        else
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

        maxScan = max(dA(:));
        if maxScan == 0
            set(gcbo, 'string', '0')
            statusString = ['Unable to rescale all zero dose distribution.'];
            scanManagementGui('status', statusString);
            return;
        end

        if isCompress | isRemote
            statusString = ['Rescaling compressed or remote dose can take a moment, please wait...'];
            scanManagementGui('status', statusString);
        end

        %Perform the rescale.
        dA = dA *  (1/maxDose * newMaxDose);

        planC = setDoseArray(doseNum, dA, planC);
        statusString = ['Rescaled dose number ' num2str(doseNum) ', ''' doseName ''' from [0 ' num2str(maxDose) '] Gy to [0 ' num2str(newMaxDose) '] Gy.'];
        ud.maxDoses{doseNum} = num2str(newMaxDose);
        set(h, 'userdata', ud);
        scanManagementGui('status', statusString);

    case 'QUIT'
        close;
end

function nBytes = getByteSize(data)
%"getByteSize"
%Returns the number of bytes in the passed data
infoStruct = whos('data');
nBytes = infoStruct.bytes;

function maxScan = drawThumb(hAxis, planC, index, hFigure)
%"drawThumb"
%In passed dose array, find slice with highest dose and draw in hAxis.
%Also denote the index in the corner.  If compressed show compressed.
set(hFigure, 'CurrentAxes', hAxis);
toDelete = get(hAxis, 'children');
delete(toDelete);

%Get the dose array and its compression state.
[dA, isCompress, isRemote] = getScanArray(index, planC);

bdf = get(hAxis, 'buttondownfcn');

maxScan = arrayMax(dA);
% 	maxLoc = find(dA == maxScan);
% 	[r,c,s] = ind2sub(size(dA), maxLoc(1));
% set the scan to median of z-values
indexS = planC{end};
[xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(index));
s = ceil(median(1:length(zV)));
thumbImage = dA(:,:,s(1));
imagesc(thumbImage, 'hittest', 'off', 'parent', hAxis);
set(hAxis, 'ytick',[],'xtick',[]);

if isCompress & isRemote
    text(.1, .1, 'Compressed', 'units', 'normalized', 'fontsize', 8, 'color', 'white', 'horizontalAlignment', 'left', 'hittest', 'off', 'parent', hAxis);
    text(.1, .2, 'Remote', 'units', 'normalized', 'fontsize', 8, 'color', 'white', 'horizontalAlignment', 'left', 'hittest', 'off', 'parent', hAxis);
elseif isRemote
    text(.1, .1, 'Remote', 'units', 'normalized', 'fontsize', 8, 'color', 'white', 'horizontalAlignment', 'left', 'hittest', 'off', 'parent', hAxis);
elseif isCompress
    text(.1, .1, 'Compressed', 'units', 'normalized', 'fontsize', 8, 'color', 'white', 'horizontalAlignment', 'left', 'hittest', 'off', 'parent', hAxis);
end

xLim = get(hAxis, 'xlim');
yLim = get(hAxis, 'ylim');
x = (xLim(2) - xLim(1)) * .87 + xLim(1);
y = (yLim(2) - yLim(1)) * .15 + yLim(1);
text(x, y, num2str(index), 'fontsize', 8, 'color', 'white', 'hittest', 'off', 'parent', hAxis);
set(hAxis, 'buttondownfcn', bdf);
axis ij;
drawnow;
set(hAxis,'xcolor', 'white', 'ycolor', 'white')


function [nAxesV] = checkDisplayedScans(scanNum)
%"checkDisplayedDoses"
%   Check to see if any CERR axes are displaying the requested dose num.
%   Returns the numbers of any axes that are.

global stateS
nAxesV = [];

%Iterate over axes.
for i=1:length(stateS.handle.CERRAxis)
    %Get axis info for this axis.
    %aI = get(stateS.handle.CERRAxis(i), 'userdata');
    aI = stateS.handle.aI(i);
    if ismember(scanNum, aI.scanSets)
        nAxesV = union(nAxesV, i);
    end
end

function setAxisScanToNull(nAxesV)
%"setAxisDoseToNull"
%   Sets the passed axis number's userdata doseSet fields to null if they
%   were using 'manual'.

global stateS

%Iterate over axes.
for i=1:length(nAxesV)
    %Get axis info for this axis.
    aI = get(stateS.handle.CERRAxis(nAxesV(i)), 'userdata');
    if strcmpi(aI.scanSelectMode, 'manual');
        aI.scanSets = [];
        set(stateS.handle.CERRAxis(nAxesV(i)), 'userdata', aI);
    end
end

function updateAxesForDeletedScan(delIndex)
%"updateAxesForDeletedDose"
%   Shifts all doseNums being displayed in CERR axes to account for deleted
%   dose distributions, given the number of the deleted dose.

global stateS

%Iterate over axes.
for i=1:length(stateS.handle.CERRAxis)
    
    %Get axis info for this axis.
    %aI = get(stateS.handle.CERRAxis(i), 'userdata');
    aI = stateS.handle.aI(i);
    if ~isempty(aI.scanObj)
        scanSets = aI.scanObj.scanSet;
        aI.scanObj.scanSet = 1; %max(1,scanSets(scanSets >= delIndex)- 1);
        %set(stateS.handle.CERRAxis(i), 'userdata', aI);
        stateS.handle.aI(i) = aI;
    end    
end
