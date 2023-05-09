function A = ambiguityfunction(f,g)
%-*- texinfo -*-
%@deftypefn {Function} ambiguityfunction
%@verbatim
%AMBIGUITYFUNCTION Ambiguity function
%   Usage: A = ambiguityfunction(f);
%          A = ambiguityfunction(f,g);
%
%   Input parameters:
%         f,g    : Input vector(s).
%
%   Output parameters:
%         A      : ambiguity function
%
%   AMBIGUITYFUNCTION(f) computes the (symmetric) ambiguity function of f.
%   The ambiguity function is computed as the two-dimensional Fourier transform
%   of the Wigner-Ville distribution WIGNERVILLEDIST.
%
%   *WARNING**: The quadratic time-frequency distributions are highly
%   redundant. For an input vector of length L, the quadratic time-frequency
%   distribution will be a L xL matrix.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/quadratic/ambiguityfunction.html}
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
% TESTING: TEST_AMBIGUITYFUNCTION
% REFERENCE: REF_AMBIGUITYFUNCTION

upfname = upper(mfilename);
complainif_notenoughargs(nargin, 1, upfname);
complainif_toomanyargs(nargin, 2, upfname);

[f,~,W]=comp_sigreshape_pre(f,upfname);

if W>1
   error('%s: Only one-dimensional vectors can be processed.',upfname); 
end

if (nargin == 1)
  if isreal(f)
    z1 = comp_fftanalytic(f);
  else
    z1 = f;
  end
  z2 = z1;

elseif (nargin == 2)
  [g,~,W]=comp_sigreshape_pre(g,upfname);
  if W>1
     error('%s: Only one-dimensional vectors can be processed.',upfname); 
  end

  if ~all(size(f)==size(g))
  	error('%s: f and g must have the same length.', upfname);
  end;

  if xor(isreal(f), isreal(g))
      error('%s: One input is real, the other one must be real too. ',...
            upfname);
  end

  if isreal(f) || isreal(g)
    z1 = comp_fftanalytic(f);
    z2 = comp_fftanalytic(g);
  else
    z1 = f;
    z2 = g;
  end;
end

R = comp_instcorrmat(z1, z2);

A = fftshift(fft2(fft(R)));



