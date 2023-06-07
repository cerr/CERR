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
            if ishandle(hWait)
                waitbar(0.9,hWait,'Importing segmentation results to CERR');
            end
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
                        [procData3M,planC] = joinH5planC(outScanNum,modelOut3M,...
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
