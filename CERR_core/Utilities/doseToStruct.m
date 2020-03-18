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
if ~exist('doseNum')& ~exist('doseLevel')& ~exist('assocScanNum')
    prompt = {'Enter the dose Number';'Enter the dose level'; 'Enter the associated scan number'};
            dlg_title = 'Iso-dose to structure';
            num_lines = 1;
            def = {'';'';''};
            outPutQst = inputdlg(prompt,dlg_title,num_lines,def);
            if isempty(outPutQst{1}) | isempty(outPutQst{2})| isempty(outPutQst{3})
                warning('Need to enter all the inputs');
                return
            else
                doseNum      = str2num(outPutQst{1});
                doseLevel    = str2num(outPutQst{2});
                assocScanNum = str2num(outPutQst{3});
            end
elseif ~exist('assocScanNum')
    assocScanNum = getDoseAssociatedScan(doseNum, planC);
end

doseTransM = getTransM('dose',doseNum,planC);
scanTransM = getTransM('scan',assocScanNum,planC);

if isempty(doseTransM)
    doseTransM = eye(4);
end
if isempty(scanTransM)
    scanTransM = eye(4);
end

transM = inv(scanTransM)*doseTransM;
doseOffset = planC{indexS.dose}(doseNum).doseOffset;
if isempty(doseOffset)
    doseOffset = 0;
end

[xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(assocScanNum));
[xV, yV, zV] = getDoseXYZVals(planC{indexS.dose}(doseNum)); 
newStructS = newCERRStructure(assocScanNum, planC);
newStructNum = length(planC{indexS.structures}) + 1;
for i=1:length(zVals)
    [doseM, imageYVals, imageXVals] = slice3DVol(planC{indexS.dose}(doseNum).doseArray, xV, yV, zV, zVals(i), 3, 'linear', transM, []);
    if isempty(doseM)
        indC = [];
    else
        C = contourc(imageXVals, imageYVals, doseM, [doseLevel+doseOffset doseLevel+doseOffset]);
        indC = getSegIndices(C);
    end
    if ~isempty(indC)
        for seg = 1:length(indC)
            points = [C(:,indC{seg})' zVals(i)*ones(length(C(1,indC{seg})),1)];
            newStructS.contour(i).segments(seg).points = points;
        end
    else
        newStructS.contour(i).segments.points = [];
    end
end

newStructS.structureName    = [planC{indexS.dose}(doseNum).fractionGroupID,'_Level_',num2str(doseLevel)];
planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructS, newStructNum);
planC = getRasterSegs(planC, newStructNum);
planC = updateStructureMatrices(planC, newStructNum);
% Refresh GUI if it exists
if ~isempty(stateS) && isfield(stateS,'handle') && isfield(stateS.handle,'CERRSliceViewer') && ishandle(stateS.handle.CERRSliceViewer)
    stateS.structsChanged = 1;
    CERRRefresh
end

return;

function indC = getSegIndices(C)
% function getSegIndices(C)
%
%This function returns the indices for each segment of input contour C.
%C is output from in-built "contourc" function
%
%APA, 12/15/2006

start = 1;
counter = 1;
indC = [];
while start < length(C(2,:))
    numPts = C(2,start);
    indC{counter} = [(start+1):(start+numPts) start+1];
    start = start + numPts + 1;
    counter = counter + 1;
end

