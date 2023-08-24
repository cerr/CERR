function [planC,allLabelNamesC,dcmExportOptS] = ...
    processAndImportAIOutput(planC,userOptS,origScanNumV,scanNumV,...
    outputScanNum,algorithm,hashID,sessionPath,cmdFlag,inputIdxS)
%[planC,,origScanNumV,allLabelNamesC,dcmExportOptS] = ...
%processAndImportAIOutput(planC,userOptS,origScanNumV,scanNumV,...
% outputScanNum,algorithm,hashID,sessionPath,cmdFlag,inputIdxS)
%--------------------------------------------------------------------------
% AI 08/29/22

outputS = userOptS.output;
allLabelNamesC = {};
dcmExportOptS = struct([]);


%Loop over model outputs

outputC = fieldnames(outputS);
for nOut = 1:length(outputC)

    outType = outputC{nOut};

    switch(lower(outType))

        case 'labelmap'
            %Segmentations

            % Import segmentations
            [planC,allLabelNamesC,dcmExportOptS] = ...
                processAndImportSeg(planC,origScanNumV,scanNumV,...
                outputScanNum,sessionPath,userOptS);

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
                    DVF4M =  permute(DVF4M,[1,4,3,2]);
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
            if ~isempty(outputScanNum)
                assocScan = outputScanNum;
            else
                idS = userOptS.outputAssocScan.identifier;
                assocScan = getScanNumFromIdentifiers(idS,planC);
            end

            tempOptS = userOptS;
            outTypesC = fieldnames(userOptS.output);
            matchIdx = strcmpi(outTypesC,'DVF');
            outTypesC = outTypesC(~matchIdx);
            tempOptS.output = rmfield(tempOptS.output,outTypesC);
            niiOutDir = tempOptS.output.DVF.outputDir;
            DVFfilename = strrep(strrep(DVFfile.name,' ','_'),'.h5','');
            dimsC = {'dx','dy','dz'};
            niiFileNameC = cell(1,length(dimsC));
            outputSizeV = size(DVF4M);
            origScanSizV = size(planC{indexS.scan}(assocScan).scanArray);
            dvfOnOrigScan4M = zeros([origScanSizV,3]);

            % Note: Expected ordering of components is: DVF_x, DVF_y,DVF_z
            % i.e., deformation along cols, rows, slices.
            
            % Convert to physical dimensions
            for nDim = 1:size(DVF4M,1)

                % Reverse pre-processing operations
                DVF3M = squeeze(DVF4M(nDim,:,:,:));
                
                [DVF3M,imgExtentsV,physExtentsV,planC] = ...
                    joinH5planC(assocScan,DVF3M,[DVFfilename,'_'...
                    dimsC{nDim}],tempOptS,planC);
                
                if nDim == 2
                    scaleFactor = abs(physExtentsV(2)-physExtentsV(1))./(outputSizeV(2)-1);
                else
                    if nDim == 1
                        scaleFactor = abs(physExtentsV(4)-physExtentsV(3))./(outputSizeV(3)-1);
                    else
                        %nDim == 3
                        % Account for reversed slice direction (CERR convention vs.
                        % DICOM) passed to model.
                        DVF3M = -DVF3M;
                        scaleFactor = abs(physExtentsV(6)-physExtentsV(5))./(outputSizeV(4)-1);
                    end
                end
                
                DVF3M = DVF3M.*scaleFactor*10;
                
                dvfOnOrigScan4M(:,:,:,nDim) = DVF3M;
               
            end
            dvfDcmM = dvfOnOrigScan4M;
            %dvfDcmM = dvfImageToDICOMCoords(dvfOnOrigScan4M,assocScan,planC);  %4D array
            dvfDcmM = permute(dvfDcmM, [1:3 5 4]); %5D array as reqd by exportScanToNii.m
            %Write DVF to NIfTI file
            fprintf('\n Writing DVF to file %s\n',niiFileNameC{nDim});
            exportScanToNii(niiOutDir,dvfDcmM,{DVFfilename},...
                [],{},planC,assocScan);

            %Calc. deformation magnitude
            DVFmag3M = zeros(origScanSizV);
            assocScanUID = planC{indexS.scan}(assocScan).scanUID;
            for nDim = 1:size(dvfOnOrigScan4M,4)
                dvfDim3M = squeeze(dvfDcmM(:,:,:,1,nDim));
                DVFmag3M = DVFmag3M + dvfDim3M.^2;
            end
            DVFmag3M = sqrt(DVFmag3M);
            % Store to planC as pseudo-dose
            description = 'Deformation magnitude';
            planC = dose2CERR(DVFmag3M,[],description,'',description,...
                'CT',[],'no',assocScanUID, planC);

            % Store metadata to deformS
            indexS = planC{end};
            if isfield(userOptS,'register') && isfield(userOptS.register,'baseScan')
                idS = userOptS.register.baseScan.identifier;
                baseScanNum = getScanNumFromIdentifiers(idS,planC,1);
                idS = userOptS.register.movingScan.identifier;
                movScanNum = getScanNumFromIdentifiers(idS,planC,1);
                planC{indexS.deform}(end+1).baseScanUID = ...
                    planC{indexS.scan}(baseScanNum).scanUID;
                planC{indexS.deform}(end+1).movScanUID = ...
                    planC{indexS.scan}(movScanNum).scanUID;
            else

                % Get associated scan num
                if ~isempty(outputScanNum)
                    baseScanNum = outputScanNum;
                else
                    idS = userOptS.outputAssocScan.identifier;
                    baseScanNum = getScanNumFromIdentifiers(idS,planC,1);
                end
                planC{indexS.deform}(end+1).baseScanUID = ...
                    planC{indexS.scan}(baseScanNum).scanUID;
            end

            planC{indexS.deform}(end+1).algorithm = algorithm;
            planC{indexS.deform}(end+1).registrationTool = 'CNN';
            planC{indexS.deform}(end+1).algorithmParamsS.singContainerHash = ...
                hashID;
            planC{indexS.deform}(end+1).DVFfileName = niiFileNameC;

            if ~isempty(cerrFile)
                save_planC(planC,[],'PASSED',cerrFile);
                planC = cerrFile;
            end

        case 'derivedimage'

            %Read output image
            outFmt = outputS.derivedImage.outputFormat;
            outputImgType = outputS.derivedImage.imageType;
            imgPath = fullfile(sessionPath,['output',outFmt],'derivedImage');
            imgFile = dir(imgPath);
            imgFile(1:2) = [];

            switch(lower(outFmt))

                case 'h5'

                    %Get unique dataset names
                    datasetsC = {};
                    for nFile = 1:length(imgFile)  %Note: Assumes 3D output
                        outFile =  fullfile(imgPath,imgFile(nFile).name);
                        I = h5info(outFile);
                        if isempty(datasetsC)
                            datasetsC{1} = I.Datasets.Name;
                        elseif ~ismember(I.Datasets,datasetsC)
                            datasetsC{end+1} = I.Datasets.Name;
                        end

                        %Read output
                        modelOut3M = h5read(outFile,['/',I.Datasets.Name]);
                        scanName = I.Datasets.Name;

                        % Reverse transform img3M to match orig scan grid
                        if isempty(outputScanNum) || isnan(outputScanNum)
                            identifierS = userOptS.outputAssocScan.identifier;
                            idS = rmfield(identifierS,{'warped','filtered'});
                            idC = fieldnames(idS);
                            if ~isempty(idC)
                                origScanNum = getScanNumFromIdentifiers(identifierS,planC);
                                origScanNum = find(origScanNumV==origScanNum);
                                %if ismember(origScanNum,scanNumV)
                                outScanNum = scanNumV(origScanNum);
                                %else
                                %   outScanNum = origScanNum;
                                %end
                            else
                                origScanNum = 1; %Assoc with first scan by default
                                outScanNum = scanNumV(origScanNum);
                            end
                        else
                            origScanNum = find(origScanNumV==outputScanNum);
                            outScanNum = scanNumV(origScanNum);
                        end

                        userOptS.input.scan(outScanNum) = userOptS.input.scan(origScanNum);
                        userOptS.input.scan(outScanNum).origScan = origScanNumV;
                        [procData3M,~,~,planC] = joinH5planC(outScanNum,modelOut3M,...
                            scanName,userOptS,planC);

                        % Add the new "derived" scan to planC
                        planC = addDerivedScan(origScanNumV,procData3M,scanName,planC);

                    end

                otherwise %TBD extend to support other formats
                    error('Invalid model output format %s.',outFmt)
            end

        otherwise
            error('Invalid output type '' %s ''.',outType)


    end
    userOptS.output.(outType) =  outputS;

end



end
