function c=ufilterbank(f,g,a,varargin)  
%-*- texinfo -*-
%@deftypefn {Function} ufilterbank
%@verbatim
%UFILTERBANK   Apply Uniform filterbank
%   Usage:  c=ufilterbank(f,g,a);
%
%   UFILTERBANK(f,g,a) applies the filter given in g to the signal
%   f. Each subband will be subsampled by a factor of a (the
%   hop-size). If f is a matrix, the transformation is applied to each
%   column.
%
%   The filters g must be a cell-array, where each entry in the cell
%   array corresponds to a filter.
%
%   If f is a single vector, then the output will be a matrix, where each
%   column in f is filtered by the corresponding filter in g. If f is
%   a matrix, the output will be 3-dimensional, and the third dimension will
%   correspond to the columns of the input signal.
%
%   The coefficients c computed from the signal f and the filterbank
%   with windows g_m are defined by
%
%                   L-1
%      c(n+1,m+1) = sum f(l+1) * g_m (an-l+1)
%                   l=0
%
%
%
%   References:
%     H. Boelcskei, F. Hlawatsch, and H. G. Feichtinger. Frame-theoretic
%     analysis of oversampled filter banks. Signal Processing, IEEE
%     Transactions on, 46(12):3256--3268, 2002.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/filterbank/ufilterbank.html}
%@seealso{ifilterbank, filterbankdual}
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

if isempty(a) || ~all(a(:,1)==a(1)) ...
   || ~isnumeric(a) || any(rem(a(:),1)~=0)
    error(['%s: a has to be either scalar or a numel(g) vector of equal',...
           ' integers.'], upper(mfilename));
end

definput.import={'pfilt'};
definput.keyvals.L=[];
[~,kv,L]=ltfatarghelper({'L'},definput,varargin);

[f,Ls,W]=comp_sigreshape_pre(f,'UFILTERBANK',0);

a=a(1);

if isempty(L)
  L=filterbanklength(Ls,a);
end;

[g,asan]=filterbankwin(g,a,L,'normal');

M=numel(g);
N=L/a;

f=postpad(f,L);

g = comp_filterbank_pre(g,asan,L,kv.crossover);

ctmp=comp_filterbank(f,g,asan);

c=zeros(N,M,W,assert_classname(f));
for m=1:M    
    c(:,m,:)=ctmp{m};
end;

