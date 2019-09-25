% compareCerrWithPyrad.m
%
% Compares CERR and pyRaiomics features
%
% APA, 9/4/2019

pradParamFileName = 'C:\Users\aptea\Desktop\PyradParamsComparison.yaml';
cerrParamFileName = 'C:\Users\aptea\Desktop\CERR_ParamsComparison.json';
nrrdSaveDir = 'C:\Users\aptea\Desktop';

global planC
indexS = planC{end};

structNum = 1;
scanNum = getStructureAssociatedScan(structNum,planC);

scan3M = double(planC{indexS.scan}(scanNum).scanArray) - planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
mask3M = getUniformStr(structNum,planC);
[xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(1));
pixelspacing = [abs(mean(diff(xV))) abs(mean(diff(yV))) abs(mean(diff(zV)))]*10;
origin = [0 0 0];
encoding = 'raw';
mask3M = cast(mask3M,'uint8');
% Write scan and mask to nrrd
scanFilename = fullfile(nrrdSaveDir,'scan.nrrd');
maskFilename = fullfile(nrrdSaveDir,'mask.nrrd');
ok1 = nrrdWriter(scanFilename, scan3M, pixelspacing, origin, encoding);
ok2 = nrrdWriter(maskFilename, mask3M, pixelspacing, origin, encoding);

pyradCallStr = ['pyradiomics ', scanFilename, ' ', maskFilename, ' --param ', pradParamFileName];
system(pyradCallStr)

delete(scanFilename)
delete(maskFilename)

% CERR radiomics
paramS = getRadiomicsParamTemplate(cerrParamFileName);
cerrFeatS = calcGlobalRadiomicsFeatures(scanNum, structNum, paramS, planC);
cerrFeatS.Original.glcmFeatS.AvgS


