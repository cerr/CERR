%% Copyright (C) 2011 Thomas Weber <tweber@debian.org>
%%
%% This program is free software; you can redistribute it and/or modify it under
%% the terms of the GNU General Public License as published by the Free Software
%% Foundation; either version 3 of the License, or (at your option) any later
%% version.
%%
%% This program is distributed in the hope that it will be useful, but WITHOUT
%% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
%% FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
%% details.
%%
%% You should have received a copy of the GNU General Public License along with
%% this program; if not, see <http://www.gnu.org/licenses/>.

%% -*- texinfo -*-
%% @deftypefn {Function File} {@var{x} =} normc (@var{M})
%% Normalize the columns of a matrix to a length of 1 and return the matrix.
%%
%% @example
%%   M=[1,2; 3,4];
%%   normc(M)
%%
%%   ans =
%%
%%   0.31623   0.44721
%%   0.94868   0.89443
%%
%% @end example
%% @seealso{normr}
%% @end deftypefn

function X = normc(M)
  if (1 != nargin)
    print_usage;
  endif

  X = normr(M.').';
  end

%% test for real and complex matrices
%!test
%! M = [1,2; 3,4];
%! expected = [0.316227766016838, 0.447213595499958;
%!             0.948683298050514, 0.894427190999916];
%! assert(normc(M), expected, eps);

%!test
%! M = [i,2*i; 3*I,4*I];
%! expected = [0.316227766016838*I, 0.447213595499958*I;
%!             0.948683298050514*I, 0.894427190999916*I];
%! assert(normc(M), expected, eps);

%!test
%! M = [1+2*I, 3+4*I; 5+6*I, 7+8*I];
%! expected = [0.123091490979333 + 0.246182981958665i, 0.255376959227625 + 0.340502612303499i;
%!             0.615457454896664 + 0.738548945875996i, 0.595879571531124 + 0.681005224606999i];
%! assert(normc(M), expected, 10*eps);

%% test error/usage handling
%!error <normc> normc();