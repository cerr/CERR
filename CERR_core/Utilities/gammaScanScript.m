% gammaScanScript
global planC
indexS = planC{end};

[newXgrid, newYgrid, newZgrid] = getScanXYZVals(planC{indexS.scan}(1));
deltaX = abs(newXgrid(2) - newXgrid(1));
deltaY = abs(newYgrid(2) - newYgrid(1));
deltaZ = abs(newZgrid(2) - newZgrid(1));
doseAgreement = 15;
distAgreement = 0.3;
thresholdAbsolute = 4000;
doseArray1 = single(planC{indexS.scan}(1).scanArray);
doseArray2 = single(planC{indexS.scan}(2).scanArray);
gammaM = gammaDose3d(doseArray1, doseArray2, [deltaX deltaY deltaZ], doseAgreement, distAgreement, [], thresholdAbsolute);

newDoseNum = length(planC{indexS.dose}) + 1;
%Remove old caching info.
planC{indexS.dose}(newDoseNum).cachedMask = [];
planC{indexS.dose}(newDoseNum).cachedColor = [];
planC{indexS.dose}(newDoseNum).cachedTime = [];
%Set coordinates.
planC{indexS.dose}(newDoseNum).sizeOfDimension1 = length(newXgrid);
planC{indexS.dose}(newDoseNum).sizeOfDimension2 = length(newYgrid);
planC{indexS.dose}(newDoseNum).sizeOfDimension3 = length(newZgrid);
planC{indexS.dose}(newDoseNum).horizontalGridInterval = newXgrid(2)-newXgrid(1);
planC{indexS.dose}(newDoseNum).verticalGridInterval = newYgrid(2)-newYgrid(1);
planC{indexS.dose}(newDoseNum).depthGridInterval = newZgrid(2)-newZgrid(1);
planC{indexS.dose}(newDoseNum).coord1OFFirstPoint = newXgrid(1);
planC{indexS.dose}(newDoseNum).coord2OFFirstPoint = newYgrid(1);
planC{indexS.dose}(newDoseNum).coord3OfFirstPoint = newZgrid(1);
planC{indexS.dose}(newDoseNum).zValues = newZgrid;
planC{indexS.dose}(newDoseNum).doseUnits = 'Gy';
planC{indexS.dose}(newDoseNum).doseArray = gammaM;
planC{indexS.dose}(newDoseNum).doseUID = createUID('dose');
planC{indexS.dose}(newDoseNum).fractionGroupID = 'Gamma Scan 4mm, 50HU';
%Switch to new dose
sliceCallBack('selectDose', num2str(newDoseNum));


