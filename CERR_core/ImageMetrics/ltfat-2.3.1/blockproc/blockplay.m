function blockplay(f)
%-*- texinfo -*-
%@deftypefn {Function} blockplay
%@verbatim
%BLOCKPLAY Schedules block to be played
%   Usage: blockplay(L)
%       
%   Input parameters:
%      f    : Samples.
%
%   Function schedules samples in f to be played. Since playrec handles
%   playing and recording in a single command, the actual relay of samples
%   to playrec is done in the next call of BLOCKREAD.
%   In case no audio output is expected (in the rec only mode), 
%   the function does nothing.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/blockproc/blockplay.html}
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


complainif_notenoughargs(nargin,1,'BLOCKPLAY');

source = block_interface('getSource');

if ( iscell(source) && strcmp(source{1},'rec')) || ...
   strcmp(source,'rec')
   % Do nothing in rec only mode.
   return; 
   % error('%s: Blocks cannot be played in the rec only mode.',upper(mfilename));
end

% Reformat f if necessary
f = comp_sigreshape_pre(f,'BLOCKPLAY',0);

block_interface('setToPlay',f);

