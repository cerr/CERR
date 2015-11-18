function showIMDose(dose3D,fractionGroupID,assocScanNum)
%Function to place dose into the running CERR plan.
%Just edit the strings below.
%JOD.
%LM:  6 Sept 05
%   APA, 11 Oct 06, Added an input param assocScanNum to link the dose to
%   this scan. Defaults to 1 if not input.
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


global planC;
global stateS;
indexS = planC{end};

register = 'UniformCT';  %Currently only option supported.  Dose has the same shape as the uniformized CT scan.
doseError = [];
doseEdition = 'CERR test';
description = 'Test PB distribution.'
overWrite = 'no';  %Overwrite the last CERR dose?
if ~exist('assocScanNum','var')
    assocScanNum = 1;
end
assocScanUID = planC{indexS.scan}(assocScanNum).scanUID;
dose2CERR(dose3D,doseError,fractionGroupID,doseEdition,description,register,[],overWrite,assocScanUID);

stateS.doseToggle = 1;

stateS.doseSetChanged = 1;
% stateS.CTDisplayChanged = 1;
% stateS.structsChanged = 1;

stateS.doseSet = length(planC{indexS.dose});
% stateS.doseUID = planC{indexS.dose}(end).doseUID;

% Reset Colorbar
stateS.colorbarFrameMax = [];
stateS.doseArrayMaxValue = [];
stateS.doseDisplayRange = [];
stateS.colorbarRange = [];
stateS.colorbarFrameMin = [];

    
sliceCallBack('refresh');
