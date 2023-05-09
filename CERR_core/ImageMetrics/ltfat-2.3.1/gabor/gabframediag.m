function d=gabframediag(g,a,M,L,varargin)
%-*- texinfo -*-
%@deftypefn {Function} gabframediag
%@verbatim
%GABFRAMEDIAG  Diagonal of Gabor frame operator
%   Usage:  d=gabframediag(g,a,M,L);
%           d=gabframediag(g,a,M,L,'lt',lt);
%
%   Input parameters:
%         g     : Window function.
%         a     : Length of time shift.
%         M     : Number of channels.
%         L     : Length of transform to do.
%         lt    : Lattice type (for non-separable lattices).
%   Output parameters:
%         d     : Diagonal stored as a column vector
%
%   GABFRAMEDIAG(g,a,M,L) computes the diagonal of the Gabor frame operator
%   with respect to the window g and parameters a and M. The
%   diagonal is stored a as column vector of length L.
%
%   The diagonal of the frame operator can for instance be used as a
%   preconditioner.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/gabframediag.html}
%@seealso{dgt}
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

if nargin<4
  error('%s: Too few input parameters.',upper(mfilename));
end;

definput.keyvals.lt=[0 1];
[flags,kv]=ltfatarghelper({},definput,varargin);

% ----- step 2a : Verify a, M and get L

Luser=dgtlength(L,a,M,kv.lt);
if Luser~=L
    error(['%s: Incorrect transform length L=%i specified. Next valid length ' ...
           'is L=%i. See the help of DGTLENGTH for the requirements.'],...
          upper(mfilename),L,Luser);
end;


%% ----- step 3 : Determine the window 

[g,info]=gabwin(g,a,M,L,kv.lt,'callfun',upper(mfilename));

if L<info.gl
  error('%s: Window is too long.',upper(mfilename));
end;

%%  compute the diagonal 

glong2=abs(fir2long(g,L)).^2;
N=L/a;

d=zeros(L,1,assert_classname(glong2));

% The diagonal is a-periodic, so compute a single period by summing up
% glong2 in slices. 
d=repmat(sum(reshape(glong2,a,N),2),N,1)*M;



