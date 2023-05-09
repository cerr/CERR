function failed=demo_blockproc_header(demo_name,demo_nargin)
failed = 0;
if demo_nargin<1
   fprintf(['\n%s:\nTo run the demo, use one of the following:\n\n',...
          '%s(''gspi.wav'') to play gspi.wav (any wav file will do).\n',...
          '%s(''dialog'') to choose the wav file via file chooser dialog GUI.\n',...
          '%s(f,''fs'',fs) to play from a column vector f using sampling frequency fs.\n',...
          '%s(''playrec'') to record from a mic and play simultaneously.\n\n',...
          'Avalable input and output devices can be listed by |blockdevices|.\n',...
          'Particular device can be chosen by passing additional key-value pair ''devid'',devid.\n',...
          'Output channels of the device cen be selected by additional key-value pair ''playch'',[ch1,ch2].\n',...
          'Input channels of the device cen be selected by additional key-value pair ''recch'',[ch1].\n\n',...
          ]...
          ,upper(demo_name),demo_name,demo_name,demo_name,demo_name);
    failed=1;
end

try
   playrec('isInitialised');
catch
   error('%s: playrec or portaudio are not properly compiled. ',demo_name);
end


%-*- texinfo -*-
%@deftypefn {Function} demo_blockproc_header
%@verbatim
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/demo_blockproc_header.html}
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

