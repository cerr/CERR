function openAxisInFig(hAxis)
%function openAxisInFig(hAxis)
%
%This function opens the passed hAxis in a new figure.
%hAxis must be one the axes stored under stateS.handle.CERRAxis
%
%APA, 11/17/2006
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
doseSet = getAxisInfo(hAxis,'doseSets');

f = figure;

%copy the specified CERR axis (2 in this example) to new figure
h1 = copyobj(hAxis,f);
set(h1,'units','normalized','Position',[0.01 0.01 0.9 0.98]) 
axis(h1,'square')
h1Color = get(h1,'color');
h1Children = get(h1,'children');
hLabelV = findobj(h1Children,'tag','CERRAxisLabel');
if sum(h1Color)==0
    set(hLabelV,'color',[1 1 1])
else
    set(hLabelV,'color',[0 0 0])
end

%copy colorbar to new figure
if stateS.doseToggle==1 && ~isempty(doseSet)
    h2 = copyobj([stateS.handle.doseColorbar.trans],f);
    set(h2,'units','normalized','Position',[0.9 0.15 0.08 0.8])
    axis(h2,'auto')
else
    set(h1,'units','normalized','Position',[0.01 0.01 0.95 0.98]) 
    colormap('gray')
end
