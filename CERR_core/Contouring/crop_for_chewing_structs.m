function bbox3M = crop_for_chewing_structs(planC,paramS,varargin)
% Custom crop function for chewing structures segmentation model
% AI 10/04/19?

%% Get mask of pt outline
indexS = planC{end};
outerStr = paramS.structureName; %pt outline
strC = {planC{indexS.structures}.structureName};
strNum = getMatchingIndex(outerStr,strC,'EXACT');
if isempty(strNum)
    %Generate pt outline
    scanNum = 1;
    scan3M = getScanArray(scanNum,planC);
    CToffset = planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
    scan3M = scan3M - CToffset;
    ptMask3M = getPatientOutline(scan3M,1:size(scan3M,3),-400);
    planC = maskToCERRStructure(ptMask3M,0,scanNum,outerStr,planC);
    strC = {planC{indexS.structures}.structureName};
    strNum = length(strC);
end
outerMask3M = getStrMask(strNum,planC);

%% Get S-I limits
mins = getNoseSlice([],planC,outerStr);
maxs = getShoulderStartSlice([],planC,outerStr);

%% Get L,R and A,P limits from nose slice
lrMaskM = double(outerMask3M(:,:,mins));
[minr, maxr, minc, maxc] = compute_boundingbox(lrMaskM);
width = maxr-minr+1;
maxr = round(maxr-.25*width);

%Return bounding box
bbox3M = false(size(outerMask3M));
bbox3M(minr:maxr,minc:maxc,mins:maxs) = true;


end