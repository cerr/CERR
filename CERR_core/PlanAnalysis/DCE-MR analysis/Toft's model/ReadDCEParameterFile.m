function [inputS,paramFile] = ReadDCEParameterFile(paramDir)
% Function for reading in a patient DCE parameter file.
%
% AI 5/26/16
% AI 8/9/17 Removed basePts from parameter file
%
% Output: parameter dictionary created from user-input .txt file
%
% Valid parameters :
%
% 1. AIFSource        : "A" for aorta, 'I' for Iliac 13-019, "PI" for Tong
%                        POST iliac, "SP" for single patient, "PROSI" for prostate iliac
% 2. pathnameBase     : Can be 13-019, 14-172, 15-073 retro, retro-pre
% 3. model            : T = Tofts, ET = extended Tofts (Default)
% 4. saveMatPlot      : Set = 'y' to save fit curves (.fig format) (Default : 'n')
%                       Only do this if you are displaying a SMALL number of fit curves.
% 5. filt             : Set to 'y' to preprocess using spatial smoothing (default : 'n')
% 6. cAgent           : Contrast agent ('gd' = gd-dtpa, mh = multihance(default) )
% 7. T1Map            : T1 scan no. (default : 0)
% 8. displayImgNum    : Display fit for every display_im_num-th voxel (Default:50)
%                       e.g. if value = 30, display fit for every 30th voxel
% 9. CACut            : Contrast agent cutoff for non-enhancing voxels (default:0.1)
% 10. cutOff          : R-squared cutoff for maps. Default:0
%                       (NOTE: For Kristen, use 0.6 for 13-066, 0.7 for retro pre post,
%                       0.8 for 14-172.)
% 11. checkShift      : 'y' if shift needs to be determined by user (default : 'y')
% 12. checkAIFShift   : Default : 'y'
% 13. ETROIPointShift : Shift to start of uptake curve
% 14. TROIPointShift  : Shift to start of uptake curve
% 15. userAIFShift    : Default:0
% 16. skip            : Default:0
% 17. FAF             : Correction factor for flip angle. Default = 1 for axials
%
% ptional parameters 
% T10              : Native T1 for tissue
% T10ref           : T1 for reference (muscle) region in ms.
% fSize            : Filter size in voxels (Reqd if filt = 'y')
% fSigma           : Gaussian filter sigma (Reqd if filt = 'y')
% hct              : Hematocrit to convert blood conc to plasma
% D                : Contrast dose mmol/kg
% yMax             : Plot axis limit for
% skipArr          : Array of time points to skip (based on poor fit).
% muscleShift      : Muscle ROI shift 
% -----------------------------------------------------------------------------------------------------

% Interface to select (.txt) paramter file
prompt = 'Select DCE parameter file';
[paramFilename, fPath] = uigetfile([paramDir '/*.txt'],prompt);
paramFile = fullfile(fPath,paramFilename);

% Read parameters
fileID = fopen(paramFile);
inputC = textscan(fileID,'%s %s %n','endofline','\r\n');
inputC{3} = num2cell(inputC{3}); 
notString = strcmp(inputC{2},'na');          % Missing/numeric fields marked 'na' in column 2.
if any(notString)
inputC{2}(notString) = inputC{3}(notString); % Replace with numeric values
end
missing = strcmp(inputC{2},'na');            % Find Missing fields marked 'na' in cols 2 and 3.
if any(missing)
inputC{2}(missing) = '';                     % Leave missing fields blank
end
fclose(fileID);

%If skipArr passed as string - convert to numeric array
arrAsString = strcmp(inputC{1},'skipArr');
if any(arrAsString)
    strArr = inputC{2}(arrAsString);
    strArr = strArr{1}(2:end-1);
    inputC{2}(arrAsString) = {str2num(strArr)};
end

%Generate parameter structure
inputS = cell2struct(inputC{2},inputC{1},1);


end



