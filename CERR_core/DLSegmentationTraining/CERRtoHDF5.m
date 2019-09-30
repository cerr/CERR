function errC = CERRtoHDF5(CERRdir,HDF5dir,userOptS)
% CERRtoHDF5.m
%
% Script to export scan and mask files in HDF5 format, split into training,
% validation, and test datasets.
% Mask: Numerical labels are assigned following the order of
% structure names input (strListC). Background voxels are assigned label=0.
%
%
% AI 3/12/19
%--------------------------------------------------------------------------
%INPUTS:
% CERRdir       : Path to generated CERR files
% HDF5dir       : Path to generated HDF5 files
% userOptS      : Options for resampling, cropping, resizing etc.
%                 See sample file: CERR_core/DLSegmentationTraining/sample_train_params.json
%--------------------------------------------------------------------------
%AI 9/3/19 Added resampling option
%AI 9/4/19 Options to populate channels
%AI 9/11/19 Updated for compatibility with testing pipeline
%RKP 9/14/19 Additional updates for compatibility with testing pipeline
%AI 9/18/19 Modularized

%% Get user inputs
dataSplitV = userOptS.dataSplit;
prefixType = userOptS.exportedFilePrefix;
passedScanDim = userOptS.passedScanDim;
if isfield(userOptS,'structList')
    strListC = userOptS.structList;
else
    strListC = {};
end

%% Get data split
[trainIdxV,valIdxV,testIdxV] = randSplitData(CERRdir,dataSplitV);


%% Batch convert CERR to HDF5
fprintf('\nConverting data to HDF5...\n');

%Label key
if ~isempty(strListC)
    labelKeyS = struct();
    for n = 1:length(strListC)
        labelKeyS.(strListC{n}) = n;
    end
else
    labelKeyS = [];
end

%Open parallel pool
p = gcp('nocreate');
if isempty(p)
    p = parpool();
    closePool = 1;
else
    closePool = 0;
end

%Loop over CERR files
dirS = dir(fullfile(CERRdir,filesep,'*.mat'));
errC = {};

parfor planNum = 1:length(dirS)
    
    try
        
        %Load file
        fprintf('\nProcessing pt %d of %d...\n',planNum,length(dirS));
        [~,ptName,~] = fileparts(dirS(planNum).name);
        fileNam = fullfile(CERRdir,dirS(planNum).name);
        planC = loadPlanC(fileNam, tempdir);
        planC = updatePlanFields(planC);
        planC = quality_assure_planC(fileNam,planC);
        
        %Extract scan and mask and preprocess based on user input
        if ~ismember(planNum,testIdxV)
            testFlag = false;
        else
            if isempty(strListC)
                testFlag = true;
            else
                testFlag = false;
            end
        end
        [scanC, mask3M] = extractAndPreprocessDataForDL(userOptS,planC,testFlag);
        
        %Export to HDF5
        
        %- Get output directory
        if ismember(planNum,trainIdxV)
            outDir = fullfile(HDF5dir,'Train');
        elseif ismember(planNum,valIdxV)
            outDir = fullfile(HDF5dir,'Val');
        else
            if dataSplitV(3)==100 %Testing only
                outDir = HDF5dir;
            else
                outDir = fullfile(HDF5dir,'Test');
            end
        end
        
        %- Get output file prefix
        switch(prefixType)
            case 'inputFileName'
                identifier = ptName;
                % Other options to be added
        end
        
        %- Write to HDF5
        writeHDF5ForDL(scanC,mask3M,passedScanDim,outDir,identifier,testFlag)
        
    catch e
        
        errC{planNum} =  ['Error processing pt %s. Failed with message: %s',fileNam,e.message];
        
    end
    
end

if ~isempty(labelKeyS)
    save([HDF5dir,filesep,'labelKeyS'],'labelKeyS','-v7.3');
end

%Return error messages if any
idxC = cellfun(@isempty, errC, 'un', 0);
idxV = ~[idxC{:}];
errC = errC(idxV);

fprintf('\nComplete.\n');

%Close parallel pool
if closePool
    delete(p); 
end

end