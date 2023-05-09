function g=long2fir(g,varargin);
%-*- texinfo -*-
%@deftypefn {Function} long2fir
%@verbatim
%LONG2FIR   Cut LONG window to FIR
%   Usage:  g=long2fir(g,L);
%
%   LONG2FIR(g,L) will cut the LONG window g to a length L FIR window by
%   cutting out the middle part. Note that this is a slightly different
%   behaviour than MIDDLEPAD.
%
%   LONG2FIR(g,L,'wp') or LONG2FIR(g,L,'hp') does the same assuming the
%   input window is a whole-point even or half-point even window,
%   respectively.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/sigproc/long2fir.html}
%@seealso{fir2long, middlepad}
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

if nargin<1
  error('%s: Too few input parameters.',upper(mfilename));
end;

definput.flags.centering = {'unsymmetric','wp','hp'};
definput.keyvals.L      = [];
definput.keyvals.cutrel = [];

[flags,kv,L]=ltfatarghelper({'L'},definput,varargin);

W=length(g);

if W<L
  error('L must be smaller than length of window.');
end;

if ~isempty(kv.cutrel)
  maxval=max(abs(g));
  mask=abs(g)>maxval*kv.cutrel;
  L=W-2*min(abs(find(mask)-L/2));
end;

if isempty(L)
    error(['%s: You must specify a way to shorten the window, either by ' ...
           'specifying the length or through a flag.'],upper(mfilename));
end;

if flags.do_unsymmetric
  % No assumption on the symmetry of the window.

  if rem(L,2)==0
    % HPE middlepad works the same way as the FIR cutting (e.g. just
    % removing middle points) for even values of L.
    g=middlepad(g,L,'hp');
  else
    % WPE middlepad works the same way as the FIR cutting (e.g. just
    % removing middle points) for odd values of L.
    g=middlepad(g,L);
  end;
  
else
  if flags.do_wp
    g=middlepad(g,L);
    if rem(L,2)==0
      g(L/2+1)=0;
    end;
  else
    g=middlepad(g,L,'hp');
    if rem(L,2)==1
      g(ceil(L/2))=0;
    end;
  end;
end;


