function [h,g,a,info] = wfilt_oddevena(N)
%-*- texinfo -*-
%@deftypefn {Function} wfilt_oddevena
%@verbatim
%WFILT_ODDEVENA  Kingsbury's symmetric even filters
%
%   Usage: [h,g,a] = wfilt_oddevena(N);
%
%   [h,g,a]=WFILT_ODDEVENA(N) with N in {1} returns Kingsbury's
%   even filters.
%
%   Examples:
%   ---------
%   :
%     figure(1);
%     wfiltinfo('ana:oddevena1');
%
%     figure(2);
%     wfiltinfo('syn:oddevena1');
% 
%   References:
%     N. Kingsbury. Complex wavelets for shift invariant analysis and
%     filtering of signals. Applied and Computational Harmonic Analysis,
%     10(3):234 -- 253, 2001.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfilt_oddevena.html}
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
             0           0           
             0           0           
             0          -0.0004645   
             0           0.0013349  
            -0.0058109   0.0022006  
             0.0166977  -0.0130127  
            -0.0000641   0.0015360  
            -0.0834914   0.0869008  
             0.0919537   0.0833552  
             0.4807151  -0.4885957  
             0.4807151   0.4885957     
             0.0919537  -0.0833552 
            -0.0834914  -0.0869008  
            -0.0000641  -0.0015360  
             0.0166977   0.0130127  
            -0.0058109  -0.0022006  
             0          -0.0013349  
             0           0.0004645  
             0           0         
             0           0          
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




