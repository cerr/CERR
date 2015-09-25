function [bbox]=boundingBox(targetMask);
%"boundingBox"
%   Fast algorithm to find the bounding box of the binary structure
%   targetMask, in terms of rows, cols, slices.  The bounding box is the
%   minimum sized box that includes all true values in the passed mask.
%
%   bbox has form [rMin rMax cMin cMax sMin sMax].
%
%Usage:
%   [bbox]=boundingBox(targetMask); 
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

  n=size(targetMask);
  
  %zmin
  cntr=1;
  true=sum(sum(targetMask(:,:,cntr)));

  while(~true)
    cntr=cntr+1;
    true=sum(sum(targetMask(:,:,cntr)));
  end
  bbox(5)=cntr;
  
  %zmax
  cntr=0;
  true=sum(sum(targetMask(:,:,end-cntr)));

  while(~true)
    cntr=cntr+1;
    true=sum(sum(targetMask(:,:,end-cntr)));
  end
  bbox(6)=n(3)-cntr;

  %ymin
  cntr=1;
  true=sum(sum(targetMask(:,cntr,:)));

  while(~true)
    cntr=cntr+1;
    true=sum(sum(targetMask(:,cntr,:)));
  end
  bbox(3)=cntr;
 
  %ymax
  cntr=0;
  true=sum(sum(targetMask(:,end-cntr,:)));

  while(~true)
    cntr=cntr+1;
    true=sum(sum(targetMask(:,end-cntr,:)));
  end
  bbox(4)=n(2)-cntr;

  %xmin
  cntr=1;
  true=sum(sum(targetMask(cntr,:,:)));

  while(~true)
    cntr=cntr+1;
    true=sum(sum(targetMask(cntr,:,:)));
  end
  bbox(1)=cntr;
 
  %xmax
  cntr=0;
  true=sum(sum(targetMask(end-cntr,:,:)));

  while(~true)
    cntr=cntr+1;
    true=sum(sum(targetMask(end-cntr,:,:)));
  end
  bbox(2)=n(1)-cntr;
