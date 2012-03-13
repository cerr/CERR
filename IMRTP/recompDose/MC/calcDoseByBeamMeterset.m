function [dose3Dsum] = calcDoseByBeamMeterset(planC, nhist, batch);
% JC Aug 30 2006
% Weigh the dose calculated by BeamMeterset.
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

indexS = planC{end};

if ischar(nhist)
    nhist = str2num(nhist)
end
if ischar(batch)
    batch = str2num(batch)
end
%endnhist = 4000000;
%batch = 1; 

weight = ones(planC{indexS.beams}.FractionGroupSequence.Item_1.NumberOfBeams, 1);

for indexBeam = 1: planC{indexS.beams}.FractionGroupSequence.Item_1.NumberOfBeams
 
    if isfield(planC{indexS.beams}.FractionGroupSequence.Item_1.ReferencedBeamSequence.(['Item_', num2str(indexBeam)]),'BeamMeterset') 
    weight(indexBeam) = planC{indexS.beams}.FractionGroupSequence.Item_1.ReferencedBeamSequence.(['Item_', num2str(indexBeam)]).BeamMeterset;
    if (weight(indexBeam) ~= 0)  %If BeamMeterset == 0. do nothing.    
    filename = ['dose3D_',num2str(indexBeam),'_', num2str(nhist), '_', num2str(batch)];
    load(filename, 'dose3D'); %load(savefile, 'v1')  % Use when filename is stored in a variable
        if indexBeam ==1
            dose3Dsum = weight(indexBeam)*dose3D;
        else
            dose3Dsum = dose3Dsum + weight(indexBeam)*dose3D;
        end
    end
    end
end

% JC. Dec 18, 2007 
% Multiply the total dose by the number of fractions:
NumberFractions = planC{indexS.beams}.FractionGroupSequence.Item_1.NumberOfFractionsPlanned;
dose3Dsum = NumberFractions * dose3Dsum;
return;