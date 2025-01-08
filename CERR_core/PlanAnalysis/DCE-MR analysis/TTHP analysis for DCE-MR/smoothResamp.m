function [resampSigM,timeOutV] = smoothResamp(sigM,timeV,smoothFlag,resampFlag)
% AI  09/28/16
% AI  10/20/16  Added smoothing for noise correction.
% =================================================================================
% INPUTS
% sigM       : (No. ROI voxels * No.slices x Time pts) Matrix of temporal signal of
%              raster-oredered voxels along rows (all slices)
% timeV      : Vector of time pts of DCE image acquisition
% smoothFlag : Flag (1-Smooth    0-No smoothing )
% resampFlag : Flag (1-Resample  0-No resampling)
% =================================================================================

%Filtering/resampling parameters
timeV = reshape(timeV,1,[]);
tdiff = timeV(2)-timeV(1);
ts = .01;
filtSiz = 6;             % Width of the smoothing window (N)
alpha = 5/2;             % Gaussian std dev = (N – 1)/(2*alpha) 
filtV = gausswin(filtSiz,alpha);
filtV = filtV./sum(filtV);
%Pad signal
nPad = 100;
padSigM = [repmat(sigM(:,1),1,nPad), sigM, repmat(sigM(:,end),1,nPad)];
padTimeV = [timeV(1)-nPad*tdiff:tdiff:timeV(1)-tdiff,timeV,timeV(end)+tdiff:tdiff:timeV(end)+nPad*tdiff];

%Perform smoothing/resampling if selected
if ~(smoothFlag || resampFlag)
    resampSigM = sigM;
    timeOutV = timeV;
else
    if smoothFlag
        peakIdxV = findFirstPeak(sigM);
        skipIdxV = sum(isnan(sigM),2);
        selPadSigM = padSigM(~skipIdxV,:);
        peakIdxV = peakIdxV(~skipIdxV);
        %Smooth signal follg. first peak
        for vox = 1:size(selPadSigM,1)
            selSegV = selPadSigM(vox, nPad+peakIdxV(vox)+1:end);
            selPadSigM(vox, nPad+peakIdxV(vox)+1:end) = ...
                conv(selSegV,filtV,'same');
        end
        padSigM(~skipIdxV,:) = selPadSigM;
    end
    if resampFlag         
        resampSigM = resample(padSigM.',padTimeV,1/ts).'; %Resample
    else
        resampSigM = padSigM;
        ts = tdiff;
    end
    
    %Discard padded ends
    tSkip = round(nPad*tdiff/ts);
    resampSigM = resampSigM(:,tSkip+1:end-tSkip);
    timeOutV = 0:ts:(size(resampSigM,2)-1)*ts;
end


end