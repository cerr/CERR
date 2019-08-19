function copyDependenciesForCERRCompile(compiled_path)

% function copyDependenciesForCERRCompile(compiled_path)
%
% This function creates bin, doc, pics directories and copies files to
% them.
%
% APA, 03/26/2012
% RKP, 8/13/2019 - Updated to use dcm4che-5.17.0


CERRPath = getCERRPath;
CERRPathSlashes = strfind(getCERRPath,filesep);
topLevelCERRDir = CERRPath(1:CERRPathSlashes(end-1));

% Create bin, doc and pics directories
mkdir(fullfile(compiled_path,'bin'));
mkdir(fullfile(compiled_path,'doc'));
mkdir(fullfile(compiled_path,'pics'));
copyfile(fullfile(topLevelCERRDir,'CERR_core','CERROptions.m'),compiled_path);
copyfile(fullfile(topLevelCERRDir,'CERR_core','CERROptions.json'),compiled_path);

% Fill-in the bin directory
destin = fullfile(compiled_path,'bin');
mkdir(fullfile(destin,'Compression'));
mkdir(fullfile(destin,'Importing'));
mkdir(fullfile(destin,'IMRTP'));
mkdir(fullfile(destin,'mat_files'));
mkdir(fullfile(destin,'MeshInterp'));
copyfile(fullfile(topLevelCERRDir,'ML_Dicom','dcm4che-5.17.0'),fullfile(destin,'dcm4che-5.17.0'));
copyfile(fullfile(topLevelCERRDir,'CERR_core','Mex'),fullfile(destin,'Mex'));

destin_compression = fullfile(compiled_path,'bin','Compression');
copyfile(fullfile(topLevelCERRDir,'CERR_core','Compression','7z.dll'),destin_compression);
copyfile(fullfile(topLevelCERRDir,'CERR_core','Compression','7z.exe'),destin_compression);
copyfile(fullfile(topLevelCERRDir,'CERR_core','Compression','7z.sfx'),destin_compression);
copyfile(fullfile(topLevelCERRDir,'CERR_core','Compression','7z_License.txt'),destin_compression);
copyfile(fullfile(topLevelCERRDir,'CERR_core','Compression','tar.exe'),destin_compression);

destin_importing = fullfile(compiled_path,'bin','Importing');
copyfile(fullfile(topLevelCERRDir,'CERR_core','Importing','readASCIIDose.exe'),destin_importing);
copyfile(fullfile(topLevelCERRDir,'CERR_core','Importing','ES - IPT4.1CompatibleDictionary.mat'),destin_importing);

destin_IMRTP = fullfile(compiled_path,'bin','IMRTP');
copyfile(fullfile(topLevelCERRDir,'IMRTP','QIBData'),fullfile(destin_IMRTP,'QIBData'),'f');
copyfile(fullfile(topLevelCERRDir,'IMRTP','vmc++'),fullfile(destin_IMRTP,'vmc++'),'f');

copyfile(fullfile(topLevelCERRDir,'CERR_core','Icons','copperColorMap.mat'),fullfile(compiled_path,'bin','mat_files'));

destin_MeshInterp = fullfile(compiled_path,'bin','MeshInterp');
copyfile(fullfile(topLevelCERRDir,'CERR_core','MeshBasedInterp','libMeshContour.dll'),destin_MeshInterp);
copyfile(fullfile(topLevelCERRDir,'CERR_core','MeshBasedInterp','MeshContour.h'),destin_MeshInterp);
copyfile(fullfile(topLevelCERRDir,'CERR_core','MeshBasedInterp','pretriang_4.txt'),destin_MeshInterp);
copyfile(fullfile(topLevelCERRDir,'CERR_core','MeshBasedInterp','pretriang_5.txt'),destin_MeshInterp);
copyfile(fullfile(topLevelCERRDir,'CERR_core','MeshBasedInterp','pretriang_6.txt'),destin_MeshInterp);

% Fill-in the pics directory
destin = fullfile(compiled_path,'pics');
copyfile(fullfile(topLevelCERRDir,'CERR_core','Icons'),fullfile(destin,'Icons'));
copyfile(fullfile(topLevelCERRDir,'CERR_core','CERR.png'),destin);
copyfile(fullfile(topLevelCERRDir,'CERR_core','Contouring','structureFusionBackground.png'),destin);


% Fill-in the docs directory
destin = fullfile(compiled_path,'doc');
mkdir(fullfile(destin,'html'));
copyfile(fullfile(topLevelCERRDir,'CERR_core','CommandLine','CERRCommandLinehelp.html'),fullfile(destin,'html'));

%  Fill-in the ModelConfiguration directory
destin_modelConfig = fullfile(compiled_path,'ModelImplementationLibrary','SegmentationModels', 'ModelConfigurationFiles');
mkdir destin_modelConfig;
copyfile(fullfile(topLevelCERRDir,'CERR_core','ModelImplementationLibrary','SegmentationModels', 'ModelConfigurationFiles'),destin_modelConfig);

return;