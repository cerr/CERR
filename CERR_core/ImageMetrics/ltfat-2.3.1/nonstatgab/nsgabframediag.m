function d=nsgabframediag(g,a,M)
%-*- texinfo -*-
%@deftypefn {Function} nsgabframediag
%@verbatim
%NSGABFRAMEDIAG  Diagonal of Gabor frame operator
%   Usage:  d=nsgabframediag(g,a,M);
%
%   Input parameters:
%         g     : Window function.
%         a     : Length of time shift.
%         M     : Number of channels.
%   Output parameters:
%         d     : Diagonal stored as a column vector
%
%   NSGABFRAMEDIAG(g,a,M) computes the diagonal of the non-stationary
%   Gabor frame operator with respect to the window g and parameters a*
%   and M. The diagonal is stored as a column vector of length L=sum(a).
%
%   The diagonal of the frame operator can for instance be used as a
%   preconditioner.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/nonstatgab/nsgabframediag.html}
%@seealso{nsdgt}
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

L=sum(a);

timepos=cumsum(a)-a(1);

N=length(a);

[g,info]=nsgabwin(g,a,M);

a=info.a;
M=info.M;

d=zeros(L,1,assert_classname(g{1}));
for ii=1:N
    shift=floor(length(g{ii})/2);
    temp=abs(circshift(g{ii},shift)).^2*M(ii);
    tempind=mod((1:length(g{ii}))+timepos(ii)-shift-1,L)+1;
    d(tempind)=d(tempind)+temp;
end



