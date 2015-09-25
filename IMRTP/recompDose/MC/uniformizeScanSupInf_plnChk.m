function planC = uniformizeScanSupInf(planC, tMin, tMax, optS, hBar)
%"uniformizeScanSupInf"
%    Creates the superior and inferior scan arrays so that they 
%   are uniform, consistent with the rest of the scan array.
%
%Latest modifications:
% 16 Aug 02, V H Clark, first version.
% 09 Apr 03, JOD, added hBar to input parameter list.
% 18 Feb 05, JRA, Added support for multiple scans.
%
%Usage:
%   function planC = uniformizeScanSupInf(planC, tMin, tMax, optS, hBar)

indexS = planC{end};

for scanNum=1:length(planC{indexS.scan})
    scanStruct = planC{indexS.scan}(scanNum);
    
	uniformScanInfo = planC{indexS.scan}(scanNum).uniformScanInfo;
	sliceNumSup = uniformScanInfo.sliceNumSup; %superior slice number of original CT scan still being used
	sliceNumInf = uniformScanInfo.sliceNumInf; %inferior slice number of original CT scan still being used
	uniformSliceThickness = uniformScanInfo.sliceThickness;
	scanArray = planC{indexS.scan}(scanNum).scanArray;
	scanInfo = planC{indexS.scan}(scanNum).scanInfo;
	
	[scanArraySup, scanArrayInf, uniformScanFirstZValue] = uniformizeScanEnds(scanStruct, sliceNumSup, sliceNumInf, uniformSliceThickness, tMin, tMax, optS, hBar);
	
	uniformScanInfo.firstZValue = uniformScanFirstZValue;
	uniformScanInfo.supInfScansCreated = 1;
	
	planC{indexS.scan}(scanNum).scanArraySuperior = scanArraySup;
	planC{indexS.scan}(scanNum).scanArrayInferior = scanArrayInf;
	
	planC{indexS.scan}(scanNum).uniformScanInfo = uniformScanInfo;	
end


