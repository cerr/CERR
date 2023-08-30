function batchExportAIRegToDICOM(cerrPath, origScanNumV, outputScanNum,...
    cmdFlag, containerPath, dvfFile, outputDicomPath,dcmExportOptS)
% function batchExportAIRegToDICOM(cerrPath, origScanNumV, outputScanNum,...
%               cmdFlag, dvfFile, outputDicomPath,dcmExportOptS)
%
% Uses reg2dcm  to export DVFs to REG DICOM format.
% reg2dcm:  https://github.mskcc.org/aptea/reg2dcm.git
%
% This requires either (1) conda env with reg2dcm module or (2)
% singularity container with the 'reg2dcm' app:
%    python /software/reg2dcm/reg2dcm.py -b $1 -m $2 -d $3 -o $4
%
%---------------------------------------------------------------------------------------------------
% INPUTS:
% cerrPath                 - Directory containing CERR files with initial
%                                 sementation
% origScanNumV      -  Indices f scans input to model
% outputScanNum    -  Scan assoc. with model output
% cmdFlag                 - 'condaEnv' or 'singContainer'
% containerPath        - Path to conda archive/sing container
% dvfFile                    - AI-generated DVF
% outputDicomPath  - directory to export DICOM REG
%---------------------------------------------------------------------------------------------------
% AI, 8/25/2023

dirS = dir(cerrPath);
dirS(1:2) = [];
init_ML_DICOM

for nFile = 1:length(dirS)
    
    
    %Load planC
    origFileName = fullfile(cerrPath,dirS(nFile).name);
    [~,fname,~] = fileparts(origFileName);
    planC = loadPlanC(origFileName);
    indexS = planC{end};
    
    %Get paths to DICOMs for base and moving scans
    baseScan = origScanNumV(origScanNumV==outputScanNum);
    movScan = origScanNumV(origScanNumV~=outputScanNum);
    baseSlcPath = planC{indexS.scan}(baseScan).scanInfo(1).scanFileName;
    [baseImgPath,~,~] = fileparts(baseSlcPath);
    moveSlcPath = planC{indexS.scan}(movScan).scanInfo(1).scanFileName;
    [moveImgPath,~,~] = fileparts(moveSlcPath);
    
    %Path to output REG file
    outRegFile = fullfile(outputDicomPath,[fname,'_DVF.dcm']);
    
    switch(lower(cmdFlag))
  
        case 'condaenv'
            activate_cmd = sprintf(['/bin/bash -c "source %s/bin/activate'],containerPath);
            reg2dcm_cmd = sprintf(['python %s/reg2dcm/reg2dcm.py -b %s -m %s -d %s -o %s"'],...
                containerPath,baseImgPath,moveImgPath,dvfFile,outRegFile);
            
            system([activate_cmd, ' && ', reg2dcm_cmd])
            
        case 'singcontainer'
            
            %Get bind paths for the container
            [ptDir,~,~] = fileparts(baseScan);
            bindingDir = ':/scratch';
            bindPath = strcat(ptDir,bindingDir);
            %Run container app
            reg2dcm_cmd = sprintf('singularity run --app reg2dcm --nv --bind  %s %s',...
                bindPath, containerPath);
            system(reg2dcm_cmd)
          
    end
    
end


end