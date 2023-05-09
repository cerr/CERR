function W = wignervilledist(f,varargin)
%-*- texinfo -*-
%@deftypefn {Function} wignervilledist
%@verbatim
%WIGNERVILLEDIST Wigner-Ville distribution
%   Usage: W = wignervilledist(f);
%          W = wignervilledist(f, g);
%
%   Input parameters:
%         f,g      : Input vector(s)
%
%   Output parameters:
%         w      : Wigner-Ville distribution
%
%   WIGNERVILLEDIST(f) computes the Wigner-Ville distribution of the vector f. The
%   Wigner-Ville distribution is computed by
%
%   where R(n,m) is the instantaneous correlation matrix given by
%
%   where m in {-L/2,..., L/2 - 1}, and where z is the analytical representation of
%   f, when f is real-valued.
%
%   WIGNERVILLEDIST(f,g) computes the cross-Wigner-Ville distribution of f and g.
%
%   *WARNING**: The quadratic time-frequency distributions are highly
%   redundant. For an input vector of length L, the quadratic time-frequency
%   distribution will be a L xL matrix.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/quadratic/wignervilledist.html}
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

% AUTHOR: Jordy van Velthoven
% TESTING: TEST_WIGNERVILLEDIST
% REFERENCE: REF_WIGNERVILLEDIST

upfname = upper(mfilename);
complainif_notenoughargs(nargin, 1, upfname);

definput.flags.complex = {'asinput','complex'};
definput.keyvals.g=[];
[flags,kv,g]=ltfatarghelper({'g'},definput,varargin);

[f,~,W]=comp_sigreshape_pre(f,upfname);
if W>1
   error('%s: Only one-dimensional vectors can be processed.',upfname); 
end

if isempty(g)
  if isreal(f) && ~flags.do_complex
    z1 = comp_fftanalytic(f);
  else
    z1 = f;
  end
  
  z2 = z1;
  R = comp_instcorrmat(z1, z2);

  W = real(fft(R));

else
  [g,~,W]=comp_sigreshape_pre(g,upfname);
  
  if W>1
    error('%s: Only one-dimensional vectors can be processed.',upfname); 
  end

  if ~all(size(f)==size(g))
  	error('%s: f and g must have the same length.', upper(mfilename));
  end;
  
  if xor(isreal(f), isreal(g))
      error('%s: One input is real, the other one must be real too. ',...
            upfname);
  end

  if isreal(f) || isreal(g) && ~flags.do_complex
    z1 = comp_fftanalytic(f);
    z2 = comp_fftanalytic(g);
  else
    z1 = f;
    z2 = g;
  end;

  R = comp_instcorrmat(z1, z2);

  W = fft(R);
end

