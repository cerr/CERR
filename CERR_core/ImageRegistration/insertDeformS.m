function planC = insertDeformS(planC,deformS)

indexS = planC{end};

deformIndex = length(planC{indexS.deform}) + 1;
planC{indexS.deform}  = dissimilarInsert(planC{indexS.deform},deformS,deformIndex);
