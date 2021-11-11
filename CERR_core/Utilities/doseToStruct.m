function planC = doseToStruct(doseNum,doseLevel,assocScanNum,planC)
%function planC = doseToStruct(doseNum,doseLevel,assocScanNum,planC)
%
%This function creates structure associated with assocScanNum at iso-dose level doseLevel.
%Example: doseToStruct(1,50,2)
%         Creates a structure at iso-dose level of 50Gy from dose 1 on scan 2.
%
%APA, 03/26/2007
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

if ~exist('planC','var')
    global planC
end
indexS = planC{end};

% for command line help document
if ~exist('doseNum','var') && ~exist('doseLevel','var') && ~exist('assocScanNum','var')
    prompt = {'Enter the dose Number';'Enter the dose level'; 'Enter the associated scan number'};
            dlg_title = 'Iso-dose to structure';
            num_lines = 1;
            def = {'';'';''};
            outPutQst = inputdlg(prompt,dlg_title,num_lines,def);
            if isempty(outPutQst{1}) || isempty(outPutQst{2}) || isempty(outPutQst{3})
                warning('Need to enter all the inputs');
                return
            else
                doseNum      = str2num(outPutQst{1});
                doseLevel    = str2num(outPutQst{2});
                assocScanNum = str2num(outPutQst{3});
            end
elseif ~exist('assocScanNum','var')
    assocScanNum = getDoseAssociatedScan(doseNum, planC);
end

doseOffset = planC{indexS.dose}(doseNum).doseOffset;
if isempty(doseOffset)
    doseOffset = 0;
end

dose3M = getDoseOnCT(doseNum, assocScanNum);
structureName    = [planC{indexS.dose}(doseNum).fractionGroupID,'_Level_',num2str(doseLevel)];
planC = maskToCERRStructure(dose3M > doseLevel+doseOffset, 0, assocScanNum, structureName, planC);

% Refresh GUI if it exists
if ~isempty(stateS) && isfield(stateS,'handle') && isfield(stateS.handle,'CERRSliceViewer') && ishandle(stateS.handle.CERRSliceViewer)
    stateS.structsChanged = 1;
    CERRRefresh
end

return;
