function y = rms(f,varargin)
%-*- texinfo -*-
%@deftypefn {Function} rms
%@verbatim
%RMS RMS value of signal
%   Usage: y = rms(f);
%          y = rms(f,...);
%
%   RMS(f) computes the RMS (Root Mean Square) value of a finite sampled
%   signal sampled at a uniform sampling rate. This is a vector norm
%   equal to the l^2 averaged by the length of the signal.
%
%   If the input is a matrix or ND-array, the RMS is computed along the
%   first (non-singleton) dimension, and a vector of values is returned.
%
%   The RMS value of a signal x of length N is computed by
%
%                            N
%      rms(f) = 1/sqrt(N) ( sum |f(n)|^2 )^(1/2)
%                           n=1
%
%   RMS takes the following flags at the end of the line of input
%   parameters:
%
%     'ac'       Consider only the AC component of the signal (i.e. the mean is
%                removed).
%
%     'dim',d    Work along specified dimension. The default value of []
%                means to work along the first non-singleton one.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/sigproc/rms.html}
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

%   AUTHOR : Peter L. Soendergaard
  
%% ------ Checking of input parameters ---------

if ~isnumeric(f) 
  error('%s: Input must be numerical.',upper(mfilename));
end;

if nargin<1
  error('%s: Too few input parameters.',upper(mfilename));
end;

definput.keyvals.dim=[];
definput.flags.mean={'noac','ac'};
[flags,kv]=ltfatarghelper({},definput,varargin);

%% ------ Computation --------------------------

% It is better to use 'norm' instead of explicitly summing the squares, as
% norm (hopefully) attempts to avoid numerical overflow.
 
[f,L,Ls,W,dim,permutedsize,order]=assert_sigreshape_pre(f,[],kv.dim, ...
                                                  upper(mfilename));
permutedsize(1)=1;
y=zeros(permutedsize);
if flags.do_ac

  for ii=1:W        
    y(1,ii) = norm(f(:,ii)-mean(f(:,ii)))/sqrt(L);
   end;

else

  for ii=1:W
    y(1,ii)=norm(f(:,ii))/sqrt(L);
  end;

end;
  
y=assert_sigreshape_post(y,kv.dim,permutedsize,order);

