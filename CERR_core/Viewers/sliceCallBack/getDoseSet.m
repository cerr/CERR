function stateS = getDoseSet(stateS, planC)
%set the dose set to be displayed.
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

doseSetTag = stateS.doseSetTag;

indexS = planC{end};
%Get the index of the dose set to be displayed.  If more than one dose set matches,
%use the first one.
stateS.doseSet = [];

if isempty(planC{indexS.dose})
    stateS.doseSet = [];
    stateS.doseToggle = -1;
    warning('No dose set found. Displaying scan and structures only');
    return;
end

for i = 1 : length(planC{indexS.dose})
    if strcmpi(doseSetTag, planC{indexS.dose}(i).fractionGroupID);
        stateS.doseSet = i;
    end
end

if isempty(stateS.doseSet)
    warning('Dose set to be displayed was not found...Defaulting to the first dose set.')
    stateS.doseSet = 1;
end

if ~isempty(stateS.doseSet) && isempty(getDoseArray(stateS.doseSet));
    stateS.doseSet = [];
    stateS.doseToggle = -1;
end