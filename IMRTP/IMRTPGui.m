function varargout = IMRTPGui(command, varargin)
%"IMRTPGui" GUI
%   Create a GUI to calculate IM structures.
%
%   JRA 4/30/04
%
%Usage:
%   Have a plan open in CERR and type IMRTPGui at Matlab prompt.
%
% Last modified:
%  JJW 07/05/06: added field sigma_100; changed names for QIB DoseTerm
%  APA 10/16/06: updates to workflow. See CVS log for details. 
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

%Globals.
global planC stateS
indexS = planC{end};

%Use a static window size, by pixels.  Do not allow resizing.
screenSize = get(0,'ScreenSize');
y = 600;
x = 796; %800+263  %936 for half
x = 811;
MCBarWidth = 136;

units = 'pixels';

%Determine what algorithms are available.
algorithms = {};
algDefault = '';
if VMCPresent
    algorithms = {algorithms{:}, 'VMC++'};
    algDefault = 'VMC++';
    %     x = 950;
end
if DPMPresent
    algorithms = {algorithms{:}, 'DPM'};
    algDefault = 'DPM';
end
if QIBPresent
    algorithms = {algorithms{:}, 'QIB'};
    algDefault = 'QIB';
end

%If no command given, default to init.
if ~exist('command') || isempty(command)
    command = 'init';
end

%Find handle of the gui figure.
% h = findobj('tag', 'IMRTPGui');
h = stateS.handle.IMRTMenuFig;

%Fields and background info for beam parameters.
fieldNames = {{'beamNum'}, {'beamModality'}, {'beamEnergy'}, {'isocenter', 'x'}, {'isocenter', 'y'}, {'isocenter', 'z'}, ...
    {'isodistance'}, {'arcAngle'}, {'couchAngle'}, {'collimatorAngle'}, {'gantryAngle'}, {'beamDescription'}, ...
    {'beamletDelta_x'}, {'beamletDelta_y'}, {'dateOfCreation'}, {'beamType'}, ...
    {'zRel'}, {'xRel'}, {'yRel'}, {'sigma_100'}};

% fieldDefaults = {beamNum, 'photons', 18, planC{indexS.scan}.scanInfo(1).xOffset, planC{indexS.scan}.scanInfo(1).yOffset, 0, 100, 0, 0, 0, ...
%              0, 'IMRTP test', 1, 1, 5, date, 'QIB', 'IM', 0, IM.beams(beamNum).isodistance * sindeg(IM.beams(beamNum).gantryAngle), IM.beams(beamNum).isodistance * cosdeg(IM.beams(beamNum).gantryAngle)};
fieldIsEditable = [0, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 0, 0, 1];
fieldIsNum      = [1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 0, 0, 1, 1, 1, 1];
fieldChoices = {{}, {'photons'}, {6,15,18}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {'IM'}, {}, {}, {}, {}};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%QIB params
paramNames = {{'algorithm'}, {'DoseTerm'}, {'ScatterMethod'}, {'Scatter', 'Threshold'}, {'Scatter', 'RandomStep'}, {'xyDownsampleIndex'}, {'numCTSamplePts'}, {'cutoffDistance'}};
paramIsEditable = [1, 1, 1, 1, 1, 1, 1, 1];
paramIsNum = [0, 0, 0, 1, 1, 1, 1, 1];
%paramChoices = {algorithms, {'primary','primary+scatter','scatter','GaussPrimary', 'GaussPrimary+scatter'}, {'random', 'threshold', 'exponential'}, {}, {}, {} ,{}, {}};
paramChoices = {algorithms, {'primary','nogauss+scatter','scatter','GaussPrimary', 'GaussPrimary+scatter'}, {'random', 'threshold', 'exponential'}, {}, {}, {} ,{}, {}};
paramDefaults = {algDefault, 'GaussPrimary+scatter', 'exponential', .01, 30, 1, 300, 4};

MCparamNames = {{'NumParticles'}, {'NumBatches'}, {'scoreDoseToWater'}, {'includeError'}, {'monoEnergy'}, {'spectrum'}, {'repeatHistory'}, {'splitPhotons'}, {'photonSplitFactor'}, {'base'}, {'dimension'}, {'skip'}};
MCparamIsEditable = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1];
MCparamIsNum = [1, 1, 0, 0, 1, 0, 1, 0, 1, 1, 1, 1];
MCparamChoices = {{}, {}, {'Yes', 'No'}, {'Yes', 'No'}, {}, {}, {}, {'Yes', 'No'}, {}, {}, {}, {}};
MCparamDefaults = {50000, 10, 'Yes', 'No', [], '', 0.251, 'Yes', -40, 2, 60, 1};

%QIB params
DPMparamNames = {{'algorithm'}, {'DoseTerm'}, {'ScatterMethod'}, {'Scatter', 'Threshold'}, {'Scatter', 'RandomStep'}, {'xyDownsampleIndex'}, {'numCTSamplePts'}, {'cutoffDistance'}};
DPMparamIsEditable = [1, 1, 1, 1, 1, 1, 1, 1];
DPMparamIsNum = [0, 0, 0, 1, 1, 1, 1, 1];
%paramChoices = {algorithms, {'primary','primary+scatter','scatter','GaussPrimary', 'GaussPrimary+scatter'}, {'random', 'threshold', 'exponential'}, {}, {}, {} ,{}, {}};
DPMparamChoices = {algorithms, {'primary','nogauss+scatter','scatter','GaussPrimary', 'GaussPrimary+scatter'}, {'random', 'threshold', 'exponential'}, {}, {}, {} ,{}, {}};
DPMparamDefaults = {algDefault, 'GaussPrimary+scatter', 'exponential', .01, 30, 1, 300, 4};


%Test if ud.ip.paramSet exists.
try
    ud = get(h, 'userdata');
    ud.ip.paramSet;
catch
    ud.ip.paramSet = 1; %Use param set 1, QIB, as the default.
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Default structure values.
% goalFields = {{'structNum'}, {'structName'}, {'isTarget'}, {'PBMargin'}, {'xySampleRate'}};
goalFields = {{'structNum'}, {'strUID'}, {'structName'}, {'isTarget'}, {'PBMargin'}, {'xySampleRate'}};
goalDefaults = {1, [], '', 'no', 0, 2};

gridUnits = planC{indexS.scan}(1).scanInfo(1).grid1Units;

switch upper(command)
    case 'INIT'
        %If gui doesnt exist, create it, else refresh it.
        if isempty(h)
            %Set up a new GUI window.
            h = figure('doublebuffer', 'on', 'units', 'pixels', 'position',[(screenSize(3)-x)/2 (screenSize(4)-y)/2 x y], 'MenuBar', 'none', 'NumberTitle', 'off', 'resize', 'off', 'Tag', 'IMRTPGui','WindowButtonUpFcn', 'IMRTPGui(''FIGUREBUTTONUP'')','closeRequestFcn','IMRTPGui(''exit'');');
            stateS.handle.IMRTMenuFig = h;
            set(h, 'Name','IMRTP');

            %Beam list frame, "bl" for short.
            blX = 10; blY = 337; blW = 253; blH = 253;
            hTmp = uicontrol(h, 'style', 'frame', 'units', units, 'position', [blX blY blW blH], 'enable', 'inactive');
            uicontrol(h, 'style', 'text', 'units', units, 'position', [blX blY+blH - 15 50 15], 'string', 'Beams', 'fontweight', 'bold');
            uicontrol(h, 'style', 'text', 'units', units, 'position', [blX+130 blY+blH-4 - 15 100 15], 'string', 'Beam''s Eye View', 'fontweight', 'bold');
            ud.bl.currentBeam = 0;
            %%

            %Beam geometry pseudo frame, "bg" for short.
            bgX = 273; bgY = 337; bgW = 253; bgH = 253;
            frameColor = get(hTmp, 'BackgroundColor');
            axes('units', units, 'Position', [bgX bgY bgW bgH], 'color', frameColor, 'ytick',[],'xtick',[], 'box', 'on', 'parent', h);
            uicontrol(h, 'style', 'text', 'units', units, 'position', [bgX bgY+bgH - 15 115 15], 'string', 'Geometry Preview', 'fontweight', 'bold');
            %Also create the axis to contain the preview, bgAxis.
            ud.bg.bgAxis = axes('units', units, 'Position', [bgX+15 bgY+15 bgW-30 bgH-30], 'color', 'black', 'ytick',[],'xtick',[], 'box', 'on', 'buttondownfcn', 'IMRTPGui(''previewAxisButtonDown'')', 'parent', h);
            sizeDim = planC{indexS.scan}(1).scanInfo(1).sizeOfDimension1;
            %Draw a circle radius 100 to represent beam positions.
            x = sin(0:2*pi/359:2*pi)*100/gridUnits;
            y = cos(0:2*pi/359:2*pi)*100/gridUnits;
            line(x,y, 'color', 'yellow', 'parent', ud.bg.bgAxis);
            hold on;
            %Prepare image of CT thumb in middle of axis, make invisible.
            ud.bg.handles.image = imagesc([-sizeDim/2 sizeDim/2], [-sizeDim/2 sizeDim/2], flipud(planC{indexS.scan}(1).scanArray(:,:,1)), 'visible', 'off', 'hittest', 'off', 'parent', ud.bg.bgAxis);
            ud.bg.handles.errText = text(0,0,{'An isocenterZ value is' 'outside the CT bounds.'}, 'visible', 'off', 'hittest', 'off', 'parent', ud.bg.bgAxis, 'color', 'white', 'horizontalalignment', 'center');
            ud.bg.sliceNum = 0;
            hold off;
            colormap gray;
            axis equal;
            ud.bg.previewDown = 0;
            ud.bg.axisCenterX = [bgX+15+(bgW-30)/2];
            ud.bg.axisCenterY = [bgY+15+(bgH-30)/2];
            %%

            %Structure selection frame, "ss" for short.
            %ssX = 536; ssY = 280; ssW = 268; ssH = 275;
            ssX = 536; ssY = 336; ssW = 268; ssH = 220;
            ud.ss.ssX = ssX; ud.ss.ssY = ssY; ud.ss.ssW = ssW; ud.ss.ssH = ssH;
            uicontrol(h, 'style', 'frame', 'units', units, 'position', [ssX ssY ssW ssH]);
            uicontrol(h, 'style', 'text', 'units', units, 'position', [ssX ssY+ssH - 15 65 15], 'string', 'Structures', 'fontweight', 'bold');
            ud.ss.sliderH = uicontrol(h, 'style', 'slider', 'units', units, 'position', [ssX+ssW-15 ssY 15 ssH-50],'min',7,'max',max(7+1,length(planC{indexS.structures})),'value',max(7+1,length(planC{indexS.structures})),'callBack','IMRTPGui(''REFRESHSTRUCTS'')');
            %%

            %Scan selection frame (based on structure frame position)
            uicontrol(h, 'style', 'frame', 'units', units, 'position', [ssX ssY+ssH+10 ssW 25]);
            uicontrol(h, 'style', 'text', 'units', units, 'position', [ssX ssY+ssH + 20 65 15], 'string', 'Select Scan', 'fontweight', 'bold');

            %IMParams frame, "ip" for short.
            %ipX = 536; ipY = 10; ipW = 268; ipH = 260;
            ipX = 536; ipY = 130; ipW = 268; ipH = 196;
            ud.ip.ipX = ipX; ud.ip.ipY = ipY; ud.ip.ipW = ipW; ud.ip.ipH = ipH;
            uicontrol(h, 'style', 'frame', 'units', units, 'position', [ipX ipY ipW ipH]);
            uicontrol(h, 'style', 'text', 'units', units, 'position', [ipX ipY+ipH - 15 90 15], 'string', 'IM Parameters', 'fontweight', 'bold');
            %%

            %Update Selection frame, "us" for short.
            %ipX = 536; ipY = 10; ipW = 268; ipH = 260;
            usX = 536; usY = 10; usW = 268; usH = 50;
            ud.usX = usX; ud.usY = usY; ud.usW = usW; ud.usH = usH;
            uicontrol(h, 'style', 'frame', 'units', units, 'position', [usX usY usW usH]);
            uicontrol(h, 'style', 'text', 'units', units, 'position', [usX usY+usH - 15 30 15], 'string', 'File', 'fontweight', 'bold');
            %%

            %IM Browser frame, "ib" for short.
            %ipX = 536; ipY = 10; ipW = 268; ipH = 260;
            ibX = 536; ibY = 70; ibW = 268; ibH = 50;
            ud.ibX = ibX; ud.ibY = ibY; ud.ibW = ibW; ud.ibH = ibH;
            uicontrol(h, 'style', 'frame', 'units', units, 'position', [ibX ibY ibW ibH]);
            uicontrol(h, 'style', 'text', 'units', units, 'position', [ibX ibY+ibH - 15 105 15], 'string', 'IM Dosimetry set', 'fontweight', 'bold');
            %%

            %Beam parameter frame, "bp" for short.
            bpX = 10; bpY = 70; bpW = 516; bpH = 257;
            ud.bp.bpX = bpX; ud.bp.bpY = bpY; ud.bp.bpW = bpW; ud.bp.bpH = bpH;
            uicontrol(h, 'style', 'frame', 'units', units, 'position', [bpX bpY bpW bpH]);
            uicontrol(h, 'style', 'text', 'units', units, 'position', [bpX bpY+bpH - 15 110 15], 'string', 'Beam Parameters', 'fontweight', 'bold');
            %%

            %MonteCarlo Params frame, "mc" for short.
            %mcX = 799; mcY = 10; mcW = 126; mcH = 580;
            mcX = 814; mcY = 10; mcW = 126; mcH = 580;
            ud.mc.mcX = mcX; ud.mc.mcY = mcY; ud.mc.mcW = mcW; ud.mc.mcH = mcH;
            uicontrol(h, 'style', 'frame', 'units', units, 'position', [mcX mcY mcW mcH]);
            uicontrol(h, 'style', 'text', 'units', units, 'position', [mcX mcY+mcH - 15 45 15], 'string', 'VMC Parameters', 'fontweight', 'bold');
            %%

            %Waitbar pseudoframe, "wb" for short.
            wbX = 10; wbY = 10; wbW = 516; wbH = 50;
            ud.wb.wbX = wbX; ud.wb.wbY = wbY; ud.wb.wbW = wbW; ud.wb.wbH = wbH;
            axes('units', units, 'Position', [wbX wbY+1 wbW-1 wbH-1], 'color', frameColor, 'ytick',[],'xtick',[], 'box', 'on', 'parent', h);
            uicontrol(h, 'style', 'text', 'units', units, 'position', [wbX wbY+wbH - 15 50 15], 'string', 'Status', 'fontweight', 'bold');
            %Waitbar axis, part of wb.
            ud.wb.handles.wbAxis = axes('units', units, 'Position', [wbX+10 wbY+10 wbW-20 15], 'color', [.9 .9 .9], 'ytick',[],'xtick',[], 'box', 'on', 'xlimmode', 'manual', 'ylimmode', 'manual', 'parent', h);
            ud.wb.handles.patch = patch([0 0 0 0], [0 1 1 0], 'red', 'parent', ud.wb.handles.wbAxis);
            ud.wb.handles.percent = text(.5, .45, '', 'parent', ud.wb.handles.wbAxis, 'horizontalAlignment', 'center');
            ud.wb.handles.text = uicontrol(h, 'style', 'text', 'units', units, 'position', [wbX+50 wbY+wbH - 21 wbW-100 15], 'string', '');
            %%

            %Create 'new', 'equispaced', 'delete' beam buttons.
            uicontrol(h, 'style', 'pushbutton', 'units', units, 'position', [blX+10 blY+5 71 20], 'string', 'New', 'horizontalAlignment', 'left', 'callback', 'IMRTPGui(''newBeam'')');
            uicontrol(h, 'style', 'pushbutton', 'units', units, 'position', [blX+91 blY+5 71 20], 'string', 'Equispaced', 'horizontalAlignment', 'left', 'callback', 'IMRTPGui(''newEquispaced'')');
            uicontrol(h, 'style', 'pushbutton', 'units', units, 'position', [blX+172 blY+5 71 20], 'string', 'Delete', 'horizontalAlignment', 'left', 'callback', 'IMRTPGui(''delBeam'')');
            %%

            %Create beam list controls, hide them.
            %             for i=1:10
            %                 ud.bl.handles.numTxt(i)   = uicontrol(h, 'enable', 'inactive', 'style', 'text', 'units', units, 'position', [blX+10 blY+blH - 20 - 20*(i) 15 15], 'userdata', i, 'horizontalAlignment', 'left', 'string', [num2str(i) '.'], 'visible', 'off');
            %                 ud.bl.handles.nameTxt(i)  = uicontrol(h, 'enable', 'inactive', 'style', 'text', 'units', units, 'position', [blX+30 blY+blH - 20 - 20*(i) 90 15], 'userdata', i, 'horizontalAlignment', 'center', 'visible', 'off', 'buttondownfcn', 'IMRTPGui(''SELECTBEAM'')');
            %             end
            %             for i = 11:20
            %                 ud.bl.handles.numTxt(i)   = uicontrol(h, 'enable', 'inactive', 'style', 'text', 'units', units, 'position', [blX+blW/2+10 blY+blH - 20 - 20*(i-10) 15 15], 'userdata', i, 'horizontalAlignment', 'left', 'string', [num2str(i) '.'], 'visible', 'off');
            %                 ud.bl.handles.nameTxt(i)  = uicontrol(h, 'enable', 'inactive', 'style', 'text', 'units', units, 'position', [blX+blW/2+30 blY+blH - 20 - 20*(i-10) 90 15], 'userdata', i, 'horizontalAlignment', 'center', 'visible', 'off', 'buttondownfcn', 'IMRTPGui(''SELECTBEAM'')');
            %             end
            
            for beamSet = 1:5
                for i=1:10
                    ud.bl.handles.numTxt((beamSet-1)*10+i)   = uicontrol(h, 'enable', 'inactive', 'style', 'text', 'units', units, 'position', [blX+10 blY+blH - 20 - 20*(i) 15 15], 'userdata', (beamSet-1)*10+i, 'horizontalAlignment', 'left', 'string', [num2str((beamSet-1)*10+i) '.'], 'visible', 'off');
                    ud.bl.handles.nameTxt((beamSet-1)*10+i)  = uicontrol(h, 'enable', 'inactive', 'style', 'text', 'units', units, 'position', [blX+30 blY+blH - 20 - 20*(i) 90 15], 'userdata', (beamSet-1)*10+i, 'horizontalAlignment', 'center', 'visible', 'off', 'buttondownfcn', 'IMRTPGui(''SELECTBEAM'')');
                    ud.bl.handles.bevChk((beamSet-1)*10+i)  = uicontrol(h, 'enable', 'on', 'style', 'check', 'units', units, 'position', [blX+130 blY+blH - 20 - 20*(i) 20 15], 'userdata', (beamSet-1)*10+i, 'horizontalAlignment', 'center', 'visible', 'off', 'callBack', ['IMRTPGui(','''BEVCHK'',',num2str(i),')']);
                    ud.bl.handles.bevType((beamSet-1)*10+i)  = uicontrol(h, 'enable', 'on', 'style', 'popup', 'string',{'Entire jaw-opening','Leaf-sequences','Beamlet-Weights'}, 'fontsize',7, 'units', units, 'position', [blX+150 blY+blH+5 - 20 - 20*(i) 80 10], 'userdata', (beamSet-1)*10+i, 'horizontalAlignment', 'center', 'visible', 'off', 'callBack', 'sliceCallBack(''REFRESH'')');
                end
            end
            ud.bl.sliderH = uicontrol(h, 'style', 'slider', 'units', units, 'position', [blX+blW/2+110 blY+blH-220 15 200],'min',0,'max',4,'value',4,'callBack','IMRTPGui(''REFRESHBEAMS'')','sliderstep',[0.2 0.2]);            
            %%
            
            %Create text and fields for beam parameters.
            %Field width and height.
            bpFieldW = (bpW - 30)/4; bpFieldH = 20;
            ud.bp.isAuto = ~fieldIsEditable;
            ud.bp.handles = [];
            for i = 1:length(fieldNames)
                col = floor(i/12);
                row = mod(i-1,11)+1;
                colspac = 2*bpFieldW+10;
                fgColor = [0 0 0];
                fName = fieldNames{i};
                boxStyle = 'edit';
                choices = '';
                if ~isempty(fieldChoices{i})
                    boxStyle = 'popupmenu';
                    choices = fieldChoices{i};
                end
                ud.bp.handles = setfield(ud.bp.handles, [[fName{:}] '_txt'], uicontrol(h, 'style', 'text', 'units', units, 'position', [bpX+10+colspac*col bpY+bpH-27-(20*row) bpFieldW bpFieldH], 'string', [fName{:}], 'horizontalAlignment', 'left'));
                ud.bp.handles = setfield(ud.bp.handles, [[fName{:}] '_val'], uicontrol(h, 'style', boxStyle, 'units', units, 'position', [bpX+10+bpFieldW+colspac*col bpY+bpH-27-(20*row) bpFieldW bpFieldH], 'string', choices, 'horizontalAlignment', 'left', 'tag', ['IMGui.' [fName{:}]], 'foregroundcolor', fgColor,  'userdata', i, 'callback', 'IMRTPGui(''BEAMPARAMCHANGED'')', 'enable', 'inactive'));
                if ~fieldIsEditable(i)
                    ud.bp.handles = setfield(ud.bp.handles, [[fName{:}] '_box'], uicontrol(h, 'style', 'checkbox', 'units', units, 'position', [bpX+10+bpFieldW+colspac*col-18 bpY+bpH-27-(20*row) 15 bpFieldH], 'value', 1, 'userdata', i, 'callback', 'IMRTPGui(''AUTOCHECKCHANGED'')'));
                end
            end
            col = 1;row = 12;
            %uicontrol(h, 'style', 'text', 'units', units, 'position', [bpX+10+colspac*col bpY-10+20*row bpFieldW*2 bpFieldH], 'string', 'Checkboxes toggle auto field calculation.', 'horizontalAlignment', 'center');
            uicontrol(h, 'style', 'text', 'units', units, 'position', [bpX+120 bpY-10+20*row bpFieldW*2 bpFieldH], 'string', 'Checkboxes toggle auto field calculation.', 'horizontalAlignment', 'left');

            % Create scan pulldown menu
            for i = 1:length(planC{indexS.scan})
                scanList{i} = [num2str(i), ' ', planC{indexS.scan}(i).scanType];
            end
            ud.ss.handles.selScanPop = uicontrol(h, 'style', 'popupmenu', 'units', units, 'position', [ssX+ssW - 126 ssY + ssH + 18 111 15], 'string', scanList, 'value', 1, 'horizontalAlignment', 'left', 'callback', 'IMRTPGui(''SELSCAN'')');

            %Create structure pulldown menu.
            [assocScansV, relStructNumV] = getStructureAssociatedScan(1:length(planC{indexS.structures}), planC);
            structsInScanS = planC{indexS.structures}(assocScansV==1);
            strList = {structsInScanS.structureName};
            ud.ss.handles.addStructPop = uicontrol(h, 'style', 'popupmenu', 'units', units, 'position', [ssX+ssW - 126 ssY + ssH - 25 111 15], 'string', strList, 'horizontalAlignment', 'left', 'callback', 'IMRTPGui(''ADDGOAL'')');

            %Create structure column headers.
            uicontrol(h, 'style', 'text', 'units', units, 'position', [ssX+10 ssY+ssH - 60 100 15], 'string', 'Index / Name', 'horizontalAlignment', 'left');
            uicontrol(h, 'style', 'text', 'units', units, 'position', [ssX+110 ssY+ssH - 60 100 15], 'string', 'isTarg', 'horizontalAlignment', 'left');
            uicontrol(h, 'style', 'text', 'units', units, 'position', [ssX+145 ssY+ssH - 60 30 15], 'string', 'marg', 'horizontalAlignment', 'left');
            uicontrol(h, 'style', 'text', 'units', units, 'position', [ssX+180 ssY+ssH - 60 50 15], 'string', 'sampRate', 'horizontalAlignment', 'left');

            %Create all uicontrols for structures, making them invisible.
            % maxDispStructs = 12; %Maximum # of structs that can be displayed at once.
            % APA: get number of structures in planC
            maxDispStructs = length(planC{indexS.structures});
            maxDispStructs = 3*maxDispStructs; % assume each structure will be repeated thrice! (cannot be more than that)
            for i = 1:maxDispStructs
                ud.ss.handles.nameTxt(i)   = uicontrol(h, 'style', 'text', 'units', units, 'position', [ssX+10 ssY+ssH - 60 - 20*(i) 100 15], 'userdata', i, 'horizontalAlignment', 'left', 'visible', 'off');
                ud.ss.handles.istargBox(i) = uicontrol(h, 'style', 'checkbox', 'units', units, 'position', [ssX+120 ssY+ssH - 60 - 20*(i) 15 15], 'userdata', i, 'horizontalAlignment', 'center', 'callback', 'IMRTPGui(''TARGBOXCLICKED'');', 'visible', 'off');
                ud.ss.handles.marginTxt(i) = uicontrol(h, 'style', 'edit', 'units', units, 'position', [ssX+145 ssY+ssH - 60 - 20*(i) 30 20], 'userdata', i, 'horizontalAlignment', 'center', 'callback', 'IMRTPGui(''PBMARGINTEXT'');', 'visible', 'off');
                ud.ss.handles.sampTxt(i)   = uicontrol(h, 'style', 'edit', 'units', units, 'position', [ssX+185 ssY+ssH - 60 - 20*(i) 30 20], 'userdata', i, 'horizontalAlignment', 'center', 'callback', 'IMRTPGui(''STRSAMPLERATE'');','visible', 'off');
                ud.ss.handles.delBut(i)    = uicontrol(h, 'style', 'pushbutton', 'units', units, 'position', [ssX+225 ssY+ssH - 60 - 20*(i) 20 20], 'string', '-', 'userdata', i, 'horizontalAlignment', 'center', 'callback', 'IMRTPGui(''DELGOAL'');', 'visible', 'off');
            end
            ud.ss.position.nameTxt = get(ud.ss.handles.nameTxt,'position');
            ud.ss.position.istargBox = get(ud.ss.handles.istargBox,'position');
            ud.ss.position.marginTxt = get(ud.ss.handles.marginTxt,'position');
            ud.ss.position.sampTxt = get(ud.ss.handles.sampTxt,'position');
            ud.ss.position.delBut = get(ud.ss.handles.delBut,'position');

            %             %Create buttons for Params.
            %             ud.ip.handles.load = uicontrol(h, 'style', 'pushbutton', 'units', units, 'position', [ipX+10 ipY+10 111 20], 'string', 'Load IMSetup File', 'horizontalAlignment', 'center', 'callback', 'IMRTPGui(''LOADIM'');');
            %             ud.ip.handles.save = uicontrol(h, 'style', 'pushbutton', 'units', units, 'position', [ipX+131 ipY+40 111 20], 'string', 'Save to Plan', 'horizontalAlignment', 'center', 'callback', 'IMRTPGui(''SAVEIM'');');
            %             ud.ip.handles.exit = uicontrol(h, 'style', 'pushbutton', 'units', units, 'position', [ipX+131 ipY+10 111 20], 'string', 'Exit', 'horizontalAlignment', 'center', 'callback', 'IMRTPGui(''EXIT'');');
            %             ud.ip.handles.run  = uicontrol(h, 'style', 'pushbutton', 'units', units, 'position', [ipX+10 ipY+40 111 20], 'string', 'Run Problem', 'horizontalAlignment', 'center', 'fontWeight', 'bold', 'callback', 'IMRTPGui(''RUNIMRT'');');
            %             %Create buttons for Update.
            %             ud.ip.handles.load = uicontrol(h, 'style', 'pushbutton', 'units', units, 'position', [usX+10 usY+4 120 18], 'string', 'Update & overwrite', 'horizontalAlignment', 'center', 'callback', 'IMRTPGui(''LOADIM'');');
            %             ud.ip.handles.save = uicontrol(h, 'style', 'pushbutton', 'units', units, 'position', [usX+135 usY+27 120 18], 'string', 'Save new', 'horizontalAlignment', 'center', 'callback', 'IMRTPGui(''SAVEIM'');');
            %             ud.ip.handles.exit = uicontrol(h, 'style', 'pushbutton', 'units', units, 'position', [usX+135 usY+4 120 18], 'string', 'Overwrite', 'horizontalAlignment', 'center', 'callback', 'IMRTPGui(''EXIT'');');
            %             ud.ip.handles.run  = uicontrol(h, 'style', 'pushbutton', 'units', units, 'position', [usX+10 usY+27 120 18], 'string', 'Update & save new', 'horizontalAlignment', 'center', 'fontWeight', 'normal', 'callback', 'IMRTPGui(''RUNIMRT'');');
            
            fileStr = {'Recompute & add dosimetry','Recompute & overwrite dosimetry','Copy/Add dosimetry w/o calc.','Overwrite dosimetry w/o calc.','Revert to Original'};
            ud.ip.handles.file  = uicontrol(h, 'style', 'popupmenu', 'units', units, 'position', [usX+10 usY+15 150 20], 'string', fileStr, 'horizontalAlignment', 'center', 'fontWeight', 'normal');
            ud.ip.handles.go  = uicontrol(h, 'style', 'pushbutton', 'units', units, 'position', [usX+170 usY+26 30 20], 'string', 'Go', 'horizontalAlignment', 'center', 'fontWeight', 'normal', 'callback', 'IMRTPGui(''SAVE'');');
            ud.ip.handles.exit = uicontrol(h, 'style', 'pushbutton', 'units', units, 'position', [usX+220 usY+26 40 20], 'string', 'Show', 'horizontalAlignment', 'center', 'callback', 'IMRTPGui(''ShowDose'');');
            ud.ip.handles.exit = uicontrol(h, 'style', 'pushbutton', 'units', units, 'position', [usX+190 usY+4 40 20], 'string', 'Exit', 'horizontalAlignment', 'center', 'callback', 'IMRTPGui(''EXIT'');');

            %Create buttons for Browser.
            ud.ib.handles.browse = uicontrol(h, 'style', 'popupmenu', 'units', units, 'position', [ibX+10 ibY+12 100 18], 'string', {''}, 'value',1, 'horizontalAlignment', 'left', 'callback', 'IMRTPGui(''BROWSEIM'');');
            ud.ib.handles.remoteIM = uicontrol(h, 'style', 'pushbutton', 'units', units, 'position', [ibX+115 ibY+25 60 15], 'string', 'Remote', 'horizontalAlignment', 'center', 'callback', 'IMRTPGui(''REMOTEIM'');');
            ud.ib.handles.deleteIM = uicontrol(h, 'style', 'pushbutton', 'units', units, 'position', [ibX+115 ibY+2 40 20], 'string', 'Delete', 'horizontalAlignment', 'center', 'callback', 'IMRTPGui(''DELETEIM'');');
            uicontrol(h, 'style', 'text', 'units', units, 'position', [ibX+180 ibY+25 60 18], 'string', 'Rename', 'horizontalAlignment', 'center');
            ud.ib.handles.rename = uicontrol(h, 'style', 'edit', 'units', units, 'position', [ibX+160 ibY+2 100 25], 'string', '', 'horizontalAlignment', 'center', 'callback', 'IMRTPGui(''RENAMEIM'');');

            %             %Create buttons for Params.
            for i=1:8 %length(paramNames)
                ud.ip.handles.name(i) = uicontrol(h, 'style', 'text', 'units', units, 'position', [ipX+10 ipY+ipH-25-i*20 111 20], 'userdata', i, 'horizontalAlignment', 'left', 'string', '');
                ud.ip.handles.val(i)  = uicontrol(h, 'style', 'edit', 'units', units, 'position', [ipX+10+121 ipY+ipH-25-i*20 111 20], 'userdata', i, 'string', choices, 'string', '', 'horizontalAlignment', 'left', 'callback', 'IMRTPGui(''IMPARAMCHANGED'');');
            end

            %Create MC fields/parameters.
            for i=1:13 %length(paramNames)
                ud.mc.handles.name(i) = uicontrol(h, 'style', 'text', 'units', units, 'position', [mcX+10 mcY-5+mcH-i*40 111 20], 'userdata', i, 'horizontalAlignment', 'left', 'string', '');
                ud.mc.handles.val(i)  = uicontrol(h, 'style', 'edit', 'units', units, 'position', [mcX+10 mcY+mcH-i*40-20 111 20], 'userdata', i, 'string', '', 'horizontalAlignment', 'left', 'callback', 'IMRTPGui(''MCPARAMCHANGED'');');
            end

        end

        try
            delete(ud.bg.beamLines)
            ud.bg.beamLines = [];
        end

        hBeamLine = findobj('tag','beamLine');
        delete(hBeamLine)
        
        for i=1:length(ud.bl.handles.numTxt)
            set(ud.bl.handles.bevChk(i),'value',0)
            set(ud.bl.handles.bevType(i),'value',1)
        end
        set(ud.bl.sliderH,'value',4)
        
        ud.saveIndex = 0;
        set(h, 'userdata', ud);
        if nargin > 1
            ud.IM = varargin{1};
            ud.saveIndex = varargin{2};
            ud.bl.currentBeam = 1;            
            IMpos = varargin{2};
        else
            ud.IM = initIMRTProblem;
            ud.IM.beams(1) = [];
            %ud.IM.goals(1) = [];
            ud.IM.goals = createDefaultStr(goalFields, goalDefaults);
            ud.IM.goals(1) = [];
            %ud.IM.beamlets(1) = [];
            ud.bl.currentBeam = 0;
            ud.IM.assocScanUID = planC{indexS.scan}(1).scanUID;
            IMpos = 1;
            ud.IM.name = ['IM doseSet ',num2str(length(planC{indexS.IM})+1)];
            ud.IM.isFresh = 1; %assume beamlets are fresh for a start
            namesList = paramNames;
            defaultList = paramDefaults;
            for i = 1:length(namesList)
                pN = namesList{i};
                ud.IM.params = setfield(ud.IM.params, pN{:}, defaultList{i});
            end

            namesList = MCparamNames;
            defaultList = MCparamDefaults;
            for i = 1:length(namesList)
                pN = namesList{i};
                ud.IM.params.VMC = setfield(ud.IM.params.VMC, pN{:}, defaultList{i});
            end

        end
        
        % Check for remoteness of IM
        if ~isempty(ud.IM.beams) && ~isLocal(ud.IM.beams(1).beamlets)
            set(ud.ib.handles.remoteIM,'string','Memory')
        end
        
        set(h, 'userdata', ud);
        
        %reset status/wait bar
        IMRTPGui('statusbar','')
        IMRTPGui('waitbar',0)

        %make structure uicontrols invisible before refreshing
        set(ud.ss.handles.nameTxt, 'visible', 'off');
        set(ud.ss.handles.istargBox, 'visible', 'off');
        set(ud.ss.handles.marginTxt, 'visible', 'off');
        set(ud.ss.handles.sampTxt, 'visible', 'off');
        set(ud.ss.handles.delBut, 'visible', 'off');


        figure(h);
        drawnow
        %Maybe implement these if we load IM from beginning
        IMRTPGui('REFRESHBEAMS');
        IMRTPGui('REFRESHSSCAN');
        IMRTPGui('REFRESHSTRUCTS');
        IMRTPGui('REFRESHPREVIEW');
        IMRTPGui('REFRESHBEAMPARAMS');
        IMRTPGui('REFRESHIMPARAMS');
        IMRTPGui('REFRESHMCPARAMS');
        IMRTPGui('REFRESHBROWSER');

        if ~VMCPresent
            IMRTPGui('STATUSBAR', 'VMC files missing. VMC calcuations disabled. See Help for details.')
        end
        if ~QIBPresent
            IMRTPGui('STATUSBAR', 'QIB files missing. QIB calcuations disabled. See Help for details.')
        end
        if ~VMCPresent & ~QIBPresent
            helpdlg({'Both QIB and VMC files are missing, no IMRT calculations are possible.',...
                '',...
                'The QIB algorithm in CERR''s IMRT Calculation secton requires four',...
                'large files that are not distributed in the default package.  This',...
                'is done to keep downloads small for users who do not require these',...
                'files.  To get the QIB matrices, go to:',...
                '',...
                'http://radium.wustl.edu/CERR/QIB.php',...
                '',...
                'and download the zip file located there. Extract the files contained',...
                'in the archive to the CERR\IMRTP\QIBData directory.',...
                '',...
                '',...
                'The VMC++ algorithm in CERR''s IMRT Calculation secton requires an',...
                'executable that is not distributed in the default package.  This',...
                'executable should be acquired from Iwan Kawrakow <iwan@irs.phy.nrc.ca>',...
                'of the Institute for National Measurement Standards in Canada.',...
                '',...
                'Extract the VMC package to the CERR\IMRTP\vmc++ directory',...
                'to use it with CERR.'});

            %IMRTPGui('exit');
            delete(h)
        end


    case 'SELSCAN'

        ud = get(h, 'userdata');
        if getAssociatedScan(ud.IM.assocScanUID) == get(gcbo,'value');
            return;
        else
            ud.IM.assocScanUID = planC{indexS.scan}(get(gcbo,'value')).scanUID;
            [assocScansV, relStructNumV] = getStructureAssociatedScan(1:length(planC{indexS.structures}), planC);
            structsInScanS = planC{indexS.structures}(assocScansV == get(gcbo,'value'));
            strList = {structsInScanS.structureName};
            set(ud.ss.handles.addStructPop,'string', strList, 'value',1)
            ud.IM.goals(1:end) = [];
            set(ud.ss.handles.nameTxt,'visible','off')
            set(ud.ss.handles.istargBox,'visible','off')
            set(ud.ss.handles.marginTxt,'visible','off')
            set(ud.ss.handles.sampTxt,'visible','off')
            set(ud.ss.handles.delBut,'visible','off')
            %delete all beamlets
            for i=1:length(ud.IM.beams)
                ud.IM.beams(i).beamlets = [];
                ud.IM.beams(i).beamUID = createUID('BEAM');
            end            
            set(h, 'userdata', ud);
            IMRTPGui('REFRESHSTRUCTS');
        end

    case 'ADDGOAL'
        %Add a goal to the IM, and refresh the GUI.
        relStrNum  = get(gcbo, 'value');
        ud      = get(h, 'userdata');

        nG = length(ud.IM.goals);
        nG = nG + 1;

        %Create a default goal.
        goal = createDefaultStr(goalFields, goalDefaults);

        %The actual adding to the IM.
        % add structNum for backward compatibility in case of single scan.
        % add relative structure number since we need to display only
        % single scan in CERR2
        goal.structNum    = relStrNum;
        % APA use strUID instead of structNum
        [assocScansV, relStructNumV] = getStructureAssociatedScan(1:length(planC{indexS.structures}), planC);
        structsInScanS = planC{indexS.structures}(assocScansV==getAssociatedScan(ud.IM.assocScanUID));
        goal.strUID    = structsInScanS(relStrNum).strUID;
        %goal.structName   = planC{indexS.structures}(strNum).structureName;
        goal.structName   = structsInScanS(relStrNum).structureName;

        %Use dissimilarInsert in case field order is mismatched.
        if isfield(ud, 'IM') & isfield(ud.IM, 'goals')
            if length(ud.IM.goals)>=1
                ud.IM.goals = dissimilarInsert(ud.IM.goals, goal, nG);
            else
                ud.IM.goals = goal;
            end
        else
            ud.IM.goals(nG) = goal;
        end

        set(h, 'name', 'IMRTP *(beamlets may be stale)')

        set(h, 'userdata', ud);
        IMRTPGui('REFRESHSTRUCTS');

    case 'DELGOAL'
        %Delete a goal from the IM and refresh.
        goalNum = get(gcbo, 'userdata');
        ud = get(h, 'userdata');
        nGolas = length(ud.IM.goals);
        ud.IM.goals(goalNum) = [];
        %delete beamlets associated with this goal
        for beamNum = 1:length(ud.IM.beams)
            if goalNum <= size(ud.IM.beams(beamNum).beamlets,1)
                ud.IM.beams(beamNum).beamlets(goalNum,:) = [];
            end
        end
        set(h, 'name', 'IMRTP *(beamlets may be stale)')
        set(h, 'userdata', ud);
        % set the last goal to invisible since all goals are to be shifted
        % by 1
        set(ud.ss.handles.nameTxt(nGolas),'visible','off')
        set(ud.ss.handles.istargBox(nGolas),'visible','off')
        set(ud.ss.handles.marginTxt(nGolas),'visible','off')
        set(ud.ss.handles.sampTxt(nGolas),'visible','off')
        set(ud.ss.handles.delBut(nGolas),'visible','off')
        IMRTPGui('REFRESHSTRUCTS');

    case 'PBMARGINTEXT'
        %PB Margin edited, update IM and refresh.
        goalNum = get(gcbo, 'userdata');
        val = get(gcbo, 'string');
        ud = get(h, 'userdata');
        ud.IM.goals(goalNum).PBMargin = str2double(val);
        %delete beamlets for this structure whose PBMargin changed
        for beamNum = 1:length(ud.IM.beams)
            ud.IM.beams(beamNum).beamlets = [];
        end
        set(h, 'name', 'IMRTP *(beamlets may be stale)')
        set(h, 'userdata', ud);
        IMRTPGui('REFRESHSTRUCTS');

    case 'STRSAMPLERATE'
        %Str samplerate edited, update IM and refresh.
        goalNum = get(gcbo, 'userdata');
        val = get(gcbo, 'string');
        ud = get(h, 'userdata');
        ud.IM.goals(goalNum).xySampleRate = str2double(val);
        %delete beamlets for this structure whose sampleRate changed
        for beamNum = 1:length(ud.IM.beams)
            ud.IM.beams(beamNum).beamlets = [];
        end
        set(h, 'name', 'IMRTP *(beamlets may be stale)')
        set(h, 'userdata', ud);
        IMRTPGui('REFRESHSTRUCTS');

    case 'TARGBOXCLICKED'
        %isTarget box has been clicked, updated IM and refresh.
        goalNum = get(gcbo, 'userdata');
        val = get(gcbo, 'value');
        ud = get(h, 'userdata');
        if val == 1;
            ud.IM.goals(goalNum).isTarget = 'Yes';
        else
            ud.IM.goals(goalNum).isTarget = 'No';
        end
        %delete beamlets for which isocenter is computed based on target
        %structures
        for beamNum = 1:length(ud.IM.beams)
            if any(strcmpi({ud.IM.beams(beamNum).isocenter.x,ud.IM.beams(beamNum).isocenter.y,ud.IM.beams(beamNum).isocenter.z},'COM'))
                ud.IM.beams(beamNum).beamlets = [];
            end
        end
        set(h, 'name', 'IMRTP *(beamlets may be stale)')
        set(h, 'userdata', ud);
        IMRTPGui('REFRESHSTRUCTS');

    case 'REFRESHSSCAN'
        ud = get(h, 'userdata');
        IM = ud.IM;
        scanNum = getAssociatedScan(IM.assocScanUID);
        if isempty(scanNum)
            IMRTPGui('Statusbar','Associated Scan has Changed !')
        else
            set(ud.ss.handles.selScanPop,'value',scanNum)
            %Create structure pulldown menu.
            [assocScansV, relStructNumV] = getStructureAssociatedScan(1:length(planC{indexS.structures}), planC);
            structsInScanS = planC{indexS.structures}(assocScansV==scanNum);
            strList = {structsInScanS.structureName};
            set(ud.ss.handles.addStructPop, 'string', strList);
        end

    case 'REFRESHSTRUCTS'
        %Draw the structure list based on the IM.goals in ud.
        ud = get(h, 'userdata');
        IM = ud.IM;
        nG = length(ud.IM.goals);
        nGui = length(ud.ss.handles.nameTxt);
        maxStructVis = 7;

        if nG<=maxStructVis
            % set original positions
            set(ud.ss.handles.nameTxt,{'position'},ud.ss.position.nameTxt);
            set(ud.ss.handles.istargBox,{'position'},ud.ss.position.istargBox);
            set(ud.ss.handles.marginTxt,{'position'},ud.ss.position.marginTxt);
            set(ud.ss.handles.sampTxt,{'position'},ud.ss.position.sampTxt);
            set(ud.ss.handles.delBut,{'position'},ud.ss.position.delBut);
            set(ud.ss.sliderH,'enable','off')
            strVal = nG;
            strToMakeVis = 1:nG;
        else
            set(ud.ss.sliderH,'enable','on')
            if gcbo == ud.ss.handles.addStructPop
                val = maxStructVis;
            else
                val = max(maxStructVis,get(ud.ss.sliderH,'value'));
                val = round(min(val,nG));
            end
            set(ud.ss.sliderH,'value',val,'max',nG,'sliderstep',[1/ceil(nG/maxStructVis) 1/ceil(nG/maxStructVis)])
            strVal = maxStructVis+nG-val;
            if strVal<=maxStructVis
                strToMakeInvis = maxStructVis+1:nG;
                strToMakeVis = 1:maxStructVis;
            else
                strToMakeInvis = 1:nGui;
                strToMakeInvis(strVal-maxStructVis+1:strVal) = [];
                strToMakeVis = strVal-maxStructVis+1:strVal;
            end

            set(ud.ss.handles.nameTxt(strToMakeVis),'visible','on')
            set(ud.ss.handles.istargBox(strToMakeVis),'visible','on')
            set(ud.ss.handles.marginTxt(strToMakeVis),'visible','on')
            set(ud.ss.handles.sampTxt(strToMakeVis),'visible','on')
            set(ud.ss.handles.delBut(strToMakeVis),'visible','on')

            set(ud.ss.handles.nameTxt(strToMakeInvis),'visible','off')
            set(ud.ss.handles.istargBox(strToMakeInvis),'visible','off')
            set(ud.ss.handles.marginTxt(strToMakeInvis),'visible','off')
            set(ud.ss.handles.sampTxt(strToMakeInvis),'visible','off')
            set(ud.ss.handles.delBut(strToMakeInvis),'visible','off')

            % set correct position of visible handles
            set(ud.ss.handles.nameTxt(strToMakeVis),{'position'},ud.ss.position.nameTxt(1:maxStructVis))
            set(ud.ss.handles.istargBox(strToMakeVis),{'position'},ud.ss.position.istargBox(1:maxStructVis))
            set(ud.ss.handles.marginTxt(strToMakeVis),{'position'},ud.ss.position.marginTxt(1:maxStructVis))
            set(ud.ss.handles.sampTxt(strToMakeVis),{'position'},ud.ss.position.sampTxt(1:maxStructVis))
            set(ud.ss.handles.delBut(strToMakeVis),{'position'},ud.ss.position.delBut(1:maxStructVis))
        end

        %Populate what GUI elements we can, up to nGui.
        % for i = 1:min(nG, nGui)
        %Populate all selected GUI elements.
        for i = strToMakeVis
            if strcmpi(IM.goals(i).isTarget, 'yes')
                isTarg = 1;
            else
                isTarg = 0;
            end
            structIndStr  = num2str(getAssociatedStr(IM.goals(i).strUID));
            if isempty(structIndStr)
                bgColor = get(stateS.handle.IMRTMenuFig,'color');
                structIndStr = 'N-A';
            else
                bgColor = getColor(getAssociatedStr(IM.goals(i).strUID), stateS.optS.colorOrder);
            end
            strName = [structIndStr,'.  ',IM.goals(i).structName];
            if length(strName)>20
                strName = strName(1:20);
            end
            set(ud.ss.handles.nameTxt(i), 'string', strName, 'BackgroundColor', bgColor, 'visible', 'on');
            set(ud.ss.handles.istargBox(i), 'value', isTarg, 'visible', 'on');
            set(ud.ss.handles.marginTxt(i), 'string', num2str(IM.goals(i).PBMargin), 'visible', 'on');
            set(ud.ss.handles.sampTxt(i), 'string', num2str(IM.goals(i).xySampleRate), 'visible', 'on');
            set(ud.ss.handles.delBut(i), 'visible', 'on');
        end

    case 'SELECTBEAM'
        %A new beam has been selected, update currentBeam & viewer.
        ud = get(h, 'userdata');
        beamNum = get(gcbo, 'userdata');
        ud.bl.currentBeam = beamNum;
        set(h, 'userdata', ud);
        IMRTPGui('REFRESHBEAMS');
        IMRTPGui('REFRESHPREVIEW');
        IMRTPGui('REFRESHBEAMPARAMS');

    case 'REFRESHBEAMS'
        %Update the list of beams to reflect ud.IM.
        ud = get(h, 'userdata');
        IM = ud.IM;
        nB = length(IM.beams);
        nGui = length(ud.bl.handles.nameTxt);
        cB = ud.bl.currentBeam;
        set(ud.bl.sliderH,'value',round(get(ud.bl.sliderH,'value')));
        beamGroup = 4-get(ud.bl.sliderH,'value');
        
        set(ud.bl.handles.numTxt, 'visible', 'off');
        set(ud.bl.handles.nameTxt, 'visible', 'off');
        set(ud.bl.handles.bevChk, 'visible', 'off');
        set(ud.bl.handles.bevType, 'visible', 'off');
        
        %for i = 1:min(nB, nGui) %only draw what we can.
        for i = beamGroup*10+1:min(nB, (beamGroup+1)*10) %only draw what we can.
            if cB == i
                bgColor = [1 1 1]; fgColor = [0 0 0];
            else
                bgColor = [0 0 0]; fgColor = [1 1 1];
            end
            set(ud.bl.handles.numTxt(i), 'visible', 'on');
            set(ud.bl.handles.nameTxt(i), 'string', IM.beams(i).beamDescription, 'BackgroundColor', bgColor, 'visible', 'on', 'ForegroundColor', fgColor, 'buttondownfcn', 'IMRTPGui(''SELECTBEAM'')');
            set(ud.bl.handles.bevChk(i), 'visible', 'on');
            set(ud.bl.handles.bevType(i), 'visible', 'on');
        end
%         for i = nB+1:nGui
%             set(ud.bl.handles.numTxt(i), 'visible', 'off');
%             set(ud.bl.handles.nameTxt(i), 'visible', 'off');
%         end

    case 'PREVIEWAXISBUTTONDOWN'
        %Preview axis has been clicked on, while mousebtn is down use
        %previewmotion to interpret mouse movement.
        ud = get(h, 'userdata');
        set(h, 'WindowButtonMotionFcn', 'IMRTPGui(''PREVIEWMOTION'')');
        set(h, 'userdata', ud)
        IMRTPGui('PREVIEWMOTION');

    case 'PREVIEWMOTION'
        %Current beam is being dragged update gantry angle and preview.
        ud = get(h, 'userdata');
        cp = get(h, 'currentpoint');
        cB = ud.bl.currentBeam;
        if(cB == 0)
            return;
        end
        angle = atan((cp(1) - ud.bg.axisCenterX) / (cp(2) - ud.bg.axisCenterY)) / (2*pi) * 360;
        if (cp(2) - ud.bg.axisCenterY) < 0
            angle = angle + 180;
        elseif (cp(1) - ud.bg.axisCenterX) < 0
            angle = angle + 360;
        end
        angle = floor(angle);

        sourceX = cos((360 - angle+90)/360*2*pi);
        sourceY = sin((360 - angle+90)/360*2*pi);
        oppX1 = cos((360 - angle+90+175)/360*2*pi);
        oppY1 = sin((360 - angle+90+175)/360*2*pi);
        oppX2 = cos((360 - angle+90+185)/360*2*pi);
        oppY2 = sin((360 - angle+90+185)/360*2*pi);

        try
            delete(ud.bg.beamLines(cB));
        end
        ud.bg.beamLines(cB) = line([oppX1 sourceX oppX2]*100/gridUnits, [oppY1 sourceY, oppY2]*100/gridUnits, 'parent', ud.bg.bgAxis, 'hittest', 'off', 'color', 'white');
        ud.IM.beams(cB).gantryAngle = angle;

        %delete beamlets since they are no longer valid
        ud.IM.beams(cB).beamlets = [];

        set(h, 'name', 'IMRTP *(beamlets may be stale)')

        set(h, 'userdata', ud);
        IMRTPGui('REFRESHBEAMPARAMS')

    case 'REFRESHPREVIEW'
        %Refresh the beam preview lines and CT thumbnail.
        ud = get(h, 'userdata');
        nB = length(ud.IM.beams);
        try
            delete(ud.bg.beamLines);
            ud.bg.beamlines = [];
        end
        for i = 1:nB
            angle = ud.IM.beams(i).gantryAngle;
            isocenterz = ud.IM.beams(i).isocenter.z;
            scanNum = getAssociatedScan(ud.IM.assocScanUID);
            [xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(scanNum));
            if isocenterz > max(zVals) | isocenterz < min(zVals)
                inRange = 0;
            else
                inRange = 1;
            end
            if ~isempty(isocenterz) & ~strcmpi(isocenterz, 'com')
                [jnk, sliceNum] = min(abs(zVals - isocenterz));
                if ud.bg.sliceNum ~= sliceNum & inRange;
                    set(ud.bg.handles.image, 'cdata', flipud(planC{indexS.scan}(scanNum).scanArray(:,:,sliceNum)), 'visible', 'on');
                    set(ud.bg.handles.errText, 'visible', 'off');
                    ud.bg.sliceNum = sliceNum;
                elseif ~inRange
                    set(ud.bg.handles.image, 'visible', 'off');
                    set(ud.bg.handles.errText, 'visible', 'on');
                end
            end
            if isempty(angle)
                return;
            end
            sourceX = cos((360 - angle+90)/360*2*pi);
            sourceY = sin((360 - angle+90)/360*2*pi);
            oppX1 = cos((360 - angle+90+175)/360*2*pi);
            oppY1 = sin((360 - angle+90+175)/360*2*pi);
            oppX2 = cos((360 - angle+90+185)/360*2*pi);
            oppY2 = sin((360 - angle+90+185)/360*2*pi);
            try
                delete(ud.bg.beamLines(i));
            end
            xCoords = [oppX1 sourceX oppX2];
            yCoords = [oppY1 sourceY oppY2];
            if ud.bl.currentBeam == i;
                %Save data for currentBeam so it can be drawn last and thus
                %on top.
                xBack = xCoords;
                yBack = yCoords;
                ind = i;
            else
                ud.bg.beamLines(i) = line(xCoords*100/gridUnits, yCoords*100/gridUnits, 'parent', ud.bg.bgAxis, 'hittest', 'off', 'color', 'blue');
            end
        end
        if exist('ind')
            ud.bg.beamLines(ind) = line(xBack*100/gridUnits, yBack*100/gridUnits, 'parent', ud.bg.bgAxis, 'hittest', 'off', 'color', 'white');
        end
        set(h, 'userdata', ud);

    case 'FIGUREBUTTONUP'
        %Exit preview refresh mode, mouse is no longer held down.
        ud = get(h, 'userdata');
        ud.bg.previewDown = 0;
        set(h, 'WindowButtonMotionFcn', '');
        ud.isFresh = 0;
        IMRTPGui('BEVCHK',ud.bl.currentBeam)

    case 'NEWBEAM'
        %Create a new beam in the IM and refresh GUI.
        ud = get(h, 'userdata');
        nB = length(ud.IM.beams);
        cB = ud.bl.currentBeam;
        ud.bl.currentBeam = nB + 1;

        if cB > 0
            beam = ud.IM.beams(cB);
        else
            beam = createDefaultBeam(ud.bl.currentBeam, [], ud.bp.isAuto, fieldNames);

        end
        beam.gantryAngle = 0;        

        if isfield(ud, 'IM') & isfield(ud.IM, 'beams')
            ud.IM.beams = dissimilarInsert(ud.IM.beams, beam, nB+1);
        else
            ud.IM.beams(nB+1) = beam;
        end
        ud.IM.beams(end).beamUID = createUID('BEAM');
        
        %Set alider position
        beamGroup = 4-floor((ud.bl.currentBeam-0.1)/10);
        set(ud.bl.sliderH,'value',beamGroup)
        set(h, 'userdata', ud);
        IMRTPGui('REFRESHBEAMS');
        IMRTPGui('REFRESHPREVIEW');
        IMRTPGui('REFRESHBEAMPARAMS');

    case 'REFRESHBROWSER'
        %set value of browser popupmenu according to passed index i.e.
        %varargin{2}
        numIMRTPs = length(planC{indexS.IM});
        if numIMRTPs==0
            browseStr = {['IM doseSet ', num2str(numIMRTPs+1)]};
        else
            for i = 1 : numIMRTPs
                browseStr{i} = [planC{indexS.IM}(i).IMDosimetry.name];
            end
            browseStr{end+1} = ['IM doseSet ', num2str(numIMRTPs+1)];
        end
        set(ud.ib.handles.rename,'string',ud.IM.name)
        if ud.saveIndex==0
            %set(ud.ib.handles.browse,'visible','off')
            set(ud.ib.handles.browse,'string',browseStr,'value',length(browseStr))
        else
            %set(ud.ib.handles.browse,'visible','on')
            set(ud.ib.handles.browse,'string',browseStr,'value',ud.saveIndex)
        end

    case 'NEWEQUISPACED'
        %Ask how many beams to create and add them to IM, then refresh.
        ud = get(h, 'userdata');
        ans = inputdlg({'Add how many equispaced beams?', 'Starting point? (0-359)'},'Beam Creation', 1, {'', '0'});
        if isempty(ans)
            return;
        end
        numBeams = str2double(ans{1});
        startPt = str2double(ans{2});
        if isnan(numBeams) | isnan(startPt)
            return; %Consider an error here.
        end
        if ud.bl.currentBeam >= 1
            tmp.beams = ud.IM.beams(ud.bl.currentBeam);
        else
            tmp.beams = createDefaultBeam(ud.bl.currentBeam, [], ud.bp.isAuto, fieldNames);
        end
        angles = startPt:360/numBeams:startPt + 360;
        angles(end) = [];
        nB = length(ud.IM.beams);
        ud.bl.currentBeam = nB + 1;
        for i=1:length(angles)
            beam = tmp.beams;
            beam.gantryAngle = angles(i);
            nB = nB + 1;
            %            ud.bl.numBeams = ud.bl.numBeams + 1;
            beam = conditionBeam(nB, beam, ud.bp.isAuto, fieldNames);
            if isfield(ud, 'IM') & isfield(ud.IM, 'beams')
                ud.IM.beams = dissimilarInsert(ud.IM.beams, beam, nB);
            else
                ud.IM.beams(nB) = beam;
            end
            ud.IM.beams(end).beamUID = createUID('BEAM');
        end
        set(h, 'userdata', ud);
        IMRTPGui('REFRESHBEAMS');
        IMRTPGui('REFRESHPREVIEW');
        IMRTPGui('REFRESHBEAMPARAMS');

    case 'DELBEAM'
        ud = get(h, 'userdata');
        toDel = ud.bl.currentBeam;
        if(toDel == 0)
            return;
        end
        nB = length(ud.IM.beams);
        nB = nB - 1;

        try
            delete(ud.bg.beamLines(toDel));
            ud.bg.beamLines(toDel) = [];
        end
        ud.IM.beams(toDel) = [];
        
        for i=ud.bl.currentBeam:nB
            set(ud.bl.handles.bevChk(i),'value',get(ud.bl.handles.bevChk(i+1),'value'))
            set(ud.bl.handles.bevType(toDel),'value',get(ud.bl.handles.bevType(i+1),'value'))
        end
        set(ud.bl.handles.bevChk(nB+1),'value',0)
        set(ud.bl.handles.bevType(nB+1),'value',1)
        
        if ud.bl.currentBeam > nB
            ud.bl.currentBeam = nB;
        end        

        %Set alider position
        beamGroup = 4-floor((ud.bl.currentBeam-0.1)/10);
        set(ud.bl.sliderH,'value',beamGroup)
        set(h, 'userdata', ud);
        IMRTPGui('REFRESHBEAMS');
        IMRTPGui('REFRESHPREVIEW');
        IMRTPGui('REFRESHBEAMPARAMS');
        CERRRefresh

    case 'REFRESHBEAMPARAMS'
        %Update the beam parameters with current ud.IM values.
        ud = get(h, 'userdata');
        cB = ud.bl.currentBeam;
        if cB == 0
            beam = [];
        else
            %ud.IM.beams(cB) = conditionBeam(cB, ud.IM.beams(cB), ud.bp.isAuto, fieldNames);
            ud.IM.beams = dissimilarInsert(ud.IM.beams,conditionBeam(cB, ud.IM.beams(cB), ud.bp.isAuto, fieldNames), cB);
            beam = ud.IM.beams(cB);
        end
        fields = fieldNames;
        for i=1:length(fields)
            try
                fName = fieldNames{i};
                choices = fieldChoices{i};
                if ~isempty(beam)
                    val = getfield(ud.IM.beams(cB), fName{:});
                else
                    if ~isempty(choices)

                        set(getfield(ud.bp.handles, [[fName{:}] '_val']), 'Value', 1, 'enable', 'off');
                    else
                        set(getfield(ud.bp.handles, [[fName{:}] '_val']), 'string', '', 'enable', 'off');
                    end
                    continue;
                end
                if ~isempty(choices) & ~fieldIsNum(i)
                    val = find(strcmpi(choices, val));
                    set(getfield(ud.bp.handles, [[fName{:}] '_val']), 'Value', val, 'enable', 'on');
                elseif ~isempty(choices) & fieldIsNum(i)
                    val = find(val==[choices{:}]);
                    set(getfield(ud.bp.handles, [[fName{:}] '_val']), 'Value', val, 'enable', 'on');
                elseif fieldIsNum(i)
                    set(getfield(ud.bp.handles, [[fName{:}] '_val']), 'string', val, 'enable', 'on');
                else
                    set(getfield(ud.bp.handles, [[fName{:}] '_val']), 'string', val, 'enable', 'on');
                end

                if ud.bp.isAuto(i)
                    set(getfield(ud.bp.handles, [[fName{:}] '_val']),'enable', 'off');
                else
                    set(getfield(ud.bp.handles, [[fName{:}] '_val']),'enable', 'on');
                end
            end
        end
        set(h, 'userdata', ud);        

    case 'AUTOCHECKCHANGED'
        ud = get(h, 'userdata');
        i = get(gcbo, 'userdata');
        val = get(gcbo, 'value');
        ud.bp.isAuto(i) = val;
        set(h, 'userdata', ud);
        set(h, 'name', 'IMRTP *(beamlets may be stale)')
        IMRTPGui('REFRESHBEAMPARAMS');

    case 'BEAMPARAMCHANGED'
        %Update ud.IM with the new value, refresh.
        ud = get(h, 'userdata');
        cB = ud.bl.currentBeam;
        data = get(gcbo, 'string');
        fieldNum = get(gcbo, 'userdata');
        if ~isempty(fieldChoices{fieldNum}) & ~fieldIsNum(fieldNum)
            val = data{get(gcbo, 'value')};
        elseif ~isempty(fieldChoices{fieldNum}) & fieldIsNum(fieldNum)
            val = str2double(data{get(gcbo, 'value')});
        elseif fieldIsNum(fieldNum)
            val = str2double(data);
        else
            val = data;
        end
        fName = fieldNames{fieldNum};
        ud.IM.beams(cB) = setfield(ud.IM.beams(cB), fName{:}, val);

        %delete beamlets associated with this beam
        ud.IM.beams(cB).beamlets = [];

        set(h, 'userdata', ud);
        set(h, 'name', 'IMRTP *(beamlets may be stale)')
        IMRTPGui('REFRESHPREVIEW');
        IMRTPGui('REFRESHBEAMPARAMS');
        IMRTPGui('REFRESHBEAMS');
        IMRTPGui('BEVCHK',cB)

    case 'REFRESHMCPARAMS'
        %Update parameter menu with ud.IM values.
        ud = get(h, 'userdata');
        fields = MCparamNames;
        %Make fields/text invisible unless it is rendered below.
        set(ud.mc.handles.name, 'visible', 'off');
        set(ud.mc.handles.val, 'visible', 'off');
        for i=1:min(length(fields), length(ud.mc.handles.name))
            try
                fName = MCparamNames{i};
                val = getfield(ud.IM.params.VMC, fName{:});
                choices = MCparamChoices{i};
                if ~isempty(choices)
                    val = find(strcmpi(choices, val));
                    set(ud.mc.handles.val(i), 'Value', val, 'style', 'popupmenu', 'string', choices, 'visible', 'on');
                elseif MCparamIsNum(i)
                    set(ud.mc.handles.val(i), 'string', num2str(val), 'style', 'edit', 'visible', 'on');
                else
                    set(ud.mc.handles.val(i), 'string', val, 'style', 'edit', 'visible', 'on');
                end
                set(ud.mc.handles.name(i), 'String', [fName{end}], 'visible', 'on');
            end
        end

    case 'MCPARAMCHANGED'
        %Menu items changed, update ud.IM.
        ud = get(h, 'userdata');
        fieldNum = get(gcbo, 'userdata');
        fName = MCparamNames{fieldNum};

        choices = MCparamChoices{fieldNum};
        if ~isempty(choices)
            ind = get(gcbo, 'value');
            val = choices{ind};
        elseif MCparamIsNum(fieldNum)
            val = str2num(get(gcbo, 'string'));
        else
            val = get(gcbo, 'string');
        end

        ud.IM.params.VMC = setfield(ud.IM.params.VMC, fName{:}, val);
        
        %delete all beamlets since calculation params changed
        for i=1:length(ud.IM.beams)
            ud.IM.beams(i).beamlets = [];
            ud.IM.beams(i).beamUID = createUID('BEAM');
        end
        
        set(h, 'name', 'IMRTP *(beamlets may be stale)')
        set(h, 'userdata', ud);

    case 'REFRESHIMPARAMS'
        %Update parameter menu with ud.IM values.
        ud = get(h, 'userdata');
        fields = paramNames;
        %Make fields/text invisible unless it is rendered below.
        set(ud.ip.handles.name, 'visible', 'off');
        set(ud.ip.handles.val, 'visible', 'off');
        for i=1:min(length(fields), length(ud.ip.handles.name))
            try
                fName = paramNames{i};
                val = getfield(ud.IM.params, fName{:});
                choices = paramChoices{i};
                if ~isempty(choices)
                    val = find(strcmpi(choices, val));
                    set(ud.ip.handles.val(i), 'Value', val, 'style', 'popupmenu', 'string', choices, 'visible', 'on');
                elseif paramIsNum(i)
                    set(ud.ip.handles.val(i), 'string', num2str(val), 'style', 'edit', 'visible', 'on');
                else
                    set(ud.ip.handles.val(i), 'string', val, 'style', 'edit', 'visible', 'on');
                end
                set(ud.ip.handles.name(i), 'String', [fName{end}], 'visible', 'on');
            end
        end
        switch ud.IM.params.algorithm
            case 'QIB'
                if ud.ip.paramSet ~= 1
                    pos = get(h, 'position');
                    pos(3) = x;
                    set(h, 'position', pos)
                    ud.ip.paramSet = 1;
                    set(h, 'userdata', ud);
                    IMRTPGui('REFRESHIMPARAMS')
                end
            case 'VMC++'
                if ud.ip.paramSet ~= 2
                    pos = get(h, 'position');
                    pos(3) = x+MCBarWidth;%936;
                    set(h, 'position', pos)
                    ud.ip.paramSet = 2;
                    set(h, 'userdata', ud);
                    IMRTPGui('REFRESHIMPARAMS')
                end
            case 'DPM'
                if ud.ip.paramSet ~= 3
                    pos = get(h, 'position');
                    pos(3) = x+MCBarWidth;%936;
                    set(h, 'position', pos)
                    ud.ip.paramSet = 2;
                    set(h, 'userdata', ud);
                    IMRTPGui('REFRESHIMPARAMS')
                end
        end

    case 'IMPARAMCHANGED'
        %Menu items changed, update ud.IM.
        ud = get(h, 'userdata');
        fieldNum = get(gcbo, 'userdata');
        fName = paramNames{fieldNum};

        choices = paramChoices{fieldNum};
        if ~isempty(choices)
            ind = get(gcbo, 'value');
            val = choices{ind};
        elseif paramIsNum(fieldNum)
            %             val = str2double(get(gcbo, 'string'));
            val = str2num(get(gcbo, 'string'));
        else
            val = get(gcbo, 'string');
        end

        ud.IM.params = setfield(ud.IM.params, fName{:}, val);
        
        %delete all beamlets since calculation params changed
        for i=1:length(ud.IM.beams)
            ud.IM.beams(i).beamlets = [];
            ud.IM.beams(i).beamUID = createUID('BEAM');
        end

        set(h, 'name', 'IMRTP *(beamlets may be stale)')
        set(h, 'userdata', ud);

        switch ud.IM.params.algorithm
            case 'QIB'
                if ud.ip.paramSet ~= 1
                    pos = get(h, 'position');
                    pos(3) = x;
                    set(h, 'position', pos)
                    ud.ip.paramSet = 1;
                    set(h, 'userdata', ud);
                    IMRTPGui('REFRESHIMPARAMS')
                end
            case 'VMC++'
                if ud.ip.paramSet ~= 2
                    pos = get(h, 'position');
                    pos(3) = x+MCBarWidth;%936;
                    set(h, 'position', pos)
                    ud.ip.paramSet = 2;
                    set(h, 'userdata', ud);
                    IMRTPGui('REFRESHIMPARAMS')
                end
            case 'DPM'
                if ud.ip.paramSet ~= 2
                    pos = get(h, 'position');
                    pos(3) = x+MCBarWidth;%936;
                    set(h, 'position', pos)
                    ud.ip.paramSet = 2;
                    set(h, 'userdata', ud);
                    IMRTPGui('REFRESHIMPARAMS')
                end
        end
        
    case 'BEVCHK'
        beamIndex = varargin{1};
        if get(ud.bl.handles.bevChk(beamIndex),'value')==1
            % Calculate isocenter
            structNums = [ud.IM.goals.structNum];
            targets = structNums(strcmpi({ud.IM.goals.isTarget}, 'yes'));
            if (strcmpi(ud.IM.beams(beamIndex).isocenter.x,'COM') || strcmpi(ud.IM.beams(beamIndex).isocenter.y,'COM') || strcmpi(ud.IM.beams(beamIndex).isocenter.z,'COM')) && ~isempty(targets)
                [xCOM, yCOM, zCOM] = calcIsocenter(targets, 'COM');
                if strcmpi(ud.IM.beams(beamIndex).isocenter.x,'COM')
                    isoX = xCOM;
                elseif isnumeric(ud.IM.beams(beamIndex).isocenter.x)
                    isoX = ud.IM.beams(beamIndex).isocenter.x;
                else
                    set(ud.bl.handles.bevChk(beamIndex),'value',0)
                    set(h,'userdata',ud)
                    warning(['Target structures or valid isocenter required. Cannot display beam # ',num2str(beamIndex)])
                    return
                end
                if strcmpi(ud.IM.beams(beamIndex).isocenter.y,'COM')
                    isoY = yCOM;
                elseif isnumeric(ud.IM.beams(beamIndex).isocenter.y)
                    isoY = ud.IM.beams(beamIndex).isocenter.y;
                else
                    set(ud.bl.handles.bevChk(beamIndex),'value',0)
                    set(h,'userdata',ud)
                    warning(['Target structures or valid isocenter required. Cannot display beam # ',num2str(beamIndex)])
                    return
                end
                if strcmpi(ud.IM.beams(beamIndex).isocenter.z,'COM')
                    isoZ = zCOM;
                elseif isnumeric(ud.IM.beams(beamIndex).isocenter.z)
                    isoZ = ud.IM.beams(beamIndex).isocenter.z;
                else
                    set(ud.bl.handles.bevChk(beamIndex),'value',0)
                    set(h,'userdata',ud)
                    warning(['Target structures or valid isocenter required. Cannot display beam # ',num2str(beamIndex)])
                    return
                end
            elseif isnumeric(ud.IM.beams(beamIndex).isocenter.x) && isnumeric(ud.IM.beams(beamIndex).isocenter.y) && isnumeric(ud.IM.beams(beamIndex).isocenter.z)
                isoX = ud.IM.beams(beamIndex).isocenter.x;
                isoY = ud.IM.beams(beamIndex).isocenter.y;
                isoZ = ud.IM.beams(beamIndex).isocenter.z;
            else
                set(ud.bl.handles.bevChk(beamIndex),'value',0)
                set(h,'userdata',ud)
                warning(['Target structures or valid isocenter required. Cannot display beam # ',num2str(beamIndex)])
                return
            end

            % Calculate source x,y,z
            ud.IM.beams(beamIndex).zRel = 0;
            ud.IM.beams(beamIndex).xRel =  ud.IM.beams(beamIndex).isodistance * sindeg(ud.IM.beams(beamIndex).gantryAngle);
            ud.IM.beams(beamIndex).yRel =  ud.IM.beams(beamIndex).isodistance * cosdeg(ud.IM.beams(beamIndex).gantryAngle);

            %RTOG positions of sources
            ud.IM.beams(beamIndex).x = ud.IM.beams(beamIndex).xRel + isoX;
            ud.IM.beams(beamIndex).y = ud.IM.beams(beamIndex).yRel + isoY;
            ud.IM.beams(beamIndex).z = ud.IM.beams(beamIndex).zRel + isoZ;

            set(h,'userdata',ud)

        end

        CERRRefresh
        

    case 'WAITBAR'
        %Draws the waitbar varargin{1}% done.
        percent = varargin{1};
        ud = get(h, 'userdata');
        hold on;
        setWaitbar(ud, percent);
        set(ud.wb.handles.percent, 'string', [num2str(round(percent)) '%']);
        drawnow;

    case 'SAVE'
        operation = get(ud.ip.handles.file,'value');
        switch num2str(operation)
            case {'1','2'} % 1=Recompute & add dosimetry, 2=Recompute & overwrite dosimetry
                
                %Start IMRT calculation.
                ud = get(h, 'userdata');
                %Check that the IM structure has been fully formed.
                if length(ud.IM.goals) < 1 | ~any(strcmpi({ud.IM.goals.isTarget}, 'yes'))
                    IMRTPGui('statusbar', 'Cannot run without at least one target structure. Please add one.');
                    return;
                end
                if length(ud.IM.beams) < 1
                    IMRTPGui('statusbar', 'Cannot run without at least one beam. Please add one.');
                    return;
                end

                t0 = clock;

                %Condition all beams once before running, to be sure that all
                %autofields are set properly and all xRel.yRel.zRel values are
                %proper.
                for i=1:length(ud.IM.beams)
                    ud.IM.beams(i) = conditionBeam(i, ud.IM.beams(i), ud.bp.isAuto, fieldNames);
                end

                %Run Problem
                %IMDosimetry = IMRTP(ud.IM);
                IMDosimetry = updateIMRTP(ud.IM);

                %Save result.
                if operation==1
                    [planC, newIndex] = addIM(IMDosimetry, planC, 0);
                    ud.saveIndex = newIndex;
                elseif operation==2
                    planC = addIM(IMDosimetry, planC, ud.saveIndex);
                end
                
                %Create a new UID for this dosimetry
                planC{indexS.IM}(ud.saveIndex).IMUID = createUID('IM');
                
                %Update viewer menu.
                sliceCallBack('REFRESHIMRTPMENU');

                totalSeconds = etime(clock, t0);
                hours = floor(totalSeconds/3600);
                totalSeconds = totalSeconds - hours*3600;
                minutes = floor((totalSeconds)/60);
                totalSeconds = totalSeconds - minutes*60;
                seconds = round(totalSeconds);
                ud.isFresh = 1;
                set(h,'userdata',ud)
                IMRTPGui('statusbar', ['Finished, in ' num2str(hours) ' hours, ' num2str(minutes) ' minutes, ' num2str(seconds) ' seconds.']);
                IMRTPGui('REFRESHBROWSER')

            case {'3','4'} % 3=Add setup, 4=Overwrite setup
                ud = get(h, 'userdata');
                if operation==3
                    [planC, newIndex] = addIM(ud.IM, planC, 0);
                elseif operation==4
                    planC = addIM(ud.IM, planC, ud.saveIndex);
                    newIndex = ud.saveIndex;
                end
                ud.saveIndex = newIndex;
                %Create a new UID for this dosimetry
                planC{indexS.IM}(ud.saveIndex).IMUID = createUID('IM');                
                ud.isFresh = 1;
                set(h,'userdata',ud)
                IMRTPGui('statusbar', 'Saved this IM to plan.');
                sliceCallBack('REFRESHIMRTPMENU');
                IMRTPGui('REFRESHBROWSER')
                
            case '5' %Revert to Original
                if ud.saveIndex ~= 0
                    IMRTPGui('init', planC{indexS.IM}(ud.saveIndex).IMDosimetry, ud.saveIndex);
                else
                    IMRTPGui('init')
                end                 
                
        end
        set(h, 'name', 'IMRTP')
        
    case 'EXIT'
        %Cancel and close everything.
        ButtonName = questdlg('Exit IMRTP?','Confirm Exit','Yes','No','No');
        if strcmpi(ButtonName,'Yes')
            hBeamLine = findobj('tag','beamLine');
            delete(hBeamLine)            
            delete(h);
            stateS.handle.IMRTMenuFig = [];
        end

    case 'LOADIM'
        %Load an IM from an IMSetup file.
        ud = get(h, 'userdata');
        %Save the IM parameters to an IMSetup file.
        [fName, dName] = uigetfile('*.m', 'Select IMSetup.m to import.');
        currentDir = pwd;
        if dName == 0
            return;
        end
        cd(dName);
        try
            ud.IM = feval('IMSetup', 'ex1');
        catch
            IMRTPGui('statusbar', 'Error loading IMSetup.m, IMSetup is malformed or was not created for this plan.');
            cd(currentDir);
            return;
        end
        cd(currentDir);
        ud.bl.currentBeam = min(1, length(ud.IM.beams));
        set(h, 'userdata', ud);

        IMRTPGui('REFRESHBEAMS')
        IMRTPGui('REFRESHSTRUCTS');
        IMRTPGui('REFRESHPREVIEW');
        IMRTPGui('REFRESHBEAMPARAMS');
        IMRTPGui('REFRESHIMPARAMS');

    case 'STATUS'
        %       Pass the status of current IMRTP problem to gui.
        currentBeam = varargin{1};
        totalBeams = varargin{2};
        if ischar(varargin{3})
            structStr = varargin{3};
        else
            currentStruct = varargin{3};
            strC = {planC{indexS.structures}.structureName};
            structStr =  strC{currentStruct};
        end
        currentPB = varargin{4};
        totalPBs = varargin{5};

        percentDone = ((currentBeam-1)*totalPBs + currentPB) / (totalBeams * totalPBs)*100;

        IMRTPGui('waitbar', percentDone);
        IMRTPGui('statusbar', ['Calculating dose to ' structStr ', beam ' num2str(currentBeam) '/' num2str(totalBeams) ', PB ' num2str(currentPB) '/' num2str(totalPBs) '.']);


    case 'STATUSBAR'
        %        Show text varargin{1} in the status bar.
        ud = get(h, 'userdata');
        str = varargin{1};
        set(ud.wb.handles.text, 'string', str);

    case 'BROWSEIM'
        newIM = get(ud.ib.handles.browse,'value');
        if newIM == length(get(ud.ib.handles.browse,'string'));
            newIM = 0;
        end
        if newIM ~= ud.saveIndex & newIM~=0
            IMRTPGui('init', planC{indexS.IM}(newIM).IMDosimetry, newIM)
        elseif newIM ~= ud.saveIndex & newIM==0
            IMRTPGui('init')
        end

    case 'RENAMEIM'
        ud.IM.name = get(ud.ib.handles.rename,'string');
        browseStr = get(ud.ib.handles.browse,'string');
        if ud.saveIndex ~=0            
            browseStr{ud.saveIndex} = ud.IM.name;
        else
            browseStr{end} = ud.IM.name;
        end
        set(ud.ib.handles.browse,'string',browseStr)
        set(h,'userdata',ud)
        
    case 'DELETEIM'
        if ud.saveIndex~=0
            ButtonName = questdlg(['Permanently delete IM # ',num2str(ud.saveIndex),' from Tx plan?'],'Confirm Delete','Yes','No','No');
            if strcmpi(ButtonName,'Yes')
                planC{indexS.IM}(ud.saveIndex) = [];
                IMRTPGui('init')
            end
        end
        
    case 'REMOTEIM'
        [fpath,fname] = fileparts(stateS.CERRFile);        
        imUID = planC{indexS.IM}(ud.saveIndex).IMUID;
        if ~isempty(planC{indexS.IM}(ud.saveIndex).IMDosimetry.beams) && isfield(planC{indexS.IM}(ud.saveIndex).IMDosimetry.beams(1).beamlets,'remotePath')
           % Bring into memory 
            for iBeam = 1:length(planC{indexS.IM}(ud.saveIndex).IMDosimetry.beams)
                remotePath = planC{indexS.IM}(ud.saveIndex).IMDosimetry.beams(iBeam).beamlets.remotePath;
                fileNam = planC{indexS.IM}(ud.saveIndex).IMDosimetry.beams(iBeam).beamlets.filename;
                planC{indexS.IM}(ud.saveIndex).IMDosimetry.beams(iBeam).beamlets = getRemoteVariable(planC{indexS.IM}(ud.saveIndex).IMDosimetry.beams(iBeam).beamlets);
                stateS.reqdRemoteFiles(strcmp(fullfile(remotePath,fileNam),stateS.reqdRemoteFiles)) = [];
                delete(fullfile(remotePath,fileNam))                
                %remove remote storage directory if it is empty
                dirRemoteS = dir(remotePath);
                if ~any(~cellfun('isempty',strfind({dirRemoteS.name},'.mat')))
                    rmdir(remotePath)
                end                
            end
            set(gcbo,'string','Remote')
        
        else
            % Make remote
            for iBeam = 1:length(planC{indexS.IM}(ud.saveIndex).IMDosimetry.beams)
                beamUID = planC{indexS.IM}(ud.saveIndex).IMDosimetry.beams(iBeam).beamUID;
                planC{indexS.IM}(ud.saveIndex).IMDosimetry.beams(iBeam).beamlets = setRemoteVariable(planC{indexS.IM}(ud.saveIndex).IMDosimetry.beams(iBeam).beamlets, 'LOCAL',fullfile(fpath,[fname,'_store']),['im_',imUID,'_beam_',beamUID,'.mat']);
            end
            set(gcbo,'string','Memory')
        end
        
    case 'SHOWDOSE'

        prompt = {'Enter PB weigth/s for Beams: (leave Empty if not sure)';...
            'Enter the structure number/s'; 'Enter name for new dose';...
            'Enter Scan Number for associating this dose (If left empty Dose will be associated with scan 1)'};
        
        dlg_title = 'Show IM dose in CERR';
        
        num_lines = 1;
        
        def = {'';'';'';''};
        
        output = inputdlg(prompt,dlg_title,num_lines,def);
        
        PBWeightsV = str2num(output{1});
        
        structsV = str2num(output{2});

        if isempty(structsV)
            return
        end
        
        fractName = output{3};
        
        scanNum = str2num(output{4});
        %Default scanNum to 1
        if isempty(scanNum)
            scanNum = 1;
        end
        
        dose3D = getIMDose(planC{indexS.IM}(ud.saveIndex).IMDosimetry , PBWeightsV, structsV);

        showIMDose(dose3D,fractName,scanNum);

end

function setWaitbar(ud, percent)
%Set the waitbar to visualize <percent> done.
set(ud.wb.handles.patch, 'Vertices', [[0 0 percent/100 percent/100]' [0 1 1 0]']);


function beam = createDefaultBeam(beamNum, beam, isAuto, fieldNames)
%Creates a beam with preset default values.
global planC;
indexS = planC{end};

fieldDefaults = {beamNum, 'photons', 6, 0, 0, 0, 100, 0, 0, 0, ...
    0, 'IM beam', 1, 1, 'date', 'IM', 0, 0, 0, 0.4};
beam = [];
for i=1:length(fieldNames)
    fN = fieldNames{i};
    beam = setfield(beam, fN{:}, fieldDefaults{i});
end
beam = conditionBeam(beamNum, beam, isAuto, fieldNames);

function beam = conditionBeam(beamNum, beam, isAuto, fieldNames)
%Sets values that should not be changed in a beam.
global planC;
indexS = planC{end};
autoFields = {beamNum, 'photons', 6, 'COM', 'COM', 'COM', 100, 0, 0, 0, ...
    0, 'IM beam', 1, 1, date, 'IM', 0, beam.isodistance * sindeg(beam.gantryAngle),...
    beam.isodistance * cosdeg(beam.gantryAngle), 0.4};

for i=1:length(fieldNames)
    if isAuto(i)
        fN = fieldNames{i};
        beam = setfield(beam, fN{:}, autoFields{i});
    end
end


function str = createDefaultStr(strFields, strDefaults)
%Given a set of fieldnames and default values for each, return a struct
%with those fieldnames populated by defaults.
str = [];
for i=1:length(strFields)
    field = strFields{i};
    str = setfield(str, field{:}, strDefaults{i});
end
