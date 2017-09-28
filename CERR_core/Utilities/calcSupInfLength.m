function siLen = calcSupInfLength(structNum,planC)
% function siLen = calcSupInfLength(structNum,planC)
%
% This function computes the length in SI direction for the passed structNum.
%
% APA, 9/28/2017

if ~exist('planC','var')
    global planC
end

indexS = planC{end};

% Initialize min/max
maxZ = -inf;
minZ = inf;

% Loo over all transverse slices for z-values
for slc = 1:length(planC{indexS.structures}(structNum).contour)
    for seg = 1:length(planC{indexS.structures}(structNum).contour(slc).segments)
        if ~isempty(planC{indexS.structures}(structNum).contour(slc).segments(seg).points)
            zSegV = planC{indexS.structures}(structNum).contour(slc).segments(seg).points(:,3);
            minZ = min(minZ,zSegV(1));
            maxZ = max(maxZ,zSegV(1));
        end
    end
end

siLen = maxZ - minZ;

