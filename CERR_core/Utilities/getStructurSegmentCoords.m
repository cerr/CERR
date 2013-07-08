function pointsM = getStructurSegmentCoords(structNum)
% function pointsM = getStructurSegmentCoords(structNum)
%
% This function returns x,y,z coordinates of all the segments belonging to
% the passed structNum
%
% APA, 8/7/2013

pointsM = [];
for i=length(planC{indexS.structures}(structNum).contour)
    for segNum = 1:length(planC{indexS.structures}(structNum).contour(i).segments)
        pointsM = [pointsM planC{indexS.structures}(structNum).contour(i).segments(segNum).points];
    end
end

