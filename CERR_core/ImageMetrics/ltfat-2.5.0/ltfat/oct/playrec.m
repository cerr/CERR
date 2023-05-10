%PLAYREC Multichannel non-blocking audio recording and playback
%
% Run: 
%     playrec('help') 
%
% Tho get the actual help.
%
% PLAYREC is a MEX file which means it has to be compiled in order to work.
% Please see INSTALL-Matlab or INSTALL-Octave for details. 
% 
% Originally created by Robert Humphrey (see license_playrec.txt) and 
% currently hosted at https://github.com/PlayrecForMatlab/playrec
% For further details visit the webpage or run playrec('about') and
% playrec('overview')
%
% This is however a sightly modified version doing an on-the-fly
% sample rate conversion if the target sample rate is not supported by
% the device.  
% 
%
%   Url: http://ltfat.github.io/doc/oct/playrec.html

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

