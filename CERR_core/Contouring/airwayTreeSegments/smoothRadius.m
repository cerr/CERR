function minDistSmoothV = smoothRadius(nodeXyzBaseM,centerTreeXyzBaseM,minDistBaseV)
% function minDistSmoothV = smoothRadius(nodeXyzBaseM,centerTreeXyzBaseM,minDistBaseV)
%
% APA, 6/3/2021

distM = sepsq(nodeXyzBaseM',centerTreeXyzBaseM');
[~,indSortedM] = sort(distM,2,'ascend');
minDistSmoothV = mean(minDistBaseV(indSortedM(:,1:3)),2);


