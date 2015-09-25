function contourLevels = getIsoDoseLevels()
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

global stateS
if stateS.layout == 7
    colorbarFrameMin = stateS.colorbarFrameMinCompare;
    colorbarFrameMax =  stateS.colorbarFrameMaxCompare;
else
    colorbarFrameMin = stateS.colorbarFrameMin;
    colorbarFrameMax =  stateS.colorbarFrameMax;
end

if strcmpi(stateS.optS.isodoseLevelMode, 'auto')
    numAuto  = stateS.optS.autoIsodoseLevels;
    isoRange = stateS.optS.autoIsodoseRange;
    if stateS.optS.autoIsodoseRangeMode == 1
        minVal  = colorbarFrameMin;
        maxVal  = colorbarFrameMax;
    else
        minVal  = isoRange(1);
        maxVal  = isoRange(2);
    end
    isodoseLevels = linspace(minVal,maxVal, numAuto+2);
    isodoseLevels = isodoseLevels(2:end-1);   
else
    isodoseLevels = stateS.optS.isodoseLevels;
end

%isodoseLevels = stateS.optS.isodoseLevels;
type = stateS.optS.isodoseLevelType;
if strcmp(type,'percent')
    contourLevels = isodoseLevels * stateS.doseArrayMaxValue / 100;
elseif strcmp(type,'absolute')
    contourLevels = isodoseLevels;
end
return;