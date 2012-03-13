function IMout = DoseScale(IMout)
% JC July 11, 2005
% To figure out whether the first 114 pbs dose distribution makes sense or
% not.
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

%load IMout_photon_114pb_July_11.mat;

max_dose = ones(1,length(IMout.beamlets));
ind_dose = ones(1,length(IMout.beamlets));
for i = 1 : length(IMout.beamlets),
  max_dose(1,i)= IMout.beamlets(i).maxInfluenceVal;
  max_dose(1,i)= max_dose(1,i) * (IMout.beams.beamletDelta_x(i) * IMout.beams.beamletDelta_y(i));
  IMout.beamlets(i).maxInfluenceVal = max_dose(1,i);
end

if (isfield(IMout, 'Errors'))

    for i = 1 : length(IMout.beamlets),
        max_dose(1,i)= IMout.Errors(i).maxInfluenceVal;
        max_dose(1,i)= max_dose(1,i) * (IMout.beams.beamletDelta_x(i) * IMout.beams.beamletDelta_y(i));
        IMout.Errors(i).maxInfluenceVal = max_dose(1,i);
    end
end


%figure; plot(max_dose(1,1:length(IMout.beamlets)))
%hold on; grid on;
%plot(IMout.beams.beamletDelta_x(1:length(IMout.beamlets)) .* IMout.beams.beamletDelta_y(1:length(IMout.beamlets)), 'r')