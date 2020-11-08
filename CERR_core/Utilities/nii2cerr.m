function planC = nii2cerr(filename,scanName,planC,save_flag)
% nii2cerr.m
%
% Import .nii data to CERR
% Usage: planC = nii2cerr(filename,scanName,planC,save_flag);
%
% AI 4/10/19
% EL 10/23/20 support for gzipped nii

if ~exist('planC','var') || isempty(planC)
    planC = [];
end

if ~exist('save_flag','var') || isempty(save_flag)
    save_flag = 0;
end

gzFlag = 0;

% check if files gzipped
fileparts = strsplit(filename,'.');
if strcmp(fileparts{end},'gz') && any(strcmp(fileparts{end - 1},{'img','hdr','nii'}))
    gzFlag = 1;    
    tmpDirPath = fullfile(getCERRPath, 'ImageRegistration', 'tmpFiles');
    if strcmp(fileparts{end - 1},'nii')
        filegz = filename;
        ungzfile = gunzip(filegz,tmpDirPath);
        filename = ungzfile{1};
    end
    if any(strcmp(fileparts{end - 1},{'hdr','img'}))
        filebase = filename(1:end - 7);
        for ext = {'hdr','img'}
            filegz = [filebase '.hdr.gz'];
            ungzfile = gunzip(filegz, tmpDirPath);
        end
        filename = ungzfile{1};
    end
end

% read nifti file
[vol3M,infoS] = nifti_read_volume(filename);

scanOffset = 0;
volMin = min(vol3M(:));
if volMin<0
    scanOffset = -volMin;
end
infoS.Offset = [0 0 0];
infoS.PixelDimensions = infoS.pixdim;
infoS.Dimensions = infoS.dimension(2:4);
planC = mha2cerr(infoS,vol3M,scanOffset,scanName,planC,save_flag);

%remove temp unzipped files
if gzFlag
    filebase = filename(1:end-4);
    delete([filebase filesep '*']);
end

end