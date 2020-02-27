function outDirC = getOutputH5Dir(defaultDir,userOptS,split)
% getOutputH5Dir.m
% Get path to directory for writing HDF5 files
%
% AI 2/24/20
%------------------------------------------------------------------------
% INPUTS
% defaultDir  : User-specified base path
% userOptS    : Parameter dictionary listing data split, views etc
% split       : May be 'train', 'val' ,'test' or empty (for inference only).
%------------------------------------------------------------------------

outDirC = {};

%Define paths for different views
if length(userOptS.view)>1
    viewC = userOptS.view;
    for i=1:length(viewC)
        outDirC{i} = fullfile(defaultDir,viewC{i});
    end
else
    outDirC{1} = defaultDir;
end

%Define paths for train/val/test split where needed
if isempty(split)
    %Do nothing (assumes testing only)
else
    switch lower(split)
        case 'train'
            outDirC = fullfile(outDirC,'Train');
        case 'val'
            outDirC = fullfile(outDirC,'Val');
        case 'test'
            outDirC = fullfile(outDirC,'Test');
    end
end

%Create output directories
for i =1:length(outDirC)
    if ~exist(outDirC{i},'dir')
        mkdir(outDirC{i});
    end
end



end