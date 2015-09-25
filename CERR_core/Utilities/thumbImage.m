%function im = thumbImage(im, xi, yi)
function im = thumbImage(im, ratio)
%OLD (10/17/06): function im = thumbImage(im, ratio)
%"thumbImage"
%   Create a thumbnail of an image, im.  The thumbnail will be reduced in
%   size by ratio, where 2 means a half size thumbnail.  Each pixel in the 
%   thumbnail will be the mean of all pixel values around the corresponding 
%   area in the original.  This has a smoothing effect.
%
%   JRA 12/31/03
%
% Usage:
%   function im = thumbImage(im, ratio)
%
%This algorithm reshapes the image so that the mean of each column within
%each of NxN subdivisions of the original image can be found.  Then the
%means of these means are found.  These are the mean values for each region
%in the original image and are used as the pixel values in the thumbnail.
%
%LM: APA, 10/17/2006: used finterp2 for interpolating scan on thumbnails.
%LM: APA, 11/06/2006: reverted back to low-pass filter since directly using
%finterp2 gave bad-quality thumbnails. Note that the passed im is such that
%size(im)./ratio is always equal in x and y.
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.

imSize = size(im);
%thumbSize = floor(imSize/ratio);
thumbSize = floor(imSize./ratio);

rowInterval = floor(imSize(1) / thumbSize(1));
colInterval = floor(imSize(2) / thumbSize(2));

thumbSize(1) = floor(imSize(1) / rowInterval);
thumbSize(2) = floor(imSize(2) / colInterval);

im = im(1:thumbSize(1)*rowInterval, 1:thumbSize(2)*colInterval);
im = double(im);

%Take the mean of the columns.
tmp = reshape(im, rowInterval, []);
meanV = mean(tmp,1);

%Reshape to be the size of thumbnail on rows
tmp = reshape(meanV, thumbSize(1), []);
tmp = tmp';

%Reshape to take the mean of the rows.
tmp = reshape(tmp, colInterval(1), []);
meanV = mean(tmp,1);

%Reshape the final means to be the size of the thumb.
%im = reshape(meanV, thumbSize(1), thumbSize(2));
im = reshape(meanV, thumbSize(2), thumbSize(1));
im = im';
