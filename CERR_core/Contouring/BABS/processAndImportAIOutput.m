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

        case 'labelmap'
        %Segmentations

            % Import segmentations
            if ishandle(hWait)
                waitbar(0.9,hWait,'Importing segmentation results to CERR');
            end
            [planC,origScanNumV,allLabelNamesC,dcmExportOptS] = ...
                processAndImportSeg(planC,scanNumV,sessionPath,userOptS);

        case 'DVF'
        %Deformation vector field

        % Read model output
            %outFile = assign loc in session dir
            outFmt = outputS.modelOutputFormat;
        switch(outFmt)
            case 'h5'
                DVF3M = h5read(outFile,'/dvf');
            otherwise
                error('Invalid model output format %s.',outFmt)
        end

        % Convert to CERR coordinate sytem
        [DVFout3M,planC] = joinH5planC(scanNum,DVF3M,labelPath,...
                             userOptS,planC);

        % Export to nii 
        fprintf('\n Writing DVF to file %s',niiFileName);
        niiFileName = userOptS.output.DVF.dvfOutDir;
        save_nii(DVFout3M, niiFileName);
        
        % Store to deformS
%         planC{indexS.deformS}(end+1).baseScanUID = %x;
%         planC{indexS.deformS}(end+1).movScanUID =  %y;
%         planC{indexS.deformS}(end+1).algorithm =  %alg;
        planC{indexS.deformS}(end+1).registrationTool = 'CNN';
%         planC{indexS.deformS}(end+1).algorithmParamsS.singContainerHash = ...
%             hashid;
        planC{indexS.deformS}(end+1).DVFfileName = niiFileName;

        otherwise
            error('Invalid output type '' %s ''.',outType)


    end
    userOptS.output.(outType) =  outputS;

end

end