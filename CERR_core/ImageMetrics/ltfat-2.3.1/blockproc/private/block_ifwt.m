function f = block_ifwt(c,w,J,Lb)
%-*- texinfo -*-
%@deftypefn {Function} block_ifwt
%@verbatim
%BLOCK_IFWT IFWT wrapper for blockstream processing
%   Usage: f=block_ifwt(c,w,J,Lb);
%
%   f = BLOCK_IFWT(c,w,J,Lb) returns block of data reconstructed
%   from coefficients c using the SegDWT algorithm (based on overlap-add
%   block convolution) with wavelet filters w and J levels. The 
%   reconstructed block contains overlap to the next block(s).
%
%   Do not call this function directly. It is called from BLOCKSYN when
%   using 'fwt' frame type with 'segola' block transform handling (see 
%   BLOCKFRAMEACCEL).
%
%   Function should be independent of block_interface.
%
%
%   References:
%     Z. Průša. Segmentwise Discrete Wavelet Transform. PhD thesis, Brno
%     University of Technology, Brno, 2012.
%     
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/blockproc/private/block_ifwt.html}
%@seealso{block, block_ifwt}
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

if nargin<4
   error('%s: Too few input parameters.',upper(mfilename));
end;


w = fwtinit(w);

%Lc = fwtclength(Lb,g,J,'per');
filtNo = length(w.g);
subbNo = (filtNo-1)*J+1;
Lc = zeros(subbNo,1);
runPtr = 0; 
levelLen = Lb;
  for jj=1:J
     for ff=filtNo:-1:2
        Lc(end-runPtr) = floor(levelLen/w.a(ff));
        runPtr = runPtr + 1;
     end
     levelLen = ceil(levelLen/w.a(1));
  end
Lc(1)=levelLen; 
c = mat2cell(c,Lc);

m = numel(w.g{1}.h);
a = w.a(1);
% Do the extension 
cstartZeros = zeros(numel(Lc),1);
filtNo = length(w.g);
runPtr = 0; 
for jj=1:J-1
   for ff=filtNo:-1:2
      cstartZeros(end-runPtr) = (a^(J-jj)-1)/(a-1)*(m-a);
      runPtr = runPtr + 1;
   end
end 

% Pad with zeros ()
cext = cellfun(@(cEl,cZEl) zeros(size(cEl,1)+cZEl,size(cEl,2)),c,num2cell(cstartZeros),'UniformOutput',0);
for jj=1:numel(cext)
   cext{jj}(end+1-size(c{jj},1):end,:) = c{jj};
end

Ls = Lb + (a^(J)-1)/(a-1)*(m-a);

%% ----- Run computation 
f = comp_ifwt(cext,w.g,w.a,J,Ls,'valid');

