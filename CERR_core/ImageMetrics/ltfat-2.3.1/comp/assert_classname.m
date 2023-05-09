function classname = assert_classname(varargin)
%-*- texinfo -*-
%@deftypefn {Function} assert_classname
%@verbatim
% ASSERT_CLASSNAME 
%
% Returns name of the least "simplest" common data type.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/assert_classname.html}
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

% Array of data types to be checked. Ordered from the "simplest" to the
% most "complex".
typesToTest = {'single','double'}; 

if nargin==0 || isempty(varargin)
   classname = 'double';
   return;
end

if ~all(cellfun(@(vEl) isnumeric(vEl),varargin))
   error('%s: Parameters are not numeric types. ',upper(mfilename));
end

% Shortcut to double
if all(cellfun(@(vEl) isa(vEl,'double'),varargin))
   classname = 'double';
   return;
end

% Go trough all the types, halt if any of the inputs is of the specified
% type.
for ii=1:numel(typesToTest)
   if any(cellfun(@(vEl) isa(vEl,typesToTest{ii}),varargin))
      classname = typesToTest{ii};
      return;
   end
end

