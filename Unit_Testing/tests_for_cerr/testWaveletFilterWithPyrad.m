% this script tests Wavelet pre-processing filter between CERR and pyradiomics.
% 
%
% RKP, 03/22/2018


% Number of Gray levels
nL = 16;

% Random n x n x n matrix
n = 20;
testM = rand(n,n,2).^0;
testM(1:10,:,:) = 20;
maskBoundingBox3M = testM .^0;

wavType = 'coif1';
scanType = 'wavelet';
dirString = 'HHH';


%% pyradiomics generated wavelet filtered images saved to tempDir     
teststruct = PyradWrapper(testM, maskBoundingBox3M, [1,1,1], scanType, dirString);

%Saving the values returned from Pyradiomics to use for comparison:
savedTeststruct = teststruct;

pyrad_wavelet_filename = fullfile(tempdir, strcat('wavelet-', dirString, '.nrrd'));
[pyWav3M, infoS] = nrrd_read(pyrad_wavelet_filename);
%log3M = flipdim(data3M,3);

pyWav3M = double(pyWav3M);

%pyWav3M = permute(pyWav3M, [2 1 3]);
pyWav3M = flipdim(permute(pyWav3M,[2,1,3]),3);


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
disp(['Percentage difference between CERR and Pyradiomics: ', num2str(quantile99Diff), '%'])

figure, 
slc = 2;
subplot(1,3,1), imagesc(testM(:,:,slc)), title('Original Image')
subplot(1,3,2), imagesc(scanArray3M(:,:,slc)), title('CERR Wavelet')
subplot(1,3,3), imagesc(pyWav3M(:,:,slc)), title('Pyradiomics Wavelet')
    
waveletDiffV = (scanArray3M - pyWav3M) ./ scanArray3M * 100;






