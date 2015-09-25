function varargout = getUniformStr(structNumV, planC, optS, generateData)
%"getUniformStr"
%   Get a 3D representation of a structure or union of structures,
%   registered to the uniformized scan.
%
%   In the case of multiple scanSets, the structure is registered to the
%   uniformized scan of its associated scanSet.  If multiple structures are
%   requested, they must all have the same associated scanSet.
%
%   If the number of output arguments is 1 or 2, the first argument is a 3D
%   mask representing the structure(s).  See first example.
%
%   If the number of output arguments is 3 or 4, the first 3 outputs are
%   vectors listing the row, column and slice coordinates of voxels in the
%   structure(s).  See second example.
%
%   structNumV can be a vector of multiple structures, in which case the
%   union of the masks of those structures is returned.
%
%   The optional parameter generateData is set to 1 if the uniformized data
%   should be generated for structures that appear un-uniformized.  0 if
%   empty data should be returned for such structures.  1 is the default.
%
%   LM:  9 may 03, JOD, create uniformized structures if they don't exist.
%                       Convert input string to a number in case structure 
%                       name was specified.
%       12 Dec 04, JRA, Now supports multiple uniform scanSets.
%
%Usage:
%   function [S, planC] = getUniformStr(structNumV, planC, optS, generateData);
%   function [r,c,s, planC] = getUniformStr(structNumV, planC, optS, generateData);
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


%Check if plan passed, if not use global.
if ~exist('planC')
    global planC;
end
indexS = planC{end};

if ~exist('generateData')
    generateData = 1;
end

%Determine whether to return mask or r,c,s coordinates.
if nargout == 0 | nargout == 1 | nargout == 2
    wantMask = 1; %Return 3D mask
elseif nargout == 3 | nargout == 4
    wantMask = 0; %Return RCS.
else
    error('Invalid number of output arguments in call to getUniformStr.');    
end

%Check if optS passed.  If not, try using global stateS options, else use
%options saved in the CERR plan.
if ~exist('optS')
    try
        global stateS;
        optS = stateS.optS;
    catch
        optS = planC{indexS.CERROptions};
    end    
end

%If structNumV is a string or cell of strings, convert to numerics.
if isstr(structNumV) | iscell(structNumV)
    if isstr(structNumV)
        structNumV = {structNumV};
    end
    
    numericStructList = [];
    for i=1:length(structNumV)
        Str_Name = structNumV{i};
        structures = lower({planC{indexS.structures}.structureName});
        [jnk, ia, ib] = intersect(lower(structNumV{i}), structures);
        structNum = ib;
        if isempty(structNum)
            error(['Structure ''' Str_Name ''' does not exist in plan.']);
        end
        numericStructList = [numericStructList structNum];
    end
    structNumV = numericStructList;
end

%Determine which scanSet the structure(s) are registered to.
[scanNum, relStructNum] = getStructureAssociatedScan(structNumV, planC);
if length(unique(scanNum)) > 1
    error('All structures passed to getUniformStr must be registered to the same scan.');
end
scanNum = scanNum(1);

%Get uniformized structure data, generating if necessary.
[indicesC, bitsC, planC] = getUniformizedData(planC, scanNum, 'yes');

%Get size of uniform scan.
siz = getUniformScanSize(planC{indexS.scan}(scanNum));
numRows     = siz(1);
numCols     = siz(2);
numSlices   = siz(3);

%Convert indicesM and bitsM into a single full array:
%use boolean to save memory.
if wantMask
    S = logical(repmat(uint8(0), siz));
end

%maskV = repmat(logical(0), [length(bitsM) 1]);
otherIndicesM = [];
for i=1:length(structNumV)
    
    structNum = structNumV(i);
    
    %Get the cell index
    if relStructNum(i)<=52
        cellNum = 1;
    else
        cellNum = ceil((structNum-52)/8)+1;
    end
    
    indicesM = indicesC{cellNum};
    bitsM    = bitsC{cellNum};

    %eliminate uniformized data that, for whatever reason, lies outside the
    %defined region.
    bitsM(find(indicesM(:,3)>numSlices),:) = [];
    indicesM(find(indicesM(:,3)>numSlices),:) = [];

	%get values corresponding to requested structure.
    if relStructNum(i)<=52
        bitMaskV = logical(bitget(bitsM(:),relStructNum(i)));
    else
        bitMaskV = logical(bitget(bitsM(:),relStructNum(i)-52-8*(cellNum-2)));
    end
    
	%If no voxels are part of structNum, suggests that the structure needs
	%to be uniformized. Uniformize it.  This is recursive so if a structure
	%exists that cannot be uniformized...trouble!
    if ~any(bitMaskV) & generateData
        warning(['Structure ' planC{indexS.structures}(structNum).structureName ' does not appear to be uniformized.  Adding it to uniformized data.']);
        planC = updateStructureMatrices(planC, structNum);
        otherIndices = [];
        [otherIndicesM(:,1), otherIndicesM(:,2), otherIndicesM(:,3), planC] = getUniformStr(structNumV, planC, optS, 0);
        break;
    end

      otherIndices = reshape(indicesM([bitMaskV bitMaskV bitMaskV]), [], 3);
      
      clear bitMaskV;
      
      if ~isempty(otherIndicesM)
          indPresentV = ismember(otherIndices,otherIndicesM,'rows');
          otherIndicesM = [otherIndicesM; otherIndices(~indPresentV,:)];
      else
          otherIndicesM = [otherIndicesM; otherIndices];
      end
      
      clear otherIndices

end
clear bitsM maskV indicesM;

if wantMask
    %Convert 3D indices to vectorized indices.
    if ~isempty(otherIndicesM)
        indexV = sub2ind([numRows,numCols,numSlices],double(otherIndicesM(:,1)),double(otherIndicesM(:,2)),double(otherIndicesM(:,3)));
    else
        indexV = [];    
    end
        
    clear otherIndicesM;

    %Fill S array in with values where the structure exists.
    S(indexV) = 1;
    varargout{1} = S;
    varargout{2} = planC;
else
    %Assign r,c,s coordinates to output.
    varargout{1} = otherIndicesM(:,1);
    varargout{2} = otherIndicesM(:,2);    
    varargout{3} = otherIndicesM(:,3);
    clear otherIndicesM;
    varargout{4} = planC;
end
