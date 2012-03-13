function [planC, indOut] = addIM(IMDosimetry, planC, saveIndex)
%"addIM"
%   Add an IM to the current planC.  Use this function to ensure that IM
%   adds properly even to plans that did not previously have an IM section
%   in their planC/indexS.
%
%JRA 5/12/2004
%LM: APA 10/06/06: Added indOut output paramater to obtain the new index.
%    APA 10/10/06: Removed IMSetup field.
%Usage:
%   function planC = addIM(IMDosimetry, location, planC);
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
try 
    i = length(planC{indexS.IM}) + 1;    
catch
    planC = updateIndexS(planC);
    indexS = planC{end};
    i = 1;
end
if saveIndex == 0
	planC{indexS.IM}(i).IMDosimetry = IMDosimetry;
    indOut = i;
else
	planC{indexS.IM}(saveIndex).IMDosimetry = IMDosimetry;    
    indOut = saveIndex;
end


function planC = updateIndexS(planC)
%"updateIndexS"
%   Updates the indexS to reflect the current initializeCERR setup.

% [jnk, jnk, jnk, jnk, jnk, jnk, jnk, jnk, ...
%  jnk, jnk, jnk, jnk, templatePlan, templateIndex] = initializeCERR;
templatePlan = initializeCERR;
templateIndex = templatePlan{end};
indexS = planC{end};

fields = fieldnames(indexS);
for i = 1:length(fields);
    try
        templatePlan{getfield(templateIndex, fields{i})} =  planC{getfield(indexS, fields{i})};  
%         templatePlan{templateIndex.(fields{i})} = planC{indexS.(fields{i})};
    catch
        error('Could not convert a field in plan to the new planC template.');
    end
end
planC = templatePlan;
planC{end+1} = templateIndex;

    