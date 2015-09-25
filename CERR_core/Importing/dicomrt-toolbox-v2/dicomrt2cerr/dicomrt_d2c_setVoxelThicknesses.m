function planC = dicomrt_d2c_setVoxelThicknesses(planC,indexS)
% dicomrt_d2c_setVoxelThicknesses(planC,indexS)
%
% Set Voxel Thicknesses. Original code from  initializeCERR.
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 
CERRStatusString(['Using zValues to compute voxel thicknesses.'])
voxelThicknessV = deduceVoxelThicknesses(1,planC);
for i = 1 : length(voxelThicknessV)  %put back into planC
    planC{indexS.scan}.scanInfo(i).voxelThickness = voxelThicknessV(i);
end