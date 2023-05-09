function [h,g,a,info] = wfilt_hden(K)
%-*- texinfo -*-
%@deftypefn {Function} wfilt_hden
%@verbatim
%WFILT_HDEN  Higher DENsity dwt filters (tight frame, frame)
%   Usage: [h,g,a] = wfilt_hden(K);
%
%   [h,g,a]=WFILT_HDEN(K) with K in {1,2,3,4} returns Higher DENsity 
%   dwt filters (tight frame, frame) from the reference. The filterbanks 
%   have 3 channels and unusual non-uniform subsamplig factors [2,2,1].
%
%   Examples:
%   ---------
%   :
%     wfiltinfo('hden3');
%
%   :
%     wfiltinfo('ana:hden4');
%
%   References:
%     I. Selesnick. A higher density discrete wavelet transform. IEEE
%     Transactions on Signal Processing, 54(8):3039--3048, 2006.
%     
%     
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfilt_hden.html}
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


a= [2;2;1];
info.istight = 1;
switch(K)
case 1
% from the paper Example 1.
garr = [
    0                   0                    0 
    0.353553390593274   0.353553390593274    0.5
    0.707106781186548   0                    -0.5
    0.353553390593274   -0.353553390593274   0
];
d = [-2,-2,-2];
case 2
% from the paper Example 2.
garr = [
    0                 0                0 
    0.189604909379    0.025752563665   0.010167956157
    0.631450512121    0.075463998066   0.046750380120
    0.655505518357   -0.064333341412  -0.009172584871
    0.099615139800   -0.327704691428  -0.354664087684
    -0.163756210215   0.228185687127   0.499004628714
    -0.023958870736   0.252240693362  -0.192086292435
    0.025752563665   -0.189604909379   0
];

d = [-3,-5,-5];
case 3
% from the paper Example 3.
garr = [
   0                 0                0
   0.022033327573    0.048477254777   0.031294135831
   0.015381522616    0.019991451948   0.013248398005
  -0.088169084245   -0.304530024033  -0.311552292833
   0.051120949834    0.165478923930   0.497594326648
   0.574161374258    0.308884916012  -0.235117092484
   0.717567366340   -0.214155508410  -0.020594576659
   0.247558418377   -0.074865474330   0.015375249485
  -0.076963057605    0.028685132531   0.009751852004
  -0.048477254777    0.022033327573   0
];
 d = [-6,-4,-4];
case 4
    info.istight = 0;
    % from the paper Example 5. Is not a tight frame!
    harr = [
       0          0           0 
       0          0           0
       0.027222   0.044889    0
       0.011217   0.005671    0.027671
      -0.112709  -0.286349    0.007159 
       0.096078   0.235789   -0.277671 
       0.685299   0.235789    0.485682 
       0.685299   -0.286349  -0.277671 
       0.096078   0.005671    0.007159 
      -0.112709   0.044889    0.027671 
       0.011217   0           0 
       0.027222   0           0  
    ];
    d = [-5,-5,-5];

    harr = flipud(harr);
    h=mat2cell(harr,size(harr,1),ones(1,size(harr,2)));
    h=cellfun(@(gEl,dEl) struct('h',gEl,'offset',dEl),h,num2cell(d),...
              'UniformOutput',0);


        garr = [
            0          0          0
           -0.039237   0.023794   0.011029
           -0.073518   0.037784   0.019204
            0.181733  -0.070538  -0.020024
            0.638129  -0.253037  -0.269204
            0.638129   0.261996   0.517991
            0.181733   0.261996  -0.269204
           -0.073518  -0.253037  -0.020024
           -0.039237  -0.070538   0.019204
            0          0.037784   0.011029
            0          0.023794   0
            0          0          0
        ];   

        g=mat2cell(garr,size(garr,1),ones(1,size(garr,2)));
        g=cellfun(@(gEl,dEl) struct('h',gEl,'offset',dEl),g,num2cell(d),...
                  'UniformOutput',0);


    return;


otherwise
        error('%s: No such Higher Density Wavelet Transform Filters..',upper(mfilename));
end

%garr = flipud(harr);
g=mat2cell(garr,size(garr,1),ones(1,size(garr,2)));
g = cellfun(@(gEl,dEl) struct('h',gEl,'offset',dEl),g,num2cell(d),'UniformOutput',0);
h = g;



