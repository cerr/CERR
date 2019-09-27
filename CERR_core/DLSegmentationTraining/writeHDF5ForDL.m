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
                % Low-level h5 write
                filename = maskFilename;
                fileID = H5F.create(filename,'H5F_ACC_TRUNC','H5P_DEFAULT','H5P_DEFAULT');
                datatypeID = H5T.copy('H5T_NATIVE_DOUBLE');
                dims = size(maskM);
                dataspaceID = H5S.create_simple(2,fliplr(dims),[]);
                dsetname = '/mask';
                datasetID = H5D.create(fileID,dsetname,datatypeID,dataspaceID,'H5P_DEFAULT');
                H5D.write(datasetID,'H5ML_DEFAULT','H5S_ALL','H5S_ALL',...
                    'H5P_DEFAULT',maskM);
                H5D.close(datasetID);
                H5S.close(dataspaceID);
                H5T.close(datatypeID);
                H5F.close(fileID);
                
                
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
            % Low-level h5 write
            filename = scanFilename;
            fileID = H5F.create(filename,'H5F_ACC_TRUNC','H5P_DEFAULT','H5P_DEFAULT');
            datatypeID = H5T.copy('H5T_NATIVE_DOUBLE');
            dims = size(exportScan3M);
            dataspaceID = H5S.create_simple(2,fliplr(dims),[]);
            dsetname = '/scan';
            datasetID = H5D.create(fileID,dsetname,datatypeID,dataspaceID,'H5P_DEFAULT');
            H5D.write(datasetID,'H5ML_DEFAULT','H5S_ALL','H5S_ALL',...
                'H5P_DEFAULT',exportScan3M);
            H5D.close(datasetID);
            H5S.close(dataspaceID);
            H5T.close(datatypeID);
            H5F.close(fileID);
            
            
        end
        
        
end

end