function [resampSigM,t50V,s50V,timeOutV] = halfPeak(ROIDataM,timeV,smoothFlag,resampFlag)
% =======================================================================================
% AI  09/28/16
% AI  10/20/16  Added smoothing/resampling options.
% ======================================================================================
% INPUTS
% ROIDataM   : (no. voxels x time pts) Matrix of temporal signals of
%              raster-ordered voxels along rows
% timeV      : Vector of time pts of DCE image acquisition.
% smoothFlag : Flag (1-Smooth    0-No smoothing )
% resampFlag : Flag (1-Resample  0-No resampling )
% =====================================================================================

%Smooth/resample if selected
nVox = size(ROIDataM,1);
[resampSigM,timeOutV] = smoothResamp(ROIDataM,timeV,smoothFlag,resampFlag);
normalizedBaseline = 1;
changeSigM = resampSigM - normalizedBaseline;

%Compute t50,s50
gts50 = bsxfun(@ge,changeSigM,(max(resampSigM,[],2) - normalizedBaseline)/2);
[~,s50ColIdx] = max(gts50,[],2);
s50rowIdx = (1:nVox).';
s50Idx = sub2ind([nVox,numel(timeOutV)],s50rowIdx,s50ColIdx);
s50V = resampSigM(s50Idx).';
t50V = timeOutV(1,s50ColIdx);

end
