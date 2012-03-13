function [maskDown3M] = getDownsample3(mask3M, sampleTrans, sampleAxis)
%Downsample a 3D matrix.
%JOD.

sV  = size(mask3M);

sampleSlices = ceil(sV(3)/sampleAxis);

maskDown3M = zeros(sV(1)/sampleTrans,sV(2)/sampleTrans,ceil(sV(3)/sampleAxis));

indV = 1 : sampleAxis: sampleSlices;
for i = 1 : length(indV)
  maskM = getDownsample2(mask3M(:,:,indV(i)),sampleTrans);
  maskDown3M(:,:,i) = maskM;
end

