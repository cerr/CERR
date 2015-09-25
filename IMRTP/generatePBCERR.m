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

numBeams = length(IM.beams);

% by default the calculation will be based on the resolution 
% of the uniformized CT dataset.

phantomPath     = fullfile('.', 'phantoms', '');
phantomFilename = fullfile(phantomPath, 'CERR_IMRT.ct');
scanNum = 1;
fillWater = 0;
offset = generateCT_uniform(getUniformizedCTScan,phantomFilename,scanNum,fillWater);


% dataPath = path where CTscan and temp data will be written
% generate CT scan with uniformized voxels, resolution [xres, yres,zres]
% phantomname='cwg3_CTvmc.ct';
% generate offset of CT scan

% Left hand side versus centre of each voxel
offset(1:2)=offset(1:2)-yres/2;
offset(3:4)=offset(3:4)-xres/2;
offset(5:6)=offset(5:6)-zres/2;

% Set the options for the VMC++ input

VMCOpt = VMCOptInit;
VMCOpt.startGeometry.startXYZGeometry.phantomFile=fullfile(dataPath, phantomname);
% number of particles per beamlets.  The user might want to set this
VMCOpt.startMCControl.NCase=10000;
% To generate independent datasets, need to set 
% VMCOpt.startQuasi.skip to skip the numbers of histories 
% used in previous calculations

for beamIndex=1:numBeams, 

  pb(:,1)=IM.beams(beamIndex).RTOGPBVectorsM_MC(:,1)+IM.beams(beamIndex).x;
  pb(:,2)=IM.beams(beamIndex).RTOGPBVectorsM_MC(:,2)+IM.beams(beamIndex).y;
  pb(:,3)=IM.beams(beamIndex).RTOGPBVectorsM_MC(:,3)+IM.beams(beamIndex).z;

  dx=IM.beams(beamIndex).beamletDelta_x;
  dy=IM.beams(beamIndex).beamletDelta_y;

  IC=[IM.beams(beamIndex).isocenter.x IM.beams(beamIndex).isocenter.y  IM.beams(beamIndex).isocenter.z];
  th=IM.beams(beamIndex).gantryAngle*pi/180;

  M=[cos(th) sin(th) 0; -sin(th) cos(th) 0; 0 0 1];
  Minv=[cos(th) -sin(th) 0; sin(th) cos(th) 0; 0 0 1];
  % translate to IC frame of reference
  pb=pb-repmat(IC, [length(pb), 1]);
  % anti rotate (i.e., to gantry angle of 0)
  pb=(Minv*pb')';

  % assuming SID=100
  % back project beams up by -50 cm

  s1=0.5;
  s2=50;
  s3=s1*0.5;

  pb(:,[1 3])=pb(:, [1 3])*s1;
  pb(:,2)=pb(:,2)+s2;

  for i=1:length(pb), 
    pb_new{i}=[pb(i, 1)+dx*s3, pb(i, 2),  pb(i, 3)+dy*s3 
	       pb(i, 1)-dx*s3,  pb(i, 2),  pb(i, 3)+dy*s3 
	       pb(i, 1)-dx*s3,  pb(i, 2),  pb(i, 3)-dy*s3];
  end

  % rotate by the gantry angle
  
  for i=1:length(pb), 
    pb_rot{i}=(M*pb_new{i}')' + repmat(IC, [3 1]);
  end

  % include the offset from the CT image
  
  virtualSource=[IM.beams(beamIndex).x-offset(3), offset(2)-IM.beams(beamIndex).y, IM.beams(beamIndex).z-offset(5)];

  IC=[IC(1)-offset(3) offset(2)-IC(2) IC(3)-offset(5)];


  for i=1:length(pb), 
    pb_rot{i}=pb_rot{i}-repmat([offset(3) 0 offset(5)], [3 1]);
    pb_rot{i}(:,2)=offset(2)-pb_rot{i}(:,2);
  end

  % rounding because VMC++ requires the edges of the beamlet form
  % a square, by testing the dot product
  for i=1:length(pb), 
    temp=pb_rot{i};
    pb_rot{i}(:,1)=temp(:,2);
    pb_rot{i}(:,2)=temp(:,1);
    pb_rot{i}=round(pb_rot{i}*100000)/100000;
  end


  VMCOpt.startBeamletSource.virtualPointSourcePosition = ...
      [virtualSource(2) virtualSource(1) virtualSource(3)];

  for i=1:length(pb_rot), 

    VMCOpt.startBeamletSource.beamletEdges= [pb_rot{i}(1, :), pb_rot{i}(2,:),pb_rot{i}(3, :)];
    outfile=['MCpencilbeam_', int2str(beamIndex), '_', int2str(i), '.vmc'];
    VMCInputC = makeVMCInput(VMCOpt, outfile);
  end

  clear pb pb_new pb_rot
end