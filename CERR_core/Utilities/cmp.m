function v = cmp(a,op,b,about)
%Overloaded method for comparison of a with b using the
%operator 'op'.  Works for string or non-string comparisons.
%Ex.:
% a = {1 , 2, 3, 4}
%
% cmp(a, '==', 3)
%» cmp(a, '==', 3)
%
%ans =
%
%     0     0     1     0
%
%J.O.Deasy, June 2000.
%Latest modifications:  JOD, 20 Feb 03, case insensitive tests.
%ex:  cmp('{'this','THIS'},'==','this')
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.

v = zeros(1,length(a));

if nargin == 4 & strcmpi(about,'nocase') %case insensitive tests
  for i = 1 : length(a)
    a{i} = lower(a{i});
  end
  b = lower(b);
end


if ~isstr(b)

    switch op

    case '=='

        for i = 1 : length(a)
           v(i) = [a{i} == b];
        end

    case '~='

        for i = 1 : length(a)
           v(i) = [a{i} ~= b];
        end


    case '<='

        for i = 1 : length(a)
           v(i) = [a{i} <= b];
        end

    case '=<'

        for i = 1 : length(a)
           v(i) = [a{i} <= b];
        end


    case '<'

        for i = 1 : length(a)
           v(i) = [a{i} < b];
        end

    case '>'

        for i = 1 : length(a)
           v(i) = [a{i} > b];
        end


    case '>='

        for i = 1 : length(a)
           v(i) = [a{i} >= b];
        end

    case '=>'

        for i = 1 : length(a)
           v(i) = [a{i} >= b];
        end

    otherwise
        error('Wrong operator in cmp!')


    end

else



    switch op

    case '=='

        for i = 1 : length(a)
           v(i) = strcmp(a{i},b);
        end

    case '~='

        for i = 1 : length(a)
           v(i) = ~strcmp(a{i}, b);
        end

    otherwise
        error('Wrong operator in cmp!')


    end


end

