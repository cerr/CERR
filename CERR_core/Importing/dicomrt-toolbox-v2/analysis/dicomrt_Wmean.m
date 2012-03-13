function [wmean,wmstd,wstd] = dicomrt_Wmean(data,dataerror)
% dicomrt_Wmean(data,error)
%
% Calculate weigthed mean and weighted standard deviation.
%
% data is vector containing the data to calculate the mean for
% dataerror is the absolute error for each data point
% 
% wmean is the weigthed mean
% wmstd is the standard deviation of the weighted mean
% wstd is the standard deviation of the distribution
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

if (length(data) ~= length(dataerror))
    error('dicomrt_Wmean: Vectors do not have the same length. Exit now');
end

% weigthed mean
wmean=sum(data./dataerror.^2)/sum(1./dataerror.^2);

% standard deviation of the mean
wmstd=sqrt(1/sum(dataerror.^2));

% standard deviation
N=length(dataerror);
if N==1
    wstd=inf;
else
    variance=(data-wmean).^2;
    wstd=sqrt(1./(N-1)*sum(variance));
end
