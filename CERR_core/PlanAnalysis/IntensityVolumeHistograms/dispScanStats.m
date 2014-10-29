function dispScanStats(scanBinsV, volHistV, name, nameVol, planC, indexS, opt)
%Command line display of basic scan statistics
%scanBinsV is a vector of the midpoint scanBin values.
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

% ESPEZI OCT 2014 added nameVol, changed order of printed items and added dose name

ud = get(findobj('Tag', 'IVHGui'),'userdata');
scanNum = get(ud.af.handles.scan,'value');
imageType = planC{indexS.scan}(scanNum).scanInfo(1).imageType;

if strcmpi(imageType,'CT')
    units = 'HU';
elseif strcmpi(imageType,'PET')
    units = 'SUV';
else
    units = '';
end

switch lower(opt)

  case 'standardscan'
    disp('-----------------------')
    disp('')
    disp(['Structure is:  ' name])

    totalVol = sum(volHistV);
    disp(['Total volume is:  ' num2str(totalVol) ' cubic cm.'])

    disp(['Scan name is:  ' nameVol])

    meanD = sum(scanBinsV.*volHistV)/sum(volHistV);
    disp(['Mean ' imageType ' ' units ' is:  ' num2str(meanD)])

    ind = max(find([volHistV~=0]));
    maxD = scanBinsV(ind);
    disp(['Max' imageType ' ' units ' is:  ' num2str(maxD)])

    ind = min(find([volHistV~=0]));
    minD = scanBinsV(ind);
    disp(['Min ' imageType ' ' units ' is:  ' num2str(minD)])
    disp('')
    disp('-----------------------')

  case 'dshscan'

    disp('-----------------------')
    disp('')
    disp(['Structure is:  ' name])

    areaV = volHistV;  %actually areas, not volumes.
    scansV = scanBinsV;

    totalArea = sum(areaV);
    disp(['Total surface area is:  ' num2str(totalArea) ' square cm.'])

    disp(['Scan name is:  ' nameVol])

    meanD = sum(scansV.*areaV)/sum(areaV);
    disp(['Mean surface ' imageType ' ' units ' is:  ' num2str(meanD)])

    maxScan = max(scansV);
    disp(['Max ' imageType ' ' units ' is:  ' num2str(maxScan)])

    minScan = min(scansV);
    disp(['Min ' imageType ' ' units ' is:  ' num2str(minScan)])
    disp('')
    disp('-----------------------')

end
