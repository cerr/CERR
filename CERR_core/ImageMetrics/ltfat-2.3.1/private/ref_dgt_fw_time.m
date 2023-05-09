function cout=ref_dgt_fw_time(f,gf,a,M)
%-*- texinfo -*-
%@deftypefn {Function} ref_dgt_fw_time
%@verbatim
%COMP_DGT_FW  Full-window factorization of a Gabor matrix.
%   Usage:  c=comp_dgt_fw(f,gf,a,M);
%
%   This should be an exact copy of the comp_dgt_fw.m file in the comp/
%   subdirectory in the toolbox. It is intended for timing when the original
%   file is masked by an oct/mex implementation. 
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_dgt_fw_time.html}
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

debug=0;
if debug
  tic;
end;

L=size(f,1);
W=size(f,2);
LR=prod(size(gf));
R=LR/L;

N=L/a;
b=L/M;

[c,h_a,h_m]=gcd(a,M);
h_a=-h_a;
p=a/c;
q=M/c;
d=N/q;

ff=zeros(p,q*W,c,d);

if debug
  disp('Initialization done');
  a
  M
  L
  W
  toc; tic;
end;

if p==1
  % --- integer oversampling ---

  if (c==1) && (d==1) && (W==1) && (R==1)
    % --- Short time Fourier transform of single signal ---
    % This is used for spectrograms of short signals.      
      ff(1,:,1,1)=f(:);
  else
    for s=0:d-1
      for r=0:c-1    
	for l=0:q-1
	  ff(1,l+1:q:W*q,r+1,s+1)=f(r+s*M+l*c+1,:);
	end;
      end;
    end;    
  end;

else
  % --- rational oversampling ---
  % Set up the small matrices
  % The r-loop (runs up to c) has been vectorized
  for w=0:W-1
    for s=0:d-1
      for l=0:q-1
	for k=0:p-1	    	  
	  ff(k+1,l+1+w*q,:,s+1)=f((1:c)+mod(k*M+s*p*M-l*h_a*a,L),w+1);
	end;
      end;
    end;
  end;
end;

if debug
  disp('First FAC done.');
  toc; tic;
end;

% This version uses matrix-vector products and ffts

% fft them
if d>1
  ff=fft(ff,[],4);
end;

if debug
  disp('FFT done');
  toc; tic;
end;

C=zeros(q*R,q*W,c,d);

for r=0:c-1    
  for s=0:d-1
    GM=reshape(gf(:,r+s*c+1),p,q*R);
    FM=reshape(ff(:,:,r+1,s+1),p,q*W);
    
    C(:,:,r+1,s+1)=GM'*FM;
  end;
end;

if debug
  disp('MatMul done');
  toc; tic;
end;

% Inverse fft
if d>1
  C=ifft(C,[],4);
end;

if debug
  disp('IFFT done');
  toc; tic;
end;

% Place the result

cout=zeros(M,N,R,W);

if p==1
  % --- integer oversampling ---

  if (c==1) && (d==1) && (W==1) && (R==1)
    
    % --- Short time Fourier transform of single signal ---
    % This is used for spectrograms of short signals.      
    for l=0:q-1
      cout(l+1,mod((0:q-1)+l,N)+1,1,1)=C(:,l+1,1,1);
    end;
    
  else

    % The r-loop (runs up to c) has been vectorized
    for rw=0:R-1
      for w=0:W-1    
	for s=0:d-1
	  for l=0:q-1
	    for u=0:q-1
	      cout((1:c)+l*c,mod(u+s*q+l,N)+1,rw+1,w+1)=C(u+1+rw*q,l+1+w*q,:,s+1);
	    end;
	  end;
	end;
      end; 
    end;
  end;

else

  % Rational oversampling
  % The r-loop (runs up to c) has been vectorized
  for rw=0:R-1
    for w=0:W-1    
      for s=0:d-1
	for l=0:q-1
	  for u=0:q-1
	    cout((1:c)+l*c,mod(u+s*q-l*h_a,N)+1,rw+1,w+1)=C(u+1+rw*q,l+1+w*q,:,s+1);
	  end;
	end;
      end;
    end; 
  end;

end;

if debug
  disp('Last FAC done');
  toc; tic;
end;

cout=reshape(cout,M,N*W*R);


function r=mymod(x,y)
  r=x-y*floor(x/y);




