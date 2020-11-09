function antsCommand = buildAntsCommand(algorithm,userCmdFile,baseScanFileName,movScanFileName,outPrefix,baseMaskFileName,movMaskFileName,deformBaseMaskFileName,deformMovMaskFileName)

antsCommand = '';

[~,nproc_str] = system('nproc');
nproc = nproc_str(1:end-1);

switch upper(algorithm)
    case {'QUICKSYN ANTS','QUICKSYN'}
        antsParams = [' -d 3 -f ' baseScanFileName ' -m ' movScanFileName ' -o ' outPrefix '  -n ' nproc ' '];
        
        %get additional flags for processing
        if exist('userCmdFile','var') && ~isempty(userCmdFile)
            if ~iscell(userCmdFile)
                userCmdFile = {userCmdFile};
            end
            for i = 1:numel(userCmdFile)
                antsParams = strrep(strrep([antsParams ' ' fileread(userCmdFile{i})],'baseMask3M',baseMaskFileName),'movMask3M',movMaskFileName);
            end
        end
        antsCommand = [antsCommand ' antsRegistrationSyNQuick.sh ' antsParams];
    case {'LDDMM ANTS','LDDMM'}
        antsCmdString = fileread(userCmdFile);
        antsCommand = strrep(strrep(strrep(strrep(strrep(strrep(strrep(antsCmdString(1:end-1),'baseScan',baseScanFileName), ...
            'movScan',movScanFileName), ...
            'baseMask',baseMaskFileName), ...
            'movMask',movMaskFileName), ...
            'outPrefix',outPrefix), ...
            'deformBaseMask',deformBaseMaskFileName), ...
            'deformMovMask',deformMovMaskFileName);
end