function planC = storeStructuresMatrices(planC, indicesM, structBitsM, scanNum)
%"storeStructuresMatrices"
%   Either 1) modifies planC by adding another cell just before the index cell, or
%          2) uses the preallocated structureArray cell in planC.
%
%this new cell includes the index matrix and the bit matrix for the structures.
%
% 16 Aug 02, V H Clark
% 18 Feb 05, JRA, Added support for multiple scanSets.
% 14 Feb 08, APA, Added UID association
%
%Usage:
%   function planC = storeStructuresMatrices(planC, indicesM, structBitsM)

fieldExists = isfield(planC{end}, 'structureArray'); %this will be true for newer versions, false for old versions
indexS = planC{end};
assScanUID = planC{indexS.scan}(scanNum).scanUID;
structSetUID = createUID('STRUCTURESET');
if fieldExists %most common
    if isempty(planC{planC{end}.structureArray})        
        planC{planC{end}.structureArray} = struct('indicesArray', indicesM, 'bitsArray', structBitsM, 'assocScanUID', assScanUID, 'structureSetUID', structSetUID);
    else
        planC{planC{end}.structureArray}(scanNum) = struct('indicesArray', indicesM, 'bitsArray', structBitsM, 'assocScanUID', assScanUID, 'structureSetUID', structSetUID);
    end
else
    structIndex = length(planC);
    planC{end+1} = planC{end}; %moves the index to the end
    
    planC{structIndex}(scanNum) = struct('indicesArray', indicesM, 'bitsArray', structBitsM, 'assocScanUID', assScanUID, 'structureSetUID', structSetUID);
    %change index
    planC{end}.structureArray = structIndex;
end
