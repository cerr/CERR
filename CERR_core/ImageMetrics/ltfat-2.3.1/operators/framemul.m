function h=framemul(f,Fa,Fs,s,varargin)
%-*- texinfo -*-
%@deftypefn {Function} framemul
%@verbatim
%FRAMEMUL  Frame multiplier
%   Usage:  h=framemul(f,Fa,Fs,s);
%
%   Input parameters:
%          Fa   : Analysis frame
%          Fs   : Synthesis frame
%          s    : Symbol
%          f    : Input signal
%
%   Output parameters: 
%          h    : Output signal
%
%   FRAMEMUL(f,Fa,Fs,s) applies the frame multiplier with symbol s*
%   to the signal f. The frame Fa is used for analysis and the frame
%   Fs for synthesis.
%
%   Examples:
%   ---------
%
%   In the following example Gabor coefficients obtained through the DGT 
%   of pink noise are multiplied by the symbol batmask before resynthesis. 
%   The result of this operation is an output signal h that is constructed 
%   through a Gabor expansion of the modified coefficients.:
%
%      f = pinknoise(400);
%      a = 10;
%      M = 40;
%      [Fa, Fs] = framepair('dgt', 'gauss', 'dual', a, M); 
%      s = framenative2coef(Fa, batmask);
%      fhat = framemul(f, Fa, Fs, s);
%      figure(1);
%      plotframe(Fa,frana(Fa,f),'clim',[-100,-20]);
%      figure(2);
%      plotframe(Fa,s,'lin');
%      figure(3);
%      plotframe(Fa,frana(Fa,fhat),'clim',[-100,-20]);
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/operators/framemul.html}
%@seealso{iframemul, framemuladj}
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
  
% Author: Peter L. Soendergaard

if nargin < 4
    error('%s: Too few input parameters.',upper(mfilename));
end;

if size(s,2)>1
    error(['%s: Symbol should be a column vecor i.e. ',... 
           'in the common Frames framework coefficient format. ',...
           'See FRAMENATIVE2COEF and FRAMECOEF2NATIVE.' ],upper(mfilename));
end

% Check for compatibility
L1=framelength(Fa,size(f,1));
L2=framelengthcoef(Fs,size(s,1));
if L1~=L2
    error(['%s: The symbol and signal lengths are incompatible.'],upper(mfilename));
end;

% This is not *strictly* necessary, but we cannot check that the symbol
% is complex-valued in just the right way.
if Fa.realinput && ~isreal(s)
    error(['%s: For real-valued-input-only frames, the symbol must also ' ...
           'be real.'],upper(mfilename));
end;

h=frsyn(Fs,bsxfun(@times,frana(Fa,f),s));



