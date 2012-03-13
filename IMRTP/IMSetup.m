function IM = IMSetup(statement)
%IMRTP example
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

%Currently problem.structures is not currently used but will be used when non-uniform voxel selection is implemented
%to keep up with the list of voxels to which dose has been computed.  For this test case we are just using
%the 0.2 cm voxels inherent in the NOMOS system.

global planC

IM = initIMRTProblem;


switch lower(statement)


  case 'ex1'

    %-------set general parameters------------%
    IM.params.xyDownsampleIndex = 1;    %Sampling rate unformized CT scan in transverse dimension.  THis value must be a power of two.
    IM.params.numCTSamplePts = 300;     %Number of ray-trace points for radiological path length calculation.
    IM.params.cutoffDistance = 4;       %Never compute dose further than this distance from the PB ray.
    IM.params.writeScale    = 1;        %When writing the influence matrix to disk, use this scale factor.

    IM.params.debug = 'n';              %'y' to turn on extra data gathering.
    
    IM.params.DoseTerm = 'primary+scatter'; 
    
    IM.params.ScatterMethod = 'random'; % Scatter reduce method - 'random' - randomly chosed points within Step, 'threshold'
                                        % cut the dose point below threshold
    
    IM.params.Scatter.Threshold = 0.01; % threshold for scatter
    
    IM.params.Scatter.RandomStep = 20; % random frequency algorithm


    %-----------List goals---------------------%

    goalNum = 1;         %The first IMRTP goal term.
    structNum = 12;      %The structure number in CERR (see structures pull down menu)
    IM.goals(goalNum).structNum  = structNum;              %index of structure within CERR dataset
    IM.goals(goalNum).structName = planC{planC{end}.structures}(structNum).structureName;    %Also supply name for human reviewability
    IM.goals(goalNum).isTarget     = 'yes';  %To know which PBs to include.
    IM.goals(goalNum).PBMargin     = 0.5;    %Include PBs whose central rays are as close as this to structure at any point.
    IM.goals(goalNum).xySampleRate = 2;   %Must be a power of 2

    goalNum = goalNum + 1;
    structNum = 15;
    IM.goals(goalNum).structNum  = structNum;              %index of structure within CERR dataset
    IM.goals(goalNum).structUID  = planC{planC{end}.structures}(structNum).structUID;
    IM.goals(goalNum).structName = planC{planC{end}.structures}(structNum).structureName;    %Also supply name for human reviewability
    IM.goals(goalNum).isTarget     = 'no';
    IM.goals(goalNum).PBMargin     = 0.5;
    IM.goals(goalNum).xySampleRate = 2;   %Must be a power of 2
    
    goalNum = goalNum + 1;
    structNum = 17;
    IM.goals(goalNum).structNum  = structNum;              %index of structure within CERR dataset
    IM.goals(goalNum).structName = planC{planC{end}.structures}(structNum).structureName;    %Also supply name for human reviewability
    IM.goals(goalNum).isTarget     = 'no';
    IM.goals(goalNum).PBMargin     = 0.5;
    IM.goals(goalNum).xySampleRate = 2;  %Must be a power of 2
%     
%     goalNum = goalNum + 1;
%     structNum = 15;
%     IM.goals(goalNum).structNum  = structNum;              %index of structure within CERR dataset
%     IM.goals(goalNum).structName = planC{planC{end}.structures}(structNum).structureName;    %Also supply name for human reviewability
%     IM.goals(goalNum).isTarget     = 'no';
%     IM.goals(goalNum).PBMargin     = 2.0;
%     IM.goals(goalNum).xySampleRate = 2;  %Must be a power of 2
%     
%     goalNum = goalNum + 1;
%     structNum = 15;
%     IM.goals(goalNum).structNum  = structNum;              %index of structure within CERR dataset
%     IM.goals(goalNum).structName = planC{planC{end}.structures}(structNum).structureName;    %Also supply name for human reviewability
%     IM.goals(goalNum).isTarget     = 'no';
%     IM.goals(goalNum).PBMargin     = 2.0;
%     IM.goals(goalNum).xySampleRate = 2;  %Must be a power of 2
%     
%     goalNum = goalNum + 1;
%     structNum = 4;
%     IM.goals(goalNum).structNum  = structNum;              %index of structure within CERR dataset
%     IM.goals(goalNum).structName = planC{planC{end}.structures}(structNum).structureName;    %Also supply name for human reviewability
%     IM.goals(goalNum).isTarget     = 'no';
%     IM.goals(goalNum).PBMargin     = 2.0;
%     IM.goals(goalNum).xySampleRate = 2;  %Must be a power of 2


    %-----------List beam characteristics---------------------%

    [CTUniform3D CTUniformInfoS] = getUniformizedCTScan(0,getStructureAssociatedScan(structNum));

    xOffset = CTUniformInfoS.xOffset;    %Do not change
    yOffset = CTUniformInfoS.yOffset;

    beamNum =1;

    IM.beams(beamNum).isocenter.x = xOffset;        %Make isocenter the center of the CT scan in RTOG coords.  Could be different.
    IM.beams(beamNum).isocenter.y = yOffset;
    IM.beams(beamNum).isocenter.z = 15;%81.9;%14; %18.1;

    IM.beams(beamNum).beamNum = 1;
    IM.beams(beamNum).beamModality          = 'photons';
    IM.beams(beamNum).beamEnergy            = 18;           %Currently only 6 and 18 MV supported.
    IM.beams(beamNum).beamDescription       = 'IMRTP test';
    IM.beams(beamNum).beamType              = 'IM';
    IM.beams(beamNum).collimatorAngle       = [];  %currently ignored
    IM.beams(beamNum).couchAngle            = []; %currently ignored
    IM.beams(beamNum).arcAngle              = []; %currently ignored
    IM.beams(beamNum).algorithm             = 'QIB';      %Quadrant infinite beam method.  See poster on deasylab.info.
    IM.beams(beamNum).isocenter.x           = xOffset;
    IM.beams(beamNum).isocenter.y           = yOffset;
    IM.beams(beamNum).isocenter.z           = 15;%81.9; %14;        %User set.

    IM.beams(beamNum).beamletDelta_x        = 0.5;         %Width of PB (beamlet) at 100 cm from source.
    IM.beams(beamNum).beamletDelta_y        = 0.5;

    IM.beams(beamNum).cutoffDistance        = 5;
    IM.beams(beamNum).dateOfCreationdate    = date;

    IM.beams(beamNum).isodistance           = 100;        %Source distance from isocenter
    IM.beams(beamNum).gantryAngle           = 0;          %Gantry angle, positive in clockwise rotation.
    IM.beams(beamNum).zRel                  = 0;          %Relative offset of z source position from isocenter z.

    IM.beams(beamNum).xRel  = IM.beams(beamNum).isodistance * sindeg(IM.beams(beamNum).gantryAngle);   %Do not modify.
    IM.beams(beamNum).yRel  = IM.beams(beamNum).isodistance * cosdeg(IM.beams(beamNum).gantryAngle);
    
    IM.beams(beamNum).sigma_100 = 0.4;
    
    beamNum = beamNum + 1;
    
    IM.beams(beamNum) = IM.beams(1);                 %Copy other parameters.
    IM.beams(beamNum).gantryAngle = 72;     %Modify gantry angle
    IM.beams(beamNum).xRel  = IM.beams(beamNum).isodistance * sindeg(IM.beams(beamNum).gantryAngle);
    IM.beams(beamNum).yRel  = IM.beams(beamNum).isodistance * cosdeg(IM.beams(beamNum).gantryAngle);
    
    beamNum = beamNum + 1;
    
    IM.beams(beamNum) = IM.beams(1);
    IM.beams(beamNum).gantryAngle = 144;
    IM.beams(beamNum).xRel  = IM.beams(beamNum).isodistance * sindeg(IM.beams(beamNum).gantryAngle);
    IM.beams(beamNum).yRel  = IM.beams(beamNum).isodistance * cosdeg(IM.beams(beamNum).gantryAngle);
    
    beamNum = beamNum + 1;
    
    IM.beams(beamNum) = IM.beams(1);
    IM.beams(beamNum).gantryAngle = 216;
    IM.beams(beamNum).xRel  = IM.beams(beamNum).isodistance * sindeg(IM.beams(beamNum).gantryAngle);
    IM.beams(beamNum).yRel  = IM.beams(beamNum).isodistance * cosdeg(IM.beams(beamNum).gantryAngle);
    
    beamNum = beamNum + 1;
    
    IM.beams(beamNum) = IM.beams(1);
    IM.beams(beamNum).gantryAngle = 288;
    IM.beams(beamNum).xRel  = IM.beams(beamNum).isodistance * sindeg(IM.beams(beamNum).gantryAngle);
    IM.beams(beamNum).yRel  = IM.beams(beamNum).isodistance * cosdeg(IM.beams(beamNum).gantryAngle);


otherwise

    disp('Unknown example')

end



