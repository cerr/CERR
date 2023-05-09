function [f,g]=idgtreal(coef,g,a,M,varargin)
%-*- texinfo -*-
%@deftypefn {Function} idgtreal
%@verbatim
%IDGTREAL  Inverse discrete Gabor transform for real-valued signals
%   Usage:  f=idgtreal(c,g,a,M);
%           f=idgtreal(c,g,a,M,Ls);
%
%   Input parameters:
%         c     : Array of coefficients.
%         g     : Window function.
%         a     : Length of time shift.
%         M     : Number of channels.
%         Ls    : length of signal.
%   Output parameters:
%         f     : Signal.
%
%   IDGTREAL(c,g,a,M) computes the Gabor expansion of the input coefficients
%   c with respect to the real-valued window g, time shift a and number of
%   channels M. c is assumed to be the positive frequencies of the Gabor
%   expansion of a real-valued signal.
%
%   It must hold that size(c,1)==floor(M/2)+1. Note that since the
%   correct number of channels cannot be deduced from the input, IDGTREAL
%   takes an additional parameter as opposed to IDGT.
%
%   The window g may be a vector of numerical values, a text string or a
%   cell array. See the help of GABWIN for more details.
%  
%   IDGTREAL(c,g,a,M,Ls) does as above but cuts or extends f to length Ls.
%
%   [f,g]=IDGTREAL(...) additionally outputs the window used in the
%   transform. This is usefull if the window was generated from a description
%   in a string or cell array.
%
%   For perfect reconstruction, the window used must be a dual window of the
%   one used to generate the coefficients.
%
%   If g is a row vector, then the output will also be a row vector. If c is
%   3-dimensional, then IDGTREAL will return a matrix consisting of one column
%   vector for each of the TF-planes in c.
%
%   See the help on IDGT for the precise definition of the inverse Gabor
%   transform.
%
%   IDGTREAL takes the following flags at the end of the line of input
%   arguments:
%
%     'freqinv'  Use a frequency-invariant phase. This is the default
%                convention described in the help for DGT.
%
%     'timeinv'  Use a time-invariant phase. This convention is typically 
%                used in filter bank algorithms.
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
%     ga={'dual',gs};      %  analysis window
%
%     [c,Ls]=dgtreal(f,ga,a,M); % analysis
%
%     % ... do interesting stuff to c at this point ...
%  
%     r=idgtreal(c,gs,a,M,Ls); % synthesis
%
%     norm(f-r)                % test
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
%     c=dgtreal(f,ga,a,M);  % analysis
%
%     % ... do interesting stuff to c at this point ...
%  
%     r=idgtreal(c,gs,a,M,Ls); % synthesis
%
%     norm(f-r)       % test
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/idgtreal.html}
%@seealso{idgt, gabwin, gabdual, dwilt}
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

if nargin<4
  error('%s: Too few input parameters.',upper(mfilename));
end;

if ~isnumeric(g) && prod(size(g))==1
  error('g must be a vector (you probably forgot to supply the window function as input parameter.)');
end;

% Define initial value for flags and key/value pairs.
definput.keyvals.Ls=[];
definput.keyvals.lt=[0 1];
definput.flags.phase={'freqinv','timeinv'};

[flags,kv,Ls]=ltfatarghelper({'Ls'},definput,varargin);

N=size(coef,2);
W=size(coef,3);

% Make a dummy call to test the input parameters
Lsmallest=dgtlength(1,a,M,kv.lt);

M2=floor(M/2)+1;

if M2~=size(coef,1)
  error('Mismatch between the specified number of channels and the size of the input coefficients.');
end;

L=N*a;

if rem(L,Lsmallest)>0
    error('%s: Invalid size of coefficient array.',upper(mfilename));
end;

if kv.lt(2)>2
  error('Only rectangular or quinqux lattices are supported.');  
end;

if kv.lt(2)~=1 && flags.do_timeinv
    error(['%s: Time-invariant phase for quinqux lattice is not ',...
           'supported.'],upper(mfilename));
end


%% ----- step 3 : Determine the window 

[g,info]=gabwin(g,a,M,L,kv.lt,'callfun',upper(mfilename));

if L<info.gl
  error('%s: Window is too long.',upper(mfilename));
end;

if ~isreal(g)
  error('%s: Window must be real-valued.',upper(mfilename));
end;

% Do the actual computation.
f=comp_idgtreal(coef,g,a,M,kv.lt,flags.do_timeinv);

% Cut or extend f to the correct length, if desired.
if ~isempty(kv.Ls)
  f=postpad(f,kv.Ls);
else
  kv.Ls=L;
end;

f=comp_sigreshape_post(f,Ls,0,[0; W]);

