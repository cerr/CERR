function [tc,relres,iter,xrec] = gabgrouplasso(x,g,a,M,lambda,varargin)
%-*- texinfo -*-
%@deftypefn {Function} gabgrouplasso
%@verbatim
%GABGROUPLASSO  Group LASSO regression in Gabor domain
%   Usage: [tc,xrec] = gabgrouplasso(x,g,a,M,group,lambda,C,maxit,tol)
%
%   GABGROUPLASSO has been deprecated. Please use FRANAGROUPLASSO instead.
%
%   A call to GABGROUPLASSO(x,g,a,M,lambda) can be replaced by :
%
%     F=frame('dgt',g,a,M);
%     tc=franagrouplasso(F,lambda);
%
%   Any additional parameters passed to GABGROUPLASSO can be passed to
%   FRANAGROUPLASSO in the same manner.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/deprecated/gabgrouplasso.html}
%@seealso{frame, franagrouplasso}
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

warning(['LTFAT: GABGROUPLASSO has been deprecated, please use FRANAGROUPLASSO ' ...
          'instead. See the help on FRANAGROUPLASSO for more details.']);  

F=newframe('dgt',[],g,a,M);
[tc,relres,iter,xrec] = framegrouplasso(F,lambda,varargin{:});

