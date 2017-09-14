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
        %Pad signal
        %Smooth signal follg. first peak
        padSigM(:,nPad+peakIdxV+1:end) = conv2(1,filtV,padSigM(:,nPad+peakIdxV+1:end),'same');
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