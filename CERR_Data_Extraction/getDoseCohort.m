function infoS = getDoseCohort(dirPath,structureName,matchCriteria)
%function getDoseCohort(dirPath)
%
%APA, 02/22/2010
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

% dirPath = 'C:\Projects\OutcomesModelingTools\CERR_Data_Extraction\SFGF_example';
% structureName = 'L Parotid';
% matchCriteria = 'exact';
% infoS = getDoseCohort(dirPath,structureName,matchCriteria)

fileNamesC = getCERRfiles(dirPath);

infoS = struct('fullFileName','','doseV','','allStructureNames','','error','');
infoS(1) = [];

stateS.optS = CERROptions;

for iFile = 1:length(fileNamesC)

    try
        planC = loadPlanC(fileNamesC{iFile},tempdir);
        planC = updatePlanFields(planC);
        global planC
        indexS = planC{end};
        
        %QA this plan
        
        %Check color assignment for displaying structures
        [assocScanV,relStrNumV] = getStructureAssociatedScan(1:length(planC{indexS.structures}),planC);
        for scanNum = 1:length(planC{indexS.scan})
            scanIndV = find(assocScanV==scanNum);
            for i = 1:length(scanIndV)
                strNum = scanIndV(i);
                colorNum = relStrNumV(strNum);
                if isempty(planC{indexS.structures}(strNum).structureColor)
                    color = stateS.optS.colorOrder( mod(colorNum-1, size(stateS.optS.colorOrder,1))+1,:);
                    planC{indexS.structures}(strNum).structureColor = color;
                end
            end
        end

        %Check dose-grid
        for doseNum = 1:length(planC{indexS.dose})
            if planC{indexS.dose}(doseNum).zValues(2) - planC{indexS.dose}(doseNum).zValues(1) < 0
                planC{indexS.dose}(doseNum).zValues = flipud(planC{indexS.dose}(doseNum).zValues);
                planC{indexS.dose}(doseNum).doseArray = flipdim(planC{indexS.dose}(doseNum).doseArray,3);
            end
        end

        %Check whether uniformized data is in cellArray format.
        if ~isempty(planC{indexS.structureArray}) && iscell(planC{indexS.structureArray}(1).indicesArray)
            planC = setUniformizedData(planC,planC{indexS.CERROptions});
            indexS = planC{end};
        end

        if length(planC{indexS.structureArrayMore}) ~= length(planC{indexS.structureArray})
            for saNum = 1:length(planC{indexS.structureArray})
                if saNum == 1
                    planC{indexS.structureArrayMore} = struct('indicesArray', {[]},...
                        'bitsArray', {[]},...
                        'assocScanUID',{planC{indexS.structureArray}(saNum).assocScanUID},...
                        'structureSetUID', {planC{indexS.structureArray}(saNum).structureSetUID});

                else
                    planC{indexS.structureArrayMore}(saNum) = struct('indicesArray', {[]},...
                        'bitsArray', {[]},...
                        'assocScanUID',{planC{indexS.structureArray}(saNum).assocScanUID},...
                        'structureSetUID', {planC{indexS.structureArray}(saNum).structureSetUID});
                end
            end
        end        
       
    catch
        disp([fileNamesC{iFile}, ' failed to load'])
        infoS(iFile).error = 'Failed to Load';
        continue
    end   
    
    infoS(iFile).fullFileName = fileNamesC{iFile};
    
    if isequal(matchCriteria,'exact')
        indV = strmatch(lower(structureName), lower({planC{indexS.structures}.structureName}),'exact');
    else
        indV = getMatchingIndex(structureName ,{planC{indexS.structures}.structureName});
    end    
    
    infoS(iFile).allStructureNames = {planC{indexS.structures}(indV).structureName};
    
    if length(indV) ~= 1
        infoS(iFile).error = ['Could not find the requested structure ', structureName];
        continue
    end
    
    %Get center of mass
    [x,y,z] = calcIsocenter(indV);
    
    %Pts where dose is desired (need to have a stragey to select these points. For now just use Center Of Mass)
    xV = x;
    yV = y;
    zV = z;
    
    %Assume final dose to be extracted
    doseNum = length(planC{indexS.dose});
    
    if doseNum == 0
        infoS(iFile).error = 'No dose found';
        continue        
    end
    
    doseV = getDoseAt(doseNum, xV, yV, zV, planC);
    
    infoS(iFile).doseV = doseV;
    
end

