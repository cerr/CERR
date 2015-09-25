function IMCalc = calculateBeamIM(leak, planC_File, nhist, OutputError, indexBeam, imin, imax)
% written by KZ
% Calculate IM struct, call DPM, get 
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

% Usage: IIMCalc = calculateBeamIM(0.018, 'DPM_10beams_planC', 1, 1, 5)
%   leak = 0.018 
%   planC_File = file name contained planC, eg. 'DPM_10beams_planC'
%   indexBeam = Beam Index: 1, 2, ...
%   imin = Beamlet index
%   imax = Beamlet index

%   eval(['load Beam',num2str(indexBeam),'_w']);
%   where, Beam1_w.mat (Beam2_w.mat) need to be in the current directory. It's the weight of
%   the beamlets for each beam.

% JC. Aug 10, 2005, Need to make planC read from the disk, since in the
% stand-alone mode, no matlab run is expected.

% open planC_File
% In matlab release 14, "eval" can be compiled.
Error = []; %Initialize Error to NULL.
load(planC_File);
%eval(['load ',planC_File]);
%leak = 0.018; %leakage in per *100
leak = str2num(leak)


% for indexBeam = 1 : planC{7}.FractionGroupSequence.Item_1.NumberOfBeams
       
    bs = planC{7}.BeamSequence.(['Item_' num2str(indexBeam)]);
    
	LS = getDICOMLeafPositions(bs)
    
       
	[inflMap, xV, yV, colDividerXCoord, rowDividerYCoord] = getLSInfluenceMap(LS,leak);

	gA = bs.ControlPointSequence.Item_1.GantryAngle;
	iC = bs.ControlPointSequence.Item_1.IsocenterPosition;
    
    IMBase.beams(1).gantryAngle = gA;
    IMBase.beams(1).isocenter.x = iC(1)/10;
    IMBase.beams(1).isocenter.y = -iC(2)/10;
    IMBase.beams(1).isocenter.z = -iC(3)/10;
    
    IMBase.beams(1).isodistance = bs.SourceAxisDistance/10;
           
    IMBase.beams(1).xRel = IMBase.beams(1).isodistance * sindeg(IMBase.beams(1).gantryAngle);
    
 	IMBase.beams(1).yRel = IMBase.beams(1).isodistance * cosdeg(IMBase.beams(1).gantryAngle); 
   
    IMBase.beams(1).beamEnergy = bs.ControlPointSequence.Item_1.NominalBeamEnergy;
        
    
    load rowLeafPositions

    [PBX] = getPBXCoorFromFluence(inflMap, rowLeafPositions, 2, 10, colDividerXCoord, rowDividerYCoord, 10);
    
   
    [xPosV,yPosV,beamlet_delta_x,beamlet_delta_y,w_field] = getPBVectors(PBX,rowLeafPositions,colDividerXCoord,rowDividerYCoord,inflMap);
    
   

    %Visualization
%     figure;hAxis1 = axes;imagesc([xV(1)+.05 xV(end)-.05], [yV(1)+.05, yV(end)-.05], inflMap);
%     set(gcf, 'renderer', 'zbuffer')
%     figure;hAxis2 = axes;hold on;
%     set(gcf, 'renderer', 'zbuffer')    
%     xL = get(hAxis1, 'xlim');
%     yL = get(hAxis1, 'ylim');
%     set(hAxis2, 'xlim', xL);
%     set(hAxis2, 'ylim', yL);
%     axis(hAxis2, 'manual');
% %     w_colors = floor((w_field ./ max(w_field))*255)+1;
%     set(gcf, 'doublebuffer', 'on');
%     for i=1:length(xPosV)
%         patch([xPosV(i) - beamlet_delta_x(i)/2 xPosV(i) - beamlet_delta_x(i)/2 xPosV(i) + beamlet_delta_x(i)/2 xPosV(i) + beamlet_delta_x(i)/2 xPosV(i) - beamlet_delta_x(i)/2], [yPosV(i) - beamlet_delta_y(i)/2 yPosV(i) + beamlet_delta_y(i)/2 yPosV(i) + beamlet_delta_y(i)/2 yPosV(i) - beamlet_delta_y(i)/2 yPosV(i) - beamlet_delta_y(i)/2], w_field(i));        
%     end
%     axis([hAxis1 hAxis2], 'ij');
%     kids = get(hAxis2, 'children');
% %     set(kids, 'edgecolor', 'none');
%     cMap = colormap('jet');
%     set(hAxis2, 'color', cMap(1,:));     
    
           
    xPosV = xPosV/10;
    yPosV = yPosV/10;
    beamlet_delta_x = beamlet_delta_x/10;
    beamlet_delta_y = beamlet_delta_y/10;
    
    save PBData xPosV yPosV beamlet_delta_x beamlet_delta_y gA
         
    IMBase.goals.PBMargin = 0.5;
    IMBase.goals.structNum = 2;
    IMBase.params.xyDownsampleIndex = 1;
    IMBase.goals.isTarget(1) = 'y';
    IMBase.goals.xySampleRate = 2;
    IMBase.params.numCTSamplePts = 300;
    
    IMBase.beams(1).zRel = 0;
    IMBase.beams(1).xRel =  IMBase.beams(1).isodistance * sindeg(IMBase.beams(1).gantryAngle);
    IMBase.beams(1).yRel =  IMBase.beams(1).isodistance * cosdeg(IMBase.beams(1).gantryAngle);
                    
    %IMBase.params.algorithm = 'VMC++';
    %IMCalc = IMRTP_MapCheck(IMBase);
    
    IMBase.params.algorithm = 'DPM';
    IMCalc = IMRTP_MapCheck(IMBase, planC, stateS);
    % JC. 11 Aug, 05 Added more arguments to IMRTP_MapCheck,
    
    %disp('OK_BIG1'); pause(5);
    % JC. Aug. 3, 2005
    % Add fields to IMCalc, necessary for generateDPMInfluence.m
    IMCalc.beams.couchAngle = 0;
    IMCalc.beams.collimatorAngle = 0;
    IMCalc.params.ScatterMethod = 'exponential';
    IMCalc.params.Scatter.Threshold = 0.01;
    IMCalc.params.Scatter.RandomStep = 30;
    IMCalc.beamlets = struct;  
    %eval(['load Beam',num2str(indexBeam),'_w']);
    IMCalc = generateDPMInfluence(IMCalc,'dpm.spectrum',nhist, OutputError,imin,imax,planC,stateS)   
    %IMCalc = DoseScale(IMCalc);
    %dose3D = getIMDose(IMCalc, w_field, 1);
    %dose3D = dose3D/max(dose3D(:));
    filename = ['IMCalc_Beam',num2str(indexBeam)];
    save(filename, 'IMCalc');
%    eval(['save IMCalc_Beam',num2str(indexBeam),' IMCalc']);
%    clear IMCalc;
% end
