function f=assert_sigreshape_post(f,dim,permutedsize,order)
%ASSERT_SIGRESHAPE_POST  Restore dimension input.
%
%   Input parameters:
%      f            : Input signal as matrix
%      dim          : Verified dim
%      permutedsize : pass to assert_sigreshape_post
%      order        : pass to assert_sigreshape_post
%   Output parameters:
%      f            : signal, possibly ND-array
%
%   ASSERT_SIGRESHAPE_POST works in conjunction with
%   assert_sigreshape_pre and restores the original
%   dimensions of the input array
%
%   Url: http://ltfat.github.io/doc/comp/assert_sigreshape_post.html

% Copyright (C) 2005-2022 Peter L. Soendergaard <peter@sonderport.dk> and others.
% This file is part of LTFAT version 2.5.0
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


% Restore the original, permuted shape.
f=reshape(f,permutedsize);

if dim>1
  % Undo the permutation.
  f=ipermute(f,order);
end;
