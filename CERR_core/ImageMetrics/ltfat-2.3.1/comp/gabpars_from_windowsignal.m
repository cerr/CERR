function [f,g,L,Ls,W,info] = gabpars_from_windowsignal(f,g,a,M,L,lt,callfun)
%-*- texinfo -*-
%@deftypefn {Function} gabpars_from_windowsignal
%@verbatim
%GABPARS_FROM_WINDOWSIGNAL  Compute g and L from window and signal
%   Usage: [g,g.info,L] = gabpars_from_windowsignal(f,g,a,M,L);
%
%   Use this function if you know an input signal, a window and a lattice
%   for the DGT. The function will calculate a transform length L and
%   evaluate the window g into numerical form. The signal will be padded and
%   returned as a column vector.
%
%   If the transform length is unknown (as it usually is unless explicitly
%   specified by the user), set L to be [] in the input to this function.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/gabpars_from_windowsignal.html}
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
  
if nargin<6
  stacknames=dbstack;  
  callfun=stacknames(2).name;
end;

% ----- step 1 : Verify f and determine its length -------
% Change f to correct shape.
[f,Ls,W,wasrow,remembershape]=comp_sigreshape_pre(f,callfun,0);


if isempty(L)

    % ----- step 2b : Verify a, M and get L from the signal length f----------
    L=dgtlength(Ls,a,M);

else

    % ----- step 2a : Verify a, M and get L
    Luser=dgtlength(L,a,M);
    if Luser~=L
        error(['%s: Incorrect transform length L=%i specified. Next valid length ' ...
               'is L=%i.'],callfun,L,Luser)
    end;

end;

% ----- step 3 : Determine the window 

[g,info]=gabwin(g,a,M,L,'callfun',callfun);

if L<info.gl
  error('%s: Window is too long.',callfun);
end;

% ----- final cleanup ---------------

f=postpad(f,L);

% If the signal is single precision, make the window single precision as
% well to avoid mismatches.
if isa(f,'single')
  g=single(g);
end;





