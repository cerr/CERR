function [tmpS] = dicomrt_d2c_buildscanstr(scanInitS)

% Construct the scan structure
tmpS = [];

tmpS.scanArray            = '';
tmpS.scanType             = 'CT';
tmpS.scanInfo             = scanInitS;
tmpS.uniformScanInfo      = '';
tmpS.scanArraySuperior    = '';
tmpS.scanArrayInferior    = '';
