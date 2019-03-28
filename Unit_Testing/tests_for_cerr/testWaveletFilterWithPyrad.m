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
teststruct = PyradWrapper(testM, maskBoundingBox3M, scanType, dirString);

pyrad_wavelet_filename = fullfile(tmpDir, strcat('wavelet-', dirString, '.nrrd'));
[pyWav3M, infoS] = nrrd_read(pyrad_wavelet_filename);
%log3M = flipdim(data3M,3);

pyWav3M = double(pyWav3M);

pyWav3M = permute(pyWav3M, [2 1 3]);


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


%% comparison
diff3M = (scanArray3M - pyWav3M)./(pyWav3M+1e-5);
quantile99Diff = quantile(abs(diff3M(abs(pyWav3M)>0.1)),0.99);
disp(['Percentage difference between CERR and ITK: ', num2str(quantile99Diff), '%'])

figure, 
slc = 3;
subplot(1,3,1), imagesc(testM(:,:,slc)), title('Original Image')
subplot(1,3,2), imagesc(scanArray3M(:,:,slc)), title('CERR Wavelet')
subplot(1,3,3), imagesc(pyWav3M(:,:,slc)), title('Pyradiomics Wavelet')





% pyfield = strcat('wavelet_', dirString);
% pyradiomicsarray = getfield(teststruct, pyfield);
% 
% %pyradiomicsarray = teststruct.wavelet_HHH;
% pydata = double(py.array.array('d',py.numpy.nditer(pyradiomicsarray)));
% data = reshape(pydata,[20 20 6]);
%         
waveletDiffV = (scanArray3M - pyWav3M) ./ scanArray3M * 100






