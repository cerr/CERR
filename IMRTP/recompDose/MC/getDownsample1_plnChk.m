function outM = getDownsample1(inM,sample)
%function outM = getDownsample1(inM,sample)
%Downsample:  retain every 'sample' point.
%Operates on every column.
%Errors out is the number of rows divided by sample
%parameter is not an integer.
%
%JOD, May 02.

%create vector index:

sV = size(inM);

len = length(inM(:));

indexV = 1 : sample : len;

outM = inM(indexV);

outM = reshape(outM,sV(1)/sample,sV(2));


