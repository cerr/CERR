function [coef]=comp_sepdgtreal(f,g,a,M,phasetype)
%COMP_SEPDGTREAL  Filter bank DGT
%   Usage:  c=comp_sepdgtreal(f,g,a,M);
%  
%   This is a computational routine. Do not call it directly.
%
%   Url: http://ltfat.github.io/doc/comp/comp_sepdgtreal.html

% Copyright (C) 2005-2022 Peter L. Soendergaard <peter@sonderport.dk> and others.
% This file is part of LTFAT version 2.5.0
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

%   See help on DGT.

%   AUTHOR : Peter L. Søndergaard.

L=size(f,1);
Lwindow=size(g,1);

if Lwindow<L
    % Do the filter bank algorithm
    % Periodic boundary conditions
    coef=comp_dgtreal_fb(f,g,a,M);

else
    % Do the factorization algorithm 
    coef=comp_dgtreal_long(f,g,a,M);
end;

% Change the phase convention from frequency-invariant to
% time-invariant
if phasetype==1
    N=L/a;
    M2=floor(M/2)+1;
    
    TimeInd = (0:(N-1))*a;
    FreqInd = (0:(M2-1))/M;
         
    phase = FreqInd'*TimeInd;
    phase = exp(2*1i*pi*phase);
    coef=bsxfun(@times,coef,phase);
end;

    
    

