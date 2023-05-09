%-*- texinfo -*-
%@deftypefn {Function} octave_poly2mask
%@verbatim
% Copyright (C) 2004 Josep Mones i Teixidor <jmones@puntbarra.com>
%
% This program is free software; you can redistribute it and/or modify it under
% the terms of the GNU General Public License as published by the Free Software
% Foundation; either version 3 of the License, or (at your option) any later
% version.
%
% This program is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
% FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
% details.
%
% You should have received a copy of the GNU General Public License along with
% this program; if not, see <http://www.gnu.org/licenses/>.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/mulaclab/octave_poly2mask.html}
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

% -*- texinfo -*-
% @deftypefn {Function File} {@var{BW} = } octave_poly2mask (@var{x},@var{y},@var{m},@var{n})
% Convert a polygon to a region mask.
%
% BW=octave_poly2mask(x,y,m,n) converts a polygon, specified by a list of
% vertices in @var{x} and @var{y} and returns in a @var{m}-by-@var{n}
% logical mask @var{BW} the filled polygon. Region inside the polygon
% is set to 1, values outside the shape are set to 0.
%
% @var{x} and @var{y} should always represent a closed polygon, first
% and last points should be coincident. If they are not octave_poly2mask will
% close it for you. If @var{x} or @var{y} are fractional they are
% nearest integer.
%
% If all the polygon or part of it falls outside the masking area
% (1:m,1:n), it is discarded or clipped.
%
% This function uses scan-line polygon filling algorithm as described
% in http://www.cs.rit.edu/~icss571/filling/ with some minor
% modifications: capability of clipping and scan order, which can
% affect the results of the algorithm (algorithm is described not to
% reach ymax, xmax border when filling to avoid enlarging shapes). In
% this function we scan the image backwards (we begin at ymax and end
% at ymin), and we don't reach ymin, xmin, which we believe should be
% compatible with MATLAB.
% @end deftypefn

% TODO: check how to create a logical BW without any conversion

function BW = octave_poly2mask (x, y, m, n)
  if (nargin ~= 4)
    print_usage ();
  end

  % check x and y
  x = round (x (:).');
  y = round (y (:).');
  if (length (x) < 3)
    error ('octave_poly2mask: polygon must have at least 3 vertices.');
  end
  if (length (x) ~= length (y))
    error ('octave_poly2mask: length of x doesn''t match length of y.');
  end

  % create output matrix
  BW = false (m, n);

  % close polygon if needed
  if ((x (1) ~= x (length (x))) || (y (1) ~= y (length (y))))
    x = horzcat (x, x (1));
    y = horzcat (y, y (1));
  end

  % build global edge table
  ex = [x(1:length (x) - 1); x(1, 2:length (x))]; % x values for each edge
  ey = [y(1:length (y) - 1); y(1, 2:length (y))]; % y values for each edge
  idx = (ey(1, :) ~= ey(2, :));                 % eliminate horizontal edges
  ex = ex (:, idx);
  ey = ey (:, idx);
  eminy = min (ey);                               % minimum y for each edge
  emaxy = max (ey);                               % maximum y for each edge
  t = (ey == [eminy; eminy]);                     % values associated to miny
  exvec = ex(:);
  exminy = exvec(t);                            % x values associated to min y
  exmaxy = exvec(~t);                           % x values associated to max y
  emaxy = emaxy.';                                % we want them vertical now...
  eminy = eminy.';
  m_inv = (exmaxy - exminy)./(emaxy - eminy);     % calculate inverse slope
  ge = [emaxy, eminy, exmaxy, m_inv];             % build global edge table
  ge = sortrows (ge, [1, 3]);                     % sort on eminy and exminy

  % we add an extra dummy edge at the end just to avoid checking
  % while indexing it
  ge = [-Inf, -Inf, -Inf, -Inf; ge];

  % initial parity is even (0)
  parity = 0;

  % init scan line set to bottom line
  sl = ge (size (ge, 1), 1);

  % init active edge table
  % we use a loop because the table is sorted and edge list could be
  % huge
  ae = [];
  gei = size (ge, 1);
  while (sl == ge (gei, 1))
    ae = [ge(gei, 2:4); ae];
    gei = gei - 1;
  end

  % calc minimum y to draw
  miny = min (y);
  if (miny < 1)
    miny = 1;
  end

  while (sl >= miny)
    % check vert clipping
    if (sl <= m)
      % draw current scan line
      % we have to round because 1/m is fractional
      ie = round (reshape (ae (:, 2), 2, size (ae, 1)/2));

      % this discards left border of image (this differs from version at
      % http://www.cs.rit.edu/~icss571/filling/ which discards right
      % border) but keeps an exception when the point is a vertex.
      ie (1, :) = ie (1, :) + (ie (1, :) ~= ie (2, :));

      % we'll clip too, just in case m,n is not big enough
      ie (1, (ie (1, :) < 1)) = 1;
      ie (2, (ie (2, :) > n)) = n;

      % we eliminate segments outside window
      ie = ie (:, (ie (1, :) <= n));
      ie = ie (:, (ie (2, :) >= 1));
      for i = 1:size(ie,2)
        BW (sl, ie (1, i):ie (2, i)) = true;
      end
    end

    % decrement scan line
    sl = sl - 1;

    % eliminate edges that eymax==sl
    % this discards ymin border of image (this differs from version at
    % http://www.cs.rit.edu/~icss571/filling/ which discards ymax).
    ae = ae ((ae (:, 1) ~= sl), :);

    % update x (x1=x0-1/m)
    ae(:, 2) = ae(:, 2) - ae(:, 3);

    % update ae with new values
    while (sl == ge (gei, 1))
      ae = vertcat (ae, ge (gei, 2:4));
      gei = gei - 1;
    end

    % order the edges in ae by x value
    if (size(ae,1) > 0)
      ae = sortrows (ae, 2);
    end
  end
end

% This should create a filled octagon
%!demo
%! s = [0:pi/4:2*pi];
%! x = cos (s) * 90 + 101;
%! y = sin (s) * 90 + 101;
%! bw = octave_poly2mask(x, y, 200, 200);
%! imshow (bw);

% This should create a 5-vertex star
%!demo
%! s = [0:2*pi/5:pi*4];
%! s = s ([1, 3, 5, 2, 4, 6]);
%! x = cos (s) * 90 + 101;
%! y = sin (s) * 90 + 101;
%! bw = octave_poly2mask (x, y, 200, 200);
%! imshow (bw);

%!# Convex polygons

%!shared xs, ys, Rs, xt, yt, Rt
%! xs=[3,3,10,10];
%! ys=[4,12,12,4];
%! Rs=zeros(16,14);
%! Rs(5:12,4:10)=1;
%! Rs=logical(Rs);
%! xt=[1,4,7];
%! yt=[1,4,1];
%! Rt=[0,0,0,0,0,0,0;
%!     0,0,1,1,1,1,0;
%!     0,0,0,1,1,0,0;
%!     0,0,0,1,0,0,0;
%!     0,0,0,0,0,0,0];
%! Rt=logical(Rt);

%!assert(octave_poly2mask(xs,ys,16,14),Rs);          # rectangle
%!assert(octave_poly2mask(xs,ys,8,7),Rs(1:8,1:7));   # clipped
%!assert(octave_poly2mask(xs-7,ys-8,8,7),Rs(9:16,8:14)); # more clipping

%!assert(octave_poly2mask(xt,yt,5,7),Rt);            # triangle
%!assert(octave_poly2mask(xt,yt,3,3),Rt(1:3,1:3));   # clipped


%!# Concave polygons

%!test
%! x=[3,3,5,5,8,8,10,10];
%! y=[4,12,12,8,8,11,11,4];
%! R=zeros(16,14);
%! R(5:12,4:5)=1;
%! R(5:8,6:8)=1;
%! R(5:11,9:10)=1;
%! R=logical(R);
%! assert(octave_poly2mask(x,y,16,14), R);

%!# Complex polygons
%!test
%! x=[1,5,1,5];
%! y=[1,1,4,4];
%! R=[0,0,0,0,0,0;
%!    0,0,1,1,0,0;
%!    0,0,1,1,0,0;
%!    0,1,1,1,1,0;
%!    0,0,0,0,0,0];
%! R=logical(R);
%! assert(octave_poly2mask(x,y,5,6), R);

