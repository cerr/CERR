% this is a wrapper function to create a .nrrd file from CERR and call
% pyradiomics.
% Requires specifying path to Pyradiomics
%
% RKP, 03/22/2018

function teststruct = PyradWrapper(scanM, maskM, preprocessingFilter, dirString)

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
    %write NRRDs (flip along 3rd axis??)
    scanFilename = strcat(tempdir,'scan.nrrd');
    scanRes = nrrdWriter(scanFilename, flip(scanM,3), [10,10,10], [0,0,0], 'raw');
   
    maskFilename = strcat(tempdir, 'mask.nrrd');
    maskRes = nrrdWriter(maskFilename, flip(maskM, 3), [10,10,10], [0,0,0], 'raw');
  
    testFilter = preprocessingFilter;
    if ~exist('dirString','var')
        dirString = '';
    end
       
    %this python module will use the path of the newly generated nrrd files 

    
    try         
     pyradiomicsDict = py.pyFeatureExtraction.extract(scanFilename, maskFilename, paramFilePath, testFilter, tempdir, dirString);              
     teststruct = struct(pyradiomicsDict);          
    catch
        disp('error calculating features in pyradiomics')
        teststruct = [];
    end
    




