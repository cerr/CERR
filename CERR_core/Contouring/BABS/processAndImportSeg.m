function [planC,outScanNum,allLabelNamesC,dcmExportOptS,success] = ...
    processAndImportSeg(planC,origScanNumV,scanNumV,outputScanNum,...
    fullSessionPath,userOptS,dcmExportOptS)
% Function to process and import AI segmentaitons to CERR. 
% Note: 4-D segmentation maps are expected (4th dim corresponds to
% structure label)
% planC = processAndImportSeg(planC,origScanNumV,scanNumV,...
%         fullSessionPath,userOptS);
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
lableMapS = struct([]);
if isfield(userOptS.output,'labelMap') &&...
        isfield(userOptS.output.labelMap,'strNameToLabelMap') 
    lableMapS = userOptS.output.labelMap.strNameToLabelMap;
end
[outC,ptListC] = stackDLMaskFiles(fullSessionPath,outFmt,...
                            passedScanDim,lableMapS);

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
        segMask4M = outC{ptIdx};

        [planC,outScanNum] = importLabelMap(userOptS,origScanNumV,scanNumV,...
                              outputScanNum,segMask4M,labelPath,planC);
        %origScanNumV(nFile) = origScanNum;

        %Save planC
        optS = [];
        saveflag = 'passed';
        save_planC(planC,optS,saveflag,planCfilename);
        toc
    end
    planC = cerrPath;
else
    segMask4M = outC{1};
    tic
    [planC,outScanNum] = importLabelMap(userOptS,origScanNumV,scanNumV,outputScanNum,...
            segMask4M,labelPath,planC);
    toc
end

success = 1;

% Get list of auto-segmented structures
AIoutputPath = fullfile(fullSessionPath,'outputLabelMap');
if ischar(userOptS.output.labelMap.strNameToLabelMap)
    labelDatS = jsondecode(fileread(fullfile(AIoutputPath,...
        userOptS.output.labelMap.strNameToLabelMap)));
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
end

%% ----- Supporting functions ----
    function [planC,outScanNum] = importLabelMap(userOptS,...
            origScanNumV,scanNumV,outputScanNum,...
            segMask4M,labelPath,planC)

        indexS = planC{end};
        
        if isempty(outputScanNum) || isnan(outputScanNum)
            %Identify output scan
            identifierS = userOptS.outputAssocScan.identifier;
            idS = rmfield(identifierS,{'warped','filtered'});
            idC = fieldnames(idS);
                       
            if ~isempty(idC)
                origScanIdx = getScanNumFromIdentifiers(identifierS,planC);
                %if ismember(origScanNum,scanNumV)
                    origScanIdx = find(origScanNumV==origScanIdx);
                %end
            else
                origScanIdx = 1; %Assoc with first scan by default
            end
        else
            origScanIdx = find(origScanNumV==outputScanNum);
        end
        outScanNum = scanNumV(origScanIdx);
        userOptS.input.scan(outScanNum) = userOptS.input.scan(origScanIdx);
        userOptS.input.scan(outScanNum).origScan = origScanNumV(origScanIdx);
        [segMask4M,~,~,planC]  = joinH5planC(outScanNum,segMask4M,labelPath,...
            userOptS,planC);

        % Post-process segmentation
        if sum(segMask4M(:))>0
            fprintf('\nPost-processing results...\n');
            tic
            planC = postProcStruct(planC,userOptS);
            toc
        end

        % Delete intermediate (resampled) scans if any
        scanListC = arrayfun(@(x)x.scanType, planC{indexS.scan},'un',0);
        resampScanName = ['Resamp_scan',num2str(origScanNumV(origScanIdx))];
        matchIdxV = ismember(scanListC,resampScanName);
        if any(matchIdxV)
            deleteScanNum = find(matchIdxV);
            planC = deleteScan(planC,deleteScanNum);
        end

    end
end