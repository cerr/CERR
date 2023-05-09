function [h,g,a,info] = wfilt_symorth(N)
%-*- texinfo -*-
%@deftypefn {Function} wfilt_symorth
%@verbatim
%WFILT_SYMORTH  Symmetric nearly-orthogonal and orthogonal nearly-symmetric
%
%   Usage: [h,g,a] = wfilt_symorth(N);
%
%   [h,g,a]=WFILT_SYMORTH(N) with Nin {1,2,3} returns orthogonal
%   near-symmetric (N==1) and symmetric near-orthogonal (N==[2,3])
%   wavelet filters from the reference.
%
%   The filters exhibit a coiflet-like behavior i.e. the scaling filter
%   has vanishing moments too.    
%
%   Examples:
%   ---------
%   :
%     wfiltinfo('ana:symorth2');
%
%   :
%     wfiltinfo('syn:symorth2');
% 
%   References:
%     F. Abdelnour and I. W. Selesnick. Symmetric nearly orthogonal and
%     orthogonal nearly symmetric wavelets. The Arabian Journal for Science
%     and Engineering, 29(2C):3 -- 16, 2004.
%     
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfilt_symorth.html}
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

info.istight = 0;
a = [2;2];


offset = [];
switch(N)
case 1
    % Example 3. From the reference. Orthogonal near-symmetric
    % K=2 wanishing moments
    A = -sqrt(2)/4+sqrt(30)/16;
    hlp = [-sqrt(2)/16,... 
            sqrt(2)/16,...
            A+sqrt(2)/2,...
            A+sqrt(2)/2,... 
            sqrt(2)/16,...
           -sqrt(2)/16,...
           -A,...
           -A...
           ].';
       
    harr = [flipud(hlp), (-1).^(1:numel(hlp)).'.*hlp];  
    
    garr = harr;   
    info.istight = 1;
    offset = [-5,-3];

case 2
    % Example 2. From the reference. Symmetric near-orthogonal
    % K=3 wanishing moments
    hlp = [
         -0.0019128844
          0.0033707110
          0.0092762126
         -0.0855138167
          0.0851905285
          0.6966960301
          0.6966960301
          0.0851905285
         -0.0855138167
          0.0092762126
          0.0033707110
         -0.0019128844
    ];


    glp = [
          0.0025454063
          0.0044852837
          0.0037033492
         -0.0855138167
          0.0851905285
          0.6966960301
          0.6966960301
          0.0851905285
         -0.0855138167
          0.0037033492
          0.0044852837
          0.0025454063
         ];   
    harr = [hlp, (-1).^(0:numel(glp)-1).'.*flipud(glp)];
    garr = [glp, (-1).^(0:numel(hlp)-1).'.*flipud(hlp)];
    offset = [-6,-6];
case 3
    % Example 1. from the reference. Symmetric near-orthogonal
    % K=5 vanishing moments (both low and high pass)
    % L=8 first zero derivatives of frequency response ar omega=0
    hlp = [
         0.0001605988        
         0.0002633873        
        -0.0028105671        
        -0.0022669755     
         0.0246782363    
        -0.0061453735       
        -0.1137025792        
         0.1226794070        
         0.6842506470
         0.6842506470
         0.1226794070
        -0.1137025792
        -0.0061453735
         0.0246782363
        -0.0022669755
        -0.0028105671
         0.0002633873
         0.0001605988
    ];

    glp = [
         0.0002809102
        -0.0004607019
        -0.0014760379
        -0.0016765216
         0.0192309116
        -0.0001723898
        -0.1099707039
         0.1091804942
         0.6921708203
         0.6921708203
         0.1091804942
        -0.1099707039
        -0.0001723898
         0.0192309116
        -0.0016765216
        -0.0014760379
        -0.0004607019
         0.0002809102
    ]; 
    harr = [hlp, (-1).^(1:numel(glp)).'.*glp];
    garr = [glp, (-1).^(1:numel(hlp)).'.*hlp];
    
    offset = [-9,-9];
  otherwise
        error('%s: No such filters.',upper(mfilename)); 

end

h=mat2cell(harr,size(harr,1),ones(1,size(harr,2)));
h=cellfun(@(hEl,offEl) struct('h',hEl(:),'offset',offEl),h,num2cell(offset),'UniformOutput',0);

g=mat2cell(garr,size(garr,1),ones(1,size(garr,2)));
g=cellfun(@(gEl,offEl) struct('h',gEl(:),'offset',offEl),g,num2cell(offset),'UniformOutput',0);



