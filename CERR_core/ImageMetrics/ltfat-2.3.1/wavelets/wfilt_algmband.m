function [h,g,a,info] = wfilt_algmband(K)
%-*- texinfo -*-
%@deftypefn {Function} wfilt_algmband
%@verbatim
%WFILT_ALGMBAND  An ALGebraic construction of orthonormal M-BAND wavelets with perfect reconstruction
%   Usage: [h,g,a] = wfilt_algmband(K);
%
%   [h,g,a]=WFILT_ALGMBAND(K) with K in {1,2} returns wavelet filters
%   from the reference paper. The filters are 3-band (K==1) and 4-band 
%   (K==2) with critical subsampling.
%
%   Examples:
%   ---------
%   :
%     wfiltinfo('algmband1');  
%
%   :
%     wfiltinfo('algmband2');   
%
%   References:
%     T. Lin, S. Xu, Q. Shi, and P. Hao. An algebraic construction of
%     orthonormal M-band wavelets with perfect reconstruction. Applied
%     mathematics and computation, 172(2):717--730, 2006.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfilt_algmband.html}
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


switch(K)
   case 1
   % from the paper Example 1.
      garr = [
              0.33838609728386 -0.11737701613483 0.40363686892892
              0.53083618701374 0.54433105395181 -0.62853936105471
              0.72328627674361 -0.01870574735313 0.46060475252131
              0.23896417190576 -0.69911956479289 -0.40363686892892
              0.04651408217589 -0.13608276348796 -0.07856742013185
             -0.14593600755399 0.42695403781698 0.24650202866523
             ];
      a= [3;3;3];
      offset = [-3,-3,-3];
   case 2
      garr = [
              0.0857130200  -0.1045086525 0.2560950163  0.1839986022
              0.1931394393  0.1183282069  -0.2048089157 -0.6622893130
              0.3491805097  -0.1011065044 -0.2503433230 0.6880085746
              0.5616494215  -0.0115563891 -0.2484277272 -0.1379502447
              0.4955029828  0.6005913823  0.4477496752  0.0446493766
              0.4145647737  -0.2550401616 0.0010274000  -0.0823301969
              0.2190308939  -0.4264277361 -0.0621881917 -0.0923899104
             -0.1145361261 -0.0827398180 0.5562313118  -0.0233349758
             -0.0952930728 0.0722022649  -0.2245618041 0.0290655661
             -0.1306948909 0.2684936992  -0.3300536827 0.0702950474
             -0.0827496793 0.1691549718  -0.2088643503 0.0443561794
              0.0719795354  -0.4437039320 0.2202951830  -0.0918374833
              0.0140770701  0.0849964877  0.0207171125  0.0128845052
              0.0229906779  0.1388163056  0.0338351983  0.0210429802
              0.0145382757  0.0877812188  0.0213958651  0.0133066389
             -0.0190928308 -0.1152813433 -0.0280987676 -0.0174753464
             ];
       a= [4;4;4;4];
       offset = [-12,-8,-8,-12];
  otherwise
        error('%s: No such orthonormal M-band wavelet filter bank.',upper(mfilename));
end

g=mat2cell(flipud(garr),size(garr,1),ones(1,size(garr,2)));
g = cellfun(@(gEl,offEl) struct('h',gEl,'offset',offEl),g,num2cell(offset),...
            'UniformOutput',0);

h = g;
info.istight=1;

