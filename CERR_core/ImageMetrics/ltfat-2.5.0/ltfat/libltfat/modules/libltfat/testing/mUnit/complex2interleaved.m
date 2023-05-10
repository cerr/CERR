function fi = complex2interleaved(fc)

if ~isnumeric(fc)
    error('%s: Input must be numeric.',upper(mfilename))
end

fsize = size(fc);
fsize(1)=fsize(1)*2;

fi = zeros(fsize,'like',fc);

fi(1:2:end,:,:) = real(fc);

if ~isreal(fc)
    fi(2:2:end,:,:) = imag(fc);
end
%
%   Url: http://ltfat.github.io/doc/libltfat/modules/libltfat/testing/mUnit/complex2interleaved.html

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
end
