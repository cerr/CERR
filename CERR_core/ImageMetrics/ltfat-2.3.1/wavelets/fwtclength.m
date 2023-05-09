function [Lc,L]=fwtclength(Ls,w,J,varargin)
%-*- texinfo -*-
%@deftypefn {Function} fwtclength
%@verbatim
%FWTCLENGTH FWT subbands lengths from a signal length
%   Usage: Lc=fwtclength(Ls,w,J);
%          [Lc,L]=fwtclength(...);
%
%   Lc=FWTCLENGTH(Ls,w,J) returns the lengths of the wavelet coefficient
%   subbands for a signal of length Ls. Please see the help on FWT for
%   an explanation of the parameters w and J.
%
%   [Lc,L]=FWTCLENGTH(...) additianally the function returns the next 
%   legal length of the input signal for the given extension type.
%
%   The function support the same boundary-handling flags as the FWT
%   does.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/fwtclength.html}
%@seealso{fwt, fwtlength}
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

complainif_notposint(Ls,'Ls','FWTCLENGTH');
complainif_notposint(J,'J','FWTCLENGTH');

w = fwtinit(w);

definput.import = {'fwtext'};
[flags,kv]=ltfatarghelper({},definput,varargin);

% Get the next legal length
L = fwtlength(Ls,w,J,flags.ext);

filtNo = length(w.g);
subbNo = (filtNo-1)*J+1;
Lc = zeros(subbNo,1);
runPtr = 0;
levelLen = L;
if flags.do_per
  % Non-expansive case
  for jj=1:J
     for ff=filtNo:-1:2
        Lc(end-runPtr) = ceil(levelLen/w.a(ff));
        runPtr = runPtr + 1;
     end
     levelLen = ceil(levelLen/w.a(1));
  end
% elseif flags.do_valid
%   % Valid coef. case
%   filts = w.g;
%   for jj=1:J
%      for ff=filtNo:-1:2
%         Lc(end-runPtr) = floor((levelLen-(length(filts{ff}.h)-1))/w.a(ff));
%         runPtr = runPtr + 1;
%      end
%      levelLen = floor((levelLen-(length(filts{1}.h)-1))/w.a(1));
%   end
else
  % Expansive case
  filts = w.g;
  for jj=1:J
    for ff=filtNo:-1:2
       skip = w.a(ff) - 1;
       Lc(end-runPtr) = ceil((levelLen+(length(filts{ff}.h)-1)-skip)/w.a(ff));
       runPtr = runPtr + 1;
    end
    skip = w.a(1) - 1;
    levelLen = ceil((levelLen+(length(filts{1}.h)-1)-skip)/w.a(1));
 end
end
Lc(1)=levelLen;

