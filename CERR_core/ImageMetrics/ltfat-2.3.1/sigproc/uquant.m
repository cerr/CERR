function xo=uquant(xi,varargin);
%-*- texinfo -*-
%@deftypefn {Function} uquant
%@verbatim
%UQUANT  Simulate uniform quantization
%   Usage:  x=uquant(x);
%           x=uquant(x,nbits,xmax,...);
%
%   UQUANT(x,nbits,xmax) simulates the effect of uniform quantization of
%   x using nbits bits. The output is simply x rounded to 2^{nbits}
%   different values.  The xmax parameters specify the maximal value that
%   should be quantifiable.
%
%   UQUANT(x,nbits) assumes a maximal quantifiable value of 1.
%
%   UQUANT(x) additionally assumes 8 bit quantization.
%
%   UQUANT takes the following flags at the end of the input arguments:
%
%     'nbits'  Number of bits to use in the quantization. Default is 8.
%
%     'xmax'   Maximal quantifiable value. Default is 1.
%  
%     's'      Use signed quantization. This assumes that the signal
%              has a both positive and negative part. Useful for sound
%              signals. This is the default.
%
%     'u'      Use unsigned quantization. Assumes the signal is positive.
%              Negative values are silently rounded to zero.
%              Useful for images.
%
%   If this function is applied to a complex signal, it will be applied to
%   the real and imaginary part separately.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/sigproc/uquant.html}
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

%   AUTHOR : Peter L. Soendergaard and Bruno Torresani.  
%   TESTING: OK
%   REFERENCE: OK

if nargin<1
  error('Too few input parameters.');
end;

% Define initial value for flags and key/value pairs.
definput.flags.sign={'s','u'};
definput.keyvals.nbits=8;
definput.keyvals.xmax=1;
[flags,keyvals,nbits,xmax]=ltfatarghelper({'nbits','xmax'},definput,varargin);

% ------ handle complex values ------------------
if ~isreal(xi)
  xo = uquant(real(xi),nbits,xmax,varargin{:}) + ...
	i*uquant(imag(xi),nbits,xmax,varargin{:});
  return
end;

if nbits<2
  error('Must specify at least 2 bits.');
end;

% Calculate number of buckets.
nbuck=2^nbits;    

if xmax<max(abs(xi(:)))
  error('Signal contains values higher than xmax.');
end;

if flags.do_s
  
  % ------------ unsigned case -----------------
  
  bucksize=xmax/(nbuck/2-1);
  
  xo=round(xi/bucksize)*bucksize;        
  
else

  % ------------- signed case------------
  
  bucksize=xmax/(nbuck-.51);
  
  % Thresh all negative values to zero.
  xi=xi.*(xi>0);
  
  xo=round(xi/bucksize)*bucksize;        
  
end;


