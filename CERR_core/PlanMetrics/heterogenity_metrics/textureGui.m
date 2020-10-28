function textureGui(command, varargin)
%"textureGui" GUI
%   Create a GUI to manage texture calculation.
%
%   APA 09/29/2015
%   AI  20/03/18   Display parameters by feature type
%   AI  27/03/18   Added wavelets,sobel,loG,first order statistic features
%   AI  04/02/18   Modified to handle parameter sub-types
%   AI  04/02/18   Updated for compatibility with processImage.m
%Usage:
%   textureGui()
%  based on textureGui.m
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
global planC stateS bridge sInfo
indexS = planC{end};

if isempty(bridge)
    try
        bridge = evalin('caller','bridge');
        sInfo = evalin('caller','arr_info');
    catch
        bridge = NaN;
        sInfo = NaN;
    end
end

%Use a static window size, by pixels.  Do not allow resizing.
screenSize = get(0,'ScreenSize');
y = 650;
x = 1000;
units = 'normalized';

%Height of a single row of text.
rowHeight = .06;

%If no command given, default to init.
if ~exist('command','var') || (exist('command','var') && isempty(command))
    command = 'init';
end

%Find handle of the gui figure.
h = findobj('tag', 'textureGui');

%Set framecolor for uicontrols and pseudoframes.
frameColor = [0.8314 0.8157 0.7843];

switch upper(command)
    case 'INIT'
        %If gui doesnt exist, create it, else refresh it.
        if isempty(h)
            %Set up a new GUI window.
            h = figure('doublebuffer', 'on', 'units', 'pixels', ...
                'position',[(screenSize(3)-x)/2 (screenSize(4)-y)/2 x y],...
                'MenuBar', 'none', 'NumberTitle', 'off', 'resize', 'off',...
                'Tag', 'textureGui', 'Color', [.75 .75 .75],...
                'WindowButtonUpFcn', 'textureGui(''FIGUREBUTTONUP'')');
            
            stateS.handle.textureManagementFig = h;
            set(h, 'Name','Texture Browser');


            %Create pseudo frames.
            axes('Position', [.02 .05 + (rowHeight + .02) .96 .87 - (rowHeight + .02)/2],...
                'color', frameColor, 'ytick',[],'xtick',[], 'box', 'on');
            line([.5 .5], [0 1], 'color', 'black');
            
            axes('Position', [.18 .06 .32 rowHeight-0.02],...
                'color', frameColor, 'ytick',[],'xtick',[], 'box', 'on');
            ud.wb.handles.wbAxis = axes('units', units, 'Position',...
                [.18 .06 .32 rowHeight-0.02], 'color', [.9 .9 .9],...
                'ytick',[],'xtick',[], 'box', 'on', 'xlimmode', 'manual',...
                'ylimmode', 'manual', 'parent', h);
            ud.wb.handles.patch = patch([0 0 0 0], [0 1 1 0], [0.1 0.9 0.1],...
                'parent', ud.wb.handles.wbAxis);
%             ud.wb.handles.percent = text(.5, .45, '', 'parent', ud.wb.handles.wbAxis, 'horizontalAlignment', 'center');
%             ud.wb.handles.text = uicontrol(h, 'style', 'text', 'units', units, 'position', [wbX+50 wbY+wbH - 21 wbW-100 15], 'string', '');

            % Initialize current scan
            ud.currentScan = 0;
            
            % Set cm vs voxels flag
            ud.cmFlag = 0;
            
            % Delta y,x,z for scan grid
            ud.dXYZ = [];
            
            % Get the default texture
            if isempty(planC{indexS.texture});
                ud.currentTexture = 0;
            else
                ud.currentTexture = 1;
            end
            ud.textureBlock = 1;
            set(h, 'userdata', ud);
        end
        textureGui('refresh', h);
        figure(h);

    case 'REFRESHFIELDS'
        %Refresh the field list for the current scan.
        ud = get(h, 'userdata');
        textureNum = ud.currentTexture;
        
        % Default texture parameters
        scanNum = 1;
        structNum = 0; 
        featureNum = 1;
                
        texturesC = {planC{indexS.texture}(:).description};        
        % Populate values from an existing texture
        if textureNum > 0
            set(ud.handles.texture, 'Value', textureNum);
            %set(ud.handles.texture, 'String', texturesC{textureNum});
            scanUID       = planC{indexS.texture}(textureNum).assocScanUID;
            scanNum       = getAssociatedScan(scanUID);
            structureUID  = planC{indexS.texture}(textureNum).assocStructUID;
            if isempty(structureUID)
                structNum = 0; %Entire scan
            else
                structNum     = getAssociatedStr(structureUID);
            end
            category      = planC{indexS.texture}(textureNum).category;
            featC = get(ud.handles.featureType,'String');
            featureNum = find(strcmp(featC,category));
            
            set(ud.handles.description,'string',texturesC{textureNum},'Enable','On');
        end
        
        set(ud.handles.scan, 'value', scanNum,'Enable','On');
        set(ud.handles.structure, 'value',structNum+1,'Enable','On');

        
        set(ud.handles.featureType,'value',featureNum, 'Enable','On');
        scanTypeC = [{'Select texture'}, planC{indexS.scan}.scanType];
        set(ud.handles.selectTextureMapsForMIM,'string',scanTypeC,...
            'value',1)
        
        set(h, 'userdata', ud);
        
%         if ~isempty(ud.currentTexture) && ud.currentTexture>0
%             textureGui('FEATURE_TYPE_SELECTED');
%         end
        
        
            
    case 'REFRESH'
        %Recreate and redraw the entire textureGui.
        if isempty(h)
            return;
        end

        %Save the current figure so focus can be returned.
        hFig = gcf;

        %Focus on textureGui for the moment.
        set(0, 'CurrentFigure', h);
        ud = get(h, 'userdata');
        if isfield(ud,'handles')            
            fieldNamC = fieldnames(ud.handles);
            for i = 1:length(fieldNamC)
                %--temp---
                if isfield(stateS.handle,fieldNamC{i})
                delete(stateS.handle.(fieldNamC{i}))
                stateS.handle.(fieldNamC{i}) = [];
                end
                %--temp---
            end            
        else
            % disp('No handles to delete')
        end
        
        % List of scans
        nScans   = length(planC{indexS.scan});
        scansC = cell(1,nScans);
        for i = 1:nScans
            scansC{i} = [num2str(i), '.', planC{indexS.scan}(i).scanType];
        end
        
        % List of Structures
        nStructs  = length(planC{indexS.structures});
        structsC = cell(1,nStructs+1);
        %structsC{1} = 'None (entire scan)'; 
        structsC{1} = 'Entire scan';  %For radiomics paper
        for i = 1:nStructs
            structsC{i+1} = [num2str(i), '.', planC{indexS.structures}(i).structureName];
        end
         
         
        % List of feature types
        featureTypeC = {'Select',...
            'Haralick Cooccurance',...
            'Laws Convolution',...
            'Laws Energy',...
            'Mean',...
            'First Order Statistics',...
            'Wavelets',...
            'Gabor',...
            'LoG',...
            'Sobel', ...
            'CoLlage'}; 
        
        %Downsample colormap, redraws much faster.
        % cM = CERRColorMap(stateS.optS.doseColormap);
        cM = CERRColorMap('weather');
        ud.cM = cM;
        
        %Setup thumbnail pane, with NxN axes.
        dx = 1/x; %pixel width in x,
        dy = 1/y; %pixel width in y, for margins.
        thumbRegion = [.52 .27 .44 .65];
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
       
        txtLeft = .05;
        textWidth = .2; 
        fieldLeft = .27;
        fieldWidth = .20;
        
        %Make text to describe uicontrols.
        uicontrol(h, 'units',units,'Position',[txtLeft 1-.12 textWidth rowHeight-0.02],...
            'String', 'Texture:', 'Style', 'text', 'horizontalAlignment', 'left',...
            'BackgroundColor', frameColor, 'fontSize',12,'fontWeight','Bold');
        uicontrol(h, 'units',units,'Position',[txtLeft 1-.20 textWidth rowHeight],...
            'String', 'Description:', 'Style', 'text', 'horizontalAlignment',...
            'left', 'BackgroundColor',frameColor,'fontSize',10);
        uicontrol(h, 'units',units,'Position',[txtLeft 1-.27 textWidth rowHeight],...
            'String', 'Scan:', 'Style', 'text', 'horizontalAlignment',...
            'left', 'BackgroundColor',frameColor,'fontSize',10);
        uicontrol(h, 'units',units,'Position',[txtLeft 1-.34 textWidth rowHeight],...
            'String', 'Structure:', 'Style', 'text', 'horizontalAlignment',...
            'left', 'BackgroundColor',frameColor,'fontSize',10);
        uicontrol(h, 'units',units,'Position',[txtLeft 1-.41 textWidth rowHeight],...
            'String', 'Category:', 'Style', 'text', 'horizontalAlignment',...
            'left', 'BackgroundColor',frameColor,'fontSize',10);
        uicontrol(h, 'units',units,'Position',[txtLeft 1-.47 2*textWidth rowHeight],...
            'String', 'Parameters:', 'Style', 'text','fontSize',12,'fontWeight','Bold',...
            'horizontalAlignment', 'left', 'BackgroundColor', frameColor);

        
        %Make uicontrols for managing the scans, and displaying info.
        structNum = 0; %default (none)
        if isfield(ud.handles,'description')
           desc = get(ud.handles.description,'String');
        else
           desc = ''; %Default
        end
        
        if length(planC{indexS.texture})>0
        texListC = strcat('Texture',cellfun(@num2str,num2cell(1:length(planC{indexS.texture})),'un',0));
        else
        texListC = {'   Click ''+'' to create  '};
        end
        ud.handles.texture       = uicontrol(h, 'units',units,'Position',[fieldLeft-0.14 1-.12 fieldWidth+0.08 rowHeight-.015],'String',texListC, 'Style', 'popup', 'callback', 'textureGui(''TEXTURE_SELECTED'');', 'enable', 'on', 'horizontalAlignment', 'right','fontSize',10);
        ud.handles.textureAdd    = uicontrol(h, 'units',units,'Position',[2*fieldLeft-0.12 1-.12 0.03 rowHeight-.01],'String','+', 'Style', 'push', 'callback', 'textureGui(''CREATE_NEW_TEXTURE'');', 'horizontalAlignment', 'right','enable','on','fontSize',10);
        ud.handles.textureDel    = uicontrol(h, 'units',units,'Position',[2*fieldLeft-0.08 1-.12 0.03 rowHeight-.01],'String','-', 'Style', 'push', 'callback', 'textureGui(''DELETE_TEXTURE'');', 'horizontalAlignment', 'right','enable','on','fontSize',10);
        ud.handles.description   = uicontrol(h, 'units',units,'Position',...
            [fieldLeft-.05 1-.18 fieldWidth+0.05 rowHeight-0.02],'String', desc,...
            'Style', 'edit', 'horizontalAlignment', 'left', 'BackgroundColor',...
            'w','enable','off','callback',{@updateLabel,h},'fontSize',10);
        ud.handles.scan          = uicontrol(h, 'units',units,'Position',...
            [fieldLeft-.05 1-.26 fieldWidth+0.05 rowHeight],'String', scansC,...
            'value', 1,  'Style', 'popup', 'horizontalAlignment', 'right',...
            'BackgroundColor', 'w','callback', 'textureGui(''SCAN_SELECTED'');',...
            'enable','off','fontSize',10);
        ud.handles.structure     = uicontrol(h, 'units',units,'Position',...
            [fieldLeft-.05 1-.33 fieldWidth+.05 rowHeight],'String', structsC,...
            'value', 1, 'Style', 'popup', 'horizontalAlignment', 'right',...
            'BackgroundColor', 'w','callback', 'textureGui(''STRUCT_SELECTED'');',...
            'enable','off','fontSize',10);

        ud.handles.featureType   = uicontrol(h, 'units',units,'Position',...
            [fieldLeft-.05 1-.4 fieldWidth+.05 rowHeight],'String', featureTypeC,...
            'value', 1, 'Style', 'popup', 'callback',...
            'textureGui(''FEATURE_TYPE_SELECTED'');', 'horizontalAlignment',...
            'right', 'BackgroundColor', 'w', 'enable','off','fontSize',10);
        
        scanNum = get(ud.handles.scan,'value');
        voxSizV = getScanXYZSpacing(scanNum,planC);
        ud.dXYZ = voxSizV;
        
        % uicontrols to generate or delete texture maps
        ud.handles.createTextureMaps  = uicontrol(h, 'units',units,'Position',[0.03 1-.95 0.12 rowHeight],'String', 'Create Maps', 'Style', 'pushbutton', 'callback', 'textureGui(''CREATE_MAPS'');');
        
        % uicontrols to write texture maps to MIM
        ud.handles.selectTextureMapsForMIM  = uicontrol(h, 'units',units,'Position',...
            [.53 .06 .3 rowHeight-0.02],'String', {'Select Texture'}, 'Style',...
            'popupmenu', 'value',1, 'callback', 'textureGui(''SELECT_MAPS_FOR_MIM'');');
        
        ud.handles.sendTextureMapsToMIM  = uicontrol(h, 'units',units,'Position',...
            [.85 .06 .12 rowHeight-0.02],'String', 'Send to MIM', 'Style',...
            'pushbutton', 'callback', 'textureGui(''SEND_MAPS_TO_MIM'');');
        
        %Set default structNum
        if ~isfield(ud,'structNum') || isempty(ud.structNum)
            ud.structNum = 0;
        end
        
        set(h, 'userdata', ud);
        set(0, 'CurrentFigure', hFig);

        if ~isempty(ud.currentTexture) && ud.currentTexture>0
            textureGui('REFRESHFIELDS');
            textureGui('SCAN_SELECTED');
            textureGui('REFRESH_THUMBS');
        end
        textureGui('SCAN_SELECTED');
        
    case 'SCAN_SELECTED'
        ud = get(h, 'userdata');
        scanNum = get(ud.handles.scan,'value');
        % Find structures associated with this scanNum
        numStructs = length(planC{indexS.structures});
        allStrV = 1:numStructs;
        scanNumV = getStructureAssociatedScan(allStrV,planC);
        matchV = scanNumV == scanNum;
        strNameC = {planC{indexS.structures}(matchV).structureName};
        structNumV = find(matchV);
        strNameC = strcat(cellfun(@num2str,num2cell(structNumV),...
            'UniformOutput',false),{'. '},strNameC);
        strNameC = [{'0. Entire Scan'},strNameC];
        set(ud.handles.structure,'string',strNameC,'value',1)
        ud.structNumV   = [0,structNumV];
        set(h, 'userdata', ud);
        
        
    case 'STRUCT_SELECTED'
        ud = get(h, 'userdata');
        % structNum = get(ud.handles.structure,'value')-1;
        ud.structNum = ud.structNumV(get(ud.handles.structure,'value'));
        scanNum = get(ud.handles.scan,'value');
        voxSizV = getScanXYZSpacing(scanNum,planC);
        ud.dXYZ = voxSizV;
        set(h, 'userdata', ud);
       
    case 'PATCH_CM_SELECTED'
        ud = get(h, 'userdata');
        cmFlag = get(ud.handles.patchCm, 'value');
        if ~ud.cmFlag && cmFlag
            patchSizeStr = '';
            patchSizeVx = str2num(get(ud.handles.patchSize, 'String'));
            patchSizeCm = patchSizeVx .* ud.dXYZ;
            for i = 1:length(patchSizeCm)
                patchSizeStr = [patchSizeStr,  sprintf('%.2f',patchSizeCm(i)), ','];
            end
            set(ud.handles.patchSize, 'String',patchSizeStr(1:end-1));            
        end        
        if ud.cmFlag && ~cmFlag
            set(ud.handles.patchCm, 'value', 1);
            ud.cmFlag = 1;
            cmFlag = 1;
        end
        if cmFlag
            set(ud.handles.patchVx, 'value', 0);
            ud.cmFlag = 1;
        end
                
        set(h, 'userdata', ud);
        
    case 'PATCH_VOX_SELECTED'
        ud = get(h, 'userdata');
        voxFlag = get(ud.handles.patchVx, 'value');
        if ud.cmFlag && voxFlag
            patchSizeStr = '';
            patchSizeCm = str2num(get(ud.handles.patchSize, 'String'));
            patchSizeVx = floor(patchSizeCm ./ ud.dXYZ);
            for i = 1:length(patchSizeVx)
                patchSizeStr = [patchSizeStr, sprintf('%.2f',patchSizeVx(i)), ','];
            end
            set(ud.handles.patchSize, 'String',patchSizeStr(1:end-1));                        
        end
        if ~ud.cmFlag && ~voxFlag
            set(ud.handles.patchVx, 'value', 1);
            ud.cmFlag = 0;
            voxFlag = 1;
        end
        if voxFlag
            set(ud.handles.patchCm, 'value', 0);
            ud.cmFlag = 0;
        end
        
        set(h, 'userdata', ud);
        
    case 'TEXTURE_SELECTED'  %View previously created tex parameters & thumbnails
        ud = get(h, 'userdata');
        strC = get(gcbo,'String');
        if length(strC) == 1 && strcmpi(strC{1},'')
            return;
        end
        %Update description
        ud.currentTexture = get(ud.handles.texture,'value');
        texC = get(ud.handles.texture,'String');
        if iscell(texC)
         set(ud.handles.description,'string',texC{ud.currentTexture});
        else
         set(ud.handles.description,'string',texC);
        end
        %Update assoc. structure name
        assocStructUID = {planC{indexS.texture}(ud.currentTexture).assocStructUID};
        strIdx = getAssociatedStr(assocStructUID);
        if isempty(strIdx)
            set(ud.handles.structure,'Value',1); %entire scan
        else
            set(ud.handles.structure,'Value',strIdx);
        end
        set(h, 'userdata', ud);
        %Update displayed parameters
        paramS = planC{indexS.texture}(ud.currentTexture).parameters;
        fType = planC{indexS.texture}(ud.currentTexture).category;
        textureGui('FEATURE_TYPE_SELECTED',paramS,fType);
        textureGui('REFRESHFIELDS');
        textureGui('REFRESH_THUMBS');
        %textureGui('REFRESH');
        
    case 'FEATURE_TYPE_SELECTED'  %Callback to categories
        
        ud = get(h, 'userdata');
        
      
        %Clear any previous parameter controls
        if isfield(ud.handles,'paramControls')
        hPar = ud.handles.paramControls;
        hPar.delete;
        end
        ud.handles.paramControls = gobjects(0);    
        
 
        %Get list of parameters, types & default values for display
        set(h, 'userdata',ud);
        scanNum = get(ud.handles.scan,'value');
        featH = ud.handles.featureType;
        featureIdx = get(featH, 'value');
        
        if isempty(featureIdx)
            featureType = varargin{2};
        else
            featListC = get(featH,'string');
            featureType = featListC{featureIdx};
            %featureType = strrep(featureType,' ','');
            paramS = [];
        end
        startPosV = get(featH,'position');
        delPos = .055;
        
        
        if nargin== 1 %List parameters for new texture map
        switch featureType
            case 'Haralick Cooccurance' 
                
                paramC = {'Type','PatchSize','PatchType','Directionality','NumLevels'};
                typeC = {'popup','edit' ,'popup','popup','edit'};
                valC = {{'All','Entropy','Energy','Sum Avg','Correlation',...
                    'Homogeneity','Contrast','Cluster Shade',...
                    'Cluster Promincence', 'Haralick Correlation'},...
                    {'2,2,2'},{'voxels','cm'},...
                    {'Co-occurance with 13 directions in 3D',...
                    'Left-Right, Ant-Post and Diagonals in 2D', ...
                    'Left-Right and Ant-Post', ...
                    'Left-Right',...
                    'Anterior-Posterior',...
                    'Superior-Inferior'},...
                    {'16'}};
                dispC = {'On','On','On','On','On'};
                
            case 'Laws Convolution' % Laws 
                paramC = {'PadMethod','PadSize','Direction','Type','Normalize'};
                typeC = {'popup','edit','popup','edit','popup'};
                valC = {{'expand','padzeros','periodic','nearest',...
                    'mirror','none'},{'2,2,2'},{'2D','3D', 'All'},...
                    {'E5L5S5'},{'Yes','No'}};
                dispC = {'On','On','On','On','On'};
                
            case 'Laws Energy' %Laws energy
                paramC = {'PadMethod','PadSize','Direction','Type',...
                          'KernelSize','Normalize'};
                typeC = {'popup','edit','popup','edit','edit','popup'};
                valC = {{'expand','padzeros','periodic','nearest',...
                    'mirror','none'},{'2,2,2'},{'2D','3D', 'All'},...
                    {'E5L5S5'},'5,5,5',{'Yes','No'}};
                dispC = {'On','On','On','On','On', 'On'};
                
            case 'Mean' % Local mean filter
                paramC = {'PadMethod', 'PadSize','KernelSize'};
                typeC = {'popup','edit','edit'};
                valC = {{'expand','padzeros','periodic','nearest',...
                    'mirror','none'},{'5,5,5'},{'3,3,3'}};
                dispC = {'On','On','On'};
                
            case 'First Order Statistics' %First-order statistics
                paramC = {'PatchSize','VoxelSize_mm'};
                typeC = {'edit','edit'};
                voxSizeV = getScanXYZSpacing(scanNum,planC);
                voxSizeV = voxSizeV.*10; % convert cm to mm
                valC = {'3,3,3',voxSizeV};
                dispC = {'On','Off'};
                

            case 'Wavelets'
                paramC = {'PadMethod','PadSize','Normalize','Direction',...
                    'Wavelets','Index'};
                typeC = {'popup','edit','popup','popup','popup','popup'};
                valC = {{'expand','padzeros','periodic','nearest',...
                    'mirror','none'},{'5,5,5'},{'Yes','No'},{'All','HHH',...
                    'LHH','HLH','HHL','LLH','LHL','HLL','LLL'},...
                    {'Daubechies','Haar','Coiflets','FejerKorovkin','Symlets',...
                    'Discrete Meyer wavelet','Biorthogonal','Reverse Biorthogonal'},...
                    @getSubParameter};
                dispC = {'On','On','On','On','On','On','Off'};
                subTypeC = {{'Index','Wavelets'}};
                
            case 'Gabor'
                paramC = {'PadMethod','PadSize','Radius','Sigma',...
                    'AspectRatio','Orientation','Wavlength'};
                typeC = {'popup','edit','edit','edit','edit','edit','edit'};
                valC = {{'expand','padzeros','periodic','nearest',...
                    'mirror','none'},{'5,5,5'},3,.5,1,30,1};
                dispC = {'On','On','On','On','On','On','On'};
                
                
            case 'LoG'
                paramC = {'PadMethod','PadSize','Sigma_mm','VoxelSize_mm'};
                typeC = {'popup','edit','edit','edit'};
                
                voxSizeV = getScanXYZSpacing(scanNum,planC);
                voxSizeV = voxSizeV.*10; % convert cm to mm
                valC = {{'expand','padzeros','periodic','nearest',...
                    'mirror','none'},{'5,5,5'},.5,voxSizeV};
                dispC = {'On','On','On','off'};

            case 'Sobel'
                paramC = {'PadMethod', 'PadSize'};
                typeC = {'popup','edit'};
                valC = {{'expand','padzeros','periodic','nearest',...
                    'mirror','none'},{'5,5,5'}};
                dispC = {'On','On','off','On'};

                
            case 'CoLlage'
                paramC = {'Dimension','Dominant_Dir_Radius','Cooccur_Radius','Number_Gray_Levels'};
                typeC = {'popup','edit','edit','edit'};
                valC = {{'2d','3d'},'3 3 0','3 3 0',64};
                dispC = {'On','On','On','On'};
                
                
        end
        
        %Display parameters
        if isempty(paramC)
            paramS = [];
        else
            for n = 1:length(paramC)
                if isa(valC{n},'function_handle')
                fn = valC{n};
                val = fn(featureType, paramS.(paramC{n-1}).val);
                paramS = addParam(paramS,paramC{n},typeC{n},val,...
                    dispC{n},startPosV(2)-(n+1)*delPos,h);
                else
                paramS = addParam(paramS,paramC{n},typeC{n},valC{n},...
                    dispC{n},startPosV(2)-(n+1)*delPos,h);
                end
            end
        end
        
        else %Display parameters for previously-created map
            paramS = varargin{1};
            if ~isempty(paramS)
            featureType = varargin{2};
            featureType = strrep(featureType,' ','');
            paramC = fieldnames(paramS);
            for n = 1:length(paramC)
                val = paramS.(paramC{n}).val;
                if numel(val)>1
                    val = num2str(val);
                end
                paramS = addParam(paramS,paramC{n},paramS.(paramC{n}).type,...
                val,paramS.(paramC{n}).disp,startPosV(2)-(n+1)*delPos,h);
            end
            end
        end
        
        if exist('subTypeC','var')
            for n = 1:length(subTypeC)
            pairC = subTypeC{n};
            paramS.(pairC{2}).subType = pairC{1};
            end
        end
        
        ud = get(h, 'userdata');
        ud.parameters = paramS;
        ud.filtType = featureType;
        set(h,'userdata',ud);
        
        % re-Populate field values
       % textureGui('REFRESHFIELDS');  
        
    case 'PREV_BLOCK'
        ud = get(h, 'userdata');
        if ud.textureBlock == 1
            return;
        end
        ud.textureBlock = ud.textureBlock - 1;   
        set(h, 'userdata', ud);
        textureGui('REFRESH_THUMBS')        
        
    case 'NEXT_BLOCK'
        ud = get(h, 'userdata');
        nScans = length(planC{indexS.dose});
        maxDoseBlocks = ceil(nScans/9);
        if ud.textureBlock == maxDoseBlocks
            return;
        end
        ud.textureBlock = ud.textureBlock + 1;
        set(h, 'userdata', ud);
        textureGui('REFRESH_THUMBS')
        
    case 'REFRESH_THUMBS'
        
        ud = get(h, 'userdata');
        if isfield(ud.handles,'thumbaxis')
            try %To handle double-clicks on next and previous buttons
                delete(ud.handles.thumbaxis);
            catch
                %return
            end
        end
        
        % Get Scans associated with this texture
        textureC = {planC{indexS.scan}.assocTextureUID};
        if ud.currentTexture == 0
            scansV = [];
            scanIndV = [];
            nTex = 0;
            nScans = 0;
        else
            texIdx = strcmp(textureC,planC{indexS.texture}(ud.currentTexture).textureUID);
            scanIndV = find(texIdx);
            if isempty(scanIndV)
                ud.currentScan = 0;
                nTex = 0;
                nScans = 0;
            else
                ud.currentScan = scanIndV(1);
                nTex = sum(texIdx);
                nScans = length(planC{indexS.scan});
            end
        end
        
        scansV = (ud.textureBlock-1)*9+1:min(nScans,ud.textureBlock*9);
        
        if ud.currentScan > max(scanIndV)
            ud.currentScan = scanIndV(1);
        elseif ud.currentScan < min(scanIndV)
            ud.currentScan = scanIndV(1);
        end        

        %Downsample colormap, redraws much faster.
        %cM = CERRColorMap(stateS.optS.CTColormap);
        cM = CERRColorMap('weather');
        n  = size(cM, 1);
        newSize = 32;
        interval = (n-1) / newSize;
        b = interp1(1:n, cM(:,1), 1:interval:n);
        c = interp1(1:n, cM(:,2), 1:interval:n);
        d = interp1(1:n, cM(:,3), 1:interval:n);
        ud.cM = [b' c' d'];
        
        %Setup thumbnail pane, with NxN axes.
        dx = 1/x; %pixel width in x,
        dy = 1/y; %pixel width in y, for margins.
        %thumbRegion = [.52 .17 .44 .75];
        thumbRegion = [.52 .23 .44 .70];
        subPlotSize = max(1,ceil(sqrt(nTex)));
        dh = thumbRegion(4)/subPlotSize;
        dw = thumbRegion(3)/subPlotSize;
        ud.handles.thumbaxis = gobjects(0);
        
        for i = 1:subPlotSize^2
            row = subPlotSize - ceil(i/subPlotSize) + 1;
            col = mod(i-1,subPlotSize)+1;
            ud.handles.thumbaxis(i) = axes('position', [thumbRegion(1) + dw*(col-1) thumbRegion(2) + dh*(row-1) dw-dx dh-dy], 'box', 'on', 'parent', h);
            set(ud.handles.thumbaxis(i), 'ytick',[],'xtick',[], 'color', 'black');
            colormap(ud.handles.thumbaxis(i), ud.cM);
        end

        maxDose = [];
        for i=1:nTex
            %set(ud.handles.thumbaxis(i), 'ButtonDownFcn', ['textureGui(''CHANGEDOSE'', ' num2str(scanIndV(i)) ');']);
            set(ud.handles.thumbaxis(i), 'ButtonDownFcn', ['textureGui(''PREVIEWCLICKED'', ' num2str(scanIndV(i)) ');']);
            maxDose{scanIndV(i)} = num2str(drawThumb(ud.handles.thumbaxis(i), planC, scanIndV(i), h));
            [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(scanIndV(i)));
            s = ceil(median(1:length(zV)));
            ud.previewSlice(scanIndV(i)) = s; %%%%%%%%%%%%%%%%%
        end
        
        ud.maxDoses = maxDose;
        
        try
            set(ud.handles.previewAxis,'nextPlot','add')
            set(ud.handles.thumbaxis,'nextPlot','add')
        end
        
        set(h,'userdata',ud)   
        
    case 'PREVIEWCLICKED'
        ud = get(h, 'userdata');
        clickType = get(get(gcbo,'Parent'),'SelectionType');
        switch clickType
            case 'normal' %Left-click
                ud.currentScan = varargin{1};
                set(h, 'userdata', ud)
                set(h, 'WindowButtonMotionFcn', 'textureGui(''PREVIEWMOTION'')');
            case 'open'  %double-click
                ud.currentScan = varargin{1};
                set(h, 'userdata', ud);
                %Display selected texture map
                scanUID = ['c',repSpaceHyp(planC{indexS.scan}(varargin{1}).scanUID(max(1,end-61):end))];
                stateS.scanStats.Colormap.(scanUID) = 'weather';
                % strNum = get(ud.handles.structure,'value')-1; %Get current structure
                strNum = ud.structNum;
                if strNum==0
                    slicesV = 1:size(getScanArray(ud.currentScan,planC),3);
                    
                else
                    rasterSegments = getRasterSegments(strNum, planC);
                    slicesV = unique(rasterSegments(:, 6));
                end
                midSlice = floor((length(slicesV)+1)/2); %Get middle slice
                [~, ~, zs] = getScanXYZVals(planC{indexS.scan}(varargin{1}));
                newCoord = zs(midSlice);
                sliceCallBack('selectScan',num2str(varargin{1}));
                setAxisInfo(uint8(stateS.currentAxis), 'coord', newCoord);
               
                %Switch focus to CERR Viewer
                f = stateS.handle.CERRSliceViewer;
                figure(f);
        end
       
    case 'SELECT_MAPS_FOR_MIM'
        
    case 'SEND_MAPS_TO_MIM'
        ud = get(h,'userdata');        
        scanIndex = get(ud.handles.selectTextureMapsForMIM,'value');
        if scanIndex == 1
            return
        end
        strC = get(ud.handles.selectTextureMapsForMIM,'string');
        bridge = evalin('base','bridge');
        vol3M = evalin('base','arr');
        vol3M = vol3M * 0;
        text3M = planC{indexS.scan}(scanIndex).scanArray;
        txtMax = max(text3M(:));        
        rescaleSlope = double(txtMax)/double(intmax('int16'));
        rescaleIntercept = 0;
        text3M = int16(double(text3M)/rescaleSlope);
        %structNum = get(ud.handles.structure,'value')-1;
        structNum = ud.structNum;
        mask3M = getUniformStr(structNum);
        [minr, maxr, minc, maxc, mins, maxs]= compute_boundingbox(mask3M);
        vol3M(minr:maxr,minc:maxc,mins:maxs) = text3M;
        assignin('base', 'textureVol', vol3M);
        sInfo = evalin('base','arr_info');
        newSinfo = sInfo.getMutableCopy();
        newSinfo.setUnits('')
        newSinfo.setCustomName(strC{scanIndex})
        newSinfo.setRescaleSlope(rescaleSlope)
        newSinfo.setRescaleIntercept(rescaleIntercept)
        bridge.sendImageToMim('textureVol', newSinfo);
        textureGui('QUIT')

            
    case 'CREATE_NEW_TEXTURE'
        ud = get(h, 'userdata');
        set(ud.handles.texture,'enable', 'on');
        texListC = get(ud.handles.texture,'String');
        set(ud.handles.description,'enable', 'on');
        set(ud.handles.scan,'enable','on');
        set(ud.handles.structure,'enable','on');
        set(ud.handles.featureType,'enable','on');
        if length(texListC)==1 && strcmp(texListC,'   Click ''+'' to create  ')
            tNum = 1;
            label = 'Texture1';
            texListC{1} = label;
        else
            tNum = length(texListC)+1;
            label = ['Texture',num2str(tNum)]; %Default label
            texListC{end+1} = label;
        end
        set(ud.handles.texture,'String',texListC);
        set(ud.handles.texture,'Value',tNum);
        set(ud.handles.description,'String',label);
        set(ud.handles.featureType,'Value',1);
        %Clear any previous parameter controls
        if isfield(ud.handles,'paramControls')
            hPar = ud.handles.paramControls;
            hPar.delete;
        end
        set(h, 'userdata',ud);
        textureGui('SCAN_SELECTED');
        
        
    case 'DELETE_TEXTURE'
        ud = get(h, 'userdata');
        if ud.currentTexture == 0
            return;
        end
        ud.currentTexture = ud.currentTexture - 1;
        textureGui('REFRESHFIELDS');        
        
        
    case 'CREATE_MAPS'
        
        ud          = get(h, 'userdata');
        set(ud.handles.createTextureMaps,'enable','off'); %Disable while computing texture maps
        scanNum     = get(ud.handles.scan, 'value');
        structNum = ud.structNum;
        
        hwait = ud.wb.handles.patch;
        indexS = planC{end};
        
        paramS = ud.parameters;
        fType = ud.filtType;
        label =  get(ud.handles.description,'String');
        
        %Get scan array
        scan3M = getScanArray(scanNum,planC);
        CTOffset = planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
        scan3M = double(scan3M) - CTOffset;
        
        %Get structure mask
        fullMask3M = scan3M.^0;
        if ~(structNum==0)
            fullMask3M = getStrMask(structNum,planC);
            [minr,maxr,minc,maxc] = compute_boundingbox(fullMask3M);
            uniqueSlicesV = find(sum(sum(fullMask3M))>0);
        else
            uniqueSlicesV = 1:size(scan3M,3);
            minc = 1;
            maxc = size(scan3M,2);
            minr = 1;
            maxr = size(scan3M,1);
        end
        
        %Crop around mask, followed by padding as specified
        if ~isfield(paramS,'PadMethod')
            [procScan3M,procMask3M] = padScan(scan3M,fullMask3M,...
                'none',0);
        else
            [procScan3M,procMask3M] = padScan(scan3M,fullMask3M,...
                paramS.PadMethod.val,paramS.PadSize.val);
        end
        
        %Map user-selections to labels
        if(strcmp(fType,'Wavelets') )
            mappedWavFamilyC = {'db','haar','coif', 'fk','sym','dmey','bior','rbio'};
            wavFamilyC = {'Daubechies','Haar','Coiflets','FejerKorovkin','Symlets',...
                'Discrete Meyer wavelet','Biorthogonal','Reverse Biorthogonal'};
            idx = paramS.Wavelets.val;
            isWav = cellfun(@(x)isequal(x,idx),wavFamilyC);
            [~,idx] = find(isWav);
            out = mappedWavFamilyC{idx};
            paramS.Wavelets.val = out;
            if length(paramS.Index.val)>1
                paramS.Index.val = paramS.Index.val{1};
            end
            
        elseif (strcmp(fType,'Haralick Cooccurance') )
            mappedDirectionalityC = {1,2,3,4,5,6};
            directionalityC = {'Co-occurance with 13 directions in 3D',...
                'Left-Right, Ant-Post and Diagonals in 2D', ...
                'Left-Right and Ant-Post', ...
                'Left-Right',...
                'Anterior-Posterior',...
                'Superior-Inferior'};
            idx = paramS.Directionality.val;
            isDir = cellfun(@(x)isequal(x,idx),directionalityC);
            [~,idx] = find(isDir);
            out = mappedDirectionalityC{idx};
            paramS.Directionality.val = out;
            
            if strcmpi(paramS.PatchType.val,'cm')
                [xVals, yVals, zVals] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
                deltaX = abs(xVals(1)-xVals(2));
                deltaY = abs(yVals(1)-yVals(2));
                deltaZ = abs(zVals(1)-zVals(2));
                patchSizeV = paramS.PatchSize.val;
                slcWindow = floor(patchSizeV(3)/deltaZ);
                rowWindow = floor(patchSizeV(1)/deltaY);
                colWindow = floor(patchSizeV(2)/deltaX);
                patchSizeV = [rowWindow, colWindow, slcWindow];
                paramS.PatchSize.val = patchSizeV;
            end
                
        elseif (strcmp(fType,'Laws Convolution') )
            
            mappedDirC = {1,2,3};
            mappedPadMethodC = {1,2,3,4,5,6};
            
            dirC = {'2D','3D', 'All'};
            padMethodC = {'expand','padzeros','periodic','nearest',...
                    'mirror','none'};
                
            idx1 = paramS.Direction.val;
            idx2 = paramS.PadMethod.val;
            isDir = cellfun(@(x)isequal(x,idx1),dirC);
            isPadMethod = cellfun(@(x)isequal(x,idx2),padMethodC);
            [~,idx1] = find(isDir);
            [~,idx2] = find(isPadMethod);
            out1 = mappedDirC{idx1};
            out2 = mappedPadMethodC{idx2};
            paramS.Direction.val = out1;
            paramS.PadMethod.val = out2;

            elseif (strcmp(fType,'LoG'))
            
            mappedPadMethodC = {1,2,3,4,5,6};
            padMethodC = {'expand','padzeros','periodic','nearest',...
                'mirror','none'};
            idx = paramS.PadMethod.val;
            isPadMethod = cellfun(@(x)isequal(x,idx),padMethodC);
            [~,idx] = find(isPadMethod);
            out = mappedPadMethodC{idx};
            paramS.PadMethod.val = out;
        end
        
        %Apply filter
        outS = processImage(fType,procScan3M,procMask3M,paramS,hwait);
    
        % Create new Texture if ud.currentTexture = 0
        if ud.currentTexture == 0
            initTextureS = initializeCERR('texture');
            initTextureS(1).textureUID = createUID('texture');
            planC{indexS.texture} = dissimilarInsert(planC{indexS.texture},initTextureS);
            ud.currentTexture = length(planC{indexS.texture});
        else
            ud.currentTexture = ud.currentTexture+1;
        end
        assocScanUID = planC{indexS.scan}(scanNum).scanUID;
        planC{indexS.texture}(ud.currentTexture).assocScanUID = assocScanUID;
        if structNum~=0
            assocStrUID = planC{indexS.structures}(structNum).strUID;
            planC{indexS.texture}(ud.currentTexture).assocStructUID = assocStrUID;
        end
        planC{indexS.texture}(ud.currentTexture).category = fType;
        
        % Assign parameters based on category of texture
        planC{indexS.texture}(ud.currentTexture).parameters = paramS;
        planC{indexS.texture}(ud.currentTexture).description = label;
        planC{indexS.texture}(ud.currentTexture).textureUID = createUID('TEXTURE');
        
        % Create Texture Scans
        [xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(scanNum));
        deltaXYZv = ud.dXYZ;
        zV = zVals(uniqueSlicesV);
        regParamsS.horizontalGridInterval = deltaXYZv(1);
        regParamsS.verticalGridInterval = deltaXYZv(2); 
        regParamsS.coord1OFFirstPoint = xVals(minc);
        regParamsS.coord2OFFirstPoint   = yVals(maxr);
        
        regParamsS.zValues  = zV;
        regParamsS.sliceThickness =[planC{indexS.scan}(scanNum).scanInfo(uniqueSlicesV).sliceThickness];
        
        assocTextureUID = planC{indexS.texture}(ud.currentTexture).textureUID;
        
        %Save to planC
        featuresC = fieldnames(outS);
        for n = 1:length(featuresC)
            feat3M = outS.(featuresC{n});
            planC = scan2CERR(feat3M,featuresC{n},'Passed',regParamsS,assocTextureUID,planC);
        end 
        
        set(ud.handles.createTextureMaps,'enable','on'); 
        
        set(h, 'userdata', ud);
        
        % Refresh Fields
        textureGui('REFRESHFIELDS');
        
        % Refresh the thumbnails
        textureGui('REFRESH_THUMBS')
        
        
    case 'PREVIEWBUTTONDOWN'
        %Button clicked in the preview window.
        ud = get(h, 'userdata');
        ud.previewDown = 1;
        set(h, 'WindowButtonMotionFcn', 'textureGui(''PREVIEWMOTION'')',...
            'WindowButtonUpFcn','textureGui(''FIGUREBUTTONUP'')');
        set(h, 'userdata', ud)

    case 'FIGUREBUTTONUP'
        %Mouse up, if in preview window disable motion fcn.
        ud = get(h, 'userdata');
        %if ~isfield(ud, 'previewDown') || ud.previewDown == 1;
        %    ud.previewDown = 0;
            set(h, 'WindowButtonMotionFcn', '');
            set(h, 'userdata', ud);
        %end

    case 'PREVIEWMOTION'
        %Motion in the preview, with mouse down. Change preview slice.
        ud = get(h, 'userdata');
        cp = get(h, 'currentpoint');
        if isfield(ud, 'previewY')
            if ud.previewY > cp(2)
                %ud.previewSlice(ud.currentTexture) = ud.previewSlice(ud.currentTexture)+1;
                ud.previewSlice(ud.currentScan) = ...
                    min(ud.previewSlice(ud.currentScan)+1, size(getScanArray(ud.currentScan), 3));
                set(h, 'userdata', ud);
                %textureGui('refreshpreviewandfields');
            elseif ud.previewY < cp(2)
                %ud.previewSlice(ud.currentTexture) = ud.previewSlice(ud.currentTexture)-1;
                ud.previewSlice(ud.currentScan) = ...
                    max(ud.previewSlice(ud.currentScan)-1,1);
                set(h, 'userdata', ud);
                %textureGui('refreshpreviewandfields');
            end
            currentTex = ud.currentScan;
            textureC = {planC{indexS.scan}.assocTextureUID};
            texIdx = strcmp(textureC,planC{indexS.texture}(ud.currentTexture).textureUID);
            prevIndV = ~texIdx;
            prevIndV = prevIndV(find(prevIndV)<currentTex);
            drawThumb(ud.handles.thumbaxis(currentTex-sum(prevIndV)), planC,...
                ud.currentScan, h, ud.previewSlice(ud.currentScan));             
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
        scanNum = ud.currentTexture;
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
        ud.currentTexture = newScan;
        set(h, 'userdata', ud);
        textureGui('refreshpreviewandfields');

    case 'NAMEFIELD'
        %Dose name has changed, update in planC.
        ud = get(h, 'userdata');
        scanNum = ud.currentTexture;
        oldString = planC{indexS.scan}(scanNum).scanType;
        string = get(gcbo, 'string');
        planC{indexS.scan}(scanNum).scanType = string;
        statusString = ['Renamed scan number ' num2str(scanNum) ' from ''' oldString ''' to ''' string '''.'];
        textureGui('status', statusString);

    case 'STATUS'
        %Display passed string in status bar.
        statusString = varargin{1};
        ud = get(gcbf, 'userdata');
        h = ud.handles.status;
        set(h, 'string', statusString);

    case 'COMPRESS'
        %Compress/decompress selected scan.
        ud = get(h, 'userdata');
        scanNum = ud.currentTexture;
        scanName = planC{indexS.scan}(scanNum).scanType;

        if ~isCompressed(planC{indexS.scan}(scanNum).scanArray)
            statusString = ['Compressing scan number ' num2str(scanNum) ', ''' scanName ''' please wait...'];
            textureGui('status', statusString);
            planC{indexS.scan}(scanNum).scanArray = compress(getScanArray(scanNum, planC));
            drawThumb(ud.handles.thumbaxis(scanNum), planC, scanNum, h);
            statusString = ['Compressed scan number ' num2str(scanNum)  ', ''' scanName '''.'];
            textureGui('status', statusString);
            set(ud.handles.compbutton, 'string', 'Decompress');
        else
            statusString = ['Decompressing scan number ' num2str(scanNum) ', ''' scanName ''', please wait...'];
            textureGui('status', statusString);
            %Use getScanArray and not decompress to use the cached value.
            planC{indexS.scan}(scanNum).scanArray = getScanArray(scanNum, planC);
            maxScan = drawThumb(ud.handles.thumbaxis(scanNum), planC, scanNum, h);
            %Update the maxScans value, but be sure to get a fresh ud since
            %a user could have clicked during compression.
            ud = get(h, 'userdata');
            ud.maxScans{scanNum} = num2str(maxScan);
            set(h, 'userdata', ud);
            statusString = ['Decompressed scan number ' num2str(scanNum)  ', ''' scanName '''.'];
            textureGui('status', statusString);
            set(ud.handles.compbutton, 'string', 'Compress');
        end
        textureGui('refreshpreviewandfields');

    case 'REMOTE'
        %Make/unmake selected dose remote.
        ud = get(h, 'userdata');
        scanNum = ud.currentTexture;
        scanName = planC{indexS.scan}(scanNum).scanType;

        scanUID = planC{indexS.scan}(scanNum).scanUID;

        if isLocal(planC{indexS.scan}(scanNum).scanArray)
            statusString = ['Writing to disk scan number ' num2str(scanNum) ', ''' scanName ''' please wait...'];
            textureGui('status', statusString);
            [fpath,fname] = fileparts(stateS.CERRFile);
            planC{indexS.scan}(scanNum).scanArray = setRemoteVariable(getScanArray(scanNum, planC), 'LOCAL',fullfile(fpath,[fname,'_store']),['scanArray_',scanUID,'.mat']);
            % Also make remote the scanArraySuperior and scanArrayInferior matrices
            planC{indexS.scan}(scanNum).scanArraySuperior = setRemoteVariable(getScanArraySuperior(scanNum, planC), 'LOCAL',fullfile(fpath,[fname,'_store']),['scanArraySuperior_',scanUID,'.mat']);
            planC{indexS.scan}(scanNum).scanArrayInferior = setRemoteVariable(getScanArrayInferior(scanNum, planC), 'LOCAL',fullfile(fpath,[fname,'_store']),['scanArrayInferior_',scanUID,'.mat']);
            drawThumb(ud.handles.thumbaxis(scanNum), planC, scanNum, h);
            statusString = ['Wrote to disk scan number ' num2str(scanNum)  ', ''' scanName '''.'];
            textureGui('status', statusString);
            set(ud.handles.remotebutton, 'string', 'Use Memory');
            uiwait(msgbox(['scanArray stored in folder ',fullfile(fpath,[fname,'_store']),'. Note the Location'],'modal'));
        else
            statusString = ['Reading from disk scan number ' num2str(scanNum) ', ''' scanName ''', please wait...'];
            textureGui('status', statusString);

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
            textureGui('status', statusString);
            set(ud.handles.remotebutton, 'string', 'Use Disk');

            %Update the maxDoses value, but be sure to get a fresh ud since
            %a user could have clicked during remote writing to disk.
            ud = get(h, 'userdata');
            ud.maxScans{scanNum} = num2str(maxScan);
            set(h, 'userdata', ud);
        end
        textureGui('refreshpreviewandfields');

    case 'SAVE'
        %Open dialog to save dose array as .mat file.
        ud = get(h, 'userdata');
        scanNum = ud.currentTexture;
        scanName = planC{indexS.scan}(scanNum).scanType;
        [filename, pathname] = uiputfile('*.mat', ['Save (uncompressed) scan array number ' num2str(scanNum) ' as:']);
        if filename==0
            return;
        end
        scan3D = getScanArray(scanNum, planC);
        save(fullfile(pathname, filename), 'scan3D');
        statusString = ['Saved scan number ' num2str(scanNum) ', ''' scanName ''' to ' [filename '.mat'] '.'];
        textureGui('status', statusString);

    case 'DELETE'
        %Delete selected scan.  If being displayed, verify deletion with user.
        ud = get(h, 'userdata');
        scanNum = ud.currentTexture;
        scanName = planC{indexS.scan}(scanNum).scanType;

        refreshViewer = 0;
        axesV = checkDisplayedScans(scanNum);
        if ~isempty(axesV)
            choice = questdlg('One or more CERR axes are currently displaying this scan.  If you delete it, these axes will be set to display no scan.  Proceed?', 'Continue?', 'Continue', 'Abort', 'Continue');
            if strcmpi(choice, 'Abort')
                statusString = ['Delete aborted.'];
                textureGui('status', statusString);
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
            textureGui('status', statusString);
            %Delete the structures associated with this scan
            assocScanV = getStructureAssociatedScan(1:length(planC{indexS.structures}), planC);
            structToDelete = find(assocScanV == scanNum);
            planC{indexS.structures}(structToDelete) = [];
            %Delete structureArray
            %indAssoc = find(strcmpi({planC{indexS.structureArray}.assocScanUID},planC{indexS.scan}(scanNum).scanUID));
            %planC{indexS.structureArray}(indAssoc) = [];
            planC{indexS.structureArray}(scanNum) = [];
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
            textureGui;
        else
        end

        %Refresh CERR axes in the case of changed dose sets.
        if refreshViewer
            sliceCallBack('refresh');
        end

    case 'DOSESCALE'
        ud          = get(h, 'userdata');
        doseNum     = ud.currentScan;
        doseName    = planC{indexS.dose}(doseNum).fractionGroupID;
        newMaxDose  = str2num(get(gcbo, 'string'));

        %Get the dose array and its compression state.
        [dA, isCompress, isRemote] = getDoseArray(doseNum, planC);

        maxScan = max(dA(:));
        if maxScan == 0
            set(gcbo, 'string', '0')
            statusString = ['Unable to rescale all zero dose distribution.'];
            textureGui('status', statusString);
            return;
        end

        if isCompress | isRemote
            statusString = ['Rescaling compressed or remote dose can take a moment, please wait...'];
            textureGui('status', statusString);
        end

        %Perform the rescale.
        dA = dA *  (1/maxDose * newMaxDose);

        planC = setDoseArray(doseNum, dA, planC);
        statusString = ['Rescaled dose number ' num2str(doseNum) ', ''' doseName ''' from [0 ' num2str(maxDose) '] Gy to [0 ' num2str(newMaxDose) '] Gy.'];
        ud.maxDoses{doseNum} = num2str(newMaxDose);
        set(h, 'userdata', ud);
        textureGui('status', statusString);

    case 'QUIT'
        close;
end

function nBytes = getByteSize(data)
%"getByteSize"
%Returns the number of bytes in the passed data
infoStruct = whos('data');
nBytes = infoStruct.bytes;

function scanType = drawThumb(hAxis, planC, index, hFigure,slcNum)
%"drawThumb"
%In passed dose array, find slice with highest dose and draw in hAxis.
%Also denote the index in the corner.  If compressed show compressed.
set(hFigure, 'CurrentAxes', hAxis);
toDelete = get(hAxis, 'children');
delete(toDelete);

bdf = get(hAxis, 'buttondownfcn');
ud = get(hFigure,'userdata');


%Get the dose array and its compression state.
indexS = planC{end};
[dA, isCompress, isRemote] = getScanArray(index, planC);
offset = planC{indexS.scan}(index).scanInfo(1).CTOffset;
dA = dA - offset;

%Set the scan to median of z-values
assocTex = planC{indexS.scan}(index).assocTextureUID;
texIdx = strcmp(assocTex,{planC{indexS.texture}.textureUID});
assocScanIdx = strcmp({planC{indexS.scan}.scanUID},planC{indexS.texture}(texIdx).assocScanUID);
[xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(assocScanIdx));
[~,~,sV] = getScanXYZVals(planC{indexS.scan}(index));
if exist('slcNum','var')
    s = min(slcNum,length(sV));
else
    s = ceil(median(1:length(sV)));    
end


%Create thumbnail
%strNum = ud.handles.structure.Value - 1;
% if isfield(ud,'structNum')
%     strNum = ud.structNum;
% else
%     ud.structNum = 0;
%     strNum = 0;
% end
strNum = ud.structNum;

if strNum==0 %Entire scan
    firstROISlice = 1;
else
    rasterSegments = getRasterSegments(strNum, planC);
    firstROISlice = min(unique(rasterSegments(:,6)));
end


thumbSlice = min(s,numel(sV));
% thumbSlice = thumbSlice + firstROISlice - 1;
thumbSlice = max(1,thumbSlice);
%endSlice = numel(sV)+ firstROISlice - 1;
endSlice = numel(sV);
thumbImage = dA(:,:,thumbSlice);
thumbImage = imgaussfilt(thumbImage,.5); %Display smoothed thumbnail
% Set window level & width
thumbMin = min(dA(:));
thumbMax = max(dA(:));
winLevel = (thumbMin + thumbMax) / 2;
winWidth = thumbMax - thumbMin;
cLim = [winLevel-winWidth/2,winLevel+winWidth/2];
imagesc(thumbImage,'hittest', 'off', 'parent', hAxis, cLim);
colormap(hAxis, ud.cM);

%Display scan name
scanType = planC{indexS.scan}(index).scanType;
scanType = strrep(scanType,'_','\_'); 
%scanType = [scanType,' ',num2str(thumbSlice+ firstROISlice - 1),'/',num2str(endSlice+ firstROISlice - 1)];
scanType = [scanType,' ',num2str(thumbSlice),'/',num2str(endSlice)];
slNum = ['Sl ',num2str(thumbSlice+ firstROISlice - 1)];



%---for radiomics paper---
% thumbSlice = 76;
% thumbImage = dA(:,:,thumbSlice);
% thumbImage = imgaussfilt(thumbImage,2); %smooth
% thumbImage = thumbImage(120:410,80:410);
% endSlice = numel(sV)+ firstROISlice - 1;
% scanType = scanType(strfind(scanType,'_')+1:end);
% % winCenterV = [ 0  -150 -25 -101.45  -106.132  -532.957 585.924 -325.482 31.0868];
% % winWidthV =  [ 0 1350  3669  1446.92  1337.77  2643.11  1969.69 4531.86  1122.75];
% %iMin = winCenterV(index) - winWidthV(index)/2;
% %iMax = winCenterV(index) + winWidthV(index)/2;
% imagesc(hAxis,thumbImage,'Parent',hAxis,'hittest', 'off');
%-------------------------

set(hAxis, 'ytick',[],'xtick',[]);

if isCompress && isRemote
    text(.1, .1, 'Compressed', 'units', 'normalized', 'fontsize', 8, 'color', 'white', 'horizontalAlignment', 'left', 'hittest', 'off', 'parent', hAxis);
    text(.1, .2, 'Remote', 'units', 'normalized', 'fontsize', 8, 'color', 'white', 'horizontalAlignment', 'left', 'hittest', 'off', 'parent', hAxis);
elseif isRemote
    text(.1, .1, 'Remote', 'units', 'normalized', 'fontsize', 8, 'color', 'white', 'horizontalAlignment', 'left', 'hittest', 'off', 'parent', hAxis);
elseif isCompress
    text(.1, .1, 'Compressed', 'units', 'normalized', 'fontsize', 8, 'color', 'white', 'horizontalAlignment', 'left', 'hittest', 'off', 'parent', hAxis);
end

xLim = get(hAxis, 'xlim');
yLim = get(hAxis, 'ylim');
x = (xLim(2) - xLim(1)) * .05 + xLim(1);
y = (yLim(2) - yLim(1)) * .15 + yLim(1);
y2 = (yLim(2) - yLim(1)) * .2 + yLim(1);
text(x, y, scanType, 'fontsize', 9, 'fontweight', 'bold', 'color', 'k',...
    'hittest', 'off', 'parent', hAxis);
text(x, y2, slNum, 'fontsize', 9, 'fontweight', 'bold', 'color', 'k',...
    'hittest', 'off', 'parent', hAxis); %added

%--- For radiomics paper---
% text(x, y, scanType, 'fontsize', 11, 'fontweight', 'bold', 'color', 'k', 'hittest', 'off', 'parent', hAxis);
%--------------------------

set(hAxis, 'buttondownfcn', bdf);
axis(hAxis,'ij');
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
    aI = get(stateS.handle.CERRAxis(i), 'userdata');
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
    aI = get(stateS.handle.CERRAxis(i), 'userdata');
    if ~isempty(aI.scanObj)
        scanSets = aI.scanObj.scanSet;
        aI.scanObj.scanSet = 1; %max(1,scanSets(scanSets >= delIndex)- 1);
        set(stateS.handle.CERRAxis(i), 'userdata', aI);
    end
    
end

    function outS = addParam(outS,fieldname,type,val,disp,pos,hFigure)
        
        %Update disctionary
        outS.(fieldname).type = type;
        in = val;
        if strcmp(type,'edit')
            if iscell(in)
                in = in{1};
            end
            if ~isnumeric(in)
                temp = str2num(in);
                if ~isempty(temp)
                    in = temp;
                end
            end
            outS.(fieldname).val = in;
        elseif strcmp(type,'popup')
            %outS.(fieldname).val = 1;
            if iscell(in)
            outS.(fieldname).val = in{1};
            else
            outS.(fieldname).val = in;
            end
        end
        outS.(fieldname).disp = disp;
        
        %Add uicontrols
        ud = get(hFigure,'userdata');
        hPar = ud.handles.paramControls;
        frameColor = [0.8314 0.8157 0.7843];
        txtLeft = .05;
        textWidth = .2;
        fieldLeft = .22;
        fieldWidth = .25;
        rowHeight = 0.04;
        
        hPar(end+1) = uicontrol(hFigure,'units','normalized','Visible',disp,...
            'Position',[txtLeft pos textWidth rowHeight],'Style','Text','String',fieldname,...
            'backgroundColor',frameColor,'horizontalAlignment', 'left','fontSize',10);
        
        hPar(end+1) = uicontrol(hFigure,'units','normalized','Visible',disp,...
            'Position',[fieldLeft pos fieldWidth rowHeight],'Style',type,'String',val,...
            'fontSize',10,'backgroundColor','w','horizontalAlignment', 'left',...
            'callback',{@updateParams,hFigure},'Tag',fieldname);
        
        ud.handles.paramControls = hPar;
        set(hFigure,'userdata',ud);
        
   
    function updateParams(hObj,hEvt,hFig)
        ud = get(hFig,'userdata');
        if strcmp(get(hObj,'style'),'edit')
            userIn = get(hObj,'string');
            if iscell(userIn)
                userIn = userIn{1};
            end
            if ~isnumeric(userIn)
                userIn = str2num(userIn);
            end
        else %popup
            %userIn = get(hObj,'value');
            userIn = hObj.String{hObj.Value};
        end
        paramS = ud.parameters;
        paramS.(hObj.Tag).val = userIn;
        
        if isfield(paramS.(hObj.Tag),'subType')
            hPar = ud.handles.paramControls;
            tagC = get(hPar,'Tag');
            featType = get(hObj,'tag');
            idx = strcmp(tagC,paramS.(featType).subType);
            val = getSubParameter(featType,userIn);
            set(hPar(idx),'String',val);
            ud.handles.paramControls = hPar;
            paramS.(paramS.(hObj.Tag).subType).val = val;
            set(hFig,'userdata',ud);
        end
        
        ud.parameters = paramS;
        set(hFig,'userdata',ud);
        
        function updateLabel(hObj,hEvt,hFig)
            ud = get(hFig,'userdata');
            label = get(hObj,'string');
            set(ud.handles.description,'String',label);
            set(hFig,'userdata',ud);
            
            
       function out = getSubParameter(featType,idx)
                
           switch(featType)
           case 'Wavelets'
                wavFamilyC = {'Daubechies','Haar','Coiflets','FejerKorovkin','Symlets',...
                    'Discrete Meyer wavelet','Biorthogonal','Reverse Biorthogonal'};
                isWav = cellfun(@(x)isequal(x,idx),wavFamilyC);
                [~,idx] = find(isWav);
                subParC =  {{'1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16',...
                    '17','18','19','20','21','22','23','24','25','26','27','28','29','30',...
                    '31','32','33','34','35','36','37','38','39','40','41','42','43','44','45'},{},...
                    {'1','2','3','4','5'},{'4','6','8','14','18','22'},{'2','3','4','5',...
                    '6','7','8','9','10','11','12','13','14','15','16',...
                    '17','18','19','20','21','22','23','24','25','26','27','28','29','30',...
                    '31','32','33','34','35','36','37','38','39','40','41','42','43','44','45'},...
                    {},{'1.1','1.3','1.5','2.2','2.4','2.6','2.8','3.1','3.3','3.5',...
                    '3.7','3.9','4.4','5.5','6.8'},{'1.1','1.3','1.5','2.2','2.4','2.6',...
                    '2.8','3.1','3.3','3.5','3.7','3.9','4.4','5.5','6.8'}};
           end
           out = subParC{idx};
           

           
                