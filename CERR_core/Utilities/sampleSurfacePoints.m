function [xSampleV,ySampleV,zSampleV] = sampleSurfacePoints(structNum,deltaLength,planC)
% function [xSampleV,ySampleV] = sampleSurfacePoints(structNum,deltaLength,planC)
%
% APA, 1/9/2020

if ~exist('planC','var')
    global planC
end

indexS = planC{end};

assocScan = getStructureAssociatedScan(structNum,planC);
numSlices = length(planC{indexS.structures}(structNum).contour);

xSampleV = [];
ySampleV = [];
zSampleV = [];

for j = 1 : numSlices
    
    %Try and access the points for this slice.  If fail, continue to
    %next slice.
    try
        nPts = length(planC{indexS.structures}(structNum).contour(j).segments(1).points);
    catch
        continue;
    end
    
    if nPts ~=0
        CERRStatusString(['Getting surface points for structure ' num2str(structNum) ', slice ' num2str(j) '.'])
    end
    
    numSegs = length(planC{indexS.structures}(structNum).contour(j).segments);
    
    for k = 1 : numSegs
        
        pointsM = planC{indexS.structures}(structNum).contour(j).segments(k).points;
        
        if ~isempty(pointsM)
            
            [xV, yV, lengthV] = surfacePoints(pointsM(:,1:2), deltaLength);
            
            delta_z = planC{indexS.scan}(assocScan).scanInfo(j).voxelThickness;
            
            areaV = lengthV * delta_z;
            
            zValue = pointsM(1,3);
            
            zV = ones(length(xV),1) * zValue;
            
            xSampleV = [xSampleV; xV];
            ySampleV = [ySampleV; yV];
            zSampleV = [zSampleV; zV];
                        
        end
        
    end
    
end
