function mi=get_mi(u,v,ngray)
%  
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

u = u - min(min(u(:)),0);
v = v - min(min(v(:)),0);
histuv=get_joint_hist(u,v,ngray);

histu=sum(histuv,2); histv=sum(histuv,1); % by integrating out the joint

mi=sum(sum(histuv.*log2(histuv./(histu*histv+eps)+eps)));

return


function histxy=get_joint_hist(x,y,ngray)

% x, y : the two images,

siz=min([size(x);size(y)]); % if sizes are different

% x=double(uint8(double(x)+1)); y=double(uint8(double(y)+1)); % convert to 8 bits
x=uint8(x+1); y=uint8(y+1); % convert to 8 bits

histxy=zeros(ngray,ngray);

[iM,jM] = meshgrid(1:siz(1),1:siz(2));

indV = (jM(:) - 1) * siz(1) + iM(:);  

xV = double(x(indV));
yV = double(y(indV));

ind2V = (yV - 1) * ngray + xV;

for i=1:length(ind2V)

    histxy(ind2V(i)) = histxy(ind2V(i)) + 1;

end

histxy=histxy/sum(histxy(:)); % normalize

return

