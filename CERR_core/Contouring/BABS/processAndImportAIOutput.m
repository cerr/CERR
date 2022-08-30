function [planC,origScanNumV,allLabelNamesC,dcmExportOptS] = ...
processAndImportAIOutput(planC,userOptS,scanNumV,sessionPath,cmdFlag,hWait)
% [planC,,origScanNumV,allLabelNamesC,dcmExportOptS] = ...
% processAndImportAIOutput(planC,userOptS,scanNumV,sessionPath,cmdFlag,hWait)
%--------------------------------------------------------------------------
% AI 08/29/22

outputS = userOptS.output;

%Loop over model outputs
outputC = fieldnames(outputS);
for nOut = 1:length(outputC)

    outType = outputC{nOut};

    switch(lower(outType))

        %Segmentations
        case 'labelmap'

            % Common for client and server
            roiDescrpt = '';
            gitHash = 'unavailable';
            if isfield(outputS.labelMap,'roiGenerationDescription')
                roiDescrpt = outputS.labelMap.roiGenerationDescription;
            end
            if strcmpi(cmdFlag,'singcontainer')
                [~,hashChk] = system(['singularity apps ' containerPathC{k},...
                    ' | grep get_hash'],'-echo');
                if ~isempty(hashChk)
                    [~,gitHash] = system(['singularity run --app get_hash ',...
                        containerPathC{k}],'-echo');
                end
                roiDescrpt = [roiDescrpt, '  __git_hash:',gitHash];
            end
            outputS.labelMap.roiGenerationDescription = roiDescrpt;

            % Import segmentations
            if ishandle(hWait)
                waitbar(0.9,hWait,'Importing segmentation results to CERR');
            end
            [planC,origScanNumV] = processAndImportSeg(planC,scanNumV,...
                sessionPath,userOptS);

            % Get list of auto-segmented structures
            if ischar(outputS.labelMap.strNameToLabelMap)
                labelDatS = readDLConfigFile(fullfile(AIoutputPath,...
                    userOptS.strNameToLabelMap));
                labelMapS = labelDatS.strNameToLabelMap;
            else
                labelMapS = outputS.labelMap.strNameToLabelMap;
            end
            allLabelNamesC = {labelMapS.structureName};

            % Get DICOM export settings
            if isfield(outputS.labelMap, 'dicomExportOptS')
                if isempty(dcmExportOptS)
                    dcmExportOptS = outputS.labelMap.dicomExportOptS;
                else
                    dcmExportOptS = dissimilarInsert(dcmExportOptS,...
                        outputS.labelMap.dicomExportOptS);
                end
            else
                if ~exist('dcmExportOptS','var')
                    dcmExportOptS = [];
                end
            end

        %Deformation vector field
        %case 'DVF'

        otherwise
            error('Invalid output type '' %s ''.',outType)

    end
    userOptS.output.(outType) =  outputS;

end

end