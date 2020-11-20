function [userOptS,errC] = prepareSegDataset(paramFilename,inputDir,outputDir)
% prepareSegDataset.m
%
% Script to preprocess and convert data to HDF5 format, split into training,
% validation, and test datasets.
%
% AI 3/15/19
%---------------------------------------------------------------------------
% INPUTS
%
% paramFilename : Path to JSON file with parameters.
% inputDir      : Path to input data (DICOM or CERR format)
% outputDir     : Path for writing intermediate files(CERR, HDF5)
%
% --- JSON fields ---:
% inputFileType    : May be 'DICOM' or 'CERR'
% structList       : Names of structures to be segmented
% dataSplit        : %Train/%Val/%Test split passed as vector [%train %val]
%                    (%test = 100-%train-%val).
%                    NOTE- Assumes 100% testing if unspecified.
% resample         : Dictionary of resampling parameters-- resolutionXCm,
%                    resolutionYcm, resolutionZCm and method.
%                    Supported methods include 'sinc', 'none'.
% resize           : Resize image as required by model
%                    Supported methods: 'pad', 'bilinear', 'sinc', 'none'.
%                    Suppoted params:'size'
% crop             : Dictionary of options for cropping with fields
%                    'methods', 'params', 'operator'
%                    Supported methods include 'crop_fixed_amt','crop_to_bounding_box',
%                    'crop_to_str', 'crop_around_center', 'crop_pt_outline',
%                    'crop_shoulder'  'none'.
% view             : Image orientation. Supported options include 'axial'
%                    (default), 'coronal', and 'sagittal'.
% channels         : Dictionary with fields 'imageType', 'slice', and
%                    'scantype' (optional - in case multiple
%                    sequences are being used).
%                    Supported image types: 'original' and filters from
%                    processImg.m. 
%                    Supported slice inputs:'current-n','current','current+n',
%                    where n is no. of slices relative to current slice.
% batchSize        : Value of batch size to pass to the Deep Learning Model 
%
% Example: See sample_train_params.json
%---------------------------------------------------------------------------
% AI 9/3/19 Added inputFileType, resampling
% AI 9/4/19 Added options to populate channels
% AI 9/11/19 Updated for compatibility with testing pipeline
% RKP 9/18/19 Additional updates for compatibility with testing pipeline
% AI 9/18/19 Added readDLConfigFile

%% Get user inputs from JSON
userOptS = readDLConfigFile(paramFilename);
dataSplitV = userOptS.dataSplit;                                                   
 
%% Create directories to write CERR, HDF5 files
fprintf('\nCreating directories for HDF5 files...\n');
if ~exist(outputDir,'dir')
    mkdir(outputDir)
end

HDF5path = fullfile(outputDir,'inputH5');   
mkdir(HDF5path)

fprintf('\nComplete\n');

%% Import data to CERR
if strcmpi(userOptS.inputFileType,'DICOM')
    
    CERRpath = fullfile(outputDir,'inputCERR');
    mkdir(CERRpath)
    
    zipFlag = 'No';
    mergeScansFlag = 'No';
    batchConvert(inputDir,CERRpath,zipFlag,mergeScansFlag);
    
elseif strcmpi(userOptS.inputFileType,'CERR')
    
    %input CERR format
    CERRpath = inputDir;
    
else
    error('Input file format not supported');
end

%% Convert to HDF5 with preprocessing and split into train, val, test datasets
errC = CERRtoHDF5(CERRpath, HDF5path, userOptS);


end