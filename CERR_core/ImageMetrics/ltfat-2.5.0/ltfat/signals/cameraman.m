function s=cameraman();
%CAMERAMAN  Load the 'cameraman' test image
%   Usage: s=cameraman;
% 
%   CAMERAMAN loads a 256 x256 greyscale image of a cameraman.
% 
%   The returned matrix s consists of integers between 0 and 255,
%   which have been converted to double precision.
% 
%   To display the image, use imagesc with a gray colormap:
% 
%     imagesc(cameraman); colormap(gray); axis('image');
% 
%   See ftp://nic.funet.fi/pub/graphics/misc/test-images/ or
%   http://sipi.usc.edu/database/database.cgi?volume=misc.
%
%   Url: http://ltfat.github.io/doc/signals/cameraman.html

% Copyright (C) 2005-2022 Peter L. Soendergaard <peter@sonderport.dk> and others.
% This file is part of LTFAT version 2.5.0
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

%   AUTHOR : Peter L. Søndergaard
%   TESTING: TEST_SIGNALS

  
if nargin>0
  error('This function does not take input arguments.')
end;

f=mfilename('fullpath');

s=double(imread([f,'.png']));

