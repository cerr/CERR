function test_failed = test_blocprocoffline()


%-*- texinfo -*-
%@deftypefn {Function} test_blocprocoffline
%@verbatim
% Scanario 1) Block reading from a wav and block writing to a wav
%             
%             
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_blocprocoffline.html}
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
inName = 'test_in.wav';
outName = 'test_out.wav';
f = 2*rand(44100,1)*0.9-1;
wavwsave(f,44100,inName);

fs=block(inName,'offline','outfile',outName);

flag = 1;
while flag
   [fb,flag] = blockread();
   blockwrite(fb/2);
end




% Scanario 2) blockwrite from vector to wav
%             
%             


f = gspi;
f2 = 2*rand(numel(f),1)*0.9-1;

fs = block([f,f2],'fs',44100,'offline','outfile',outName);

flag = 1;
while flag
   [fb,flag] = blockread(44100);
   blockwrite(fb/2);
end




delete(inName);
delete(outName);

