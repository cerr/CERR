function [h,g,a,info] = wfilt_ddena(N)
%-*- texinfo -*-
%@deftypefn {Function} wfilt_ddena
%@verbatim
%WFILT_DDENA  Double-Density Dual-Tree DWT filters 
%
%   Usage: [h,g,a] = wfilt_ddena(N);
%
%   [h,g,a]=wfil_ddena(N) with N in {1,2} returns filters suitable
%   for dual-tree double density complex wavelet transform tree A. 
%
%   Examples:
%   ---------
%   :
%     wfiltinfo('ddena1');
%
%   References:
%     I. Selesnick. The double-density dual-tree DWT. Signal Processing, IEEE
%     Transactions on, 52(5):1304--1314, May 2004.
%     
%     
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfilt_ddena.html}
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
a = [2;2;2];

switch(N)
 case 1
    % Example 1. from the reference. 
    harr = [
        0.0691158205  0.0000734237  0.0001621689  
        0.3596612703  0.0003820788  0.0008438861  
        0.6657851023 -0.0059866448 -0.0136616968  
        0.4659189433 -0.0343385512 -0.0781278793 
       -0.0191014398 -0.0554428419 -0.0840435464  
       -0.1377522956  0.0018714327  0.2230705831 
       -0.0087922813  0.1386271745  0.3945086960 
        0.0194794983  0.3321168878 -0.6566499317  
        0.0000995795 -0.5661664438  0.2138977202  
       -0.0002006352  0.1888634841  0            
    ];
    d = [-3,-7,-7];
case 2
    % Example 2. From the reference. 
    harr = [
         0.0116751500  0.0000002803  0.0000009631  
         0.1121045343  0.0000026917  0.0000092482  
         0.3902035988 -0.0000945824 -0.0003285657  
         0.6376600221 -0.0009828317 -0.0034113692 
         0.4515927116 -0.0032260080 -0.0098485834  
        -0.0177905271 -0.0033984723  0.0011435281 
        -0.1899509889  0.0053478454  0.0535846285 
        -0.0363317137  0.0269410607  0.0710003404 
         0.0511638041  0.0499929334 -0.0732656061 
         0.0130979774 -0.0076424664 -0.2335672955 
        -0.0081410874 -0.2115533011 -0.0478802585
        -0.0016378610 -0.1367235355  0.5808457358
         0.0005650673  0.6180972127 -0.4014544851
         0.0000043492 -0.3981725189  0.0631717194
        -0.0000014745  0.0614116921  0           
    ];
    d = [-4,-12,-12];

  otherwise
        error('%s: No such filters.',upper(mfilename)); 

end

htmp=mat2cell(harr,size(harr,1),ones(1,size(harr,2)));

h = cellfun(@(hEl,dEl)struct('h',hEl,'offset',dEl),...
                 htmp(1:3),num2cell(d(1:3)),...
                 'UniformOutput',0);

g = h;





