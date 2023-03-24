function [planC,deformS] = registerScansForDLS(planC,scanNumV,...
    algorithm,paramS)
% registerScansForDLS.m
% -----------------------------------------------------------------------
% INPUTS
% planC
% scanNumV     : Scan nos of fixed and moving scans.
%baseScanNum = scanNumV(1);
%movScanNum = scanNumV(2:end);
% algorithm    : Name of registration algorithm. See register_scans for
%                supported options. Alternatively, specify custom script
%                registration function to be used.
% paramS       : Dictionary of input paramters.
%                Required- paramS.registration_tool: 'plastimatch','elastix',
%                          'ants', or 'custom'.
%                Optional- See register_scans.m for supported inputs.
% -----------------------------------------------------------------------
%AI 11/19/21

indexS = planC{end};

baseScanNum = scanNumV(1);
movScanNum = scanNumV(2);
registrationTool = paramS.tool;
switch(lower(registrationTool))
    
    case 'custom'
        
        planC = feval(algorithm,planC,baseScanNum,...
            movScanNum,paramS);
        
    case {'plastimatch','elastix','ants'}
        
        %Get optional inputs
        argC = {};
        optArgC = {'baseMask','movMask','boneThreshold',...
            'inputCmdFile','inBspFile','outBspFile'};
        for nArg = 1:length(optArgC)
            if isfield(paramS,optArgC{nArg})
                if strcmpi(optArgC{nArg},'inputCmdFile')
                    regCmdPath = fullfile(getCERRPath,'ImageRegistration',...
                        'plastimatch_command');
                    argC{nArg} = fullfile(regCmdPath,paramS.(optArgC{nArg}));
                else
                    argC{nArg} = paramS.(optArgC{nArg});
                end
            end
        end
        
        %Set temp dir
        tmpCmdDir = fullfile(getCERRPath,'ImageRegistration','tmpFiles');
        
        %Register scans
        [planC, ~, deformS] = register_scans(planC,baseScanNum, ...
            planC, movScanNum, algorithm, registrationTool, tmpCmdDir,...
            argC{:});
        
        regScanNum = length(planC{indexS.scan});
        planC{indexS.scan}(regScanNum).scanType = ['Reg_scan',...
            num2str(movScanNum)];
        %scanNumV = [baseScanNum,regScanNum];
        
        %Warp selected structures
        if isfield(paramS,'copyStr')
            copyStrC = paramS.copyStr; 
            if ~iscell(copyStrC)
                copyStrC = {copyStrC};
            end
            renameC = paramS.renameStr;
            if ~iscell(renameC)
                renameC = {renameC};
            end
            cpyBaseStrV = [];
            cpyMovStrV = [];
            renameBaseStrC = {};
            renameMovStrC = {};
            strC = {planC{indexS.structures}.structureName};
            for nStr = 1:length(copyStrC)
                matchIdxV = getMatchingIndex(copyStrC{nStr},strC,'EXACT');
                assocScanV = getStructureAssociatedScan(matchIdxV,planC);
                baseMatchIdx = matchIdxV(assocScanV==baseScanNum);
                movMatchIdx = matchIdxV(assocScanV==movScanNum);
                cpyBaseStrV = [cpyBaseStrV,baseMatchIdx];
                cpyMovStrV = [cpyMovStrV,movMatchIdx];
                if ~isempty(baseMatchIdx)
                    renameBaseStrC{end+1} = renameC{nStr};
                else
                    if ~isempty(movMatchIdx)
                        renameMovStrC{end+1} = renameC{nStr};
                    end
                end
            end
            numStrs = length(planC{indexS.structures});
            if ~isempty(cpyBaseStrV)
                planC = warp_structures(deformS,regScanNum,cpyBaseStrV,...
                    planC,planC,tmpCmdDir,0);
                numStrs = length(planC{indexS.structures});
                %Rename warped structures
                for nStr = 1:length(movStrV)
                    strIdx = numStrs-nStr+1;
                    planC{indexS.structures}(strIdx).structureName = ...
                        renameBaseStrC{cpyBaseStrV(nStr)};
                end
            end
            if ~isempty(cpyMovStrV)
                for nStr = 1:length(cpyMovStrV)
                    planC = copyStrToScan(cpyMovStrV(nStr),regScanNum,planC);
                    %Rename copied structures
                    numStrs = numStrs+1;
                    planC{indexS.structures}(numStrs).structureName =...
                        renameMovStrC{cpyMovStrV(nStr)};
                end
            end
        end
        
        
    otherwise
        
        error(['Invalid registration tool %s. Supported options: '...
            '''plastimatch'',''elastix'',''ants'', or ''custom'''],...
            registrationTool);
        
end

end