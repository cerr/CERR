function [edges,uqIntensityV,histM] = getPrePostHist(planC,FGTStrIdV,norm)
% ------------------------------------------------------------
% INPUTS
% planC    
% FGTStrIdV : Structure nos. corresponding to FGT seg
% norm      : Normalize pre and post scans if norm==1 (default:0)
% -------------------------------------------------------------

%Defaults
if ~exist('norm','var')
    norm = 0;
end

%Identify series'
preScanIdx = 2;
postDeformedScanIdx = 5;

%Get scandata (pre & post) 
FGTMask3M = getUniformStr(FGTStrIdV(1), planC); % FGTStrIdV(1): Pre-contrast FGT mask
preScan3M = double(getScanArray(preScanIdx,planC));
postScan3M = double(getScanArray(postDeformedScanIdx,planC));
FGTMaskSlicesV = logical(squeeze(sum(sum(FGTMask3M))));
preScan3M = preScan3M(:,:,FGTMaskSlicesV);
postScan3M = postScan3M(:,:,FGTMaskSlicesV);

if norm==1
preScan3M = imNorm(preScan3M);
postScan3M = imNorm(postScan3M);
end

%Get voxel intensities within FGT mask
preScanV = preScan3M(FGTMask3M(:,:,FGTMaskSlicesV));
postScanV = postScan3M(FGTMask3M(:,:,FGTMaskSlicesV));

%Generate histogram
uqIntensityV = unique(preScanV);
if norm==1
edges = 0:256;
else
   nBins = 500;
   binWidth = round((max(postScanV)-min(postScanV))/nBins);
   %binWidth = 10;
   edges = round(min(postScanV)):binWidth:round(max(postScanV)); 
end

histM = zeros(numel(uqIntensityV),numel(edges)-1);
for l = 1:numel(uqIntensityV)
    idx = round(preScanV)==uqIntensityV(l);
    postV = postScanV(idx);
    countV = histcounts(postV,edges); 
    histM(l,:) = countV;
end



%--- Sub-function -----%
    function normImg3M = imNorm(image3M)
       newMax = 255;
       newMin = 0;
       Imax = max(max(image3M,[],2),[],1);
       Imin = min(min(image3M,[],2),[],1);
       % In = (I - Imin) * (newMax - newMin)/(Imax-Imin) + newMin
       sub = bsxfun(@minus,image3M,Imin);
       scale = (newMax - newMin)./(Imax - Imin);
       normImg3M = bsxfun(@times,sub,scale) + newMin;
    end
end