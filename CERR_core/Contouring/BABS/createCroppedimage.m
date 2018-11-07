function planC = createCroppedimage(scanNum,structNumV,pcaParamsFile,planC)
% function createCroppedimage(scanNum,structNumV,pcaParamsFile,planC)
%
% pcaParamsFile: ''
%
% APA, 10/6/2017

if ~iscell(scanNum)
    rowMargin = 100; % extend rows by this amount
    colMargin = 512; % extend cols by this amount
    slcMargin = 7; % extend slcss by this amount   
    
    if ~exist('planC','var')
        global planC
    end
    
    indexS = planC{end};
    
    %load(pcaParamsFile)
    
    % get ROI
    randomFlg = 1;
    [volToEval,maskBoundingBox3M,mask3M,minr,maxr,minc,maxc,mins,maxs,uniqueSlices] = ...
        getROI(structNumV,rowMargin,colMargin,slcMargin,planC,randomFlg);
    
    sliceThickNessV = ...
        [planC{indexS.scan}(scanNum).scanInfo(mins:maxs).sliceThickness];
    [xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(scanNum));
    
else
    
    volToEval = scanNum{1};
    maskBoundingBox3M = scanNum{2};
    mask3M = scanNum{3};
    minr = scanNum{4};
    maxr = scanNum{5};
    minc = scanNum{6};
    maxc = scanNum{7};
    mins = scanNum{8};
    maxs = scanNum{9};
    uniqueSlices = scanNum{10};
    sliceThickNessV = scanNum{11};
    xVals = scanNum{12};
    yVals = scanNum{13};
    zVals = scanNum{14};
    
    
end

minIntensity = -200;   % Clipping min
maxIntensity = 400; % Clipping max

%%
% Save comp3M to planC
deltaXYZv = [abs(xVals(1)-xVals(2)) abs(yVals(1)-yVals(2)) abs(zVals(1)-zVals(2))];
zV = zVals(mins:maxs);
regParamsS.horizontalGridInterval = deltaXYZv(1);
regParamsS.verticalGridInterval   = deltaXYZv(2); %(-)ve for dose
regParamsS.coord1OFFirstPoint   = xVals(minc);
%regParamsS.coord2OFFirstPoint   = yVals(minr); % for dose
regParamsS.coord2OFFirstPoint   = yVals(maxr);
regParamsS.zValues  = zV;
regParamsS.sliceThickness = sliceThickNessV;
%dose2CERR(entropy3M,[], 'entropy3voxls_Ins3_NI14','test','test','non CT',regParamsS,'no',assocScanUID)
assocTextureUID = '';
%planC = scan2CERR(comp3M,['PC_',num2str(compNum)],'Passed',regParamsS,assocTextureUID,planC);
planC = scan2CERR(volToEval,'CT_Cropped','Passed',regParamsS,assocTextureUID,planC);



