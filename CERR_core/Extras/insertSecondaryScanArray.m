function planC = insertSecondaryScanArray(newScan3M, seriesDescription, refScanNum, planC) %, forceInsert)

if ischar(planC)
    saveFlag = 1;
    saveFileName = planC;
    planC = loadPlanC(saveFileName);
end
% 
% if ~exist('forceInsert','var')
%     forceInsert = 0;
% end

% scanNum = 1;
indexS = planC{end};

refScan3M = getScanArray(refScanNum,planC);

if size(refScan3M) ~= size(newScan3M)
    error(['Reference scan dimensions must match new insert scan. refScan3m size = ' num2str(size(refScan3M)) ', newScan3M size = ' num2str(size(newScan3M))]);
end



% Create scan grid

deltaXYZv = getScanXYZSpacing(refScanNum,planC);

[xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(refScanNum));

uniqueSlicesV = 1:size(newScan3M,3);
minc = 1;
maxc = size(newScan3M,2);
minr = 1;
maxr = size(newScan3M,1);

zV = zVals(uniqueSlicesV);

regParamsS.horizontalGridInterval = deltaXYZv(1);

regParamsS.verticalGridInterval = deltaXYZv(2);

regParamsS.coord1OFFirstPoint = xVals(minc);

regParamsS.coord2OFFirstPoint   = yVals(maxr);

regParamsS.zValues  = zV;

regParamsS.sliceThickness =[planC{indexS.scan}(refScanNum).scanInfo(uniqueSlicesV).sliceThickness];



% Get associated texture, if available (otherwise leave empty, assocTextureUID = '';)
% assocTextureUID = planC{indexS.texture}(end).textureUID; % add a texture entry, optional


% Add feat3M to planC{indexS.scan}
% planC = scan2CERR(scanNew3M,scanType,register,regParamsS,assocTextureUID,planC)
planC = scan2CERR(newScan3M,seriesDescription,'Passed',regParamsS,'',planC);

if saveFlag
    save_planC(planC,[],'PASSED',saveFileName);
end