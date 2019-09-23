function writeHDF5ForDL(scanC,mask3M,passedScanDim,outDir,filePrefix,testFlag)
%
% Script to write extracted scan and mask to HDf5 for DL.
%
% AI 9/18/19
% -------------------------------------------------------------------------
% INPUTS:
%
% scanC          : Extracted scan(s)
% mask3M         : Extracted mask
% passedScanDim  : May be '2D' or '3D'
% outDir         : Path to output directory
% filePrefix     : File prefix. E.g. Pass CERR file name
% testFlag       : Set flag to true for test dataset to skip mask export.
%                  Default:true. Assumes testing dataset if not specified.
% -------------------------------------------------------------------------
% AI 9/19/19 Updated to support 3D export

% Set defaults
if ~exist('testFlag','var')
    testFlag = true;
end

%Write scan and mask
switch (passedScanDim)
    
    case '3D'
        
        %Write mask
        if ~isempty(mask3M) && ~testFlag
            if ~exist(fullfile(outDir,'Masks'),'dir')
                mkdir(fullfile(outDir,'Masks'))
            end
            mask3M = uint8(mask3M);
            maskFilename = fullfile(outDir,'Masks',[filePrefix,'_3D.h5']);
            h5create(maskFilename,'/mask',size(mask3M));
            h5write(maskFilename,'/mask',mask3M);
        end
        
        %Write scan
        exportScan3M = scanC{1};
        scanFilename = fullfile(outDir,[filePrefix,'_scan_3D.h5']);
        h5create(scanFilename,'/scan',size(exportScan3M));
        h5write(scanFilename,'/scan',exportScan3M);
        
        
    case '2D'
        
        % Loop over slices
        for slIdx = 1:size(scanC{1},3)
            
            %Write mask
            if ~isempty(mask3M) && ~testFlag
                if slIdx == 1
                    if ~exist(fullfile(outDir,'Masks'),'dir')
                        mkdir(fullfile(outDir,'Masks'))
                    end
                end
                maskM = uint8(mask3M(:,:,slIdx));
                maskFilename = fullfile(outDir,'Masks',[filePrefix,'_slice',...
                    num2str(slIdx),'.h5']);
                h5create(maskFilename,'/mask',size(maskM));
                h5write(maskFilename,'/mask',maskM);
            end
            
            %Write scan
            exportScan3M = [];
            exportScan3M = scanC{1}(:,:,slIdx);
            if length(scanC)>1
                for c = 2:length(scanC)
                    exportScan3M = cat(3,exportScan3M,scanC{c}(:,:,slIdx));
                end
            end
            
            scanFilename = fullfile(outDir,[filePrefix,'_scan_slice_',...
                num2str(slIdx),'.h5']);
            h5create(scanFilename,'/scan1',size(exportScan3M));
            h5write(scanFilename,'/scan1',exportScan3M);
            
        end
        
        
end

end