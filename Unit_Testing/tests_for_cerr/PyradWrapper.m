% this is a wrapper function to create a .nrrd file from CERR and call
% pyradiomics.
% Requires specifying path to Pyradiomics
%
% RKP, 03/22/2018

function teststruct = PyradWrapper(scanM, maskM, preprocessingFilter)

    %pyradiomicsWrapperPath = fullfile(getCERRPath,'Unit_Testing','tests_for_cerr','pyFeatureExtraction.py');
    pyradiomicsWrapperPath = strcat(fileparts(which('pyFeatureExtraction.py')),'\pyFeatureExtraction.py');
    paramFilePath = strcat(fileparts(which('pyradParams.yaml')),'\pyradParams.yaml') ; %fullfile, getcerrpath
    %paramFilePath = fullfile(getCERRPath,'Unit_Testing','tests_for_cerr','pyradParams.yaml');
    pyModule = 'pyFeatureExtraction';
    P = py.sys.path;
    %
    currentPath = pwd;
    cd(fileparts(which('pyFeatureExtraction.py')));
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
    
    %this python module will use the path of the newly generated nrrd files 
    %pass path of mask and scan here
    
    try              
     pyradiomicsDict = py.pyFeatureExtraction.extract(scanFilename, maskFilename, paramFilePath, testFilter);              
     teststruct = struct(pyradiomicsDict);     
     if strcmp(preprocessingFilter,'wavelet')
%          teststructC = struct2cell(teststruct);   
%          fields = fieldnames(teststruct);
%          for i = 1:length(fields)
%             npa = teststructC{i};
%             data = double(py.array.array('d',py.numpy.nditer(npa)));
%             data = reshape(data,[20,20,5]);
%          end
     end
    catch
        disp('error calculating features in pyradiomics')
        teststruct = [];
    end
    




