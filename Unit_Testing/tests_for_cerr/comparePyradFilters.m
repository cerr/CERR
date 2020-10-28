function [pyFiltS,cerrFiltS] = comparePyradFilters
% Function to compare filtered images computed using CERR vs. Pyradiomics.
% Supported filer types: LoG, Wavelets.
%------------------------------------------------------------------------
% AI 07/02/2020

%% Load sample data
fpath = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing/data_for_cerr_tests/IBSI1_CT_phantom/IBSILungCancerCTImage.mat.bz2');
planC = loadPlanC(fpath,tempdir);
planC = updatePlanFields(planC);
planC = quality_assure_planC(fpath,planC);
indexS = planC{end};
scanNum=1;

%% Apply filters using pyradiomics

% 1. LoG
filtName = 'LoG';
testSigmaV = [3.0,4.0]; 
pyFiltParam1S.sigma = testSigmaV;
pyFiltS = processImageUsingPyradiomics(planC,'',filtName,pyFiltParam1S);
pyFieldLoGC = fieldnames(pyFiltS);

%2. Wavelets
filtName = 'wavelet';
pyFiltParam2S.wavetype = 'coif1';
pyFilt2S = processImageUsingPyradiomics(planC,'',filtName,pyFiltParam2S);
pyFieldWavC = fieldnames(pyFilt2S);
for n = 1:length(pyFieldWavC)
    pyFiltS.(pyFieldWavC{n}) = pyFilt2S.(pyFieldWavC{n});
end

%% Apply filters using CERR

%Get scan array
scan3M = getScanArray(scanNum,planC);
CToffset = planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
scan3M = double(scan3M)-CToffset;
wholeScanMask3M = ones(size(scan3M));

% 1. LoG
filtName = 'LoG';
cerrFiltS = struct();
scanS = planC{indexS.scan}(scanNum);
[xV,yV,zV] = getScanXYZVals(scanS);
dx = median(abs(diff(xV)));
dy = median(abs(diff(yV)));
dz = median(diff(zV));
voxelSizeV = [dx,dy,dz];
cerrFiltParam1S.VoxelSize_mm.val = voxelSizeV*10;%convert to mm
for n = 1:length(testSigmaV)
        cerrFiltParam1S.Sigma_mm.val = testSigmaV(n);
        outFieldname = pyFieldLoGC{n};
        outS = processImage(filtName,scan3M,wholeScanMask3M,cerrFiltParam1S);
        fieldsC = fieldnames(outS);
        cerrFiltS.(outFieldname) = outS.(fieldsC{1});
end

% 2. Wavelets
cerrFiltParam2S = struct();
cerrFiltParam2S.Wavelets.val='coif';
cerrFiltParam2S.Index.val='1';
cerrFiltParam2S.NormFlag.val=0;
dirC = {'LLH','LHL','LHH','HLL','HLH','HHL','HHH','LLL'};
filtName = 'Wavelets';
for n = 1:length(dirC)
    %Convert python dictionary to matlab struct
    cerrFiltParam2S.Direction.val = dirC{n};
    outS = processImage(filtName,scan3M,wholeScanMask3M,cerrFiltParam2S);
    outFieldname = pyFieldWavC{n};
    fieldsC = fieldnames(outS);
    cerrFiltS.(outFieldname) = outS.(fieldsC{1});
end


end