function [planC,allLabelNamesC,dcmExportOptS,success] = ...
    processAndImportSeg(planC,origScanNumV,scanNumV,outputScanNum,...
    fullSessionPath,userOptS)
% planC = processAndImportSeg(planC,origScanNumV,scanNumV,fullSessionPath,userOptS);
%-------------------------------------------------------------------------
% INPUTS
% planC           : planC OR path to directory containing CERR files.
% origScanNumV    : User-input or obtained from scan identifiers.
% scanNumV        : (Processed) Scan nos input to model
% outputScanNum   : Scan no. for output association 
%                   (scan identifier used if empty).
% fullSessionPath : Full path to session dir
% userOptS        : Dictionary of post-processing parameters.
%-------------------------------------------------------------------------
% AI 9/21/21

%-For structname-to-label map
labelPath = fullfile(fullSessionPath,'outputLabelMap');

% Read structure masks
outFmt = userOptS.modelOutputFormat;
passedScanDim = userOptS.passedScanDim;
[outC,ptListC] = stackDLMaskFiles(fullSessionPath,outFmt,passedScanDim);

% Import to CERR
success = 0;
if ~iscell(planC)
    cerrPath = planC;
    % Load from file
    planCfileS = dir(fullfile(cerrPath,'*.mat'));
    planCfilenameC = {planCfileS.name};
    %origScanNumV = nan(1,length(planCfilenameC));
    for nFile = 1:length(planCfilenameC)
        tic
        [~,ptName,~] = fileparts(planCfilenameC{nFile});
        planCfilename = fullfile(cerrPath, planCfilenameC{nFile});
        planC = loadPlanC(planCfilename,tempdir);
        
        ptIdx = ~cellfun(@isempty, strfind(ptListC, strtok(ptName,'_')));
        segMask3M = outC{ptIdx};

        planC = importLabelMap(userOptS,origScanNumV,scanNumV,...
                              outputScanNum,segMask3M,labelPath,planC);
        %origScanNumV(nFile) = origScanNum;

        %Save planC
        optS = [];
        saveflag = 'passed';
        save_planC(planC,optS,saveflag,planCfilename);
        toc
    end
    planC = cerrPath;
else
    segMask3M = outC{1};
    tic
    planC = importLabelMap(userOptS,origScanNumV,scanNumV,outputScanNum,...
            segMask3M,labelPath,planC);
    toc
end

success = 1;

% Get list of auto-segmented structures
AIoutputPath = fullfile(fullSessionPath,'AIoutput');
if ischar(userOptS.output.labelMap.strNameToLabelMap)
    labelDatS = readDLConfigFile(fullfile(AIoutputPath,...
        userOptS.strNameToLabelMap));
    labelMapS = labelDatS.strNameToLabelMap;
else
    labelMapS = userOptS.output.labelMap.strNameToLabelMap;
end
allLabelNamesC = {labelMapS.structureName};

% Get DICOM export settings
if isfield(userOptS.output.labelMap, 'dicomExportOptS')
    if isempty(dcmExportOptS)
        dcmExportOptS = userOptS.output.labelMap.dicomExportOptS;
    else
        dcmExportOptS = dissimilarInsert(dcmExportOptS,...
            userOptS.output.labelMap.dicomExportOptS);
    end
else
    if ~exist('dcmExportOptS','var')
        dcmExportOptS = [];
    end
end



%% ----- Supporting functions ----
    function planC = importLabelMap(userOptS,origScanNumV,scanNumV,...
                     outputScanNum,segMask3M,labelPath,planC)

        indexS = planC{end};
        if isempty(outputScanNum) || isnan(outputScanNum)
            identifierS = userOptS.outputAssocScan.identifier;
            idS = rmfield(identifierS,{'warped','filtered'});
            idC = fieldnames(idS);
            if ~isempty(idC)
                origScanNum = getScanNumFromIdentifiers(identifierS,planC);
                if ismember(origScanNum,scanNumV)
                    origScanNum = find(origScanNumV==origScanNum);
                end
            else
                origScanNum = 1; %Assoc with first scan by default
            end
        else
            origScanNum = find(origScanNumV==outputScanNum);
        end
        outScanNum = scanNumV(origScanNum);
        userOptS.input.scan(outScanNum) = userOptS.input.scan(origScanNum);
        userOptS.input.scan(outScanNum).origScan = origScanNum;
        [segMask3M,~,planC]  = joinH5planC(outScanNum,segMask3M,labelPath,...
            userOptS,planC);

        % Post-process segmentation
        if sum(segMask3M(:))>0
            fprintf('\nPost-processing results...\n');
            tic
            planC = postProcStruct(planC,userOptS);
            toc
        end

        % Delete intermediate (resampled) scans if any
        scanListC = arrayfun(@(x)x.scanType, planC{indexS.scan},'un',0);
        resampScanName = ['Resamp_scan',num2str(origScanNum)];
        matchIdxV = ismember(scanListC,resampScanName);
        if any(matchIdxV)
            deleteScanNum = find(matchIdxV);
            planC = deleteScan(planC,deleteScanNum);
        end

    end
end