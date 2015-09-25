function writeInfluenceMatrixBixel(IM, structNum, planC, outFile)
%"writeInfluenceMatrixBixel"
%   Write the bixel information to binary file.
%
%   All beams in one file, for each beam:
%       float    a_g, a_t, a_c  - gantry, table and collimator angles
%       float    dx_b, dy_b     - bixel dimensions 
%       float    dx, dy, dz     - voxel dimensions   
%       int      Nx, Ny, Nz     - dose cube dimensions (number of voxels)
%       int      Npb            - number of pencil beams (bixels) used for this field
%       float    DoseScalefactor- conversion factor to the absolute dose, for the best resolution, this will be max(Dij_entry)/max(short) = max(Dij_entry)/(2^15-1)
% 
%       For each of Npb bixels:
%           PB header:  
%           float    energy         - energy
%           float    spot_x, spot_y - position of the bixel w/ respect to the central axis of the field
%           int      Nvox           - number of voxels with non-zero dose from this beamlet
%
%           For each of Nvox voxels:
%               int      VoxelNumber    - voxel ID in the cube (between 1 and Nx*Ny*Nz)
%               short    Value          - multiply this by DoseScalefactor to get the dose deposited by this beamlet to the voxel VoxelNumber, assuming the beamlet weight of 1
%
% Repeat for each beam.
%
% JRA 3/11/04
%
%Usage:
%   function writeInfluenceMatrixBixel(IM, structNum, planC, outFile)
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

indexS = planC{end};

%Open file
if nargin < 4   %default
    outFile = 'c:\tmp\default.txt'
else
    outFile
end
fid = fopen(outFile,'w+');

%Rows of inflM are voxels, columns are PBs.
disp('Constructing influence matrix...')
[inflM] = getGlobalInfluenceM(IM, structNum);
disp('Done.')

%Find indices of voxels with nonzero dose.
indexV = find(any(inflM,2));

%Get total number of non zero voxels for each bixel.
nnzVoxelsPerBixel = full(sum(inflM ~= 0, 1));

%Get beamNumber for each beamlet.
beamN = [IM.beamlets(structNum, :).beamNum];

%Index map from influence beamlets to beam style beamlets
for i = 1:length(IM.beams)
    beamletsPerBeam([IM.beamlets(structNum, :).beamNum] == i) = find([IM.beamlets(structNum, :).beamNum] == i);
end

%For each beam...
for beamNum = 1:length(IM.beams)
	%Generate header info.
	a_g = IM.beams(beamNum).gantryAngle;
	a_t = IM.beams(beamNum).couchAngle;
    if isempty(a_t), a_t = 0; end
	a_c = IM.beams(beamNum).collimatorAngle;
    if isempty(a_c), a_c = 0; end
	
	dx_b = IM.beams(beamNum).beamletDelta_x;
	dy_b = IM.beams(beamNum).beamletDelta_y;
	
	dx = planC{indexS.scan}.uniformScanInfo.grid2Units;
	dy = planC{indexS.scan}.uniformScanInfo.grid1Units;
	dz = planC{indexS.scan}.uniformScanInfo.sliceThickness;
	
	siz = getUniformizedSize(planC)
	Nx = siz(1);
	Ny = siz(2);
	Nz = siz(3);
	
	Npb = length(find([IM.beamlets(structNum, :).beamNum] == beamNum));
	
    %Find bixels belonging to this beam.
    myBixels = find([IM.beamlets(structNum, :).beamNum] == beamNum);

    %Scale determined by maximum value contributed to influence matrix from all bixels belonging to this beam. 
  	dScale = max(max(inflM(:, myBixels)))/(2^15-1);
    
	%Write header info:
	fwrite(fid, [a_g a_t a_c dx_b dy_b dx dy dz],'float32');
	fwrite(fid, [Nx Ny Nz Npb], 'int32');
    fwrite(fid, dScale, 'float32');
    
	%For every beamlet in this beam...
	for i = myBixels
        %Prepare data that will be written.
        bE     = IM.beams(beamNum).beamEnergy;
        spot_x = IM.beams(beamNum).xPBPosV(beamletsPerBeam(i));
        spot_y = IM.beams(beamNum).yPBPosV(beamletsPerBeam(i));
        nVox   = nnzVoxelsPerBixel(i);
        voxNum = find(inflM(:,i));
        %Convert to KonRad Cube.
        voxI = KonRadCube(voxNum, siz);
        doses = full(inflM(voxNum, i)) / dScale;      

        %Write it.                
        write  = fwrite(fid, bE,'float32');
        write  = fwrite(fid, spot_x,'float32');    
        write  = fwrite(fid, spot_y,'float32');    
        write  = fwrite(fid, nVox,'uint32');    
                  
        %Use seeking+skips to interleave values.
        pos = ftell(fid);
        fseek(fid, -2, 'cof');
        write = fwrite(fid, voxI,'int32', 2);
        fseek(fid, pos, 'bof');
        write = fwrite(fid, doses,'ushort', 4);
        
        if mod(i,200) == 0
            disp(['Processed ' num2str(i) ' bixels for beam ' num2str(beamNum) '.']);
        end
    end
end	
clear inflM;

disp('Done.');
fclose(fid);