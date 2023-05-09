function blockdone(varargin)
%-*- texinfo -*-
%@deftypefn {Function} blockdone
%@verbatim
%BLOCKDONE  Destroy the current blockstream
%   Usage: blockdone();
%
%   BLOCKDONE() closes the current blockstream. The function resets
%   the playrec tool and clear all buffers in block_interface.
%
%   BLOCKDONE(p1,p2,...) in addition tries to call close methods on
%   all input arguments which are JAVA objects (which are passed by reference).
%   
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/blockproc/blockdone.html}
%@seealso{block}
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

% TO DO: Process additional zeros to compensate for the delay 

block_interface('clearAll');
if playrec('isInitialised')
   playrec('reset');
end
clear playrec;

for ii=1:numel(varargin)
   p = varargin{ii};
   if isjava(p)
      try
         javaMethod('close',p);
      catch
         warning(sprintf('%s: Object %i does not have a close method.',...
         upper(mfilename),ii));
      end
   elseif isstruct(p) && isfield(p,'destructor') &&...
          isa(p.destructor,'function_handle')
      p.destructor();
   end
end

