function [coef]=comp_dgt_fb(f,g,a,M)
%-*- texinfo -*-
%@deftypefn {Function} comp_dgt_fb
%@verbatim
%COMP_DGT_FB  Filter bank DGT
%   Usage:  c=comp_dgt_fb(f,g,a,M);
%  
%   This is a computational routine. Do not call it directly.
%
%   See help on DGT.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_dgt_fb.html}
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

% Calculate the parameters that was not specified.
L=size(f,1);
N=L/a;
gl=length(g);
W=size(f,2);      % Number of columns to apply the transform to.
glh=floor(gl/2);  % gl-half


% Conjugate the window here.
g=conj(fftshift(g));

coef=zeros(M,N,W,assert_classname(f,g));

% ----- Handle the first boundary using periodic boundary conditions. ---
for n=0:ceil(glh/a)-1

    % Periodic boundary condition.
    fpart=[f(L-(glh-n*a)+1:L,:);...
           f(1:gl-(glh-n*a),:)];
    
    fg=bsxfun(@times,fpart,g);
    
    % Do the sum (decimation in frequency, Poisson summation)
    coef(:,n+1,:)=sum(reshape(fg,M,gl/M,W),2);
      
end;

% ----- Handle the middle case. ---------------------
for n=ceil(glh/a):floor((L-ceil(gl/2))/a)
  
  fg=bsxfun(@times,f(n*a-glh+1:n*a-glh+gl,:),g);
  
  % Do the sum (decimation in frequency, Poisson summation)
  coef(:,n+1,:)=sum(reshape(fg,M,gl/M,W),2);
end;

% ----- Handle the last boundary using periodic boundary conditions. ---
for n=floor((L-ceil(gl/2))/a)+1:N-1

    % Periodic boundary condition.
    fpart=[f((n*a-glh)+1:L,:);... %   L-n*a+glh elements
           f(1:n*a-glh+gl-L,:)];  %  gl-L+n*a-glh elements      
    
    fg=bsxfun(@times,fpart,g);
    
    % Do the sum (decimation in frequency, Poisson summation)
    coef(:,n+1,:)=sum(reshape(fg,M,gl/M,W),2);      
end;

% --- Shift back again to make it a frequency-invariant system. ---
for n=0:N-1
  coef(:,n+1,:)=circshift(coef(:,n+1,:),n*a-glh);
end;


coef=fft(coef);



% Simple code using a lot of circshifts.
% Move f initially so it lines up with the initial fftshift of the
% window
%f=circshift(f,glh);
%for n=0:N-1
  % Do the inner product.
  %fg=circshift(f,-n*a)(1:gl,:).*gw;
  
  % Periodize it.
  %fpp=zeros(M,W);
  %for ii=0:gl/M-1
    %  fpp=fpp+fg(ii*M+1:(ii+1)*M,:);
    %end;
%  fpp=sum(reshape(fg,M,gl/M,W),2);
  
  % Shift back again.
%  coef(:,n+1,:)=circshift(fpp,n*a-glh); %),M,1,W);
  
%end;





