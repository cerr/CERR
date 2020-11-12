function color = setStructureColor(planC,colorArr)
%  function colorNum = setStructureColor(planC,colorArr)
% function to ensure effective color cycling of structure hues in planC
%
% EML 2020/11/11
%

indexS = planC{end};
colorsTotal = size(colorArr,1);

if ~isempty(planC{indexS.structures})
    colorReserve = cell2mat({planC{indexS.structures}.structureColor}');
    vacantList = find(~ismember(colorArr,colorReserve,'rows'));
    if ~isempty(vacantList)
        nextColorNum = vacantList(1);
    else
        lastUsed = colorReserve(end,:);
        lastIdx = find(ismember(colorArr,lastUsed,'rows'));
        if lastIdx ~= colorsTotal && ~isempty(lastIdx)
            nextColorNum = lastIdx + 1;
        else
            nextColorNum = 1;
        end
    end
else
    nextColorNum = 1;
end

color = colorArr(nextColorNum,:);