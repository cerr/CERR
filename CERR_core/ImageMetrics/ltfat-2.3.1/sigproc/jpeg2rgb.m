function RGB = jpeg2rgb(YCbCr)
%-*- texinfo -*-
%@deftypefn {Function} jpeg2rgb
%@verbatim
%JPEG2RGB  Coverts from RGB format to YCbCr format
%   Usage:  RGB = jpeg2rgb(YCbCr);
% 
%   Input parameters:
%         YCbCr : 3d data-cube, containing the YCbCr information of the
%                 image
% 
%   Output parameters:
%         RGB   : 3d data-cube, containing RGB information of the image
% 
%   'jpeg2rgb(YCbCr)' performs a transformation of the 3d data-cube YCbCr with
%   dimensions N xM x3, which contains information of
%   "luminance", "chrominance blue" and "chrominance red".  The output
%   variable RGB is a 3d data-cube of the same size containing information
%   about the colours "red", "green" and "blue". The output will be of
%   the uint8 type.
% 
%   For more information, see
%   http://en.wikipedia.org/wiki/YCbCr and http://de.wikipedia.org/wiki/JPEG
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/sigproc/jpeg2rgb.html}
%@seealso{rgb2jpeg}
%@end deftypefn

% Copyright (C) 2005-2016 Peter L. Soendergaard <peter@sonderport.dk>.
% This file is part of LTFAT version 2.3.1
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

% AUTHOR:   Markus Faulhuber, February 2013

[s1,s2,s3] = size(YCbCr);
YCbCr = double(YCbCr);

if s3 ~= 3
    disp('Sorry, this routine is for YCbCr of dimension NxMx3 only')
    return;
end

RGB(:,:,1) = YCbCr(:,:,1)+1.402*(YCbCr(:,:,3)-128);
RGB(:,:,2) = YCbCr(:,:,1)-0.3441*(YCbCr(:,:,2)-128)-0.7141*(YCbCr(:,:,3)-128);
RGB(:,:,3) = YCbCr(:,:,1)+1.772*(YCbCr(:,:,2)-128);

RGB = uint8(RGB);

