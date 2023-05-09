function [out,nlen] = ref_pbspline(splinetype,L,order,a,centering)
%-*- texinfo -*-
%@deftypefn {Function} ref_pbspline
%@verbatim
%PBSPLINE   Periodized B-spline.
%   Usage:   out=pbspline(splinetype,L,order,a);
%            [out,nlen]=pbspline(splinetype,L,order,a);
%
%   Input parameters:
%         splinetype : type of spline
%         L     : Length of window.
%         order : Order of B-spline.
%         a     : Time-shift parameter for partition of unity.
%   Output parameters:
%         out   : Almost B-spline.
%         nlen  : Number of non-zero elements in out.
%
%
%   Types are:
%         0 - as pspline, real formed from DFT product
%         1 - forced even by taking ABS value of fft.
%         2 - New even
%         3 - computed from continous case
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_pbspline.html}
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

complainif_argnonotinrange(nargin,4,5,mfilename);

if nargin==4
  centering=0;
end;

% Matlab and Octave uses the following definition of a fractional
% power of a complex number. This is consistant with what Unser uses.
% zp=abs(z).^alpha.*exp(i*alpha*angle(z));

% This is always WPE
s1=middlepad([ones(a,1)],L);

nlen=0;

switch splinetype
    
  case 0
    % (Possibly) unsymmeteric spline
    
    % If a=3,7,11,... then the Nyquest frequency will have a negative
    % coefficient, and generate a complex spline. 

    if centering==0

      % Method 1
      out = real(ifft(fft(s1).^(order+1)));
      
      % Method 2
      % Create FFT of spline. Flip over top part, to make it strickly real.
      % This method is more robust against a bad FFT implementation.
      %sf=fft(s1).^(order+1);
      %if rem(L,2)==0
	%  sf(L/2+2:L)=conj(flipud(sf(2:L/2)));
	%else
	%	 sf((L+3)/2:L)=conj(flipud(sf(2:(L+1)/2)));
	%end;
      %sf(L/2+1)
      %out = real(ifft(sf));
      
    else
      s2=middlepad([ones(a,1)],L,.5);
      out = real(ifft(fft(s1).^order.*fft(s2)));
      
    end;
	
  case 1

    % Symmetric spline

    if centering==0
      out = real(ifft(abs(fft(s1)).^(order+1)));
    else
      s2=middlepad([ones(a,1)],L,.5);
      out = real(ifft(abs(fft(s1)).^order.*abs(fft(s2))));

    end;
    
  case 2

    % Mild symmetric

    intorder=floor(order);
    fracorder=order-intorder;

    if centering==0
      out = real(ifft(abs(fft(s1)).^order.*fft(s1)));
    else
      s2=middlepad([ones(a,1)],L,.5);
      out = real(ifft(abs(fft(s1)).^order.*fft(s2)));
    end;
      
    
  case 3
    
    Llong=ceil(a*(order+2)/L)*L;
    x=((0:Llong-1).')/a;
    
    x
    
    out=zeros(Llong,1);
    
    for k=0:order+1
      
      out=out+(-1)^k*ref_bincoeff(order+1,k)*onesidedpower(x-k,order);
      
      out
    end;
    out=out/factorial(order);
    
end;



% Scale such that the elements will form a partition of unity.
out=out./a.^order;

% nlen cannot be larger that L
nlen=min(L,nlen);

% If order is a fraction nlen==L
if rem(order,1)~=0
  nlen=L;
end;

if use_row_layout
  out=out.';
end;

% Normalize
out=out/sqrt(a);


% This code verifies that we have obtained a partition of unity.
%pu=zeros(L,1);
%for ii=0:L/a-1
%  pu=pu+circshift(out,a*ii);
%end;
%pu

% Verify middlepad claim
%norm(out-middlepad(middlepad(out,nlen),L))

  
function xa=onesidedpower(x,a)
  % Compute a one-sided power. See Unser and Blu "Fractional Spline and
  % Wavelets", section 1.1.2

  % Zero all negative values
  x=x.*(x>=0)
  
  % Raise
  xa=x.^a;
  



