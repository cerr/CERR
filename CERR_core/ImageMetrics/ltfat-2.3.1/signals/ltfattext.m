function s=ltfattext();
%-*- texinfo -*-
%@deftypefn {Function} ltfattext
%@verbatim
%LTFATTEXT  Load the 'ltfattext' test image
%   Usage: s=ltfattext;
% 
%   LTFATTEXT loads a 401 x600 black and white image of the word
%   'LTFAT'.
% 
%   The image is assumed to be used as a spectrogram with 800 channels
%   as produced by DGTREAL.
% 
%   The returned matrix s consists of the integers 0 and 1, which have
%   been converted to double precision.
% 
%   To display the image, use imagesc with a gray colormap:
% 
%     imagesc(ltfattext);
%     colormap(gray);
%     axis('xy');
% 
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/signals/ltfattext.html}
%@seealso{ltfatlogo, dgtreal}
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


%   AUTHOR : Peter L. Soendergaard
%   TESTING: TEST_SIGNALS
%   REFERENCE: OK
  
if nargin>0
  error('This function does not take input arguments.')
end;

f=mfilename('fullpath');

s=flipud(double(imread([f,'.png'])))/255;

