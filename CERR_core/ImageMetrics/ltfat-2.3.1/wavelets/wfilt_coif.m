function [h,g,a,info] = wfilt_coif(K)
%-*- texinfo -*-
%@deftypefn {Function} wfilt_coif
%@verbatim
%WFILT_COIF Coiflets
%
%   Usage: [h,g,a] = wfilt_coif(K);
%
%   [h,g,a]=WFILT_COIF(K) with K in {1,2,3,4,5} returns a Coiflet
%   filters of order 2K the number of vanishing moments of both the
%   scaling and the wavelet functions.
%
%   Values are taken from table 8.1 from the reference. REMARK: There is 
%   a typo in 2nd element for K==1.
%
%   Examples:
%   ---------
%   :
%     wfiltinfo('coif2');
%
%   :
%     wfiltinfo('coif5');
% 
%   References:
%     I. Daubechies. Ten Lectures on Wavelets. Society for Industrial and
%     Applied Mathematics, Philadelphia, PA, USA, 1992.
%     
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfilt_coif.html}
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

% AUTHOR: Zdenek Prusa

info.istight = 1;
a = [2;2];

switch(K)
    case 1
       hlp = [
             -0.011070271529
             -0.051429728471
              0.272140543058
              0.602859456942
              0.238929728471
             -0.051429728471
            ];
       d = [-3,-3];
    case 2 
       hlp = [
             -0.000509505399
             -0.001289203356
              0.003967883613
              0.016744410163
             -0.042026480461
             -0.054085607092
              0.294867193696
              0.574682393857
              0.273021046535
             -0.047639590310
             -0.029320137980
              0.011587596739           
             ];
       d = [-7,-5]; 
    case 3 
       hlp = [
             -0.000024465734
             -0.000050192775
              0.000329665174
              0.000790205101
             -0.001820458916
             -0.006369601011
              0.011229240962
              0.024434094321
             -0.058196250762
             -0.050770140755
              0.302983571773
              0.561285256870
              0.286503335274
             -0.043220763560
             -0.046507764479
              0.016583560479
              0.005503126709
             -0.002682418671   
             ];
       d= [-11,-7];
    case 4 
       hlp = [
             -0.000001262175
             -0.000002304942
              0.000022082857
              0.000044080354
             -0.000183829769
             -0.000416500571
              0.000895594529
              0.002652665946
             -0.004001012886
             -0.010756318517
              0.017735837438
              0.027813640153
             -0.068038127051
             -0.047112738865
              0.307157326198
              0.553126452562
              0.293667390895
             -0.039652648517
             -0.057464234429
              0.018867235378
              0.011362459244
             -0.005194524026
             -0.001152224852
              0.000630961046   
             ];
       d= [-15,-9];
    case 5 
       hlp = [
             -0.0000000673
             -0.0000001184
              0.0000014593
              0.0000026408
             -0.0000150720
             -0.0000292321
              0.0000993776 
              0.0002137298
             -0.0004512270
             -0.0011758222
              0.0017206547
              0.0047830014
             -0.0064800900
             -0.0139736879
              0.0231107770
              0.0291958795
             -0.0746522389
             -0.0438660508
              0.3097068490 
              0.5475054294
              0.2980923235
             -0.0368000736
             -0.0649972628
              0.0199178043
              0.0165520664
             -0.0071637819
             -0.0029411108
              0.0015402457
              0.0002535612
             -0.0001499638    
             ];
       d= [-19,-11];
  otherwise
        error('%s: No such COIFLET filters.',upper(mfilename)); 

end

hlp = hlp*sqrt(2);

harr = [hlp, (-1).^(0:size(hlp,1)-1).'.*flipud(hlp)];

h=mat2cell(harr,size(harr,1),ones(1,size(harr,2)));
h=cellfun(@(hEl,dEl) struct('h',hEl(:),'offset',dEl),h,num2cell(d),...
          'UniformOutput',0);

g = h;




