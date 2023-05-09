function cout=wil2rect(cin);
%-*- texinfo -*-
%@deftypefn {Function} wil2rect
%@verbatim
%WIL2RECT  Arrange Wilson coefficients in a rectangular layout
%   Usage:  c=wil2rect(c);
%
%   WIL2RECT(c) rearranges the coefficients c in a rectangular shape. The
%   coefficients must have been obtained from DWILT. After rearrangement
%   the coefficients are placed correctly on the time/frequency-plane.
%
%   The rearranged array is larger than the input array: it contains
%   zeros on the spots where the Wilson transform is missing a DC or
%   Nyquest component.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/wil2rect.html}
%@seealso{rect2wil, dwilt, wmdct}
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
  
complainif_argnonotinrange(nargin,1,1,mfilename);
  
M=size(cin,1)/2;
N=size(cin,2)*2;
W=size(cin,3);

cout=zeros(M+1,N,W,assert_classname(cin));

if rem(M,2)==0
  for ii=0:N/2-1
    cout(1:M+1,2*ii+1,:)=cin(1:M+1  ,ii+1,:);
    cout(2:M,2*ii+2,:)  =cin(M+2:2*M,ii+1,:);
  end;
else
  for ii=0:N/2-1
    cout(1:M,2*ii+1,:)  =cin(1:M    ,ii+1,:);
    cout(2:M,2*ii+2,:)  =cin(M+2:2*M,ii+1,:);
    cout(M+1,2*ii+2,:)  =cin(M+1    ,ii+1,:);
  end;  
end;


