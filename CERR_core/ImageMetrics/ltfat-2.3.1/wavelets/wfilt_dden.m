function [h,g,a,info] = wfilt_dden(N)
%-*- texinfo -*-
%@deftypefn {Function} wfilt_dden
%@verbatim
%WFILT_DDEN  Double-DENsity DWT filters (tight frame)
%   Usage: [h,g,a] = wfilt_dden(N);
%
%   [h,g,a]=WFILT_DDEN(N) computes oversampled dyadic double-density DWT
%   filters. 
%   The redundancy of the basic filterbank is equal to 1.5.
%
%   Examples:
%   ---------
%   :
%
%     wfiltinfo('dden5');
%
%   References:
%     A. A. Petrosian and F. G. Meyer, editors. Wavelets in Signal and Image
%     Analysis: From Theory to Practice, chapter The Double Density DWT,
%     pages 39--66. Kluwer, 1 edition, 2001.
%     
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfilt_dden.html}
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


offset = [];
switch(N)
    case 1
% from the software package filters1.m
garr = [
  0.14301535070442  -0.01850334430500  -0.04603639605741
  0.51743439976158  -0.06694572860103  -0.16656124565526
  0.63958409200212  -0.07389654873135   0.00312998080994
  0.24429938448107   0.00042268944277   0.67756935957555
 -0.07549266151999   0.58114390323763  -0.46810169867282
 -0.05462700305610  -0.42222097104302   0
];
garr = flipud(garr);
offset = [-4,-2,-2];

    case 2
% from the paper Table 2.2.
garr = [
  0.14301535070442  -0.08558263399002  -0.43390145071794
  0.51743439976158  -0.30964087862262   0.73950431733582
  0.63958409200212   0.56730336474330  -0.17730428251781
  0.24429938448107   0.04536039941690  -0.12829858410007
 -0.07549266151999  -0.12615420862311   0
 -0.05462700305610  -0.09128604292445   0
];
garr = flipud(garr);
offset = [-4];
    case 3
% from the paper Table 2.3.
garr = [
  0.14301535070442  -0.04961575871056  -0.06973280238342
  0.51743439976158  -0.17951150139240  -0.25229564915399
  0.63958409200212  -0.02465426871823   0.71378970545825
  0.24429938448107   0.62884602337929  -0.39176125392083
 -0.07549266151999  -0.21760444148150   0
 -0.05462700305610  -0.15746005307660   0
];
garr = flipud(garr);
offset = [-4,-2,-2];
    case 4
% from the paper Table 2.5.
garr = [
                 0                  0                  0
  0.05857000614054  -0.01533062192062   0.00887131217814
  0.30400518363062  -0.07957295618112  -0.33001182554443
  0.60500290681752  -0.10085811812745   0.74577631077164
  0.52582892852883   0.52906821581280  -0.38690622229177
  0.09438203761968  -0.15144941570477  -0.14689062498210
 -0.14096408166391  -0.23774566907201   0.06822592840635
 -0.06179010337508  -0.05558739119206   0.04093512146217
  0.01823675069101   0.06967275075248   0
  0.01094193398389   0.04180320563276   0
];
garr = flipud(garr);
offset = [-6];
    case 5
% from the paper Table 2.6.
garr = [
                 0                  0                  0
  0.05857000614054   0.00194831075352   0.00699621691962
  0.30400518363062   0.01011262602523   0.03631357326930
  0.60500290681752   0.02176698144741   0.04759817780411
  0.52582892852883   0.02601306210369  -0.06523665620369
  0.09438203761968  -0.01747727200822  -0.22001495718527
 -0.14096408166391  -0.18498449534896  -0.11614112361411
 -0.06179010337508  -0.19373607227976   0.64842789652539
  0.01823675069101   0.66529265123158  -0.33794312751535
  0.01094193398389  -0.32893579192449   0
];
garr = flipud(garr);
offset = [-6,-2,-2];
    case 6
% from the software package filters2.m
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
offset = [-5];
    otherwise
        error('%s: No such Double Density DWT filter',upper(mfilename));
end;

g=mat2cell(garr,size(garr,1),ones(1,size(garr,2)));
if isempty(offset)
   g = cellfun(@(gEl) struct('h',gEl,'offset',-floor((length(gEl)+1)/2)),g,'UniformOutput',0);
elseif numel(offset)==1
   g = cellfun(@(gEl) struct('h',gEl,'offset',offset),g,'UniformOutput',0);
elseif isvector(offset)
   g = cellfun(@(gEl,ofEl) struct('h',gEl,'offset',ofEl),g,num2cell(offset),...
               'UniformOutput',0); 
end
h = g;
a= [2;2;2];
info.istight=1;

