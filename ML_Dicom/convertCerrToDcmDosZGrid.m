function zDicomV = convertCerrToDcmDosZGrid(doseS,scanS)
% function zDicomV = convertCerrToDcmDosZGrid(doseS,scanS)
%
% APA, 11/19/2021

imagePositionPatient = doseS.imagePositionPatient/10; % this is already in DICOM Patient coordinates

isOblique = 0;
doseOri = doseS.imageOrientationPatient;
obliqTol = 1e-4;
if ~isempty(doseOri) && max(abs(abs(doseOri(:)) - [1 0 0 0 1 0]')) > obliqTol
    isOblique = 1;
end

% Convert doseS.zValues from virtual to DICOM Patient coordinates
if ~isOblique
    % For non-oblique scans/doses, this transformation is simply (-)ve z-values to go back to DICOM coordinates
    zDicomV = -doseS.zValues; % tested only for non-oblique HFS dose
    %data = zDicomV - zDicomV(1);
else
    
    [xs,ys,zs] = getScanXYZVals(scanS);
    dx = xs(2)-xs(1);
    dy = ys(2)-ys(1);
    slice_distance = zs(2)-zs(1);
    virPosMtx = [dx 0 0 xs(1);0 dy 0 ys(1); 0 0 slice_distance zs(1); 0 0 0 1];

    %zDicomV = convertCerrToDcmDoseZgrid(doseS.zValues); % to be implemented
    positionMatrix = getDicomImageToPatientAffineMat(scanS);
    dosePositionMatrix = getDicomRtDoseToPatientAffineMat(doseS);
    dosedim = size(doseS.doseArray);
    
    vecs = [0 0 0 1; 1 1 0 1; (dosedim(2)-1)/2 (dosedim(1)-1)/2 0 1];
    vecsout = (dosePositionMatrix*vecs'); % to physical coordinates
    vecsout(1:3,:) = vecsout(1:3,:)/10;
    vecsout = positionMatrix \ vecsout;  % to MR image index (not dose voxel index)
    vecsout = virPosMtx * vecsout; % to the virtual coordinates
    
    % APA added to get zValues in virtual coordinates
    zDicomV = doseS.zValues - vecsout(3,1) + imagePositionPatient(3);
    
end
