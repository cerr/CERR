function [gt]=wilorth(p1,p2,p3)
%-*- texinfo -*-
%@deftypefn {Function} wilorth
%@verbatim
%WILORTH  Wilson orthonormal window
%   Usage:   gt=wilorth(M,L);
%            gt=wilorth(g,M);
%            gt=wilorth(g,M,L);
%
%   Input parameters:
%         g   : Auxiliary window window function (optional).
%         M   : Number of modulations.
%         L   : Length of window (optional).
%   Output parameters:
%         gt  : Window generating an orthonormal Wilson basis.
%
%   WILORTH(M,L) computes a nice window of length L generating an
%   orthonormal Wilson or WMDCT basis with M frequency bands for signals
%   of length L.
%
%   WILORTH(g,M) computes a window generating an orthonomal basis from the
%   window g and number of channels M.
%
%   The window g may be a vector of numerical values, a text string or a
%   cell array. See the help of WILWIN for more details.
%
%   If the length of g is equal to 2xM, then the input window is
%   assumed to be a FIR window. In this case, the orthonormal window also
%   has length of 2xM. Otherwise the smallest possible transform
%   length is chosen as the window length.
%
%   WILORTH(g,M,L) pads or truncates g to length L before calculating
%   the orthonormal window. The output will also be of length L.
%
%   The input window g must be real whole-point even. If g is not
%   whole-point even, the computed window will not generate an orthonormal
%   system (i.e. reconstruction will not be perfect). For a random window
%   g, the window closest to g that satisfies these restrictions can be
%   found by :
%
%     g_wpe = real(peven(g));
%
%   All Gabor windows in the toolbox satisfies these restrictions unless
%   clearly stated otherwise.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/wilorth.html}
%@seealso{dwilt, wmdct, wildual, isevenfunction}
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

%   AUTHOR: Peter L. Soendergaard
%   TESTING: TEST_DWILT TEST_WMDCT
%   REFERENCE: OK

complainif_argnonotinrange(nargin,2,3,mfilename);

wasrow=0;

% Detect which parameters was entered, and do simple transformations.
if nargin == 3
  g=p1;
  M=p2;
  L=p3;

  if size(g,2)>1
    if size(g,1)>1
      error('g must be a vector');
    else
      % g was a row vector.
      wasrow=1;
      g=g(:);
    end;
  end;

  assert_squarelat(M,M,1,'WILORTH',0);
  [b,N,L]=assert_L(L,length(g),L,M,2*M,'WILORTH');


  % fir2long is now safe.
  g=fir2long(g,L);
else

  if numel(p1)>1
    % First parameter is a vector.
    g=p1;
    M=p2;
    
    if size(g,2)>1
      if size(g,1)>1
        error('g must be a vector');
      else
        % g was a row vector.
        wasrow=1;
        g=g(:);
      end;
    end;

    assert_squarelat(M,2*M,1,'WILORTH',0);
    [b,N,L]=assert_L(length(g),length(g),[],M,2*M,'WILORTH');
  else
    
    M=p1;
    L=p2;
    
    assert_squarelat(M,M,1,'WILORTH',0);
    [b,N,L]=assert_L(L,L,L,M,2*M,'WILORTH');

    a=M;
    b=L/(2*M);
        
    % Create default window, a Gaussian.
    g=comp_pgauss(L,a/b,0,0);    
  end;

end;

a=M;
b=L/(2*M);

% Multiply by sqrt(2), because comp_gabtight will return a normalized
% tight frame, i.e. the framebounds are A=B=1 instead of A=B=2. This means
% that the returned gt only has norm=.701 and not norm=1.

gt=sqrt(2)*comp_gabtight_long(g,a,2*M);

if wasrow
  gt=gt.';
end;


