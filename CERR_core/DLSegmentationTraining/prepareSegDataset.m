function prepareSegDataset(paramFilename)
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
%
% dcmDir           : Path to DICOM data
% tempDir          : Path for writing intermediate files(CERR, HDF5)
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

%% Get user inputs from JSON
userInS = jsondecode(fileread(paramFilename));
dcmDir = userInS.dcmDir;
tempDir = userInS.tempDir;
strListC = userInS.structList;
cropS = userInS.crop;
outSizeV = userInS.imageSizeForModel;
resizeMethod = userInS.resize.method;
dataSplitV = userInS.dataSplit;

%% Create directories to write CERR, HDF5 files
fprintf('\nCreating directories for CERR, HDF5 files...\n');
mkdir(tempDir)

cerrPath = fullfile(tempDir,'dataCERR');
mkdir(cerrPath)

HDF5path = fullfile(tempDir,'dataHDF5');
mkdir(HDF5path)

mkdir([HDF5path,filesep,'Train']);
mkdir([HDF5path,filesep,'Train',filesep,'Masks']);

mkdir([HDF5path,filesep,'Val']);
mkdir([HDF5path,filesep,'Val',filesep,'Masks']);

mkdir([HDF5path,filesep,'Test']);
mkdir([HDF5path,filesep,'Test',filesep,'Masks']);

fprintf('\nComplete\n');

%% Import data to CERR
zipFlag = 'No';
mergeScansFlag = 'No';
batchConvert(dcmDir,cerrPath,zipFlag,mergeScansFlag);

%% Convert to HDF5 with preprocessing and split into train, val, test datasets
CERRtoHDF5(cerrPath, HDF5path, dataSplitV, strListC, outSizeV, resizeMethod, cropS);


end