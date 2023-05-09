function h=lconv(f,g,varargin)
%-*- texinfo -*-
%@deftypefn {Function} lconv
%@verbatim
%LCONV  Linear convolution
%   Usage:  h=lconv(f,g);
%
%   LCONV(f,g) computes the linear convolution of f and g. The linear 
%   convolution is given by
%
%               Lh-1
%      h(l+1) = sum f(k+1) * g(l-k+1)
%               k=0
%
%   with L_{h} = L_{f} + L_{g} - 1 where L_{f} and L_{g} are the lengths of f and g, 
%   respectively.
%
%   LCONV(f,g,'r') computes the linear convolution of f and g where g is reversed.
%   This type of convolution is also known as linear cross-correlation and is given by
%
%               Lh-1
%      h(l+1) = sum f(k+1) * conj(g(k-l+1))
%               k=0
%
%   LCONV(f,g,'rr') computes the alternative where both f and g are
%   reversed given by
%
%               Lh-1
%      h(l+1) = sum conj(f(-k+1)) * conj(g(k-l+1))
%               k=0
%     
%   In the above formulas, l-k, k-l and -k are computed modulo L_{h}.
%
%   The input arrays f and g can be 1D vectors or one of them can be
%   a multidimensional array. In either case, the convolution is performed
%   along columns with row vectors transformed to columns.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/lconv.html}
%@seealso{pconv}
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

%   AUTHOR: Jordy van Velthoven
%   TESTING: TEST_LCONV	
%   REFERENCE: REF_LCONV
  
complainif_notenoughargs(nargin, 2, 'LCONV');

definput.keyvals.L=[];
definput.keyvals.dim=[];
definput.flags.type={'default', 'r', 'rr'};

[flags,~,L,dim]=ltfatarghelper({'L','dim'},definput,varargin);

[f,~,Lf,Wf,dimoutf,permutedsize_f,order_f]=assert_sigreshape_pre(f,L,dim,'LCONV');
[g,~,Lg,Wg,dimoutg,permutedsize_g,order_g]=assert_sigreshape_pre(g,L,dim,'LCONV');

if (Wf>1) && (Wg>1)
  error('%s: Only one of the inputs can be multi-dimensional.',upper(mfilename));
end;

W=max(Wf,Wg);
if Wf<W
  f=repmat(f,1,W);
end;

if Wg<W
  g=repmat(g,1,W);
end;

Lh = Lf+Lg-1;

f = postpad(f,Lh);
g = postpad(g,Lh);

if isreal(f) && isreal(g)
  fftfunc = @(x) fftreal(x);
  ifftfunc = @(x) ifftreal(x, Lh);
else
  fftfunc = @(x) fft(x);
  ifftfunc = @(x) ifft(x, Lh);
end;

if flags.do_default
  h=ifftfunc(fftfunc(f).*fftfunc(g));
end;

if flags.do_r
  h=ifftfunc(fftfunc(f).*(conj(fftfunc(g))));
end;

if flags.do_rr
  h=ifftfunc((conj(fftfunc(f))).*(conj(fftfunc(g))));
end;



