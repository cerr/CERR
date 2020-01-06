function peakIdxV = findFirstPeak(X)
% AI  10/17/16
% ========================================================================
% X  : Input data matrix (nVox x nTimePts)
% ========================================================================

nVox = size(X,1);

% Find pts of local maxima 't' where x(t)>x(t-1) & x(t)>x(t+1)
test1_M = [zeros(nVox,1) diff(X,1,2)];
test2_M = [-diff(X,1,2) zeros(nVox,1)];
test12_M = test1_M>=0 & test2_M>=0;
% Retain local maxima that are at least 80% of the max. signal intensity
test3_M = bsxfun(@gt,X,.8*max(X,[],2));
allPeaksM = test12_M & test3_M;
% First peak
[~,peakIdxV] = max(allPeaksM,[],2);   %Max returns the index corresponding to the
                                      %first occurrence of maximum (here 1)
                                      %If no peaks are found, returns first point)

end