function [planC,origScanNumV,allLabelNamesC,dcmExportOptS] = ...
    processAndImportAIOutput(planC,userOptS,scanNumV,algorithm,hashID,...
    sessionPath,cmdFlag,hWait)
%[planC,,origScanNumV,allLabelNamesC,dcmExportOptS] = ...
%processAndImportAIOutput(planC,userOptS,scanNumV,algorithm,hashID,...
%sessionPath,cmdFlag,hWait)
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

        case 'dvf'
            %Deformation vector field

            outFmt = outputS.DVF.outputFormat;
            DVFpath = fullfile(sessionPath,'outputH5','DVF');
            DVFfile = dir([DVFpath,filesep,'*.h5']);
            outFile = fullfile(DVFpath,DVFfile.name);
            switch(lower(outFmt))
                case 'h5'
                    DVF4M = h5read(outFile,'/dvf');
                otherwise
                    error('Invalid model output format %s.',outFmt)
            end


            % Convert to CERR coordinate sytem

            if ~iscell(planC)
                cerrDir = planC;
                cerrDirS = dir(cerrDir);
                cerrFile = cerrDirS(3).name;
                planC = loadPlanC(fullfile(cerrDir,cerrFile),tempdir);
            else
                cerrFile = '';
            end

            niiOutDir = userOptS.output.DVF.outputDir;
            DVFfilename = strrep(DVFfile.name,'.h5','');
            dimsC = {'dx','dy','dz'};
            niiFileNameC = cell(1,length(dimsC));
            for nDim = 1:size(DVF4M,1)
                DVF3M = squeeze(DVF4M(:,:,:,nDim));
%                 [DVF3M,~] = joinH5planC(scanNum,DVF3M,labelPath,...
%                     userOptS,planC);
                niiFileNameC{nDim} = fullfile(niiOutDir,[DVFfilename,'_'...
                    dimsC{nDim},'.nii.gz']);
                fprintf('\n Writing DVF to file %s',niiFileNameC{nDim});
                DVF3M_nii = make_nii(DVF3M);
                save_nii(DVF3M_nii, niiFileNameC{nDim}, 0);
            end

            % Store to deformS
            indexS = planC{end};
            idS = userOptS.register.baseScan.identifier;
            baseScanNum = getScanNumFromIdentifiers(idS,planC,1);
            idS = userOptS.register.movingScan.identifier;
            movScanNum = getScanNumFromIdentifiers(idS,planC,1);

            planC{indexS.deform}(end+1).baseScanUID = ...
                planC{indexS.scan}(baseScanNum).scanUID;
            planC{indexS.deform}(end+1).movScanUID = ...
                planC{indexS.scan}(movScanNum).scanUID;

            planC{indexS.deform}(end+1).algorithm = algorithm;
            planC{indexS.deform}(end+1).registrationTool = 'CNN';
            planC{indexS.deform}(end+1).algorithmParamsS.singContainerHash = ...
                hashID;
            planC{indexS.deform}(end+1).DVFfileName = niiFileNameC;

            if ~isempty(cerrFile)
                save_planC(planC,[],'PASSED',cerrFile);
                planC = cerrFile;
            end


        otherwise
            error('Invalid output type '' %s ''.',outType)


    end
    userOptS.output.(outType) =  outputS;

end

end