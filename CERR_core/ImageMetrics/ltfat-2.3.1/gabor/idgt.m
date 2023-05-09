function [f,g]=idgt(coef,g,a,varargin)
%-*- texinfo -*-
%@deftypefn {Function} idgt
%@verbatim
%IDGT  Inverse discrete Gabor transform
%   Usage:  f=idgt(c,g,a);
%           f=idgt(c,g,a,Ls);
%           f=idgt(c,g,a,Ls,lt);
%
%   Input parameters:
%         c     : Array of coefficients.
%         g     : Window function.
%         a     : Length of time shift.
%         Ls    : Length of signal.
%         lt    : Lattice type (for non-separable lattices)
%   Output parameters:
%         f     : Signal.
%
%   IDGT(c,g,a) computes the Gabor expansion of the input coefficients
%   c with respect to the window g and time shift a. The number of 
%   channels is deduced from the size of the coefficients c.
%
%   IDGT(c,g,a,Ls) does as above but cuts or extends f to length Ls.
%
%   [f,g]=IDGT(...) additionally outputs the window used in the
%   transform. This is useful if the window was generated from a description
%   in a string or cell array.
%
%   For perfect reconstruction, the window used must be a dual window of the
%   one used to generate the coefficients.
%
%   The window g may be a vector of numerical values, a text string or a
%   cell array. See the help of GABWIN for more details.
%
%   If g is a row vector, then the output will also be a row vector. If c is
%   3-dimensional, then IDGT will return a matrix consisting of one column
%   vector for each of the TF-planes in c.
%
%   Assume that f=IDGT(c,g,a,L) for an array c of size M xN. 
%   Then the following holds for k=0,...,L-1: 
% 
%               N-1 M-1          
%     f(l+1)  = sum sum c(m+1,n+1)*exp(2*pi*i*m*l/M)*g(l-a*n+1)
%               n=0 m=0          
%
%   Non-separable lattices:
%   -----------------------
%
%   IDGT(c,g,a,'lt',lt) computes the Gabor expansion of the input
%   coefficients c with respect to the window g, time shift a and
%   lattice type lt. Please see the help of MATRIX2LATTICETYPE for a
%   precise description of the parameter lt.
%
%   Assume that f=dgt(c,g,a,L,lt) for an array c of size MxN.
%   Then the following holds for k=0,...,L-1:
% 
%               N-1 M-1          
%     f(l+1)  = sum sum c(m+1,n+1)*exp(2*pi*i*m*l/M)*g(l-a*n+1)
%               n=0 m=0          
%
%   Additional parameters:
%   ----------------------
%
%   IDGT takes the following flags at the end of the line of input
%   arguments:
%
%     'freqinv'  Compute an IDGT using a frequency-invariant phase. This
%                is the default convention described above.
%
%     'timeinv'  Compute an IDGT using a time-invariant phase. This
%                convention is typically used in FIR-filter algorithms.
%
%   Examples:
%   ---------
%
%   The following example demostrates the basic pricinples for getting
%   perfect reconstruction (short version):
%
%     f=greasy;            % test signal
%     a=32;                % time shift
%     M=64;                % frequency shift
%     gs={'blackman',128}; % synthesis window
%     ga={'dual',gs};      % analysis window
%
%     [c,Ls]=dgt(f,ga,a,M);    % analysis
%
%     % ... do interesting stuff to c at this point ...
%  
%     r=idgt(c,gs,a,Ls); % synthesis
%
%     norm(f-r)          % test
%
%   The following example does the same as the previous one, with an
%   explicit construction of the analysis and synthesis windows:
%
%     f=greasy;     % test signal
%     a=32;         % time shift
%     M=64;         % frequency shift
%     Ls=length(f); % signal length
%
%     % Length of transform to do
%     L=dgtlength(Ls,a,M);
%
%     % Analysis and synthesis window
%     gs=firwin('blackman',128);
%     ga=gabdual(gs,a,M,L);
%
%     c=dgt(f,ga,a,M); % analysis
%
%     % ... do interesting stuff to c at this point ...
%  
%     r=idgt(c,gs,a,Ls);  % synthesis
%
%     norm(f-r)  % test
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/idgt.html}
%@seealso{dgt, gabwin, dwilt, gabtight}
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
%   TESTING: TEST_DGT
%   REFERENCE: OK

% Check input paramameters.

if nargin<3
  error('%s: Too few input parameters.',upper(mfilename));
end;

if ~isnumeric(g) && numel(g)==1
  error('g must be a vector (you probably forgot to supply the window function as input parameter.)');
end;

definput.keyvals.Ls=[];
definput.keyvals.lt=[0 1];
definput.keyvals.dim=[];
definput.flags.phase={'freqinv','timeinv'};
[flags,kv,Ls]=ltfatarghelper({'Ls'},definput,varargin);

M=size(coef,1);
N=size(coef,2);
W=size(coef,3);

if ~isnumeric(a) || ~isscalar(a)
  error('%s: "a" must be a scalar',upper(mfilename));
end;

if rem(a,1)~=0
  error('%s: "a" must be an integer',upper(mfilename));
end;

L=N*a;

Ltest=dgtlength(L,a,M,kv.lt);

if Ltest~=L
    error(['%s: Incorrect size of coefficient array or "a" parameter. See ' ...
           'the help of DGTLENGTH for the requirements.'], ...
          upper(mfilename))
end;

g=gabwin(g,a,M,L,kv.lt,'callfun',upper(mfilename));

f=comp_idgt(coef,g,a,kv.lt,flags.do_timeinv,0);

% Cut or extend f to the correct length, if desired.
if ~isempty(Ls)
  f=postpad(f,Ls);
else
  Ls=L;
end;

f=comp_sigreshape_post(f,Ls,0,[0; W]);

