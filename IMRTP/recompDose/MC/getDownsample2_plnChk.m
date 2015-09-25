function outM = getDownsample2(inM,sample)
%Downsample of 2-D matrix in both directions

maskM = getDownsample1(inM,sample);
maskM = getDownsample1(maskM',sample)';
outM = maskM;
