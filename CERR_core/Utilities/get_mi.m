function mi = get_mi(u,v,ngray)
% function mi = get_mi(u,v,ngray)
%
% This function returns the mutual information metric for 2D images of same
% size.
%
% INPUTS: u,v: 2D matrices of same size
%         ngray: number of gray levels for discretization
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
u = imquantize_cerr(u,ngray);
v = imquantize_cerr(v,ngray);
histuv=get_joint_hist(u,v,ngray);

histu=sum(histuv,2); histv=sum(histuv,1); % by integrating out the joint

mi=sum(sum(histuv.*log2(histuv./(histu*histv+eps)+eps)));

return


function histxy=get_joint_hist(x,y,ngray)

% x, y : the two images,

siz=min([size(x);size(y)]); % if sizes are different

% x=double(uint8(double(x)+1)); y=double(uint8(double(y)+1)); % convert to 8 bits
%x=uint8(x+1); y=uint8(y+1); % convert to 8 bits

histxy = zeros(ngray,ngray);

[iM,jM] = meshgrid(1:siz(1),1:siz(2));

indV = (jM(:) - 1) * siz(1) + iM(:);  

xV = double(x(indV));
yV = double(y(indV));

ind2V = (yV - 1) * ngray + xV;

for i=1:length(ind2V)

    histxy(ind2V(i)) = histxy(ind2V(i)) + 1;

end

histxy = histxy/sum(histxy(:)); % normalize

return



% %%% ==== another implementation (for QA purpose)
% function h=joint_histogram(x,y)
% %
% % Takes a pair of images of equal size and returns the 2d joint histogram.
% % used for MI calculation
% % 
% % written by Amir Pasha Mahmoudzadeh
% % University of California, San Francisco
% % Biomedical Imaging Lab
% %
% % Copyright (c) 2016, Amir Pasha Mahmoudzadeh
% % All rights reserved.
% % 
% % Redistribution and use in source and binary forms, with or without
% % modification, are permitted provided that the following conditions are met:
% % 
% % * Redistributions of source code must retain the above copyright notice, this
% %   list of conditions and the following disclaimer.
% % 
% % * Redistributions in binary form must reproduce the above copyright notice,
% %   this list of conditions and the following disclaimer in the documentation
% %   and/or other materials provided with the distribution
% % THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% % AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% % IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% % DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
% % FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
% % DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% % SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
% % CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
% % OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
% % OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
% 
% rows=size(x,1);
% cols=size(y,2);
% N=256;
% h=zeros(N,N);
% for i=1:rows;   
%   for j=1:cols;   
%     h(x(i,j)+1,y(i,j)+1)= h(x(i,j)+1,y(i,j)+1)+1;
%   end
% end
% imshow(h)
% end
% 
