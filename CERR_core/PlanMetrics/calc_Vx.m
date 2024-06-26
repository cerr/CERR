function ans = calc_Vx(doseBinsV, volsHistV, doseCutoff, volumeType)
% Returns the volume of structure that get dose above a given dose cutoff'
% given the DVH data and the parameter percent.
%  
%  MODIFICATION ALERT:  THIS FUNCTION IS UTILIZED BY THE DREXLER CODEBASE
%
%  Usage: calc_Vx(doseBinsV, volsHistV, doseCutoff, volumeType)
%
% volumeType
%  1 = fractional
%  anything else = absolute volumes
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.

if isstruct(doseCutoff)  %for use with ROE
    temp = doseCutoff;
    volumeType = temp.volumeType.val;
    doseCutoff = temp.x.val;
end


if ~exist('volumeType')
    volumeType = 0;
end

% Add 0 to the beginning to account for the fact that the first bin must
% correspond to the entire volume.
volsHistV = [0 volsHistV(:)'];
cumVolsV = cumsum(volsHistV);
cumVols2V  = cumVolsV(end) - cumVolsV;
ind = find(doseBinsV >= doseCutoff, 1 );

if isempty(ind)
    ans = 0;
else
    ans = cumVols2V(ind);
end

% if(doseCutoff==0)
%     ans=cumVolsV(end);
% else 
%     if isempty(ind)
%         ans = 0;
%     else
%         ans = cumVols2V(ind);
%     end
% end  

if(volumeType == 1)
    ans = ans/cumVolsV(end);
else
    %warning('Vx is being calculated in absolute terms.');
end

%% ------ TESTING----
%1. for testing when BMI=22 and for NTCP=0.5, V99 = 107.1067cc ----
%ans = ans * 107.1067/cumVolsV(end);

%2. for testing when BMI=22 and for NTCP=0.1, V99 = 1.2753cc ----
%ans = ans * 1.2753/cumVolsV(end);
%-------------------------------------------------------------------

return;

