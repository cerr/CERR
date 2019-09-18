function [errC,rcsC,originImageSizC, userOptS] = CERRtoHDF5(CERRdir,HDF5dir,dataSplitV,strListC,userOptS)
% CERRtoHDF5.m
%
% Script to export scan and mask files in HDF5 format, split into training,
% validation, and test datasets.
% Mask: Numerical labels are assigned following the order of
% structure names input (strListC). Background voxels are assigned label=0.
%
%
% AI 3/12/19
%--------------------------------------------------------------------------
%INPUTS:
% CERRdir       : Path to generated CERR files
% HDF5dir       : Path to generated HDF5 files
% dataSplitV    : Train/Val/Test split fraction
% strListC      : List of structures to export
% userOptS      : Options for resampling, cropping, resizing etc.
%                 See sample file: CERR_core/DLSegmentationTraining/sample_train_params.json
%--------------------------------------------------------------------------
%AI 9/3/19 Added resampling option
%AI 9/4/19 Options to populate channels
%AI 9/11/19 Updated for compatibility with testing pipeline
%RKP 9/14/19 Additional updates for compatibility with testing pipeline

%% Get user inputs
outSizeV = userOptS.resize.size;
cropS = userOptS.crop;
resampleS = userOptS.resample;
channelS = userOptS.channels;
maskChannelS = channelS;
maskChannelS.method = 'none';
prefixType = userOptS.exportedFilePrefix;
resizeMethod = userOptS.resize.method;

%% Get data split
[trainIdxV,valIdxV,testIdxV] = randSplitData(CERRdir,dataSplitV);


%% Batch convert CERR to HDF5
fprintf('\nConverting data to HDF5...\n');

%Label key
labelKeyS = struct();
for n = 1:length(strListC)
    labelKeyS.(strListC{n}) = n;
end

%Loop over CERR files
dirS = dir(fullfile(CERRdir,filesep,'*.mat'));
labelV = 1:length(strListC);
resC = cell(1,length(dirS));
originImageSizC = cell(1,length(dirS));
errC = {};

for planNum = 1:length(dirS)
    
     try
        
        %Load file
        fprintf('\nProcessing pt %d of %d...\n',planNum,length(dirS));
        [~,ptName,~] = fileparts(dirS(planNum).name);
        fileNam = fullfile(CERRdir,dirS(planNum).name);
        planC = loadPlanC(fileNam, tempdir);
        planC = updatePlanFields(planC);
        planC = quality_assure_planC(fileNam,planC);
        indexS = planC{end};
        
        %Identify available structures
        allStrC = {planC{indexS.structures}.structureName};
        strNotAvailableV = ~ismember(lower(strListC),lower(allStrC)); %Case-insensitive
        if any(strNotAvailableV)
            warning(['Skipping missing structures: ',strjoin(strListC(strNotAvailableV),',')]);
        end
        exportStrC = strListC(~strNotAvailableV);
        
        if ~isempty(exportStrC) || ismember(planNum,testIdxV)
            
            exportLabelV = labelV(~strNotAvailableV);
            
            
            %Get structure ID and assoc scan
            strIdxV = nan(length(exportStrC),1);
            for strNum = 1:length(exportStrC)
                
                currentLabelName = exportStrC{strNum};
                strIdxV(strNum) = getMatchingIndex(currentLabelName,allStrC,'exact');
                
            end
            
            %Extract scan arrays
            scanC = {};
            maskC = {};
            if isempty(exportStrC) && ismember(planNum,testIdxV)
                scanNumV = 1; %Assume scan 1
            else
                if strcmpi(channelS.append.method,'multiscan')
                    scanNumV = channelS.append.parameters;
                else
                    scanNumV = unique(getStructureAssociatedScan(strIdxV,planC));
                end
            end
            
            UIDc = {planC{indexS.structures}.assocScanUID};
            resM = nan(length(scanNumV),3);
            
            for scanIdx = 1:length(scanNumV)
                
                scan3M = double(getScanArray(scanNumV(scanIdx),planC));
                CTOffset = planC{indexS.scan}(scanNumV(scanIdx)).scanInfo(1).CTOffset;
                scan3M = scan3M - CTOffset;
                
                %Extract masks
                if isempty(exportStrC) && ismember(planNum,testIdxV)
                    mask3M = [];
                    validStrIdxV = [];
                else
                    mask3M = zeros(size(scan3M));
                    assocStrIdxV = strcmpi(planC{indexS.scan}(scanNumV(scanIdx)).scanUID,UIDc);
                    validStrIdxV = ismember(strIdxV,find(assocStrIdxV));
                    validExportLabelV = exportLabelV(validStrIdxV);
                    validStrIdxV = strIdxV(validStrIdxV);
                end
                for strNum = 1:length(validStrIdxV)
                    
                    strIdx = validStrIdxV(strNum);
                    
                    %Update labels
                    tempMask3M = false(size(mask3M));
                    [rasterSegM, planC] = getRasterSegments(strIdx,planC);
                    [maskSlicesM, uniqueSlices] = rasterToMask(rasterSegM, scanNumV(scanIdx), planC);
                    tempMask3M(:,:,uniqueSlices) = maskSlicesM;
                    
                    mask3M(tempMask3M) = validExportLabelV(strNum);
                    
                end
                
                %Pre-processing
                %1. Resample
                if ~strcmpi(resampleS.method,'none')
                    
                    % Get the new x,y,z grid
                    [xValsV, yValsV, zValsV] = getScanXYZVals(planC{indexS.scan}(scanNumV(scanIdx)));
                    if yValsV(1) > yValsV(2)
                        yValsV = fliplr(yValsV);
                    end
                    
                    xValsV = xValsV(1):resampleS.resolutionXCm:(xValsV(end)+10000*eps);
                    yValsV = yValsV(1):resampleS.resolutionYCm:(yValsV(end)+10000*eps);
                    zValsV = zValsV(1):resampleS.resolutionZCm:(zValsV(end)+10000*eps);
                    
                    % Interpolate using sinc sampling
                    numCols = length(xValsV);
                    numRows = length(yValsV);
                    numSlcs = length(zValsV);
                    
                    %Get resampling method
                    if strcmpi(resampleS.method,'sinc')
                        method = 'lanczos3';
                    end
                    scan3M = imresize3(scan3M,[numRows numCols numSlcs],'method',method);
                    mask3M = imresize3(single(mask3M),[numRows numCols numSlcs],'method',method) > 0.5;
                    
                end
                
                %2. Crop
                scanNum = scanNumV(scanIdx);
                mask3M = getMaskForModelConfig(planC,mask3M,scanNum,cropS);
                
                %3. Resize               
             
                indexS = planC{end};
                scan3M = getScanArray(scanNum,planC);
                originImageSizV = size(scan3M);
                CToffset = planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
                scan3M = double(scan3M);
                scan3M = scan3M - CToffset;
%                 if ~isempty(intensityOffset)
%                     scan3M = scan3M + intensityOffset;
%                 end
                [scan3M,rcsM] = resizeScanAndMask(scan3M,mask3M,outSizeV,resizeMethod);
                scanC{scanIdx} = scan3M;
                maskC{scanIdx} = mask3M;                
                
            end
            
            % store rcs for this file
            rcsC{planNum} = rcsM;            
            
            %Populate channels
            scanC = populateChannels(scanC,channelS);
            maskC = populateChannels(maskC,maskChannelS);
            mask3M = maskC{1};
            
            %Get output directory
            if ismember(planNum,trainIdxV)
                outDir = fullfile(HDF5dir,'Train');
            elseif ismember(planNum,valIdxV)
                outDir = fullfile(HDF5dir,'Val');
            else
                if dataSplitV(3)==100
                    %Testing only
                    outDir = HDF5dir;
                else
                    outDir = fullfile(HDF5dir,'Test');
                end
            end
            
            uniformScanInfoS = planC{indexS.scan}(scanNumV(scanIdx)).uniformScanInfo;
            resM(scanIdx,:) = [uniformScanInfoS.grid2Units, uniformScanInfoS.grid1Units, uniformScanInfoS.sliceThickness];
            
            %Export to HDF5
            
            %Get output file prefix
            switch(prefixType)
                case 'inputFileName'
                    identifier = ptName;
                    % Other options to be added
            end
            
            
            for slIdx = 1:size(scanC{1},3)
                
                if ~isempty(mask3M) && dataSplitV(3)<100
                    maskM = uint8(mask3M(:,:,slIdx));
                    maskFilename = fullfile(outDir,'Masks',[identifier,'_slice',...
                        num2str(slIdx),'.h5']);
                    h5create(maskFilename,'/mask',size(maskM));
                    h5write(maskFilename,'/mask',maskM);
                end
                
                exportScan3M = [];
                exportScan3M = scanC{1}(:,:,slIdx);
                if length(scanC)>1
                    for c = 2:length(scanC)
                        exportScan3M = cat(3,exportScan3M,scanC{c}(:,:,slIdx));
                    end
                end
                
                scanFilename = fullfile(outDir,[identifier,'_scan_slice_',...
                    num2str(slIdx),'.h5']);
                h5create(scanFilename,'/scan1',size(exportScan3M));
                h5write(scanFilename,'/scan1',exportScan3M);
            end
            
            resC{planNum} = resM;
            originImageSizC{planNum} = originImageSizV;
        end
        
    catch e
        errC{planNum} =  ['Error processing pt %s. Failed with message: %s',fileNam,e.message];
    end
    
end

save([HDF5dir,filesep,'labelKeyS'],'labelKeyS','-v7.3');
save([HDF5dir,filesep,'resolutionC'],'resC','-v7.3');

%Return error messages if any
idxC = cellfun(@isempty, errC, 'un', 0);
idxV = ~[idxC{:}];
errC = errC(idxV);

fprintf('\nComplete.\n');


end

