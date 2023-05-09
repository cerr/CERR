function H = comp_zerofilt(wintype,fs,chan_min,freqtoscale,scaletofreq,bwmul,bins,Ls)
%-*- texinfo -*-
%@deftypefn {Function} comp_zerofilt
%@verbatim
%COMP_ZEROFILT low-pass filter for warped filter banks
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_zerofilt.html}
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

    kk = chan_min;
    while scaletofreq(kk+bwmul) > fs/Ls 
      kk = kk-1/bins;
    end
    Minfilt = kk;
    
    Maxpos = floor(Ls/fs*scaletofreq(chan_min-1/bins+bwmul));
    samples = freqtoscale((0:Maxpos)*fs/Ls);
    if samples(1) == -Inf
        samples(1) = samples(2);
    end
    
    FILTS = zeros(round(bins*(chan_min-Minfilt)),numel(samples));
    for kk = 1:size(FILTS,1)
       FILTS(kk,:) = firwin(wintype,(samples-(chan_min-kk/bins))/(2*bwmul));
    end
    H = zeros(2*numel(samples)-1,1);
    H(numel(samples):end) = sqrt(sum(abs(FILTS.^2),1));
    H(1:numel(samples)-1) = H(end:-1:numel(samples)+1); 

