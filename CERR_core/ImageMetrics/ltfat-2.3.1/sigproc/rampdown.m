function outsig=rampdown(L,wintype)
%-*- texinfo -*-
%@deftypefn {Function} rampdown
%@verbatim
%RAMPDOWN  Falling ramp function
%   Usage: outsig=rampdown(siglen);
%
%   RAMPDOWN(siglen) will return a falling ramp function of length
%   siglen. The ramp is a sinusoid starting from one and ending at
%   zero. The ramp is centered such that the first element is always one and
%   the last element is not quite zero, such that the ramp fits with
%   following zeros.
%
%   RAMPDOWN(L,wintype) will use another window for ramping. This may be
%   any of the window types from FIRWIN. Please see the help on FIRWIN
%   for more information. The default is to use a piece of the Hann window.
%  
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/sigproc/rampdown.html}
%@seealso{rampup, rampsignal, firwin}
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
   
complainif_argnonotinrange(nargin,1,2,mfilename);

if nargin==1
  wintype='hann';
end;
  
win=firwin(wintype,2*L,'inf');
outsig=win(1:L);


