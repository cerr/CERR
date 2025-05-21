function writeHDF5ForDL(scanC,maskC,passedScanDim,coordInfoS,outDirC,...
    filePrefix,testFlag)
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
% coordInfoS     : Dictionary of scan metadata
% outDirC        : Path to output directory
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
        if ~isempty(maskC{1}) && ~testFlag
            mask4M = maskC{1}{1};
            if ~isempty(mask4M)
                if ~exist(fullfile(outDirC{1},'Masks'),'dir')
                    mkdir(fullfile(outDirC{1},'Masks'))
                end
                mask4M = uint8(mask4M);
                maskFilename = fullfile(outDirC{1},'Masks',[filePrefix,'_4D.h5']);
                h5create(maskFilename,'/mask',size(mask4M));
                pause(0.1)
                h5write(maskFilename,'/mask',mask4M);
            end
        end

        %Write scan
        exportScan3M = scanC{1}{1}; % one view and one scan matrix
        %exportScan3M = scanC{1};
        scanFilename = fullfile(outDirC{1},[filePrefix,'_scan_3D.h5']);
        h5create(scanFilename,'/scan',size(exportScan3M));
        pause(0.1)
        h5write(scanFilename,'/scan',exportScan3M);

        % Write metadata to file
        metadataFilename = scanFilename;
        fileID = fopen(scanFilename,'a+');
        infoC = fieldnames(coordInfoS);
        rank = 2;
        closeFlag = 0;
        for nField = 1:length(infoC)
            info = coordInfoS.(infoC{nField});
            dims = size(info);
            dsetname = ['/',infoC{nField}];
            success = lowLevelH5Write(fileID,metadataFilename,dims,...
                dsetname,info,rank,closeFlag);
        end
        fclose(fileID);

    case '2D'

        %Loop over views
        for i = 1:length(scanC)

            closeFileFlag = 0;

            % Loop over slices
            for slIdx = 1:size(scanC{i}{1},3)

                %Write mask
                if ~isempty(maskC) && ~isempty(maskC{i}) && ~testFlag
                    mask4M = maskC{i}{1};

                    if slIdx == 1
                        if ~exist(fullfile(outDirC{i},'Masks'),'dir')
                            mkdir(fullfile(outDirC{i},'Masks'))
                        end
                    end
                    maskM = uint8(squeeze(mask4M(:,:,slIdx,:)));
                    maskFilename = fullfile(outDirC{i},'Masks',...
                        [filePrefix,'_slice',num2str(slIdx),'.h5']);

                    % Low-level h5 write
                    dims = size(maskM);
                    dsetname = '/mask';
                    rank = 2;
                    fileID = H5F.create(maskFilename,'H5F_ACC_TRUNC',...
                        'H5P_DEFAULT','H5P_DEFAULT');
                    success = lowLevelH5Write(fileID,maskFilename,dims,...
                        dsetname,maskM,rank,1);
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

                % Low-level h5 write
                scanFilename = fullfile(outDirC{i},[filePrefix,'_scan_slice_',...
                    num2str(slIdx),'.h5']);
                dims = size(exportScan3M);
                if length(dims)==2
                    rank = 2;
                else
                    rank = 3; %Multiple channels
                end
                dsetname = '/scan';
                fileID = H5F.create(scanFilename,'H5F_ACC_TRUNC',...
                    'H5P_DEFAULT','H5P_DEFAULT');
                success = lowLevelH5Write(fileID,scanFilename,dims,...
                    dsetname,exportScan3M,rank,closeFileFlag);

                % Write metadata to file
                metadataFilename = scanFilename;
                infoC = fieldnames(coordInfoS);
                rank = 2;
                for nField = 1:length(infoC)
                    dims = size(coordInfoS.(infoC{nField}));
                    dsetname = ['/',infoC{nField}];
                    if nField == length(infoC)
                        closeFileFlag = 1;
                    end
                    success = lowLevelH5Write(fileID,metadataFilename,...
                        dims,dsetname,coordInfoS.(infoC{nField}),...
                        rank,closeFileFlag);
                end

            end
        end

end



%% Supporting functions
    function success = lowLevelH5Write(fileID,filename,dims,dsetname,dataM,...
            rank,closeFlag)

        success = 1;
        try
            datatypeID = H5T.copy('H5T_NATIVE_DOUBLE');
            dataspaceID = H5S.create_simple(rank,fliplr(dims),fliplr(dims));
            datasetID = H5D.create(fileID,dsetname,datatypeID,...
                dataspaceID,'H5P_DEFAULT');
            H5D.write(datasetID,'H5ML_DEFAULT','H5S_ALL','H5S_ALL',...
                'H5P_DEFAULT',dataM);
            if closeFlag
                H5D.close(datasetID);
                H5S.close(dataspaceID);
                H5T.close(datatypeID);
                H5F.close(fileID);
            end

        catch e
            success = 0;
        end


    end

end