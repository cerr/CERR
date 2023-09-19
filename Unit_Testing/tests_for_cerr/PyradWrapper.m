function featS = PyradWrapper(scanNum, strNum, paramFilePath,...
                 pyradPath,planC)
% This is a wrapper function to create a NIfTI file from CERR and call
% pyradiomics.
%-----------------------------------------------------------------------
% INPUTS
% scanNum       : Index to scan in planC
% strNum        : Index to structure in planC 
% paramFilePath : Path to PyRadiomics settings file
% pyradPath     : Path to Python packages including Pyradiomics & Scipy
%                 Typically 'C:\Miniconda3\Lib\site-packages\'
% planC
%-----------------------------------------------------------------------
% RKP, 03/22/2018
% AI, 06/10/2020
% AI, 09/14/23    Export files to NIfTI to preserve metadata.

indexS = planC{end};

%Get struct name
strName = planC{indexS.structures}(strNum).structureName;

%Get path to pyradiomics wrapper
CERRPath = getCERRPath;
CERRPathSlashes = strfind(getCERRPath,filesep);
topLevelCERRDir = CERRPath(1:CERRPathSlashes(end-1));
pyradiomicsWrapperPath = fullfile(topLevelCERRDir,'Unit_Testing',...
    'tests_for_cerr', 'pyFeatureExtraction.py');

%% Add python module to system path & import
pyModule = 'pyFeatureExtraction';

P = py.sys.path;
currentPath = pwd;
cd(fullfile(topLevelCERRDir,'Unit_Testing','tests_for_cerr'));

try
    if count(P,pyradiomicsWrapperPath) == 0
        %Insert paths to scipy and pyradiomics.
        insert(P,int64(0), fullfile(pyradPath,'radiomics'));%path to pyradiomic pkg
        P = py.sys.path;
        insert(P,int64(0),fullfile(pyradPath,'scipy'));%path to scipy pkg
        P = py.sys.path;
        insert(P,int64(0),pyradiomicsWrapperPath);
    end
    py.importlib.reload(py.importlib.import_module(pyModule));
    %py.importlib.import_module(pyModule);
catch e 
    error('Python module %s could not be imported. %s',pyModule,e.message);
end

%% Write scan & mask to NIfTI files
fprintf('\nWriting scan and mask to NIfTI format...\n');
cd(currentPath);
%Create unique filenames
dateTimeV = clock;
randStr = [num2str(dateTimeV(4)), num2str(dateTimeV(5)),...
    num2str(dateTimeV(6)),sprintf('%6.3f',rand*1000)];
niiScanName = ['scan_',randStr];
scanFilename = fullfile(tempdir,[niiScanName,'.nii.gz']);

niiMaskPostfix = ['mask_',randStr];
maskFilename = fullfile(tempdir,[strName,'_',niiMaskPostfix,'.nii.gz']);

exportScanToNii(tempdir,scanNum,{niiScanName},...
strNum,{niiMaskPostfix},planC,scanNum);

%% Call feature extractor
try
    status = 0;
    pyOutC = py.pyFeatureExtraction.extract(scanFilename, maskFilename,...
        paramFilePath, tempdir);
    pyFeatDict = pyOutC{1};
    status = logical(pyOutC{2});

    while(~status) pause(0.1); end

    %Convert python dictionary to matlab struct
    featS = struct(pyFeatDict{1});
    
catch e
    error('Feature extraction failed with message %s',e.message)
end