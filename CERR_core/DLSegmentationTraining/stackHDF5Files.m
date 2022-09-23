function [outC,ptListC] = stackHDF5Files(outPath,passedScanDim)
% stackHDF5Files.m
%
% Reads .H5 files with mask slices and returns 3D stacks
%
% AI 9/13/19
%--------------------------------------------------------------------------
%INPUTS:
% outPath       : Path to generated H5 files
%                 Note: Assumes output filenames are of the form: prefix_slice# if
%                 passedScanDim = '2D' and of the form prefix_3D if passedScanDim = '3D'.
%------------------------------------------------------------------------
% RKP 9/18/2019 Updates for compatibility with testing pipeline

dirS = dir(fullfile(outPath,'outputH5','*.h5'));
fileNameC = {dirS.name};
ptListC = unique(strtok(fileNameC,'_'));
outC = cell(length(ptListC),1);

for p = 1:length(ptListC)
    
    %Get mask filenames for each pt
    matchIdxV = find(strcmp(strtok(fileNameC,'_'),ptListC{p}));
    
    switch(passedScanDim)
        case '3D'
            
            fileName = fullfile(outPath,'outputH5',fileNameC{matchIdxV});
            mask3M = h5read(fileName,'/mask');
            mask3M = permute(mask3M,[3 2 1]);
            
        case '2D'
            %Stack files
            mask3M = [];
            for s = 1: length(matchIdxV)
                
                slcName = fullfile(outPath,'outputH5',...
                          fileNameC{matchIdxV(s)});
                idx = strfind(slcName,'_slice');
                slcNum = str2double(slcName(idx+7:end-3));
                labelM = h5read(slcName,'/mask').';
                mask3M(:,:,slcNum) = labelM;
                
                
            end
    end
    
    outC{p} = mask3M;
    
end

end