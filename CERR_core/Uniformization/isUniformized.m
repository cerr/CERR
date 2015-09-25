function [valid, saveflg]= isUniformized(scanNum, planC)
%"isUniformized"
%   Checks to see if the uniform data for the specified scanNum exists and
%   that all fields appear valid.  Returns true if they are, false if they
%   arent (therefore suggesting the data should be regenerated using
%   setUniformizedData).
%
%JRA 05/24/05
%DK  04/20/06 check uniformization for old plans
%Usage:
%   function valid = isUniformized(scanNum, planC);
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
optS = CERROptions;
saveflg = 0;
%Assume valid to start.
valid = 1;

%Check for required planC fields.
if ~isfield(indexS, 'scan') | ~isfield(indexS, 'structureArray');
    valid = 0;
    return;
end

%Check the two major planC components.
scanStruct = planC{indexS.scan}(scanNum);
if length(planC{indexS.structureArray})>=scanNum
    uniStruct  = planC{indexS.structureArray}(scanNum);
else
    uniStruct = [];
end

if isempty(scanStruct.uniformScanInfo)
    valid = 0;
    return;
end

%if isfield(uniStruct,'bitsArray') & isempty(uniStruct.bitsArray)& length(planC{indexS.structures})~= 0
if isfield(uniStruct,'bitsArray') && isempty(uniStruct.bitsArray) && ismember(scanNum,getAssociatedScan({planC{indexS.structures}.assocScanUID},planC))
    valid = 0;
    return;
elseif length(planC{indexS.structures})== 0
    return;    
end

if ~isfield(scanStruct, 'uniformScanInfo') | ~isfield(scanStruct, 'scanArrayInferior') | ~isfield(scanStruct, 'scanArraySuperior')
    valid = 0;
    return;
end

if isempty(uniStruct) | isempty(uniStruct.indicesArray) | isempty(uniStruct.bitsArray)
    %The uniformized structs are empty.  This should only happen if no
    %structures associated with this scan have no rasterSegments or if the
    %structures are excluded from uniformization in the options file.
    
    nStructs = length(planC{indexS.structures});        
    assocScansV = getStructureAssociatedScan(1:nStructs, planC);
    
    %Check only structs that are associated with this scan.
    structsToCheck = find(assocScansV == scanNum);
    
    for i=1:length(structsToCheck)
        structNum = structsToCheck(i);
        structName = planC{indexS.structures}(structNum).structureName;
        
        %Ignore structures that are on the exclude list.
        if ismember(lower(structName), lower(optS.uniformizeExcludeStructs))           
            continue;
        end
        
        [rS, planC] = getRasterSegments(structNum, planC);
        if ~isempty(rS) && ~(isfield(planC{indexS.structures},'rasterized') && planC{indexS.structures}(1).rasterized == 1)
            valid = 0;
            return;
        end
    end    
else
    [xV, yV, zV] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
    indicesM = planC{indexS.structureArray}(scanNum).indicesArray;
    askQuestion = 1;
%     for cellNum = 1:length(indicesC)
%         indicesM = indicesC{cellNum};
        if ~isempty(indicesM) && max(indicesM(:,3))>length(zV) && askQuestion
            askQuestion = 0;
            valid = 0;
            querry = {'This is an old archived plan which was uniformized incorrectly'...
                'CERR will uniformized the plan again'...
                ''...
                'Would you like to save changes to original plan?'};
            ButtonName = questdlg(querry,'Uniformization Check','Yes','No','Yes');
            if strcmpi(ButtonName,'yes')
                saveflg = 1;
            end
        end
%     end
end