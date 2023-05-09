function L=wfbtlength(Ls,wt,varargin);
%-*- texinfo -*-
%@deftypefn {Function} wfbtlength
%@verbatim
%WFBTLENGTH  WFBT length from signal
%   Usage: L=wfbtlength(Ls,wt);
%
%   WFBTLENGTH(Ls,wt) returns the length of a Wavelet system that is long
%   enough to expand a signal of length Ls. Please see the help on
%   WFBT for an explanation of the parameter wt.
%
%   If the returned length is longer than the signal length, the signal
%   will be zero-padded by WFBT to length L.
%
%   In addition, the function accepts flags defining boundary extension
%   technique as in WFBT. The returned length can be longer than the
%   signal length only in case of 'per' (periodic extension).
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfbtlength.html}
%@seealso{wfbt, fwt}
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

% AUTHOR: Zdenek Prusa

complainif_notposint(Ls,'Ls','WFBTLENGTH');

definput.import = {'fwt'};
[flags,kv]=ltfatarghelper({},definput,varargin);

% Initialize the wavelet filters structure
if ~isstruct(wt)
   wt = wfbtinit(wt);
end

if(flags.do_per)
   a = treeSub(wt);
   L = filterbanklength(Ls,a);
else
   L = Ls;
end

