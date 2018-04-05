% this script tests Wavelet pre-processing filter between CERR and pyradiomics.
% 
%
% RKP, 03/22/2018


% % Structure from planC
% global planC
% indexS = planC{end};
% scanNum     = 1;
% structNum   = 16;
% 
% [rasterSegments, planC, isError]    = getRasterSegments(structNum,planC);
% [mask3M, uniqueSlices]              = rasterToMask(rasterSegments, scanNum, planC);
% scanArray3M                         = getScanArray(planC{indexS.scan}(scanNum));
% 
% SUVvals3M                           = mask3M.*double(scanArray3M(:,:,uniqueSlices));
% [minr, maxr, minc, maxc, mins, maxs]= compute_boundingbox(mask3M);
% maskBoundingBox3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);
% volToEval                           = SUVvals3M(minr:maxr,minc:maxc,mins:maxs);
% volToEval(maskBoundingBox3M==0)     = NaN;
% 
% testM = imquantize_cerr(volToEval,nL);

% Number of Gray levels
nL = 16;

% Random n x n x n matrix
n = 20;
testM = rand(n,n,6);
testM = imquantize_cerr(testM,nL);
maskBoundingBox3M = testM .^0;

wavType = 'coif1';
scanType = 'wavelet';
dirString = 'HHH';

%%pyradiomics generated wavelet filtered images saved to tempDir     
teststruct = PyradWrapper(testM, maskBoundingBox3M, scanType);


%% CERR wavelet images
scanArray3M = flip(testM,3);



if mod(size(scanArray3M,3),2) > 0
    scanArray3M(:,:,end+1) = 0*scanArray3M(:,:,1);
end
scanArray3M = wavDecom3D(double(scanArray3M),dirString,wavType);
if mod(size(scanArray3M,3),2) > 0
    scanArray3M = scanArray3M(:,:,1:end-1);
end
scanArray3M = flip(scanArray3M,3);

pyfield = strcat('wavelet_', dirString);
pyradiomicsarray = getfield(teststruct, pyfield);

%pyradiomicsarray = teststruct.wavelet_HHH;
pydata = double(py.array.array('d',py.numpy.nditer(pyradiomicsarray)));
data = reshape(pydata,[20 20 6]);
        
waveletDiffV = (scanArray3M - data) ./ scanArray3M * 100






