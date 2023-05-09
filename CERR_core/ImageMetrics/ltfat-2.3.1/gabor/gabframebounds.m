function [AF,BF]=gabframebounds(g,a,M,varargin)
%-*- texinfo -*-
%@deftypefn {Function} gabframebounds
%@verbatim
%GABFRAMEBOUNDS  Calculate frame bounds of Gabor frame
%   Usage:  fcond=gabframebounds(g,a,M);
%           [A,B]=gabframebounds(g,a,M);
%           [A,B]=gabframebounds(g,a,M,L);
%           [A,B]=gabframebounds(g,a,M,'lt',lt);
%
%   Input parameters:
%           g     : The window function.
%           a     : Length of time shift.
%           M     : Number of channels.
%           L     : Length of transform to consider.
%           lt    : Lattice type (for non-separable lattices).
%   Output parameters:
%           fcond : Frame condition number (B/A)
%           A,B   : Frame bounds.
%          
%   GABFRAMEBOUNDS(g,a,M) calculates the ratio B/A of the frame bounds
%   of the Gabor system with window g, and parameters a, M.
%
%   [A,B]=GABFRAMEBOUNDS(...) returns the frame bounds A and B*
%   instead of just the ratio.
%
%   The window g may be a vector of numerical values, a text string or a
%   cell array. See the help of GABWIN for more details.
%  
%   GABFRAMEBOUNDS(g,a,M,L) will cut or zero-extend the window to length
%   L.
%
%   GABFRAMEBOUNDS(g,a,M,'lt',lt) does the same for a non-separable
%   lattice specified by lt. Please see the help of MATRIX2LATTICETYPE
%   for a precise description of the parameter lt.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/gabframebounds.html}
%@seealso{gabrieszbounds, gabwin}
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

if nargin<3
  error('%s: Too few input parameters.',upper(mfilename));
end;

definput.keyvals.L=[];
definput.keyvals.lt=[0 1];
[flags,kv,L]=ltfatarghelper({'L'},definput,varargin);


%% ------ step 2: Verify a, M and L
if isempty(L)
    if isnumeric(g)
        % Use the window length
        Ls=length(g);
    else
        % Use the smallest possible length
        Ls=1;
    end;

    % ----- step 2b : Verify a, M and get L from the window length ----------
    L=dgtlength(Ls,a,M,kv.lt);

else

    % ----- step 2a : Verify a, M and get L

    Luser=dgtlength(L,a,M,kv.lt);
    if Luser~=L
        error(['%s: Incorrect transform length L=%i specified. Next valid length ' ...
               'is L=%i. See the help of DGTLENGTH for the requirements.'],...
              upper(mfilename),L,Luser);
    end;

end;

%% ----- step 3 : Determine the window 

[g,info]=gabwin(g,a,M,L,kv.lt,'callfun',upper(mfilename));

if L<info.gl
  error('%s: Window is too long.',upper(mfilename));
end;

%% ----- actual computation ------------

g=fir2long(g,L);
R=size(g,2);

if kv.lt(2)==1
    % Rectangular case
    % Get the factorization of the window.
    gf=comp_wfac(g,a,M);
    
    % Compute all eigenvalues.
    lambdas=comp_gfeigs(gf,L,a,M);
    s=size(lambdas,1);
    
else
    
    % Convert to multi-window
    mwin=comp_nonsepwin2multi(g,a,M,kv.lt,L);
    
    % Get the factorization of the window.
    gf=comp_wfac(mwin,a*kv.lt(2),M);

    % Compute all eigenvalues.
    lambdas=comp_gfeigs(gf,L,a*kv.lt(2),M);
    s=size(lambdas,1);
        
end;
    
% Min and max eigenvalue.
if a>M*R
    % This can is not a frame, so A is identically 0.
    AF=0;
else
    AF=lambdas(1);
end;

BF=lambdas(s);

if nargout<2
    % Avoid the potential warning about division by zero.
    if AF==0
        AF=Inf;
    else
        AF=BF/AF;
    end;
end;


