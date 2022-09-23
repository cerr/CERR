function cmdFileC = genPlastimatchCmdFile(baseScanFileName, movScanFileName, ...
    baseMaskFileName, movMaskFileName, warpedMhaFile, inBspFile, ...
    xformOutFileName, algorithm, userCmdFile, threshold_bone,landmarkListM)
% function cmdFileC = genPlastimatchCmdFile(baseScanFileName, movScanFileName, ...
%     baseMaskFileName, movMaskFileName, warpedMhaFile, inBspFile, ...
%     xformOutFileName, algorithm, userCmdFile, threshold_bone,landmarkListM)
%
% Generates parameter cmd file for running plastimatch register based on
% user-
% specified algorithm

[workingDir,baseFile,~] = fileparts(baseScanFileName);
[~,movFile,~] = fileparts(movScanFileName);

cmdFileC{1,1} = '[GLOBAL]';
cmdFileC{end+1,1} = ['fixed=',escapeSlashes(baseScanFileName)];
cmdFileC{end+1,1} = ['moving=',escapeSlashes(movScanFileName)];

if ~isempty(baseMaskFileName)
    cmdFileC{end+1,1} = ['fixed_roi=',escapeSlashes(baseMaskFileName)];
end

if ~isempty(movMaskFileName)
    cmdFileC{end+1,1} = ['moving_roi=',escapeSlashes(movMaskFileName)];
end

if exist('inBspFile','var') && exist(inBspFile,'file')
    cmdFileC{end+1,1} = ['xform_in=',escapeSlashes(inBspFile)];
end

cmdFileC{end+1,1} = ['img_out=' escapeSlashes(warpedMhaFile)];

if ~exist('threshold_bone','var')
    threshold_bone = [];
end

if exist('landmarkListM','var') && ~isempty(landmarkListM)
    baseLandmarkM = landmarkListM(:,:,1);
    movLandmarkM = landmarkListM(:,:,2);
    
    baseLandmarkFile = fullfile(workingDir,[baseFile '.csv']);
    movLandmarkFile = fullfile(workingDir,[movFile '.csv']);
    
    csvwrite(baseLandmarkFile,baseLandmarkM);
    csvwrite(movLandmarkFile,movLandmarkM);
    
    cmdFileC{end+1,1} = ['fixed_landmarks=',escapeSlashes(baseLandmarkFile)];
    cmdFileC{end+1,1} = ['moving_landmarks=',escapeSlashes(movLandmarkFile)];
    
end

if exist('userCmdFile','var') && exist(userCmdFile,'file')
    usrFileC = file2cell(userCmdFile);
    %matchIdxC = cellfun(@(x)contains(x,'xform_out='),usrFileC,'un',0);    
    %matchIdxV = [matchIdxC{:}];
    matchIdxV = ~cellfun(@isempty,strfind(usrFileC,'xform_out='));
    if any(matchIdxV)
        inFileName = usrFileC{matchIdxV};
        fnameC = strsplit(inFileName,'xform_out=');
        [~,~,ext] = fileparts(fnameC{2});
        usrFileC{matchIdxV} = ['xform_out=',escapeSlashes([xformOutFileName,ext])];
    end
    cmdFileC(end+1:end+size(usrFileC,2),1) = usrFileC(:);
end

%add algorithm-specific options
switch upper(algorithm)
    case 'ALIGN CENTER'
        %output vector field vf
        cmdFileC{end+1,1} = ['vf_out=',escapeSlashes([xformOutFileName '.mha'])];
        cmdFileC{end+1,1} = '';
       
        cmdFileC{end+1,1} ='[STAGE]';
        cmdFileC{end+1,1} ='xform=align_center';
        cmdFileC{end+1,1} = '';
        
        
    case {'RIGID PLASTIMATCH','RIGID'}
        
        cmdFileC{end+1,1} = ['vf_out=',escapeSlashes([xformOutFileName '.mha'])];
        cmdFileC{end+1,1} = '';
        
        cmdFileC{end+1,1} = ' [STAGE]';
        cmdFileC{end+1,1} = 'xform=rigid';
        cmdFileC{end+1,1} = 'optim=versor';
        cmdFileC{end+1,1} ='max_its=30';
        cmdFileC{end+1,1} ='res=4 4 2';
        cmdFileC{end+1,1} = '';
        
        
    case {'BSPLINE PLASTIMATCH','BSPLINE'}
        
        %cmdFileC{end+1,1} = ['xform_in=',escapeSlashes(bspFileName_rigid)];
        cmdFileC{end+1,1} = ['xform_out=',escapeSlashes([xformOutFileName '.txt'])];
        cmdFileC{end+1,1} = '';
        
        % Add background_max to all the stages if threshold_bone is not empty
        if ~isempty(threshold_bone)
            backgrC = cell(1);
            backgrC{1} = ['background_max=',num2str(threshold_bone)];
            indStageV = find(strcmp(cmdFileC,'[STAGE]'));
            for i = 1:length(indStageV)
                ind = indStageV(i)+i-1;
                cmdFileC(ind+2:end+1) = cmdFileC(ind+1:end);
                cmdFileC(ind+1) = backgrC;
            end
        end
        
        
    case 'DEMONS PLASTIMATCH'
        
        %cmdFileC{end+1,1} = ['xform_in=',escapeSlashes(bspFileName_rigid)];
        cmdFileC{end+1,1} = ['xform_out=',escapeSlashes(xformOutFileName)];
        cmdFileC{end+1,1} = '';
         % Add background_max to all the stages if threshold_bone is not empty
        if ~isempty(threshold_bone)
            backgrC = cell(1);
            backgrC{1} = ['background_max=',num2str(threshold_bone)];
            indStageV = find(strcmp(cmdFileC,'[STAGE]'));
            for i = 1:length(indStageV)
                ind = indStageV(i)+i-1;
                cmdFileC(ind+2:end+1) = cmdFileC(ind+1:end);
                cmdFileC(ind+1) = backgrC;
            end
        end
            
end
