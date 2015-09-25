function [interpV] = finterp3(xInterpV, yInterpV, zInterpV, field3M, xFieldV, yFieldV, zFieldV, OOBV)
%"finterp3"
%   Fast 3D linear interpolation of the data field3M defined at
%   xFieldV,yFieldV,zFieldV, to the points listed in x/y/zInterpV.
%
%   xFieldV and yFieldV are 3 element vectors of the form [start, delta, end],
%   where start is the coordinate of the first column(x) or row(y) and end 
%   is the coord of the last column/row, with delta being the spacing.  Delta 
%   can be negative if start > end.
%
%   zFieldV must be specified as a list of coordinates for each slice in
%   field3M.
%
%   xInterpV, yInterpV, zInterpV are vectors of equal length indicating the
%   x,y,z, coordinates to interpolate from original data field3M.
%
%   Based on code by J.O.Deasy.
%
%JRA 1/13/05
%
%Usage:
%   function [interpV] = finterp3(xInterpV, yInterpV, zInterpV, field3M, xFieldV, yFieldV, zFieldV, outOfBoundsVal)

siz = size(field3M);

if ~exist('OOBV')
    OOBV = NaN;
end

xDelta = xFieldV(2);
yDelta = yFieldV(2);

%Get r,c,s indices.
% cols = interp1q(reshape(xFieldV, [], 1), reshape(1:length(xFieldV),[], 1), reshape(xInterpV, [], 1));
% rows = interp1q(reshape(yFieldV, [], 1), reshape(1:length(yFieldV),[], 1), reshape(yInterpV, [], 1));
cols = (xInterpV-(xFieldV(1)-xDelta))/xDelta;
rows = (yInterpV-(yFieldV(1)-yDelta))/yDelta;
if length(zFieldV) > 1;
    slcs = interp1(zFieldV,1:length(zFieldV),zInterpV);
else
    slcs = ones(size(cols));    %This effectively negates Z.  All values are in plane.  Bad idea? 
end

clear xInterpV yInterpV zInterpV
clear xFieldV yFieldV zFieldV

%Find indices out of bounds.
colNaN = cols >= siz(2) | cols < 1;
rowNaN = rows >= siz(1) | rows < 1;    
% slcNaN = slcs >= siz(3) | slcs < 1;    

% colNaN = isnan(cols);
% rowNaN = isnan(rows);
slcNaN = isnan(slcs) | slcs < 1 | slcs >= siz(3);

%Set those to a proxy 1.
rows(rowNaN) = 1;
cols(colNaN) = 1;
slcs(slcNaN) = 1;

colFloor = floor(cols);
colMod   = cols - colFloor;
oneMinusColMod = (1-colMod);

rowFloor = floor(rows);
rowMod = rows - rowFloor;
oneMinusRowMod = (1-rowMod);    

slcFloor = floor(slcs);
slcMod = slcs - slcFloor;
oneMinusSlcMod = (1-slcMod);    

clear rows cols slcs

%Linear indices of lower bound contributing points.
INDEXLIST = rowFloor + (colFloor-1)*siz(1) + (slcFloor-1)*siz(1)*siz(2);

clear rowFloor colFloor slcFloor

%Linear offsets when moving in 3D matrix.
oneRow = 1;
oneCol = siz(1);
oneSlc = siz(1)*siz(2);

%Accumulate contribution from each voxel surrounding x,y,z point.
interpV = double(field3M(INDEXLIST)) .* oneMinusRowMod .* oneMinusColMod .* oneMinusSlcMod;
interpV = interpV + double(field3M(INDEXLIST+(oneRow))) .* rowMod .* oneMinusColMod .* oneMinusSlcMod;
interpV = interpV + double(field3M(INDEXLIST+(oneCol))) .* oneMinusRowMod .* colMod .* oneMinusSlcMod;
interpV = interpV + double(field3M(INDEXLIST+(oneCol+oneRow))) .* rowMod .* colMod .* oneMinusSlcMod;;
interpV = interpV + double(field3M(INDEXLIST+(oneSlc))) .* oneMinusRowMod .* oneMinusColMod .* slcMod;
interpV = interpV + double(field3M(INDEXLIST+(oneSlc+oneRow))) .* rowMod .* oneMinusColMod .* slcMod;
interpV = interpV + double(field3M(INDEXLIST+(oneSlc+oneCol))) .* oneMinusRowMod .* colMod .* slcMod;
interpV = interpV + double(field3M(INDEXLIST+(oneSlc+oneCol+oneRow))) .* rowMod .* colMod .* slcMod;

%Replace proxy 1s with out of bounds vals.
interpV(rowNaN | colNaN | slcNaN) = OOBV;

return;