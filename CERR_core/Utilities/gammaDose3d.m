function gammaM = gammaDose3d(doseArray1, doseArray2, deltaXYZv, doseAgreement, distAgreement, maxDistance, thresholdAbsolute)
% function gammaM = gammaDose3d(doseArray1, doseArray2, deltaXYZv, doseAgreement, distAgreement, maxDistance, thresholdAbsolute)
%
% Block-wise comparison for each voxel.
%
% APA, 08/28/2015

deltaX = deltaXYZv(1);
deltaY = deltaXYZv(2);
deltaZ = deltaXYZv(3);

% Get Block size to process
if ~exist('maxDistance', 'var') || (exist('maxDistance', 'var') && isempty(maxDistance))
    maxDistance = distAgreement*2;
end
%maxDistance = 1; % cm
slcWindow = floor(2*maxDistance/deltaZ);
rowWindow = floor(2*maxDistance/deltaY);
colWindow = floor(2*maxDistance/deltaX);

% Make sure that the window is of odd size
if mod(slcWindow,2) == 0
    slcWindow = slcWindow + 1;
end
if mod(rowWindow,2) == 0
    rowWindow = rowWindow + 1;
end
if mod(colWindow,2) == 0
    colWindow = colWindow + 1;
end

% Build distance matrices
numCols = floor(colWindow/2);
numRows = floor(rowWindow/2);
numSlcs = floor(slcWindow/2);
xV = -numCols*deltaX:deltaX:numCols*deltaX;
yV = -numRows*deltaY:deltaY:numRows*deltaY;
zV = -numSlcs*deltaZ:deltaZ:numSlcs*deltaZ;
[yM,xM] = ndgrid(yV,xV);
xysq = xM(:).^2 + yM(:).^2;

% Pad doseArray2 so that sliding window works also for the edge voxels
doseArray2 = padarray(doseArray2,[floor(rowWindow/2) floor(colWindow/2) floor(slcWindow/2)],NaN,'both');

% Create indices for 2D blocks
[m,n,~] = size(doseArray2);
m = uint32(m);
n = uint32(n);
colWindow = uint32(colWindow);
rowWindow = uint32(rowWindow);
slcWindow = uint32(slcWindow);

% Index calculation adapted from 
% http://stackoverflow.com/questions/25449279/efficient-implementation-of-im2col-and-col2im

%// Start indices for each block
start_ind = reshape(bsxfun(@plus,[1:m-rowWindow+1]',[0:n-colWindow]*m),[],1); %//'

%// Row indices
lin_row = permute(bsxfun(@plus,start_ind,[0:rowWindow-1])',[1 3 2]);  %//'

%// Get linear indices based on row and col indices and get desired output
% imTmpM = A(reshape(bsxfun(@plus,lin_row,[0:ncols-1]*m),nrows*ncols,[]));
indM = reshape(bsxfun(@plus,lin_row,(0:colWindow-1)*m),rowWindow*colWindow,[]);

gammaM = Inf*zeros(size(doseArray1),'single');
% Find regions of zero dose and exclude from calculation
gammaM(doseArray1 <= thresholdAbsolute) = 0;

% Update waitbar on gamma GUI
gammaGUIFig = findobj('tag','CERRgammaInputGUI');
if ~isempty(gammaGUIFig)
    ud = get(gammaGUIFig,'userdata');
    set(ud.wb.patch,'xData',[0 0 0 0])
end

tic
siz = size(doseArray1(:,:,1));
numSlices = size(doseArray1,3);
for slcNum = 1:numSlices
    disp(['--- Gamma Calculation for Slice # ', num2str(slcNum), ' ----'])
    gammaV = gammaM(:,:,slcNum);
    gammaV = gammaV(:)';
    slc1M = doseArray1(:,:,slcNum);
    slcCount = 1;
    for slc = slcNum:slcWindow+slcNum-1
        slc2M = doseArray2(:,:,slc);
        tmpGammaV = bsxfun(@minus,slc2M(indM),slc1M(:)');
        tmpGammaV = bsxfun(@plus,tmpGammaV.^2/doseAgreement^2 , (xysq + zV(slcCount)^2) / distAgreement^2);
        gammaV = min(gammaV,min(tmpGammaV));
        gammaM(:,:,slcNum) = reshape(gammaV,siz);
        slcCount = slcCount + 1;
    end
    if ~isempty(gammaGUIFig)
        set(ud.wb.patch,'xData',[0 0 slcNum/numSlices slcNum/numSlices])
        drawnow
    end    
end
gammaM = gammaM.^0.5;
toc
set(ud.wb.patch,'xData',[0 0 1 1])





% % APA, 04/27/2012
% 
% deltaX = deltaXYZv(1);
% deltaY = deltaXYZv(2);
% deltaZ = deltaXYZv(3);
% incrementRadius = min([deltaX deltaY deltaZ]);
% 
% % Initial gamma
% gammaM = ((doseArray1-doseArray2).^2).^0.5/doseAgreement;
% %convergedM = false(size(gammaM));
% 
% % Find regions of zero dose and exclude from calculation
% if ~exist('thresholdAbsolute', 'var') 
%     thresholdAbsolute = 0;
% end
% convergedM = doseArray1 <= thresholdAbsolute;
% %convergedM = doseArray1 >= thresholdAbsolute; % for MR scan
% gammaM(convergedM) = NaN;
% 
% % Calculate until 4 times the permissible distance to agreement.
% if ~exist('maxDistance', 'var') || (exist('maxDistance', 'var') && isempty(maxDistance))
%     maxDistance = distAgreement*4;
% end
% outerRadiusV = incrementRadius:incrementRadius:maxDistance;
% numIters = length(outerRadiusV);
% 
% siz = size(gammaM);
% minDoseDiffM = zeros(siz,'single');
% maxDoseDiffM = minDoseDiffM;
% 
% % convergenceCountM = zeros(siz,'uint8');
% 
% % Update waitbar on gamma GUI
% gammaGUIFig = findobj('tag','CERRgammaInputGUI');
% if ~isempty(gammaGUIFig)
%     ud = get(gammaGUIFig,'userdata');
%     set(ud.wb.patch,'xData',[0 0 0 0])
% end
% 
% for radNum = 1:numIters
%     
%     disp(['--- Gamma Calculation Iteraion ', num2str(radNum), ' ----'])    
%     
%     % Create an ellipsoid ring neighborhood
%     outerRadius = outerRadiusV(radNum);    
%     
%     rowOutV = floor(outerRadius/deltaY);
%     colOutV = floor(outerRadius/deltaX);
%     slcOutV = floor(outerRadius/deltaZ);
%         
%     NHOOD_outer = createEllipsoidNHOOD(1:rowOutV,1:colOutV,1:slcOutV);
%     
%     % Compute Min and Max for the ellipsoid neighborhood
%     [minLocalM, maxLocalM] = getMinMaxIM(doseArray2,NHOOD_outer);
%     
%     % Compute difference between dose1 and (min,max) for dose2
%     minDoseDiffM(~convergedM) = doseArray1(~convergedM) - minLocalM(~convergedM);
%     maxDoseDiffM(~convergedM) = maxLocalM(~convergedM) - doseArray1(~convergedM);
%     
%     % If dose1 is contained within (min,max) for dose2, then it converged!
%     newConvergedM = ~convergedM & minDoseDiffM >= 0 & maxDoseDiffM >= 0;
%     
%     % Compute gamma for voxels that converged
%     gammaM(newConvergedM) =  min(gammaM(newConvergedM), outerRadius/distAgreement);
%     
%     % Add newly converged voxels to the list
%     convergedM = convergedM | newConvergedM;    
%     
%     % Compute gamma for voxels that have not yet converged
%     gammaForNotConvergedM =  (min((minDoseDiffM(~convergedM)-doseAgreement).^2, (maxDoseDiffM(~convergedM)-doseAgreement).^2)./doseAgreement^2 + (outerRadius/distAgreement)^2).^0.5;
%     gammaM(~convergedM) = min(gammaM(~convergedM), gammaForNotConvergedM);
%        
%     % If gamma is less or equal to outerRadius/distAgreement, then the voxel conveged!
%     convergedM(~convergedM) = gammaM(~convergedM) <= outerRadius/distAgreement;
%     
% %     % Count number of consecutive gamma increments for each uncoverged voxel
% %     indConvergeM = false(size(gammaM));
% %     indConvergeM(~convergedM) = gammaM(~convergedM) <= gammaForNotConvergedM;
% %     convergenceCountM(indConvergeM) = convergenceCountM(indConvergeM) + 1;
% %     
% %     % If gamma increases 4 consecutive times for a voxel, then assume it has converged
% %     convergedM(convergenceCountM > 3) = 1;
%     
%     if ~isempty(gammaGUIFig)
%         set(ud.wb.patch,'xData',[0 0 radNum/numIters radNum/numIters])
%         drawnow
%     end
%         
%     if all(convergedM(:))
%         disp('All converged!!!')
%         if ~isempty(gammaGUIFig)
%             set(ud.wb.patch,'xData',[0 0 1 1])
%         end
%         break
%     end
%     
% end

