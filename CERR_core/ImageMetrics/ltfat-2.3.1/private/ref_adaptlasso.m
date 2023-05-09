function [xo,N]=ref_adaptlasso(ttype,xi,lambda,group);
%-*- texinfo -*-
%@deftypefn {Function} ref_adaptlasso
%@verbatim
%TF_ADAPTLASSO   adaptive lasso estimate (hard/soft) in time-frequency domain
%   Usage:  xo=tf_adaptlasso(ttype,x,lambda,group);
%           [xo,N]=tf_grouplasso(ttype,x,lambda,group));
%
%   TF_ADAPTLASSO('hard',x,lambda,'time') will perform
%   time hard adaptive thresholding on x, i.e. coefficients
%   below a column dependent threshold are set to zero. The
%   threshold is computed from the l-1 norm of its
%   time-frequency column.
%
%   TF_ADAPTLASSO('soft',x,lambda,'time') will perform
%   time soft adaptive thresholding on x, i.e. all coefficients
%   below a column dependent threshold are set to zero.
%   The threshold value is substracted from coefficients above
%   the threshold
%
%   TF_ADAPTLASSO(ttype,x,lambda,'frequency') will perform
%   frequency adaptive thresholding on x, i.e. coefficients
%   below a row dependent threshold are set to zero. The
%   threshold is computed from the l-1 norm of its
%   time-frequency row.
%
%   [xo,N]=TF_ADAPTLASSO(ttype,x,lambda,group) additionally returns
%   a number N specifying how many numbers where kept.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_adaptlasso.html}
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

complainif_notenoughargs(nargin,4,mfilename);
  
group=lower(group);
ttype=lower(ttype);

tmp = size(xi);
NbFreqBands = tmp(1);
NbTimeSteps = tmp(2);

xo = zeros(size(xi));

if (strcmp(group,'time')),
    for t=1:NbTimeSteps,
        threshold = norm(xi(:,t),1);
        threshold = lambda*threshold /(1+NbFreqBands*lambda);
        mask = abs(xi(:,t)) >= threshold;
        if(strcmp(ttype,'soft'))
            xo(mask,t) = sign(xi(mask,t)) .* (abs(xi(mask,t))-threshold);
        elseif(strcmp(ttype,'hard'))
            xo(mask,t) = sign(xi(mask,t)) .* abs(xi(mask,t));
        end
    end
elseif (strcmp(group,'frequency')),
    for f=1:NbFreqBands,
        threshold = norm(xi(f,:),1);
        threshold = lambda*threshold /(1+NbTimeSteps*lambda);
        mask = abs(xi(f,:)) >= threshold;
        if(strcmp(ttype,'soft'))
            xo(f,mask) = sign(xi(f,mask)) .* (abs(xi(f,mask))-threshold);
        elseif(strcmp(ttype,'hard'))
            xo(f,mask) = sign(xi(f,mask)) .* abs(xi(f,mask));
        end
    end
end

if nargout==2
    signif_map = (abs(xo)>0);
    N = sum(signif_map(:));
end
    


