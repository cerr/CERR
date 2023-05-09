function [Lc,L]=wpfbtclength(Ls,wt,varargin)
%-*- texinfo -*-
%@deftypefn {Function} wpfbtclength
%@verbatim
%WPFBTCLENGTH  WPFBT subband length from a signal length
%   Usage: Lc=wpfbtclength(Ls,wt);
%          [Lc,L]=wpfbtclength(Ls,wt);
%
%   Lc=WPFBTCLENGTH(Ls,wt) returns the lengths of coefficient subbands 
%   obtained from WPFBT for a signal of length Ls. Please see the help 
%   on WPFBT for an explanation of the parameter wt. 
%
%   [Lc,L]=WPFBTCLENGTH(...) additionally returns the next legal length 
%   of the input signal for the given extension type.
%
%   The function support the same boundary-handling flags as the FWT
%   does.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wpfbtclength.html}
%@seealso{wpfbt}
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


definput.import = {'fwt'};
[flags,kv]=ltfatarghelper({},definput,varargin);

% Initialize the wavelet filters structure
wt = wfbtinit(wt);

if(flags.do_per)
   a = treeSub(wt);
   L = filterbanklength(Ls,a);
else
   L = Ls;
end

wtPath = nodeBForder(0,wt);
Lc = nodesOutLen(wtPath,L,[],flags.do_per,wt);



