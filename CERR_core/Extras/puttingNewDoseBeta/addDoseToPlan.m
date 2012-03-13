function planC = addDoseToPlan(planC, doseNew,doseError,fractionGroupID,doseEdition,description,register,regParamsS)
%function dose2CERR(doseNew,doseError,fractionGroupID,doseEdition,description,register,regParamsS)
%Use this function to put a new dose distribution into CERR.
%See test_dose2CERR in the putNewDose subdirectory for an example of its use.
%doseNew - 3-D array of dose values.
%doseError - estimate of standard deviation for Monte Carlo plans
%fractionGroupID - unique ID as a function of the number of fractions.
%doseEdition - another ID, see the RTOG specification.
%description - Short description string if desired.
%register - 'CT' or blank (defaults to CT), or non-CT.  If CT, registration geomtrical
%information is taken from the CT scan.  Otherwise, registration data is taken from regParamsS:
%regParamsS should contain geometric registration data including the following fields:
%regParamsS.horizontalGridInterval = 0.2 (say)  (x voxel width)
%regParamsS.verticalGridInterval   = 0.2 (say)  (y voxel width)
%regParamsS.coord1OFFirstPoint     = 0.5 (say)  (x value of center of upper left voxel on all slices)
%regParamsS.coord2OFFirstPoint     = 25  (say)  (y value of center of upper left voxel on all slices
%regParamsS.zValues                = [0.5 1.0 1.5 2.0 ...] (say) (z values of all slices)
%(x,y,z) are in the AAPM/RTOG coordinate system.
%El Naqa & Deasy, Feb 03.
%Latest Modifications: 7 March 03, JOD; input can be non-registered to CT scan.  Now using regParamsS.
%                      31 July 03, JOD, corrected use of fraction group ID.
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

indexS=planC{end};
W = size(doseNew);

%How many old dose distributions?
prevSets = length(planC{indexS.dose});
setIndex = prevSets + 1;

%Get latest dose structure, this way future field additions are included.
doseInitS = initializeCERR('dose');

doseInitS(1).doseArray = doseNew;
doseInitS(1).imageNumber=  '';
doseInitS(1).imageType='DOSE';
doseInitS(1).caseNumber=1;
doseInitS(1).patientName='';
doseInitS(1).doseNumber= setIndex;
doseInitS(1).doseType='PHYSICAL';
doseInitS(1).doseUnits='GRAYS';
doseInitS(1).doseScale=1;
doseInitS(1).fractionGroupID= fractionGroupID;
doseInitS(1).numberOfTx= '';
doseInitS(1).orientationOfDose='TRANSVERSE';
doseInitS(1).numberRepresentation=  '';
doseInitS(1).numberOfDimensions=length(W);
doseInitS(1).sizeOfDimension1=W(1);
doseInitS(1).sizeOfDimension2=W(2);
doseInitS(1).sizeOfDimension3=W(3);
if ~isempty(description)
  doseInitS(1).doseDescription=description;
end
if ~isempty(doseEdition)
  doseInitS(1).doseEdition= doseEdition;
end
doseInitS(1).unitNumber='';
doseInitS(1).writer='';
doseInitS(1).dateWritten='';
doseInitS(1).planNumberOfOrigin='';
doseInitS(1).planEditionOfOrigin='';
doseInitS(1).studyNumberOfOrigin='';
doseInitS(1).versionNumberOfProgram='';
doseInitS(1).xcoordOfNormaliznPoint='';
doseInitS(1).ycoordOfNormaliznPoint='';
doseInitS(1).zcoordOfNormaliznPoint='';
doseInitS(1).doseAtNormaliznPoint='';
doseInitS(1).coord3OfFirstPoint= '';   %Not used in CERR
doseInitS(1).depthGridInterval = '';

%Monte Carlo specific:
if ~isempty(doseError)
  doseInitS(1).doseError=doseError;
end

if nargin > 5
  if strcmpi(register,'CT')

    grid2Units = planC{indexS.scan}.scanInfo(1).grid2Units;
    grid1Units = planC{indexS.scan}.scanInfo(1).grid1Units;
    doseInitS(1).horizontalGridInterval = grid1Units;
    doseInitS(1).verticalGridInterval= grid2Units;

    abGrid1Units = abs(grid1Units);
    abGrid2Units = abs(grid2Units);

    xOffset = planC{indexS.scan}.scanInfo(1).xOffset;
    yOffset = planC{indexS.scan}.scanInfo(1).yOffset;

    CTWidth = planC{indexS.scan}.scanInfo(1).sizeOfDimension2;

    doseInitS(1).coord1OFFirstPoint=  xOffset - (CTWidth/2) * abGrid1Units + abGrid1Units/2;
    doseInitS(1).coord2OFFirstPoint=  yOffset + (CTWidth/2) * abGrid2Units - abGrid2Units/2;

    % get from CT info:

    zValues = [planC{indexS.scan}.scanInfo(:).zValue];
    doseInitS(1).zValues = zValues;
    doseInitS(1).delivered='';

  end

elseif nargin == 7

  doseInitS(1).horizontalGridInterval = regParamsS.horizontalGridInterval;
  doseInitS(1).verticalGridInterval   = regParamsS.verticalGridInterval;
  doseInitS(1).coord1OFFirstPoint     = regParamsS.coord1OFFirstPoint;
  doseInitS(1).coord2OFFirstPoint     = regParamsS.coord2OFFirstPoint;
  doseInitS(1).zValues                = regParamsS.zValues;

else

  error('Inputs to dose2CERR are incorrect')

end

planC{indexS.dose}(setIndex) = doseInitS;

%Update the CERR dose menu
% try
%   putDoseMenu(stateS.handle.CERRSliceViewer, planC, indexS);
% end

