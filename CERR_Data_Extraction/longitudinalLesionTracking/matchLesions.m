function [lesionMapping, scan2LesionS] = matchLesions(scan1LesionS, scan2LesionS, scanNum1, scanNum2, scan1PlanC, scan2PlanC)
% function lesionMapping = matchLesions(scan1LesionS, scan2LesionS, scanNum1, scanNum2, scan1PlanC, scan2PlanC)
%
% This function returns mapping between lesions on scan1 and scan2.
%
% APA, 04/17/2013

index1S = scan1PlanC{end};
index2S = scan2PlanC{end};

scan1UID = scan1PlanC{index1S.scan}.scanUID;
scan2UID = scan2PlanC{index2S.scan}.scanUID;

baseMapV = strcmp(scan1UID,{scan1PlanC{index1S.deform}.baseScanUID});
movMapV = strcmp(scan2UID,{scan1PlanC{index1S.deform}.movScanUID});
deformIndex = find(baseMapV & movMapV);
deformIndex = deformIndex(end);

allLesionPtsM = [];
lesionStartIndV = [];
for lesionNum = 1:length(scan1LesionS)
    allLesionPtsM = [allLesionPtsM; scan1LesionS(lesionNum).xV scan1LesionS(lesionNum).yV scan1LesionS(lesionNum).zV];
    lesionStartIndV = [lesionStartIndV size(allLesionPtsM,1)-length(scan1LesionS(lesionNum).xV)+1];
end

% Deform all lesion points from scan1 to scan2
[xDeformV,yDeformV,zDeformV] = getDeformationAt(scan1PlanC{index1S.deform}(deformIndex),scan2PlanC,scanNum2,scan1PlanC,scanNum1,allLesionPtsM);

for i = 1:length(lesionStartIndV)-1
   xyzDeformC{i} = [scan1LesionS(i).xV scan1LesionS(i).yV scan1LesionS(i).zV] + [xDeformV(lesionStartIndV(i):lesionStartIndV(i+1)-1),yDeformV(lesionStartIndV(i):lesionStartIndV(i+1)-1),zDeformV(lesionStartIndV(i):lesionStartIndV(i+1)-1)];
end
xyzDeformC{end+1} = [scan1LesionS(end).xV scan1LesionS(end).yV scan1LesionS(end).zV] + [xDeformV(lesionStartIndV(end):end),yDeformV(lesionStartIndV(end):end),zDeformV(lesionStartIndV(end):end)];

% Match scan1LesionS with those on scan # 2
for lesionNum = 1:length(xyzDeformC)
    lesionMapping(lesionNum,1) = lesionNum;
    hausdorffDistV = [];
    for matchLesionNum = 1:length(scan2LesionS)
        xyzMatchedLesion = [scan2LesionS(matchLesionNum).xV scan2LesionS(matchLesionNum).yV scan2LesionS(matchLesionNum).zV];
        hausdorffDistV(matchLesionNum) = hausdorff(xyzDeformC{lesionNum},xyzMatchedLesion);
        meanDistV(matchLesionNum) = sqrt(sum((mean(xyzDeformC{lesionNum})-mean(xyzMatchedLesion)).^2));
    end
    [minHausDist, matchHausIndex] = min(hausdorffDistV);
    [minMeanDist, matchMeanIndex] = min(meanDistV);
    if matchMeanIndex == matchHausIndex && (minHausDist < 3 || minMeanDist < 3)
        lesionMapping(lesionNum,2) = matchHausIndex;
        lesionMapping(lesionNum,3) = minHausDist;
        lesionMapping(lesionNum,4) = minMeanDist;
    else
        % Create new (Predicted) lesion on scan 2
        numLesionsOnScan2 = length(scan2LesionS);
        scan2LesionS(numLesionsOnScan2+1).xV = xyzDeformC{lesionNum}(:,1);
        scan2LesionS(numLesionsOnScan2+1).yV = xyzDeformC{lesionNum}(:,2);
        scan2LesionS(numLesionsOnScan2+1).zV = mean(xyzDeformC{lesionNum}(:,3))*xyzDeformC{lesionNum}(:,3).^0;
        scan2LesionS(numLesionsOnScan2+1).assocScanUID = scan2LesionS(1).assocScanUID;
        scan2LesionS(numLesionsOnScan2+1).assocAnnotUID = '';
        scan2LesionS(numLesionsOnScan2+1).graphicNumsV = [];
        lesionMapping(lesionNum,2) = numLesionsOnScan2+1;
        lesionMapping(lesionNum,3) = minHausDist;
        lesionMapping(lesionNum,4) = minMeanDist;
    end    
end

