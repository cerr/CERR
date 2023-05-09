function [coef]=ref_dgt_fb(f,g,a,M)
%-*- texinfo -*-
%@deftypefn {Function} ref_dgt_fb
%@verbatim
%REF_DGT_FB  Filter bank DGT
%   Usage:  c=ref_dgt_fb(f,g,a,M);
%  
%   This should be an exact copy of comp_dgt_fb to serve for testing
%   the oct/mex routines and for timings.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_dgt_fb.html}
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

%   Author : Peter L. Soendergaard.

% Calculate the parameters that was not specified.
L=size(f,1);
b=L/M;
N=L/a;
gl=length(g);
W=size(f,2);      % Number of columns to apply the transform to.
glh=floor(gl/2);  % gl-half


% Conjugate the window here.
g=conj(fftshift(g));

coef=zeros(M,N,W);

% Replicate g when multiple columns should be transformed.
gw=repmat(g,1,W);

% ----- Handle the first boundary using periodic boundary conditions. ---
for n=0:ceil(glh/a)-1 
  %disp(["ref: begin: ",num2str(n)]);

  % This code does the same using a circshift. It will also work for
  % the last boundary part.
  %fpart=circshift(f,glh-n*a);
  %fg=fpart(1:gl,:).*gw;

  fpart=[f(L-(glh-n*a)+1:L,:);...
	 f(1:gl-(glh-n*a),:)];

  fg=fpart.*gw;
  
  % Do the sum (decimation in frequency, Poisson summation)
  coef(:,n+1,:)=sum(reshape(fg,M,gl/M,W),2);
      
  % Make it frequency invariant
  coef(:,n+1,:)=circshift(coef(:,n+1,:),n*a-glh);

end;

% ----- Handle the middle case. ---------------------
for n=ceil(glh/a):floor((L-ceil(gl/2))/a) 
  %disp(["ref: middle: ",num2str(n)]);

  fg=f(n*a-glh+1:n*a-glh+gl,:).*gw;
  
  % Do the sum (decimation in frequency, Poisson summation)
  coef(:,n+1,:)=sum(reshape(fg,M,gl/M,W),2);

  coef(:,n+1,:)=circshift(coef(:,n+1,:),n*a-glh);
end;

% ----- Handle the last boundary using periodic boundary conditions. ---
for n=floor((L-ceil(gl/2))/a)+1:N-1
  %disp(["ref: end: ",num2str(n)]);

  fpart=[f((n*a-glh)+1:L,:);... %   L-n*a+glh) elements
	 f(1:n*a-glh+gl-L,:)];  %  gl-L+n*a-glh elements
  fg=fpart.*gw;
  
  % Do the sum (decimation in frequency, Poisson summation)
  coef(:,n+1,:)=sum(reshape(fg,M,gl/M,W),2);      

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





