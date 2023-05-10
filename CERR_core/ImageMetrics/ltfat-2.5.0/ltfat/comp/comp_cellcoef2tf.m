function coef = comp_cellcoef2tf(coef,maxLen)
%COMP_CELLCOEF2TF Cell to a tf-layout
%   Usage: coef = comp_cellcoef2tf(coef,maxLen)
%
%
%   Url: http://ltfat.github.io/doc/comp/comp_cellcoef2tf.html

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




coefLenMax = max(cellfun(@(cEl)size(cEl,1),coef));

if nargin>1
   coefLenMax = min([coefLenMax,maxLen]);
end

coefTmp = zeros(coefLenMax,numel(coef),size(coef{1},2),class(coef{1}));

for ii=1:numel(coef)
   if size(coef{ii},1) == 1
      coefTmp(:,ii) = coef{ii};
      continue;
   end
   if ~isoctave
       coefTmp(:,ii) = interp1(coef{ii},linspace(1,size(coef{ii},1),...
                       coefLenMax),'nearest');
   else
       coefRe = interp1(real(coef{ii}),linspace(1,size(coef{ii},1),...
                       coefLenMax),'nearest');
                   
        coefIm = interp1(imag(coef{ii}),linspace(1,size(coef{ii},1),...
                       coefLenMax),'nearest');  
                   
        coefTmp(:,ii) = coefRe + 1i*coefIm;
   end
end
coef = coefTmp';

