function [minM, maxM] = getMinMaxIM(IM,NHOOD)
% function [minM, maxM] = getMinMaxIM(IM,NHOOD)
%
% This function returns min and max for the local neighborhood NHOOD
%
% APA, 04/26/2012


% ---- No reflection required if our NHOOD is symmetric ------

% % NHOOD is reflected across its origin in order for IMDILATE
% % to return the local maxima of I in NHOOD if it is asymmetric. A symmetric NHOOD
% % is naturally unaffected by this reflection.
% reflectH = NHOOD(:);
% reflectH = flipud(reflectH);
% reflectH = reshape(reflectH, size(NHOOD));
% maxMat = imdilate(IM,reflectH);

maxM = imdilate(IM,NHOOD);

% IMERODE returns the local minima of IM in NHOOD.
minM = imerode(IM,NHOOD);  

end