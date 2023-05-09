function [Ncoef, L]=frameclength(F,Ls)
%-*- texinfo -*-
%@deftypefn {Function} frameclength
%@verbatim
%FRAMECLENGTH  Number of coefficients from length of signal
%   Usage: Ncoef=frameclength(F,Ls);
%          [Ncoef,L]=frameclength(...);
%
%   Ncoef=FRAMECLENGTH(F,Ls) returns the total number of coefficients 
%   obtained by applying the analysis operator of frame F to a signal
%   of length Ls i.e. size(frana(F,f),1) for Ls=length(f). 
%
%   [Ncoef,L]=FRAMECLENGTH(F,Ls) additionally returns L, which is the 
%   same as returned by FRAMELENGTH.
%
%   If the frame length L is longer than the signal length Ls, the 
%   signal will be zero-padded to L by FRANA.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/frames/frameclength.html}
%@seealso{frame, framelengthcoef}
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

callfun = upper(mfilename);
complainif_notposint(Ls,'Ls',callfun);
complainif_notvalidframeobj(F,callfun);

L = F.length(Ls);

% Some frames need special function
if isfield(F,'clength')
    Ncoef = F.clength(L);
else
    % Generic, works for any non-realonly frame and for
    % all representaions not having any extra coefficients

    Ncoef = L*F.red;
    
    if F.realinput
        Ncoef=Ncoef/2;
    end

    assert(abs(Ncoef-round(Ncoef))<1e-3,...
           sprintf('%s: There is a bug. L=%d should be an integer.',...
           upper(mfilename),Ncoef));

    Ncoef=round(Ncoef);
end

