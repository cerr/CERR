function [xo,Nout]=largestr(xi,p,varargin)
%-*- texinfo -*-
%@deftypefn {Function} largestr
%@verbatim
%LARGESTR   Keep fixed ratio of largest coefficients
%   Usage:  xo=largestr(x,p);
%           xo=largestr(x,p,mtype);  
%           [xo,N]=largestr(...);
%
%   LARGESTR(x,p) returns an array of the same size as x keeping
%   the fraction p of the coefficients. The coefficients with the largest
%   magnitude are kept.
%
%   [xo,n]=LARGESTR(xi,p) additionally returns the number of coefficients
%   kept.
% 
%   *Note:* If the function is used on coefficients coming from a
%   redundant transform or from a transform where the input signal was
%   padded, the coefficient array will be larger than the original input
%   signal. Therefore, the number of coefficients kept might be higher than
%   expected.
%
%   LARGESTR takes the following flags at the end of the line of input
%   arguments:
%
%     'hard'    Perform hard thresholding. This is the default.
%
%     'wiener'  Perform empirical Wiener shrinkage. This is in between
%               soft and hard thresholding.
%
%     'soft'    Perform soft thresholding.  
%
%     'full'    Returns the output as a full matrix. This is the default.
%
%     'sparse'  Returns the output as a sparse matrix.   
%
%   *Note:* If soft- or Wiener thresholding is selected, one less
%   coefficient will actually be returned. This is caused by that
%   coefficient being set to zero.
%
%
%   References:
%     S. Mallat. A wavelet tour of signal processing. Academic Press, San
%     Diego, CA, 1998.
%     
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/sigproc/largestr.html}
%@seealso{largestn}
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
%   TESTING: OK
%   REFERENCE: OK

if nargin<2
  error('%s: Too few input parameters.',upper(mfilename));
end;

definput.import={'thresh'};
[flags,keyvals]=ltfatarghelper({},definput,varargin);

if (prod(size(p))~=1 || ~isnumeric(p))
  error('p must be a scalar.');
end;

wascell=iscell(xi);

if wascell
  [xi,shape]=cell2vec(xi);
end;

% Determine the size of the array.
ss=numel(xi);

N=round(ss*p);
  
[xo,Nout]=largestn(xi,N,flags.outclass,flags.iofun);

if wascell
  xo=vec2cell(xo,shape);
end;

