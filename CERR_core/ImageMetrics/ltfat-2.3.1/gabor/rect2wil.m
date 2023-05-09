function cout=rect2wil(cin);
%-*- texinfo -*-
%@deftypefn {Function} rect2wil
%@verbatim
%RECT2WIL  Inverse of WIL2RECT
%   Usage:  c=rect2wil(c);
%   
%   RECT2WIL(c) takes Wilson coefficients processed by WIL2RECT and
%   puts them back in the compact form used by DWILT and IDWILT. The
%   coefficients can then be processed by IDWILT.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/rect2wil.html}
%@seealso{wil2rect, dwilt, idwilt}
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
%   TESTING: OK
%   REFERENCE: OK

complainif_argnonotinrange(nargin,1,1,mfilename);
  
M=size(cin,1)-1;
N=size(cin,2);
W=size(cin,3);

cout=zeros(2*M,N/2,W,assert_classname(cin));

if rem(M,2)==0
  for ii=0:N/2-1
    cout(1:M+1  ,ii+1,:)=cin(1:M+1,2*ii+1,:);
    cout(M+2:2*M,ii+1,:)=cin(2:M,2*ii+2,:);
  end;
else
  for ii=0:N/2-1
    cout(1:M    ,ii+1,:)=cin(1:M,2*ii+1,:);
    cout(M+2:2*M,ii+1,:)=cin(2:M,2*ii+2,:);
    cout(M+1    ,ii+1,:)=cin(M+1,2*ii+2,:);
  end;  
end;


