function [h,g,a,info] = wfilt_symdden(K)
%-*- texinfo -*-
%@deftypefn {Function} wfilt_symdden
%@verbatim
%WFILT_SYMDDEN  Symmetric Double-Density DWT filters (tight frame)
%   Usage: [h,g,a] = wfilt_symdden(K);
%
%   [h,g,a]=WFILT_SYMDDEN(K) with K in {1,2} returns oversampled
%   symmetric double-density DWT filters. 
%   The redundancy of the basic filterbank is equal to 1.5.
%
%   Examples:
%   ---------
%   :
%     wfiltinfo('symdden1');
%
%   :
%     wfiltinfo('symdden2');
%
%   References:
%     I. Selesnick and A. Abdelnour. Symmetric wavelet tight frames with two
%     generators. Appl. Comput. Harmon. Anal., 17(2):211--225, 2004.
%     
%     
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfilt_symdden.html}
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
garr = [
    0.00069616789827   0.00120643067872  -0.00020086099895
   -0.02692519074183  -0.04666026144290   0.00776855801988
   -0.04145457368921  -0.05765656504458   0.01432190717031
    0.19056483888762  -0.21828637525088  -0.14630790303599
    0.58422553883170   0.69498947938197  -0.24917440947758
    0.58422553883170  -0.24917440947758   0.69498947938197
    0.19056483888762  -0.14630790303599  -0.21828637525088
   -0.04145457368921   0.01432190717031  -0.05765656504458
   -0.02692519074183   0.00776855801988  -0.04666026144290
    0.00069616789827  -0.00020086099895   0.00120643067872
];
offset = [-5,-5,-5];
    case 2

garr = [
    0.00069616789827  -0.00014203017443   0.00014203017443
   -0.02692519074183   0.00549320005590  -0.00549320005590
   -0.04145457368920   0.01098019299363  -0.00927404236573
    0.19056483888763  -0.13644909765612   0.07046152309968
    0.58422553883167  -0.21696226276259   0.13542356651691
    0.58422553883167   0.33707999754362  -0.64578354990472
    0.19056483888763   0.33707999754362   0.64578354990472
   -0.04145457368920  -0.21696226276259  -0.13542356651691
   -0.02692519074183  -0.13644909765612  -0.07046152309968
    0.00069616789827   0.01098019299363   0.00927404236573
    0                  0.00549320005590   0.00549320005590
    0                 -0.00014203017443  -0.00014203017443
];
offset = [-5,-5,-5];
    otherwise
        error('%s: No such Double Density DWT filter',upper(mfilename));
end;

g=mat2cell(garr,size(garr,1),ones(1,size(garr,2)));
g = cellfun(@(gEl,ofEl) struct('h',gEl(:),'offset',ofEl),...
            g,num2cell(offset),'UniformOutput',0);
h = g;
a= [2;2;2];
info.istight=1;

