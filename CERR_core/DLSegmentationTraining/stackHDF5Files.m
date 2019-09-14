function outC = stackHDF5Files(outPath)
% stackHDF5Files.m
%
% Reads .H5 files with mask slices and returns 3D stacks
%
% AI 9/13/19
%--------------------------------------------------------------------------
%INPUTS:
% outPath       : Path to generated CERR files
% Note: Assumes output filenames are of the form: prefix_slice#
%------------------------------------------------------------------------

dirS = dir(fullfile(outPath,'*.h5'));
fileNameC = {dirS.name};
ptListC = unique(strtok(fileNameC,'_'));
outC = cell(length(ptListC),1);

for p = 1:length(ptListC)
    
    %Get mask filenames for each pt
    matchIdxV = find(strcmp(strtok(fileNameC,'_'),ptListC{p}));
    
    %Stack files
    mask3M = [];
    for s = 1: length(matchIdxV)
        
        slcName = fullfile(outPath,fileNameC{s});
        idx = strfind(slcName,'_slice');
        slcNum = str2double(slcName(idx+6:end-3));
        mask3M(:,:,slcNum) = hdf5read(slcName,'/mask');
        
    end
    
    outC{p} = mask3M;
    
end

end