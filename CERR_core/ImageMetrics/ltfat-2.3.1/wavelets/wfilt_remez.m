function [h,g,a,info]=wfilt_remez(L,K,B)
%-*- texinfo -*-
%@deftypefn {Function} wfilt_remez
%@verbatim
%WFILT_REMEZ Filters designed using Remez exchange algorithm
%   Usage: [h,g,a]=wfilt_remez(L,K,B)
%
%   Input parameters:
%         L     : Length of the filters.
%         K     : Degree of flatness (regularity) at z=-1. 
%         B     : Normalized transition bandwidth.
%
%   [h,g,a]=WFILT_REMEZ(L,K,B) calculates a set of wavelet filters. 
%   Regularity, frequency selectivity, and length of the filters can be
%   controlled by K, B and L parameters respectivelly.
%
%   The filter desigh algorithm is based on a Remez algorithm and a 
%   factorization of the complex cepstrum of the polynomial.
%
%   Examples:
%   ---------
%   :
%
%     wfiltinfo('remez50:2:0.1');
%
%   References:
%     O. Rioul and P. Duhamel. A remez exchange algorithm for orthonormal
%     wavelets. Circuits and Systems II: Analog and Digital Signal
%     Processing, IEEE Transactions on, 41(8):550 --560, aug 1994.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfilt_remez.html}
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

% Original copyright goes to:
% Copyright (C) 1994, 1995, 1996, by Universidad de Vigo 
% Author: Jose Martin Garcia
% e-mail: Uvi_Wave@tsc.uvigo.es

if(nargin<3)
     error('%s: Too few input parameters.',upper(mfilename)); 
end

complainif_notposint(L,'L',mfilename);
complainif_notposint(L,'K',mfilename);

if B>0.2
    error(['%s: Bandwidth of the transition band should not be',...
           ' bigger than 0.2.'],upper(mfilename));
end

poly=remezwav(L,K,B);
rh=fc_cceps(poly);

g{1} = flipud(rh(:));
g{2} = -(-1).^(1:length(rh)).'.*flipud(g{1});

% Default offset
d = [0,0];
  % Do a filter alignment according to "center of gravity"
  d(1) = -floor(sum((1:L)'.*abs(g{1}).^2)/sum(abs(g{1}).^2));
  d(2) = -floor(sum((1:L)'.*abs(g{2}).^2)/sum(abs(g{2}).^2));
  if rem(d(1)-d(2),2)==1
      % Shift d(2) just a bit
      d(2) = d(2) + 1;
  end


g = cellfun(@(gEl,dEl) struct('h',gEl,'offset',dEl),g,num2cell(d),...
            'UniformOutput',0);
h = g;

a= [2;2];
info.istight = 1;

function [p,r]=remezwav(L,K,B)

%REMEZWAV    P=REMEZWAV(L,K,B) gives impulse response of maximally
%	     frequency selective P(z), product filter of paraunitary
%	     filter bank solution H(z) of length L satisfying K flatness
%	     constraints (wavelet filter), with normalized transition
%	     bandwidth B (optional argument if K==L/2).
% 
%	     [P,R]=REMEZWAV(L,K,B) also gives the roots of P(z) which can
%	     be used to determine H(z).
%
%	     See also: REMEZFLT, FC_CCEPS.
%
%	     References: O. Rioul and P. Duhamel, "A Remez Exchange Algorithm
%			 for Orthonormal Wavelets", IEEE Trans. Circuits and
%			 Systems - II: Analog and Digital Signal Processing,
%			 41(8), August 1994
%                                                                          
%       Author: Olivier Rioul, Nov. 1, 1992 (taken from the
%		above reference)
%  Modified by: Jose Martin Garcia
%       e-mail: Uvi_Wave@tsc.uvigo.es
%--------------------------------------------------------


computeroots=(nargout>1);

%%%%%%%%%%%%%%%%%%%%%%%%%% STEP 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%
if rem(L,2), error('L must be even'); end
if rem(L/2-K,2), K=K+1; end
N=L/2-K;
%%%%%%%%%%%%%%%%%%%%%%%%%% STEP 2  %%%%%%%%%%%%%%%%%%%%%%%%%%
% Daubechies solution
% PK(z)=z^(-2K-1))+AK(z^2)
if K==0, AK=0;
else
   binom=pascal(2*K,1);
   AK=binom(2*K,1:K)./(2*K-1:-2:1);
   AK=[AK AK(K:-1:1)];
   AK=AK/sum(AK);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%% STEP 2' %%%%%%%%%%%%%%%%%%%%%%%%%%%
% Daubechies factor
% PK(z)=((1+z^(-1))/2)^2*K QK(z)
if computeroots && K>0
   QK=binom(2*K,1:K);
   QK=QK.*abs(QK);
   QK=cumsum(QK);
   QK=QK./abs(binom(2*K-1,1:K));
   QK=[QK QK(K-1:-1:1)];
   QK=QK/sum(QK)*2;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%% STEP 3 %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% output Daubechies solution PK(z)
if K==L/2
   p=zeros(1,2*L-1);
   p(1:2:2*L-1)=AK; p(L)=1;
   if computeroots
      r=[roots(QK); -ones(L,1)];
   end
   return
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% STEP 4 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Daubechies polinomial
% PK(x)=1+x*DK(x^2)
if K==0, DK=0;
else
   binom=pascal(K,1);
   binom=binom(K,:);
   DK=binom./(1:2:2*K-1);
   DK=fliplr(DK)/sum(DK);
end

wp=(1/2-B)*pi;  % cut-off frequency
gridens=16*(N+1);  % grid density
found=0;  % boolean for Remez loop

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% STEP I %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initial estimate of yk
a=min(4,K)/10;
yk=linspace(0,1-a,N+1);
yk=(yk.^2).*(3+a-(2+a)*yk);
yk=1-(1-yk)*(1-cos(wp)^2);
ykold=yk;

iter=0;
while 1  % REMEZ LOOP
iter=iter+1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% STEP II %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute delta
Wyk=sqrt(yk).*((1-yk).^K);
Dyk=(1-sqrt(yk).*polyval(DK,yk))./Wyk;
for k=1:N+1
   dy=yk-yk(k); dy(k)=[];
   dy=dy(1:N/2).*dy(N:-1:N/2+1);
   Lk(k)=prod(dy);
end
invW(1:2:N+1)=2./Wyk(1:2:N+1);
delta=sum(Dyk./Lk)/sum(invW./Lk);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% STEP III %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute R(y) on fine grid
Ryk=Dyk-delta.*invW; Ryk(N+1)=[];
Lk=(yk(1:N)-yk(N+1))./Lk(1:N);
y=linspace(cos(wp)^2,1-K*1e-7,gridens);
yy=ones(N,1)*y-yk(1:N)'*ones(1,gridens);
% yy contain y-yk on each line
ind=find(yy==0);  % avoid division by 0
if ~isempty(ind)
   yy(ind)=1e-30*ones(size(ind));
end
yy=1./yy;
Ry=((Ryk.*Lk)*yy)./(Lk*yy);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% STEP IV %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% find next yk
Ey=1-delta-sqrt(y).*(polyval(DK,y)+((1-y).^K).*Ry);
k=find(abs(diff(sign(diff(Ey))))==2)+1;
% N extrema
if length(k)>N
% may happen if L and K are large 
   k=k(1:N);
end
yk=[yk(1) y(k)];
% N+1 extrema including wp
if K==0, yk=[yk 1]; end
% extrema at y==1 added
if all(yk==ykold), break; end
ykold=yk;

end  % REMEZ LOOP

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  STEP A %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute impulse response
w=(0:2*N-2)*pi/(2*N-1);
y=cos(w).^2;
yy=ones(N,1)*y-yk(1:N)'*ones(1,2*N-1);
ind=find(yy==0);
if ~isempty(ind)
   yy(ind)=1e-30*ones(size(ind));
end
yy=1./yy;
Ry=((Ryk.*Lk)*yy)./(Lk*yy);
Ry(2:2:2*N-2)=-Ry(2:2:2*N-2);
r=Ry*cos(w'*(2*(0:N-1)+1));
% partial real IDFT done
r=r/(2*N-1);
r=[r r(N-1:-1:1)];
p1=[r 0]+[0 r];
pp=p1;  % save p1 for later use
for k=1:2*K
   p1=[p1 0]-[0 p1];
end
if rem(K,2), p1=-p1; end
p1=p1/2^(2*K+1);
p1(N+1:N+2*K)=p1(N+1:N+2*K)+AK;
% add Daubechies response:
p(1:2:2*L-1)=p1; p(L)=1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% STEP A' %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute roots
if computeroots
   Q(1:2:2*length(pp)-1)=pp;
   for k=1:2*K
     Q=[Q 0]-[0 Q];
   end
   if rem(K,2), Q=-Q; end
   Q=Q/2;
   if K>0  % add Daubechies factor QK
      Q(2*N+1:L-1)=Q(2*N+1:L-1)+QK;
   else
      Q(L)=1;
   end
   r=[roots(Q); -ones(2*K,1)];
end



function  h=fc_cceps(poly,ro)

%FC_CCEPS    Performs a factorization using complex cepstrum.
%
%	     H = FC_CCEPS (POLY,RO) provides H that is the spectral
%	     factor of a FIR transfer function POLY(z) with non-negative 
%	     frequency response. This methode let us obtain lowpass
%	     filters of a bank structure without finding the POLY zeros.
%	     The filter obtained is minimum phase (all zeros are inside
%	     unit circle).
%		
%	     RO is a parameter used to move zeros out of unit circle.
%	     It is optional and the default value is RO=1.02.
%
%	     See also: INVCCEPS, MYCCEPS, REMEZWAV.
%
%	     References: P.P Vaidyanathan, "Multirate Systems and Filter
%			 Banks", pp. 849-857, Prentice-Hall, 1993


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
%       Author: Jose Martin Garcia
%       e-mail: Uvi_Wave@tsc.uvigo.es
%--------------------------------------------------------

if nargin < 2
	ro=1.02;
end

L=4096;   % number points of fft.

N=(length(poly)-1)/2;

%% Moving zeros out of unit circle
roo=(ro).^[0:2*N];
g=poly./roo;

%% Calculate complex cepstrum of secuence g
ghat=mycceps(g,L);

%% Fold the anticausal part of ghat, add it to the causal part and divide by 2
gcausal=ghat(1 : L/2);
gaux1=ghat(L/2+1 : L);
gaux2=gaux1(L/2 :-1: 1);
gantic=[0 gaux2(1 : L/2-1)];

xhat=0.5*(gcausal+gantic);

%% Calculate cepstral inversion
h=invcceps(xhat,N+1);
 
%% Low-pass filter has energie sqrt(2)
h=h*sqrt(2)/sum(h);


function  x=invcceps(xhat,L)

%INVCCEPS    Complex cepstrum Inversion
%
%	     X= INVCCEPS (CX,L) recovers X from its complex cepstrum sequence 
%	     CX. X has to be real, causal, and stable (X(z) has no zeros  
%	     outside unit circle) and x(0)>0. L is the length of the 
%	     recovered secuence.
%
%	     See also: MYCCEPS, FC_CCEPS, REMEZWAV.
%
%	     References: P.P Vaidyanathan, "Multirate Systems and Filter
%			 Banks", pp. 849-857, Prentice-Hall, 1993


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
%       Author: Jose Martin Garcia
%       e-mail: Uvi_Wave@tsc.uvigo.es
%--------------------------------------------------------


x=zeros(1,L);

%% First point of x
x(1)=exp(xhat(1));

%% Recursion to obtain the other point of x
for muestra=1:L-1
   for k=1:muestra
	x(muestra+1)=x(muestra+1)+k/muestra*xhat(k+1)*x(muestra-k+1);
   end
end


function xhat=mycceps(x,L)

%MYCCEPS     Complex Cepstrum
%
%	     CX = MYCCEPS (X,L) calculates complex cepstrum of the
%	     real sequence X. L is the number of points of the fft
%	     used. L is optional and its default value is 1024 points.
%
%	     See also: FC_CEPS, INVCCEPS, REMEZWAV.


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
%       Author: Jose Martin Garcia
%       e-mail: Uvi_Wave@tsc.uvigo.es
%--------------------------------------------------------

if nargin < 2
   L=1024;
end

H = fft(x,L);

%% H must not be zero
ind=find(abs(H)==0);
if length(ind) > 0 
   H(ind)=H(ind)+1e-25;
end

logH = log(abs(H))+sqrt(-1)*rcunwrap(angle(H));

xhat = real(ifft(logH));


function y = rcunwrap(x)
%RCUNWRAP Phase unwrap utility used by CCEPS.
%	RCUNWRAP(X) unwraps the phase and removes phase corresponding
%	to integer lag.  See also: UNWRAP, CCEPS.

%	Author(s): L. Shure, 1988
%		   L. Shure and help from PL, 3-30-92, revised
%	Copyright (c) 1984-94 by The MathWorks, Inc.
%       $Revision: 1.4 $  $Date: 1994/01/25 17:59:42 $

n = max(size(x));
y = unwrap(x);
nh = fix((n+1)/2);
y(:) = y(:)' - pi*round(y(nh+1)/pi)*(0:(n-1))/nh;






