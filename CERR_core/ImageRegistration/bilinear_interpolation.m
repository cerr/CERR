function temp=bilinear_interpolation(im,xd,yd)
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

% bilinear interpolation routine
[w,h]=size(im);
% check boundary...
xd=max(min(xd,w),1);
yd=max(min(yd,h),1);
i  =max(floor(xd),1);
j  =max(floor(yd),1);
dx = xd - i;
dy = yd - j;
ul = im(sub2ind([w,h],i,j));
ur = im(sub2ind([w,h],min(i+1,w),j));
ll = im(sub2ind([w,h],i,min(j+1,h)));
lr = im(sub2ind([w,h],min(i+1,w),min(j+1,h)));
ul = double(ul);
ur = double(ur);
ll = double(ll);
lr = double(lr);

temp = ul.*(1.-dx).*(1.-dy) + ur.*(1.-dy).*dx + ll.*dy.*(1.-dx) + lr.*dx.*dy; 
%temp=reshape(temp,w,h);
return


