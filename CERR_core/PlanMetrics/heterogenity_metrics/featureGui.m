function featureGui(command, varargin)
%"featureGui" GUI
%   Create a GUI to manage featutre set calculation.
%
%   APA 06/25/2017
%
%Usage:
%   featureGui()
%  based on featureGui.m
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
h = findobj('tag', 'featureGui');

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
                'Tag', 'featureGui', 'Color', [.75 .75 .75],...
                'WindowButtonUpFcn', 'featureGui(''FIGUREBUTTONUP'')');
            
            stateS.handle.featureManagementFig = h;
            set(h, 'Name','Feature Calculator');


            %Create pseudo frames.
            axes('Position', [.02 .05 + (rowHeight + .02) .96 .87 - (rowHeight + .02)/2],...
                'color', frameColor, 'ytick',[],'xtick',[], 'box', 'on');
            line([.5 .5], [0 1], 'color', 'black');
            
            axes('Position', [.20 .06 .30 rowHeight-0.02],...
                'color', frameColor, 'ytick',[],'xtick',[], 'box', 'on');
            ud.wb.handles.wbAxis = axes('units', units, 'Position',...
                [.20 .06 .30 rowHeight-0.02], 'color', [.9 .9 .9],...
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
            
            % Get the default Feature Set
            if isempty(planC{indexS.featureSet})
                ud.currenrFeatureSet = 0;
            else
                ud.currenrFeatureSet = 1;
            end
            ud.featureSetBlock = 1;
            set(h, 'userdata', ud);
        end
        featureGui('refresh', h);
        figure(h);

    case 'REFRESHFIELDS'
        %Refresh the field list for the current scan.
        ud = get(h, 'userdata');
        featureSetNum = ud.currenrFeatureSet;
        
        % Default feature set parameters
        scanNum = 1;
        structNum = 1;
        descript = '';
        patchSize = [2,2,2];
        ud.cmFlag = 0;
        
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
        
        featureSetC = {planC{indexS.featureSet}(:).description};        
        
        % Populate values from an existing texture
        if featureSetNum > 0
            set(ud.handles.featureSet, 'String', featureSetC)
            
            scanUID       = planC{indexS.featureSet}(featureSetNum).assocScanUID;
            scanNum       = getAssociatedScan(scanUID);
            structureUID  = planC{indexS.featureSet}(featureSetNum).assocStructUID;
            structNum     = getAssociatedStr(structureUID);
            category      = planC{indexS.featureSet}(featureSetNum).category;
            descript      = planC{indexS.featureSet}(featureSetNum).description;
            patchSize     = planC{indexS.featureSet}(featureSetNum).patchSize;
            patchUnit     = planC{indexS.featureSet}(featureSetNum).patchUnit;
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
                numGrLevels   = planC{indexS.featureSet}(featureSetNum).paramS.numGrLevels;
                directionHar  = planC{indexS.featureSet}(featureSetNum).paramS.direction;
                entropyFlg    = planC{indexS.featureSet}(featureSetNum).paramS.entropyFlag;
                energyFlg     = planC{indexS.featureSet}(featureSetNum).paramS.energyFlag;
                sumAvgFlg     = planC{indexS.featureSet}(featureSetNum).paramS.sumAvgFlag;
                homogFlg      = planC{indexS.featureSet}(featureSetNum).paramS.homogFlag;
                contrastFlg   = planC{indexS.featureSet}(featureSetNum).paramS.contrastFlag;
                corrFlg       = planC{indexS.featureSet}(featureSetNum).paramS.corrFlag;
                clustShadFlg  = planC{indexS.featureSet}(featureSetNum).paramS.clusterShadeFlag;
                clustPromFlg  = planC{indexS.featureSet}(featureSetNum).paramS.clusterPromFlag;
            elseif strcmpi(category,'absGradient')
                directionAbsGr  = planC{indexS.featureSet}(featureSetNum).paramS.direction;
                meanAgrGrFlag = planC{indexS.featureSet}(featureSetNum).paramS.meanAgrGrFlag;
                varAbsGrFlag = planC{indexS.featureSet}(featureSetNum).paramS.varAbsGrFlag;
            elseif strcmpi(category,'edge')
            else
                disp('unknown category')
            end
            
            set(ud.handles.featureSet, 'value',featureSetNum);

        end
        
        set(ud.handles.scan, 'value', scanNum);
        set(ud.handles.structure, 'value', structNum);
        set(ud.handles.description, 'String', descript);
%         patchSizeStr = '';
%         for i = 1:length(patchSize)
%             patchSizeStr = [patchSizeStr, num2str(patchSize(i)), ','];
%         end
%         set(ud.handles.patchSize, 'String',patchSizeStr(1:end-1));
%         if ud.cmFlag        
%             set(ud.handles.patchCm, 'value',1);
%             set(ud.handles.patchVx, 'value',0);
%         else
%             set(ud.handles.patchCm, 'value',0);
%             set(ud.handles.patchVx, 'value',1);
%         end
        
%         set(ud.handles.direction, 'value',directionHar);
%         set(ud.handles.numLevels, 'String',numGrLevels);
%         set(ud.handles.entropy, 'value', entropyFlg);
%         set(ud.handles.energy, 'value', energyFlg);
%         set(ud.handles.sumAvg, 'value', sumAvgFlg);
%         set(ud.handles.homog, 'value', homogFlg);
%         set(ud.handles.contrast, 'value', contrastFlg);
%         set(ud.handles.corr, 'value', corrFlg);
%         set(ud.handles.clustShade, 'value', clustShadFlg);
%         set(ud.handles.clustProm, 'value', clustPromFlg);
        
        
%         scanTypeC = [{'Select Feature Set'}, planC{indexS.scan}.scanType];
%         set(ud.handles.selectFeatureSetForMIM,'string',scanTypeC,...
%             'value',1)        
        
        set(h, 'userdata', ud);
            
    case 'REFRESH'
        %Recreate and redraw the entire featureGui.
        if isempty(h)
            return;
        end

        %Save the current figure so focus can be returned.
        hFig = gcf;

        %Focus on featureGui for the moment.
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
        scansC = cell(1,nScans+1);
        scansC{1} = 'None';
        for i = 1:nScans
            scansC{i+1} = [num2str(i), '.', planC{indexS.scan}(i).scanType];
        end
        
        % List of doses
        nDoses   = length(planC{indexS.dose});
        dosesC = cell(1,nDoses+1);
        dosesC{1} = 'None';
        for i = 1:nDoses
            dosesC{i+1} = [num2str(i), '.', planC{indexS.dose}(i).fractionGroupID];
        end        
                
        % List of Structures
        nStructs  = length(planC{indexS.structures});
        structsC = cell(1,nStructs);
        for i = 1:nStructs
            structsC{i} = [num2str(i), '.', planC{indexS.structures}(i).structureName];
        end
        
        % list of parameters
        paramC{1,1} = 'shape_rcsV';
        paramC{1,2} = num2str(stateS.optS.shape_rcsV);
        paramC{2,1} = 'higherOrder_minIntensity';
        paramC{2,2} = num2str(stateS.optS.higherOrder_minIntensity);
        paramC{3,1} = 'higherOrder_maxIntensity';
        paramC{3,2} = num2str(stateS.optS.higherOrder_maxIntensity);
        paramC{4,1} = 'higherOrder_numGrLevels';
        paramC{4,2} = num2str(stateS.optS.higherOrder_numGrLevels);
        paramC{5,1} = 'higherOrder_patchRadius2dV';
        paramC{5,2} = num2str(stateS.optS.higherOrder_patchRadius2dV);
        paramC{6,1} = 'higherOrder_patchRadius3dV';
        paramC{6,2} = num2str(stateS.optS.higherOrder_patchRadius3dV);
        paramC{7,1} = 'higherOrder_imgDiffThresh';
        paramC{7,2} = num2str(stateS.optS.higherOrder_imgDiffThresh);
        paramC{8,1} = 'peakValley_peakRadius';
        paramC{8,2} = num2str(stateS.optS.peakValley_peakRadius);
        paramC{9,1} = 'ivh_xForIxV';
        paramC{9,2} = num2str(stateS.optS.ivh_xForIxV);
        paramC{10,1} = 'ivh_xAbsForIxV';
        paramC{10,2} = num2str(stateS.optS.ivh_xAbsForIxV);
        paramC{11,1} = 'ivh_xForVxV';
        paramC{11,2} = num2str(stateS.optS.ivh_xForVxV);
        paramC{12,1} = 'ivh_xAbsForVxV';        
        paramC{12,2} = num2str(stateS.optS.ivh_xAbsForVxV);
        
        % List of Directions
        dirsC = {'Co-occurance with 13 directions in 3D',...
            'Left-Right, Ant-Post and Diagonals in 2D', ...
            'Left-Right and Ant-Post', ...
            'Left-Right',...
            'Anterior-Posterior',...
            'Superior-Inferior'};
        
        % List of feature types
        featureTypeC = {'Image', ...
            'Dose',...
            'Image+Dose'
             };
        
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
        
%         % Get scans associated with this feature set
%         for i=1:nScans
%             set(ud.handles.thumbaxis(i), 'ButtonDownFcn', ['featureGui(''CHANGESCAN'', ' num2str(i) ');']);
%             maxScan{i} = num2str(drawThumb(ud.handles.thumbaxis(i), planC, i, h));
%             ud.previewSlice(i) = 1; %%%%%%%%%%%%%%%%%
%         end

        txtLeft = .05;
        textWidth = .1;
        fieldLeft = .27;
        fieldWidth = .20;

        %Make text to describe uicontrols.
        uicontrol(h, 'units',units,'Position',[txtLeft-0.02 1-.16 textWidth rowHeight],'String', 'Feature Set:', 'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'fontSize',10);
        uicontrol(h, 'units',units,'Position',[txtLeft 1-.25 textWidth rowHeight],'String', 'Scan:', 'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor);
        uicontrol(h, 'units',units,'Position',[txtLeft 1-.32 textWidth rowHeight],'String', 'Dose:', 'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor);
        uicontrol(h, 'units',units,'Position',[txtLeft 1-.39 textWidth rowHeight],'String', 'Structure:', 'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor);
        uicontrol(h, 'units',units,'Position',[txtLeft 1-.47 textWidth rowHeight],'String', 'Description:', 'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor);
        uicontrol(h, 'units',units,'Position',[txtLeft 1-.54 textWidth rowHeight],'String', 'Category:', 'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor);
        %uicontrol(h, 'units',units,'Position',[txtLeft 1-.53 textWidth rowHeight],'String', 'Patch Radius:', 'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor);
        %uicontrol(h, 'units',units,'Position',[txtLeft 1-.60 textWidth rowHeight],'String', 'Directionality:', 'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag','haralick');
        %uicontrol(h, 'units',units,'Position',[txtLeft 1-.67 textWidth+0.1 rowHeight],'String', 'Number of Grey Levels:', 'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag','haralick');

        %Make uicontrols for managing the scans, and displaying info.
        structNum = 1;
        ud.handles.featureSet       = uicontrol(h, 'units',units,'Position',[fieldLeft-0.14 1-.15 fieldWidth+0.08 rowHeight-.01],'String',{''}, 'Style', 'popup', 'callback', 'featureGui(''FEATURE_SET_SELECTED'');', 'enable', 'inactive', 'horizontalAlignment', 'right');
        ud.handles.featureSetAdd    = uicontrol(h, 'units',units,'Position',[2*fieldLeft-0.12 1-.15 0.03 rowHeight-.01],'String','+', 'Style', 'push', 'callback', 'featureGui(''CREATE_NEW_FETURE_SET'');', 'horizontalAlignment', 'right');
        ud.handles.featureSetDel    = uicontrol(h, 'units',units,'Position',[2*fieldLeft-0.08 1-.15 0.03 rowHeight-.01],'String','-', 'Style', 'push', 'callback', 'featureGui(''DELETE_FEATURE_SET'');', 'horizontalAlignment', 'right');
        ud.handles.scan          = uicontrol(h, 'units',units,'Position',[fieldLeft-.05 1-.25 fieldWidth+0.05 rowHeight],'String', scansC, 'value', 1,  'Style', 'popup', 'horizontalAlignment', 'right', 'BackgroundColor', frameColor,'callback', 'featureGui(''SCAN_SELECTED'');');
        ud.handles.dose          = uicontrol(h, 'units',units,'Position',[fieldLeft-.05 1-.32 fieldWidth+0.05 rowHeight],'String', dosesC, 'value', 1,  'Style', 'popup', 'horizontalAlignment', 'right', 'BackgroundColor', frameColor,'callback', 'featureGui(''DOSE_SELECTED'');');
        ud.handles.structure     = uicontrol(h, 'units',units,'Position',...
            [fieldLeft-.05 1-.39 fieldWidth+.05 rowHeight],'String', structsC,...
            'value', 1, 'Style', 'popup', 'horizontalAlignment', 'right',...
            'BackgroundColor', frameColor,'callback', 'featureGui(''STRUCT_SELECTED'');');
        ud.handles.description   = uicontrol(h, 'units',units,'Position',[fieldLeft-.05 1-.46 fieldWidth+.05 rowHeight-0.01],'String', '',  'Style', 'edit', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor);
%         ud.handles.patchSize     = uicontrol(h, 'units',units,'Position',[fieldLeft-.05 1-.44 fieldWidth/2+0.05 rowHeight-0.01],'String', '2,2,2',  'Style', 'edit', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor);
%         ud.handles.patchCm       = uicontrol(h, 'units',units,'Position',[fieldLeft+0.11 1-.42 0.11 rowHeight-0.01],'String', 'cm (y,x,z)',  'Style', 'radio', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'callback', 'featureGui(''PATCH_CM_SELECTED'');');
%         ud.handles.patchVx       = uicontrol(h, 'units',units,'Position',[fieldLeft+0.11 1-.46 0.11 rowHeight-0.01],'String', 'vox (r,c,s)',  'Style', 'radio', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'callback', 'featureGui(''PATCH_VOX_SELECTED'');');
        ud.handles.featureType   = uicontrol(h, 'units',units,'Position',[fieldLeft-.05 1-.53 fieldWidth+.05 rowHeight],'String', featureTypeC, 'value', 1, 'Style', 'popup', 'callback', 'featureGui(''FEATURE_TYPE_SELECTED'');', 'horizontalAlignment', 'right', 'BackgroundColor', frameColor);
        ud.handles.featureParams = uitable(h, 'units',units,'Position',[fieldLeft-.22 1-.85 fieldWidth+.22 rowHeight+0.25], 'ColumnName', {'Parameter','Value'},'Data',paramC, 'ColumnWidth', {150,200}, 'ColumnEditable', [false true], 'BackgroundColor', frameColor);
        ud.dXYZ                  = getVoxelSize(structNum);
        
%         % Haralick handles
%         ud.handles.direction     = uicontrol(h, 'units',units,'Position',[fieldLeft-.05 1-.59 fieldWidth+.05 rowHeight],'String', dirsC, 'value', 1, 'Style', 'popup', 'horizontalAlignment', 'right', 'BackgroundColor', frameColor, 'tag', 'haralick');
%         ud.handles.numLevels     = uicontrol(h, 'units',units,'Position',[fieldLeft-.05 1-.65 fieldWidth/2 rowHeight-0.01],'String', '',  'Style', 'edit', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');        
%         ud.handles.entropy       = uicontrol(h, 'units',units,'Position',[0.04 1-.73+0.01 0.02 rowHeight],'String', 'Entropy',  'Style', 'checkbox', 'value', 0, 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
%         ud.handles.entropyTxt    = uicontrol(h, 'units',units,'Position',[0.07 1-.73 0.1 rowHeight],'String', 'Entropy',  'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
%         ud.handles.energy        = uicontrol(h, 'units',units,'Position',[0.18 1-.73+0.01 0.02 rowHeight],'String', '',  'Style', 'checkbox', 'value', 0, 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
%         ud.handles.energyTxt     = uicontrol(h, 'units',units,'Position',[0.21 1-.73 0.1 rowHeight],'String', 'Energy',  'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
%         ud.handles.sumAvg        = uicontrol(h, 'units',units,'Position',[0.32 1-.73+0.01 0.02 rowHeight],'String', '',  'Style', 'checkbox', 'value', 0, 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
%         ud.handles.sumAvgTxt     = uicontrol(h, 'units',units,'Position',[0.35 1-.73 0.1 rowHeight],'String', 'SumAvg',  'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
%         ud.handles.homog         = uicontrol(h, 'units',units,'Position',[0.04 1-.78+0.01 0.02 rowHeight],'String', '',  'Style', 'checkbox', 'value', 0, 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
%         ud.handles.homogTxt      = uicontrol(h, 'units',units,'Position',[0.07 1-.78 0.1 rowHeight],'String', 'Homogenity',  'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
%         ud.handles.contrast      = uicontrol(h, 'units',units,'Position',[0.18 1-.78+0.01 0.02 rowHeight],'String', '',  'Style', 'checkbox', 'value', 0, 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
%         ud.handles.contrastTxt   = uicontrol(h, 'units',units,'Position',[0.21 1-.78 0.1 rowHeight],'String', 'Contrast',  'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
%         ud.handles.corr          = uicontrol(h, 'units',units,'Position',[0.32 1-.78+0.01 0.02 rowHeight],'String', '',  'Style', 'checkbox', 'value', 0, 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
%         ud.handles.corrTxt       = uicontrol(h, 'units',units,'Position',[0.35 1-.78 0.1 rowHeight],'String', 'Correlation',  'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
%         ud.handles.clustShade    = uicontrol(h, 'units',units,'Position',[0.04 1-.83+0.01 0.02 rowHeight],'String', '',  'Style', 'checkbox', 'value', 0, 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
%         ud.handles.clustShadeTxt = uicontrol(h, 'units',units,'Position',[0.07 1-.83 0.12 rowHeight],'String', 'ClusterShade',  'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
%         ud.handles.clustProm     = uicontrol(h, 'units',units,'Position',[0.18 1-.83+0.01 0.02 rowHeight],'String', '',  'Style', 'checkbox', 'value', 0, 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
%         ud.handles.clustPromTxt  = uicontrol(h, 'units',units,'Position',[0.21 1-.83 0.12 rowHeight],'String', 'ClusterProm',  'Style', 'text', 'horizontalAlignment', 'left', 'BackgroundColor', frameColor, 'tag', 'haralick');
        
        % Absolute Gradient handles
        
        % Edge handles
        
        
        % uicontrols to generate or delete texture maps
        ud.handles.createFeatureSets  = uicontrol(h, 'units',units,'Position',[0.03 1-.95 0.15 rowHeight],'String', 'calculate Features', 'Style', 'pushbutton', 'callback', 'featureGui(''CALCULATE_FEATURES'');');
        
        % uicontrols to write texture maps to MIM
%         ud.handles.selectFeatureSetForMIM  = uicontrol(h, 'units',units,'Position',...
%             [.53 .06 .3 rowHeight-0.02],'String', {'Select Texture'}, 'Style',...
%             'popupmenu', 'value',1, 'callback', 'featureGui(''SELECT_MAPS_FOR_MIM'');');
        
%         ud.handles.sendFeatureSetsToMIM  = uicontrol(h, 'units',units,'Position',...
%             [.85 .06 .12 rowHeight-0.02],'String', 'Send to MIM', 'Style',...
%             'pushbutton', 'callback', 'featureGui(''SEND_MAPS_TO_MIM'');');
        
        set(h, 'userdata', ud);
        set(0, 'CurrentFigure', hFig);

        if ~isempty(ud.currenrFeatureSet)
            featureGui('REFRESHFIELDS');
            featureGui('REFRESH_THUMBS');
        end        
        
    case 'STRUCT_SELECTED'
        ud = get(h, 'userdata');
        structNum = get(ud.handles.structure,'value');
        ud.dXYZ   = getVoxelSize(structNum);
        set(h, 'userdata', ud);
        featureGui('REFRESH_THUMBS');
        
    case 'SCAN_SELECTED'
        featureGui('REFRESH_THUMBS');
        
    case 'DOSE_SELECTED'
        
       
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
        
    case 'FEATURE_SET_SELECTED'
        ud = get(h, 'userdata');
        strC = get(gcbo,'String');
        if length(strC) == 1 && strcmpi(strC{1},'')
            return;
        end
        ud.currenrFeatureSet = get(ud.handles.featureSet,'value');
        set(h, 'userdata', ud);
        featureGui('REFRESHFIELDS');
        featureGui('REFRESH_THUMBS');
        
    case 'FEATURE_TYPE_SELECTED'
        
        ud = get(h, 'userdata');
        featureType = get(ud.handles.featureType, 'value');
        harV = findobj(stateS.handle.featureManagementFig,'tag','haralick');
        absGrV = findobj(stateS.handle.featureManagementFig,'tag','absGradient');
        edgV = findobj(stateS.handle.featureManagementFig,'tag','edge');
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
        featureGui('REFRESHFIELDS');   
        
    case 'PREV_BLOCK'
        ud = get(h, 'userdata');
        if ud.featureSetBlock == 1
            return;
        end
        ud.featureSetBlock = ud.featureSetBlock - 1;   
        set(h, 'userdata', ud);
        featureGui('REFRESH_THUMBS')        
        
    case 'NEXT_BLOCK'
        ud = get(h, 'userdata');
        nScans = length(planC{indexS.dose});
        maxDoseBlocks = ceil(nScans/9);
        if ud.featureSetBlock == maxDoseBlocks
            return;
        end
        ud.featureSetBlock = ud.featureSetBlock + 1;     
        set(h, 'userdata', ud);
        featureGui('REFRESH_THUMBS')
                      
    case 'REFRESH_THUMBS'
        
        ud = get(h, 'userdata');
        if isfield(ud.handles,'thumbaxis')
            try %To handle double-clicks on next and previous buttons
                delete(ud.handles.thumbaxis);
            catch
                %return
            end
        end
        
%         % Get Scans associated with this texture        
%         textureC = {planC{indexS.scan}.assocFeatureSetUID};
%         if ud.currenrFeatureSet == 0
%             scansV = [];
%             scanIndV = [];
%             nScans = 0;
%         else
%             scansV = strcmp(textureC,planC{indexS.featureSet}(ud.currenrFeatureSet).featureSetUID);
%             scanIndV = find(scansV);
%             if isempty(scanIndV)
%                 ud.currentScan = 0;
%                 nScans = 0;
%             else
%                 ud.currentScan = scanIndV(1);
%                 nScans = sum(scansV);
%             end
%         end        
        
%         if ~isempty(planC{indexS.featureSet})
%             scanUID = planC{indexS.featureSet}.assocScanUID;
%         end
%         scansV = strcmp({planC{indexS.scan}.scanUID}, scanUID);        
        scansV = get(ud.handles.scan,'value') - 1;        
        if scansV == 0
            return;
        end
        nScans = 1;
        scanIndV = scansV;
        %scansV = (ud.featureSetBlock-1)*9+1:min(nScans,ud.featureSetBlock*9);
        %scansV = 1;
        
        if ud.currentScan > max(scanIndV)
            ud.currentScan = scanIndV(1);
        elseif ud.currentScan < min(scanIndV)
            ud.currentScan = scanIndV(1);
        end        

        %Downsample colormap, redraws much faster.
        %cM = CERRColorMap(stateS.optS.CTColormap);
%         cM = CERRColorMap('starinterp');
%         n  = size(cM, 1);
%         newSize = 32;
%         interval = (n-1) / newSize;
%         b = interp1(1:n, cM(:,1), 1:interval:n);
%         c = interp1(1:n, cM(:,2), 1:interval:n);
%         d = interp1(1:n, cM(:,3), 1:interval:n);
%         ud.cM = [b' c' d'];
        
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
            %set(ud.handles.thumbaxis(i), 'ButtonDownFcn', ['featureGui(''CHANGEDOSE'', ' num2str(scanIndV(i)) ');']);
            set(ud.handles.thumbaxis(i), 'ButtonDownFcn', ['featureGui(''PREVIEWCLICKED'', ' num2str(scanIndV(i)) ');']);
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
        ud.currentScan = varargin{1};
        set(h, 'userdata', ud)
        set(h, 'WindowButtonMotionFcn', 'featureGui(''PREVIEWMOTION'')');
        
    case 'SELECT_MAPS_FOR_MIM'
        
    case 'SEND_MAPS_TO_MIM'
        ud = get(h,'userdata');        
        scanIndex = get(ud.handles.selectFeatureSetForMIM,'value');
        if scanIndex == 1
            return
        end
        strC = get(ud.handles.selectFeatureSetForMIM,'string');
        bridge = evalin('base','bridge');
        vol3M = evalin('base','arr');
        vol3M = vol3M * 0;
        text3M = planC{indexS.scan}(scanIndex).scanArray;
        txtMax = max(text3M(:));        
        rescaleSlope = double(txtMax)/double(intmax('int16'));
        rescaleIntercept = 0;
        text3M = int16(double(text3M)/rescaleSlope);
        structNum = get(ud.handles.structure,'value');
        mask3M = getUniformStr(structNum);
        [minr, maxr, minc, maxc, mins, maxs]= compute_boundingbox(mask3M);
        vol3M(minr:maxr,minc:maxc,mins:maxs) = text3M;
        assignin('base', 'featureSetVol', vol3M);
        sInfo = evalin('base','arr_info');
        newSinfo = sInfo.getMutableCopy();
        newSinfo.setUnits('')
        newSinfo.setCustomName(strC{scanIndex})
        newSinfo.setRescaleSlope(rescaleSlope)
        newSinfo.setRescaleIntercept(rescaleIntercept)
        bridge.sendImageToMim('featureSetVol', newSinfo);
        featureGui('QUIT')

            
    case 'CREATE_NEW_FETURE_SET'
        ud = get(h, 'userdata');
        ud.currenrFeatureSet = 0;
        set(ud.handles.featureSet,'enable', 'on')
        featureGui('REFRESHFIELDS');       
        
        
    case 'DELETE_FEATURE_SET'
        ud = get(h, 'userdata');
        if ud.currenrFeatureSet == 0
            return;
        end
        ud.currenrFeatureSet = ud.currenrFeatureSet - 1;
        featureGui('REFRESHFIELDS');        
        
        
    case 'CREATE_MAPS'
        ud          = get(h, 'userdata');
        scanNum     = get(ud.handles.scan, 'value')-1;
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
            patchUnit = 'vox';
            patchSizeV = [2,2,2];
        else
            patchUnit = 'vox';
        end
        
        offsetsM = getOffsets(dirctn);
        
        % Create new FeatureSet if ud.currenrFeatureSet = 0
        if ud.currenrFeatureSet == 0
            initFeatureSetS = initializeCERR('featureSet');
            initFeatureSetS(1).featureSetUID = createUID('featureSet');
            planC{indexS.featureSet} = dissimilarInsert(planC{indexS.featureSet},initFeatureSetS);
            ud.currenrFeatureSet = length(planC{indexS.featureSet});
            assocScanUID = planC{indexS.scan}(scanNum).scanUID;
            planC{indexS.featureSet}(ud.currenrFeatureSet).assocScanUID = assocScanUID;            
            assocStrUID = planC{indexS.structures}(structNum).strUID;
            planC{indexS.featureSet}(ud.currenrFeatureSet).assocStructUID = assocStrUID;
            planC{indexS.featureSet}(ud.currenrFeatureSet).category = category;
        end
        
        % Assign parameters based on category of featureSet
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
                clustShade3M,clustPromin3M, haralickCorr3M] = textureByPatchCombineCooccur(volToEval,...
                numLevels,patchSizeV,offsetsM,flagsV,ud.wb.handles.patch);
            
            planC{indexS.featureSet}(ud.currenrFeatureSet).paramS.direction = direction;
            planC{indexS.featureSet}(ud.currenrFeatureSet).paramS.numGrLevels = numGrLevels;
            planC{indexS.featureSet}(ud.currenrFeatureSet).paramS.energyFlag = energyFlg;
            planC{indexS.featureSet}(ud.currenrFeatureSet).paramS.entropyFlag = entropyFlg;
            planC{indexS.featureSet}(ud.currenrFeatureSet).paramS.sumAvgFlag = sumAvgFlg;
            planC{indexS.featureSet}(ud.currenrFeatureSet).paramS.corrFlag = corrFlg;
            planC{indexS.featureSet}(ud.currenrFeatureSet).paramS.homogFlag = homogFlg;
            planC{indexS.featureSet}(ud.currenrFeatureSet).paramS.contrastFlag = contrastFlg;
            planC{indexS.featureSet}(ud.currenrFeatureSet).paramS.clusterShadeFlag = clustShadFlg;
            planC{indexS.featureSet}(ud.currenrFeatureSet).paramS.clusterPromFlag = clustPromFlg;
            planC{indexS.featureSet}(ud.currenrFeatureSet).paramS.haralickCorrFlg = haralickCorrFlg;

        elseif category == 2 % Absolute Gradient
            
        elseif category == 3 % Edge
            
        else
            disp('Unknown category')            
        end
                    
        planC{indexS.featureSet}(ud.currenrFeatureSet).description = descript;
        planC{indexS.featureSet}(ud.currenrFeatureSet).patchSize = patchSizeV;
        planC{indexS.featureSet}(ud.currenrFeatureSet).patchUnit = patchUnit;            
        
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
        assocFeatureSetUID = planC{indexS.featureSet}(ud.currenrFeatureSet).featureSetUID;
        %dose2CERR(entropy3M,[], 'entropy3voxls_Ins3_NI14','test','test','non CT',regParamsS,'no',assocScanUID)
        if ~isempty(energy3M)
            planC = scan2CERR(energy3M,'Energy','Passed',regParamsS,assocFeatureSetUID,planC);
        end
        if ~isempty(entropy3M)
            planC = scan2CERR(entropy3M,'Entropy','Passed',regParamsS,assocFeatureSetUID,planC);
        end
        if ~isempty(sumAvg3M)
            planC = scan2CERR(sumAvg3M,'Sum Average','Passed',regParamsS,assocFeatureSetUID,planC);
        end
        if ~isempty(corr3M)
            planC = scan2CERR(corr3M,'Correlation','Passed',regParamsS,assocFeatureSetUID,planC);
        end
        if ~isempty(invDiffMom3M)
            planC = scan2CERR(invDiffMom3M,'Homogenity','Passed',regParamsS,assocFeatureSetUID,planC);
        end
        if ~isempty(contrast3M)
            planC = scan2CERR(contrast3M,'Contrast','Passed',regParamsS,assocFeatureSetUID,planC);
        end
        if ~isempty(clustShade3M)
            planC = scan2CERR(clustShade3M,'Cluster Shade','Passed',regParamsS,assocFeatureSetUID,planC);
        end
        if ~isempty(clustPromin3M)
            planC = scan2CERR(clustPromin3M,'Cluster Prominance','Passed',regParamsS,assocFeatureSetUID,planC);
        end
        if ~isempty(haralickCorr3M)
            planC = scan2CERR(haralickCorr3M,'Haralick Correlation','Passed',regParamsS,assocFeatureSetUID,planC);
        end        
        
        set(h, 'userdata', ud);
        
        % Refresh Fields
        featureGui('REFRESHFIELDS');
        
        % Refresh the thumbnails
        featureGui('REFRESH_THUMBS')
        
    case 'CALCULATE_FEATURES'
        
        firstOrderParamsS = struct;
        higherOrderParamS = struct;
        shapeParamS = struct;
        peakValleyParamS = struct;
        ivhParamS = struct;
        
        shapeParamS.rcsV = [100 100 100]; %stateS.optS.shape_rcsV; %[100, 100, 100];
        paramS.shapeParamS = shapeParamS;
        
        higherOrderParamS.minIntensity = -38; %stateS.optS.higherOrder_minIntensity; %-140;
        higherOrderParamS.maxIntensity = 195; %stateS.optS.higherOrder_maxIntensity; %100;
        higherOrderParamS.numGrLevels = 32; %stateS.optS.higherOrder_numGrLevels; %100;
        higherOrderParamS.patchRadius2dV = [1 1 0]; %stateS.optS.higherOrder_patchRadius2dV; % [1 1 0];
        higherOrderParamS.imgDiffThresh = 0; %stateS.optS.higherOrder_imgDiffThresh; %0;
        higherOrderParamS.patchRadius3dV = [1 1 1]; %stateS.optS.higherOrder_patchRadius3dV; %[1 1 1];
        paramS.higherOrderParamS = higherOrderParamS;
        
        peakValleyParamS.peakRadius = [2 2 0]; %stateS.optS.peakValley_peakRadius; %[2 2 0];
        paramS.peakValleyParamS = peakValleyParamS;
        
        ivhParamS.xAbsForVxV =  -38:10:195; %stateS.optS.ivh_xAbsForIxV; % -140:10:100; % CT;, 0:2:28; % PET
        ivhParamS.xForIxV = 10:10:90; %stateS.optS.ivh_xForIxV; % 10:10:90; % percentage volume
        ivhParamS.xAbsForIxV = 5:10:200; %stateS.optS.ivh_xAbsForIxV; % 10:20:200; % absolute volume [cc]
        ivhParamS.xForVxV = 10:10:90; %stateS.optS.ivh_xForVxV; % 10:10:90; % percent intensity cutoff
        paramS.ivhParamS = ivhParamS;
                
        whichFeatS = struct;
        whichFeatS.shape = 1;
        %whichFeatS.highOrder = 1;
        whichFeatS.harFeat2Ddir = 1;
        whichFeatS.harFeat2Dcomb = 1;
        whichFeatS.harFeat3Ddir = 1;
        whichFeatS.harFeat3Dcomb = 1;
        whichFeatS.rlmFeat2Ddir = 1;
        whichFeatS.rlmFeat2Dcomb = 1;
        whichFeatS.rlmFeat3Ddir = 1;
        whichFeatS.rlmFeat3Dcomb = 1;
        whichFeatS.ngtdmFeatures2d = 1;
        whichFeatS.ngtdmFeatures3d = 1;
        whichFeatS.ngldmFeatures2d = 1;
        whichFeatS.ngldmFeatures3d = 1;
        whichFeatS.szmFeature2d = 1;
        whichFeatS.szmFeature3d = 1;
        whichFeatS.firstOrder = 1;
        whichFeatS.ivh = 1;
        whichFeatS.peakValley = 1;
        paramS.whichFeatS = whichFeatS;
        
        paramS.toQuantizeFlag = 1;


        ud          = get(h, 'userdata');
        scanNum     = get(ud.handles.scan, 'value')-1;
        structNum   = get(ud.handles.structure, 'value');
        descript    = get(ud.handles.description, 'String');    
        paramC = get(ud.handles.featureParams,'Data');
        
        featS = calcGlobalRadiomicsFeatures(scanNum, structNum, ...
            paramS, planC);
        featNum = length(planC{indexS.featureSet}) + 1;
        planC{indexS.featureSet}(featNum).valuesS = featS;
        planC{indexS.featureSet}(featNum).paramS = paramS;
        assocScanUID = planC{indexS.scan}(scanNum).scanUID;
        assocStrUID = planC{indexS.structures}(structNum).strUID;
        planC{indexS.featureSet}(featNum).assocScanUID = assocScanUID;
        planC{indexS.featureSet}(featNum).assocStrUID = assocStrUID;
        planC{indexS.featureSet}(featNum).featureSetUID = createUID('featureSet');
        planC{indexS.featureSet}(featNum).description = descript;
                
        
    case 'PREVIEWBUTTONDOWN'
        %Button clicked in the preview window.
        ud = get(h, 'userdata');
        ud.previewDown = 1;
        set(h, 'WindowButtonMotionFcn', 'featureGui(''PREVIEWMOTION'')',...
            'WindowButtonUpFcn','featureGui(''FIGUREBUTTONUP'')');
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
                %ud.previewSlice(ud.currenrFeatureSet) = ud.previewSlice(ud.currenrFeatureSet)+1;
                ud.previewSlice(ud.currentScan) = ...
                    min(ud.previewSlice(ud.currentScan)+1, size(getScanArray(ud.currentScan), 3));
                set(h, 'userdata', ud);
                %featureGui('refreshpreviewandfields');
            elseif ud.previewY < cp(2)
                %ud.previewSlice(ud.currenrFeatureSet) = ud.previewSlice(ud.currenrFeatureSet)-1;
                ud.previewSlice(ud.currentScan) = ...
                    max(ud.previewSlice(ud.currentScan)-1,1);
                set(h, 'userdata', ud);
                %featureGui('refreshpreviewandfields');
            end
            drawThumb(ud.handles.thumbaxis(ud.currentScan), planC,...
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
        scanNum = ud.currenrFeatureSet;
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
        ud.currenrFeatureSet = newScan;
        set(h, 'userdata', ud);
        featureGui('refreshpreviewandfields');

    case 'NAMEFIELD'
        %Dose name has changed, update in planC.
        ud = get(h, 'userdata');
        scanNum = ud.currenrFeatureSet;
        oldString = planC{indexS.scan}(scanNum).scanType;
        string = get(gcbo, 'string');
        planC{indexS.scan}(scanNum).scanType = string;
        statusString = ['Renamed scan number ' num2str(scanNum) ' from ''' oldString ''' to ''' string '''.'];
        featureGui('status', statusString);

    case 'STATUS'
        %Display passed string in status bar.
        statusString = varargin{1};
        ud = get(gcbf, 'userdata');
        h = ud.handles.status;
        set(h, 'string', statusString);

    case 'COMPRESS'
        %Compress/decompress selected scan.
        ud = get(h, 'userdata');
        scanNum = ud.currenrFeatureSet;
        scanName = planC{indexS.scan}(scanNum).scanType;

        if ~isCompressed(planC{indexS.scan}(scanNum).scanArray)
            statusString = ['Compressing scan number ' num2str(scanNum) ', ''' scanName ''' please wait...'];
            featureGui('status', statusString);
            planC{indexS.scan}(scanNum).scanArray = compress(getScanArray(scanNum, planC));
            drawThumb(ud.handles.thumbaxis(scanNum), planC, scanNum, h);
            statusString = ['Compressed scan number ' num2str(scanNum)  ', ''' scanName '''.'];
            featureGui('status', statusString);
            set(ud.handles.compbutton, 'string', 'Decompress');
        else
            statusString = ['Decompressing scan number ' num2str(scanNum) ', ''' scanName ''', please wait...'];
            featureGui('status', statusString);
            %Use getScanArray and not decompress to use the cached value.
            planC{indexS.scan}(scanNum).scanArray = getScanArray(scanNum, planC);
            maxScan = drawThumb(ud.handles.thumbaxis(scanNum), planC, scanNum, h);
            %Update the maxScans value, but be sure to get a fresh ud since
            %a user could have clicked during compression.
            ud = get(h, 'userdata');
            ud.maxScans{scanNum} = num2str(maxScan);
            set(h, 'userdata', ud);
            statusString = ['Decompressed scan number ' num2str(scanNum)  ', ''' scanName '''.'];
            featureGui('status', statusString);
            set(ud.handles.compbutton, 'string', 'Compress');
        end
        featureGui('refreshpreviewandfields');

    case 'REMOTE'
        %Make/unmake selected dose remote.
        ud = get(h, 'userdata');
        scanNum = ud.currenrFeatureSet;
        scanName = planC{indexS.scan}(scanNum).scanType;

        scanUID = planC{indexS.scan}(scanNum).scanUID;

        if isLocal(planC{indexS.scan}(scanNum).scanArray)
            statusString = ['Writing to disk scan number ' num2str(scanNum) ', ''' scanName ''' please wait...'];
            featureGui('status', statusString);
            [fpath,fname] = fileparts(stateS.CERRFile);
            planC{indexS.scan}(scanNum).scanArray = setRemoteVariable(getScanArray(scanNum, planC), 'LOCAL',fullfile(fpath,[fname,'_store']),['scanArray_',scanUID,'.mat']);
            % Also make remote the scanArraySuperior and scanArrayInferior matrices
            planC{indexS.scan}(scanNum).scanArraySuperior = setRemoteVariable(getScanArraySuperior(scanNum, planC), 'LOCAL',fullfile(fpath,[fname,'_store']),['scanArraySuperior_',scanUID,'.mat']);
            planC{indexS.scan}(scanNum).scanArrayInferior = setRemoteVariable(getScanArrayInferior(scanNum, planC), 'LOCAL',fullfile(fpath,[fname,'_store']),['scanArrayInferior_',scanUID,'.mat']);
            drawThumb(ud.handles.thumbaxis(scanNum), planC, scanNum, h);
            statusString = ['Wrote to disk scan number ' num2str(scanNum)  ', ''' scanName '''.'];
            featureGui('status', statusString);
            set(ud.handles.remotebutton, 'string', 'Use Memory');
            uiwait(msgbox(['scanArray stored in folder ',fullfile(fpath,[fname,'_store']),'. Note the Location'],'modal'));
        else
            statusString = ['Reading from disk scan number ' num2str(scanNum) ', ''' scanName ''', please wait...'];
            featureGui('status', statusString);

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
            featureGui('status', statusString);
            set(ud.handles.remotebutton, 'string', 'Use Disk');

            %Update the maxDoses value, but be sure to get a fresh ud since
            %a user could have clicked during remote writing to disk.
            ud = get(h, 'userdata');
            ud.maxScans{scanNum} = num2str(maxScan);
            set(h, 'userdata', ud);
        end
        featureGui('refreshpreviewandfields');

    case 'SAVE'
        %Open dialog to save dose array as .mat file.
        ud = get(h, 'userdata');
        scanNum = ud.currenrFeatureSet;
        scanName = planC{indexS.scan}(scanNum).scanType;
        [filename, pathname] = uiputfile('*.mat', ['Save (uncompressed) scan array number ' num2str(scanNum) ' as:']);
        if filename==0
            return;
        end
        scan3D = getScanArray(scanNum, planC);
        save(fullfile(pathname, filename), 'scan3D');
        statusString = ['Saved scan number ' num2str(scanNum) ', ''' scanName ''' to ' [filename '.mat'] '.'];
        featureGui('status', statusString);

    case 'DELETE'
        %Delete selected scan.  If being displayed, verify deletion with user.
        ud = get(h, 'userdata');
        scanNum = ud.currenrFeatureSet;
        scanName = planC{indexS.scan}(scanNum).scanType;

        refreshViewer = 0;
        axesV = checkDisplayedScans(scanNum);
        if ~isempty(axesV)
            choice = questdlg('One or more CERR axes are currently displaying this scan.  If you delete it, these axes will be set to display no scan.  Proceed?', 'Continue?', 'Continue', 'Abort', 'Continue');
            if strcmpi(choice, 'Abort')
                statusString = ['Delete aborted.'];
                featureGui('status', statusString);
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
            featureGui('status', statusString);
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
            featureGui;
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
            featureGui('status', statusString);
            return;
        end

        if isCompress | isRemote
            statusString = ['Rescaling compressed or remote dose can take a moment, please wait...'];
            featureGui('status', statusString);
        end

        %Perform the rescale.
        dA = dA *  (1/maxDose * newMaxDose);

        planC = setDoseArray(doseNum, dA, planC);
        statusString = ['Rescaled dose number ' num2str(doseNum) ', ''' doseName ''' from [0 ' num2str(maxDose) '] Gy to [0 ' num2str(newMaxDose) '] Gy.'];
        ud.maxDoses{doseNum} = num2str(newMaxDose);
        set(h, 'userdata', ud);
        featureGui('status', statusString);

    case 'QUIT'
        close;
end

function nBytes = getByteSize(data)
%"getByteSize"
%Returns the number of bytes in the passed data
infoStruct = whos('data');
nBytes = infoStruct.bytes;

function maxScan = drawThumb(hAxis, planC, index, hFigure,slcNum)
%"drawThumb"

if exist('slcNum','var')
    s = slcNum;
else
    s = [];    
end

% Get the structure mask
h = findobj('tag', 'featureGui');
ud = get(h, 'userdata');
structNum = get(ud.handles.structure,'value');
rasterSegsM = getRasterSegments(structNum, planC);
[mask3M, uniqueSlicesV] = rasterToMask(rasterSegsM, index, planC);
if isempty(s)
    s = uniqueSlicesV(1);
end
if uniqueSlicesV(1) > s(1) || uniqueSlicesV(end) < s(1)
    return
end

%In passed dose array, find slice with highest dose and draw in hAxis.
%Also denote the index in the corner.  If compressed show compressed.
set(hFigure, 'CurrentAxes', hAxis);
toDelete = get(hAxis, 'children');
delete(toDelete);

% Get the dose array and its compression state.
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
% if exist('slcNum','var')
%     s = slcNum;
% else
%     s = ceil(median(1:length(zV)));    
% end
% maxScan = [maxScan,' ',num2str(s),'/',num2str(length(uniqueSlicesV))];

% % Get the structure mask
% h = findobj('tag', 'featureGui');
% ud = get(h, 'userdata');
% structNum = get(ud.handles.structure,'value');
% rasterSegsM = getRasterSegments(structNum, planC);
% [mask3M, uniqueSlicesV] = rasterToMask(rasterSegsM, index, planC);
% if uniqueSlicesV(1) > s(1)
%     return
% end
slc = find(uniqueSlicesV == s(1));
maskM = mask3M(:,:,slc);
sumRowV = sum(maskM,1);
sumColV = sum(maskM,2);
jMin = find(sumRowV,1,'first');
jMax = find(sumRowV,1,'last');
iMin = find(sumColV,1,'first');
iMax = find(sumColV,1,'last');
scanM = single(dA(iMin:iMax,jMin:jMax,s(1))) .* single(maskM(iMin:iMax,jMin:jMax));
maxScan = [maxScan,' ',num2str(slc),'/',num2str(length(uniqueSlicesV))];

% thumbImage = dA(:,:,s(1));
thumbImage = scanM;
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

