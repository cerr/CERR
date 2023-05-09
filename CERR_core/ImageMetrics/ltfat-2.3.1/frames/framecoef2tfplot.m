function coef=framecoef2tfplot(F,coef)
%-*- texinfo -*-
%@deftypefn {Function} framecoef2tfplot
%@verbatim
%FRAMECOEF2TFPLOT  Convert coefficients to time-frequency plane matrix
%   Usage: cout=framecoef2tfplot(F,cin);
%
%   FRAMECOEF2TFPLOT(F,coef) converts the frame coefficients coef into
%   the time-frequency plane layout matrix. The frame object F must have 
%   been created using FRAME. The function acts exactly as 
%   FRAMECOEF2TF for frames which admit regular (rectangular) sampling
%   of a time-frequency plane and converts irregularly sampled coefficients
%   to a rectangular matrix. This is usefull for custom plotting.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/frames/framecoef2tfplot.html}
%@seealso{frame, frametf2coef, framecoef2native, blockplot}
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
  
complainif_notenoughargs(nargin,2,'FRAMECOEF2TFPLOT');
complainif_notvalidframeobj(F,'FRAMECOEF2TFPLOT');

switch(F.type)
   % We could have done a try-catch block here, but it is slow
   case {'dgt','dgtreal','dwilt','wmdct','ufilterbank','ufwt','uwfbt','uwpfbt'} 
    coef=framecoef2tf(F,coef);
    return;
   case 'fwt'
    coef = comp_fwtpack2cell(F,coef);
   case {'wfbt','wpfbt','filterbank','filterbankreal'}
    coef = F.coef2native(coef,size(coef));   
end

switch(F.type)
 case {'fwt','wfbt','wpfbt','filterbank','filterbankreal'}
  coef = comp_cellcoef2tf(coef);
 otherwise
  error('%s: TF-plane plot not supported for this transform.',upper(mfilename));
end;


