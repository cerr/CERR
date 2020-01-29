function [planC,seriesIdxV,FGTMask3M] = getFGTMask(planC,breastMaskNum,seriesIdxV,isReg,cmdFile,verbose)

%% Set defaults
if ~exist('isReg','var')
    isReg = 0;
end
if ~exist('verbose','var')
    verbose = 0; %Default;
end

%% Register series
% Use slices w/ breast outline for registration
rasterSegM = getRasterSegments(breastMaskNum,planC);
[~,maskSlices] = rasterToMask(rasterSegM,1,planC);
sizV = size(getScanArray(breastMaskNum,planC));
bbox3M = false(sizV);
for k = 1:numel(maskSlices)
    bbox3M(:,:,maskSlices(k)) = true(sizV(1),sizV(2));
end
%Register
if ~isReg
    fprintf('\nRegistering scans...\n');
    if ~exist('seriesIdxV','var')
        seriesIdxV = 1:3; %Default;
    end
    if verbose
        [planC,seriesIdxV] = registerSeries(planC,seriesIdxV,bbox3M,breastMaskNum,cmdFile);
    else
        [~,planC,seriesIdxV] = evalc('registerSeries(planC, seriesIdxV, bbox3M, breastMaskNum, cmdFile)');
    end
    indexS = planC{end};
    breastMaskNum = length(planC{indexS.structures});  %Deformed to registered NFS scan
    fprintf('\nRegistration complete...');
else
    seriesIdxV = [1 4 5];
end
indexS = planC{end};

%% Get NFS,FS (pre,post) series
nonFatSat3M = double(getScanArray(seriesIdxV(1), planC));  %nonfatsatimg
fatSatPre3M = double(getScanArray(seriesIdxV(2), planC));  %fatsatimg pre
[nRows,nCols,nSlices] = size(nonFatSat3M);

%% Get breast mask
breastMask3M = getUniformStr(breastMaskNum,planC);
maskSliceV = find(sum(sum(breastMask3M)));

%% Segment FGT
fprintf('\nSegmenting FGT...\n');
diffImg3M = zeros(nRows,nCols,nSlices);
for j = 1:numel(maskSliceV)
    
    nonFatImgM = nonFatSat3M(:,:,maskSliceV(j));
    fatSatPreImgM = fatSatPre3M(:,:,maskSliceV(j));
    %breastMaskM = breastMask3M(:,:,maskSliceV(j));
    
    % Construct difference image (between normalized non-Fat sat and fat sat images)
    normNFSM = nonFatImgM/max(nonFatImgM(:))*255.0;
    normFSPreM = fatSatPreImgM/max(fatSatPreImgM(:))*255.0;
    
    diffImgM = normNFSM-normFSPreM;
    diffImg3M(:,:,maskSliceV(j)) = diffImgM;
    
end

%Find global threshold

%CHANGES:
%1. Look at a bunch of histograms-- sample looks like it has one big peak
% at lower end corresp to air/breast boundary
%2. Second peak-- probably coresponds to FGT--maybe some part of outline
% That needs to be removed by erosion. Check!

dataV = diffImg3M(breastMask3M);

if isempty(dataV)
    %To handle cases with too few slices (no FGT)
    FGTMask3M = [];
    return
else
    Data2 = dataV-min(dataV);
    threshold = th_maxlik(Data2,ceil(max(Data2))) + min(dataV);%/255*max(Data);
    %If threshold is less than -100 or greater than 100 or not a number, force it to 0.
    if threshold>=100 || threshold<-100 || isnan(threshold)
        threshold =0;
    end
    
    
    %---TEMP (for hist plots)----
    % indexS = planC{end};
    % H = planC{indexS.scan}(1).scanInfo(1).DICOMHeaders;
    % pid = H.PatientID;
    % h=figure;
    % histogram(dataV);
    % hold on
    % line([threshold threshold],[1 10000]);
    % saveas(h,['C:\Users\iyera\Desktop\test_BPE\plots\',...
    %     pid,'_thresh'],'jpeg');
    % close(h);
    %----------
    
    
    %Create FGT mask
    FGTMask3M = false(nRows,nCols,nSlices);
    for  j = 1:numel(maskSliceV)
        FGTMaskV = false(nRows*nCols,1);
        %If difference between non-fat sat and fat sat < threshold &
        %fat sat image >  0, identify as FGT voxel
        breastMaskM = breastMask3M(:,:,maskSliceV(j));
        diffImgM = diffImg3M(:,:,maskSliceV(j));
        fatSatPreImgM = fatSatPre3M(:,:,maskSliceV(j));
        fgtIdx = breastMaskM & diffImgM<threshold &fatSatPreImgM>0; %Changed AI
        FGTMaskV(fgtIdx) = true;
        FGTMaskM = reshape(FGTMaskV,nRows,nCols);
        FGTMask3M(:,:,maskSliceV(j)) = FGTMaskM;
    end
    
    % Exclude voxels that are part of breast outline
    valid3M = imerode(breastMask3M,strel('disk',4));
    FGTMask3M = FGTMask3M & valid3M;
    
end
fprintf('\nComplete.');

end