function [newXgrid, newYgrid, newZgrid, doseArray1, doseArray2] = prepareDosesForGamma(doseNum1,doseNum2, assocScan, planC)
% function [xDoseVals, yDoseVals, zDoseVals, doseArray1, doseArray2, baseDoseIndex] = prepareDosesForGamma(doseNum1,doseNum2, assocScan, planC)
%
% APA, 06/15/2012

indexS = planC{end};
wtfactor = [1 1];

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
newXgrid = linspace(min(cell2mat(xGrid)),max(cell2mat(xGrid)),max(cell2mat(xRes)));
newYgrid = linspace(max(cell2mat(yGrid)),min(cell2mat(yGrid)),max(cell2mat(yRes)));
newZgrid = linspace(min(cell2mat(zGrid)),max(cell2mat(zGrid)),max(cell2mat(zRes)));

%Obtain doses with same grid
if isempty(assocTransM)
    assocTransM = eye(4);
end
doseIndC = {};
doseNumsTmp = doseNums;
for iSortAll = 1:length(doseNums)
    iSort = doseNums(iSortAll);
    indRemaining = doseNums;
    indRemaining(iSortAll) = [];
    doseSortM = [iSort];
    if ~ismember(iSort,[doseIndC{:}])
        for jSortAll = 1:length(indRemaining)
            jSort = indRemaining(jSortAll);
            if ~isempty(getTransM('dose',iSort,planC))
                doseITM = inv(assocTransM) * getTransM('dose',iSort,planC);
            else
                doseITM = inv(assocTransM);
            end
            if ~isempty(getTransM('dose',jSort,planC))
                doseJTM = inv(assocTransM) * getTransM('dose',jSort,planC);
            else
                doseJTM = inv(assocTransM);
            end
            if isequal([xRes{iSort},yRes{iSort},zRes{iSort}],[xRes{jSort},yRes{jSort},zRes{jSort}]) && isequal(doseITM,doseJTM)
                doseSortM(end+1) = jSort;
                indJsort = find(doseNumsTmp == jSort);
                doseNumsTmp(indJsort) = [];
            end
        end
    end
    doseIndC{iSort} = doseSortM;
end

doseNums = doseNumsTmp;

%Loop over doses and add over new grid
hWait = waitbar(0,'Summing Dose distributions');
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
    
    %Get the summation for this grid
    doseCombinedM = [];
    for iDoseAll = 1:length(doseIndC{doseNum})
        iDose = doseIndC{doseNum}(iDoseAll);
        doseUnits2 = getDoseUnitsStr(iDose,planC);
        if strcmpi(doseUnits, 'Gy') && strcmpi(doseUnits2, 'cGy')
            multFact = 0.01;
        elseif strcmpi(doseUnits, 'cGy') && strcmpi(doseUnits2, 'Gy')
            multFact = 100;
        else
            multFact = 1;
        end
        doseOffset = planC{indexS.dose}(iDose).doseOffset;
        if isempty(doseOffset)
            doseOffset = 0;
        end
        if ~isempty(doseCombinedM)
            doseCombinedM = doseCombinedM + multFact * wtfactor(iDose) * single(getDoseArray(planC{indexS.dose}(iDose)) - doseOffset);
        else
            doseCombinedM = multFact * wtfactor(iDose) * single(getDoseArray(planC{indexS.dose}(iDose)) - doseOffset);
        end
    end
    
    %Check if this dose is on same grid as the new one
    %if isequal(xGrid{doseNum},newXgrid) && isequal(yGrid{doseNum},newYgrid) && isequal(zGrid{doseNum},newZgrid)
    chkLength = length(xGrid{doseNum})==length(newXgrid) && length(yGrid{doseNum})==length(newYgrid) && length(zGrid{doseNum})==length(newZgrid);
    if sum(sum((inputTM-eye(4)).^2)) < 1e-3 && chkLength && max(abs(xGrid{doseNum}-newXgrid)) < 1e-3 && max(abs(yGrid{doseNum}-newYgrid)) < 1e-3 && max(abs(zGrid{doseNum}-newZgrid)) < 1e-3
        
        % doseSumM = doseSumM + doseCombinedM;
        if i == 1
            doseArray1 = doseCombinedM;
        else
            doseArray2 = doseCombinedM;            
        end
            
        waitbar((i-1)/length(doseNums),hWait,['Calculating contribution from Dose ', num2str(doseNum)])
        
    else %interpolation required
        
        %Transform this dose
        doseTmpM = [];
        
        for slcNum=1:length(newZgrid)
            [xV, yV, zV] = getDoseXYZVals(planC{indexS.dose}(doseNum));
            doseTmp = slice3DVol(doseCombinedM, xV, yV, zV, newZgrid(slcNum), 3, 'linear', inputTM, [], newXgrid, newYgrid);
            if isempty(doseTmp)
                doseTmpM(:,:,slcNum) = doseEmptyM;
            else
                doseTmpM(:,:,slcNum) = doseTmp;
            end
            waitbar((i-1)/length(doseNums) + (slcNum-1)/length(newZgrid)/length(doseNums) ,hWait,['Calculating contribution from Dose ', num2str(doseNum)])
        end
        
        % doseSumM = doseSumM + doseTmpM;
        if i == 1
            doseArray1 = doseTmpM;
        else
            doseArray2 = doseTmpM;            
        end
        
    end
    
end


