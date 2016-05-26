function textureGui(command, varargin)
%"textureGui" GUI
%   Create a GUI to manage texture calculation.
%
%   APA 09/29/2015
%
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
global planC stateS
indexS = planC{end};

%Use a static window size, by pixels.  Do not allow resizing.
screenSize = get(0,'ScreenSize');
y = 380;
x = 640;
y = 480;
x = 740;
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
            %ud.wb.handles.percent = text(.5, .45, '', 'parent', ud.wb.handles.wbAxis, 'horizontalAlignment', 'center');
            %ud.wb.handles.text = uicontrol(h, 'style', 'text', 'units', units, 'position', [wbX+50 wbY+wbH - 21 wbW-100 15], 'string', '');

            % Initialize current scan
            ud.currentScan = 0;
            
            % Set cm vs voxels flag
            ud.cmFlag = 1;
            
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
        structNum = 1;
        descript = '';
        patchSize = [0.5,0.5,0.3];
        ud.cmFlag = 1;
        
        % Haralick default parameters
        directionHar  = 1;
        numGrLevels   = 16;
        entropyFlg    = 0;
        energyFlg     = 0;
        sumAvgFlg     = 0;
        homogFlg      = 0;
        contrastFlg   = 0;
        corrFlg       = 0;
        clustShadFlg  = 0;
        clustPromFlg  = 0;
        
        % Absolute Gradient default parameters
        directionAbsGr = 1;

        % Edge default parameters
        sigma = 0.5;                
        
        texturesC = {planC{indexS.texture}(:).description};        
        
        % Populate values from an existing texture
        if textureNum > 0
            set(ud.handles.texture, 'String', texturesC)
            
            scanUID       = planC{indexS.texture}(textureNum).assocScanUID;
            scanNum       = getAssociatedScan(scanUID);
            structureUID  = planC{indexS.texture}(textureNum).assocStructUID;
            structNum     = getAssociatedStr(structureUID);
            category      = planC{indexS.texture}(textureNum).category;
            descript      = planC{indexS.texture}(textureNum).description;
            patchSize     = planC{indexS.texture}(textureNum).patchSize;
            patchUnit     = planC{indexS.texture}(textureNum).patchUnit;
            if strcmpi(patchUnit, 'cm')
                ud.cmFlag = 1;
            else
                ud.cmFlag = 0;
            end
%             [xV,yV,zV] = getScanXYZVals(planC{indexS.scan}(scanNum));
%             dx = abs(mean(diff(xV)));
%             dy = abs(mean(diff(yV)));
%             dz = abs(mean(diff(zV)));
%             ud.dXYZ = [dy dx dz];
            if category == 1 %strcmpi(category,'haralick')
                numGrLevels   = planC{indexS.texture}(textureNum).paramS.numGrLevels;
                directionHar  = planC{indexS.texture}(textureNum).paramS.direction;
                entropyFlg    = planC{indexS.texture}(textureNum).paramS.entropyFlag;
                energyFlg     = planC{indexS.texture}(textureNum).paramS.energyFlag;
                sumAvgFlg     = planC{indexS.texture}(textureNum).paramS.sumAvgFlag;
                homogFlg      = planC{indexS.texture}(textureNum).paramS.homogFlag;
                contrastFlg   = planC{indexS.texture}(textureNum).paramS.contrastFlag;
                corrFlg       = planC{indexS.texture}(textureNum).paramS.corrFlag;
                clustShadFlg  = planC{indexS.texture}(textureNum).paramS.clusterShadeFlag;
                clustPromFlg  = planC{indexS.texture}(textureNum).paramS.clusterPromFlag;
            elseif strcmpi(category,'absGradient')
                directionAbsGr  = planC{indexS.texture}(textureNum).paramS.direction;
                meanAgrGrFlag = planC{indexS.texture}(textureNum).paramS.meanAgrGrFlag;
                varAbsGrFlag = planC{indexS.texture}(textureNum).paramS.varAbsGrFlag;
            elseif strcmpi(category,'edge')
            else
                disp('unknown category')
            end
            
            set(ud.handles.texture, 'value',textureNum);

        end
        
        set(ud.handles.scan, 'value', scanNum);
        set(ud.handles.structure, 'value', structNum);
        set(ud.handles.description, 'String', descript);
        patchSizeStr = '';
        for i = 1:length(patchSize)
            patchSizeStr = [patchSizeStr, num2str(patchSize(i)), ','];
        end
        set(ud.handles.patchSize, 'String',patchSizeStr(1:end-1));
        if ud.cmFlag        
            set(ud.handles.patchCm, 'value',1);
            set(ud.handles.patchVx, 'value',0);
        else
            set(ud.handles.patchCm, 'value',0);
            set(ud.handles.patchVx, 'value',1);
        end
        
        set(ud.handles.direction, 'value',directionHar);
        set(ud.handles.numLevels, 'String',numGrLevels);
        set(ud.handles.entropy, 'value', entropyFlg);
        set(ud.handles.energy, 'value', energyFlg);
        set(ud.handles.sumAvg, 'value', sumAvgFlg);
        set(ud.handles.homog, 'value', homogFlg);
        set(ud.handles.contrast, 'value', contrastFlg);
        set(ud.handles.corr, 'value', corrFlg);
        set(ud.handles.clustShade, 'value', clustShadFlg);
        set(ud.handles.clustProm, 'value', clustPromFlg);
        
        set(h, 'userdata', ud);
            
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
                delete(stateS.handle.(fieldNamC{i}))
                stateS.handle.(fieldNamC{i}) = [];
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
        structsC = cell(1,nStructs);
        for i = 1:nStructs
            structsC{i} = [num2str(i), '.', planC{indexS.structures}(i).structureName];
        end
        
        % List of Directions
        dirsC = {'Co-occurance with 13 directions in 3D',...
            'Left-Right, Ant-Post and Diagonals in 2D', ...
            'Left-Right and Ant-Post', ...
            'Left-Right',...
            'Anterior-Posterior',...
            'Superior-Inferior'};
        
        % List of feature types
        featureTypeC = {'Haralick Cooccurance', ...
            'Absolute Gradient', ...
            'Edge'};
        
        %Downsample colormap, redraws much faster.
        % cM = CERRColorMap(stateS.optS.doseColormap);
        cM = CERRColorMap('gray');
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
        
%         % Get scans associated with this texture
%         for i=1:nScans
%             set(ud.handles.thumbaxis(i), 'ButtonDownFcn', ['textureGui(''CHANGESCAN'', ' num2str(i) ');']);
%             maxScan{i} = num2str(drawThumb(ud.handles.thumbaxis(i), planC, i, h));
%             ud.previewSlice(i) = 1; %%%%%%%%%%%%%%%%%
%         end

        txtLeft = .05;
        textWidth = .1;
        fieldLeft = .27;
        fieldWidth = .20;

        %Make text to describe uicontrols.
        uicontrol(h, 'units',units,'Position',[txtLeft-0.02 1-.15 textWidth rowHeight],'String', 'Texture:', 'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'fontSize',14);
        uicontrol(h, 'units',units,'Position',[txtLeft 1-.25 textWidth rowHeight],'String', 'Scan:', 'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor);
        uicontrol(h, 'units',units,'Position',[txtLeft 1-.32 textWidth rowHeight],'String', 'Structure:', 'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor);
        uicontrol(h, 'units',units,'Position',[txtLeft 1-.39 textWidth rowHeight],'String', 'Description:', 'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor);
        uicontrol(h, 'units',units,'Position',[txtLeft 1-.46 textWidth rowHeight],'String', 'Patch Radius:', 'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor);
        uicontrol(h, 'units',units,'Position',[txtLeft 1-.53 textWidth rowHeight],'String', 'Category:', 'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor);
        uicontrol(h, 'units',units,'Position',[txtLeft 1-.60 textWidth rowHeight],'String', 'Directionality:', 'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag','haralick');
        uicontrol(h, 'units',units,'Position',[txtLeft 1-.67 textWidth+0.1 rowHeight],'String', 'Number of Grey Levels:', 'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag','haralick');

        %Make uicontrols for managing the scans, and displaying info.
        structNum = 1;
        ud.handles.texture       = uicontrol(h, 'units',units,'Position',[fieldLeft-0.14 1-.15 fieldWidth+0.08 rowHeight-.01],'String',{''}, 'Style', 'popup', 'callback', 'textureGui(''TEXTURE_SELECTED'');', 'enable', 'inactive', 'horizontalAlignment', 'right');
        ud.handles.textureAdd    = uicontrol(h, 'units',units,'Position',[2*fieldLeft-0.12 1-.15 0.03 rowHeight-.01],'String','+', 'Style', 'push', 'callback', 'textureGui(''CREATE_NEW_TEXTURE'');', 'horizontalAlignment', 'right');
        ud.handles.textureDel    = uicontrol(h, 'units',units,'Position',[2*fieldLeft-0.08 1-.15 0.03 rowHeight-.01],'String','-', 'Style', 'push', 'callback', 'textureGui(''DELETE_TEXTURE'');', 'horizontalAlignment', 'right');
        ud.handles.scan          = uicontrol(h, 'units',units,'Position',[fieldLeft-.05 1-.25 fieldWidth+0.05 rowHeight],'String', scansC, 'value', 1,  'Style', 'popup', 'horizontalAlignment', 'right', 'BackgroundColor', frameColor);
        ud.handles.structure     = uicontrol(h, 'units',units,'Position',...
            [fieldLeft-.05 1-.32 fieldWidth+.05 rowHeight],'String', structsC,...
            'value', 1, 'Style', 'popup', 'horizontalAlignment', 'right',...
            'BackgroundColor', frameColor,'callback', 'textureGui(''STRUCT_SELECTED'');');
        ud.handles.description   = uicontrol(h, 'units',units,'Position',[fieldLeft-.05 1-.37 fieldWidth+.05 rowHeight-0.01],'String', '',  'Style', 'edit', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor);
        ud.handles.patchSize     = uicontrol(h, 'units',units,'Position',[fieldLeft-.05 1-.44 fieldWidth/2+0.05 rowHeight-0.01],'String', '0.5 0.5 0.5',  'Style', 'edit', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor);
        ud.handles.patchCm       = uicontrol(h, 'units',units,'Position',[fieldLeft+0.11 1-.42 0.11 rowHeight-0.01],'String', 'cm (y,x,z)',  'Style', 'radio', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'callback', 'textureGui(''PATCH_CM_SELECTED'');');
        ud.handles.patchVx       = uicontrol(h, 'units',units,'Position',[fieldLeft+0.11 1-.46 0.11 rowHeight-0.01],'String', 'vox (r,c,s)',  'Style', 'radio', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'callback', 'textureGui(''PATCH_VOX_SELECTED'');');
        ud.handles.featureType   = uicontrol(h, 'units',units,'Position',[fieldLeft-.05 1-.52 fieldWidth+.05 rowHeight],'String', featureTypeC, 'value', 1, 'Style', 'popup', 'callback', 'textureGui(''FEATURE_TYPE_SELECTED'');', 'horizontalAlignment', 'right', 'BackgroundColor', frameColor);
        ud.dXYZ                  = getVoxelSize(structNum);
        
        % Haralick handles
        ud.handles.direction     = uicontrol(h, 'units',units,'Position',[fieldLeft-.05 1-.59 fieldWidth+.05 rowHeight],'String', dirsC, 'value', 1, 'Style', 'popup', 'horizontalAlignment', 'right', 'BackgroundColor', frameColor, 'tag', 'haralick');
        ud.handles.numLevels     = uicontrol(h, 'units',units,'Position',[fieldLeft-.05 1-.65 fieldWidth/2 rowHeight-0.01],'String', '',  'Style', 'edit', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');        
        ud.handles.entropy       = uicontrol(h, 'units',units,'Position',[0.04 1-.73+0.01 0.02 rowHeight],'String', 'Entropy',  'Style', 'checkbox', 'value', 0, 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
        ud.handles.entropyTxt    = uicontrol(h, 'units',units,'Position',[0.07 1-.73 0.1 rowHeight],'String', 'Entropy',  'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
        ud.handles.energy        = uicontrol(h, 'units',units,'Position',[0.18 1-.73+0.01 0.02 rowHeight],'String', '',  'Style', 'checkbox', 'value', 0, 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
        ud.handles.energyTxt     = uicontrol(h, 'units',units,'Position',[0.21 1-.73 0.1 rowHeight],'String', 'Energy',  'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
        ud.handles.sumAvg        = uicontrol(h, 'units',units,'Position',[0.32 1-.73+0.01 0.02 rowHeight],'String', '',  'Style', 'checkbox', 'value', 0, 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
        ud.handles.sumAvgTxt     = uicontrol(h, 'units',units,'Position',[0.35 1-.73 0.1 rowHeight],'String', 'SumAvg',  'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
        ud.handles.homog         = uicontrol(h, 'units',units,'Position',[0.04 1-.78+0.01 0.02 rowHeight],'String', '',  'Style', 'checkbox', 'value', 0, 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
        ud.handles.homogTxt      = uicontrol(h, 'units',units,'Position',[0.07 1-.78 0.1 rowHeight],'String', 'Homogenity',  'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
        ud.handles.contrast      = uicontrol(h, 'units',units,'Position',[0.18 1-.78+0.01 0.02 rowHeight],'String', '',  'Style', 'checkbox', 'value', 0, 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
        ud.handles.contrastTxt   = uicontrol(h, 'units',units,'Position',[0.21 1-.78 0.1 rowHeight],'String', 'Contrast',  'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
        ud.handles.corr          = uicontrol(h, 'units',units,'Position',[0.32 1-.78+0.01 0.02 rowHeight],'String', '',  'Style', 'checkbox', 'value', 0, 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
        ud.handles.corrTxt       = uicontrol(h, 'units',units,'Position',[0.35 1-.78 0.1 rowHeight],'String', 'Correlation',  'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
        ud.handles.clustShade    = uicontrol(h, 'units',units,'Position',[0.04 1-.83+0.01 0.02 rowHeight],'String', '',  'Style', 'checkbox', 'value', 0, 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
        ud.handles.clustShadeTxt = uicontrol(h, 'units',units,'Position',[0.07 1-.83 0.12 rowHeight],'String', 'ClusterShade',  'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
        ud.handles.clustProm     = uicontrol(h, 'units',units,'Position',[0.18 1-.83+0.01 0.02 rowHeight],'String', '',  'Style', 'checkbox', 'value', 0, 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
        ud.handles.clustPromTxt  = uicontrol(h, 'units',units,'Position',[0.21 1-.83 0.12 rowHeight],'String', 'ClusterProm',  'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
        
        % Absolute Gradient handles
        
        % Edge handles
        
        
        % uicontrols to generate or delete texture maps
        ud.handles.createTextureMaps  = uicontrol(h, 'units',units,'Position',[0.03 1-.95 0.12 rowHeight],'String', 'Create Maps', 'Style', 'pushbutton', 'callback', 'textureGui(''CREATE_MAPS'');', 'userdata', i);
        
        set(h, 'userdata', ud);
        set(0, 'CurrentFigure', hFig);

        if ~isempty(ud.currentTexture)
            textureGui('REFRESHFIELDS');
            textureGui('REFRESH_THUMBS');
        end        
        
    case 'STRUCT_SELECTED'
        ud = get(h, 'userdata');
        structNum = get(ud.handles.structure,'value');
        ud.dXYZ   = getVoxelSize(structNum);
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
        
    case 'TEXTURE_SELECTED'
        ud = get(h, 'userdata');
        strC = get(gcbo,'String');
        if length(strC) == 1 && strcmpi(strC{1},'')
            return;
        end
        ud.currentTexture = get(ud.handles.texture,'value');
        set(h, 'userdata', ud);
        textureGui('REFRESHFIELDS');
        textureGui('REFRESH_THUMBS');
        
    case 'FEATURE_TYPE_SELECTED'
        
        ud = get(h, 'userdata');
        featureType = get(ud.handles.featureType, 'value');
        harV = findobj(stateS.handle.textureManagementFig,'tag','haralick');
        absGrV = findobj(stateS.handle.textureManagementFig,'tag','absGradient');
        edgV = findobj(stateS.handle.textureManagementFig,'tag','edge');
        set([harV, absGrV, edgV],'visible','off')
        if featureType == 1 % Haralick
            set(harV, 'visible','on')
        end
        if featureType == 2 % Absolute Gradient
            set(absGrV, 'visible','on')
        end
        if featureType == 3 % Edge
            set(edgV, 'visible','on')
        end
        
        % re-Populate field values
        textureGui('REFRESHFIELDS');   
        
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
            nScans = 0;
        else
            scansV = strcmp(textureC,planC{indexS.texture}(ud.currentTexture).textureUID);
            scanIndV = find(scansV);
            if isempty(scanIndV)
                ud.currentScan = 0;
                nScans = 0;
            else
                ud.currentScan = scanIndV(1);
                nScans = sum(scansV);
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
        cM = CERRColorMap('starinterp');
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
        subPlotSize = max(1,ceil(sqrt(nScans)));
        dh = thumbRegion(4)/subPlotSize;
        dw = thumbRegion(3)/subPlotSize;
        ud.handles.thumbaxis = [];
        for i =1:subPlotSize^2
            row = subPlotSize - ceil(i/subPlotSize) + 1;
            col = mod(i-1,subPlotSize)+1;
            ud.handles.thumbaxis(i) = axes('position', [thumbRegion(1) + dw*(col-1) thumbRegion(2) + dh*(row-1) dw-dx dh-dy], 'box', 'on', 'parent', h);
            set(ud.handles.thumbaxis(i), 'ytick',[],'xtick',[], 'color', 'black');
            colormap(ud.handles.thumbaxis(i), ud.cM);
        end

        maxDose = [];
        for i=1:nScans
            set(ud.handles.thumbaxis(i), 'ButtonDownFcn', ['textureGui(''CHANGEDOSE'', ' num2str(scanIndV(i)) ');']);
            maxDose{scanIndV(i)} = num2str(drawThumb(ud.handles.thumbaxis(i), planC, scanIndV(i), h));
            ud.previewSlice(scanIndV(i)) = 1; %%%%%%%%%%%%%%%%%
        end
        
        ud.maxDoses = maxDose;
        
        try
            set(ud.handles.previewAxis,'nextPlot','add')
            set(ud.handles.thumbaxis,'nextPlot','add')
        end
        
        set(h,'userdata',ud)        
        

        
    case 'CREATE_NEW_TEXTURE'
        ud = get(h, 'userdata');
        ud.currentTexture = 0;
        set(ud.handles.texture,'enable', 'on')
        textureGui('REFRESHFIELDS');       
        
        
    case 'DELETE_TEXTURE'
        ud = get(h, 'userdata');
        if ud.currentTexture == 0
            return;
        end
        ud.currentTexture = ud.currentTexture - 1;
        textureGui('REFRESHFIELDS');        
        
        
    case 'CREATE_MAPS'
        ud          = get(h, 'userdata');
        scanNum     = get(ud.handles.scan, 'value');
        structNum   = get(ud.handles.structure, 'value');
        descript    = get(ud.handles.description, 'String');
        numLevels   = str2num(get(ud.handles.numLevels,'string'));
        patchSizeV  = str2num(get(ud.handles.patchSize, 'String'));
        category    = get(ud.handles.featureType, 'value');
        dirctn      = get(ud.handles.direction,'value');
        if get(ud.handles.patchCm, 'value') == 1            
            patchUnit = 'cm';
            [xVals, yVals, zVals] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));      
            deltaX = abs(xVals(1)-xVals(2));
            deltaY = abs(yVals(1)-yVals(2));
            deltaZ = abs(zVals(1)-zVals(2));
            slcWindow = floor(patchSizeV(3)/deltaZ);
            rowWindow = floor(patchSizeV(1)/deltaY);
            colWindow = floor(patchSizeV(2)/deltaX);
            patchSizeV = [rowWindow, colWindow, slcWindow];
        else
            patchUnit = 'vox';
        end
        
        offsetsM = getOffsets(dirctn);
        
        % Create new Texture if ud.currentTexture = 0
        if ud.currentTexture == 0
            initTextureS = initializeCERR('texture');
            initTextureS(1).textureUID = createUID('texture');
            planC{indexS.texture} = dissimilarInsert(planC{indexS.texture},initTextureS);
            ud.currentTexture = length(planC{indexS.texture});
            assocScanUID = planC{indexS.scan}(scanNum).scanUID;
            planC{indexS.texture}(ud.currentTexture).assocScanUID = assocScanUID;            
            assocStrUID = planC{indexS.structures}(structNum).strUID;
            planC{indexS.texture}(ud.currentTexture).assocStructUID = assocStrUID;
            planC{indexS.texture}(ud.currentTexture).category = category;
        end
        
        % Assign parameters based on category of texture
        if category == 1 % Haralick
            direction = get(ud.handles.direction, 'value');
            numGrLevels = str2num(get(ud.handles.numLevels, 'String'));
            entropyFlg = get(ud.handles.entropy, 'value');
            energyFlg = get(ud.handles.energy, 'value');
            sumAvgFlg = get(ud.handles.sumAvg, 'value');
            homogFlg = get(ud.handles.homog, 'value');
            contrastFlg = get(ud.handles.contrast, 'value');
            corrFlg = get(ud.handles.corr, 'value');
            clustShadFlg = get(ud.handles.clustShade, 'value');
            clustPromFlg = get(ud.handles.clustProm, 'value');
            haralickCorrFlg = 0; % Add haralick correlation to GUI.
            
            flagsV = [energyFlg, entropyFlg, sumAvgFlg, corrFlg, homogFlg, ...
                contrastFlg, clustShadFlg, clustPromFlg haralickCorrFlg];
            
            [rasterSegments, planC, isError]    = getRasterSegments(structNum,planC);
            [mask3M, uniqueSlices]              = rasterToMask(rasterSegments, scanNum, planC);
            scanArray3M                         = getScanArray(planC{indexS.scan}(scanNum));
            SUVvals3M                           = mask3M.*double(scanArray3M(:,:,uniqueSlices));
            [minr, maxr, minc, maxc, mins, maxs]= compute_boundingbox(mask3M);
            maskBoundingBox3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);
            volToEval                           = SUVvals3M(minr:maxr,minc:maxc,mins:maxs);
            volToEval(maskBoundingBox3M==0)     = NaN;
            volToEval                           = volToEval / max(volToEval(:));
            %volToEval                           = sqrt(volToEval);
            

            [energy3M,entropy3M,sumAvg3M,corr3M,invDiffMom3M,contrast3M, ...
                clustShade3M,clustPromin3M] = textureByPatchCombineCooccur(volToEval,...
                numLevels,patchSizeV,offsetsM,flagsV,ud.wb.handles.patch);
            
            planC{indexS.texture}(ud.currentTexture).paramS.direction = direction;
            planC{indexS.texture}(ud.currentTexture).paramS.numGrLevels = numGrLevels;
            planC{indexS.texture}(ud.currentTexture).paramS.energyFlag = energyFlg;
            planC{indexS.texture}(ud.currentTexture).paramS.entropyFlag = entropyFlg;
            planC{indexS.texture}(ud.currentTexture).paramS.sumAvgFlag = sumAvgFlg;
            planC{indexS.texture}(ud.currentTexture).paramS.corrFlag = corrFlg;
            planC{indexS.texture}(ud.currentTexture).paramS.homogFlag = homogFlg;
            planC{indexS.texture}(ud.currentTexture).paramS.contrastFlag = contrastFlg;
            planC{indexS.texture}(ud.currentTexture).paramS.clusterShadeFlag = clustShadFlg;
            planC{indexS.texture}(ud.currentTexture).paramS.clusterPromFlag = clustPromFlg;

        elseif category == 2 % Absolute Gradient
            
        elseif category == 3 % Edge
            
        else
            disp('Unknown category')            
        end
                    
        planC{indexS.texture}(ud.currentTexture).description = descript;
        planC{indexS.texture}(ud.currentTexture).patchSize = patchSizeV;
        planC{indexS.texture}(ud.currentTexture).patchUnit = patchUnit;            
        
        % Create Texture Scans  
        [xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(scanNum));
        deltaXYZv = ud.dXYZ;
        zV = zVals(uniqueSlices);
        regParamsS.horizontalGridInterval = deltaXYZv(1);
        regParamsS.verticalGridInterval   = deltaXYZv(2); %(-)ve for dose
        regParamsS.coord1OFFirstPoint   = xVals(minc);
        %regParamsS.coord2OFFirstPoint   = yVals(minr); % for dose
        regParamsS.coord2OFFirstPoint   = yVals(maxr);
        regParamsS.zValues  = zV;
        regParamsS.sliceThickness = [planC{indexS.scan}(scanNum).scanInfo(uniqueSlices).sliceThickness];
        assocTextureUID = planC{indexS.texture}(ud.currentTexture).textureUID;
        %dose2CERR(entropy3M,[], 'entropy3voxls_Ins3_NI14','test','test','non CT',regParamsS,'no',assocScanUID)
        if ~isempty(energy3M)
            planC = scan2CERR(energy3M,'Energy','Passed',regParamsS,assocTextureUID,planC);
        end
        if ~isempty(entropy3M)
            planC = scan2CERR(entropy3M,'Entropy','Passed',regParamsS,assocTextureUID,planC);
        end
        if ~isempty(sumAvg3M)
            planC = scan2CERR(sumAvg3M,'Sum Average','Passed',regParamsS,assocTextureUID,planC);
        end
        if ~isempty(corr3M)
            planC = scan2CERR(corr3M,'Correlation','Passed',regParamsS,assocTextureUID,planC);
        end
        if ~isempty(invDiffMom3M)
            planC = scan2CERR(invDiffMom3M,'Homogenity','Passed',regParamsS,assocTextureUID,planC);
        end
        if ~isempty(contrast3M)
            planC = scan2CERR(contrast3M,'Contrast','Passed',regParamsS,assocTextureUID,planC);
        end
        if ~isempty(clustShade3M)
            planC = scan2CERR(clustShade3M,'Cluster Shade','Passed',regParamsS,assocTextureUID,planC);
        end
        if ~isempty(clustPromin3M)
            planC = scan2CERR(clustPromin3M,'Cluster Prominance','Passed',regParamsS,assocTextureUID,planC);
        end
        
        set(h, 'userdata', ud);
        
        % Refresh Fields
        textureGui('REFRESHFIELDS');
        
        % Refresh the thumbnails
        textureGui('REFRESH_THUMBS')
        
        
    case 'PREVIEWBUTTONDOWN'
        %Button clicked in the preview window.
        ud = get(h, 'userdata');
        ud.previewDown = 1;
        set(h, 'WindowButtonMotionFcn', 'textureGui(''PREVIEWMOTION'')');
        set(h, 'userdata', ud)

    case 'FIGUREBUTTONUP'
        %Mouse up, if in preview window disable motion fcn.
        ud = get(h, 'userdata');
        if ~isfield(ud, 'previewDown') || ud.previewDown == 1;
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
                ud.previewSlice(ud.currentTexture) = ud.previewSlice(ud.currentTexture)+1;%min(ud.previewSlice(ud.currentScan)+1, size(getDoseArray(ud.currentScan), 3));
                set(h, 'userdata', ud);
                textureGui('refreshpreviewandfields');
            elseif ud.previewY < cp(2)
                ud.previewSlice(ud.currentTexture) = ud.previewSlice(ud.currentTexture)-1;%max(ud.previewSlice(ud.currentScan)-1,1);
                set(h, 'userdata', ud);
                textureGui('refreshpreviewandfields');
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

%maxScan = arrayMax(dA);
indexS = planC{end};
maxScan = planC{indexS.scan}(index).scanType;
% 	maxLoc = find(dA == maxScan);
% 	[r,c,s] = ind2sub(size(dA), maxLoc(1));
% set the scan to median of z-values
indexS = planC{end};
[xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(index));
s = ceil(median(1:length(zV)));
thumbImage = dA(:,:,s(1));
imagesc(thumbImage, 'hittest', 'off', 'parent', hAxis);
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
text(x, y, maxScan, 'fontsize', 8, 'color', 'white', 'hittest', 'off', 'parent', hAxis);
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


function dXYZ = getVoxelSize(structNum)
global planC
indexS = planC{end};
scanNum = getStructureAssociatedScan(structNum);
[xV,yV,zV] = getScanXYZVals(planC{indexS.scan}(scanNum));
dx = abs(mean(diff(xV)));
dy = abs(mean(diff(yV)));
dz = abs(mean(diff(zV)));
dXYZ = [dy dx dz];





