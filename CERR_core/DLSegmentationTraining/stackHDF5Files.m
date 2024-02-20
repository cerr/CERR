function [outC,ptListC] = stackHDF5Files(outPath,passedScanDim,labelMapS)
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
% --- Optional---
%labelMapS    : Stucture name to label# dictionary
%------------------------------------------------------------------------
% RKP 9/18/2019 Updates for compatibility with testing pipeline

if ~exist('labelMapS','var')
    labelMapS = struct([]);
end

dirS = dir(fullfile(outPath,'outputH5','*.h5'));
fileNameC = {dirS.name};
ptListC = unique(strtok(fileNameC,'_'));
outC = cell(length(ptListC),1);

for p = 1:length(ptListC)
    
    %Get mask filenames for each pt
    matchIdxV = find(strcmp(strtok(fileNameC,'_'),ptListC{p}));
    
    switch(passedScanDim)
        case '3D'
            
            fileName = fullfile(outPath,'outputH5',fileNameC{1});
            mask4M = h5read(fileName,'/mask');
            %mask3M = permute(mask3M,[3 2 1]);
            mask4M = permute(mask4M,[4 3 2 1]); %?
            
        case '2D'
            %Stack files
            mask3M = [];
            for s = 1: length(matchIdxV)
                
                slcName = fullfile(outPath,'outputH5',...
                          fileNameC{matchIdxV(s)});
                idx = strfind(slcName,'_slice');
                slcNum = str2double(slcName(idx+7:end-3));
                maskM = h5read(slcName,'/mask');
                maskM = permute(maskM,[3,2,1]);
                mask3M(:,:,slcNum) = maskM;
            end
            if len(labelMapS)>1
                labelsV = [labelMapS.value];
            else
                labelsV = unique(mask3M(:));
                labelsV = labelsV(labelsV~=0);
            end
            mask4M = zeros([size(mask3M),length(labelsV)]);
            for iLab = 1:length(labelsV)
                mask4M(:,:,:,labelsV(iLab)) = mask3M==labelsV(iLab);
            end
            
    end
    
    outC{p} = mask4M;
    
end

end