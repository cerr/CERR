% LTFAT - Block processing
%
%  Zdenek Prusa, 2013 - 2018.
%
%  Basic methods
%    BLOCK          - Setup a new block-stream
%    BLOCKDEVICES   - List available audio I/O devices
%    BLOCKREAD      - Read samples from file/device
%    BLOCKPLAY      - Play block (sound output)
%    BLOCKPANEL     - Block-stream control GUI
%    BLOCKPANELGET  - Obtain parameter(s) from GUI
%    BLOCKDONE      - Closes block-stream and frees resources
%    BLOCKWRITE     - Appends data to a wav file
%
%  Block-adapted transforms
%    BLOCKFRAMEACCEL     - Prepare a frame for a block-stream processing
%    BLOCKFRAMEPAIRACCEL - Prepare a pair of frames for a block-stream processing
%    BLOCKANA            - Block analysis
%    BLOCKSYN            - Block synthesis
%
%  Running visualisation
%    BLOCKFIGURE   - Initialize figure for redrawing
%    BLOCKPLOT     - Append coefficients to the running plot
%
%  Other
%    LTFATPLAY     - Replacement for the sound command allowing selecting an output device
%
%  For help, bug reports, suggestions etc. please visit 
%  http://github.com/ltfat/ltfat/issues
%
%   Url: http://ltfat.github.io/doc/blockproc/Contents.html

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

