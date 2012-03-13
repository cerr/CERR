function num_PB = getBeamsInfo(leak, planC_File)
% written by KZ
% Calculate IM struct, call DPM, get 

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
load(planC_File);
%eval(['load ',planC_File]);
%leak = 0.018; %leakage in per *100
leak = str2num(leak)


for indexBeam = 1 : planC{7}.FractionGroupSequence.Item_1.NumberOfBeams
%indexBeam = 3       
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
    figure;hAxis1 = axes;imagesc([xV(1)+.05 xV(end)-.05], [yV(1)+.05, yV(end)-.05], inflMap);
    set(gcf, 'renderer', 'zbuffer')
    figure;hAxis2 = axes;hold on;
    set(gcf, 'renderer', 'zbuffer')    
    xL = get(hAxis1, 'xlim');
    yL = get(hAxis1, 'ylim');
    set(hAxis2, 'xlim', xL);
    set(hAxis2, 'ylim', yL);
    axis(hAxis2, 'manual');
%     w_colors = floor((w_field ./ max(w_field))*255)+1;
    set(gcf, 'doublebuffer', 'on');
    for i=1:length(xPosV)
        patch([xPosV(i) - beamlet_delta_x(i)/2 xPosV(i) - beamlet_delta_x(i)/2 xPosV(i) + beamlet_delta_x(i)/2 xPosV(i) + beamlet_delta_x(i)/2 xPosV(i) - beamlet_delta_x(i)/2], [yPosV(i) - beamlet_delta_y(i)/2 yPosV(i) + beamlet_delta_y(i)/2 yPosV(i) + beamlet_delta_y(i)/2 yPosV(i) - beamlet_delta_y(i)/2 yPosV(i) - beamlet_delta_y(i)/2], w_field(i));        
    end
    axis([hAxis1 hAxis2], 'ij');
    kids = get(hAxis2, 'children');
%     set(kids, 'edgecolor', 'none');
    cMap = colormap('jet');
    set(hAxis2, 'color', cMap(1,:));     
    
    num_PB(indexBeam) =  length(w_field);
    
end
