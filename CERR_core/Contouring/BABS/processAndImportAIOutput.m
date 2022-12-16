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
                    loadDataS = load(outFile);
                    DVF4M = loadDataS.dvf;
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
            indexS = planC{end};

            % Get associated scan num
            idS = userOptS.outputAssocScan.identifier;
            assocScan = getScanNumFromIdentifiers(idS,planC);

            tempOptS = userOptS;
            outTypesC = fieldnames(userOptS.output);
            matchIdx = strcmpi(outTypesC,'DVF');
            outTypesC = outTypesC(~matchIdx);
            tempOptS.output = rmfield(tempOptS.output,outTypesC);
            niiOutDir = tempOptS.output.DVF.outputDir;
            DVFfilename = strrep(DVFfile.name,'.h5','');
            dimsC = {'dx','dy','dz'};
            niiFileNameC = cell(1,length(dimsC));
            for nDim = 1:size(DVF4M,1)
                DVF3M = squeeze(DVF4M(nDim,:,:,:));
                DVF3M = permute(DVF3M,[2,3,1]);
                [DVF3M,planC] = joinH5planC(assocScan,DVF3M,[DVFfilename,'_'...
                    dimsC{nDim}],tempOptS,planC);
                niiFileNameC{nDim} = fullfile(niiOutDir,[DVFfilename,'_'...
                    dimsC{nDim},'.nii.gz']);
                fprintf('\n Writing DVF to file %s\n',niiFileNameC{nDim});
                DVF3M_nii = make_nii(DVF3M);
                save_nii(DVF3M_nii, niiFileNameC{nDim}, 0);
            end

            %Calc. deformation magnitude
            DVFmag3M = zeros(size(DVF3M));
            assocScanUID = planC{indexS.scan}(assocScan).scanUID;
            for nDim = 1:size(DVF4M,1)
                doseNum = length(planC{indexS.dose})-nDim+1;
                doseArray3M = double(getDoseArray(doseNum,planC));
                DVFmag3M = DVFmag3M + doseArray3M.^2;
            end
            DVFmag3M = sqrt(DVFmag3M);
            description = 'Deformation magnitude';
            planC = dose2CERR(DVFmag3M,[],description,'',description,...
                'CT',[],'no',assocScanUID, planC);

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
