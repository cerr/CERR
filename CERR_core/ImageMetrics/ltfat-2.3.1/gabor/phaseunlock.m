function c = phaseunlock(c,a,varargin)
%-*- texinfo -*-
%@deftypefn {Function} phaseunlock
%@verbatim
%PHASEUNLOCK  Undo phase lock of Gabor coefficients
%   Usage:  c=phaseunlock(c,a);
%
%   PHASEUNLOCK(c,a) removes phase locking from the Gabor coefficients c.
%   The coefficient must have been obtained from a DGT with parameter a.
%
%   Phase locking the coefficients modifies them so as if they were obtained
%   from a time-invariant Gabor system. A filter bank produces phase locked
%   coefficients. 
%
%
%   References:
%     M. Puckette. Phase-locked vocoder. Applications of Signal Processing to
%     Audio and Acoustics, 1995., IEEE ASSP Workshop on, pages 222 --225,
%     1995.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/phaseunlock.html}
%@seealso{dgt, phaselock, symphase}
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

%   AUTHOR:    Peter Balazs, Peter L. Soendergaard.
%   TESTING:   OK
%   REFERENCE: OK

if nargin<2
  error('%s: Too few input parameters.',upper(mfilename));
end;

definput.keyvals.lt=[0 1];
[flags,kv]=ltfatarghelper({},definput,varargin);

if  (prod(size(a))~=1 || ~isnumeric(a))
  error('a must be a scalar');
end;

if rem(a,1)~=0
  error('a must be an integer');
end;

M=size(c,1);
N=size(c,2);
L=N*a;
b=L/M;

if rem(b,1)~=0
  error('Lattice error. The a parameter is probably incorrect.');
end;

TimeInd = (0:(N-1))*a;
FreqInd = (0:(M-1));

phase = FreqInd'*TimeInd;
phase = mod(phase,M);
phase = exp(-2*1i*pi*phase/M);

if kv.lt(1)>0 
    % truly non-separable case
    
    for n=0:(N-1)
        w = mod(n*kv.lt(1)/kv.lt(2),1);
        phase(:,n+1) = phase(:,n+1)*exp(-2*pi*1i*a*w*n/M);
    end
end

% Handle multisignals
c=bsxfun(@times,c,phase);

