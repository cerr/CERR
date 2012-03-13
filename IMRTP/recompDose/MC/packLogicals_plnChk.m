function data = packLogicals(logicals)
%"packLogicals"
%   Compresses a logical vector or array so that each element takes up only
%   one bit instead of the usual 8 bits.  Unpack using unpackLogicals,
%   which requires the size of the original input.
%
%JRA 7/15/04
%JRA 12/22/04 - Vectorize for speed improvement.
%
%Usage:
%   function data = packLogicals(logicals)

if ~islogical(logicals)
    error('packLogicals.m only works on logical inputs.');
    return;
end

nData = length(logicals(:));
nUINTS = ceil(nData/8);

data = repmat(uint8(0), [1 nUINTS]);

for i=1:8
    thisBitValue = logicals(i:8:end);
    trueInds = find(thisBitValue);
    data(trueInds) = bitset(data(trueInds), i, 1);
end


% %Old, nonvectorized code
% if ~islogical(logicals)
%     error('packLogicals.m only works on logical inputs.');
%     return;
% end
% 
% 
% nData = length(logicals(:));
% nUINTS = ceil(nData/8);
% 
% data = uint8(zeros([1 nUINTS]));
% 
% bitNumV = mod((1:nData)-1, 8) + 1;
% uintNumV = floor(((1:nData)-1)/8) + 1;
% for i=1:nData
%     data(uintNumV(i)) = bitset(data(uintNumV(i)), bitNumV(i), logicals(i));        
% end

