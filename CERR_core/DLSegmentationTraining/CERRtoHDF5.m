function errC = CERRtoHDF5(CERRdir,HDF5dir,dataSplitV,strListC,outSizeV,resizeMethod,cropMethod,varargin)
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
% strListC      : List of structures to export
% outSizeV      : Image size required by model [height, width]
% resizeMethod  : 'none', 'pad', 'bilinear', 'sinc'
% cropMethod    : 'none','crop_fixed_amt','crop_to_bounding_box'
% varargin      : Parameters for pre-processing
%--------------------------------------------------------------------------


%% Get data split
[trainIdxV,valIdxV,testIdxV] = randSplitData(CERRdir,dataSplitV);


%% Batch convert CERR to HDF5
fprintf('\nConverting data to HDF5...\n');

%Label key
labelKeyS = struct();
for n = 1:length(strListC)
    labelKeyS.(strListC{n}) = n;
end

dirS = dir(fullfile(CERRdir,filesep,'*.mat'));
labelV = 1:length(strListC);

resC = cell(1,length(dirS));
errC = {};
%Loop over CERR files
for planNum = 1:length(dirS)
    
    try
        
        %Load file
        fprintf('\nProcessing pt %d of %d...\n',planNum,length(dirS));
        [~,ptName,~] = fileparts(dirS(planNum).name);
        fileNam = fullfile(CERRdir,dirS(planNum).name);
        planC = loadPlanC(fileNam, tempdir);
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
            if ismember(planNum,testIdxV)
                scanNumV = 1; %Assume scan 1
            else
                scanNumV = unique(getStructureAssociatedScan(strIdxV,planC));
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
                else
                    mask3M = zeros(size(scan3M));
                    assocStrIdxV = strcmpi(planC{indexS.scan}(scanNumV(scanIdx)).scanUID,UIDc);
                    validStrIdxV = ismember(strIdxV,find(assocStrIdxV));
                    validExportLabelV = exportLabelV(validStrIdxV);
                    validStrIdxV = strIdxV(validStrIdxV);
                    
                    for strNum = 1:length(validStrIdxV)
                        
                        strIdx = validStrIdxV(strNum);
                        
                        %Update labels
                        tempMask3M = false(size(mask3M));
                        [rasterSegM, planC] = getRasterSegments(strIdx,planC);
                        [maskSlicesM, uniqueSlices] = rasterToMask(rasterSegM, scanNumV(scanIdx), planC);
                        tempMask3M(:,:,uniqueSlices) = maskSlicesM;
                        
                        mask3M(tempMask3M) = validExportLabelV(strNum);
                        
                    end
                end
                
                %Pre-processing
                %1. Cropping
                [scan3M,mask3M] = cropScanAndMask(planC,scan3M,mask3M,cropMethod,varargin);
                %2. Resizing
                [scan3M,mask3M] = resizeScanAndMask(scan3M,mask3M,outSizeV,resizeMethod);
                
                %Save to HDF5
                if ismember(planNum,trainIdxV)
                    outDir = [HDF5dir,filesep,'Train'];
                elseif ismember(planNum,valIdxV)
                    outDir = [HDF5dir,filesep,'Val'];
                else
                    outDir = [HDF5dir,filesep,'Test'];
                end
                
                uniformScanInfoS = planC{indexS.scan}(scanNumV(scanIdx)).uniformScanInfo;
                resM(scanIdx,:) = [uniformScanInfoS.grid2Units, uniformScanInfoS.grid1Units, uniformScanInfoS.sliceThickness];
                
                for slIdx = 1:size(scan3M,3)
                    %Save data
                    maskM = mask3M(:,:,slIdx);
                    if ~isempty(maskM)
                        maskFilename = fullfile(outDir,'Masks',[ptName,'_slice',...
                            num2str(slIdx),'.h5']);
                        h5create(maskFilename,'/mask',size(maskM));
                        h5write(maskFilename,'/mask',maskM);
                    end
                    
                    scanM = scan3M(:,:,slIdx);
                    scanFilename = fullfile(outDir,[ptName,'_scan_',...
                        num2str(scanIdx),'_slice',num2str(slIdx),'.h5']);
                    h5create(scanFilename,'/scan1',size(scanM));
                    h5write(scanFilename,'/scan1',scanM);
                end
                
            end
            
            resC{planNum} = resM;
            
        end
        
    catch e
        errC{planNum} =  ['Error processing pt %s. Failed with message: %s',fileNam,e.message];
    end
    
    
    idxC = cellfun(@isempty, errC, 'un', 0);
    idxV = ~[idxC{:}];
    errC = errC(idxV);
    
    save([HDF5dir,filesep,'labelKeyS'],'labelKeyS','-v7.3');
    save([HDF5dir,filesep,'resolutionC'],'resC','-v7.3');
    
    
    fprintf('\nComplete.\n');
    
    
end

