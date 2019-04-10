% this is a wrapper function to create a .nrrd file from CERR and call
% pyradiomics.
% Requires specifying path to Pyradiomics
%
% RKP, 03/22/2018

function teststruct = PyradWrapper(scanM, maskM, pixelSize, preprocessingFilter, waveletDirString)

    CERRPath = getCERRPath;
    CERRPathSlashes = strfind(getCERRPath,filesep);
    topLevelCERRDir = CERRPath(1:CERRPathSlashes(end-1));

    pyradiomicsWrapperPath = fullfile(topLevelCERRDir,'Unit_Testing','tests_for_cerr', 'pyFeatureExtraction.py');
    paramFilePath = fullfile(topLevelCERRDir,'Unit_Testing','tests_for_cerr', 'pyradParams.yaml');
   
    pyModule = 'pyFeatureExtraction';
    
    P = py.sys.path;     
    currentPath = pwd;
    cd(fullfile(topLevelCERRDir,'Unit_Testing','tests_for_cerr'));
    %import python module if not in system path
    try
        
        if count(P,pyradiomicsWrapperPath) == 0
            insert(P,int32(0),pyradiomicsWrapperPath);
        end
        py.importlib.import_module(pyModule);
        
    catch
        disp('Python module could not be imported, check the pyradiomics path');
    end
    
    cd(currentPath);
    maskM = uint16(maskM);
    
    maskM = permute(maskM, [2 1 3]);
    maskM = flipdim(maskM,3);
    scanM = permute(scanM, [2 1 3]);
    scanM = flipdim(scanM,3);
    
    %write NRRDs (flip along 3rd axis??)
    scanFilename = strcat(tempdir,'scan.nrrd');
    scanRes = nrrdWriter(scanFilename, scanM, pixelSize, [0,0,0], 'raw');
   
    maskFilename = strcat(tempdir, 'mask.nrrd');
    maskRes = nrrdWriter(maskFilename, maskM, pixelSize, [0,0,0], 'raw');
  
    testFilter = preprocessingFilter;
    if ~exist('waveletDirString','var')
        waveletDirString = '';
    end
       
    %this python module will use the path of the newly generated nrrd files 

    
    try         
     pyradiomicsDict = py.pyFeatureExtraction.extract(scanFilename, maskFilename, paramFilePath, testFilter, tempdir, waveletDirString);              
     teststruct = struct(pyradiomicsDict);          
    catch
        disp('error calculating features in pyradiomics')
        teststruct = [];
    end
    




