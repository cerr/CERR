function writeHDF5ForDL(scanC,maskC,passedScanDim,coordInfoS,outDirC,filePrefix,testFlag)
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
            OctaveExportMask = uint8(mask3M);
            maskFilename = fullfile(outDirC{1},'Masks',[filePrefix,'_3D.h5']);
            save ("-hdf5",maskFilename,"OctaveExportMask")
        end

        %Write scan
        OctaveExportScan = scanC{1}{1};
        scanFilename = fullfile(outDirC{1},[filePrefix,'_scan_3D.h5']);

        %Write metadata
        infoC = fieldnames(coordInfoS);
        for nField = 1:length(infoC)
          eval([infoC{nField} '=coordInfoS.' infoC{nField},';']);
        end
        save ("-hdf5",scanFilename,"OctaveExportScan",infoC{:});

    case '2D'

        %Loop over views
        for i = 1:length(scanC)

            % Loop over slices
            for slIdx = 1:size(scanC{i}{1},3)

                %Write mask
                if ~isempty(maskC) && ~isempty(maskC{i}) && ~testFlag
                    mask3M = maskC{i}{1};

                    if slIdx == 1
                        if ~exist(fullfile(outDirC{i},'Masks'),'dir')
                            mkdir(fullfile(outDirC{i},'Masks'))
                        end
                    end
                    OctaveExportMask = uint8(mask3M(:,:,slIdx));
                    maskFilename = fullfile(outDirC{i},'Masks',[filePrefix,'_slice',...
                        num2str(slIdx),'.h5']);


                    % Low-level h5 write
                    save ("-hdf5",maskFilename,"OctaveExportMask")

                end

                %Write scan
                OctaveExportScan = [];
                OctaveExportScan = scanC{i}{1}(:,:,slIdx);
                if length(scanC{i})>1
                    for c = 2:length(scanC{i})
                        temp = scanC{i}{c};
                        OctaveExportScan = cat(3,OctaveExportScan,temp(:,:,slIdx));
                    end
                end

                %Write scan slice
                scanFilename = fullfile(outDirC{i},[filePrefix,'_scan_slice_',...
                num2str(slIdx),'.h5']);

                %Write metadata
                infoC = fieldnames(coordInfoS);
                for nField = 1:length(infoC)
                  dims = size(coordInfoS.(infoC{nField}));
                  dsetname = infoC{nField};
                  eval([dsetname,'=','coordInfoS.(dsetname);']);
                end
                save ("-hdf5",scanFilename,"OctaveExportScan",infoC{:});

            end
        end


end

end
