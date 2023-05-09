function c = block_fwt( f, w, J)
%-*- texinfo -*-
%@deftypefn {Function} block_fwt
%@verbatim
%BLOCK_FWT FWT func. wrapper for a block processing
%   Usage: c = block_fwt( f, w, J);
%
%   Input parameters:
%         f     : Input data.
%         w     : Analysis Wavelet Filterbank. 
%         J     : Number of filterbank iterations.
%
%   Output parameters:
%         c      : Coefficient vector.
%
%   c = BLOCK_FWT(f,w,J) accepts suitably extended block of data f*
%   and produces correct coefficients using the SegDWT algorithm (based on
%   overlap-save block convolution) with wavelet filters defined by w 
%   and J levels. f is expected to be a column vector or a matrix and 
%   the processing is done column-wise.
%
%   Do not call this function directly. The function is called from 
%   BLOCKANA when used with frame type 'fwt' and 'segola' block transform
%   handling see BLOCKFRAMEACCEL.
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
%@strong{Url}: @url{http://ltfat.github.io/doc/blockproc/private/block_fwt.html}
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

if nargin<3
  error('%s: Too few input parameters.',upper(mfilename));
end;

% Initialize the wavelet filters structure
%h = fwtinit(h,'ana');

if any(w.a~=w.a(1))
   error('%s: Non-equal subsampling factors are not supported.',upper(mfilename));
end

w = fwtinit(w);
% Extended block length 
Ls = size(f,1);
% Low-pass filter length
m = numel(w.h{1}.h);
% Low-pass subsampling factor
a = w.a(1);
% Extension length
rred = (a^J-1)/(a-1)*(m-a);
% Block boundaries
blocksize=w.a(1)^J;
% Input signal samples to be processed

% This is effectivelly the "negative" right extension described in chapter
% 4.1.4 in the reference.
L=rred+floor((Ls-rred)/blocksize)*blocksize;

levelLen = L;
filtNo = length(w.h);
subbNo = (filtNo-1)*J+1;
Lc = zeros(subbNo,1);
runPtr = 0; 
for jj=1:J
   for ff=filtNo:-1:2
      Lc(end-runPtr) = floor((levelLen-m-1)/w.a(ff));
      runPtr = runPtr + 1;
   end
   levelLen = floor((levelLen-m-1)/w.a(1));
end
Lc(1)=levelLen; 

% 
%[Lc, L] = fwtclength(Ls,h,J,'valid');

% Crop to the right length
if(Ls>L)
   f=postpad(f,L); 
end

if Ls<rred+a^J
   error('%s: Insufficient input signal length for the %s flag. Minimum is %i.',upper(mfilename),'''valid''',rred+a^J);
end

c = comp_fwt(f,w.h,w.a,J,'valid');

% Do the cropping 
runPtr = 0; 
for jj=1:J-1
   for ff=filtNo:-1:2
      cstart = (a^(J-jj)-1)/(a-1)*(m-a);
      c{end-runPtr} = c{end-runPtr}(cstart+1:end,:);
      runPtr = runPtr + 1;
   end
end

% To the pack format
c = cell2mat(c);

