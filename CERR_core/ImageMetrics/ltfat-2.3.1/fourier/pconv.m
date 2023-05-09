function h=pconv(f,g,varargin)
%-*- texinfo -*-
%@deftypefn {Function} pconv
%@verbatim
%PCONV  Periodic convolution
%   Usage:  h=pconv(f,g)
%           h=pconv(f,g,ftype); 
%
%   PCONV(f,g) computes the periodic convolution of f and g. The convolution
%   is given by
%
%               L-1
%      h(l+1) = sum f(k+1) * g(l-k+1)
%               k=0
%
%   PCONV(f,g,'r') computes the convolution where g is reversed
%   (involuted) given by
%
%               L-1
%      h(l+1) = sum f(k+1) * conj(g(k-l+1))
%               k=0
%
%   This type of convolution is also known as cross-correlation.
%
%   PCONV(f,g,'rr') computes the alternative where both f and g are
%   reversed given by
%
%               L-1
%      h(l+1) = sum conj(f(-k+1)) * conj(g(k-l+1))
%               k=0
%     
%   In the above formulas, l-k, k-l and -k are computed modulo L.
%
%   The input arrays f and g can be 1D vectors or one of them can be
%   a multidimensional array. In either case, the convolution is performed
%   along columns with row vectors transformed to columns.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/pconv.html}
%@seealso{dft, involute}
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

%   AUTHOR: Peter L. Soendergaard, Jordy van Velthoven
%   TESTING: TEST_PCONV
%   REFERENCE: REF_PCONV


complainif_notenoughargs(nargin, 2, 'PCONV');

definput.keyvals.L=[];
definput.keyvals.dim=[];
definput.flags.type={'default', 'r', 'rr'};
[flags,~,L,dim]=ltfatarghelper({'L','dim'},definput,varargin);

[f,~,~,Wf,dimout,permutedsize_f,order_f]=assert_sigreshape_pre(f,L,dim,'PCONV');
[g,~,~,Wg,dimout,permutedsize_g,order_g]=assert_sigreshape_pre(g,L,dim,'PCONV');

if (Wf>1) && (Wg>1)
  error('%s: Only one of the inputs can be multi-dimensional.',upper(mfilename));
end;

if size(f,1)~=size(g,1)
    error(['%s: f and g must have the same size in the direction of the',...
           ' convolution.'],upper(mfilename));
end;

W=max(Wf,Wg);
if Wf<W
  f=repmat(f,1,W);
end;

if Wg<W
  g=repmat(g,1,W);
end;

if isreal(f) && isreal(g)
    fftfunc = @(x) fftreal(x);
    ifftfunc = @(x) ifftreal(x, size(f,1));
else
    fftfunc = @(x) fft(x);
    ifftfunc = @(x) ifft(x);
end;

if flags.do_default
    h=ifftfunc(fftfunc(f).*fftfunc(g));
end;

if flags.do_r
  h=ifftfunc(fftfunc(f).*conj(fftfunc(g)));
end;

if flags.do_rr
  h=ifftfunc(conj(fftfunc(f)).*conj(fftfunc(g)));
end;

