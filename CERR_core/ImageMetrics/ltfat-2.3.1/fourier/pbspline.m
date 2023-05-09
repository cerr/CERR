function [g,nlen] = pbspline(L,order,a,varargin)
%-*- texinfo -*-
%@deftypefn {Function} pbspline
%@verbatim
%PBSPLINE   Periodized B-spline
%   Usage:   g=pbspline(L,order,a,...);
%            [g,nlen]=pbspline(L,order,a,...);
%
%   Input parameters:
%         L      : Length of window.
%         order  : Order of B-spline.
%         a      : Time-shift parameter for partition of unity.
%   Output parameters:
%         g      : Fractional B-spline.
%         nlen   : Number of non-zero elements in out.
%
%   PBSPLINE(L,order,a) computes a (slightly modified) B-spline of order
%   order of total length L.
%
%   If shifted by the distance a, the returned function will form a
%   partition of unity. The result is normalized such that the functions sum
%   to 1/sqrt(a).
%
%   PBSPLINE takes the following flags at the end of the input arguments:
%
%     'ed'     Even discrete fractional spline. This is the default
%
%     'xd'     'flat' discrete fractional spline.
%
%     'stard'  'pointy' discrete fractional spline
%
%     'ec'     Even fractional spline by sampling.
%
%     'xc'     'flat' fractional spline by sampling.
%
%     'starc'  'pointy' fractional spline by sampling.
%
%     'wp'     Generate whole point centered splines. This is the default.
%
%     'hp'     Generate half point centered splines.
%
%   The different types are accurately described in the referenced paper.
%   Generally, the 'd' types of splines are very fast to compute, while
%   the 'c' types are samplings of the continuous splines. The 'e' types
%   coincides with the regular B-splines for integer orders. The 'x' types
%   do not coincide, but generate Gabor frames with favorable frame
%   bounds. The default type is 'ed' to guarantee fast computation and a
%   familiar shape of the splines.
%
%   [out,nlen]=PBSPLINE(...) will additionally compute the number of
%   non-zero elements in out.
%
%   If nlen = L, the function returned will be a periodization of a
%   B-spline.
%
%   If nlen < L, you can choose to remove the additional zeros by calling
%   g=middlepad(g,nlen).
%
%   Additionally, PBSPLINE accepts flags to normalize the output. Please
%   see the help of NORMALIZE. Default is to use 'peak' normalization.
%
%
%
%   References:
%     P. L. Soendergaard. Symmetric, discrete fractional splines and Gabor
%     systems. preprint, 2008.
%     
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/pbspline.html}
%@seealso{pgauss, firwin, middlepad, normalize, demo_pbspline}
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
%   TESTING: TEST_PBSPLINE
%   REFERENCE: OK

% FIXME: In some very special cases, a spline that should be compactly
% supported is not. See this output from test_pbspline
%   PBSPLINE NLEN ec HPE L: 15 a:  3 o:  3 0.00063001 FAILED
%   PBSPLINE NLEN starc HPE L: 15 a:  3 o:  3 0.00063001 FAILED
  
%  --------- checking of input parameters ---------------

  if nargin<3
    error('Too few input arguments.');
  end;

  if prod(size(L))~=1
    error('L must be a scalar');
  end;
  
  if rem(L,1)~=0
    error('L must be an integer.')
  end;
  
  if prod(size(L))~=1
    error('a must be a scalar');
  end;
  
  if rem(a,1)~=0
    error('a must be an integer.')
  end;
  
  if size(a,1)>1 || size(a,2)>1
    error('order must be a scalar');
  end;
    
  % Define initial value for flags and key/value pairs.
  definput.import={'normalize'};
  definput.importdefaults={'inf'};
  definput.flags.centering={'wp','hp'};
  definput.flags.stype={'ed','xd','stard','ec','xc','starc'};
  
[flags,keyvals]=ltfatarghelper({},definput,varargin);


  
dodisc=1;
splinetype=3;
switch(lower(flags.stype))
  %case {'+d'}
  %  dodisc=1;
  %  splinetype=0;
  case {'stard'}
    dodisc=1;
    splinetype=1;
  case {'xd'}
    dodisc=1;
    splinetype=2;
  case {'ed'}
    dodisc=1;
    splinetype=3;
  %case {'+c'}
  %  dodisc=0;
  %  splinetype=0;
  case {'starc'}
    dodisc=0;
    splinetype=1;
  case {'xc'}
    dodisc=0;
    splinetype=2;
  case {'ec'}
    dodisc=0;
    splinetype=3;
end;


% --------  compute the function --------------

N=L/a;

if dodisc

  if flags.do_wp
    if order<=-1
      error('Order must be larger than -1 for this type of spline.');
    end;
  else
    if order<0
      error('Order must be larger than or equal to zero for this type of spline.');
    end;  
  end;

  % -------- compute the discrete fractional splines -----------
  
  % Constuct a rectangular function in the odd case,
  % and a rectangular function with 0.5 in both ends
  % in the even case. This is always WPE
  s1=middlepad(ones(a,1),L);

  switch splinetype
      
    %case 0
      % Asymmeteric spline
      
      % If a=3,7,11,... then the Nyquist frequency will have a negative
      % coefficient, and generate a complex spline. 
	
    %  if cent==0
	
    %	g = real(ifft(fft(s1).^(order+1)));
	
    %  else
    %	s2=middlepad([ones(a,1)],L,'hp');
    %	g = real(ifft(fft(s1).^order.*fft(s2)));
	
    %  end;
	
    case 1
      
      % Unsers symmetric spline (signed power)

      if flags.do_wp
	g = real(ifft(abs(fft(s1)).^(order+1)));
      else

	% Producing the unsigned power spline of order zero is slightly
	% complicated in this case.
        s2=middlepad([ones(a,1)],L,'hp');
	
	l=(0:L-1).';
	minv=exp(-pi*i*l/L);
	m=exp(pi*i*l/L);
	
	h1=fft(s2).*minv;
	h3=[abs(h1(1:floor(L/2)+1));...
	    -abs(h1(floor(L/2)+2:L))];
	%h5=real(ifft(h3.*m));
	
	gf=abs(fft(s1)).^order.*h3;
	g = ifft(gf.*m);
	g=real(g);
        
      end;
    
    case 2

      % unsigned power spline.
      
      if flags.do_wp
	
	% We must remove the zero imaginary part from s, otherwise
	% it will confuse the sign function.
	s=real(fft(s1));
	g = real(ifft(sign(s).*abs(s).^(order+1)));
      else
	s2=middlepad([ones(a,1)],L,'hp');
	g = real(ifft(abs(fft(s1)).^order.*fft(s2)));
      end;

    case 3

      % even spline

      if flags.do_wp
	g = ifftreal(real(fftreal(s1)).^(order+1),L);
      else
	s2=middlepad([ones(a,1)],L,'hp');
	g=real(ifft(real(fft(s1).^order).*fft(s2)));

      end;
      
  end

  % Scale such that the elements will form a partition of unity.
  g=g./a.^order;

  % Normalize
  %g=g/sqrt(a);


else

  % -------- compute the sampled and periodized continuous splines -------

  if order<0
    error('Order must be larger than or equal to zero for this type of spline.');
  end;

  if flags.do_hp

    % Handle all HPE splines by subsampling the WPE spline of double the size
    % and double a.
    g=pbspline(2*L,order,2*a,flags.stype);
    g=sqrt(2)*g(2:2:2*L);

  else

    % Check for order 0
    if order==0
      if splinetype==1
	error('The zero-th order spline of type starc cannot be sampled and periodized.');
      else
	% Compute it explicitly.
	g=middlepad(ones(a,1),L)/sqrt(a);
	
      end;
    else 
      
      
      gf=zeros(L,1);
      switch splinetype
	  
	%case 0
	  
	%  % Asymmetric spline

	%  if rem(a,2)==0

	%    wt1=(-1)^(-order-1);
	%    for m=1:L/2
	%      z1=myhzeta(order+1,1-m/L);
	%      z2=myhzeta(order+1,m/L);
	%      s=sin(pi*m/N)^(order+1);	      
	%      gf(m+1)=(sin(pi*m/N)/(pi*a)).^(order+1)*(wt1*z1+z2);
	%    end;    
	%  else
	    
	%    wt1=(-1)^(-order-1);
	%    wt2=(-1)^(order+1);
	%    for m=1:L/2
	      
	%      z1=wt1*myhzeta(order+1, 1 - m/(2*L));
	%      z2=    myhzeta(order+1,     m/(2*L));
	%      z3=    myhzeta(order+1,.5 - m/(2*L));
	%      z4=wt2*myhzeta(order+1,.5 + m/(2*L));
	%      gf(m+1)=(sin(pi*m/N)/(2*pi*a)).^(order+1)*(z1+z2+z3+z4);
	%    end;
	%  end;
	  
	case 1
	  % Unsers symmetric spline (unsigned power)
	  for m=1:L/2
	    gf(m+1)=(abs(sin(pi*m/N)/(pi*a))).^(order+1)*(myhzeta(order+1,1-m/L)+myhzeta(order+1,m/L));	    
	  end;    
	
	case 2      
	  % Signed power spline

	  if rem(a,2)==0
	    for m=1:L/2
	      gf(m+1)=(sin(pi*m/N)*abs(sin(pi*m/N)).^order)*(-myhzeta(order+1,1-m/L)+myhzeta(order+1,m/L));	    
	    end;    
	    % Scale
	    gf=gf/((pi*a).^(order+1));
	  
	  else
	    for m=1:L/2	      
	      z1=-myhzeta(order+1,1-m/(2*L));
	      z2=myhzeta(order+1,m/(2*L));
	      z3=myhzeta(order+1,.5-m/(2*L));
	      z4=-myhzeta(order+1,.5+m/(2*L));	      	      
	      gf(m+1)=(sin(pi*m/N)*abs(sin(pi*m/N)).^order)*(z1+z2+z3+z4);	    
	    end;   
	    % Scale
	    gf=gf/((2*pi*a).^(order+1));
	  
	  end;
          
	case 3

	  % Real part spline.
	  if rem(a,2)==0
  
	    wt1=(-1)^(-order-1);

	    for m=1:L/2

	      z1=myhzeta(order+1,1-m/L);
	      z2=myhzeta(order+1,m/L);
	      s=sin(pi*m/N)^(order+1);	      
	      gf(m+1)=real((sin(pi*m/N)/(pi*a)).^(order+1)*(wt1*z1+z2));
	    end;    
	  else

	  wt1=(-1)^(-order-1);
	  wt2=(-1)^(order+1);
	  
	  for m=1:L/2
	    	    
	    z1=wt1*myhzeta(order+1,1-m/(2*L));
	    z2=myhzeta(order+1,m/(2*L));
	    z3=myhzeta(order+1,.5-m/(2*L));
	    z4=wt2*myhzeta(order+1,.5+m/(2*L));
	    gf(m+1)=real((sin(pi*m/N)/(2*pi*a)).^(order+1)*(z1+z2+z3+z4));
	    
	  end;
          
	end;
      end;

      gf(1)=1;
      
      % This makes it even by construction!
      gf(floor(L/2)+2:L)=conj(flipud(gf(2:ceil(L/2))));      
      g=real(ifft(gf));
          
      % Normalize it correctly.
      g=g*sqrt(a);

    end; % order < 0
    
  end;


end;

% Calculate the length of the spline
% If order is a fraction then nlen==L
if rem(order,1)~=0
  nlen=L;
else
  if flags.do_wp

    if dodisc          
      if rem(a,2)==0  
	nlen=a*(order+1)+1;
      else
	nlen=(a-1)*(order+1)+1;
      end;      
    else      
      if rem(a,2)==0  
	nlen=a*(order+1)-1;
      else
	nlen=(a-1)*(order+1)+3;
      end;
    end;      
  else
    aeven=floor(a/2)*2;
    if dodisc          
      if rem(a,2)==0  
	nlen=aeven*(order+1);
      else
	nlen=aeven*(order+1)+2;
      end;      
    else      
      if rem(a,2)==0  
	nlen=aeven*(order+1);
      else
	nlen=aeven*(order+1)+2;
      end;            
    end;      

    
  end;     

  if (((splinetype==1) && (rem(order,2)==0)) || ...
      ((splinetype==2) && (rem(order,2)==1)))
    % The unsigned/signed power splines generate infinitely
    % supported splines in these cases
    nlen=L;
  end;

end;



% nlen cannot be larger that L
nlen=min(L,nlen);

g=normalize(g,flags.norm);

function Z=myhzeta(z,v);
  

  if isoctave
    
    Z=hzeta(z,v);
    
  else
    
    % Matlab does not have a true zeta function. Instead it calls Maple.
    % Unfortunately, the zeta function it Matlab does not provide access
    % to the full functionality of the Maple zeta function, so we need
    % to call it directly.
    % The following line assures that numbers are converted at full
    % precision, and that we avoid a lot of overhead in converting
    % double -> sym -> char


    %expr1 = maple('Zeta',sym(0),sym(z),sym(v));    
    %Z=double(maple('evalf',expr1));

    out=maplemex(['Zeta(0,',num2str(z,16),',',num2str(v,16),');']);
    Z=double(sym(out));

    if isempty(Z)
      error(['Zeta ERROR: ',out]);
    end;

  end;


