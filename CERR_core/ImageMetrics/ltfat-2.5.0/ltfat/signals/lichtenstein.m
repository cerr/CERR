function s=lichtenstein();
%LICHTENSTEIN  Load the 'lichtenstein' test image
%   Usage: s=lichtenstein;
% 
%   LICHTENSTEIN loads a 512 x512 color image of a castle
%   Lichtenstein.
% 
%   The returned matrix s consists of integers between 0 and 255.
% 
%   To display the image, simply use image:
% 
%     image(lichtenstein); axis('image');
% 
%   See also: cameraman  
%
%   Url: http://ltfat.github.io/doc/signals/lichtenstein.html

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

%   See
%   `<http://commons.wikimedia.org/wiki/File:Lichtenstein_img_processing_test.png>`_.
%
%   AUTHOR : Peter L. Søndergaard
%   TESTING: TEST_SIGNALS

if nargin>0
  error('This function does not take input arguments.')
end;

f=mfilename('fullpath');

s=imread([f,'.png']);





