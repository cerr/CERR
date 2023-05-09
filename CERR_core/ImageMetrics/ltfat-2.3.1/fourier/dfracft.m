function frf=dfracft(f,a,varargin)
%-*- texinfo -*-
%@deftypefn {Function} dfracft
%@verbatim
%DFRACFT  Discrete Fractional Fourier transform
%   Usage:  V=dfracft(f,a,p);
%           V=dfracft(f,a);
%
%   DFRACFT(f,a) computes the discrete fractional Fourier Transform of the
%   signal f to the power a. For a=1 it corresponds to the ordinary
%   discrete Fourier Transform. If f is multi-dimensional, the
%   transformation is applied along the first non-singleton dimension.
%
%   DFRACFT(f,a,dim) does the same along dimension dim.   
%
%   DFRACFT(f,a,[],p) or DFRACFT(f,a,dim,p) allows to choose the order
%   of approximation of the second difference operator (default: p=2*).
%
%
%   References:
%     A. Bultheel and S. Martinez. Computation of the Fractional Fourier
%     Transform. Appl. Comput. Harmon. Anal., 16(3):182--202, 2004.
%     
%     H. M. Ozaktas, Z. Zalevsky, and M. A. Kutay. The Fractional Fourier
%     Transform. John Wiley and Sons, 2001.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/dfracft.html}
%@seealso{ffracft, dft, hermbasis, pherm}
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

%   AUTHOR : Christoph Wiesmeyr 
%   TESTING: TEST_HERMBASIS
%   REFERENCE: OK

if nargin<2
  error('%s: Too few input parameters.',upper(mfilename));
end;

definput.keyvals.p   = 2;
definput.keyvals.dim = [];
[flags,keyvals,dim,p]=ltfatarghelper({'dim','p'},definput,varargin);

[f,L,Ls,W,dim,permutedsize,order]=assert_sigreshape_pre(f,[],dim,upper(mfilename));

H = hermbasis(L,p);

% set up the eigenvalues
k=0:L-1;
lam = exp(-1i*k*a*pi/2);
lam=lam(:);

% correction for even signal lengths
if ~rem(L,2)
    lam(end)=exp(-1i*L*a*pi/2);
end

% shuffle the eigenvalues in the right order
even=~mod(L,2);
cor=2*floor(L/4)+1;
for k=(cor+1):2:(L-even)
    lam([k,k+1])=lam([k+1,k]);
end

frf =H*(bsxfun(@times,lam,H'*f));

frf=assert_sigreshape_post(frf,dim,permutedsize,order);




