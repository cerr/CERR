function [newXgrid, newYgrid, newZgrid, doseArray1, doseArray2, interpMask3M] = prepareDosesForGamma(doseNum1,doseNum2,strNum,assocScan,planC)
% function [xDoseVals, yDoseVals, zDoseVals, doseArray1, doseArray2, interpMask3M] = prepareDosesForGamma(doseNum1,doseNum2,strNum,assocScan,planC)
%
% APA, 06/15/2012

if ~exist('planC','var')
    global planC
end
indexS = planC{end};

if assocScan > 0
    assocScanUID = planC{indexS.scan}(assocScan).scanUID;
    %Get associated transM
    assocTransM = planC{indexS.scan}(assocScan).transM;
    if isempty(assocTransM)
        assocTransM = eye(4);
    end
else %No Association
    assocScanUID = '';
    assocTransM = eye(4);
end

doseNums = [doseNum1, doseNum2];

%Get the x,y,z grid for Gamma
for i = 1:length(doseNums)
    doseNum = doseNums(i);
    %Get x,y,z values for doseNum
    [xV, yV, zV] = getDoseXYZVals(planC{indexS.dose}(doseNum));
    
    %Get the corners of the original dataset.
    [xCorn, yCorn, zCorn] = meshgrid([min(xV) max(xV)], [min(yV) max(yV)], [min(zV) max(zV)]);
    
    %Add ones to the corners so we can apply a transformation matrix.
    corners = [xCorn(:) yCorn(:) zCorn(:) ones(numel(xCorn), 1)];
    
    %Apply transform to corners, so we know boundary of the slice.
    transM = getTransM(planC{indexS.dose}(doseNum),planC);
    if isempty(transM) || isequal(transM,eye(4))
        [xV,yV,zV] = getDoseXYZVals(planC{indexS.dose}(doseNum));
        xGrid{doseNum} = xV(:)';
        yGrid{doseNum} = yV(:)';
        zGrid{doseNum} = zV(:)';
    else
        newCorners = inv(assocTransM) * transM * corners';
        xGrid{doseNum} = linspace(min(newCorners(1,:)), max(newCorners(1,:)), length(xV));
        yGrid{doseNum} = linspace(max(newCorners(2,:)), min(newCorners(2,:)), length(yV));
        zGrid{doseNum} = linspace(min(newCorners(3,:)), max(newCorners(3,:)), length(zV));
    end
    xRes{doseNum} = length(xV);
    yRes{doseNum} = length(yV);
    zRes{doseNum} = length(zV);
    
    %Get associated scan
    assocScanV{doseNum} = getAssociatedScan(planC{indexS.dose}(doseNum).assocScanUID);
end

newXgrid = linspace(max(cellfun(@min,xGrid(~cellfun(@isempty,xGrid)))),min(cellfun(@max,xGrid(~cellfun(@isempty,xGrid)))),max(cell2mat(xRes(~cellfun(@isempty,xRes)))));
newYgrid = linspace(min(cellfun(@max,yGrid(~cellfun(@isempty,yGrid)))),max(cellfun(@min,yGrid(~cellfun(@isempty,yGrid)))),max(cell2mat(yRes(~cellfun(@isempty,yRes)))));
newZgrid = linspace(max(cellfun(@min,zGrid(~cellfun(@isempty,zGrid)))),min(cellfun(@max,zGrid(~cellfun(@isempty,zGrid)))),max(cell2mat(zRes(~cellfun(@isempty,zRes)))));

%Loop over doses and add over new grid
hWait = waitbar(0,'Summing Dose distributions');
numRows = length(newYgrid);
numCols = length(newXgrid);
numSlcs = length(newZgrid);
% doseSumM = zeros([length(newYgrid),length(newXgrid),length(newZgrid)],'single');
doseEmptyM = zeros([length(newYgrid),length(newXgrid)],'single');

%Assume dose units are same as that of 1st dose
doseUnits = getDoseUnitsStr(doseNums(1),planC);
for i = 1:length(doseNums)
    
    doseNum = doseNums(i);
    
    %Check for transM
    if ~isempty(assocTransM) && ~isequal(assocTransM,eye(4))
        doseTtransM = getTransM('dose',doseNum,planC);
        if isempty(doseTtransM)
            doseTtransM = eye(4);
        end
        inputTM = inv(assocTransM) * doseTtransM;
    else
        inputTM = getTransM('dose',doseNum,planC);
        if isempty(inputTM)
            inputTM = eye(4);
        end
    end
        
    %Check if this dose is on same grid as the new one
    chkLength = length(xGrid{doseNum})==length(newXgrid) && length(yGrid{doseNum})==length(newYgrid) && length(zGrid{doseNum})==length(newZgrid);
    if sum(sum((inputTM-eye(4)).^2)) < 1e-3 && chkLength && max(abs(xGrid{doseNum}-newXgrid)) < 1e-3 && max(abs(yGrid{doseNum}-newYgrid)) < 1e-3 && max(abs(zGrid{doseNum}-newZgrid)) < 1e-3
        
        if i == 1
            doseArray1 = getDoseArray(planC{indexS.dose}(doseNum));
        else
            doseArray2 = getDoseArray(planC{indexS.dose}(doseNum));            
        end
            
        waitbar((i-1)/(length(doseNums)+1),hWait,['Calculating contribution from Dose ', num2str(doseNum)])
        
    else %interpolation required
        
        %Transform this dose
        doseTmpM = zeros(numRows,numCols,numSlcs);
        dA = getDoseArray(planC{indexS.dose}(doseNum));
        [xV, yV, zV] = getDoseXYZVals(planC{indexS.dose}(doseNum));
        for slcNum=1:length(newZgrid)            
            doseTmp = slice3DVol(dA, xV, yV, zV, newZgrid(slcNum), 3, 'linear', inputTM, [], newXgrid, newYgrid);
            if ~isempty(doseTmp)
                doseTmpM(:,:,slcNum) = doseTmp;
            end
            waitbar((i-1)/(length(doseNums)+1) + (slcNum-1)/length(newZgrid)/(length(doseNums)+1) ,hWait,['Calculating contribution from Dose ', num2str(doseNum)])
        end
        
        clear dA
        
        if i == 1
            doseArray1 = doseTmpM;
        else
            doseArray2 = doseTmpM;            
        end
        
    end        
    
end

% Interpolate structure mask to dose grid
mask3M = getUniformStr(strNum,planC);
[~,~,kV] = find3d(mask3M);
kV = unique(kV);
interpMask3M = zeros(numRows,numCols,numSlcs,'logical');
assocScanNum = getStructureAssociatedScan(strNum,planC);
[xV,yV,zV] = getUniformScanXYZVals(planC{indexS.scan}(assocScanNum));
kMin = max(find(newZgrid < zV(min(kV))));
kMax = min(find(newZgrid > zV(max(kV))));
for slcNum=kMin:kMax %1:length(newZgrid)
    strTmpM = slice3DVol(mask3M, xV, yV, zV, newZgrid(slcNum), 3, 'linear', inputTM, [], newXgrid, newYgrid);
    if ~isempty(strTmpM)
        interpMask3M(:,:,slcNum) = strTmpM > 0.5;
    end
    waitbar((2)/(length(doseNums)+1) + (slcNum-1)/length(newZgrid)/(length(doseNums)+1) ,hWait,['Calculating contribution from Structure '])
end
close(hWait)

