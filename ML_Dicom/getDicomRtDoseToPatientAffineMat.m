function dosePositionMatrix = getDicomRtDoseToPatientAffineMat(doseNum,planC)
% function dosePositionMatrix = getDicomRtDoseToPatientAffineMat(scanNum,planC)
% 
% Based on https://nipy.org/nibabel/dicom/dicom_orientation.html#dicom-slice-affine
%
% APA, 11/16/2021

if exist('planC','var')
    indexS = planC{end};
end
if isstruct(doseNum)
    doseS = doseNum;
else
    doseS = planC{indexS.doseS}(doseNum);
end
 

vec1 = doseS.imageOrientationPatient(1:3);
vec2 = doseS.imageOrientationPatient(4:6);
vec3 = cross(vec1,vec2);
%vec3 = vec3 * (info.GridFrameOffsetVector(2)-info.GridFrameOffsetVector(1));
vec3 = vec3 * (doseS.zValues(2)-doseS.zValues(1))*10; % factor of 10 to go to DICOM mm
pos1 = doseS.imagePositionPatient;

% positionMatrix translate voxel indexes to physical
% coordinates
pixelSpacing = [-doseS.verticalGridInterval, doseS.horizontalGridInterval]*10;
% dosePositionMatrix = [reshape(doseS.imageOrientationPatient,[3 2])*diag(info.PixelSpacing) [vec3(1) pos1(1);vec3(2) pos1(2); vec3(3) pos1(3)]];
dosePositionMatrix = [reshape(doseS.imageOrientationPatient,[3 2])*diag(pixelSpacing) [vec3(1) pos1(1);vec3(2) pos1(2); vec3(3) pos1(3)]];
dosePositionMatrix = [dosePositionMatrix; 0 0 0 1];




% 
% dosedim = size(doseS.doseArray);
% 
% % Need to figure out coord1OFFirstPoint,
% % coord2OFFirstPoint, horizontalGridInterval,
% % verticalGridInterval and zValues
% 
% % xOffset = iPP(1) + (pixspac(1) * (nCols - 1) / 2);
% % yOffset = iPP(2) + (pixspac(2) * (nRows - 1) / 2);
% 
% vecs = [0 0 0 1; 1 1 0 1; (dosedim(2)-1)/2 (dosedim(1)-1)/2 0 1];
% vecsout = (dosePositionMatrix*vecs'); % to physical coordinates
% vecsout(1:3,:) = vecsout(1:3,:)/10;
% vecsout = positionMatrix \ vecsout;  % to MR image index (not doseS voxel index)
% vecsout = virPosMtx * vecsout; % to the virtual coordinates
% 
% % doseS.coord1OFFirstPoint = vecsout(1,3);
% % doseS.coord2OFFirstPoint = vecsout(2,3);
% doseS.coord1OFFirstPoint = vecsout(1,1);
% doseS.coord2OFFirstPoint = vecsout(2,1);
% doseS.horizontalGridInterval = vecsout(1,2) - vecsout(1,1);
% doseS.verticalGridInterval = vecsout(2,2) - vecsout(2,1);
% 
% % APA commented ====== get z-grid using GridFrameOffset
% % vecs = [zeros(2,dosedim(3));0:(dosedim(3)-1);ones(1,dosedim(3))];
% % vecsout = (dosePositionMatrix*vecs); % to physical coordinates
% % vecsout(1:3,:) = vecsout(1:3,:)/10;
% % vecsout = positionMatrix \ vecsout;  % to MR image index (not doseS voxel index)
% % vecsout = virPosMtx * vecsout; % to the virtual coordinates
% % zValuesV = vecsout(3,:)';
% % APA commented ends
% 
% % APA added to get zValues in virtual coordinates
% zValuesV = vecsout(3,1) + doseS.zValues - doseS.imagePositionPatient(3)/10;
