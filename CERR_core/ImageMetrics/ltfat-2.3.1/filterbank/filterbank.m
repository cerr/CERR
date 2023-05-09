function c=filterbank(f,g,a,varargin)  
%-*- texinfo -*-
%@deftypefn {Function} filterbank
%@verbatim
%FILTERBANK   Apply filterbank
%   Usage:  c=filterbank(f,g,a);
%
%   FILTERBANK(f,g,a) applies the filters given in g to the signal
%   f. Each subband will be subsampled by a factor of a (the
%   hop-size). In contrast to UFILTERBANK, a can be a vector so the
%   hop-size can be channel-dependant. If f is a matrix, the
%   transformation is applied to each column.
%
%   The filters g must be a cell-array, where each entry in the cell
%   array corresponds to an FIR filter.
%
%   The output coefficients are stored a cell array. More precisely, the
%   n'th cell of c, c{m}, is a 2D matrix of size M(n) xW and
%   containing the output from the m'th channel subsampled at a rate of
%   a(m).  c{m}(n,l) is thus the value of the coefficient for time index
%   n, frequency index m and signal channel l.
%
%   The coefficients c computed from the signal f and the filterbank
%   with windows g_m are defined by
%
%                 L-1
%      c_m(n+1) = sum f(l+1) * g_m (a(m)n-l+1)
%                 l=0
%
%   where an-l is computed modulo L.
%
%
%   References:
%     H. Boelcskei, F. Hlawatsch, and H. G. Feichtinger. Frame-theoretic
%     analysis of oversampled filter banks. Signal Processing, IEEE
%     Transactions on, 46(12):3256--3268, 2002.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/filterbank/filterbank.html}
%@seealso{ufilterbank, ifilterbank, pfilt}
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
    
if nargin<3
  error('%s: Too few input parameters.',upper(mfilename));
end;

definput.import={'pfilt'};
definput.keyvals.L=[];
[~,kv,L]=ltfatarghelper({'L'},definput,varargin);

[f,Ls]=comp_sigreshape_pre(f,'FILTERBANK',0);
  
if ~isnumeric(a) || isempty(a)
  error('%s: a must be non-empty numeric.',upper(mfilename));
end;
  
if isempty(L)
   L=filterbanklength(Ls,a);
end;

[g,asan]=filterbankwin(g,a,L,'normal');

%  if size(a,1)>1 
%    if  size(a,1)~= numel(g);
%      error(['%s: The number of entries in "a" must match the number of ' ...
%             'filters.'],upper(mfilename));
%    end;
%  end;

f=postpad(f,L);

g=comp_filterbank_pre(g,asan,L,kv.crossover);
c=comp_filterbank(f,g,asan);



