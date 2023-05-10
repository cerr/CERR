function sr=comp_gabreassign(s,tgrad,fgrad,a);
%COMP_GABREASSIGN  Reassign time-frequency distribution.
%   Usage:  sr = comp_gabreassign(s,tgrad,fgrad,a);
%
%   COMP_GABREASSIGN(s,tgrad,fgrad,a) will reassign the values of the positive
%   time-frequency distribution s using the instantaneous time and frequency
%   fgrad and ifdummy. The lattice is determined by the time shift a and
%   the number of channels deduced from the size of s.
%
%   See also: gabreassign
%
%   References:
%     F. Auger and P. Flandrin. Improving the readability of time-frequency
%     and time-scale representations by the reassignment method. IEEE Trans.
%     Signal Process., 43(5):1068--1089, 1995.
%     
%
%   Url: http://ltfat.github.io/doc/comp/comp_gabreassign.html

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

%   AUTHOR : Peter L. Søndergaard.
%   TESTING: OK
%   REFERENCE: OK

[M,N,W]=size(s);
L=N*a;
b=L/M;

freqpos=fftindex(M);  
tgrad=bsxfun(@plus,tgrad/b,freqpos);

timepos=fftindex(N);
fgrad=bsxfun(@plus,fgrad/a,timepos.');

tgrad=round(tgrad);
fgrad=round(fgrad);

tgrad=mod(tgrad,M);
fgrad=mod(fgrad,N);  
  
sr=zeros(M,N,W,assert_classname(s,tgrad,fgrad));

fgrad=fgrad+1;
tgrad=tgrad+1;

for w=1:W
    for ii=1:M
        for jj=1:N      
            sr(tgrad(ii,jj),fgrad(ii,jj),w) = sr(tgrad(ii,jj),fgrad(ii,jj),w)+s(ii,jj,w);
        end;
    end;  
end;




