function featS = PyradWrapper(scan3M, mask3M, voxelSizeV, paramFilePath)

% This is a wrapper function to create a .nrrd file from CERR and call
% pyradiomics.
% Requires specifying path to Pyradiomics
%
% RKP, 03/22/2018
% AI, 06/10/2020

%Get path to pyradiomics wrapper
CERRPath = getCERRPath;
CERRPathSlashes = strfind(getCERRPath,filesep);
topLevelCERRDir = CERRPath(1:CERRPathSlashes(end-1));
pyradiomicsWrapperPath = fullfile(topLevelCERRDir,'Unit_Testing','tests_for_cerr', 'pyFeatureExtraction.py');

%Add python module to system path & iImport
pyModule = 'pyFeatureExtraction';

P = py.sys.path;
currentPath = pwd;
cd(fullfile(topLevelCERRDir,'Unit_Testing','tests_for_cerr'));

try
    if count(P,pyradiomicsWrapperPath) == 0
        insert(P,int64(0),pyradiomicsWrapperPath);
    end
    py.importlib.import_module(pyModule);
catch
    disp('Python module could not be imported, check the pyradiomics path');
end

%Write scan & mask to NRRD format
fprintf('\nWriting scan and mask to NRRD format...\n');
cd(currentPath);

originV = [0,0,0];
encoding = 'raw';

mask3M = uint16(mask3M);
mask3M = permute(mask3M, [2 1 3]);
mask3M = flip(mask3M,3);

scan3M = permute(scan3M, [2 1 3]);
scan3M = flip(scan3M,3);

scanFilename = strcat(tempdir,'scan.nrrd');
scanRes = nrrdWriter(scanFilename, scan3M, voxelSizeV, originV, encoding);

maskFilename = strcat(tempdir, 'mask.nrrd');
maskRes = nrrdWriter(maskFilename, mask3M, voxelSizeV, originV, encoding);


%Call feature extractor
try
    
    pyFeatDict = py.pyFeatureExtraction.extract(scanFilename, maskFilename,...
        paramFilePath, tempdir);
    
    %Convert python dictionary to matlab struct
    featS = struct(pyFeatDict);
    
catch e
    error('Feature extraction failed with message %s',e.message)
end
