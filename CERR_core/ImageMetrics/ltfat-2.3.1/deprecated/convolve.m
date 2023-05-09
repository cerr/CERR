function h=convolve(f,g,varargin)
%-*- texinfo -*-
%@deftypefn {Function} convolve
%@verbatim
%CONVOLVE  Convolution
%   Usage:  h=convolve(f,g);
%
%   CONVOLVE has been deprecated. Please use LCONV instead.
%
%   A call to CONVOLVE(f,g) can be replaced by :
%
%     lconv(f,g);
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/deprecated/convolve.html}
%@seealso{lconv}
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

warning(['LTFAT: CONVOLVE has been deprecated, please use LCONV ' ...
         'instead. See the help on LCONV for more details.']); 
  
if nargin<2
  error('%s: Too few input parameters.',upper(mfilename));
end;

definput.keyvals.L=[];
definput.keyvals.dim=[];

[flags,kv,L,dim]=ltfatarghelper({'L','dim'},definput,varargin);

[f,L1,Lf,Wf,dimout,permutedsize_f,order_f]=assert_sigreshape_pre(f,L,dim,'CONVOLVE');
[g,L2,Lg,Wg,dimout,permutedsize_g,order_g]=assert_sigreshape_pre(g,L,dim,'CONVOLVE');

Lh=Lf+Lg-1;

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

if isreal(f) && isreal(g)
  h=comp_ifftreal(comp_fftreal(postpad(f,Lh)).*...
                  comp_fftreal(postpad(g,Lh)),Lh);
else
  h=ifft(fft(postpad(f,Lh)).*...
         fft(postpad(g,Lh)));
  
end;

