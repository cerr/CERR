function planC = delUniformStr(structNumsV, planC)
%"delUniformStr"
%   Remove the requested structNums from the uniformized data, by shifting
%   all structures following each structNum towards the least significant bit.
%   Also, remove any indices from the uniformized data that no longer
%   contain any structure after this shift.
%
%   This does not remove the structures from planC{indexS.structures},
%   and so should be called by whatever function is doing the deletion 
%   to keep the uniformized data current.
%
%   JRA 4/19/04
%
%Usage:
%   function planC = delUniformStr(structNum, planC);
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


if ~exist('planC','var')
    global planC;
end

indexS = planC{end};

[scanNumsV, relStructNumsV] = getStructureAssociatedScan(structNumsV, planC);

uniqueScans = unique(scanNumsV);

%Handle each individual scan number's uniformized data seperately.
for i=1:length(uniqueScans)

    scanNum = uniqueScans(i);

    [strInScanV, relStrInScan] = getStructureAssociatedScan(1:length(planC{indexS.structures}),planC);
    strInScan = find(strInScanV == scanNum);
    relStrInScan = relStrInScan(strInScan);

    %SORTED Structures to delete in this scan.  Must be sorted so bits can
    %be removed in the proper order (largest to smallest).
    toDel = sort(relStructNumsV(scanNumsV == scanNum));

    %Get the bits and indices into the uniformized data for this scan.
    [indC, bitsC] = getUniformizedData(planC, scanNum, 'no');

    %If uniformized data does not exist, continue, nothing needs to be done.
    if isempty(bitsC) || isempty(indC)
        continue;
    end

    for cellNum = 1:length(indC)

        %Find structures in this cell
        if cellNum == 1
            strIndCell = find(toDel > 0 & toDel <= 52);
        else
            strIndCell = find(toDel > 52 + (cellNum-2)*8 & toDel <= 52 + (cellNum-1)*8);
        end

        if isempty(strIndCell)
            continue;
        end

        toDelCell = sort(toDel(strIndCell));
        
        bitsA = bitsC{cellNum};
        indA = indC{cellNum};

        %If uniformized data does not exist, continue, nothing needs to be done.
        if isempty(bitsA) || isempty(indA)
            continue;
        end

        %Get the datatype of the bits array for casting later.
        datatype = class(bitsA);
        
        clear bitsC

        %Create the number consisting of the bits to the left of the structNum bit,
        %with a shift towards least significant bit of 1. Repeat for each bit
        %to remove.  Go from largest to smallest for proper bit removal.
        for j=length(toDelCell):-1:1
            if cellNum == 1
                bitToRemove = toDelCell(j);
            else
                %bitToRemove = toDelCell(j) - 8*(cellNum-1);
                bitToRemove = toDelCell(j) - 52 - 8*(cellNum-2);
            end
            %b = double(bitshift(bitshift(bitsA,-bitToRemove), bitToRemove-1));
            b = bitshift(bitshift(bitsA,-bitToRemove), bitToRemove-1);

            %Create the number consisting of the bits to the right of the structNum bit.
            %c = mod(double(bitsA),2^(bitToRemove-1));
            c = mod(bitsA,2^(bitToRemove-1));

            %Add these two numbers to get the final number with structNum bit removed.
            bitsA = b + c;            
            clear b c            
        end
        
        %Find bits where no structure exists.
        noStructsV = find(bitsA == 0);

        %Remove these bits from the bits/indices.
        bitsA(noStructsV) = [];
        indA(noStructsV,:) = [];      
        
        clear noStructsV
        
        %Move structures from other cells into cellNum
        strOtherIndCell = find(relStrInScan > 52 + (cellNum-1)*8);
        if cellNum == 1 && isempty(strOtherIndCell)
            planC{indexS.structureArray}(scanNum).bitsArray = bitsA;
            planC{indexS.structureArray}(scanNum).indicesArray = indA;
            planC{indexS.structureArrayMore}(scanNum).bitsArray = {};
            planC{indexS.structureArrayMore}(scanNum).indicesArray = {};
            continue;
        elseif cellNum > 1 && isempty(strOtherIndCell) && length(planC{indexS.structureArrayMore}(scanNum).bitsArray) > cellNum-1
            planC{indexS.structureArrayMore}(scanNum).bitsArray{cellNum-1} = bitsA;
            planC{indexS.structureArrayMore}(scanNum).indicesArray{cellNum-1} = indA;            
            planC{indexS.structureArrayMore}(scanNum).bitsArray = planC{indexS.structureArrayMore}(scanNum).bitsArray(1:cellNum-1);
            planC{indexS.structureArrayMore}(scanNum).indicesArray = planC{indexS.structureArrayMore}(scanNum).indicesArray(1:cellNum-1);
            continue;
        end

        strOtherCell = sort(strInScan(strOtherIndCell));
        if length(strOtherCell) < length(strIndCell)
            structsTomove = strOtherCell;
            relStructsTomove = strOtherIndCell;
        else
            structsTomove = strOtherCell(1:length(strIndCell));
            relStructsTomove = strOtherIndCell(1:length(strIndCell));
        end
        
        %Add bits and indices to current cell
        bitCount = 1;
        for strToMov = structsTomove
            if relStructsTomove(bitCount) <= 52
                otherCellNum = 1;
            else
                otherCellNum = ceil((relStructsTomove(bitCount)-52)/8)+1;
            end
            %otherCellNum = ceil(relStructsTomove(bitCount)/8);            
            if otherCellNum == cellNum
                if cellNum == 1
                    bitsA = bitset(bitsA,52-length(strIndCell)+bitCount,1);
                else
                    bitsA = bitset(bitsA,8-length(strIndCell)+bitCount,1);
                end
                continue;
            end
            indOther = indC{otherCellNum};
            %Find indices of other structure which are already in current cell
            matchA = ismember(indA,indOther,'rows');
            if cellNum == 1
                bitsA(matchA) = bitset(bitsA(matchA),52-length(strIndCell)+bitCount, 1);
            else
                bitsA(matchA) = bitset(bitsA(matchA),8-length(strIndCell)+bitCount, 1);
            end
            mtchOther = ismember(indOther,indA,'rows');            
            indA = [indA;indOther(~mtchOther,:)];
            %strBitOtherA = uint8(zeros(length(find(~mtchOther)),1));
            strBitOtherA = zeros(length(find(~mtchOther)),1,datatype);
            if cellNum == 1
                strBitOtherA(1:end,:) = bitset(zeros(1,1,datatype), 52-length(strIndCell)+bitCount, 1);
            else                
                strBitOtherA(1:end,:) = bitset(zeros(1,1,datatype), 8-length(strIndCell)+bitCount, 1);
            end
            bitsA = [bitsA;strBitOtherA];            
            bitCount = bitCount + 1;
        end                      
        
        %bitsA = uint8(bitsA);
        bitsA = cast(bitsA,datatype);

        %Put revised bits/indices into the plan.
        if cellNum == 1
            planC{indexS.structureArray}(scanNum).bitsArray = bitsA;
            planC{indexS.structureArray}(scanNum).indicesArray = indA;
        else
            planC{indexS.structureArrayMore}(scanNum).bitsArray{cellNum-1} = bitsA;
            planC{indexS.structureArrayMore}(scanNum).indicesArray{cellNum-1} = indA;
        end

        planC = delUniformStr(structsTomove, planC);
        
        clear bitsA indA
        
        [indC, bitsC] = getUniformizedData(planC, scanNum, 'no');

    end

    
end