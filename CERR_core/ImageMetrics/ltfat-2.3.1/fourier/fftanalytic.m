function z = fftanalytic(f,varargin)
%-*- texinfo -*-
%@deftypefn {Function} fftanalytic
%@verbatim
%FFTANALYTIC Compute analytic representation
%   Usage:  z = fftanalytic(f);
%           z = fftanalytic(f,L);
%           z = fftanalytic(f,L,dim);
%
%   Input parameters:
%         f     : Input data.
%         L     : Extend or truncate f to this length.
%         dim   : Dimension to along which to apply the computations.
%   Output parameters:
%         z     : Analytic signal.
%
%   FFTANALYTIC(f) computes the analytic representation of a 
%   real-valued signal f. The analytic representation is computed 
%   through the FFT of f. The computations are done along the first 
%   non-singleton dimension. 
%
%   FFTANALYTIC(f,L) acts as before but f is padded with zeros or 
%   truncated to length L.
%
%   FFTANALYTIC(f,L,dim) in addition allows specifying the dimension 
%   along which the computation should be done.
%
%   The real part of the analytic representation z equals the signal 
%   f and the imaginary part is the Hilbert transform of f. 
%
%   The instananeous amplitude (a Hilbert envelope) of the signal f can 
%   be computed as:
%
%     abs(fftanalytic(f));
%
%   The instantaneous phase of the function f can be computed as:
%
%     angle(fftanalytic(f));
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/fftanalytic.html}
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

if ~isreal(f)
  error('%s: The input should be a real-valued numeric array.',...
      upper(mfilename));
end;

definput.keyvals.dim=[];
definput.keyvals.L=[];
[~,~,L,dim]=ltfatarghelper({'L','dim'},definput,varargin);
         
% Pre-shape the signal
[f,L,~,~,dim,permutedsize,order]=assert_sigreshape_pre(f,L,dim,upper(mfilename));

f = postpad(f,L);

% Run the computation
z = comp_fftanalytic(f);

% Post-shape the signal
z = assert_sigreshape_post(z,dim,permutedsize,order);

