function logicals = unpackLogicals(data, siz)
%"unpackLogicals"
%   Decompresses a logical vector or array that was compressed using
%   packLogicals.  The size of the initial data must be known.
%
%JRA 7/16/04
%JRA 9/14/04 - Vectorize for speed improvement.
%
%Usage:
%   function logicals = unpackLogicals(data, siz)

if ~strcmpi(class(data), 'uint8')
    error('unpackLogicals.m only works on uint8 inputs.');
    return;
end

nUINTS = length(data(:));
nData = prod(siz);

if nUINTS * 8 < nData
    error('Not enough data to construct vector/matrix of that size.');
end

%---Begin Vectorized Code

logicals = logical(zeros([1 nUINTS*8]));
for i=1:8
    logicals(i:8:end) = bitget(data, i);   
end
logicals = logicals(1:nData);
logicals = reshape(logicals, siz);

%---Old, Unvectorized Code.
% logicals = logical(zeros([1 nData]));
% bitNumV = mod((1:nData)-1, 8) + 1;
% uintNumV = floor(((1:nData)-1)/8) + 1;
% for i=1:nData
%     logicals(i) = bitget(data(uintNumV(i)), bitNumV(i));
% end
% logicals = reshape(logicals, siz);