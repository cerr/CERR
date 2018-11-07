function coLlAGe3M = getCollageFeature(scanNum, structNum, domDirPatchRadV,...
    haralTextPatchRadV, numGrayLevels, dim2d3dFlag, hWait, planC)
%
% function coLlAGe3M = getCollageFeature(scanNum, structNum, patchSizeV, dim2d3dFlag, hWait, planC)
%
% INPUTS:
% scanArray3M - 3d matrix containing pixel intensities
% mask3M - 0/1 mask for structure
% domDirPatchRadV - [n,n,n] patch size. must be of length 3.
% dim2d3dFlag - '2d' or '3d'
% haralTextPatchRadV - [n,n,n] patch size. must be of length 3.
% numGrayLevels - number of gray levels for discretization.
% hWait - waitbar handle. Can be NaN.
%
% OUTPUT:
% coLlAGe3M - resulting coLlAGe3M matrix
%
% EXAMPLE:
% scan3M = randi([1,500],20,20,20);
% mask3M = scan3M.^0;
% domDirPatchRadV = [3 3 0];
% haralTextPatchRadV = [3 3 0];
% numGrayLevels = 64;
% dim2d3dFlag = '2d';
% coLlAGe3M = getCollageFeature(scan3M, mask3M, domDirPatchRadV,...
%     haralTextPatchRadV, numGrayLevels, dim2d3dFlag);
%
% APA, 11/2/2018

if ~exist('planC','var')
    global planC
end
indexS = planC{end};

if ~exist('hWait','var')
    hWait = NaN;
end

% Get structure mask
if numel(structNum) > 1
    mask3M = structNum;
else
    mask3M = getUniformStr(structNum,planC);
end

% Scanarray
if numel(scanNum) > 1
    scanArray3M = scanNum;
else
    scanArray3M = planC{indexS.scan}(scanNum).scanArray - planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
end

% calculate dominant orientations
domOrient3M = calcDominantOrientation(single(scanArray3M), mask3M, domDirPatchRadV, dim2d3dFlag, hWait);

% Calculate patchwise texture of dominant orientations
domOrient3M(~mask3M) = NaN;
flagV = zeros(1,9);
flagV(2) = 1; % entropy only
[~,coLlAGe3M] = textureByPatchAllOffsFromCtr(domOrient3M, numGrayLevels, ...
    haralTextPatchRadV, flagV);

% 
% % test .exe
% resolution = [1 1 1] * 10;
% offset = [0 0 0] * 10;
% scan3M = randi([1,500],20,20,20);
% mask3M = scan3M.^0;
% scanFileName = 'L:\Aditya\coLlageFeature\Data\case_1\VolumeImage.mha';
% maskFileName = 'L:\Aditya\coLlageFeature\Data\case_1\VolumeMask.mha';
% collageFileName = 'L:\Aditya\coLlageFeature\collageCase1Out.mha';
% % % Write .mha file for this scan
% % writemetaimagefile(scanFileName, scan3M, resolution, offset);
% % % Write .mha file for this structure mask
% % writemetaimagefile(maskFileName, mask3M, resolution, offset);
% % Call collage calculator
% system(['L:\Aditya\coLlageFeature\ccipdColiageFeatureExtractor2D.exe "', scanFileName, '" "', ...
%     maskFileName, '" 2 "', collageFileName, '"'])
% 
% infoS = mha_read_header(collageFileName);
% coll3M = mha_read_volume(infoS);
% figure, imagesc(coll3M)
% figure, imagesc(A(:,:,1))
% figure, imagesc(A(:,:,2))
% Ainfo = mha_read_header('L:\Aditya\coLlageFeature\Data\case_1\VolumeMask.mha');
% mask3M = mha_read_volume(Ainfo);
% figure, imagesc(mask3M(:,:,2))
% 
% 
% scanFileName = 'L:\Aditya\coLlageFeature\Data\case_1\VolumeImage.mha';
% maskFileName = 'L:\Aditya\coLlageFeature\Data\case_1\VolumeMask.mha';
% infoS = mha_read_header(maskFileName);
% mask3M = mha_read_volume(infoS);
% infoS = mha_read_header(scanFileName);
% scan3M = mha_read_volume(infoS);
% scan3M(~mask3M) = NaN;
% nL = 64;
% patchSizeV = [5 5 0];
% offsetsM = [];
% flagV = zeros(1,9);
% flagV(2) = 1; % entropy only
% [~,coLlAGe3M] = textureByPatchAllOffsFromCtr(scan3M, nL, ...
%     patchSizeV, offsetsM, flagV); % need to update for all possible offsets
