function planC = smoothContour(structNum,planC)
% function planC = smoothContour(structNum,planC)
%
% Smooths contour segments using spcrv
%
% APA, 03/09/2021

indexS = planC{end};
for slc = 1:length(planC{indexS.structures}(structNum).contour)
    for seg = 1:length(planC{indexS.structures}(structNum).contour(slc).segments)
        ptsM = planC{indexS.structures}(structNum).contour(slc).segments(seg).points;
        if isempty(ptsM)
            continue;
        end
        numPts = size(ptsM,1);
        intrvl = ceil(numPts*0.2/10);
        pts1M = spcrv(ptsM(1:intrvl:end,1:2)',3,100)';
        pts1M(:,3) = ptsM(1,3)*pts1M(:,1).^0;
        pts1M(end+1,:) = pts1M(1,:);
        planC{indexS.structures}(structNum).contour(slc).segments(seg).points = pts1M;
    end
end
planC = getRasterSegs(planC, structNum);



