function a=appendc7(x,k,l)
% append kernel by warpping
% x: input image
% k,l padding dimension
% Written by Issam El Naqa
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

[m,n]=size(x);
icx = ceil((m+1)/2);
icy = ceil((n+1)/2);
a=zeros(k,l);
%apply padding by warpping
a(1:m-icx+1,1:n-icy+1)=x(icx:m,icy:n);   %4th quadrant->initial position
a(k:-1:k-icx+2,1:n-icy+1)=x(icx-1:-1:1,icy:n); %2nd quad->down
a(1:m-icx+1,l:-1:l-icy+2)=x(icx:m,icy-1:-1:1); %3rd quad->right
a(k:-1:k-icx+2,l:-1:l-icy+2)=x(icx-1:-1:1,icy-1:-1:1); %1ts quad->far corner
return
  
