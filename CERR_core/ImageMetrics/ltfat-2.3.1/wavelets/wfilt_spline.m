function [h,g,a,info]=wfilt_spline(m,n)
%-*- texinfo -*-
%@deftypefn {Function} wfilt_spline
%@verbatim
% WFILT_SPLINE  Biorthogonal spline wavelets
%   Usage: [h,g,a]=wfilt_spline(m,n);
%
%   Input parameters:
%         m     : Number of zeros at z=-1 of the lowpass filter in g{1}
%         n     : Number of zeros at z=-1 of the lowpass filter in h{1}
%
%   [h,g,a]=WFILT_SPLINE(m,n) with m+n being even returns biorthogonal
%   spline wavelet filters.  
%
%   Examples:
%   ---------
%   :
%     wfiltinfo('ana:spline4:2');
%
%   :
%     wfiltinfo('syn:spline4:2');
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfilt_spline.html}
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

%   Original copyright goes to:
%   Copyright (C) 1994, 1995, 1996, by Universidad de Vigo 
%   Author: Jose Martin Garcia
%   e-mail: Uvi_Wave@tsc.uvigo.es

if(nargin<2)
     error('%s: Too few input parameters.',upper(mfilename)); 
end

if(rem(m+n,2)~=0)
    error('%s: M+N must be even.',upper(mfilename)); 
end

if m==1 && n==1
   [h,g,a,info]=wfilt_db(1); 
   return;
end

% Calculate rh coefficients, RH(z)=sqrt(2)*((1+z^-1)/2)^m;

rh=sqrt(2)*(1/2)^m*binewton(m);

% Calculate h coefficients, H(-z)=sqrt(2)*((1+z^-1)/2)^n*P(z)

% First calculate P(z) (pol)

if (rem(n,2)==0)
   N=n/2+m/2;
else
   N=(n+m-2)/2+1;
end

pol=trigpol(N);

% Now calculate ((1+z*-1)/2)^n;

r0=(1/2)^n*binewton(n);


hrev=sqrt(2)*conv(r0,pol);

l=length(hrev);
hh=hrev(l:-1:1);


[h{2}, g{2}]=calhpf(hh,rh);
h{1} = hh;
g{1} = rh;

if(length(h{1})>length(h{2}))
    if(rem(length(h{1}),2)~=1)
       r0 = (length(h{1})-length(h{2}))/2;
       l0 = r0;
    else
       r0 = (length(h{1})-length(h{2}))/2+1;
       l0 = (length(h{1})-length(h{2}))/2-1;
    end
      h{2} = [zeros(1,l0), h{2}, zeros(1,r0) ];
else
    if(rem(length(h{1}),2)~=1)
       r0 = (length(h{2})-length(h{1}))/2;
       l0 = r0;
    else
       r0 = (length(h{2})-length(h{1}))/2+1;
       l0 = (length(h{2})-length(h{1}))/2-1;
    end
      h{1} = [zeros(1,l0), h{1}, zeros(1,r0) ];
end

if(length(g{1})>length(g{2}))
    if(rem(length(g{1}),2)~=1)
       r0 = (length(g{1})-length(g{2}))/2;
       l0 = r0;
    else
       r0 = (length(g{1})-length(g{2}))/2+1;
       l0 = (length(g{1})-length(g{2}))/2-1;
    end
      g{2} = [zeros(1,l0), g{2}, zeros(1,r0) ];
else
    if(rem(length(g{1}),2)~=1)
       r0 = (length(g{2})-length(g{1}))/2;
       l0 = r0;
    else
       r0 = (length(g{2})-length(g{1}))/2+1;
       l0 = (length(g{2})-length(g{1}))/2-1;
    end
      g{1} = [zeros(1,l0), g{1}, zeros(1,r0) ];
end

% adding "the convenience" zero
if(rem(length(h{1}),2))
    h{1}= [0, h{1}];
    h{2}= [0, h{2}];
    g{1}= [0, g{1}];
    g{2}= [0, g{2}];
end


% Ajust the initial filter position
if rem(m,2)==1
   d = [-numel(h{1})/2, -numel(h{1})/2]; 
else
   d = [-numel(h{1})/2+1, -numel(h{1})/2-1];
end


g = cellfun(@(gEl,dEl) struct('h',gEl(:),'offset',dEl),g,num2cell(d),...
            'UniformOutput',0);
h = cellfun(@(hEl,dEl) struct('h',flipud(hEl(:)),'offset',dEl),h,num2cell(d),...
            'UniformOutput',0);
%h = cellfun(@(hEl) hEl(end:-1:1),h,'UniformOutput',0);
a= [2;2];
info.istight = 0;


function c=binewton(N)

% BINEWTON generate coefficients of Newton binomial.
%        
%          BINEWTON(N) generates the N+1 coefficients of
%          the Nth order Newton binomial.
%
%          See also: NUMCOMB   

%-------------------------------------------------------- 
% Copyright (C) 1994, 1995, 1996, by Universidad de Vigo 
%                                                      
%                                                      
% Uvi_Wave is free software; you can redistribute it and/or modify it      
% under the terms of the GNU General Public License as published by the    
% Free Software Foundation; either version 2, or (at your option) any      
% later version.                                                           
%                                                                          
% Uvi_Wave is distributed in the hope that it will be useful, but WITHOUT  
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or    
% FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License    
% for more details.                                                        
%                                                                          
% You should have received a copy of the GNU General Public License        
% along with Uvi_Wave; see the file COPYING.  If not, write to the Free    
% Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.             
%                                                                          
%       Author: Nuria Gonzalez Prelcic
%       e-mail: Uvi_Wave@tsc.uvigo.es
%--------------------------------------------------------

c=[1];
for j=1:N,
    c=[c,numcomb(N,j)];
end

function y=numcomb(n,k)

if n==k,
   y=1;
elseif k==0,
   y=1;
elseif k==1,
   y=n;
else 
   y=fact(n)/(fact(k)*fact(n-k));
end

function y=fact(x)

for j=1:length(x)
    if x(j)==0,
       y(j)=1;
    else
       y(j)=x(j)*fact(x(j)-1);
    end
end

function polinomio=trigpol(N)

coefs=zeros(N,2*N-1);
coefs(1,N)=1;

 
for i=1:N-1
	fila=[1 -2 1];
	for j=2:i
		fila=conv(fila,[1 -2 1]);
	end;
	fila=numcomb(N-1+i,i)*(-0.25)^i*fila;
	fila=[ zeros(1,(N-i-1))  fila zeros(1,(N-i-1))];
	coefs(i+1,:)=fila;
end

for i=0:(2*(N-1))
	polinomio(i+1)=0;
	for j=1:N
		polinomio(i+1)=polinomio(i+1)+coefs(j,i+1);
	end
end;


function [g,rg]=calhpf(h,rh)

% CALHPF   Obtain high pass analysis and synthesis filters 
%          in a biortoghonal filterbank.

lrh=length(rh);    

if (rem(lrh,2))   % rh has odd length 
   nrh=(lrh-1)/2; % Support [-nrh,nrh]            
else              % rh has even length
   nrh=lrh/2-1;     % Support [-nrh,nrh+1]
end 


if (rem(nrh,2))   % nrh is odd
   flag=1;
else              % nrh is even 
   flag=0;
end 

grev=chsign(rh(lrh:-1:1),flag);
g=grev(lrh:-1:1);


lh=length(h);

if (rem(lh,2))   % h has odd length 
   nh=(lh-1)/2; % Support [-nh,nh]
else              % h has even length
   nh=lh/2-1;     % Support [-nh,nh+1]
end

if (rem(nh,2))% nh is odd
      flag=1;
else
      flag=0;     % nh is even  
end

rg=chsign(h,flag);


function y=chsign(x,flag)
lx=length(x);
if (flag==1)
   y=(-1).^(1:lx).*x;
else
   y=-(-1).^(1:lx).*x;
end 




