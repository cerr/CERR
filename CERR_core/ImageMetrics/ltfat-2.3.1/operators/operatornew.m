function Op=operatornew(otype,varargin)
%-*- texinfo -*-
%@deftypefn {Function} operatornew
%@verbatim
%OPERATORNEW  Construct a new operator
%   Usage: F=operatornew(otype,...);
%
%   Op=OPERATORNEW(otype,...) constructs a new operator object Op of type
%   otype. Arguments following otype are specific to the type of operator
%   chosen.
%
%   Frame multipliers
%   -----------------
%
%   OPERATORNEW('framemul',Fa,Fs,s) constructs a frame multiplier with
%   analysis frame Fa, synthesis frame Fs and symbol s. See the help on
%   FRAMEMUL.
%
%   Spreading operators
%   -------------------
%
%   OPERATORNEW('spread',s) constructs a spreading operator with symbol
%   s. See the help on SPREADOP.
%  
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/operators/operatornew.html}
%@seealso{operator, ioperator}
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

  
if nargin<2
  error('%s: Too few input parameters.',upper(mfilename));
end;

if ~ischar(otype)
  error(['%s: First agument must be a string denoting the type of ' ...
         'frame.'],upper(mfilename));
end;

otype=lower(otype);

switch(otype)
  case 'framemul'
    Op.Fa=varargin{1};
    Op.Fs=varargin{2};
    Op.s =varargin{3};
    Op.L =framelengthcoef(Op.Fs,size(Op.s,1));
  case 'spread'
    Op.s =varargin{1};
    Op.L =length(Op.s);
  otherwise
    error('%s: Unknows operator type: %s',upper(mfilename),otype);  
end;

Op.type=otype;

