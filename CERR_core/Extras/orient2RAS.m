function [vol3M, affineMat] = orient2RAS(volArray, affineMat, originRAS, pixDim, orientationStr)

vol3M = permute(volArray,[2 1 3]);

originLPS = affineMat(1:3,3);

orientMat = zeros(4,4);
orientMat(4,4) = 1;

if strcmpi(orientationStr,'HFS')
    orientMat(2,1) = -1;
    vol3M = flip(vol3M,1);
    orientMat(1,2) = -1;
    vol3M = flip(vol3M,2);
    orientMat(3,3) = -1;
    vol3M = flip(vol3M,3);
elseif strcmpi(orientationStr,'HFP')
    orientMat(2,1) = 1;
    originRAS(1) = -originLPS(1);
    orientMat(1,2) = 1;
    originRAS(2) = -originLPS(2);
    orientMat(3,3) = -1;
    vol3M = flip(vol3M,3);
elseif strcmpi(orientationStr,'FFP')
    orientMat(2,1) = -1;
    vol3M = flip(vol3M,1);
    orientMat(1,2) = 1;
%     vol3M = flipdim(vol3M,2);
    originRAS(2) = -pixDim(2)*(size(vol3M,2) - (abs(originLPS(2)) / pixDim(2)));
    orientMat(3,3) = -1;
    vol3M = flip(vol3M,3);
else %FFS
    orientMat(2,1) = -1;
    vol3M = flip(vol3M,1);
    originRAS(1) = -pixDim(1)*(size(vol3M,1) - (abs(originLPS(1)) / pixDim(1)));
    orientMat(1,2) = 1;
    originRAS(2) = -originLPS(2);
    orientMat(3,3) = -1;
    vol3M = flip(vol3M,3);
end
% 
% if strcmpi(orientationStr{2,2},'R')
%     orientMat(2,1) = 1;
%     originRAS(1) = -originLPS(1);
% else
%     orientMat(2,1) = -1;
%     vol3M = flipdim(vol3M,1);
% %     originRAS(1) = -pixDim(1)*(size(vol3M,1) - (abs(originLPS(1)) / pixDim(1)));
% end
% if strcmpi(orientationStr{1,2},'A')
%     orientMat(1,2) = 1;
%     originRAS(2) = -originLPS(2);
% else
%     orientMat(1,2) = -1;
%     vol3M = flipdim(vol3M,2);
% %     originRAS(2) = -pixDim(2)*(size(vol3M,2) - (abs(originLPS(2)) / pixDim(2)));
% end
% if strcmpi(orientationStr{3,2},'S')
%     orientMat(3,3) = 1;
%     originRAS(3) = -originLPS(3);
% else
%     orientMat(3,3) = -1;
%     vol3M = flipdim(vol3M,3);
% %     originRAS(3) = -pixDim(3)*(size(vol3M,3) - (abs(originLPS(3)) / pixDim(3)));
% end

newMat = affineMat * orientMat;
newMat(1:3,end) = originRAS(1:3);
affineMat = newMat;