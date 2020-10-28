function deformS = createNewDeformObject(baseScanUID,movScanUID,algorithm, registration_tool, algorithmParamsS)
% function deformS = createNewDeformObject(baseScanUID,movScanUID,algorithm,algorithmParamsS);
%
% APA, 08/14/2012

deformS                     = initializeCERR('deform');
deformS(1).baseScanUID      = baseScanUID;
deformS(1).movScanUID       = movScanUID;
deformS(1).algorithm        = algorithm;
deformS(1).registration_tool = registration_tool;
deformS(1).algorithmParamsS = algorithmParamsS;
deformS(1).deformUID        = createUID('deform');

