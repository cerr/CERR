function planC = getplanCDownSample(planC, optS, index)

indexS = planC{end};


for i = 1: size(planC{indexS.scan}.scanArray,3)
    planC{indexS.scan}.scanInfo(1,i).grid1Units = index*planC{indexS.scan}.scanInfo(1,i).grid1Units;
    planC{indexS.scan}.scanInfo(1,i).grid2Units = index*planC{indexS.scan}.scanInfo(1,i).grid2Units;
    planC{indexS.scan}.scanInfo(1,i).sizeOfDimension2 = size(planC{indexS.scan}.scanArray,2)/index;
    planC{indexS.scan}.scanInfo(1,i).sizeOfDimension1 = size(planC{indexS.scan}.scanArray,1)/index;
end

planC{indexS.scan}.scanArray = getDownsample3(planC{indexS.scan}.scanArray,index,1);

planC{indexS.scan}.scanArraySuperior = [];
planC{indexS.scan}.scanArrayInferior = [];
planC{indexS.scan}.uniformScanInfo = [];

for i=1:length(planC{indexS.structures})
    planC{indexS.structures}(i).rasterSegments =[];
end

planC = getRasterSegs(planC, optS);

planC = setUniformizedData(planC, optS);

try
	for i=1:length(planC{indexS.dose})
        planC = clearCache(planC, i);
	end
end