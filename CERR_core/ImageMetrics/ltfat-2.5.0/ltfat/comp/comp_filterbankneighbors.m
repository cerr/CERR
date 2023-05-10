function [NEIGH,posInfo] = comp_filterbankneighbors(a,M,N,do_real)

%this function is called by filterbankconstphase
%
%   Url: http://ltfat.github.io/doc/comp/comp_filterbankneighbors.html

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

chanStart = [0;cumsum(N)];

NEIGH = zeros(6,chanStart(end));

%Horizontal neighbors
for kk = 1:M
  NEIGH(1,chanStart(kk)+1) = chanStart(kk)+2; 
  NEIGH(1,chanStart(kk+1)) = chanStart(kk+1)-1;
  NEIGH(1:2,chanStart(kk)+(2:N(kk)-1)) = chanStart(kk)+[(1:N(kk)-2);(3:N(kk))];
end

%Vertical neighbors
%Set time distance limit
LIM = .8;

%One channel higher
for kk = 1:M-1
  aTemp = a(kk)/a(kk+1);
  POSlow = chanStart(kk+1)+min(max(0,ceil(((0:N(kk)-1)-LIM)*aTemp)),N(kk+1)-1);
  POShigh = chanStart(kk+1)+max(0,min(floor(((0:N(kk)-1)+LIM)*aTemp),N(kk+1)-1));
  
%   for ll = 1:N(kk)
%     tmpIdx = (POSlow(ll):POShigh(ll))+1;    
%     NEIGH((5:4+numel(tmpIdx)),chanStart(kk)+ll) = tmpIdx.';
%   end

NEIGH(5,chanStart(kk)+(1:N(kk))) = POSlow + 1;
NEIGH(6,chanStart(kk)+(1:N(kk))) = POShigh + 1;
end
if ~do_real
    aTemp = a(M)/a(1);
    POSlow = chanStart(1)+min(max(0,ceil(((0:N(M)-1)-LIM)*aTemp)),N(1)-1);
    POShigh = chanStart(1)+max(0,min(floor(((0:N(M)-1)+LIM)*aTemp),N(1)-1));
    
    NEIGH(5,chanStart(M)+(1:N(M))) = POSlow + 1;
    NEIGH(6,chanStart(M)+(1:N(M))) = POShigh + 1;
end
NEIGH(6,NEIGH(6,:)==NEIGH(5,:)) = 0;

%One channel lower
for kk = 2:M
  aTemp = a(kk)/a(kk-1);  
  POSlow = chanStart(kk-1)+min(max(0,ceil(((0:N(kk)-1)-LIM)*aTemp))',N(kk-1)-1);
  POShigh = chanStart(kk-1)+max(0,min(floor(((0:N(kk)-1)+LIM)*aTemp),N(kk-1)-1)');
  
%   for ll = 1:N(kk)
%     tmpIdx = (POSlow(ll):POShigh(ll))+1;    
%     NEIGH((3:2+numel(tmpIdx)),chanStart(kk)+ll) = tmpIdx.';
%   end
NEIGH(3,chanStart(kk)+(1:N(kk))) = POSlow + 1;
NEIGH(4,chanStart(kk)+(1:N(kk))) = POShigh + 1;
end
if ~do_real
    aTemp = a(1)/a(M);
    POSlow = chanStart(M)+min(max(0,ceil(((0:N(1)-1)-LIM)*aTemp)),N(M)-1);
    POShigh = chanStart(M)+max(0,min(floor(((0:N(1)-1)+LIM)*aTemp),N(M)-1));
    
    NEIGH(3,chanStart(1)+(1:N(1))) = POSlow + 1;
    NEIGH(4,chanStart(1)+(1:N(1))) = POShigh + 1;
end
NEIGH(4,NEIGH(4,:)==NEIGH(3,:)) = 0;


posInfo = zeros(chanStart(end),2);
for kk = 1:M
    posInfo(chanStart(kk)+(1:N(kk)),:) = [(kk-1)*ones(N(kk),1),(0:N(kk)-1)'.*a(kk)];
end
posInfo = posInfo.';


