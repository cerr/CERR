function [a,info]=comp_filterbank_a(a,M,info)
%-*- texinfo -*-
%@deftypefn {Function} comp_filterbank_a
%@verbatim
%COMP_FILTERBANK_A  Return sanitized a
%   Usage:  [a,info]=comp_filterbank_a(a,M);
%   
%   [a,info]=COMP_FILTERBANK_A(a,M) returns a sanitized version of a*
%   expand to a Mx2 matrix, and update the information in info.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_filterbank_a.html}
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

% FIXME: Not sufficiently safe in the case where there is only one
% channel, or when attempting to specify a uniform filterbank with
% fractional downsampling.
%


info.isfractional=0;
info.isuniform=0;


% Sanity checks

%  All numers in a must be integers
if ~isnumeric(a) || any(a(:)<=0)
    error('%s: All subsampling factors must be positive.',upper(mfilename));
end

% Avoid a being scalar if M>1
if isscalar(a)
   a = a*ones(M,1); 
end


% One filter expect a to be a single value or a 2 element row vector
if M==1 && (size(a,1)~=1 || ~any(size(a,2)==[1,2]))
   error('%s: One channel, but more subsampling factors.',upper(mfilename));
end

% .. and sanitize if it is a column vector
if M==1 && size(a,2)==1
   a = [a,1];
end

% Two filters can have [a1,a2],[a1;a2], [a1,a1;a2,a2]
if M==2 && ~any(size(a)==2)  
   error('%s: Bad format of a.',upper(mfilename)); 
end

% .. and sanitize 
if M==2 && isvector(a)
   a = [a(:),ones(numel(a),1)];
end

% In another configuration, there is no confusion
% e.g. for M = 3, a can be:
% a = [a1,a2,a3]
% a = [a1;a2;a3]
% a = [a1,a1;a2,a2;a3,a3];

% Make column vector
if M>2 && isvector(a)
    a = a(:);
end


if isvector(a) && M~=1 && size(a,2)<2
    if numel(a)~=M
        error(['%s: The number of entries in "a" must match the number of ' ...
                'filters.'],upper(mfilename));
    end
        
    if all(a==a(1))
        info.isuniform=1;
    end;

    a=[a,ones(M,1)];
else
    if size(a,2)>2
       error(['%s: Bad format of a.'],upper(mfilename)); 
    end
    % We need to check against the case where this routine has already
    % been run
    if isequal(a(:,2),ones(M,1))
        if all(a(:,1)==a(1))
            info.isuniform=1;
        end;        
    else
        info.isfractional=1;
    end;
    
    % If the filterbank uses fractional downsampling, it cannot be
    % treated by the uniform algorithms, even though the sampling rate is uniform.
    
    % FIXME: Fractional, uniform filterbanks are not handled, they are
    % not allowed.

end;

info.a=a;


