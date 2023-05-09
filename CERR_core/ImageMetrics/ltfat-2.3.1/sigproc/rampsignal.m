function outsig=rampsignal(insig,varargin)
%-*- texinfo -*-
%@deftypefn {Function} rampsignal
%@verbatim
%RAMPSIGNAL  Ramp signal
%   Usage: outsig=rampsignal(insig,L);
%
%   RAMPSIGNAL(insig,L) applies a ramp function of length L to the
%   beginning and the end of the input signal. The default ramp is a
%   sinusoide starting from zero and ending at one (also known as a cosine
%   squared ramp).
%
%   If L is scalar, the starting and ending ramps will be of the same
%   length. If L is a vector of length 2, the first entry will be used
%   for the rising ramp, and the second for the falling.
%
%   If the input is a matrix or an N-D array, the ramp will be applied
%   along the first non-singleton dimension.
%
%   RAMPSIGNAL(insig) will use a ramp length of half the signal.
%
%   RAMPSIGNAL(insig,L,wintype) will use another window for ramping. This
%   may be any of the window types from FIRWIN. Please see the help on
%   FIRWIN for more information. The default is to use a piece of the
%   Hann window.
%
%   RAMPSIGNAL accepts the following optional parameters:
%
%     'dim',d   Apply the ramp along dimension d. The default value of []
%               means to use the first non-singleton dimension.     
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/sigproc/rampsignal.html}
%@seealso{rampdown, rampsignal, firwin}
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

definput.import={'firwin'};
definput.keyvals.dim=[];
definput.keyvals.L=[];
[flags,kv]=ltfatarghelper({'L','dim'},definput,varargin);

[insig,L,Ls,W,dim,permutedsize,order]=assert_sigreshape_pre(insig,[],kv.dim,'RAMPSIGNAL');
% Note: Meaning of L has changed, it is now the length of the signal.

switch numel(kv.L)
 case 0
  L1=L/2;
  L2=L/2;
 case 1
  L1=kv.L;
  L2=kv.L;
 case 2
  L1=kv.L(1);
  L2=kv.L(2);
 otherwise
  error('%s: The length must a scalar or vector.',upper(mfilename));
end;

if rem(L1,1)~=0 || rem(L2,1)~=0
  error('The length of the ramp must be an integer.');
end;

if L<L1+L2
  error(['%s: The length of the input signal must be greater than the length of the ramps ' ...
         'combined.'],upper(mfilename));
end;

r1=rampup(L1,flags.wintype);
r2=rampdown(L2,flags.wintype);

ramp=[r1;ones(L-L1-L2,1);r2];

% Apply the ramp
for ii=1:W
  insig(:,ii)=insig(:,ii).*ramp;
end;

outsig=assert_sigreshape_post(insig,dim,permutedsize,order);


