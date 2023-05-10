function c = comp_dst(f,type)
%COMP_DST Calculates DST
%   Input parameters:
%         f     : Input data.
%         type  : DST version.
%
%
%   Url: http://ltfat.github.io/doc/comp/comp_dst.html

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

      s1=dft([zeros(1,W,assert_classname(f));...
	           f;...
	           zeros(1,W,assert_classname(f));...
	           -flipud(f)]);


      % This could be done by a repmat instead.
      for w=1:W
         c(:,w)=s1(2:L+1,w)-s1(2*L+2:-1:L+3,w);
      end;

      c=c*1i/2;
   case 2
      c=zeros(L,W,assert_classname(f));

      m1=1/sqrt(2)*exp(-(1:L)*pi*i/(2*L)).';
      m1(L)=-i;
  
      m2=-1/sqrt(2)*exp((1:L-1)*pi*i/(2*L)).';

      s1=i*fft([f;-flipud(f)])/sqrt(L)/2;

      % This could be done by a repmat instead.
      for w=1:W
        c(:,w)=s1(2:L+1,w).*m1+[s1(2*L:-1:L+2,w).*m2;0];
      end;
   case 3
      c=zeros(2*L,W,assert_classname(f));

      m1=1/sqrt(2)*exp((1:L)*pi*i/(2*L)).';
      m1(L)=i;

      m2=-1/sqrt(2)*exp(-(L-1:-1:1)*pi*i/(2*L)).';

      for w=1:W
        c(:,w)=[0;m1.*f(:,w);m2.*f(L-1:-1:1,w)];
      end;

      c=-sqrt(L)*2*i*ifft(c);
      c=c(1:L,:);
   case 4
      s1=zeros(2*L,W,assert_classname(f));
      c=zeros(L,W,assert_classname(f));

      m1=1/sqrt(2)*exp(-(0:L-1)*pi*i/(2*L)).';
      m2=-1/sqrt(2)*exp((1:L)*pi*i/(2*L)).';

      for w=1:W
        s1(:,w)=[m1.*f(:,w);flipud(m2).*f(L:-1:1,w)];
      end;

      s1=i*exp(-pi*i/(4*L))*fft(s1)/sqrt(2*L);

      % This could be done by a repmat instead.
      for w=1:W
        c(:,w)=s1(1:L,w).*m1+s1(2*L:-1:L+1,w).*m2;
      end;
   otherwise
      error('%s: Type not supported.',upper(mfilename));
end


if isreal(f)
   c=real(c);
end;

