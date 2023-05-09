function [f,L,Ls,W,dim,permutedsize,order]=assert_sigreshape_pre(f,L,dim,callfun)
%-*- texinfo -*-
%@deftypefn {Function} assert_sigreshape_pre
%@verbatim
%ASSERT_SIGRESHAPE_PRE  Preprocess and handle dimension input.
%
%   Input parameters:
%      f            : signal, possibly ND-array
%      L            : L parameter
%      dim          : dim parameter
%      callfun      : Name of calling function
%   Output parameters:
%      f            : Input signal as matrix
%      L            : Verified L
%      Ls           : Length of signal along dimension to be processed
%      W            : Number of transforms to do.
%      dim          : Verified dim
%      permutedsize : pass to assert_sigreshape_post
%      order        : pass to assert_sigreshape_post
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/assert_sigreshape_pre.html}
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
  
  
if ~isnumeric(f)
  error('%s: The input must be numeric.',callfun);
end;

D=ndims(f);

% Dummy assignment.
order=1;

if isempty(dim)
  dim=1;

  if sum(size(f)>1)==1
    % We have a vector, find the dimension where it lives.
    dim=find(size(f)>1);
  end;

else
  if (numel(dim)~=1 || ~isnumeric(dim))
    error('%s: dim must be a scalar.',callfun);
  end;
  if rem(dim,1)~=0
    error('%s: dim must be an integer.',callfun);
  end;
  if (dim<1) || (dim>D)
    error('%s: dim must be in the range from 1 to %d.',callfun,D);
  end;  

end;

if (numel(L)>1 || ~isnumeric(L))
  error('%s: L must be a scalar.',callfun);
end;
if (~isempty(L) && rem(L,1)~=0)
  error('%s: L must be an integer.',callfun);
end;


if dim>1
  order=[dim, 1:dim-1,dim+1:D];

  % Put the desired dimension first.
  f=permute(f,order);

end;

Ls=size(f,1);

% If L is empty it is set to be the length of the transform.
if isempty(L)
  L=Ls;
end;  

% Remember the exact size for later and modify it for the new length
permutedsize=size(f);
permutedsize(1)=L;
  
% Reshape f to a matrix.
if ~isempty(f)
  f=reshape(f,size(f,1),numel(f)/size(f,1));
end;
W=size(f,2);






