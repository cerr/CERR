%-*- texinfo -*-
%@deftypefn {Function} demo_nextfastfft
%@verbatim
%DEMO_NEXTFASTFFT  Next fast FFT number
%
%   This demo shows the behaviour of the NEXTFASTFFT function.
%
%   Figure 1: Benchmark of the FFT routine
%
%      The figure shows the sizes returned by the NEXTFASTFFT function
%      compared to using nextpow2. As can be seen, the NEXTFASTFFT
%      approach gives FFT sizes that are much closer to the input size.
%
%   Figure 2: Efficiency of the table
%
%      The figure show the highest output/input ratio for varying input
%      sizes. As can be seen, the efficiency is better for larger input
%      values, where the output size is at most a few percent larger than
%      the input size.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/demos/demo_nextfastfft.html}
%@seealso{nextfastfft}
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

% Range to use for testing.
% It is important for this script that
% range_max = 2^nextpow2(range_max) = nextfastfft(range_max), so it must
% be a power of 2.
range_min=100;
range_max=1024;
r=range_min:range_max;

% r2 contains the next higher sizes using nextpow2
r2=2.^nextpow2(r);

% r3 contains the next higher sizes using nextfastfft
r3=nextfastfft(r);

figure(1);
plot(r,r,r,r2,r,r3);
xlabel('Input size.');
ylabel('FFT size.');
legend('Same size','nextpow2','nextfastfft','Location','SouthEast');

%% Efficiency analysis of the table
[dummy,table]=nextfastfft(1);

eff=table(2:end)./(table(1:end-1)+1);

figure(2);
semilogx(table(2:end),eff);
xlabel('Input size.');
ylabel('Output/input ratio.');
mean(eff)

