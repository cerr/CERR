function frf=ffracft(f,a,varargin)
%-*- texinfo -*-
%@deftypefn {Function} ffracft
%@verbatim
%FFRACFT Approximate fast fractional Fourier transform
%   Usage:  frf=ffracft(f,a)
%           frf=ffracft(f,a,dim)
%
%   FFRACFT(f,a) computes an approximation of the fractional Fourier
%   transform of the signal f to the power a. If f is
%   multi-dimensional, the transformation is applied along the first
%   non-singleton dimension.
%
%   FFRACFT(f,a,dim) does the same along dimension dim.   
%
%   FFRACFT takes the following flags at the end of the line of input
%   arguments:
%
%     'origin'    Rotate around the origin of the signal. This is the
%                 same action as the DFT, but the signal will split in
%                 the middle, which may not be the correct action for
%                 data signals. This is the default.
%
%     'middle'    Rotate around the middle of the signal. This will not
%                 break the signal in the middle, but the DFT cannot be
%                 obtained in this way.
%
%   Examples:
%   ---------
%
%   The following example shows a rotation of the LTFATLOGO test
%   signal:
%
%      sgram(ffracft(ltfatlogo,.3,'middle'),'lin','nf');
%
%
%   References:
%     A. Bultheel and S. Martinez. Computation of the Fractional Fourier
%     Transform. Appl. Comput. Harmon. Anal., 16(3):182--202, 2004.
%     
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/ffracft.html}
%@seealso{dfracft, hermbasis, pherm}
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

%   AUTHOR: Christoph Wiesmeyr
%   TESTING: ??

if nargin<2
  error('%s: Too few input parameters.',upper(mfilename));
end;

definput.keyvals.p      = 2;
definput.keyvals.dim    = [];
definput.flags.center = {'origin','middle'};
[flags,keyvals,dim,p]=ltfatarghelper({'dim','p'},definput,varargin);

[f,L,Ls,W,dim,permutedsize,order]=assert_sigreshape_pre(f,[],dim,upper(mfilename));

% correct input
a=mod(a,4);

if flags.do_middle
    f=fftshift(f);
end;

% special cases
switch(a)
  case 0
    frf=f;
  case 1      
    frf=fft(f)/sqrt(L);
  case 2
    frf=flipud(f);
  case 3
    frf=fft(flipud(f));
  otherwise

    % reduce to interval 0.5 < a < 1.5
    if (a>2.0), a = a-2; f = flipud(f); end
    if (a>1.5), a = a-1; f = fft(f)/sqrt(L); end
    if (a<0.5), a = a+1; f = ifft(f)*sqrt(L); end
    
    % general setting
    alpha = a*pi/2;
    tana2 = tan(alpha/2);
    sina = sin(alpha);
    
    % oversample and zero pad f (sinc interpolation)
    
    m=norm(f);
    f=ifft(middlepad(fft(f),2*L))*sqrt(2);
    f=middlepad(f,4*L);
    
    % chirp multiplication
    
    chrp = fftshift(exp(-i*pi/L*tana2/4*((-2*L):(2*L-1))'.^2));
    f=f.*chrp;
    
    % chirp convolution
    
    c = pi/L/sina/4;
    chrp2=fftshift(exp(i*c*((-2*L):(2*L-1))'.^2));
    frf=(pconv(middlepad(chrp2,8*L),middlepad(f,8*L)));
    frf(2*L+1:6*L)=[];
    
    % chirp multiplication
    
    frf=frf.*chrp;
    
    % normalize and downsample
    frf(L+1:3*L)=[];
    ind=ceil(L/2);
    ft=fft(frf);
    ft(ind+1:ind+L)=[];
    frf=ifft(ft);
    frf = exp(-i*(1-a)*pi/4)*frf;
    frf=normalize(frf)*m;
    
end;

if flags.do_middle
    frf=ifftshift(frf);
end;

frf=assert_sigreshape_post(frf,dim,permutedsize,order);

