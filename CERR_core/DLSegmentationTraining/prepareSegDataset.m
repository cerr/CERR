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
% outputDir        : Path for writing intermediate files(CERR, HDF5)
% structList       : Names of structures to be segmented
% dataSplit        : %Train/%Val/%Test split passed as vector [%train %val]
%                    (%test = 100-%train-%val).
% imageSizeForModel: Dimensions of output image required by model
% resample         : Dictionary of resampling parameters-- resolutionXCm,
%                    resolutionYcm, resolutionZCm and method.
%                    Supported methods include 'sinc', 'none'.
% resize           : Resize image as required by model
%                    Supported methods: 'pad', 'bilinear', 'sinc', 'none'.
% crop             : Dictionary of options for cropping with fields
%                    'methods', 'params', 'operator'
%                    Supported methods include 'crop_fixed_amt','crop_to_bounding_box',
%                    'crop_to_str', 'crop_around_center', 'none'.
% channels         : Dictionary with fields 'number', 'imageType' and 'append'.
%                    Supported image types: 'original', 'coronal', 'sagittal'.
%                    Supported methods of appending: 'repeat','2.5D','multiscan'.
%
% Example: See sample_train_params.json
%---------------------------------------------------------------------------
% AI 9/3/19 Added inputFileType, resampling
% AI 9/4/19 Added options to populate channels

%% Get user inputs from JSON
userInS = jsondecode(fileread(paramFilename));
inputFileType = userInS.inputFileType;
inputDir = userInS.inputDir;
outputDir = userInS.outputDir;
strListC = userInS.structList;
dataSplitV = userInS.dataSplit;

%Set defaults for optional inputs
defaultS = struct();
defaultS.crop.method = 'none';
defaultS.imageSizeForModel = [];
defaultS.resize.method = 'none';
defaultS.resample.method = 'none';
defaultS.channels.imageType = 'original';
defaultS.channels.append.method = 'none';

userOptS = struct();
defC = fieldnames(defaultS);
for n = 1:length(defC)
    if isfield(userInS,defC{n})
        userOptS.(defC{n}) = userInS.(defC{n});
    else
        userOptS.(defC{n}) = defaultS.(defC{n});
    end
end

%% Create directories to write CERR, HDF5 files
fprintf('\nCreating directories for HDF5 files...\n');
mkdir(outputDir)

HDF5path = fullfile(outputDir,'dataHDF5');
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
    
    CERRpath = fullfile(outputDir,'dataCERR');
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