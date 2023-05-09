function gamma=gabmixdual(g1,g2,a,M,varargin)
%-*- texinfo -*-
%@deftypefn {Function} gabmixdual
%@verbatim
%GABMIXDUAL  Computes the mixdual of g1
%   Usage: gamma=mixdual(g1,g2,a,M)
%
%   Input parameters:
%        g1     : Window 1
%        g2     : Window 2
%        a      : Length of time shift.
%        M      : Number of modulations.
%
%   Output parameters:
%        gammaf : Mixdual of window 1.
%
%   GABMIXDUAL(g1,g2,a,M) computes a dual window of g1 from a mix of the
%   canonical dual windows of g1 and g2.
%
%
%
%   References:
%     T. Werther, Y. Eldar, and N. Subbana. Dual Gabor Frames: Theory and
%     Computational Aspects. IEEE Trans. Signal Process., 53(11), 2005.
%     
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/gabmixdual.html}
%@seealso{gabdual, gabprojdual, demo_gabmixdual}
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

% Assert correct input.

if nargin<4
  error('%s: Too few input parameters.',upper(mfilename));
end;

definput.keyvals.L=[];
definput.keyvals.lt=[0 1];
definput.flags.phase={'freqinv','timeinv'};
[flags,kv,L]=ltfatarghelper({'L'},definput,varargin);



%% ------ step 2: Verify a, M and L
if isempty(L)
    % Minimum transform length by default.
    Ls=1;
    
    % Use the window lengths, if any of them are numerical
    if isnumeric(g1)
        Ls=max(length(g1),Ls);
    end;

    if isnumeric(g2)
        Ls=max(length(g2),Ls);
    end;

    % ----- step 2b : Verify a, M and get L from the window length ----------
    L=dgtlength(Ls,a,M,kv.lt);

else

    % ----- step 2a : Verify a, M and get L

    Luser=dgtlength(L,a,M,kv.lt);
    if Luser~=L
        error(['%s: Incorrect transform length L=%i specified. Next valid length ' ...
               'is L=%i. See the help of DGTLENGTH for the requirements.'],...
              upper(mfilename),L,Luser)
    end;

end;

[g1,info_g1] = gabwin(g1,a,M,L,kv.lt,'callfun',upper(mfilename));
[g2,info_g2] = gabwin(g2,a,M,L,kv.lt,'callfun',upper(mfilename));
 
% gm must have the correct length, otherwise dgt will zero-extend it
% incorrectly using postpad instead of fir2long
g1=fir2long(g1,L);
g2=fir2long(g2,L);

gf1=comp_wfac(g1,a,M);
gf2=comp_wfac(g2,a,M);

gammaf=comp_gabmixdual_fac(gf1,gf2,L,a,M);

gamma=comp_iwfac(gammaf,L,a,M);

