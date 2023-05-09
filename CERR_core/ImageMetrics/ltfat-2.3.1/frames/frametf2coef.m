function coef=frametf2coef(F,coef)
%-*- texinfo -*-
%@deftypefn {Function} frametf2coef
%@verbatim
%FRAMETF2COEF  Convert coefficients from TF-plane format
%   Usage: cout=frametf2coef(F,cin);
%
%   FRAMETF2COEF(F,cin) converts the frame coefficients from the
%   time-frequency plane layout into the common column format.
%
%   Not all types of frames support this coefficient conversion. The supported 
%   types of frames are: 'dgt', 'dgtreal', 'dwilt', 'wmdct', 'ufilterbank',
%   'ufwt','uwfbt' and 'uwpfbt'.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/frames/frametf2coef.html}
%@seealso{frame, framecoef2tf, framecoef2native}
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

complainif_notenoughargs(nargin,2,'FRAMETF2COEF');
complainif_notvalidframeobj(F,'FRAMETF2COEF');


switch(F.type)
 case {'dgt','dgtreal','wmdct'}
  [M,N,W]=size(coef);
  coef=reshape(coef,[M*N,W]);
 case {'dwilt'}
  coef=framenative2coef(F,rect2wil(coef));
 case {'ufilterbank'}
   coef=permute(coef,[2,1,3]);
   [M,N,W]=size(coef);
   coef=reshape(coef,[M*N,W]);
 case {'ufwt','uwfbt','uwpfbt'}
  coef = F.native2coef(permute(coef,[2,1,3])); 
 otherwise
  error('%s: TF-plane layout not supported for this transform.',upper(mfilename));
end;




