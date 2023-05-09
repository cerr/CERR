function [gamma]=wildual(g,M,L)
%-*- texinfo -*-
%@deftypefn {Function} wildual
%@verbatim
%WILDUAL  Wilson dual window
%   Usage:  gamma=wildual(g,M);
%           gamma=wildual(g,M,L);
%
%   Input parameters:
%         g     : Gabor window.
%         M     : Number of modulations.
%         L     : Length of window. (optional)
%   Output parameters:
%         gamma : Canonical dual window.
%
%   WILDUAL(g,M) returns the dual window of the Wilson or WMDCT basis with
%   window g, parameter M and length equal to the length of the window g.
%
%   The window g may be a vector of numerical values, a text string or a
%   cell array. See the help of WILWIN for more details.
%
%   If the length of g is equal to 2*M then the input window is
%   assumed to be an FIR window. In this case, the dual window also has
%   length of 2*M. Otherwise the smallest possible transform length is
%   chosen as the window length.
%
%   WILDUAL(g,M,L) does the same, but now L is used as the length of the
%   Wilson basis.
%
%   The input window g must be real and whole-point even. If g is not
%   whole-point even, then reconstruction using the dual window will not be
%   perfect. For a random window g, the window closest to g that satisfies
%   these restrictions can be found by :
%
%     g_wpe = real(peven(g));
%
%   All windows in the toolbox satisfies these restrictions unless
%   clearly stated otherwise.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/wildual.html}
%@seealso{dwilt, wilwin, wmdct, wilorth, isevenfunction}
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

%   AUTHOR : Peter L. Soendergaard.
%   TESTING: TEST_DWILT
%   REFERENCE: OK

complainif_argnonotinrange(nargin,2,3,mfilename);

if nargin==2
    L=[];
end;

%% ------ step 2: Verify a, M and L
if isempty(L)
    if isnumeric(g)
        % Use the window length
        Ls=length(g);
    else
        % Use the smallest possible length
        Ls=1;
    end;

    % ----- step 2b : Verify M and get L from the window length ----------
    L=dwiltlength(Ls,M);

else

    % ----- step 2a : Verify M and get L

    Luser=dwiltlength(L,M);
    if Luser~=L
        error(['%s: Incorrect transform length L=%i specified. Next valid length ' ...
               'is L=%i. See the help of DWILTLENGTH for the requirements.'],...
              upper(mfilename),L,Luser);
    end;

end;


%% ----- step 3 : Determine the window 

[g,info]=wilwin(g,M,L,upper(mfilename));

if L<info.gl
  error('%s: Window is too long.',upper(mfilename));
end;

%% ----- call gabdual ----------------
a=M;

g=fir2long(g,L);
gamma=2*comp_gabdual_long(g,a,2*M);

