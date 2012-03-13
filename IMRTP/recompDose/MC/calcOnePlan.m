function calcOnePlan (leak, spectrum_File, planC_File, nhist, OutputError, numBeams, PBMaxWidth, gradsense, numCPUs);
% JC Feb 27, 06
% calculate the dose for each beam, for a whole plan, on the designized
% number of CPU.
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

% How to use.
% calcOnePlan 0.033 photon18MV.spectrum LungCCC_nhist2M.mat 250000 0 6 20 26 1

if ischar(numCPUs)
    numCPUs = str2num(numCPUs)
end

if ischar(numBeams)
    numBeams = str2num(numBeams)
end

% Other input arguments can be char. the called function will handle this
% properply.

if (numCPUs ~= 1);
    error('Only implemented to run on a single CPU.');
else

    h = waitbar(0,'Please wait...');
    for i = 1 : numBeams
        %Format to call DPMpc for each beam.
        %DPMpcStandAlongJingOneBeam3(leak, spectrum_File, planC_File, nhist, OutputError, whichBeam, PBMaxWidth, gradsense, batch )
        DPMpcStandAlongJingOneBeam3 leak spectrum_File planC_File nhist OutputError i PBMaxWidth gradsense batch
        waitbar(i/numBeams,h, [num2str(numBeams), 'beams total. Now beam ', num2str(i),' is done']);
    end
    close(h);

end
