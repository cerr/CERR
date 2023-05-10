function coef=framecoef2native(F,coef)
%FRAMECOEF2NATIVE  Convert coefficients to native format
%   Usage: coef=framecoef2native(F,coef);
%
%   FRAMECOEF2NATIVE(F,coef) converts the frame coefficients coef into 
%   the native coefficient format of the frame. The frame object F must 
%   have been created using FRAME.
%
%   See also: frame, framenative2coef, framecoef2tf
%
%   Url: http://ltfat.github.io/doc/frames/framecoef2native.html

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
  
complainif_notenoughargs(nargin,2,'FRAMECOEF2NATIVE');
complainif_notvalidframeobj(F,'FRAMECOEF2NATIVE');

[MN,W]=size(coef);

% .coef2native field is not mandatory since for some frames, both
% coefficient formats are identical
if isfield(F,'coef2native')
    coef=F.coef2native(coef,size(coef));
end;

