function dosefilenames = find_pinnacle_dose_filenames(dosedim,planPath)
%
%	dosefilenames = find_pinnacle_dose_filenames(dosedim)
%
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

%APA
% planPath = 'C:\Projects\PinnacleReader\PinnacleWholePatientPlanExample\Plan_2\plan.Trial.binary.*';
files = dir(planPath);
%files = dir('plan.Trial.binary.*');
N = length(files);

dosefilenames = cell(0);

for k = 1:N
	if files(k).bytes == prod(dosedim)*4
		if isempty(dosefilenames)
			dosefilenames{1} = files(k).name;
		else
			dosefilenames{end+1,1} = files(k).name;
		end
	end
end

% The number of binary dose files should be equal to 2 * number of beams


