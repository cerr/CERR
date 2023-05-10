function fc = interleaved2complex(fi)

if ~isreal(fi)
    error('%s: Input must be real.',upper(mfilename))
end

fsize = size(fi);
fsize(1)=fsize(1)/2;

if rem(fsize(1),1)~=0
     error('%s: Wrong dimension.',upper(mfilename))
end


fc=fi(1:2:end,:,:) + 1i*fi(2:2:end,:,:);


%
%   Url: http://ltfat.github.io/doc/libltfat/modules/libphaseret/testing/mUnit/interleaved2complex.html

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

