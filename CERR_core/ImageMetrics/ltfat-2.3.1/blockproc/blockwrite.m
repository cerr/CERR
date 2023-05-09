function blockwrite(f)
%-*- texinfo -*-
%@deftypefn {Function} blockwrite
%@verbatim
%BLOCKWRITE  Append block to an existing file
%   Usage: blockwrite(f);
%
%   Input parameters:
%      f    : Block stream input.
%
%   Function appends f to a existing file. The file must have been
%   explicitly defined as the 'outfile' parameter of BLOCK prior
%   calling this function. If not, the function does nothing.
%
%   The function expect exactly the same format of f as is returned by
%   BLOCKREAD.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/blockproc/blockwrite.html}
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

% Authors: Bjoern Ohl, Zdenek Prusa

complainif_notenoughargs(nargin,1,'BLOCKWRITE');

filestruct = block_interface('getOutFile');

if isempty(filestruct)
   % Do nothing if the file was not setup in block.
   return;
   %error('%s: Output file was not specified in block function.',...
   %      upper(mfilename));
end

filename = filestruct.filename;


% Reformat f if necessary
f = comp_sigreshape_pre(f,'BLOCKPLAY',0);

[L, W] = size(f);

Wread = filestruct.Nchan;

if Wread ~= W
    error(['%s: %s was initialized to work with %i channels but', ...
           ' only %i provided. '],upper(mfilename),filename,Wread,W);
end


if W>2
    error('%s: Cannot work with more than 2 channels.',upper(mfilename));
end


% prepare data depending on mono/stereo:
if W == 2           % stereo
  f = f.';
  f = f(:);
end


% flength = dlength + 36;
% We need to read one field from the header and
% update two.
fid = fopen(filename,'r+');

fseek(fid,40,-1);
dataLenInBytes = fread(fid,1,'uint32');
dataLenInBytes = dataLenInBytes + filestruct.alignment*L;
fileLenInBytes = dataLenInBytes + 36;

try
    if fseek(fid,4,-1) ~= 0
        error('d');
    end
    if fwrite(fid,fileLenInBytes,'uint32')<=0
        error('d');
    end

    if fseek(fid,40,-1)~=0
         error('d');
    end
    if fwrite(fid,dataLenInBytes,'uint32') <=0
         error('d');
    end
catch
    % We have to check whether the header was modified properly.
    error(['%s: An error has ocurred when modifying header of the ',...
          ' wav file. The file might be unreadable. Consider',...
          ' starting over.'],upper(mfilename));

end
fclose(fid);

% And now we can append the actual data
fid = fopen(filename,'a');
%write data into file (amplified by 2^15 to suit int16-range (from -2^15 to +2^15):

maxval = 1-(1/2^16);
minval = -1;

% Allow clipping since it is hard to do some sensible normalization.
f(f >= maxval)  = maxval;
f(f <= minval)  = minval;


% clipping check:
%if (max(tempvec) >= maxval) || (min(tempvec) <= minval)
    %We have no way how to find out how to properly normalize in blocks
    %warning('Clipping! Audio data limited to [-1, +1)');
%end

fwrite(fid, f*2^15, 'int16');
fclose(fid);    %close file

