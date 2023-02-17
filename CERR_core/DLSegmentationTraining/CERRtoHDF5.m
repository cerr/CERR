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
%AI 9/18/20 Extended to handle multiple scans

%% Get user inputs
dataSplitV = userOptS.dataSplit;
if isfield(userOptS,'exportedFilePrefix')
    prefixType = userOptS.exportedFilePrefix;
else
    prefixType = 'inputFileName';
end
scanOptS = userOptS.input.scan;
passedScanDim = userOptS.passedScanDim;
if isfield(userOptS.input,'strNameToLabelMap')
    labelKeyS = userOptS.input.strNameToLabelMap;
    strListC = {labelKeyS.structureName};
    labelV = [labelKeyS.value];
else
    strListC = {};
    labelKeyS = [];
end
skipMaskExport = false;

%% Get data split
[trainIdxV,valIdxV,testIdxV] = randSplitData(CERRdir,dataSplitV);


%% Batch convert CERR to HDF5
modelFmt = userOptS.modelInputFormat;
fprintf('\nConverting data to %s...\n',modelFmt);

%Open parallel pool
%p = gcp('nocreate');
%if isempty(p)
%    p = parpool();
%    closePool = 1;
%else
    closePool = 0;
%end

%Loop over CERR files
dirS = dir(fullfile(CERRdir,filesep,'*.mat'));

errC = {};

%par
for planNum = 1:length(dirS)

    %try

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
            %if isempty(strListC)
            % testFlag = true;
            %else
            % testFlag = false;
            %end
            testFlag = true;
        end
        [scanC, maskC,~,scanNumV,~,coordInfoS,planC] = ...
            extractAndPreprocessDataForDL(userOptS,planC,testFlag);

        %Save ROI to planC if selected
        ROIsaveFlag = 0;
        scanS = userOptS.input.scan;
        for scanIdx = 1:length(scanS)
            cropMethodsC = {scanS(scanIdx).crop.method};
            if length(cropMethodsC)>1 || ~all(strcmp(cropMethodsC,'none'))
                cropS = scanS(scanIdx).crop;
                if isfield(cropS,'params')
                    parS = cropS.params;
                    if isfield(parS,'saveStrToPlanCFlag') && ...
                            parS.saveStrToPlanCFlag
                        ROIsaveFlag = 1;
                        break
                    end
                end
            end
        end
        if ROIsaveFlag
            save_planC(planC,[],'PASSED',fileNam);
        end

        %Export to HDF5
        %- Get split
        if ismember(planNum,trainIdxV)
            split = 'Train';
        elseif ismember(planNum,valIdxV)
            split = 'Val';
        else
            if dataSplitV(3)==100 %Testing only
                split = '';
            else
                split ='Test';
            end
        end

        %- Get output file prefix
        switch(prefixType)
            case 'inputFileName'
                identifier = ptName;
                % Other options to be added
            otherwise
                %default
                identifier = 'cerrFile';
        end

        %- Write to user-selected format
        %Loop over scan types
        for n = 1:size(scanC,1)

            %Append identifiers to o/p name
            idOut = getOutputFileNameForDL(identifier,scanOptS(n),...
                scanNumV(n),planC);

            %Get o/p dirs & dim
            outDirC = getOutputH5Dir(HDF5dir,scanOptS(n),split);

            %Write to model input fmt
            writeDataForDL(scanC{n},maskC{n},coordInfoS,passedScanDim,...
                modelFmt,outDirC,idOut,skipMaskExport);

        end

    %catch e

    %   errC{planNum} =  ['Error processing pt %s. Failed with message: %s',fileNam,e.message];

    %end

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