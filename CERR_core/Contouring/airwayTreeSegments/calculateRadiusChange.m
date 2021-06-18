function nodeDiffV = calculateRadiusChange(baseXyzM,followupXyzM,...
    minDistBaseV,minDistFollowupV,distTolerance,...
    vf,xFieldV,yFieldV,zUnifV)
% function nodeDiffV = calculateRadiusChange(baseXyzM,followupXyzM,distTolerance,...
%     vf,xFieldV,yFieldV,zUnifV)
%
% APA, 6/3/2021

% Calculate difference in radius between folloup and baseline
xDeformV = finterp3(baseXyzM(:,1),baseXyzM(:,2),baseXyzM(:,3),...
    flip(vf(:,:,:,1),1),xFieldV,yFieldV,zUnifV);
yDeformV = finterp3(baseXyzM(:,2),baseXyzM(:,2),baseXyzM(:,3),...
    flip(vf(:,:,:,2),1),xFieldV,yFieldV,zUnifV);
zDeformV = finterp3(baseXyzM(:,1),baseXyzM(:,2),baseXyzM(:,3),...
    flip(vf(:,:,:,3),1),xFieldV,yFieldV,zUnifV);

nodeXyzInterpM = baseXyzM + [xDeformV(:), yDeformV(:), zDeformV(:)];

distM = sepsq(nodeXyzInterpM',followupXyzM');

[minDistNodesV,minIndV] = min(distM,[],2);
nodeDiffV = zeros(1,size(baseXyzM,1));
indValidV = minDistNodesV(:) < distTolerance^2; %medianDistBaseV(:).^2; % 0.2
% Percent change
nodeDiffV(indValidV) = (minDistFollowupV(minIndV(indValidV)) - ...
    minDistBaseV(indValidV))./(minDistBaseV(indValidV)+1e-5)*100;
% nodeDiffV(indValidV) = (minDistV(minIndV(indValidV)) - ...
%     minDistBaseV(indValidV));
nodeDiffV(nodeDiffV>50) = 50;
nodeDiffV(~indValidV) = -100;
