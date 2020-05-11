function [bbox3M, planC] = crop_for_chewing_structs(planC,paramS,varargin)
% Custom crop function for chewing structures segmentation model
% AI 10/04/19

%% Get mask of pt outline
indexS = planC{end};
outerStr = paramS.structureName; %pt outline
strC = {planC{indexS.structures}.structureName};
strNum = getMatchingIndex(outerStr,strC,'EXACT');
if isempty(strNum)
    %Generate pt outline
    scanNum = 1;
    scan3M = double(getScanArray(scanNum,planC));
    CToffset = planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
    scan3M = scan3M - CToffset;
    outerMask3M = getPatientOutline(scan3M,1:size(scan3M,3),-400);
    planC = maskToCERRStructure(outerMask3M,0,scanNum,outerStr,planC);
    strC = {planC{indexS.structures}.structureName};
    strNum = length(strC);
else
    [outerMask3M, planC]= getStrMask(strNum,planC);
end

%% Get S-I limits
% ----- Decommissioned----
%[noseSliceNum, planC] = getNoseSlice(outerMask3M,planC,outerStr);
%[maxs, mins, planC] = ...
%getShoulderStartSlice(outerMask3M,planC,outerStr,noseSliceNum); %Crop to shoulder slice
%--------------------------
%Use all slices
mins = 1;
maxs = size(outerMask3M,3); 

%% Get L,R , A,P limits 
minrV = nan(size(outerMask3M,3),1);
maxrV = minrV;
mincV = minrV;
maxcV = minrV;
for n = 1:size(outerMask3M,3)
    maskSlcM = outerMask3M(:,:,n);
    if any(maskSlcM(:))
        [minrV(n),maxrV(n),mincV(n),maxcV(n)] = compute_boundingbox(outerMask3M(:,:,n));
    end
end
minc = round(nanmedian(mincV));
maxc = round(nanmedian(maxcV));
minr = round(prctile(minrV,5));
maxr = round(nanmedian(maxrV));
width = maxr-minr+1;
maxr = round(maxr-.25*width);

%Return bounding box
bbox3M = false(size(outerMask3M));
bbox3M(minr:maxr,minc:maxc,mins:maxs) = true;


end