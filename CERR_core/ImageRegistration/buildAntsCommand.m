function antsCommand = buildAntsCommand(algorithm,userCmdFile,baseScanFileName,movScanFileName,outPrefix,baseMaskFileName,movMaskFileName,deformBaseMaskFileName,deformMovMaskFileName)

if isunix
    antsCommand = 'sh ';
else
    antsCommand = '';
end

[~,nproc_str] = system('nproc');
nproc = nproc_str(1:end-1);

switch algorithm
    case 'QUICKSYN ANTS'
    antsParams = [' -d 3 -f ' baseScanFileName ' -m ' movScanFileName ' -o ' outPrefix '  -n ' nproc ' '];
        
    %get additional flags for processing
    if exist('userCmdFile','var') && ~isempty(userCmdFile)
        if ~iscell(userCmdFile)
            userCmdFile = cell(userCmdFile);
        end
        for i = 1:numel(userCmdFile)
            antsParams = strrep(strrep([antsParams ' ' fileread(userCmdFile)],'baseMask3M',baseMaskFileName),'movMask3M',movMaskFileName);
        end
        antsCommand = [antsCommand ' antsRegistrationSyNQuick.sh ' antsParams];
    end        
    case 'LDDMM ANTS'
        antsCmdString = fileread(userCmdFile);
        antsCommand = strrep(strrep(strrep(strrep(strrep(strrep(strrep(strrep(antsCmdString(1:end-1),'baseScan',baseScanFileName), ...
            'movScan',movScanFileName), ...
            'baseMask',baseMaskFileName), ...
            'movMask',movMaskFileName), ...
            'outPrefix',outPrefix),'nproc',nproc), ...
            'deformBaseMask',deformBaseMaskFileName), ...
            'deformMovMask',deformMovMaskFileName);
end