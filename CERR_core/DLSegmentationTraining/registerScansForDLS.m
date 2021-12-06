function [planC,scanNumV] = registerScansForDLS(planC,scanNumV,...
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
        
        [planC, deformS, scanNumV] = feval(algorithm,planC,baseScanNum,...
            movScanNum,paramS);
        
    case {'plastimatch','elastix','ants'}
        
        %Get optional inputs
        argC = {};
        optArgC = {'baseMask','movMask','boneThreshold',...
            'inputCmdFile','inBspFile','outBspFile'};
        for nArg = 1:length(optArgC)
            if isfield(paramS,optArgC{nArg})
                argC{nArg} = paramS.(optArgC{nArg});
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
        scanNumV = [baseScanNum,regScanNum];
        
        if isfield(paramS,'copyStr')
            
            %Warp selected structures
            copyStrC = paramS.copyStr;
            movStrV = [];
            strC = {planC{indexS.structures}.structureName};
            for nStr = 1:length(copyStrC)
                matchIdx = getMatchingIndex(copyStrC{nStr},strC,'EXACT');
                movStrV = [movStrV,matchIdx];
            end
            planC = warp_structures(deformS,regScanNum,movStrV,planC,...
                planC,tmpCmdDir,0);
           
        end
        
        
    otherwise
        
        error(['Invalid registration tool %s. Supported options: '...
            '''plastimatch'',''elastix'',''ants'', or ''custom'''],...
            registrationTool);
        
        
end