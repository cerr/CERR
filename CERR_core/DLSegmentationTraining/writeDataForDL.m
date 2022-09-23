function writeDataForDL(scanC,maskC,coordInfoS,passedScanDim,outFmt,outDirC,...
    filePrefix,testFlag)
% Write extracted scan and mask to DL model input format.
%
% -------------------------------------------------------------------------
% INPUTS:
%
% scanC          : Extracted scan(s)
% maskC          : Extracted masks (for different views)
% coordInfoS     : Structure array with fields 'affineM','originV','voxSizV' 
%                  specifying affine transformation matrix, origin and for
%                  voxel size for each input scan. NOTE: Not reqd (empty) 
%                  for H5 fmt.
% passedScanDim  : May be '2D' or '3D'. NRRD/NIFTI outputs assumed 3D.
% outFmt         : Output format. May be 'NRRD','NIFTI',or 'H5' (default). 
% outDirC        : Path to output directory
% filePrefix     : File prefix. E.g. Pass CERR file name
% testFlag       : Set flag to true for test dataset to skip mask export.
%                  Default:true. Assumes testing dataset if not specified.
% -------------------------------------------------------------------------
% AI 06/29/21

% Set defaults
if ~exist('testFlag','var')
    testFlag = true;
end


%Write scan and mask
switch upper(outFmt)
    
    case 'H5'
        
        writeHDF5ForDL(scanC,maskC,passedScanDim,coordInfoS,outDirC,...
            filePrefix,testFlag);
        
    case 'NRRD'
        
        %Assumes single scan, with passedScanDim '3D'.
        vol3M = scanC{1}{1};
        affineM = coordInfoS.affineM;
        originV = coordInfoS.originV;
        voxSizV = coordInfoS.voxSizV;
        scanFileName = fullfile(outDirC{1},[filePrefix,'.nrrd']);
        vol2nrrd(vol3M,affineM,originV,voxSizV,[],scanFileName);
        
   case 'NIFTI'
       
        %Assumes single scan, with passedScanDim '3D'.
        vol3M = scanC{1}{1};
        affineM = coordInfoS.affineM;
        originV = coordInfoS.originV;
        voxSizV = coordInfoS.voxSizV;
        scanFileName = fullfile(outDirC{1},[filePrefix,'.nii']);
        vol2nii(vol3M,affineM,originV,voxSizV,[],scanFileName);

        mask3M = maskC{1}{1};
        if ~isempty(mask3M)
            maskDir = fullfile(outDirC{1},'Masks');
            if ~exist(maskDir,'dir')
                mkdir(maskDir)
            end
            idx = strfind(filePrefix,'scan');
            maskFileName = [filePrefix(1:idx-1),'mask.nii'];
            maskFileName = fullfile(maskDir,maskFileName);
            vol2nii(mask3M,affineM,originV,voxSizV,[],maskFileName);
        end

    otherwise
          error('invalid output format %s',outFmt);
        
end

end