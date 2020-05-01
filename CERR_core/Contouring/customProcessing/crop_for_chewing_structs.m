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
[noseSliceNum, planC] = getNoseSlice(outerMask3M,planC,outerStr);
%[maxs, mins, planC] = ...
%getShoulderStartSlice(outerMask3M,planC,outerStr,noseSliceNum); %Crop to shoulder slice
mins = noseSliceNum;
maxs = size(outerMask3M,3); %Use all slices

%% Get L,R and A,P limits from nose slice
lrMaskM = double(outerMask3M(:,:,mins));
[minr, maxr, minc, maxc] = compute_boundingbox(lrMaskM);
width = maxr-minr+1;
maxr = round(maxr-.25*width);

%Return bounding box
bbox3M = false(size(outerMask3M));
bbox3M(minr:maxr,minc:maxc,mins:maxs) = true;


end