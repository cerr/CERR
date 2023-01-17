function deformS = createNewDeformObject(baseScanUID,movScanUID,algorithm,...
    registration_tool, algorithmParamsS, DVFfileName)
% function deformS = createNewDeformObject(baseScanUID,movScanUID,algorithm,...
% registration_tool, algorithmParamsS, DVFfileName);
%
% APA, 08/14/2012
% AI, 09/23/22

if ~exist('DVFfileName','var')
    DVFfileName = '';
end

deformS                     = initializeCERR('deform');
deformS(1).baseScanUID      = baseScanUID;
deformS(1).movScanUID       = movScanUID;
deformS(1).algorithm        = algorithm;
deformS(1).registrationTool = registration_tool;
deformS(1).algorithmParamsS = algorithmParamsS;
deformS(1).DVFfileName      = DVFfileName;
deformS(1).deformUID        = createUID('deform');

