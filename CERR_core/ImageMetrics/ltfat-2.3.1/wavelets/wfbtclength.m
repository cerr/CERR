function [Lc,L]=wfbtclength(Ls,wt,varargin)
%-*- texinfo -*-
%@deftypefn {Function} wfbtclength
%@verbatim
%WFBTCLENGTH  WFBT subband lengths from a signal length
%   Usage: Lc=wfbtclength(Ls,wt);
%          [Lc,L]=wfbtclength(...);
%
%   Lc=WFBTCLENGTH(Ls,wt) returns the lengths of coefficient subbands 
%   obtained from WFBT for a signal of length Ls. Please see the help 
%   on WFBT for an explanation of the parameters wt. 
%
%   [Lc,L]=WFBTCLENGTH(...) additionally returns the next legal length 
%   of the input signal for the given extension type.
%
%   The function support the same boundary-handling flags as the FWT
%   does.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfbtclength.html}
%@seealso{wfbt, wfbtlength}
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

complainif_notposint(Ls,'Ls','WFBTCLENGTH');

definput.import = {'fwt'};
[flags,kv]=ltfatarghelper({},definput,varargin);

% Initialize the wavelet filters structure
wt = wfbtinit(wt);


if(flags.do_per)
   a = treeSub(wt);
   L = filterbanklength(Ls,a);
   Lc = L./a;
else
   L = Ls;
   Lc = treeOutLen(L,0,wt);
end



