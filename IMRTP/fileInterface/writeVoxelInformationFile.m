function writeVoxelInformationFile(IM, structNum, planC, outFile)
%"writeVoxelInformationFile"
%   Stores voxel data in a format similar to orart-cwg specification.
%
%   For all voxels receiving dose in IM:
%       int     voxel_ID        - voxel index, in KonRad coordinates.
%       float   x,y,z           - x,y,z location in RTOG coordinates
%       int     struct_type     - 32 bits of int indicate what structures
%                                 the voxel is contained in, ie if bit 1 is
%                                 on, voxel is in structure 1.
%       int     voxel_type      - 1 for boundary, 0 for interior
%       int     bixel_total     - number of bixels giving to this voxel
%       float   t_dose          - total dose voxel receives.
%
% JRA 3/11/04
%
%Usage:
%   function writeVoxelInformationFile(IM, structNum, planC, outFile)
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

%Prepare output vars.
sizeVec = [4 4 4 4 1 4 4 4];
cumVec = cumsum(sizeVec);
bytesPerVoxel = sum(sizeVec);

%Rows of inflM are voxels, columns are PBs.
disp('Constructing influence matrix...')
[inflM] = getGlobalInfluenceM(IM, structNum);
disp('Done.')

%Find indices of voxels with nonzero dose.
indexV = find(any(inflM,2));
s = getUniformizedSize(planC);

%Write Voxel IDS
disp('Writing Voxel IDs...');
voxel_ID = KonRadCube(indexV, s);
status = fseek(fid, 0,-1);
write = fwrite(fid, voxel_ID(1),   'uint32');
write = fwrite(fid, voxel_ID(2:end),   'uint32', bytesPerVoxel-4);
clear voxel_ID;

%Write X,Y,Z coords.
disp('Writing X, Y, Z coords...');
flag = 'uniform';
[rowV, colV, sliceV] = ind2sub(s, indexV);
[xV,yV,zV] = mtoxyz(rowV,colV,sliceV,planC,flag,s);
status = fseek(fid, cumVec(1),-1);
write = fwrite(fid, xV(1), 'float32');
write = fwrite(fid, xV(2:end), 'float32', bytesPerVoxel-4);

status = fseek(fid, cumVec(2),-1);
write = fwrite(fid, yV(1), 'float32');
write = fwrite(fid, yV(2:end), 'float32', bytesPerVoxel-4);

status = fseek(fid, cumVec(3),-1);
write = fwrite(fid, zV(1), 'float32');
write = fwrite(fid, zV(2:end), 'float32', bytesPerVoxel-4);
clear xV yV zV;


%Inflate uniformized data to find structures that each voxel is in.

disp('Writing structures containing voxel...');
mat = repmat(uint32(0), s);
bitsV = planC{indexS.structureArray}.bitsArray;
indV = planC{indexS.structureArray}.indicesArray;
for i = 1:length(bitsV)
    mat(indV(i,1), indV(i,2), indV(i,3)) = bitsV(i);
end

for i = 1:length(rowV)
    structsV(i) = mat(rowV(i),colV(i),sliceV(i));
end
clear mat;

%Write struct_type data.
struct_type = double(structsV');
status = fseek(fid, cumVec(4),-1);
write = fwrite(fid, struct_type(1),'uint32');
write = fwrite(fid, struct_type(2:end),'uint32', bytesPerVoxel-4);

%Get surface points for this structure;
mask3M = getUniformStr(structNum);
surfPoints = getSurfacePoints(mask3M);
clear mask3M;
surf3M = repmat(logical(0), s);
for i=1:size(surfPoints,1)
     surf3M(surfPoints(i,1),surfPoints(i,2), surfPoints(i,3)) = 1;
end
voxel_type = surf3M(indexV);
clear surf3M;

%Write voxel_type data.
disp('Writing surface index...');
status = fseek(fid, cumVec(4),-1);
write = fwrite(fid, voxel_type, 'uint8', bytesPerVoxel-1);

%Get influence matrix for dose/bixel information.
disp('Writing cumulative dose and bixel totals...');
bixel_total = full(sum(inflM ~= 0, 2));
bixel_total = bixel_total(indexV);
t_dose = full(sum(inflM,2));
t_dose = t_dose(indexV);

%Write total number of bixels hitting this voxel.
status = fseek(fid, cumVec(6),-1);
write = fwrite(fid, bixel_total(1),'uint32');
write = fwrite(fid, bixel_total(2:end),'uint32', bytesPerVoxel-4);

%Write total dose administered to this voxel.
status = fseek(fid, cumVec(7),-1);
write = fwrite(fid, t_dose(1), 'float32');
write = fwrite(fid, t_dose(2:end), 'float32', bytesPerVoxel-4);
clear inflM;

fclose(fid);
disp('Done.');