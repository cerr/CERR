function [resampSigM,TTHPv,SHPv,timeOutV] = halfPeak(ROIDataM,timeV,smoothFlag,resampFlag)
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

%% Smooth/resample if selected
nVox = size(ROIDataM,1);
[resampSigM,timeOutV] = smoothResamp(ROIDataM,timeV,smoothFlag,resampFlag);
normalizedBaseline = 1;
relSigEnhM = resampSigM - normalizedBaseline;

%% Compute TTHP, SHP
%Identify first time point where changeSig > half-peak
gts50 = bsxfun(@ge,relSigEnhM,(max(resampSigM,[],2) - normalizedBaseline)/2);
[~,SHPcolIdx] = max(gts50,[],2);
SHProwIdx = (1:nVox).';
SHPidx = sub2ind([nVox,numel(timeOutV)],SHProwIdx,SHPcolIdx);
%Get signal at half-peak
SHPv = resampSigM(SHPidx).';
%Get time to half-peak
TTHPv = timeOutV(1,SHPcolIdx);

end
