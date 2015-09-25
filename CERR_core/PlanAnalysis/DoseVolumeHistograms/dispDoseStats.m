function doseStat = dispDoseStats(doseBinsV, volHistV, name, nameVol, planC, indexS, opt)
%Command line display of basic dose statistics
%doseBinsV is a vector of the midpoint doseBin values.
%volHistV is either a histogram of volumes or surface areas.
%LM: 14 Oct 02, JOD.
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

switch lower(opt)

  case 'standarddose'
    disp('-----------------------')
    disp('')
    disp(['Structure is:  ' name])

    totalVol = sum(volHistV);
    disp(['Total volume is:  ' num2str(totalVol) ' cubic cm.'])

    disp(['Dose map name is:  ' nameVol])

    meanD = sum(doseBinsV(:).*volHistV(:))/sum(volHistV);
    disp(['Mean dose is:  ' num2str(meanD)])

    ind = max(find([volHistV~=0]));
    maxD = doseBinsV(ind);
    disp(['Max dose is:  ' num2str(maxD)])

    ind = min(find([volHistV~=0]));
    minD = doseBinsV(ind);
    
    disp(['Min dose is:  ' num2str(minD)])
    disp('')
    disp('-----------------------')
    
    doseStat.volume = totalVol;

  case 'dshdose'

    disp('-----------------------')
    disp('')
    disp(['Structure is:  ' name])

    areaV = volHistV;  %actually areas, not volumes.
    dosesV = doseBinsV;

    totalArea = sum(areaV);
    disp(['Total surface area is:  ' num2str(totalArea) ' square cm.'])
    
    disp(['Dose map name is:  ' nameVol])

    meanD = sum(dosesV(:).*areaV(:))/sum(areaV);
    disp(['Mean surface dose is:  ' num2str(meanD)])

    maxD = max(dosesV);
    disp(['Max dose is:  ' num2str(maxD)])

    minD = min(dosesV);
    
    disp(['Min dose is:  ' num2str(minD)])
    disp('')
    disp('-----------------------')
    
    doseStat.volume = totalArea;

end

doseStat.min    = minD;
doseStat.mean   = meanD;
doseStat.max    = maxD;
