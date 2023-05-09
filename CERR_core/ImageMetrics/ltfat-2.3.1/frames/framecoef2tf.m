function coef=framecoef2tf(F,coef)
%-*- texinfo -*-
%@deftypefn {Function} framecoef2tf
%@verbatim
%FRAMECOEF2TF  Convert coefficients to time-frequency plane
%   Usage: cout=framecoef2tf(F,cin);
%
%   FRAMECOEF2TF(F,cin) converts the frame coefficients cin into the
%   time-frequency plane layout. The frame object F must have been
%   created using FRAME.
%
%   The time-frequency plane layout is a matrix, where the first
%   dimension indexes frequency and the second dimension time. This is
%   similar to the output format from DGT and WMDCT.
%
%   Not all types of frames support this coefficient conversion. The supported 
%   types of frames are: 'dgt', 'dgtreal', 'dwilt', 'wmdct', 'ufilterbank',
%   'ufwt','uwfbt' and 'uwpfbt'.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/frames/framecoef2tf.html}
%@seealso{frame, frametf2coef, framecoef2native}
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
  
complainif_notenoughargs(nargin,2,'FRAMECOEF2TF');
complainif_notvalidframeobj(F,'FRAMECOEF2TF');

switch(F.type)
 case 'dgt'
  [MN,W]=size(coef);
  N=MN/F.M;
  coef=reshape(coef,[F.M,N,W]);  
 case 'dgtreal'
  [MN,W]=size(coef);
  M2=floor(F.M/2)+1;
  N=MN/M2;
  coef=reshape(coef,[M2,N,W]);  
 case 'dwilt'
  [MN,W]=size(coef);
  N=MN/F.M;
  coef=wil2rect(reshape(coef,[2*F.M,N/2,W]));  
 case 'wmdct'
  [MN,W]=size(coef);
  N=MN/F.M;
  coef=reshape(coef,[F.M,N,W]);  
 case 'ufilterbank'
  [MN,W]=size(coef);
  M=numel(F.g);
  N=MN/M;
  coef=permute(reshape(coef,[N,M,W]),[2,1,3]); 
 case {'ufwt','uwfbt','uwpfbt'}
  coef = permute(F.coef2native(coef,size(coef)),[2,1,3]); 
 otherwise
  error('%s: TF-plane layout not supported for this transform.',upper(mfilename));
end;


