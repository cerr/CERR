function [xo,N]=gabglasso(ttype,xi,lambda,group);
%-*- texinfo -*-
%@deftypefn {Function} ref_gabglasso_onb
%@verbatim
%GABGLASSO   group lasso estimate (hard/soft) in time-frequency domain
%   Usage:  xo=gabglasso(ttype,x,lambda,group);
%           [xo,N]=gabglasso(ttype,x,lambda,group));
%
%   GABGLASSO('hard',x,lambda,'time') will perform
%   time hard group thresholding on x, i.e. all time-frequency
%   columns whose norm less than lambda will be set to zero.
%
%   GABGLASSO('soft',x,lambda,'time') will perform
%   time soft thresholding on x, i.e. all time-frequency
%   columns whose norm less than lambda will be set to zero,
%   and those whose norm exceeds lambda will be multiplied
%   by (1-lambda/norm).
%
%   GABGLASSO(ttype,x,lambda,'frequency') will perform
%   frequency thresholding on x, i.e. all time-frequency
%   rows whose norm less than lambda will be soft or hard thresholded
%   (see above).
%
%   [xo,N]=GABGLASSO(ttype,x,lambda,group) additionally returns
%   a number N specifying how many numbers where kept.
%
%   The function may meaningfully be applied to output from DGT, WMDCT or
%   from WIL2RECT(DWILT(...)).
%
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_gabglasso_onb.html}
%@seealso{gablasso, gabelasso, demo_audioshrink}
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

%   AUTHOR : Bruno Torresani.  
%   REFERENCE: OK

complainif_argnonotinrange(nargin,4,4,mfilename);
  
NbFreqBands = size(xi,1);
NbTimeSteps = size(xi,2);

xo = zeros(size(xi));

switch(lower(group))
 case {'time'}
  for t=1:NbTimeSteps,
    threshold = norm(xi(:,t));
    mask = (1-lambda/threshold);
    if(strcmp(ttype,'soft'))
      mask = mask * (mask>0);
    elseif(strcmp(ttype,'hard'))
      mask = (mask>0);
    end
    xo(:,t) = xi(:,t) * mask;
  end
 case {'frequency'}
  for f=1:NbFreqBands,
    threshold = norm(xi(f,:));
    mask = (1-lambda/threshold);
    mask = mask * (mask>0);
    if(strcmp(ttype,'soft'))
      mask = mask * (mask>0);
    elseif(strcmp(ttype,'hard'))
      mask = (mask>0);
    end
    xo(f,:) = xi(f,:) * mask;
  end
 otherwise
  error('"group" parameter must be either "time" or "frequency".'); 
end

if nargout==2
    signif_map = (abs(xo)>0);
    N = sum(signif_map(:));
end
    



