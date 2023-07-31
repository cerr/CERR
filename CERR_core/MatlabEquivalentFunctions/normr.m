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
%% @deftypefn {Function File} {@var{x} = } normr (@var{M})
%% Normalize the rows of a matrix to a length of 1 and return the matrix.
%%
%% @example
%%   M=[1,2; 3,4];
%%   normr(M)
%%
%%   ans =
%%
%%   0.44721   0.89443
%%   0.60000   0.80000
%%
%% @end example
%% @seealso{normc}
%% @end deftypefn

function X = normr(M)
  if (1 != nargin)
    print_usage;
  endif
  
  norm = sqrt(sum(M .* conj(M),2));
  X = diag(1./norm) *  M;
endfunction

%% test for real and complex matrices
%!test
%! M = [1,2; 3,4];
%! expected = [0.447213595499958, 0.894427190999916; 0.6, 0.8];
%! assert(normr(M), expected, eps);

%!test
%! M = [i,2*i; 3*I,4*I];
%! expected = [0.447213595499958*I, 0.894427190999916*I; 0.6*I, 0.8*I];
%! assert(normr(M), expected, eps);

%!test
%! M = [1+2*I, 3+4*I; 5+6*I, 7+8*I];
%! expected = [0.182574185835055 + 0.365148371670111i, 0.547722557505166 + 0.730296743340221i
%!             0.379049021789452 + 0.454858826147342i, 0.530668630505232 + 0.606478434863123i];
%! assert(normr(M), expected, 10*eps);

%% test error/usage handling
%!error <normr> normr();