function [AF,BF]=wilbounds(g,M,varargin)
%-*- texinfo -*-
%@deftypefn {Function} wilbounds
%@verbatim
%WILBOUNDS  Calculate frame bounds of Wilson basis
%   Usage:  [AF,BF]=wilbounds(g,M)
%           [AF,BF]=wilbounds(g,M,L)
%
%   Input parameters:
%           g       : Window function.
%           M       : Number of channels.
%           L       : Length of transform to do (optional)
%   Output parameters:
%           AF,BF   : Frame bounds.
%          
%   WILBOUNDS(g,M) calculates the frame bounds of the Wilson frame operator
%   of the Wilson basis with window g and M channels.
%
%   [A,B]=WILBOUNDS(g,a,M) returns the frame bounds A and B instead of
%   just the ratio.
%
%   The window g may be a vector of numerical values, a text string or a
%   cell array. See the help of WILWIN for more details.
%
%   If the length of g is equal to 2*M then the input window is
%   assumed to be a FIR window. Otherwise the smallest possible transform
%   length is chosen as the window length.
%
%   If the optional parameter L is specified, the window is cut or
%   zero-extended to length L.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/wilbounds.html}
%@seealso{wilwin, gabframebounds}
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

if nargin<2
   error('Too few input parameters.');    
end;

definput.keyvals.L=[];

[flags,keyvals]=ltfatarghelper({'L'},definput,varargin);
L=keyvals.L;

if size(M,1)>1 || size(M,2)>1
  error('M must be a scalar');
end;

if rem(M,1)~=0
  error('M must be an integer.')
end;

[g,info]=wilwin(g,M,L,'WILBOUNDS');
Lwindow=length(g);

[b,N,L]=assert_L(Lwindow,Lwindow,L,M,2*M,'WILBOUNDS');

g=fir2long(g,L);

a=M;

N=L/a;

if rem(N,2)==1
  error('L/M must be even.');
end;


% Get the factorization of the window.
gf=comp_wfac(g,a,2*M);

% Compute all eigenvalues.
lambdas=comp_gfeigs(gf,L,a,2*M);

% Min and max eigenvalue.
AF=lambdas(1);
BF=lambdas(size(lambdas,1));

% Divide by 2 (only difference to gfeigs).
AF=AF/2;
BF=BF/2;

if nargout<2
  AF=BF/AF;
end;

