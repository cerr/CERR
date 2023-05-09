function ltfatplay(source,varargin)
%-*- texinfo -*-
%@deftypefn {Function} ltfatplay
%@verbatim
%LTFATPLAY Play data samples or a wav file
%   Usage: ltfatplay('file.wav')
%          ltfatplay(data,'fs',fs)
%          ltfatplay(...,'devid',devid)
%
%
%   LTFATPLAY('file.wav') plays a wav file using the default sound device.
%
%   LTFATPLAY('file.wav','devid',devid) plays a wav file using the sound
%   device with id devid. A list of available devices can be obtained by 
%   BLOCKDEVICES.
%
%   LTFATPLAY(data,'fs',fs,...) works entirely similar, but data is
%   expected to be a vector of length L or a LxW matrix with
%   columns as individual channels and fs to be a sampling rate to be used.
%   When no sampling rate is specified, 44.1 kHz is used.
%
%   In addition, individual channels of the output sound device can be
%   selected by using an additional key-value pair
%
%   'playch',playch
%      A vector of channel indexes starting at 1.
%
%   This function has the advantage over sound and soundsc that one can 
%   directly specify output device chosen from BLOCKDEVICES. Similar
%   behavior can be achieved using audioplayer and audiodevinfo but
%   only in Matlab. Audioplayer is not yet supported in Octave.
%   
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/blockproc/ltfatplay.html}
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

%   Author: Zdenek Prusa

% Initialize block stream
block(source,varargin{:});

sourceHandle = block_interface('getSource');

% Allow playing data and wav files only
if ~isa(sourceHandle,'function_handle')
    error('%s: Specified source cannot be played.',upper(mfilename));
end

% Make the vector safe
Ls = block_interface('getLs');
Lssafe = max([256,Ls(1)]);
f = postpad(sourceHandle(1,Ls(1)),Lssafe);

% If one channel is used, broadcast it to all output channels
chanList = block_interface('getPlayChanList');
if size(f,2)==1
    f = repmat(f,1,numel(chanList));
end

% Finally play it at once
playrec('play',f,chanList);




