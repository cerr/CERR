function createPlmCmdFile(usrInputFileName, cmdFileName, bspOutputFileName, ...
    baseScanFileName, movScanFileName, baseMaskFileName, ...
    movMaskFileName, baseMaskFlg, movMaskFlg, threshold_bone)
% function createPlmCmdFile(usrInputFileName, cmdFileName, baseScanFileName,...
%     movScanFileName, movScanFileName, movMaskFileName, threshold_bone)
%
% This function generates the input command file for plastimatch
% registration.
%
% INPUTS:
%   usrInputFileName: full file name containing user commands
%   cmdFileName: full filename for the plastimatch command file
%   baseScanFileName: mha file name for the base scan
%   movScanFileName: mha file name for the base scan
%
% APA, 2/28/2017

ursFileC = file2cell(usrInputFileName);
cmdFileC{1,1} = '[GLOBAL]';
cmdFileC{end+1,1} = ['fixed=',escapeSlashes(baseScanFileName)];
cmdFileC{end+1,1} = ['moving=',escapeSlashes(movScanFileName)];
if baseMaskFlg==1 || ~isempty(threshold_bone)
    cmdFileC{end+1,1} = ['fixed_roi=',escapeSlashes(baseMaskFileName)];
end
if movMaskFlg==1 || ~isempty(threshold_bone)
    cmdFileC{end+1,1} = ['moving_roi=',escapeSlashes(movMaskFileName)];
end
%cmdFileC{end+1,1} = ['xform_in=',escapeSlashes(bspFileName_rigid)];
cmdFileC{end+1,1} = ['xform_out=',escapeSlashes(bspOutputFileName)];
cmdFileC{end+1,1} = '';
if ~isempty(threshold_bone)
    cmdFileC{end+1,1} = ['background_max=',num2str(threshold_bone)];
    cmdFileC{end+1,1} = '';
end
cmdFileC(end+1:end+size(ursFileC,2),1) = ursFileC(:);
cell2file(cmdFileC,cmdFileName)
