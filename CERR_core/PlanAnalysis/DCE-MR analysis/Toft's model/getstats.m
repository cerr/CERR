function statV = getstats(X)
%Returns statistics of input vector.
% ---------------------------------------------------------
% OUTPUT
% statV(1) : Mean
% statV(2) : Std deviation
% statV(3) : Median
% StatV(4) : 10th percentile
% StatV(5) : 75th percentile
% StatV(6) : 90th percentile
% StatV(7) : Skewness
% StatV(8) : Kurtosis
% ---------------------------------------------------------

Y = X(:);
statV(1)= mean(Y);
statV(2)= std(Y);
statV(3)= median(Y); 
statV(4)= prctile(Y,10);
statV(5)= prctile(Y,75);
statV(6)= prctile(Y,90);
statV(7)= skewness(Y);
statV(8)= kurtosis(Y);

end