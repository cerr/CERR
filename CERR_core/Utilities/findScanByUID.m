function scanNum = findScanByUID(planC, scanUID)

scanNum = [];

indexS = planC{end};

for i = 1:numel(planC{indexS.scan})
	if strcmp(scanUID,planC{indexS.scan}(i).scanUID)
		scanNum = i;
		break
	end
end