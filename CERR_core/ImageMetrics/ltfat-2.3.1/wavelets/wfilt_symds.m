function [h,g,a,info] = wfilt_symds(K)
%-*- texinfo -*-
%@deftypefn {Function} wfilt_symds
%@verbatim
%WFILT_SYMDS  Symmetric wavelets dyadic sibling
%   Usage: [h,g,a] = wfilt_symds(K);
%
%   [h,g,a]=WFILT_SYMDS(K) with K in {1,2,3,4,5} returns symmetric 
%   dyadic sibling wavelet frame filters from the reference.
%
%   The returned filterbank has redundancy equal to 2 and it does not form
%   a tight frame.
%
%   Examples:
%   ---------
%   :
%     wfiltinfo('ana:symds3');
%
%   :
%     wfiltinfo('syn:symds3');
% 
%   References:
%     F. Abdelnour. Symmetric wavelets dyadic sibling and dual frames. Signal
%     Processing, 92(5):1216 -- 1229, 2012. [1]http ]
%     
%     
%     References
%     
%     1. http://www.sciencedirect.com/science/article/pii/S0165168411003963
%     
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfilt_symds.html}
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
a = [2;2;2;2];

switch(K)
 case 1
    % Example 1. Not a tight frame!
    harr = [
        -5    3     -1   0
        -7    17    -2   -1
        35    11    -3   -2
        105   -31   12   -3
        105   -31   -3   12
        35    11    -2   -3
        -7    17    -1   -2
        -5    3     0    -1
    ];
    harr(:,1)=harr(:,1)*sqrt(2)/2^8;
    harr(:,2)=harr(:,2)/2^7;
    harr(:,3:4)=harr(:,3:4)/2^4;
    
    hoffset = [-4,-4,-4,-4];

    garr = [
        0    0     0    0
        -3   -5    0    -1
        5    -13   -1   -2
        30   18    -2   6
        30   18    6    -2
        5    -13   -2   -1
        -3   -5    -1   0
        0    0     0    0
    ]; 
    garr(:,1)=garr(:,1)*sqrt(2)/2^6;
    garr(:,2)=garr(:,2)/2^6;
    garr(:,3:4)=garr(:,3:4)/2^3;
    goffset = [-4,-4,-4,-4];

case 2
    % Example 2. Not a tight frame!
    harr = [
       0                  0                  0           0 
       0                  0                  0           0 
       0                  -sqrt(2)/2^5       -1/2^3      0        
       -sqrt(2)/2^5       -4*sqrt(2)/2^5     -2/2^3      -1/2^3 
       0                  sqrt(2)/2^5        6/2^3       -2/2^3
       9*sqrt(2)/2^5      8*sqrt(2)/2^5      -2/2^3      6/2^3 
       16*sqrt(2)/2^5     sqrt(2)/2^5        -1/2^3      -2/2^3
       9*sqrt(2)/2^5      -4*sqrt(2)/2^5     0           -1/2^3
       0                  -sqrt(2)/2^5       0           0
       -sqrt(2)/2^5       0                  0           0
    ];
    hoffset = [-3,-5,-5,-5];
    

    garr = [
           -sqrt(2)/2^5       0                  0           1/2^6 
           0                  -sqrt(2)/2^5       1/2^6       2/2^6
           9*sqrt(2)/2^5      -4*sqrt(2)/2^5     2/2^6       0 
           16*sqrt(2)/2^5     sqrt(2)/2^5        0           -18/2^6
           9*sqrt(2)/2^5      8*sqrt(2)/2^5      -18/2^6     30/2^6
           0                  sqrt(2)/2^5        30/2^6      -18/2^6
           -sqrt(2)/2^5       -4*sqrt(2)/2^5     -18/2^6     0
           0                  -sqrt(2)/2^5       0           2/2^6
           0                  0                  2/2^6       1/2^6
           0                  0                  1/2^6       0
         ];   
    goffset = [-3,-5,-5,-5];
    
case 3
    % Example 3. Not a tight frame!
    harr = [
       0                       35*sqrt(2)/2^12       0.003385355341795    0    
       35*sqrt(2)/2^12         185*sqrt(2)/2^12      0.011757930078244    0.003385355341795
       -45*sqrt(2)/2^12        208*sqrt(2)/2^12      0.038383315957975    0.011757930078244
       -252*sqrt(2)/2^12       -648*sqrt(2)/2^12     0.127426546608992    0.038383315957975
       420*sqrt(2)/2^12        -706*sqrt(2)/2^12     -0.112865104706813   0.127426546608992
       1890*sqrt(2)/2^12       706*sqrt(2)/2^12      -0.710280910094278   -0.112865104706813
       1890*sqrt(2)/2^12       648*sqrt(2)/2^12      0.710280910094278    -0.710280910094278
       420*sqrt(2)/2^12        -208*sqrt(2)/2^12     0.112865104706813    0.710280910094278
       -252*sqrt(2)/2^12       -185*sqrt(2)/2^12     -0.127426546608992   0.112865104706813
       -45*sqrt(2)/2^12        -35*sqrt(2)/2^12      -0.038383315957975   -0.127426546608992
       35*sqrt(2)/2^12         0                     -0.011757930078244   -0.038383315957975
       0                       0                     -0.003385355341795   -0.011757930078244
       0                       0                     0                    -0.003385355341795
    ];
    hoffset = [-7,-7,-7,-5];

    garr = [
            0	                  0	                   0	                   0
            0	                  0	                   0	                   0
            35*sqrt(2)/2^12	      0	                   0	                   -0.043136204314165
            -45*sqrt(2)/2^12	  35*sqrt(2)/2^12	   -0.043136204314165	   -0.022725249453801
            -252*sqrt(2)/2^12	  185*sqrt(2)/2^12	   -0.022725249453801	   -0.016002341917868
            420*sqrt(2)/2^12	  208*sqrt(2)/2^12	   -0.016002341917868	   0.463586703221768
            1890*sqrt(2)/2^12	  -648*sqrt(2)/2^12	   0.463586703221768	   -0.463586703221768
            1890*sqrt(2)/2^12	  -706*sqrt(2)/2^12	   -0.463586703221768	   0.016002341917868
            420*sqrt(2)/2^12	  706*sqrt(2)/2^12	   0.016002341917868	   0.022725249453801
            -252*sqrt(2)/2^12	  648*sqrt(2)/2^12	   0.022725249453801	   0.043136204314165
            -45*sqrt(2)/2^12	  -208*sqrt(2)/2^12	   0.043136204314165	   0
            35*sqrt(2)/2^12	      -185*sqrt(2)/2^12	   0	                   0
            0	                  -35*sqrt(2)/2^12	   0	                   0
%            0	                  0	                   0	                   0
      ];  
      goffset = [-7,-7,-7,-5];

case 4
    % Example 4. Not a tight frame!
    harr = [
       0       99        0.0008317898274     0 
       99      837       0.00527762349601    0.0008317898274
       351     2630      0.01705880266437    0.00527762349601 
       -286    2778      0.02633268946272    0.01705880266437
       -2574   -3195     0.03753999326488    0.02633268946272    
       -1287   -10429    -0.00195902477575   0.03753999326488   
       10725   -6348     -0.0711227784702    -0.00195902477575
       25740   6348      -0.54534348089652   -0.0711227784702    
       25740   10429     0.54534348089652    -0.54534348089652  
       10725   3195      0.0711227784702     0.54534348089652   
       -1287   -2778     0.00195902477575    0.0711227784702
       -2574   -2630     -0.03753999326488   0.00195902477575
       -286    -837      -0.02633268946272   -0.03753999326488
       351     -99       -0.01705880266437   -0.02633268946272
       99       0         -0.00527762349601   -0.01705880266437
       0       0         -0.0008317898274    -0.00527762349601
       0       0         0                   -0.0008317898274
  ];
   harr(:,1:2)=harr(:,1:2)*sqrt(2)/2^16;
   hoffset = [-9,-9,-9,-7];

    garr = [
         0        0        0                  0 
         0        0        0                  0
         99       0        0                  -0.0054868984046
         351      99       -0.0054868984046   -0.03102895771555
         -286     837      -0.03102895771555  -0.05109382225012
         -2574    2630     -0.05109382225012  -0.05321999995116
         -1287    2778     -0.05321999995116   0.1089262550963
         10725    -3195    0.1089262550963     0.6365944921083
         25740    -10429   0.6365944921083     -0.6365944921083
         25740    -6348    -0.6365944921083    -0.1089262550963
         10725    6348     -0.1089262550963    0.05321999995116
         -1287    10429    0.05321999995116    0.05109382225012
         -2574    3195     0.05109382225012    0.03102895771555
         -286     -2778    0.03102895771555    0.0054868984046
         351      -2630    0.0054868984046     0
         99       -837     0                   0
         0        -99      0                   0

      ];   
     garr(:,1:2)=garr(:,1:2)*sqrt(2)/2^16;
     goffset = [-9,-9,-9,-7];

case 5
    % Example 5. Not a tight frame!
    harr = [
        -5   35     0      5
        -7   -35    35     -7
        35   -665   -35    -35
        105  665    -665   105
        105  665    665    -105
        35   -665   665    35
        -7   -35    -665   7
        -5   35     -35    -5
        0    0      35     0
   ];
   harr(:,[1 4])=harr(:,[1 4])*sqrt(2)/2^8;
   harr(:,2:3)=harr(:,2:3)*sqrt(2)/2^12;
   hoffset = [-5,-5,-5,-5];


    garr = [
        0    0    0     0
        -5   0    -1    -5
        -7   -1   -1    7
        35   -1   2     35
        105  2    2     -105
        105  2    -1    105
        35   -1   -1    -35
        -7   -1   0     -7
        -5   0    0     5
      ];   
     garr(:,[1 4])=garr(:,[1 4])*sqrt(2)/2^8;
     garr(:,2:3)=garr(:,2:3)*sqrt(2)/2^3;
     goffset = [-5,-5,-5,-5];

  otherwise
        error('%s: No such filters.',upper(mfilename)); 

end

g=mat2cell(garr,size(garr,1),ones(1,size(garr,2)));
g = cellfun(@(gEl,ofEl) struct('h',gEl(:),'offset',ofEl),...
            g,num2cell(goffset),'UniformOutput',0);

h=mat2cell(flipud(harr),size(harr,1),ones(1,size(harr,2)));
h = cellfun(@(hEl,ofEl) struct('h',hEl(:),'offset',ofEl),...
            h,num2cell(hoffset),'UniformOutput',0);


