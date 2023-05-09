function H = comp_nyquistfilt(wintype,fs,chan_max,freqtoscale,scaletofreq,bwmul,bins,Ls)
%-*- texinfo -*-
%@deftypefn {Function} comp_nyquistfilt
%@verbatim
%COMP_NYQUISTFILT high-pass filter for warped filter banks
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_nyquistfilt.html}
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

    kk = chan_max;
    while scaletofreq(kk-bwmul) < fs/2;
      kk = kk+1/bins;
    end
    Maxfilt = kk;
    
    Minpos = ceil(Ls/fs*scaletofreq(chan_max+1/bins-bwmul));
    samples = freqtoscale((Minpos-1:floor(Ls/2))*fs/Ls);
    
    FILTS = zeros(round(bins*(Maxfilt-chan_max)),numel(samples));
    for kk = 1:size(FILTS,1)
       FILTS(kk,:) = firwin(wintype,(samples-(chan_max+kk/bins))/(2*bwmul));
    end
    H = zeros(2*numel(samples)-1,1);
    H(1:numel(samples)) = sqrt(sum(abs(FILTS.^2),1));
    H(numel(samples)+1:end) = H(numel(samples)-1:-1:1); 

