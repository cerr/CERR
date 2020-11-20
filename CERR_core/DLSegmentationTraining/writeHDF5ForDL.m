function writeHDF5ForDL(scanC,maskC,passedScanDim,outDirC,filePrefix,testFlag)
%
% Script to write extracted scan and mask to HDf5 for DL.
%
% AI 9/18/19
% -------------------------------------------------------------------------
% INPUTS:
%
% scanC          : Extracted scan(s)
% maskC          : Extracted masks (for different views)
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
        
%         mask3M = maskC{1}{1};
        %Write mask
%         if ~isempty(mask3M) && ~testFlag
        if ~isempty(maskC{1}) && ~testFlag
            mask3M = maskC{1}{1};
            if ~exist(fullfile(outDirC{1},'Masks'),'dir')
                mkdir(fullfile(outDirC{1},'Masks'))
            end
            mask3M = uint8(mask3M);
            maskFilename = fullfile(outDirC{1},'Masks',[filePrefix,'_3D.h5']);
            h5create(maskFilename,'/mask',size(mask3M));
            pause(0.1)
            h5write(maskFilename,'/mask',mask3M);
        end
        
        %Write scan
        exportScan3M = scanC{1}{1}; % one view and one scan matrix
        %exportScan3M = scanC{1};
        scanFilename = fullfile(outDirC{1},[filePrefix,'_scan_3D.h5']);
        h5create(scanFilename,'/scan',size(exportScan3M));
        pause(0.1)
        h5write(scanFilename,'/scan',exportScan3M);
        
        
    case '2D'
        
        %Loop over views
        for i = 1:length(scanC)
            
            % Loop over slices
            for slIdx = 1:size(scanC{i}{1},3)
             
                %Write mask
                if ~isempty(maskC) && ~isempty(maskC{i}) && ~testFlag
                    mask3M = maskC{i};

                    if slIdx == 1
                        if ~exist(fullfile(outDirC{i},'Masks'),'dir')
                            mkdir(fullfile(outDirC{i},'Masks'))
                        end
                    end
                    maskM = uint8(mask3M(:,:,slIdx));
                    maskFilename = fullfile(outDirC{i},'Masks',[filePrefix,'_slice',...
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
                exportScan3M = scanC{i}{1}(:,:,slIdx);
                if length(scanC{i})>1
                    for c = 2:length(scanC{i})
                        temp = scanC{i}{c};
                        exportScan3M = cat(3,exportScan3M,temp(:,:,slIdx));
                    end
                end
                
                scanFilename = fullfile(outDirC{i},[filePrefix,'_scan_slice_',...
                    num2str(slIdx),'.h5']);
                % Low-level h5 write
                filename = scanFilename;
                fileID = H5F.create(filename,'H5F_ACC_TRUNC','H5P_DEFAULT','H5P_DEFAULT');
                datatypeID = H5T.copy('H5T_NATIVE_DOUBLE');
                dims = size(exportScan3M);
                if length(dims)==2
                    rank = 2;
                else
                    rank = 3; %Multiple channels
                end
                dataspaceID = H5S.create_simple(rank,fliplr(dims),[]);
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

end