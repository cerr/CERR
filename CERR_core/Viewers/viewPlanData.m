% View and printout beam geometry
%
% Latest modifications  Shunde 8/25/05
%                       KU  10/10/05 Several changes.
%                       KU  12/1/07  Added statement that plan data is not available when beam
%                                    geometry cell is empty.
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

global stateS planC

indexS = planC{end};
ind = 'beamGeometry';
num = stateS.doseSet;
ind2 = getfield(indexS,ind);

if isempty(stateS.doseSet)
    return;
end

% get the current plan ID
ID = planC{indexS.dose}(stateS.doseSet).fractionGroupID;
diary plandata.txt;
disp(['Plan data printed on: ' datestr(now, 'mm/dd/yyyy HH:MM:SS AM')]);
disp('===============================================');
disp(['Institution: ' planC{1,1}.institution]);
try
    try
        disp(['Study Created on: ' planC{indexS.dose}(num).DICOMHeaders.StudyDate]);
    catch
        disp(['Study Created on: ' planC{indexS.dose}(num).DICOMHeaders{1,1}.StudyDate]);
    end
catch
    if ischar(planC{1,1}.dateCreated)
        disp(['Study Created on: ' planC{1,1}.dateCreated]);
    else
        disp(['Study Created on: ']);
    end
end

disp('===============================================')
if isnumeric(planC{indexS.dose}(num).patientName)
   disp(['Patient Name: ' num2str(planC{indexS.dose}(num).patientName)]);
elseif ischar(planC{indexS.dose}(num).patientName)
   disp(['Patient Name: ' planC{indexS.dose}(num).patientName]);
end

disp(['Current Treatment Plan ID: ' num2str(stateS.doseSet)]);
disp(['Fraction Group ID: ' ID]);
disp('===============================================')

nbeams = 0;
for i = 1:length(planC{1,ind2}) 
    if ischar(planC{1,ind2}(1,i).fractionGroupID)
        idString = (planC{1,ind2}(1,i).fractionGroupID);
    else
        idString = num2str(planC{1,ind2}(1,i).fractionGroupID);
    end
    if strcmpi(idString, ID)
        nbeams = nbeams + 1;
    end
end

if nbeams ~= 0
    disp(['This plan has ' num2str(nbeams),' fields.']);
elseif isempty(planC{ind2})
    disp('Plan data is not available for this study.');
else
    disp('No plan data exists for this plan.  This may be'); 
    disp('because it is a sum or difference plan. The'); 
    disp('plan data can always be viewed for the individual'); 
    disp('plans.');
end
disp('===============================================')

for i = 1:length(planC{1,ind2}) 
    
    % check Fraction Group ID
    if ischar(planC{1,ind2}(1,i).fractionGroupID)
        idString = (planC{1,ind2}(1,i).fractionGroupID);
    else
        idString = num2str(planC{1,ind2}(1,i).fractionGroupID);
    end

    if strcmpi(idString, ID)
        % beam number
        disp(['Beam Number: ' num2str(planC{1,ind2}(1,i).beamNumber)]);     
        % beam description
        disp(['Beam Description: ' planC{1,ind2}(1,i).beamDescription]);
        % beam modality
        disp(['Beam Modality: ' planC{1,ind2}(1,i).beamModality]);
        % beam energy MeV
        disp(['Beam Energy MeV: ' num2str(planC{1,ind2}(1,i).beamEnergyMeV)]);
        % beam type
        disp(['Beam Type: ' planC{1,ind2}(1,i).beamType]);
        % nominal isocenter distance
        disp(['Nominal Isocenter Distance: ' num2str(planC{1,ind2}(1,i).nominalIsocenterDistance)]);

        file = planC{1,ind2}(1,i).file;
        format compact
        % collimator type
        disp(['Collimator Type: ' planC{1,ind2}(1,i).collimatorType]);

        disp(file{1})
        disp(file{2})
        disp(file{3})
        
        %may need to display files 4,5,6,7 to show collimator settings for some
        %studies (Pinnacle RTOG?) KU 10/10/05
        
        % collimator angle
        disp(['Collimator Angle: ' num2str(planC{1,ind2}(1,i).collimatorAngle)]);
        % couch angle
        disp(['Couch Angle: ' num2str(planC{1,ind2}(1,i).couchAngle)]);
        % gantry angle
        disp(['Gantry Angle: ' num2str(planC{1,ind2}(1,i).gantryAngle)]);
        % head in out
        disp(['Head IN/OUT: ' planC{1,ind2}(1,i).headInOut]);
        % aperture type
        disp(['Aperture Type: ' planC{1,ind2}(1,i).apertureType]);
        % wedge angle
        disp(['Wedge Angle: ' num2str(planC{1,ind2}(1,i).wedgeAngle)]);
        % wedge rotation angle
        disp(['Wedge Rotation Angle: ' num2str(planC{1,ind2}(1,i).wedgeRotationAngle)]);

        % dose per treatment
        if isnumeric(planC{1,ind2}(1,i).RxDosePerTxGy)
            disp(['Rx Dose Per Tx(Gy): ' num2str(planC{1,ind2}(1,i).RxDosePerTxGy)]);
        else
            disp(['Rx Dose Per Tx(Gy): ' planC{1,ind2}(1,i).RxDosePerTxGy]);
        end
        
        % monitor units per treatment
        try
            disp(['Monitor Units Per Tx: ' num2str(planC{1,ind2}(1,i).MonitorUnitsPerTx)]);
        end

        % number of treatments
        disp(['Number of Tx: ' num2str(planC{1,ind2}(1,i).numberOfTx)]);
        disp('===============================================')
    end
end

diary off;
if ispc
    %Open file in Notepad
    dos ('notepad plandata.txt &');
else
    edit plandata.txt; 
end
delete plandata.txt;
%clear
%----------END OF FILE-----------------