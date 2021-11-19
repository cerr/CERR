function dcmPatientCoordM = convertCerrToDcmPoints(cerrPointsM,scanNum,planC)
%
% function dcmPatientCoordM = convertCerrToDcmPoints(cerrPointsM,scanNum,planC)
%
% Example: 
% global planC
% indexS = planC{end};
% scanNum = 1;
% cerrPointsM = planC{indexS.structures}(1).contour(35).segments(1).points;
% scanS = planC{indexS.scan}(scanNum);
% dcmPatientCoordM = convertCerrToDcmPoints(cerrPointsM,scanS);
%
% APA, 11/16/2021

if exist('planC','var')
    indexS = planC{end};
end
if isstruct(scanNum)
    scanS = scanNum;
else
    scanS = planC{indexS.scan}(scanNum);
end

% Convert contour points to DICOM r,c,s
[xs,ys,zs] = getScanXYZVals(scanS);
dx = xs(2)-xs(1);
dy = ys(2)-ys(1);
slice_distance = zs(2)-zs(1);
virPosMtx = [dx 0 0 xs(1);0 dy 0 ys(1); 0 0 slice_distance -zs(end); 0 0 0 1]; % (-)ve zs since CERR z is opposite of DICOM
cerrPointsM(:,3) = -cerrPointsM(:,3); % (-)ve since cerr z is opposite of DICOM
cerrPointsM = [cerrPointsM, ones(size(cerrPointsM,1),1)];
rcsM = virPosMtx \ cerrPointsM';

% Convert r,c,s to DICOM Patient coordinates (mm)
positionMatrix = getDicomImageToPatientAffineMat(scanS);
dcmPatientCoordM = positionMatrix * rcsM;
dcmPatientCoordM = dcmPatientCoordM(1:3,:)';



