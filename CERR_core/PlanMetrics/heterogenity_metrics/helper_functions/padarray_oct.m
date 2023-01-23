% Copyright (C) 2013 CarnÃ« Draug <carandraug@octave.org>
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

% -*- texinfo -*-
% @deftypefn  {Function File} {} padarray (@var{A}, @var{padsize})
% @deftypefnx {Function File} {} padarray (@dots{}, @var{padval})
% @deftypefnx {Function File} {} padarray (@dots{}, @var{pattern})
% @deftypefnx {Function File} {} padarray (@dots{}, @var{direction})
% Pad array or matrix.
%
% Adds padding of length @var{padsize}, to a numeric matrix @var{A}.
% @var{padsize} must be a vector of non-negative values, each of them
% defining the length of padding to its corresponding dimension.  For
% example, if @var{padsize} is [4 5], it adds 4 rows (1st dimension)
% and 5 columns (2nd dimension), to both the start and end of @var{A}.
%
% If there's less values in @var{padsize} than number of dimensions in @var{A},
% they're assumed to be zero.  Singleton dimensions of @var{A} are also
% padded accordingly (except when @var{pattern} is @qcode{"reflect"}).
%
% The values used in the padding can either be a scalar value @var{padval}, or
% the name of a specific @var{pattern}.  Available patterns are:
%
% @table @asis
% @item @qcode{"zeros"} (default)
% Pads with the value 0 (same as passing a @var{padval} of 0).  This is the
% default.
%
% @item @qcode{"circular"}
% Pads with a circular repetition of elements in @var{A} (similar to
% tiling @var{A}).
%
% @item @qcode{"replicate"}
% Pads replicating the values at the border of @var{A}.
%
% @item @qcode{"symmetric"}
% Pads with a mirror reflection of @var{A}.
%
% @item @qcode{"reflect"}
% Same as "symmetric", but the borders are not used in the padding.  Because
% of this, it is not possible to pad singleton dimensions.
%
% @end table
%
% By default, padding is done in both directions.  To change this,
% @var{direction} can be one of the following values:
%
% @table @asis
% @item @qcode{"both"} (default)
% Pad each dimension before the first element of @var{A} the number
% of elements defined by @var{padsize}, and the same number again after
% the last element. This is the default.
%
% @item @qcode{"pre"}
% Pad each dimension before the first element of @var{A} the number of
% elements defined by @var{padsize}.
%
% @item @qcode{"post"}
% Pad each dimension after the last element of @var{A} the number of
% elements defined by @var{padsize}.
%
% @end table
%
% @seealso{cat, flip, resize, prepad, postpad}
% @end deftypefn

function B = padarray_oct(A, padsize, varargin)

  if (nargin < 2 || nargin > 4)
    print_usage ();
  elseif (~ isvector (padsize) || ~ isnumeric (padsize) || any (padsize < 0) || ...
          any (padsize ~= fix (padsize)))
    error ('padarray: PADSIZE must be a vecto of non-negative integers');
  end

  % Assure padsize is a row vector
  padsize = padsize(:).';

  if (~ any (padsize))
    % Nothing to do here
    B = A;
    return
  end

  % Default values
  padval    = 0;
  pattern   = '';
  direction = 'both';

  % There won't be more than 2 elements in varargin
  % We have to support setting the padval (shape) and direction in any
  % order. Both examples must work:
  %  padarray (A, padsize, "circular", "pre")
  %  padarray (A, padsize, "pre", "circular")
  for opt = 1:numel(varargin)
    val = varargin{opt};
    if (ischar (val))
      if (any (strcmpi (val, {'pre', 'post', 'both'})))
        direction = val;
      elseif (any (strcmpi (val, {'circular', 'replicate', 'reflect', 'symmetric'})))
        pattern = val;
      elseif (strcmpi (val, 'zeros'))
        padval = 0;
      else
        error ('padarray: unrecognized string option `%s', val);
      end
    elseif (isscalar (val))
      padval = val;
    else
      error ('padarray: PADVAL and DIRECTION must be a string or a scalar');
    end
  end

  fancy_pad = false;
  if (~ isempty (pattern))
    fancy_pad = true;
  end

  % Check direction
  pre  = any (strcmpi (direction, {'pre', 'both'}));
  post = any (strcmpi (direction, {'post', 'both'}));

  % Create output matrix
  B_ndims = max ([numel(padsize) ndims(A)]);
  A_size  = size (A);
  P_size  = padsize;
  A_size(end+1:B_ndims) = 1;  % add singleton dimensions
  P_size(end+1:B_ndims) = 0;  % assume zero for missing dimensions

  pre_pad_size = P_size * pre;
  B_size = A_size + pre_pad_size + (P_size * post);

  % insert input matrix into output matrix
  A_idx = cell (B_ndims, 1);
  for dim = 1:B_ndims
    A_idx{dim} = (pre_pad_size(dim) +1):(pre_pad_size(dim) + A_size(dim));
  end
  if (post && ~ pre && (padval == 0 || fancy_pad))
    % optimization for post padding only with zeros
    %B = resize (A, B_size);
    B = resize_oct (A, B_size);
  else
    B = repmat (cast (padval, class (A)), B_size);
    B(A_idx{:}) = A;
  end

  if (fancy_pad)
    % Init a template "index all" cell array
    template_idx = repmat ({':'}, [B_ndims 1]);

    circular = false;
    replicate = false;
    symmetric = false;
    reflect = false;
    switch (lower (pattern))
      case 'circular',  circular  = true;
      case 'replicate', replicate = true;
      case 'symmetric', symmetric = true;
      case 'reflect',   reflect   = true;
      otherwise
        error ('padarray: unknown PADVAL `%s`', pattern);
    end

    % For a dimension of the input matrix of size 1, since reflect does
    % not includes the borders, it is not possible to pad singleton dimensions.
    if (reflect && any ((~ (A_size -1)) & P_size))
      error ('padarray: can''t add %s padding to singleton dimensions', pattern);
    end

    % For symmetric and reflect:
    %
    % The idea is to split the padding into 3 different cases:
    %    bits
    %        Parts of the input matrix that are used for the padding.
    %        In most user cases, there will be only this padding,
    %        complete will be zero, and so bits will be equal to padsize.
    %    complete
    %        Number of full copies of the input matrix are used for
    %        the padding (for reflect, "full" size is actually minus 1).
    %        This is divided into pair and unpaired complete. In most
    %        cases, this will be zero.
    %    pair complete
    %        Number of pairs of complete copies.
    %    unpaired complete
    %        This is either 1 or 0. If 1, then the complete copy closer
    %        to the output borders has already been flipped so that if
    %        there's bits used to pad as well, they don't need to be flipped.
    %
    % Reasoning pair and unpaired complete: when the pad is much larger
    % than the input matrix, we must pay we must pay special attention to
    % symmetric and reflect. In a normal case (the padding is smaller than
    % the input), we just use the flipped matrix to pad and we're done.
    % In other cases, if the input matrix is used multiple times on the
    % pad, every other copy of it must NOT be flipped (the padding must be
    % symmetric itself) or the padding will be circular.

    if (reflect)
      A_cut_size          = A_size -1;
      complete            = floor (P_size ./ A_cut_size);
      bits                = rem (P_size, A_cut_size);
      pair_size           = A_cut_size * 2;
      pair_complete       = floor (complete / 2);
      unpaired_complete   = mod (complete, 2);
    else
      complete            = floor (P_size ./ A_size);
      bits                = rem (P_size, A_size);
      if (circular)
        complete_size     = complete .* A_size;
      elseif (symmetric)
        pair_complete     = floor (complete / 2);
        pair_size         = A_size * 2;
        unpaired_complete = mod (complete, 2);
      end
    end

    dim = 0;
    for s = padsize
      dim = dim + 1;
      if (s == 0)
        % skip this dimension if no padding requested
        continue
      end

      if (circular)
        dim_idx     = template_idx;
        source_idx  = template_idx;
        A_idx_end   = A_idx{dim}(end);
        A_idx_ini   = A_idx{dim}(1);

        if (complete(dim))
          dim_pad_size(1:B_ndims) = 1;
          dim_pad_size(dim)       = complete(dim)*pre + complete(dim)*post;
          dim_idx{dim}            = [];
          if (pre)
            dim_idx{dim}  = [(bits(dim) +1):(complete_size(dim) + bits(dim))];
          end
          if (post)
            dim_idx{dim}  = [dim_idx{dim} (A_idx_end +1):(A_idx_end + complete_size(dim))];
          end
          source_idx{dim} = A_idx{dim};
          B(dim_idx{:})   = repmat (B(source_idx{:}), dim_pad_size);
        end

        if (pre)
          if (bits(dim))
            dim_idx{dim}    = 1:bits(dim);
            source_idx{dim} = (A_idx_end - bits(dim) +1):A_idx_end;
            B(dim_idx{:})   = B(source_idx{:});
          end
        end
        if (post)
          if (bits(dim))
            dim_idx{dim}    = (B_size(dim) -bits(dim) +1):B_size(dim);
            source_idx{dim} = A_idx_ini:(A_idx_ini + bits(dim) -1);
            B(dim_idx{:})   = B(source_idx{:});
          end
        end

      elseif (replicate)
        dim_pad_size(1:B_ndims) = 1;
        dim_pad_size(dim)       = P_size(dim);
        dim_idx                 = template_idx;
        source_idx              = template_idx;
        if (pre)
          dim_idx{dim}          = 1:P_size(dim);
          source_idx{dim}       = P_size(dim) +1;
          B(dim_idx{:})         = repmat (B(source_idx{:}), dim_pad_size);
        end
        if (post)
          dim_idx{dim}          = (A_idx{dim}(end) +1):B_size(dim);
          source_idx{dim}       = A_idx{dim}(end);
          B(dim_idx{:})         = repmat (B(source_idx{:}), dim_pad_size);
        end

      % The idea behind symmetric and reflect passing is the same so the
      % following cases have similar looking code. However, there's small
      % adjustements everywhere that makes it really hard to merge as a
      % common case.
      elseif (symmetric)
        dim_idx     = template_idx;
        source_idx  = template_idx;
        A_idx_ini   = A_idx{dim}(1);
        A_idx_end   = A_idx{dim}(end);

        if (pre)
          if (bits(dim))
            dim_idx{dim}      = 1:bits(dim);
            if (unpaired_complete(dim))
              source_idx{dim} = (A_idx_end - bits(dim) +1):A_idx_end;
              B(dim_idx{:})   = B(source_idx{:});
            else
              source_idx{dim} = A_idx_ini:(A_idx_ini + bits(dim) -1);
              B(dim_idx{:})   = flip (B(source_idx{:}), dim);
            end
          end
        end
        if (post)
          if (bits(dim))
            dim_idx{dim}      = (B_size(dim) - bits(dim) +1):B_size(dim);
            if (unpaired_complete(dim))
              source_idx{dim} = A_idx_ini:(A_idx_ini + bits(dim) -1);
              B(dim_idx{:})   = B(source_idx{:});
            else
              source_idx{dim} = (A_idx_end - bits(dim) +1):A_idx_end;
              B(dim_idx{:})   = flip (B(source_idx{:}), dim);
            end
          end
        end

        if (complete(dim))
          dim_pad_size(1:B_ndims) = 1;
          source_idx{dim}         = A_idx{dim};
          flipped_source          = flip (B(source_idx{:}), dim);
        end

        if (pair_complete(dim))
          dim_pad_size(dim) = pair_complete(dim);
          dim_idx{dim}      = [];
          if (pre)
            dim_idx{dim}    = [(1 + bits(dim) + (A_size(dim)*unpaired_complete(dim))):(A_idx_ini -1)];
            B(dim_idx{:})   = repmat (cat (dim, B(source_idx{:}), flipped_source), dim_pad_size);
          end
          if (post)
            dim_idx{dim}    = [(A_idx_end +1):(A_idx_end + (pair_size(dim) * pair_complete(dim)))];
            B(dim_idx{:})   = repmat (cat (dim, flipped_source, B(source_idx{:})), dim_pad_size);
          end
        end

        if (unpaired_complete(dim))
          source_idx = template_idx;
          if (pre)
            dim_idx{dim}  = (1 + bits(dim)):(bits(dim) + A_size(dim));
            B(dim_idx{:}) = flipped_source(source_idx{:});
          end
          if (post)
            dim_idx{dim}  = (B_size(dim) - bits(dim) - A_size(dim) +1):(B_size(dim) - bits(dim));
            B(dim_idx{:}) = flipped_source(source_idx{:});
          end
        end

      elseif (reflect)
        dim_idx     = template_idx;
        source_idx  = template_idx;
        A_idx_ini   = A_idx{dim}(1);
        A_idx_end   = A_idx{dim}(end);

        if (pre)
          if (bits(dim))
            dim_idx{dim}      = 1:bits(dim);
            if (unpaired_complete(dim))
              source_idx{dim} = (A_idx_end - bits(dim)):(A_idx_end -1);
              B(dim_idx{:})   = B(source_idx{:});
            else
              source_idx{dim} = (A_idx_ini +1):(A_idx_ini + bits(dim));
              B(dim_idx{:})   = flip (B(source_idx{:}), dim);
            end
          end
        end
        if (post)
          if (bits(dim))
            dim_idx{dim}      = (B_size(dim) - bits(dim) +1):B_size(dim);
            if (unpaired_complete(dim))
              source_idx{dim} = (A_idx_ini +1):(A_idx_ini + bits(dim));
              B(dim_idx{:})   = B(source_idx{:});
            else
              source_idx{dim} = (A_idx_end - bits(dim)):(A_idx_end -1);
              B(dim_idx{:})   = flip (B(source_idx{:}), dim);
            end
          end
        end

        if (complete(dim))
          dim_pad_size(1:B_ndims) = 1;
          source_idx{dim}         = A_idx{dim};
          flipped_source          = flip (B(source_idx{:}), dim);
        end

        if (pair_complete(dim))
          dim_pad_size(dim) = pair_complete(dim);
          dim_idx{dim}      = [];
          if (pre)
            flipped_source_idx = source_idx;
            flipped_source_idx{dim} = 1:A_cut_size(dim);
            source_idx{dim} = A_idx_ini:(A_idx_end -1);
            dim_idx{dim}    = [(1 + bits(dim) + (A_cut_size(dim)*unpaired_complete(dim))):(A_idx_ini -1)];
            B(dim_idx{:})   = repmat (cat (dim, B(source_idx{:}), flipped_source(flipped_source_idx{:})), dim_pad_size);
          end
          if (post)
            flipped_source_idx = source_idx;
            flipped_source_idx{dim} = 2:A_size(dim);
            source_idx{dim} = (A_idx_ini +1):A_idx_end;
            dim_idx{dim}    = [(A_idx_end +1):(A_idx_end + (pair_size(dim) * pair_complete(dim)))];
            B(dim_idx{:})   = repmat (cat (dim, flipped_source(flipped_source_idx{:}), B(source_idx{:})), dim_pad_size);
          end
        end

        if (unpaired_complete(dim))
          source_idx = template_idx;
          if (pre)
            source_idx{dim} = 1:(A_size(dim)-1);
            dim_idx{dim}    = (1 + bits(dim)):(bits(dim) + A_size(dim) -1);
            B(dim_idx{:})   = flipped_source(source_idx{:});
          end
          if (post)
            source_idx{dim} = 2:A_size(dim);
            dim_idx{dim}    = (B_size(dim) - bits(dim) - A_size(dim) +2):(B_size(dim) - bits(dim));
            B(dim_idx{:})   = flipped_source(source_idx{:});
          end
        end

      end
    end
  end
end

%!demo
%! padarray([1,2,3;4,5,6],[2,1])
%! % pads [1,2,3;4,5,6] with a whole border of 2 rows and 1 columns of 0

%!demo
%! padarray([1,2,3;4,5,6],[2,1],5)
%! % pads [1,2,3;4,5,6] with a whole border of 2 rows and 1 columns of 5

%!demo
%! padarray([1,2,3;4,5,6],[2,1],0,'pre')
%! % pads [1,2,3;4,5,6] with a left and top border of 2 rows and 1 columns of 0

%!demo
%! padarray([1,2,3;4,5,6],[2,1],'circular')
%! % pads [1,2,3;4,5,6] with a whole 'circular' border of 2 rows and 1 columns
%! % border 'repeats' data as if we tiled blocks of data

%!demo
%! padarray([1,2,3;4,5,6],[2,1],'replicate')
%! % pads [1,2,3;4,5,6] with a whole border of 2 rows and 1 columns which
%! % 'replicates' edge data

%!demo
%! padarray([1,2,3;4,5,6],[2,1],'symmetric')
%! % pads [1,2,3;4,5,6] with a whole border of 2 rows and 1 columns which
%! % is symmetric to the data on the edge 

% Test default padval and direction
%!assert (padarray ([1;2], [1]), [0;1;2;0]);
%!assert (padarray ([3 4], [0 2]), [0 0 3 4 0 0]);
%!assert (padarray ([1 2 3; 4 5 6], [1 2]),
%!      [zeros(1, 7); 0 0 1 2 3 0 0; 0 0 4 5 6 0 0; zeros(1, 7)]);

% Test padding on 3D array
%!test
%! assert (padarray ([1 2 3; 4 5 6], [3 2 1]),
%!         cat(3, zeros(8, 7),
%!                [ [             zeros(3, 7)               ]
%!                  [zeros(2, 2) [1 2 3; 4 5 6] zeros(2, 2) ]
%!                  [             zeros(3,7)]               ],
%!                zeros (8, 7)));

% Test if default param are ok
%!assert (padarray ([1 2], [4 5]), padarray ([1 2], [4 5], 0));
%!assert (padarray ([1 2], [4 5]), padarray ([1 2], [4 5], "both"));

% Test literal padval
%!assert (padarray ([1;2], [1], i), [i; 1; 2; i]);

% Test directions (horizontal)
%!assert (padarray ([1;2], [1], i, "pre"),  [i; 1; 2]);
%!assert (padarray ([1;2], [1], i, "post"), [1; 2; i]);
%!assert (padarray ([1;2], [1], i, "both"), [i; 1; 2; i]);

% Test directions (vertical)
%!assert (padarray ([1 2], [0 1], i, "pre"),  [i 1 2]);
%!assert (padarray ([1 2], [0 1], i, "post"), [1 2 i]);
%!assert (padarray ([1 2], [0 1], i, "both"), [i 1 2 i]);

% Test vertical padsize
%!assert (padarray ([1 2], [0;1], i, "both"), [i 1 2 i]);

% Test circular padding
%!test
%! A = [1 2 3; 4 5 6];
%! B = repmat (A, 7, 9);
%! assert (padarray (A, [1 2], "circular", "pre"),  B(2:4,2:6));
%! assert (padarray (A, [1 2], "circular", "post"), B(3:5,4:8));
%! assert (padarray (A, [1 2], "circular", "both"), B(2:5,2:8));
%! % This tests when padding is bigger than data
%! assert (padarray (A, [5 10], "circular", "both"), B(2:13,3:25));

% Test circular padding with int* uint* class types
%!test
%! A = int8 ([1 2 3; 4 5 6]);
%! B = repmat (A, 7, 9);
%! assert (padarray (A, [1 2], "circular", "pre"),  B(2:4,2:6));
%! assert (padarray (A, [1 2], "circular", "post"), B(3:5,4:8));
%! assert (padarray (A, [1 2], "circular", "both"), B(2:5,2:8));
%! % This tests when padding is bigger than data
%! assert (padarray (A, [5 10], "circular", "both"), B(2:13,3:25));

% Test replicate padding
%!test
%! A = [1 2; 3 4];
%! B = kron (A, ones (10, 5));
%! assert (padarray (A, [9 4], "replicate", "pre"),  B(1:11,1:6));
%! assert (padarray (A, [9 4], "replicate", "post"), B(10:20,5:10));
%! assert (padarray (A, [9 4], "replicate", "both"), B);
%! % same with uint class
%! assert (padarray (uint8 (A), [9 4], "replicate", "pre"),  uint8 (B(1:11,1:6)));
%! assert (padarray (uint8 (A), [9 4], "replicate", "post"), uint8 (B(10:20,5:10)));
%! assert (padarray (uint8 (A), [9 4], "replicate", "both"), uint8 (B));

% Test symmetric padding
%!test
%! A    = [1:3
%!         4:6];
%! HA   = [3:-1:1
%!         6:-1:4];
%! VA   = [4:6
%!         1:3];
%! VHA  = [6:-1:4
%!         3:-1:1];
%! B    = [VHA VA VHA
%!         HA  A  HA
%!         VHA VA VHA];
%! assert (padarray (A, [1 2], "symmetric", "pre"),  B(2:4,2:6));
%! assert (padarray (A, [1 2], "symmetric", "post"), B(3:5,4:8));
%! assert (padarray (A, [1 2], "symmetric", "both"), B(2:5,2:8));
%! % same with int class
%! assert (padarray (int16 (A), [1 2], "symmetric", "pre"),  int16 (B(2:4,2:6)));
%! assert (padarray (int16 (A), [1 2], "symmetric", "post"), int16 (B(3:5,4:8)));
%! assert (padarray (int16 (A), [1 2], "symmetric", "both"), int16 (B(2:5,2:8)));

% Repeat some tests with int* uint* class types
%!assert (padarray (int8   ([1; 2]), [1]),            int8   ([0; 1; 2; 0]));
%!assert (padarray (uint8  ([3  4]), [0 2]),          uint8  ([0 0 3 4 0 0]));
%!assert (padarray (int16  ([1; 2]), [1], 4),         int16  ([4; 1; 2; 4]));
%!assert (padarray (uint16 ([1; 2]), [1], 0),         uint16 ([0; 1; 2; 0]));
%!assert (padarray (uint32 ([1; 2]), [1], 6, "post"), uint32 ([1; 2; 6]));
%!assert (padarray (int32  ([1; 2]), [1], int32 (4), "pre"), int32 ([4; 1; 2]));

% Test symmetric and reflect for multiple lengths of padding (since the way
% it's done changes based on this). By iterating from 10 on a matrix of size
% 10, we catch the cases where there's only part of the matrix on the pad, a
% single copy of the matrix, a single copy with bits of non-flipped matrix, two
%copies of the matrix (flipped and non-flipped), the two copies with bits.
%!test
%! in = [ 7  5  1  3
%!        5  3  3  4
%!        7  5  2  3
%!        6  1  3  8];
%! padded = [
%!  3  5  5  3  3  4  4  3  3  5  5  3  3  4  4  3  3  5  5  3  3  4  4  3
%!  5  7  7  5  1  3  3  1  5  7  7  5  1  3  3  1  5  7  7  5  1  3  3  1
%!  5  7  7  5  1  3  3  1  5  7  7  5  1  3  3  1  5  7  7  5  1  3  3  1
%!  3  5  5  3  3  4  4  3  3  5  5  3  3  4  4  3  3  5  5  3  3  4  4  3
%!  5  7  7  5  2  3  3  2  5  7  7  5  2  3  3  2  5  7  7  5  2  3  3  2
%!  1  6  6  1  3  8  8  3  1  6  6  1  3  8  8  3  1  6  6  1  3  8  8  3
%!  1  6  6  1  3  8  8  3  1  6  6  1  3  8  8  3  1  6  6  1  3  8  8  3
%!  5  7  7  5  2  3  3  2  5  7  7  5  2  3  3  2  5  7  7  5  2  3  3  2
%!  3  5  5  3  3  4  4  3  3  5  5  3  3  4  4  3  3  5  5  3  3  4  4  3
%!  5  7  7  5  1  3  3  1  5  7  7  5  1  3  3  1  5  7  7  5  1  3  3  1
%!  5  7  7  5  1  3  3  1  5  7  7  5  1  3  3  1  5  7  7  5  1  3  3  1
%!  3  5  5  3  3  4  4  3  3  5  5  3  3  4  4  3  3  5  5  3  3  4  4  3
%!  5  7  7  5  2  3  3  2  5  7  7  5  2  3  3  2  5  7  7  5  2  3  3  2
%!  1  6  6  1  3  8  8  3  1  6  6  1  3  8  8  3  1  6  6  1  3  8  8  3
%!  1  6  6  1  3  8  8  3  1  6  6  1  3  8  8  3  1  6  6  1  3  8  8  3
%!  5  7  7  5  2  3  3  2  5  7  7  5  2  3  3  2  5  7  7  5  2  3  3  2
%!  3  5  5  3  3  4  4  3  3  5  5  3  3  4  4  3  3  5  5  3  3  4  4  3
%!  5  7  7  5  1  3  3  1  5  7  7  5  1  3  3  1  5  7  7  5  1  3  3  1
%!  5  7  7  5  1  3  3  1  5  7  7  5  1  3  3  1  5  7  7  5  1  3  3  1
%!  3  5  5  3  3  4  4  3  3  5  5  3  3  4  4  3  3  5  5  3  3  4  4  3
%!  5  7  7  5  2  3  3  2  5  7  7  5  2  3  3  2  5  7  7  5  2  3  3  2
%!  1  6  6  1  3  8  8  3  1  6  6  1  3  8  8  3  1  6  6  1  3  8  8  3
%!  1  6  6  1  3  8  8  3  1  6  6  1  3  8  8  3  1  6  6  1  3  8  8  3
%!  5  7  7  5  2  3  3  2  5  7  7  5  2  3  3  2  5  7  7  5  2  3  3  2];
%! for ite = 1:10
%!  assert (padarray (in, [ite ite], "symmetric"), padded((11-ite):(14+ite),(11-ite):(14+ite)));
%!  assert (padarray (in, [ite ite], "symmetric", "pre"),  padded((11-ite):14,(11-ite):14));
%!  assert (padarray (in, [ite ite], "symmetric", "post"), padded(11:(14+ite),11:(14+ite)));
%! endfor

%!test
%! in = [ 7  5  4  9
%!        6  4  5  1
%!        5  3  3  3
%!        2  6  7  3];
%! padded = [
%!  3  3  3  3  5  3  3  3  3  3  5  3  3  3  3  3  5  3  3  3  3  3  5  3
%!  7  3  7  6  2  6  7  3  7  6  2  6  7  3  7  6  2  6  7  3  7  6  2  6
%!  3  3  3  3  5  3  3  3  3  3  5  3  3  3  3  3  5  3  3  3  3  3  5  3
%!  5  1  5  4  6  4  5  1  5  4  6  4  5  1  5  4  6  4  5  1  5  4  6  4
%!  4  9  4  5  7  5  4  9  4  5  7  5  4  9  4  5  7  5  4  9  4  5  7  5
%!  5  1  5  4  6  4  5  1  5  4  6  4  5  1  5  4  6  4  5  1  5  4  6  4
%!  3  3  3  3  5  3  3  3  3  3  5  3  3  3  3  3  5  3  3  3  3  3  5  3
%!  7  3  7  6  2  6  7  3  7  6  2  6  7  3  7  6  2  6  7  3  7  6  2  6
%!  3  3  3  3  5  3  3  3  3  3  5  3  3  3  3  3  5  3  3  3  3  3  5  3
%!  5  1  5  4  6  4  5  1  5  4  6  4  5  1  5  4  6  4  5  1  5  4  6  4
%!  4  9  4  5  7  5  4  9  4  5  7  5  4  9  4  5  7  5  4  9  4  5  7  5
%!  5  1  5  4  6  4  5  1  5  4  6  4  5  1  5  4  6  4  5  1  5  4  6  4
%!  3  3  3  3  5  3  3  3  3  3  5  3  3  3  3  3  5  3  3  3  3  3  5  3
%!  7  3  7  6  2  6  7  3  7  6  2  6  7  3  7  6  2  6  7  3  7  6  2  6
%!  3  3  3  3  5  3  3  3  3  3  5  3  3  3  3  3  5  3  3  3  3  3  5  3
%!  5  1  5  4  6  4  5  1  5  4  6  4  5  1  5  4  6  4  5  1  5  4  6  4
%!  4  9  4  5  7  5  4  9  4  5  7  5  4  9  4  5  7  5  4  9  4  5  7  5
%!  5  1  5  4  6  4  5  1  5  4  6  4  5  1  5  4  6  4  5  1  5  4  6  4
%!  3  3  3  3  5  3  3  3  3  3  5  3  3  3  3  3  5  3  3  3  3  3  5  3
%!  7  3  7  6  2  6  7  3  7  6  2  6  7  3  7  6  2  6  7  3  7  6  2  6
%!  3  3  3  3  5  3  3  3  3  3  5  3  3  3  3  3  5  3  3  3  3  3  5  3
%!  5  1  5  4  6  4  5  1  5  4  6  4  5  1  5  4  6  4  5  1  5  4  6  4
%!  4  9  4  5  7  5  4  9  4  5  7  5  4  9  4  5  7  5  4  9  4  5  7  5
%!  5  1  5  4  6  4  5  1  5  4  6  4  5  1  5  4  6  4  5  1  5  4  6  4];
%! for ite = 1:10
%!  assert (padarray (in, [ite ite], "reflect"), padded((11-ite):(14+ite),(11-ite):(14+ite)));
%!  assert (padarray (in, [ite ite], "reflect", "pre"),  padded((11-ite):14,(11-ite):14));
%!  assert (padarray (in, [ite ite], "reflect", "post"), padded(11:(14+ite),11:(14+ite)));
%! endfor