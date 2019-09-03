function errC = prepareSegDataset(paramFilename)
% prepareSegDataset.m
%
% Script to preprocess and convert data to HDF5 format, split into training,
% validation, and test datasets.
%
% AI 3/15/19
%---------------------------------------------------------------------------
% INPUT:
% paramFilename : Path to JSON file with parameters.
%
% --- JSON fields ---:
% inputFileType    : May be 'DICOM' or 'CERR'
% inputDir         : Path to input data
% outDir           : Path for writing intermediate files(CERR, HDF5)
% structList       : Names of structures to be segmented
% dataSplit        : Train/Val/Test split passed as vector: [%train %val]  (%test = 100-%train-%val).
% imageSizeForModel: Dimensions of output image required for model
% resize           : Resize image as required by model
%                    Supported methods: 'pad', 'bilinear', 'sinc', 'none'.
% crop             : Dictionary of options for cropping with fields
%                    'methods', 'params', 'operator'
%                    Supported methods include 'crop_fixed_amt','crop_to_bounding_box',
%                    'crop_to_str', 'crop_around_center', 'none'.                             :
% Example: See sample_train_params.json
%---------------------------------------------------------------------------
% AI 9/3/19 Added inputFileType, resampling

%% Get user inputs from JSON
userInS = jsondecode(fileread(paramFilename));
inputFileType = userInS.inputFileType;
inputDir = userInS.inputDir;
outDir = userInS.outDir;
strListC = userInS.structList;
dataSplitV = userInS.dataSplit;

userOptS = struct();
userOptS.crop = userInS.crop;
userOptS.outSize = userInS.imageSizeForModel;
userOptS.resizeMethod = userInS.resize.method;
userOptS.resample = userInS.resample;

%% Create directories to write CERR, HDF5 files
fprintf('\nCreating directories for HDF5 files...\n');
mkdir(outDir)

HDF5path = fullfile(outDir,'dataHDF5');
mkdir(HDF5path)

mkdir([HDF5path,filesep,'Train']);
mkdir([HDF5path,filesep,'Train',filesep,'Masks']);

mkdir([HDF5path,filesep,'Val']);
mkdir([HDF5path,filesep,'Val',filesep,'Masks']);

mkdir([HDF5path,filesep,'Test']);
mkdir([HDF5path,filesep,'Test',filesep,'Masks']);

fprintf('\nComplete\n');

%% Import data to CERR
if strcmpi(inputFileType,'DICOM')
    
    CERRpath = fullfile(outDir,'dataCERR');
    mkdir(CERRpath)
    
    zipFlag = 'No';
    mergeScansFlag = 'No';
    batchConvert(inputDir,CERRpath,zipFlag,mergeScansFlag);
    
else
    %input CERR format
    CERRpath = inputDir;
    
end

%% Convert to HDF5 with preprocessing and split into train, val, test datasets
errC = CERRtoHDF5(CERRpath, HDF5path, dataSplitV, strListC, userOptS);


end