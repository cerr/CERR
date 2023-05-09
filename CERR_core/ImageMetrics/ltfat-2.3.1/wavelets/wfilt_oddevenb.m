function [h,g,a,info] = wfilt_oddevenb(N)
%-*- texinfo -*-
%@deftypefn {Function} wfilt_oddevenb
%@verbatim
%WFILT_ODDEVENB  Kingsbury's symmetric odd filters
%
%   Usage: [h,g,a] = wfilt_oddevenb(N);
%
%   [h,g,a]=WFILT_ODDEVENB(N) with N in {1} returns Kingsbury's
%   odd filters.
%
%   Examples:
%   ---------
%   :
%     figure(1);
%     wfiltinfo('ana:oddevenb1');
%
%     figure(2);
%     wfiltinfo('syn:oddevenb1');
% 
%   References:
%     N. Kingsbury. Complex wavelets for shift invariant analysis and
%     filtering of signals. Applied and Computational Harmonic Analysis,
%     10(3):234 -- 253, 2001.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfilt_oddevenb.html}
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

switch(N)
 case 1
    % Example 1. from the reference. Symmetric near-orthogonal
    garr = [
             0              0
             0             -7.062639508928571e-05 
             0              0        
            -0.0017578125   1.341901506696429e-03
             0             -1.883370535714286e-03
             0.022265625   -7.156808035714285e-03
            -0.046875       2.385602678571428e-02
            -0.0482421875   5.564313616071428e-02
             0.2968750     -5.168805803571428e-02
             0.55546875    -2.997576032366072e-01
             0.2968750      5.594308035714286e-01           
            -0.0482421875  -2.997576032366072e-01
            -0.046875      -5.168805803571428e-02
             0.022265625    5.564313616071428e-02
             0              2.385602678571428e-02
            -0.0017578125  -7.156808035714285e-03
             0             -1.883370535714286e-03
             0              1.341901506696429e-03
             0              0        
             0             -7.062639508928571e-05       
    ];

    % This scaling is not in the reference paper, but it is here to be
    % consistent
    garr = garr*sqrt(2);
    %garr = normalize(garr,'energy');
    
    offset = -10;

  otherwise
        error('%s: No such filters.',upper(mfilename)); 
end

    %garr = [garr(:,3:4),garr(:,1:2)];
    modrange = (-1).^((0:size(garr,1)-1) + offset+1).';
    modrange2 = (-1).^((0:size(garr,1)-1) + offset).';
    
    harr =       [garr(:,2).*modrange2,...
                  garr(:,1).*modrange,...
                  ];
            
   
% In the biorthogonal case, the filters do not get time reversed
garr = flipud(garr);
  
htmp=mat2cell(harr,size(harr,1),ones(1,size(harr,2)));
h = cellfun(@(hEl)struct('h',hEl,'offset',offset),htmp(1:2),...
                   'UniformOutput',0);


gtmp=mat2cell(garr,size(garr,1),ones(1,size(garr,2)));

g = cellfun(@(gEl)struct('h',gEl,'offset',offset),gtmp(1:2),...
                   'UniformOutput',0);




