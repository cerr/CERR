function c = comp_dct(f,type)
%COMP_DCT Calculates DCT
%   Input parameters:
%         f     : Input data.
%         type  : DCT version.
%
%
%   Url: http://ltfat.github.io/doc/comp/comp_dct.html

% Copyright (C) 2005-2022 Peter L. Soendergaard <peter@sonderport.dk> and others.
% This file is part of LTFAT version 2.5.0
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


[L,W] = size(f);


switch type
   case 1
      c=zeros(L,W,assert_classname(f));
      f2=[f;flipud(f(2:L-1,:))]/sqrt(2);
      f2(1,:)=f2(1,:)*sqrt(2);
      f2(L,:)=f2(L,:)*sqrt(2);
  
      s1=fft(f2)/sqrt(2*L-2);

      c=s1(1:L,:)+[zeros(1,W);s1(2*L-2:-1:L+1,:);zeros(1,W)];

      c(2:L-1,:)=c(2:L-1,:)/sqrt(2);
   case 2
      c=zeros(L,W,assert_classname(f));
      m1=1/sqrt(2)*exp(-(0:L-1)*pi*i/(2*L)).';
      m1(1)=1;

      m2=1/sqrt(2)*exp((1:L-1)*pi*i/(2*L)).';

      s1=fft([f;flipud(f)]);

      c=bsxfun(@times,s1(1:L,:),m1)+[zeros(1,W);bsxfun(@times,s1(2*L:-1:L+2,:),m2)];

      c=c/sqrt(L)/2;
   case 3
      c=zeros(2*L,W,assert_classname(f));

      m1=1/sqrt(2)*exp(-(0:L-1)*pi*i/(2*L)).';
      m1(1)=1;
  
      m2=1/sqrt(2)*exp((L-1:-1:1)*pi*i/(2*L)).';

      c=[bsxfun(@times,m1,f);zeros(1,W);bsxfun(@times,m2,f(L:-1:2,:))];

      c=fft(c)/sqrt(L);

      c=c(1:L,:);
   case 4
      s1=zeros(2*L,W,assert_classname(f));
      c=zeros(L,W,assert_classname(f));

      m1=1/sqrt(2)*exp(-(0:L-1)*pi*i/(2*L)).';
      m2=1/sqrt(2)*exp((1:L)*pi*i/(2*L)).';

      s1=[bsxfun(@times,m1,f);bsxfun(@times,flipud(m2),f(L:-1:1,:))];
  
      s1=exp(-pi*i/(4*L))*fft(s1)/sqrt(2*L);

      c=bsxfun(@times,s1(1:L,:),m1)+bsxfun(@times,s1(2*L:-1:L+1,:),m2);
   otherwise
      error('%s: Type not supported.',upper(mfilename));
end


if isreal(f)
   c=real(c);
end;

