function [uniqName,scanUID] = genScanUniqName(planC, scanNum)
% previously from register_scans.m
if nargin < 2
    scanNum = 1;
end

randPart = num2str(floor(rand*1000));

if iscell(planC)
    indexS = planC{end};
    scanUID = planC{indexS.scan}(scanNum).scanUID;
    uniqName = [scanUID randPart];
else
    [~,f,ext] = fileparts(planC);
    if strcmp(ext,'.gz')
        [~,f,~] = fileparts(f);
    end
    orgRoot = '1.3.6.1.4.1.9590.100.1.2';
    scanUID = char(javaMethod('createUID','org.dcm4che3.util.UIDUtils',...
        orgRoot));
    %scanUID = dicomuid;
    uniqName = [f '_' scanUID];
end