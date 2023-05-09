function [o1,o2]=gabdualnorm(g,gamma,a,M,varargin);
%-*- texinfo -*-
%@deftypefn {Function} gabdualnorm
%@verbatim
%GABDUALNORM  Measure of how close a window is to being a dual window
%   Usage:  dn=gabdualnorm(g,gamma,a,M);
%           dn=gabdualnorm(g,gamma,a,M,L);
%           dn=gabdualnorm(g,gamma,a,M,'lt',lt);
%           [scal,res]=gabdualnorm(...);
%
%   Input parameters:
%         gamma  : input window..
%         g      : window function.
%         a      : Length of time shift.
%         M      : Number of modulations.
%         L      : Length of transform to consider
%   Output parameters:
%         dn     : dual norm.
%         scal   : Scaling factor
%         res    : Residual
%
%   GABDUALNORM(g,gamma,a,M) calculates how close gamma is to being a
%   dual window of the Gabor frame with window g and parameters a and M.
%
%   The windows g and gamma may be vectors of numerical values, text strings
%   or cell arrays. See the help of GABWIN for more details.
%
%   [scal,res]=GABDUALNORM(...) computes two entities: scal determines
%   if the windows are scaled correctly, it must be 1 for the windows to be
%   dual. res is close to zero if the windows (scaled correctly) are dual
%   windows.
%
%   GABDUALNORM(g,gamma,a,M,L) does the same, but considers a transform
%   length of L.
%
%   GABDUALNORM(g,gamma,a,M,'lt',lt) does the same for a non-separable
%   lattice specified by lt. Please see the help of MATRIX2LATTICETYPE
%   for a precise description of the parameter lt.
%
%   GABDUALNORM can be used to get the maximum relative reconstruction
%   error when using the two specified windows. Consider the following code
%   for some signal f, windows g, gamma, parameters a and M and 
%   transform-length L (See help on DGT on how to obtain L*):
%
%     fr=idgt(dgt(f,g,a,M),gamma,a); 
%     er=norm(f-fr)/norm(f);
%     eest=gabdualnorm(g,gamma,a,M,L);
%
%   Then  er<eest for all possible input signals f.
%
%   To get a similar estimate for an almost tight window gt, simply use :
%  
%     eest=gabdualnorm(gt,gt,a,M,L);
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/gabdualnorm.html}
%@seealso{gabframebounds, dgt}
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

  
%% ---------- Assert correct input.

if nargin<4
  error('%s: Too few input parameters.',upper(mfilename));
end;

definput.keyvals.L=[];
definput.keyvals.lt=[0 1];
[flags,kv,L]=ltfatarghelper({'L'},definput,varargin);

%% ------ step 2: Verify a, M and L
if isempty(L)
    % Minimum transform length by default.
    Ls=1;
    
    % Use the window lengths, if any of them are numerical
    if isnumeric(g)
        Ls=max(length(g),Ls);
    end;

    if isnumeric(gamma)
        Ls=max(length(gamma),Ls);
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

[g,    info_g]     = gabwin(g,    a,M,L,kv.lt,'callfun',upper(mfilename));
[gamma,info_gamma] = gabwin(gamma,a,M,L,kv.lt,'callfun',upper(mfilename));
 
% gamma must have the correct length, otherwise dgt will zero-extend it
% incorrectly using postpad instead of fir2long
gamma=fir2long(gamma,L);
g    =fir2long(g,L);

% Handle the Riesz basis (dual lattice) case.
if a>M

  % Calculate the right-hand side of the Wexler-Raz equations.
  rhs=dgt(gamma,g,a,M,L,'lt',kv.lt);
  scalconst=1;
  
else
  
  % Calculate the right-hand side of the Wexler-Raz equations.
  rhs=dgt(gamma,g,M,a,L,'lt',kv.lt);
  
  scalconst=a/M;
  
end;

if nargout<2
  % Subtract from the first element to make it zero, if the windows are
  % dual.
  rhs(1)=rhs(1)-scalconst;

  o1=norm(rhs(:),1);
else
  % Scale the first element to make it one, if the windows are dual.
  o1=rhs(1)/scalconst;
  o2=norm(rhs(2:end),1);
end;

