function F=tfmat(ttype,p2,p3,p4,p5)
%-*- texinfo -*-
%@deftypefn {Function} tfmat
%@verbatim
%TFMAT Matrix of transform / operator
%   Usage:  F=tfmat('fourier',L);
%           F=tfmat('dcti',L);
%           F=tfmat('dgt',g,a,M);
%           F=tfmat('dwilt',g,M);
%           F=tfmat('wmdct',g,M);
%           F=tfmat('zak',L,a);
%           F=tfmat('gabmul',sym,a);
%           F=tfmat('spread',c);
%
%   TFMAT has been deprecated. Please construct a frame (using FRAME)
%   and use FRSYNMATRIX, or construct an operator (using OPERATORNEW)
%   and use OPERATORMATRIX instead.
%
%   Original help
%   -------------
%
%   TFMAT returns a matrix F containing the basis functions / atoms of
%   one of the transforms in the toolbox. The atoms are placed as column
%   vectors in the matrix. A forward transform (analysis) can be done by:
%
%     c=F'*f;
%
%   and a backwards or adjoint transform (synthesis) can be done by:
%
%     r=F*c;
%
%   The possibilities are:
%
%   TFMAT('fourier',L) returns the matrix of the unitary Fourier
%   transform of length L. See DFT.
%
%   TFMAT('dcti',L) returns the matrix of the DCTI transform of length
%   L. Similarly for 'dctii', 'dctiii', 'dctiv', 'dsti', 'dstii',
%   'dstiii' or 'dstiv'.
%
%   TFMAT('dgt',g,a,M) returns a matrix containing all the atoms of the
%   Gabor frame with window g and lattice constants a and M. 
%   TFMAT('dgt',g,a,M,L) will do the same for a FIR window g.
%
%   TFMAT('dwilt',g,M) returns a matrix containing all the atoms of the
%   Wilson  basis with window g and M channels. TFMAT(g,M,L) will do the
%   same for a FIR window g.
%
%   TFMAT('wmdct',g,M) and TFMAT('wmdct',g,M,L) does the same for an WMDCT
%   with M channels.
%
%   TFMAT('gabmul',sym,a) return the matrix of the Gabor multiplier with
%   symbol sym and time shift a. TFMAT('gabmul',c,g,a) does the same
%   using the window g for both analysis and synthesis.
%   TFMAT('gabmul',sym,ga,gs,a) does the same using ga as analysis window
%   and gs as synthesis window.
%
%   TFMAT('spread',c) returns the matrix of the spreading operator with
%   symbol c.
%
%   TFMAT('zak',L,a) returns the transform matrix for a Zak transform of
%   length L and parameter a.
% 
%   This function should mainly be used for educational purposes or for 
%   experimenting with systems, as the generated matrix can
%   become very large.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/deprecated/tfmat.html}
%@seealso{frsynmatrix, operatormatrix}
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

warning(['LTFAT: TFMAT has been deprecated, please use FRSYNMATRIX ' ...
         'or OPERATORMATRIX instead.']);   

if (nargin<1) || ~ischar(ttype)
  error('You must specify the transform type')
end;

switch(lower(ttype))
  case {'fourier','dft'}
    complainif_argnonotinrange(nargin,2,2,mfilename);
    F=idft(eye(p2));

  case {'dcti'}
    complainif_argnonotinrange(nargin,2,2,mfilename);
    F=dcti(eye(p2))';

  case {'dctii'}
    complainif_argnonotinrange(nargin,2,2,mfilename);
    F=dctii(eye(p2))';

  case {'dctiii'}
    complainif_argnonotinrange(nargin,2,2,mfilename);
    F=dctiii(eye(p2))';

  case {'dctiv'}
    complainif_argnonotinrange(nargin,2,2,mfilename);
    F=dctiv(eye(p2))';

  case {'dsti'}
    complainif_argnonotinrange(nargin,2,2,mfilename);
    F=dsti(eye(p2))';

  case {'dstii'}
    complainif_argnonotinrange(nargin,2,2,mfilename);
    F=dstii(eye(p2))';

  case {'dstiii'}
    complainif_argnonotinrange(nargin,2,2,mfilename);
    F=dstiii(eye(p2))';

  case {'dstiv'}
    complainif_argnonotinrange(nargin,2,2,mfilename);
    F=dstiv(eye(p2))';

  case {'gabor','dgt'}
    complainif_argnonotinrange(nargin,4,5,mfilename);
    g=p2;    
    if nargin==4
      L=length(g);
    else
      L=p5;
    end;
    a=p3;
    M=p4;
    N=L/a;
    c=reshape(eye(M*N),M,N,M*N);
    F=idgt(c,g,a);

  case {'wilson','dwilt'}
    complainif_argnonotinrange(nargin,3,4,mfilename);
    g=p2;    
    if nargin==3
      L=length(g);
    else
      L=p4;
    end;
    M=p3;
    N=L/M;
    c=reshape(eye(M*N),2*M,N/2,M*N);
    F=idwilt(c,g);

  case {'wmdct'}
    complainif_argnonotinrange(nargin,3,4,mfilename);
    g=p2;    
    if nargin==3
      L=length(g);
    else
      L=p4;
    end;
    M=p3;
    N=L/M;
    c=reshape(eye(M*N),M,N,M*N);
    F=iwmdct(c,g);

  case {'spread','spreadop'}
    complainif_argnonotinrange(nargin,2,2,mfilename);
    c=p2;
    L=size(c,2);
    F=spreadop(eye(L),c);

  case {'gabmul'}
    complainif_argnonotinrange(nargin,3,5,mfilename);
    sym=p2;
    M=size(sym,1);
    N=size(sym,2);
    switch(nargin)
      case 3
       a=p3;
       L=a*N;
       F=gabmul(eye(L),sym,a);
     case 4
       g=p3;
       a=p4;       
       L=a*N;
       F=gabmul(eye(L),sym,g,a);
     case 5
       ga=p3;
       gs=p4;
       a=p5;       
       L=a*N;
       F=gabmul(eye(L),sym,ga,gs,a);
    end;

  case {'ndgt'}
    complainif_argnonotinrange(nargin,5,5,mfilename);
    g=p2;
    a=p3;
    M=p4;
    L=p5;
        
    %!!! the computation using eye matrix doesn't work if M>sigLen
    
    N=length(a); % number of time positions
    MN=sum(M); % total number of frame elements
    
    F=zeros(L,MN);
    jj=0;
    for ii=1:N
      c={eye(M(ii))};
      F(:,jj+(1:M(ii)))=indgt(c,g(ii),a(ii),L);
      jj=jj+M(ii);
    end
    

  case {'zak'}
    complainif_argnonotinrange(nargin,3,5,mfilename);
    L=p2;
    a=p3;
    N=L/a;
    c=reshape(eye(L),a,N,L);
    F=izak(c);

  otherwise
    error('Unknown transform.');
end;


