function varargout = dicm2nii(src, niiFolder, fmt)
% Convert dicom and more into nii or img/hdr files. 
% 
% DICM2NII(dcmSource, niiFolder, outFormat)
% 
% The input arguments are all optional:
%  1. source file or folder can be a zip or tgz file, a folder containing dicom
%     files, or other convertible files. It can also contain wildcards like 
%     'run1_*' for all files start with 'run1_'.
%  2. folder to save result files.
%  3. output file format:
%      0 or '.nii'           for single nii uncompressed.
%      1 or '.nii.gz'        for single nii compressed (default).
%      2 or '.hdr'           for hdr/img pair uncompressed.
%      3 or '.hdr.gz'        for hdr/img pair compressed.
%      4 or '.nii 3D'        for 3D nii uncompressed (SPM12).
%      5 or '.nii.gz 3D'     for 3D nii compressed.
%      6 or '.hdr 3D'        for 3D hdr/img pair uncompressed (SPM8).
%      7 or '.hdr.gz 3D'     for 3D hdr/img pair compressed.
%      'bids'                for bids data structure (http://bids.neuroimaging.io/)
%
% Typical examples:
%  DICM2NII; % bring up user interface if there is no input argument
%  DICM2NII('D:/myProj/zip/subj1.zip', 'D:/myProj/subj1/data'); % zip file
%  DICM2NII('D:/myProj/subj1/dicom/', 'D:/myProj/subj1/data'); % folder
% 
% Less common examples:
%  DICM2NII('D:/myProj/dicom/', 'D:/myProj/subj2/data', 'nii'); % no gz compress
%  DICM2NII('D:/myProj/dicom/run2*', 'D:/myProj/subj/data'); % convert run2 only
%  DICM2NII('D:/dicom/', 'D:/data', '3D.nii'); % SPM style files
% 
% If there is no input, or any of the first two input is empty, the graphic user
% interface will appear.
% 
% If the first input is a zip/tgz file, such as those downloaded from a dicom
% server, DICM2NII will extract files into a temp folder, create NIfTI files
% into the data folder, and then delete the temp folder. For this reason, it is
% better to keep the compressed file as backup.
% 
% If a folder is the data source, DICM2NII will convert all files in the folder
% and its subfolders (there is no need to sort files for different series).
% 
% The output file names adopt SeriesDescription or ProtocolName of each series
% used on scanner console. If both original and MoCo series are present, '_MoCo'
% will be appended for MoCo series. For phase image, such as those from field
% map, '_phase' will be appended to the name. If multiple subjects data are
% mixed (highly discouraged), subject name will be in file name. In case of name
% conflict, SeriesNumber, such as '_s005', will be appended to make file names
% unique. It is suggested to use short, descriptive and distinct
% SeriesDescription on the scanner console.
% 
% For SPM 3D files, the file names will have volume index in format of '_00001'
% appended to above name.
% 
% Please note that, if a file in the middle of a series is missing, the series
% will normally be skipped without converting, and a warning message in red text
% will be shown in Command Window. The message will also be saved into a text
% file under the data folder.
% 
% A Matlab data file, dcmHeaders.mat, is always saved into the data folder. This
% file contains dicom header from the first file for created series and some
% information from last file in field LastFile. Some extra information is also
% saved into this file. For MoCo series, motion parameters (RBMoCoTrans and
% RBMoCoRot) are also saved.
% 
% Slice timing information, if available, is stored in nii header, such as
% slice_code and slice_duration. But the simple way may be to use the field
% SliceTiming in dcmHeaders.mat. That timing is actually those numbers for FSL
% when using custom slice timing. This is the universal method to specify any
% kind of slice order, and for now, is the only way which works for multiband.
% Slice order is one of the most confusing parameters, and it is recommended to
% use this method to avoid mistake. Following shows how to convert this timing
% into slice timing in ms and slice order for SPM:
%   
%  load('dcmHeaders.mat'); % or drag and drop the MAT file into Command Window
%  s = h.myFuncSeries; % field name is the same as nii file name
%  spm_ms = (0.5 - s.SliceTiming) * s.RepetitionTime;
%  [~, spm_order] = sort(-s.SliceTiming);
% 
% Some information, such as TE, phase encoding direction and effective dwell
% time, are stored in descrip of nii header. These are useful for fieldmap B0
% unwarp correction. Acquisition start time and date are also stored, and this
% may be useful if one wants to align the functional data to some physiological
% recording, like pulse, respiration or ECG.
% 
% If there is DTI series, bval and bvec files will be generated for FSL etc.
% bval and bvec are also saved in the dcmHeaders.mat file.
% 
% Starting from 20150514, the converter stores some useful information in NIfTI
% text extension (ecode=6). nii_tool can decode these information easily:
%  ext = nii_tool('ext', 'myNiftiFile.nii'); % read NIfTI extension
% ext.edata_decoded contains all above mentioned information, and more. The
% included nii_viewer can show the extension by Window->Show NIfTI ext.
% 
% Several preference can be set from dicm2nii GUI. The preference change stays
% in effect until it is changed next time. 
% 
% One of preference is to save a .json file for each converted NIfTI. For more
% information about the purpose of json file, check
%  http://bids.neuroimaging.io/ 
% 
% By default, the converter will use parallel pool for dicom header reading if
% there are 2000+ files. User can turn this off from GUI.
% 
% By default, the PatientName is stored in NIfTI hdr and ext. This can be turned
% off from GUI.
% 
% Please note that some information, such as the slice order information, phase
% encoding direction and DTI bvec are in image reference, rather than NIfTI
% coordinate system. This is because most analysis packages require information
% in image space. For this reason, in case the image in a NIfTI file is flipped
% or re-oriented, these information may not be correct anymore.
% 
% Please report any bug to xiangrui.li@gmail.com or at
% https://github.com/xiangruili/dicm2nii/issues
% http://www.mathworks.com/matlabcentral/fileexchange/42997
% 
% To cite the work and for more detail about the conversion, check the paper at
% http://www.sciencedirect.com/science/article/pii/S0165027016300073
% 
% See also NII_VIEWER, NII_MOCO, NII_STC

% Thanks to:
% Jimmy Shen's Tools for NIfTI and ANALYZE image,
% Chris Rorden's dcm2nii pascal source code,
% Przemyslaw Baranski for direction cosine matrix to quaternions. 

% History (yymmdd):
% 130512 Publish to CCBBI users (Xiangrui Li).
% 130823 Remove dependency on Image Processing Toolbox.
% 130919 Work for GE and Philips dicom at Chris R website.
% 130923 Work for Philips PAR/REC pair files.
% 131021 Implement conversion for AFNI HEAD/BRIK.
% 131219 Write warning message to a file in data folder (Gui's suggestion).
% 140621 Support tgz file as data source.
% 150112 Use nii_tool.m, remove make_nii, save_nii etc from this file.
% 150209 Support output format for SPM style: 3D output;
% 150405 Implement BrainVoyager dmr/fmr/vmr conversion: need BVQX_file. 
% 150514 set_nii_ext: start to store txt edata (ecode=6).
% 160127 dicm_hdr & dicm_img: support big endian dicom.
% 160229 reorient now makes det<0, instead negative 1st axis (cor slice affected).
% 170404 set MB slice_code to 0 to avoid FreeSurfer error. Thx JacobM.
% 170826 Use 'VolumeTiming' for missing volumes based on BIDS.
% 171211 Make it work for Siemens multiframe dicom (seems 3D only).
% 180523 set_nii_hdr: use MRScaleSlope for Philips, same as dcm2niiX default.
% 180530 store EchoTimes and CardiacTriggerDelayTimes;
%        split_components: not only phase, json for each file (thx ChrisR).
% 180614 Implement scale_16bit: free precision for tools using 16-bit datatype. 
% 180914 support UIH dicm, both GRID (mosaic) and regular. 
% 190122 add BIDS support. tanguy.duval@inserm.fr
%  Most later history relies on GitHub

% TODO: need testing files to figure out following parameters:
%    flag for MOCO series for GE/Philips
%    GE non-axial slice (phase: ROW) bvec sign

if nargout, varargout{1} = ''; end
if nargin==3 && ischar(fmt) && strcmp(fmt, 'func_handle') % special purpose
    varargout{1} = str2func(niiFolder);
    return;
end

%% Deal with output format first, and error out if invalid
if nargin<3 || isempty(fmt), fmt = 1; end % default .nii.gz
no_save = ischar(fmt) && strcmp(fmt, 'no_save');
if no_save, fmt = 'nii'; end

bids = false;
if ischar(fmt) && strcmpi(fmt,'BIDS')
    bids = true;
    fmt = '.nii.gz';
end
if ischar(fmt) && strcmpi(fmt,'BIDSNII')
    bids = true;
    fmt = '.nii';
end
if bids && verLessThanOctave
    fprintf('BIDS conversion is easier with MATLAB R2018a or later.\n')
end

if (isnumeric(fmt) && any(fmt==[0 1 4 5])) || ...
        (ischar(fmt) && ~isempty(regexpi(fmt, 'nii')))
    ext = '.nii';
elseif (isnumeric(fmt) && any(fmt==[2 3 6 7])) || (ischar(fmt) && ...
        (~isempty(regexpi(fmt, 'hdr')) || ~isempty(regexpi(fmt, 'img'))))
    ext = '.img';
else
    error(' Invalid output file format (the 3rd input).');
end

if (isnumeric(fmt) && mod(fmt,2)) || (ischar(fmt) && ~isempty(regexpi(fmt, '.gz')))
    ext = [ext '.gz']; % gzip file
end

rst3D = (isnumeric(fmt) && fmt>3) || (ischar(fmt) && ~isempty(regexpi(fmt, '3D')));

if nargin<1 || isempty(src) || (nargin<2 || isempty(niiFolder))
    create_gui; % show GUI if input is not enough
    return;
end

%% Deal with niiFolder
if ~isfolder(niiFolder), mkdir(niiFolder); end
niiFolder = strcat(fullName(niiFolder), filesep);
converter = ['dicm2nii.m ' getVersion];
if errorLog('', niiFolder) && ~no_save % remember niiFolder for later call
    more off;
    disp(['Xiangrui Li''s ' converter ' (feedback to xiangrui.li@gmail.com)']);
end

%% Deal with data source
tic;
if isnumeric(src)
    error('Invalid dicom source.');    
elseif iscellstr(src) %#ok<*ISCLSTR> % multiple files/folders
    fnames = {};
    for i = 1:numel(src)
        if isfolder(src{i})
            fnames = [fnames filesInDir(src{i})];
        else
            a = dir(src{i});
            if isempty(a), continue; end
            dcmFolder = fileparts(fullName(src{i}));
            fnames = [fnames fullfile(dcmFolder, a.name)];
        end
    end
elseif isfolder(src) % folder
    fnames = filesInDir(src);
elseif ~exist(src, 'file') % like input: run1*.dcm
    fnames = dir(src);
    if isempty(fnames), error('%s does not exist.', src); end
    fnames([fnames.isdir]) = [];
    dcmFolder = fileparts(fullName(src));
    fnames = strcat(dcmFolder, filesep, {fnames.name});    
elseif ischar(src) % 1 dicom or zip/tgz file
    dcmFolder = fileparts(fullName(src));
    unzip_cmd = compress_func(src);
    if isempty(unzip_cmd)
        fnames = dir(src);
        fnames = strcat(dcmFolder, filesep, {fnames.name});
    else % unzip if compressed file is the source
        [~, fname, ext1] = fileparts(src);
        dcmFolder = sprintf('%stmpDcm%s/', niiFolder, fname);
        if ~isfolder(dcmFolder)
            mkdir(dcmFolder);
            delTmpDir = onCleanup(@() rmdir(dcmFolder, 's'));
        end
        fprintf('Extracting files from %s%s ...\n', fname, ext1);
        
        if strcmp(unzip_cmd, 'unzip')
            cmd = sprintf('unzip -qq -o %s -d %s', src, dcmFolder);
            err = system(cmd); % first try system unzip
            if err, unzip(src, dcmFolder); end % Matlab's unzip is too slow
        elseif strcmp(unzip_cmd, 'untar')
            if isempty(which('untar'))
                error('No untar found in matlab path.');
            end
            untar(src, dcmFolder);
        end
        fnames = filesInDir(dcmFolder);
    end
else
    error('Unknown dicom source.');
end
nFile = numel(fnames);
if nFile<1, error(' No files found in the data source.'); end

%% user preference
pf.save_patientName = getpref('dicm2nii_gui_para', 'save_patientName', true);
pf.save_json        = getpref('dicm2nii_gui_para', 'save_json', false);
pf.use_parfor       = getpref('dicm2nii_gui_para', 'use_parfor', true);
pf.use_seriesUID    = getpref('dicm2nii_gui_para', 'use_seriesUID', true);
pf.lefthand         = getpref('dicm2nii_gui_para', 'lefthand', true);
pf.scale_16bit      = getpref('dicm2nii_gui_para', 'scale_16bit', false);

%% Check each file, store partial header in cell array hh
% first 2 fields are must. First 10 indexed in code
flds = {'Columns' 'Rows' 'BitsAllocated' 'SeriesInstanceUID' 'SeriesNumber' ...
    'ImageOrientationPatient' 'ImagePositionPatient' 'PixelSpacing' ...
    'SliceThickness' 'SpacingBetweenSlices' ... % these 10 indexed in code
    'PixelRepresentation' 'BitsStored' 'HighBit' 'SamplesPerPixel' ...
    'PlanarConfiguration' 'EchoTime' 'RescaleIntercept' 'RescaleSlope' ...
    'InstanceNumber' 'NumberOfFrames' 'B_value' 'DiffusionGradientDirection' ...
    'TriggerTime' 'RTIA_timer' 'RBMoCoTrans' 'RBMoCoRot' 'AcquisitionNumber' ...
    'CoilString' 'TemporalPositionIdentifier' ...
    'MRImageGradientOrientationNumber' 'MRImageLabelType' 'SliceNumberMR' 'PhaseNumber'};
dict = dicm_dict('SIEMENS', flds); % dicm_hdr will update vendor if needed

% read header for all files, use parpool if available and worthy
if ~no_save, fprintf('Validating %g files ... ', nFile); end
hh = cell(1, nFile); errStr = cell(1, nFile);
doParFor = pf.use_parfor && nFile>2000 && useParTool;
for k = 1:nFile
    [hh{k}, errStr{k}, dict] = dicm_hdr(fnames{k}, dict);
    if doParFor && ~isempty(hh{k}) % parfor wont allow updating dict
        parfor i = k+1:nFile
            [hh{i}, errStr{i}] = dicm_hdr(fnames{i}, dict); 
        end
        break; 
    end
end
hh(cellfun(@(c)isempty(c) || any(~isfield(c, flds(1:2))) || ~isfield(c, 'PixelData') ...
    || (isstruct(c.PixelData) && c.PixelData.Bytes<1), hh)) = [];
if ~no_save, fprintf('(%g valid)\n', numel(hh)); end

%% sort headers into cell h by SeriesInstanceUID/SeriesNumber
h = {}; % in case of no dicom files at all
if pf.use_seriesUID % use UID unless asked not to do so
    hasID = cellfun(@(c)isfield(c,'SeriesInstanceUID'), hh);
    hh0 = hh(hasID);
    sUID = cellfun(@(c)c.SeriesInstanceUID, hh0, 'UniformOutput', false);
    [sUID, ~, ic] = unique(sUID);
    for k = 1:numel(sUID), h{k} = hh0(ic==k); end
    hh = hh(~hasID); % likely none after UID
end
hasSN = cellfun(@(c)isfield(c,'SeriesNumber'), hh);
hh0 = hh(hasSN);
sNs = cellfun(@(c)c.SeriesNumber, hh0);
[sNs, ~, ic] = unique(sNs);
n = numel(h);
for k = 1:numel(sNs), h{k+n} = hh0(ic==k); end % rely on SN
hh = hh(~hasSN);
n = numel(h);
for k = 1:numel(hh), h{k+n} = hh(k); end % treat as separate series if no SN

%% Split each series by CoilString (seen for uncombined Siemens)
hSuf = repmat({''}, 1, numel(h));
for i = 1:numel(h)
    hh = h{i};
    try
        cs = cellfun(@(c)c.CoilString, hh, 'UniformOutput', false);
        [cs, ~, ic] = unique(cs);
        if numel(cs)<2, continue; end
        for k = 1:numel(cs)
            h{end+1} = hh(ic==k); hSuf{end+1} = ['_c' cs{k}]; % like dcm2niix
        end
        h{i} = [];
    end
end
a = cellfun(@isempty, h);
h(a) = []; hSuf(a) = [];

%% Split series by ComplexImageComponent
for i = 1:numel(h)
    hh = h{i};
    try
        cs = cellfun(@(c)c.ComplexImageComponent, hh, 'UniformOutput', false);
        [cs, ~, ic] = unique(cs);
        if numel(cs)<2, continue; end
        for k = 1:numel(cs)
            h{end+1} = hh(ic==k); hSuf{end+1} = ['_' cs{k}];
        end
        h{i} = [];
    end
end
a = cellfun(@isempty, h);
h(a) = []; hSuf(a) = [];

%% Split series by EchoTime
for i = 1:numel(h)
    hh = h{i};
    try
        [ETs, ~, ic] = unique(cellfun(@(c)c.EchoTime, hh));
        if numel(ETs)<2, continue; end
        for k = 1:numel(ETs)
            h{end+1} = hh(ic==k); hSuf{end+1} = [hSuf{i} '_e' num2str(k)];
        end
        h{i} = [];
    end
end
a = cellfun(@isempty, h);
h(a) = []; hSuf(a) = [];

%% sort each series by InstanceNumber
for i = 1:numel(h)
    try
        [~, ia] = sort(cellfun(@(c)c.InstanceNumber, h{i}));
        h{i} = h{i}(ia);
    end
end

%% Check headers: remove dim-inconsistent series
nRun = numel(h);
if nRun<1 % no valid series
    errorLog(sprintf('No valid files found:\n%s.', strjoin(unique(errStr), '\n'))); 
    return;
end
keep = true(1, nRun); % true for useful runs
subjs = cell(1, nRun); vendor = cell(1, nRun);
sNs = ones(1, nRun); studyIDs = cell(1, nRun);
fldsCk = {'ImageOrientationPatient' 'NumberOfFrames' 'Columns' 'Rows' ...
          'PixelSpacing' 'RescaleIntercept' 'RescaleSlope' 'SamplesPerPixel' ...
          'SpacingBetweenSlices' 'SliceThickness'}; % last for thickness
for i = 1:nRun
    s = h{i}{1};
    if ~isfield(s, 'LastFile') % avoid re-read for PAR/HEAD/BV file
        s = dicm_hdr(s.Filename); % full header for 1st file
    end
    if ~isfield(s, 'Manufacturer'), s.Manufacturer = 'Unknown'; end
    subjs{i} = PatientName(s);
    acqs{i} =  AcquisitionDateField(s);
    vendor{i} = s.Manufacturer;
    if isfield(s, 'SeriesNumber'), sNs(i) = s.SeriesNumber; 
    else, sNs(i) = fix(toc*1e6); 
    end
    studyIDs{i} = tryGetField(s, 'StudyID', '1');
    series = sprintf('Subject %s, %s (Series %g)', subjs{i}, ProtocolName(s), sNs(i));
    s = multiFrameFields(s); % no-op if non multi-frame
    if isempty(s), keep(i) = 0; continue; end % invalid multiframe series
    s.isDTI = isDTI(s);
    if ~isfield(s, 'AcquisitionDateTime') % assumption: 1st instance is earliest
        try s.AcquisitionDateTime = [s.AcquisitionDate s.AcquisitionTime]; end
    end
    
    h{i}{1} = s; % update record in case of full hdr or multiframe
    
    nFile = numel(h{i});
    if nFile>1 && tryGetField(s, 'NumberOfFrames', 1) > 1 % seen in vida
        for k = 2:nFile % this can be slow: improve in the future
            h{i}{k} = dicm_hdr(h{i}{k}.Filename); % full header
            h{i}{k} = multiFrameFields(h{i}{k});
        end
    end
    
    % check consistency in 'fldsCk'
    nFlds = numel(fldsCk);
    if isfield(s, 'SpacingBetweenSlices'), nFlds = nFlds - 1; end % check 1 of 2
    for k = 1:nFlds*(nFile>1)
        if isfield(s, fldsCk{k}), val = s.(fldsCk{k}); else, continue; end
        val = repmat(double(val), [1 nFile]);
        for j = 2:nFile
            if isfield(h{i}{j}, fldsCk{k}), val(:,j) = h{i}{j}.(fldsCk{k});
            else, keep(i) = 0; break;
            end
        end
        if ~keep(i), break; end % skip silently
        ind = sum(abs(bsxfun(@minus, val, val(:,2))), 1) / sum(abs(val(:,2))) > 0.01;
        if ~any(ind), continue; end % good
        if any(strcmp(fldsCk{k}, {'RescaleIntercept' 'RescaleSlope'}))
            h{i}{1}.ApplyRescale = true;
            continue;
        end
        if numel(ind)>2 && sum(ind)==1 % 2+ files but only 1 inconsistent
            h{i}(ind) = []; % remove first or last, but keep the series
            nFile = nFile - 1;
            if ind(1) % re-do full header for new 1st file
                s = dicm_hdr(h{i}{1}.Filename);
                s.isDTI = isDTI(s);
                h{i}{1} = s;
            end
        else
            errorLog(['Inconsistent ''' fldsCk{k} ''' for ' series '. Series skipped.']);
            keep(i) = 0; break;
        end
    end
    
    nSL = nMosaic(s); % nSL>1 for mosaic
    if ~isempty(nSL) && nSL>1
        h{i}{1}.isMos = true;
        h{i}{1}.LocationsInAcquisition = nSL;
        if s.isDTI, continue; end % allow missing directions for DTI
        a = zeros(1, nFile);
        for j = 1:nFile, a(j) = tryGetField(h{i}{j}, 'InstanceNumber', 1); end
        if numel(unique(diff(4)))>1 % like CMRR ISSS seq or multi echo. Error for UIH
            errorLog(['InstanceNumber discontinuity detected for ' series '.' ...
                'See VolumeTiming in NIfTI ext or dcmHeaders.mat.']);
            dict = dicm_dict('', {'AcquisitionDate' 'AcquisitionTime'});
            vTime = nan(1, nFile);
            for j = 1:nFile
                s2 = dicm_hdr(h{i}{j}.Filename, dict);
                dt = [s2.AcquisitionDate s2.AcquisitionTime];
                vTime(j) = datenum(dt, 'yyyymmddHHMMSS.fff');
            end
            vTime = vTime - min(vTime);
            h{i}{1}.VolumeTiming = vTime * 86400; % day to seconds
        end
        continue; % no other check for mosaic
    end
        
    if ~keep(i) || nFile<2 || ~isfield(s, 'ImagePositionPatient'), continue; end
    if tryGetField(s, 'NumberOfFrames', 1) > 1, continue; end % Siemens Vida
    
    [err, h{i}] = checkImagePosition(h{i}); % may re-oder h{i} for Philips
    if ~isempty(err)
        errorLog([err ' for ' series '. Series skipped.']);
        keep(i) = 0; continue; % skip
    end    
end
h = h(keep); sNs = sNs(keep); studyIDs = studyIDs(keep); hSuf = hSuf(keep);
subjs = subjs(keep); vendor = vendor(keep);
subj = unique(subjs);
acqs = acqs(keep);
acq = unique(acqs);

% sort h by PatientName, then StudyID, then SeriesNumber
% Also get correct order for subjs/studyIDs/nStudy/sNs for nii file names
[~, ind] = sortrows([subjs' studyIDs' num2cell(sNs')]);
h = h(ind); subjs = subjs(ind); studyIDs = studyIDs(ind); sNs = sNs(ind); hSuf = hSuf(ind); acqs = acqs(ind);
multiStudy = cellfun(@(c)numel(unique(studyIDs(strcmp(subjs,c))))>1, subjs);

%% Generate unique result file names
% Unique names are in format of SeriesDescription[_hSuf]_s007. Special cases are: 
%  for phase image, such as field_map phase, append '_phase' to the name;
%  for MoCo series, append '_MoCo' to the name if both series are present.
%  for multiple subjs, it is SeriesDescription_subj_s007
%  for multiple Study, it is SeriesDescription_subj_Study1_s007
nRun = numel(h); % update it, since we have removed some
if nRun<1
    errorLog('No valid series found');
    return;
end
rNames = cell(1, nRun);
multiSubj = numel(subj)>1;
j_s = nan(nRun, 1); % index-1 for _s003. needed if 4+ length SeriesNumbers

for i = 1:nRun
    s = h{i}{1};
    sN = sNs(i);
    a = [ProtocolName(s) hSuf{i}];
    if isPhase(s), a = [a '_phase']; end % phase image
    if i>1 && sN-sNs(i-1)==1 && isType(s, '\MOCO\') && strncmp(a, rNames{i-1}, numel(a))
        a = [a '_MoCo'];
    end
    if asc_header(s, 'sPreScanNormalizeFilter.ucSaveUnfiltered', 0) && isType(s, '\NORM')
        a = [a '_NORM'];
    end
    if multiSubj, a = [a '_' subjs{i}]; end
    if multiStudy(i), a = [a '_Study' studyIDs{i}]; end
    if ~isstrprop(a(1), 'alpha'), a = ['x' a]; end % genvarname behavior
    % a = regexprep(a, '(?<=\S)\s+([a-z])', '${upper($1)}'); % camel case
    a = regexprep(regexprep(a, '[^a-zA-Z0-9_]', '_'), '_{2,}', '_');
    if sN>100 && strncmp(s.Manufacturer, 'Philips', 7)
        sN = tryGetField(s, 'AcquisitionNumber', floor(sN/100));
    end
    j_s(i) = numel(a);
    rNames{i} = sprintf('%s_s%03i', a, sN);
    d = numel(rNames{i}) - 255; % file max len = 255
    if d>0, rNames{i}(j_s(i)+(-d+1:0)) = ''; j_s(i) = j_s(i)-d; end % keep _s007
end

vendor = strtok(unique(vendor));
if nargout>0, varargout{1} = subj; end % return converted subject IDs

% After following sort, we need to compare only neighboring names. Remove
% _s007 if there is no conflict. Have to ignore letter case for Windows & MAC
fnames = rNames; % copy it, reserve letter cases
[rNames, iRuns] = sort(lower(fnames));
j_s = j_s(iRuns);
for i = 1:nRun
    if i>1 && strcmp(rNames{i}, rNames{i-1}) % truncated StudyID to PatientName
        a = num2str(i);
        rNames{i}(j_s(i)+(-numel(a)+1:0)) = a; % not 100% unique    
    end
    a = rNames{i}(1:j_s(i)); % remove _s003
    % no conflict with both previous and next name
    if nRun==1 || ... % only one run
         (i==1    && ~strcmpi(a, rNames{2}(1:j_s(2)))) || ... % first
         (i==nRun && ~strcmpi(a, rNames{i-1}(1:j_s(i-1)))) || ... % last
         (i>1 && i<nRun && ~strcmpi(a, rNames{i-1}(1:j_s(i-1))) ...
                        && ~strcmpi(a, rNames{i+1}(1:j_s(i+1)))) % middle ones
        fnames{iRuns(i)}(j_s(i)+1:end) = [];
    end
end
if numel(unique(fnames)) < nRun % may happen to user-modified dicom/par
    fnames = matlab.lang.makeUniqueStrings(fnames); % since R2014a
end
fmtStr = sprintf(' %%-%gs %%dx%%dx%%dx%%d\n', max(cellfun(@numel, fnames))+12);

%% Now ready to convert nii series by series
subjStr = sprintf('''%s'', ', subj{:}); subjStr(end+(-1:0)) = [];
vendor = sprintf('%s, ', vendor{:}); vendor(end+(-1:0)) = [];
if ~no_save
    fprintf('Converting %g series (%s) into %g-D %s: subject %s\n', ...
            nRun, vendor, 4-rst3D, ext, subjStr);
end

%% Parse BIDS
if bids
    pf.save_json = true; % force to save json for BIDS
    % Manage Multiple SUBJECT or SESSION
    if multiSubj
        fprintf(['Multiple subjects detected!!!!! Skipping...\n' ...
            'Please convert subjects one by one with BIDS options\n'])
        fprintf('%s\n',subj{:})
        for isub = 1:length(subj)
            fprintf('Converting subject one by one...  %s\n',subj{isub})
            isublist = strcmp(subjs,subj{isub});
            FileNames = cellfun(@(y) cellfun(@(x) x.Filename,y,'uni',0),h(isublist),'uni',0);
            dicm2nii([FileNames{:}],niiFolder,'bids')
        end
        return;
    end
    if numel(acq)>1
        fprintf('Multiple acquitisition detected!!!!! \n')
        for iacq = 1:length(acq)
            fprintf('Converting sessions one by one...  %s\n',acq{iacq})
            iacqlist = strcmp(acqs,acq{iacq});
            FileNames = cellfun(@(y) cellfun(@(x) x.Filename,y,'uni',0),h(iacqlist),'uni',0);
            dicm2nii([FileNames{:}],niiFolder,'bids')
        end
        return;
    end

    % Table: subject Name
    Subject = regexprep(subj, '[^0-9a-zA-Z]', '');
    Session                = {''};
    AcquisitionDate = {[acq{1}(1:4) '-' acq{1}(5:6) '-' acq{1}(7:8)]};
    Comment                = {'N/A'};
    S = table(Subject,Session,AcquisitionDate,Comment);

    types = {'skip' 'anat' 'dwi' 'fmap' 'func' 'perf'};
    modalities = {'skip' 'FLAIR' 'FLASH' 'PD' 'PDmap' 'T1map' 'T1rho' 'T1w' 'T2map'  ...
        'T2star''T2w' 'asl' 'dwi'  'fieldmap' 'm0scan' 'magnitude1' 'magnitude2' ...
        'phase1' 'phase2' 'phasediff' 'task-motor_bold' 'task-rest_bold'};
    Modality = categorical(repmat({'skip'}, [length(fnames) 1]), modalities);
    Type = categorical(repmat({'skip'},[length(fnames),1]), types);
    Name = regexprep(fnames', '_s\d+$', '');
    T = table(Name,Type,Modality);
    
    ModalityTablePref = getpref('dicm2nii_gui_para', 'ModalityTable', T);
    [Lia, Locb] = ismember(T.Name, ModalityTablePref.Name);
    for i = 1:nRun
        if Lia(i)
            T.Type(i) = ModalityTablePref.Type(Locb(i));
            T.Modality(i) = ModalityTablePref.Modality(Locb(i));
            continue;
        end
        seq = tryGetField(h{i}{1}, 'SequenceName', '');
        seqContains = @(p)any(cellfun(@(c)~isempty(strfind(seq,c)), p));
        if h{i}{1}.isDTI % do this first
            T.Type(i) = {'dwi'}; T.Modality(i) = {'dwi'};
        elseif seqContains({'epfid2d' 'EPI' 'epi'})
            T.Type(i) = {'func'};
            if ~isempty(regexpi(T.Name{i}, 'rest'))
                T.Modality(i) = {'task-rest'};
            else
                try nam = h{i}{1}.ProtocolName; 
                catch, nam = ProtocolName(h{i}{1});
                end
                c = regexpi(nam, '(.*)?run[-_]*(\d*)', 'tokens', 'once');
                if isempty(c)
                    c = regexprep(nam, '[^0-9a-zA-Z]', '');
                else
                    c = regexprep(c, '[^0-9a-zA-Z]', '');
                    c = sprintf('%s_run-%s', c{:});
                end
                T.Modality(i) = {['task-' c]};
            end
            ec = regexp(T.Name{i}, '_e\d+', 'match', 'once');
            if ~isempty(ec)
                T.Modality(i) = {[char(T.Modality(i)) '_echo-' ec(3:end)]};
            end
            if ~isempty(regexp(T.Name{i}, '_SBRef$', 'once'))
                T.Modality(i) = {[char(T.Modality(i)) '_sbref']};
            else
                T.Modality(i) = {[char(T.Modality(i)) '_bold']};
            end
        elseif seqContains({'fm2d' 'FFE'})
            T.Type(i) = {'fmap'};
            if strcmp(T.Name{i}(end+(-2:0)), '_e1')
                T.Modality(i) = {'magnitude1'};
            elseif strcmp(T.Name{i}(end+(-2:0)), '_e2')
                T.Modality(i) = {'magnitude2'};
            elseif isType(h{i}{1}, '\P\')
                T.Modality(i) = {'phasediff'};
            else
                T.Modality(i) = {'fieldmap'};
            end
        elseif seqContains({'epse'}) % after isDTI, is it safe?
            T.Type(i) = {'fmap'}; T.Modality(i) = {'fieldmap'};
        elseif seqContains({'tir2d'})
            T.Type(i) = {'anat'}; T.Modality(i) = {'FLAIR'};
        elseif seqContains({'tfl3d' 'T1' 'EFGRE3D' 'gre_fsp'})
            T.Type(i) = {'anat'}; T.Modality(i) = {'T1w'};
        elseif seqContains({'spc' 'T2'})
            T.Type(i) = {'anat'}; T.Modality(i) = {'T2w'};
        end
    end
    
    % GUI
    toSkip = any(ismember(cellfun(@char,table2cell(T(:,2:3)),'uni',0), 'skip'), 2);
    uniqueNames = unique(T.Modality(~toSkip));
    guiOn = getpref('dicm2nii_gui_para', 'bidsForceGUI', []);
    if ~isempty(guiOn), setpref('dicm2nii_gui_para', 'bidsForceGUI', []); end
    if isempty(guiOn)
        guiOn = ~all(Lia) || all(toSkip) || numel(uniqueNames)<sum(~toSkip);
    end
    if guiOn
        setappdata(0,'Canceldicm2nii',false);
        scrSz = get(0, 'ScreenSize');
        figargs = {'bids'*256.^(0:3)','Position',[min(scrSz(4)+420,620) scrSz(4)-600 800 400],...
            'Color', [1 1 1]*206/256, 'CloseRequestFcn', @my_closereq};
        if verLessThanOctave
            hf = figure(figargs{1});
            set(hf,figargs{2:end});
            % add help
            set(hf,'ToolBar','none')
            set(hf,'MenuBar','none')
        else
            hf = uifigure(figargs{:});
        end
        uimenu(hf,'Label','help','Callback',@(src,evnt)showHelp(types,modalities))
        set(hf,'Name', 'dicm2nii - BIDS Converter', 'NumberTitle', 'off')
        
        % tables
        if verLessThanOctave
            SCN = S.Properties.VariableNames;
            S   = table2cell(S);
            TCN = T.Properties.VariableNames;
            T   = cellfun(@char,table2cell(T),'uni',0);
        end
        TS = uitable(hf,'Data',S);
        TT = uitable(hf,'Data',T);
        TSpos = [20 hf.Position(4)-110 hf.Position(3)-160 90];
        TTpos = [20 20 hf.Position(3)-160 hf.Position(4)-120];
        if verLessThanOctave
            setpixelposition(TS,TSpos);
            set(TS,'Units','Normalized')
            setpixelposition(TT,TTpos);
            set(TT,'Units','Normalized')
        else
            TS.Position = TSpos;
            TT.Position = TTpos;
        end
        TS.ColumnEditable = [true true true true];
        if verLessThanOctave
            TS.ColumnName = SCN;
            TT.ColumnName = TCN;
        end
        TT.ColumnEditable = [false true true];
        
        % button
        Bpos = [hf.Position(3)-120 20 100 30];
        BCB  = @(btn,event) BtnModalityTable(hf,TT, TS);
        if verLessThanOctave
            B = uicontrol(hf,'Style','pushbutton','String','OK');
            set(B,'Callback',BCB);
            setpixelposition(B,Bpos)
            set(B,'Units','Normalized')
        else
            B = uibutton(hf,'Position',Bpos);
            B.Text = 'OK';
            B.ButtonPushedFcn = BCB;
        end
        
        % preview panel
        axesArgs = {hf,'Position',[hf.Position(3)-120 70 100 hf.Position(4)-90], 'Colormap',gray(64)};
        ax = previewDicom([],h{1},axesArgs);
        ax.YTickLabel = [];
        ax.XTickLabel = [];
        TT.CellSelectionCallback = @(src,event) previewDicom(ax,h{event.Indices(1)},axesArgs);
        
        waitfor(hf);
        if getappdata(0,'Canceldicm2nii'), return; end
        ModalityTable = getappdata(0,'ModalityTable');
        SubjectTable = getappdata(0,'SubjectTable');
        rmappdata(0,'ModalityTable'); rmappdata(0,'SubjectTable');
        
        % setpref
        ModalityTablePref = [ModalityTable; ModalityTablePref];
        [~, a] = unique(ModalityTablePref.Name, 'stable');
        setpref('dicm2nii_gui_para', 'ModalityTable', ModalityTablePref(a,:));
    else
        ModalityTable = cellfun(@char, table2cell(T),'uni',0);
        SubjectTable = S{1,:};
    end
        
    % participants.tsv
    try
        tsvfile = fullfile(niiFolder, 'participants.tsv');
        participant_id = SubjectTable{1,1};
        Sex = tryGetField(h{i}{1}, 'PatientSex');
        Age = tryGetField(h{i}{1}, 'PatientAge');
        if ischar(Age), Age = sscanf(Age, '%f'); end
        Size = tryGetField(h{i}{1}, 'PatientSize');
        Weight = tryGetField(h{i}{1}, 'PatientWeight');
        write_tsv(participant_id,tsvfile,'Age',Age,'Sex',Sex,'Weight',Weight,'Size',Size)
    catch
        warning('Could not save participants.tsv');
    end
    
    if isempty(SubjectTable{2}) % no session
        ses = '';
        session_id='';
    else
        session_id=SubjectTable{2};
        ses = ['ses-' session_id '_'];
    end
    
    % _session.tsv
    if ~isempty(ses)
        try
            tsvfile = fullfile(niiFolder, ['sub-' SubjectTable{1}],['sub-' SubjectTable{1} '_sessions.tsv']);
            if verLessThanOctave
                write_tsv(session_id,tsvfile,'acq_time',SubjectTable{3},'Comment',SubjectTable{4})
            else
                write_tsv(session_id,tsvfile,'acq_time',datestr(SubjectTable{3},'yyyy-mm-dd'),'Comment',SubjectTable{4})
            end
        catch ME
            fprintf(1, '\n')
            warning(['Could not save sub-' SubjectTable{1} '_sessions.tsv']);
            errorMessage = sprintf('Error in function %s() at line %d.\nError Message: %s\n\n', ...
                ME.stack(1).name, ME.stack(1).line, ME.message);
            fprintf(1, '%s\n', errorMessage);
        end
    end
end

%% Convert
for i = 1:nRun
    if bids
        if any(ismember(ModalityTable(i,2:3),'skip')), continue; end
        modalityfolder = fullfile(['sub-' SubjectTable{1}],...
                                    ses(1:end-1), ModalityTable{i,2});
        if ~exist(fullfile(niiFolder, modalityfolder),'dir')
            mkdir(fullfile(niiFolder, modalityfolder));
        end
        fnames{i} = fullfile(modalityfolder,...
              ['sub-' SubjectTable{1} '_' ses ModalityTable{i,3}]);
    end
    
    nFile = numel(h{i});
    h{i}{1}.NiftiName = fnames{i};
    s = h{i}{1};
    if nFile>1 && ~isfield(s, 'LastFile')
        h{i}{1}.LastFile = h{i}{nFile}; % store partial last header into 1st
    end
    
    for j = 1:nFile
        if j==1
            img = dicm_img(s, 0); % initialize img with dicm data type
            if ndims(img)>4 % err out, likely won't work for other series
                error('Image with 5 or more dim not supported: %s', s.Filename);
            end
            applyRescale = tryGetField(s, 'ApplyRescale', false);
            if applyRescale, img = single(img); end
        else
            if j==2, img(:,:,:,:,nFile) = 0; end % pre-allocate for speed
            img(:,:,:,:,j) = dicm_img(h{i}{j}, 0);
        end
        if applyRescale
            slope = tryGetField(h{i}{j}, 'RescaleSlope', 1);
            inter = tryGetField(h{i}{j}, 'RescaleIntercept', 0);
            img(:,:,:,:,j) = img(:,:,:,:,j) * slope + inter;
        end
    end
    if strcmpi(tryGetField(s, 'DataRepresentation', ''), 'COMPLEX')
        img = complex(img(:,:,:,1:2:end,:), img(:,:,:,2:2:end,:));
    end
    [~, ~, d3, d4, ~] = size(img);
    if strcmpi(tryGetField(s, 'SignalDomainColumns', ''), 'TIME') % no permute
    elseif d3<2 && d4<2, img = permute(img, [1 2 5 3 4]); % remove dim3,4
    elseif d4<2,         img = permute(img, [1:3 5 4]);   % remove dim4: Frames
    elseif d3<2,         img = permute(img, [1 2 4 5 3]); % remove dim3: RGB
    end

    nSL = double(tryGetField(s, 'LocationsInAcquisition'));
    if tryGetField(s, 'SamplesPerPixel', 1) > 1 % color image
        img = permute(img, [1 2 4:8 3]); % put RGB into dim8 for nii_tool
    elseif tryGetField(s, 'isMos', false) % mosaic
        img = mos2vol(img, nSL, strncmpi(s.Manufacturer, 'UIH', 3));
    elseif ndims(img)==3 && ~isempty(nSL) % may need to reshape to 4D
        if isfield(s, 'SortFrames'), img = img(:,:,s.SortFrames); end
        dim = size(img);
        dim(3:4) = [nSL dim(3)/nSL]; % verified integer earlier
        img = reshape(img, dim);
    end

    if any(~isfield(s, flds(6:8))) || ~any(isfield(s, flds(9:10)))
        h{i}{1} = csa2pos(h{i}{1}, size(img,3));
    end
    
    if isa(img, 'uint16') && max(img(:))<32768, img = int16(img); end % lossless    
    
    h{i}{1}.ConversionSoftware = converter;
    nii = nii_tool('init', img); % create nii struct based on img
    [nii, h{i}] = set_nii_hdr(nii, h{i}, pf, bids); % set most nii hdr

    % Save bval and bvec files after bvec perm/sign adjusted in set_nii_hdr
    fname = fullfile(niiFolder, fnames{i}); % name without ext
    if s.isDTI && ~no_save, save_dti_para(h{i}{1}, fname); end

    nii = split_components(nii, h{i}{1}); % split vol components
    if no_save % only return the first nii
        nii(1).hdr.file_name = strcat(fnames{i}, '.nii');
        nii(1).hdr.magic = 'n+1';
        varargout{1} = nii_tool('update', nii(1));
        return;
    end
    
    for j = 1:numel(nii)
        nam = fnames{i};
        if numel(nii)>1, nam = nii(j).hdr.file_name; end
        fprintf(fmtStr, nam, nii(j).hdr.dim(2:5));
        nii(j).ext = set_nii_ext(nii(j).json); % NIfTI extension
        if pf.save_json, save_json(nii(j).json, fname); end
        nii_tool('save', nii(j), fullfile(niiFolder, strcat(nam, ext)), rst3D);
    end
        
    if isfield(nii(1).hdr, 'hdrTilt')
        nii = nii_xform(nii(1), nii.hdr.hdrTilt);
        fprintf(fmtStr, strcat(fnames{i}, '_Tilt'), nii.hdr.dim(2:5));
        nii_tool('save', nii, strcat(fname, '_Tilt', ext), rst3D); % save xformed nii
    end
    
    h{i} = h{i}{1}; % keep 1st dicm header only
    if isnumeric(h{i}.PixelData), h{i} = rmfield(h{i}, 'PixelData'); end % BV
end

[~, fnames] = cellfun(@fileparts, fnames, 'UniformOutput', false);
try % since 2014a 
    fnames = matlab.lang.makeValidName(fnames);
    fnames = matlab.lang.makeUniqueStrings(fnames, {}, namelengthmax);
catch
    fnames = genvarname(fnames);
end
h = cell2struct(h, fnames, 2); % convert into struct
if bids, fname = fullfile(niiFolder, ['sub-' SubjectTable{1,1}], 'dcmHeaders.mat');
else, fname = fullfile(niiFolder, 'dcmHeaders.mat');
end
if exist(fname, 'file') % if file exists, we update fields only
    S = load(fname);
    for i = 1:numel(fnames), S.h.(fnames{i}) = h.(fnames{i}); end
    h = S.h;
end
save(fname, 'h', '-v7'); % -v7 better compatibility

fprintf('Elapsed time by dicm2nii is %.1f seconds\n\n', toc);
return;

%% Subfunction: return PatientName
function subj = PatientName(s)
subj = tryGetField(s, 'PatientName');
if isempty(subj), subj = tryGetField(s, 'PatientID', 'Anonymous'); end

%% Subfunction: return AcquisitionDate
function acq = AcquisitionDateField(s)
acq = tryGetField(s, 'AcquisitionDate');
if isempty(acq), acq = tryGetField(s, 'AcquisitionDateTime'); end
if isempty(acq), acq = tryGetField(s, 'SeriesDate'); end
if isempty(acq), acq = tryGetField(s, 'StudyDate', ''); end

%% Subfunction: return SeriesDescription
function name = ProtocolName(s)
name = tryGetField(s, 'SeriesDescription');
if isempty(name) || (strncmp(s.Manufacturer, 'SIEMENS', 7) && any(regexp(name, 'MoCoSeries$')))
    name = tryGetField(s, 'ProtocolName');
end
if isempty(name), [~, name] = fileparts(s.Filename); end
name = strtrim(name);

%% Subfunction: return true if keyword is in s.ImageType
function tf = isType(s, keyword)
typ = tryGetField(s, 'ImageType', '');
tf = ~isempty(strfind(typ, keyword)); %#ok<*STREMP>

%% Subfunction: return true if series is DTI
function tf = isDTI(s)
tf = isType(s, '\DIFFUSION'); % Siemens, Philips
if tf, return; end
if isfield(s, 'ProtocolDataBlock') % GE, not labeled as \DIFFISION
    IOPT = tryGetField(s.ProtocolDataBlock, 'IOPT');
    if isempty(IOPT), tf = tryGetField(s, 'DiffusionDirection', 0)>0;
    else, tf = ~isempty(regexp(IOPT, 'DIFF', 'once'));
    end
elseif strncmpi(s.Manufacturer, 'Philips', 7)
    tf = strcmp(tryGetField(s, 'MRSeriesDiffusion', 'N'), 'Y');
elseif isfield(s, 'ApplicationCategory') % UIH
    tf = ~isempty(regexp(s.ApplicationCategory, 'DTI', 'once'));
elseif isfield(s, 'AcquisitionContrast') % Bruker    
    tf = ~isempty(regexpi(s.AcquisitionContrast, 'DIFF', 'once'));
else % Some Siemens DTI are not labeled as \DIFFUSION
    tf = ~isempty(csa_header(s, 'B_value'));
end

%% Subfunction: return true if series is phase img
function tf = isPhase(s)
tf = isType(s, '\P\') || ...
    strcmpi(tryGetField(s, 'ComplexImageComponent', ''), 'PHASE'); % Philips

%% Subfunction: get field if exist, return default value otherwise
function val = tryGetField(s, field, dftVal)
if isfield(s, field), val = s.(field); 
elseif nargin>2, val = dftVal;
else, val = [];
end

%% Subfunction: Set most nii header and re-orient img
function [nii, h] = set_nii_hdr(nii, h, pf, bids)
dim = nii.hdr.dim(2:4); nVol = nii.hdr.dim(5);
% fld = 'NumberOfTemporalPositions';
% if ~isfield(h{1}, fld) && nVol>1, h{1}.(fld) = nVol; end

% Transformation matrix: most important feature for nii
[ixyz, R, pixdim, xyz_unit] = xform_mat(h{1}, dim); % R: dicom xform matrix
R(1:2,:) = -R(1:2,:); % dicom LPS to nifti RAS, xform matrix before reorient

% Compute bval & bvec in image reference for DTI series before reorienting
if h{1}.isDTI, [h, nii] = get_dti_para(h, nii); end

% Store CardiacTriggerDelayTime
fld = 'CardiacTriggerDelayTime';
if ~isfield(h{1}, 'CardiacTriggerDelayTimes') && nVol>1 && isfield(h{1}, fld)
    if numel(h) == 1 % multi frames
        iFrames = 1:dim(3):dim(3)*nVol;
        if isfield(h{1}, 'SortFrames'), iFrames = h{1}.SortFrames(iFrames); end
        s2 = struct(fld, nan(1,nVol));
        s2 = dicm_hdr(h{1}, s2, iFrames);
        tt = s2.(fld);
    else
        tt = zeros(1, nVol);
        inc = numel(h) / nVol;
        for j = 1:nVol
            tt(j) = tryGetField(h{(j-1)*inc+1}, fld, 0);
        end
    end
    if ~all(diff(tt)==0), h{1}.CardiacTriggerDelayTimes = tt; end
end

% Get EchoTime for each vol for 4D multi frames
if ~isfield(h{1}, 'EchoTimes') && nVol>1 && isfield(h{1}, 'EchoTime') && numel(h)<2
    iFrames = 1:dim(3):dim(3)*nVol;
    if isfield(h{1}, 'SortFrames'), iFrames = h{1}.SortFrames(iFrames); end
    s2 = struct('EffectiveEchoTime', nan(1,nVol));
    s2 = dicm_hdr(h{1}, s2, iFrames);
    ETs = s2.EffectiveEchoTime;
    if ~all(diff(ETs)==0), h{1}.EchoTimes = ETs; end
end

% set TR and slice timing related info before re-orient
[h, nii.hdr] = sliceTiming(h, nii.hdr);
nii.hdr.xyzt_units = xyz_unit + nii.hdr.xyzt_units; % normally: mm (2) + sec (8)
s = h{1};

% set TaskName if present in filename (using bids labels convention)
if bids % parse filename: _task-label
    task = regexp(s.NiftiName, '(?<=_task-).*?(?=_)', 'match', 'once'); 
    if ~isempty(task), s.TaskName = task; end
end

% Store motion parameters for MoCo series
if ~isempty(csa_header(s, 'RBMoCoRot')) && nVol>1
    inc = numel(h) / nVol;
    s.RBMoCoTrans = zeros(nVol, 3);
    s.RBMoCoRot   = zeros(nVol, 3);
    for j = 1:nVol
        s.RBMoCoTrans(j,:) = csa_header(h{(j-1)*inc+1}, 'RBMoCoTrans');
        s.RBMoCoRot(j,:)   = csa_header(h{(j-1)*inc+1}, 'RBMoCoRot');
    end
end

% Store FrameReferenceTime: seen in Philips PET
if isfield(s, 'FrameReferenceTime') && nVol>1
    inc = numel(h) / nVol;
    vTime = zeros(1, nVol);
    dict = dicm_dict('', 'FrameReferenceTime');
    for j = 1:nVol
        s2 = dicm_hdr(h{(j-1)*inc+1}.Filename, dict);
        vTime(j) = tryGetField(s2, 'FrameReferenceTime', 0);
    end
    if vTime(1) > vTime(end) % could also re-read sorted h{i}{1}
        vTime = flip(vTime);
        nii.img = flip(nii.img, 4);
    end
    s.VolumeTiming = vTime / 1000; % ms to seconds
end

% dim_info byte: freq_dim, phase_dim, slice_dim low to high, each 2 bits
[phPos, iPhase] = phaseDirection(s); % phPos relative to image in FSL feat!
if     iPhase == 2, fps_bits = [1 4 16];
elseif iPhase == 1, fps_bits = [4 1 16]; 
else,               fps_bits = [0 0 16];
end

% Reorient if MRAcquisitionType==3D && nSL>1
% If FSL etc can read dim_info for STC, we can always reorient.
[~, perm] = sort(ixyz); % may permute 3 dimensions in this order
if strcmp(tryGetField(s, 'MRAcquisitionType', ''), '3D') && ...
        dim(3)>1 && (~isequal(perm, 1:3)) % skip if already XYZ order
    R(:, 1:3) = R(:, perm); % xform matrix after perm
    fps_bits = fps_bits(perm);
    ixyz = ixyz(perm); % 1:3 after perm
    dim = dim(perm);
    pixdim = pixdim(perm);
    nii.hdr.dim(2:4) = dim;
    nii.img = permute(nii.img, [perm 4:8]);
    if isfield(s, 'bvec'), s.bvec = s.bvec(:, perm); end
end
iSL = find(fps_bits==16);
iPhase = find(fps_bits==4); % axis index for phase_dim in re-oriented img

nii.hdr.dim_info = (1:3) * fps_bits'; % useful for EPI only
nii.hdr.pixdim(2:4) = pixdim; % voxel zize

flp = R(ixyz+[0 3 6])<0; % flip an axis if true
d = det(R(:,1:3)) * prod(1-flp*2); % det after all 3 axis positive
if (d>0 && pf.lefthand) || (d<0 && ~pf.lefthand)
    flp(1) = ~flp(1); % left or right storage
end
rotM = diag([1-flp*2 1]); % 1 or -1 on diagnal
rotM(1:3, 4) = (dim-1) .* flp; % 0 or dim-1
R = R / rotM; % xform matrix after flip
for k = 1:3, if flp(k), nii.img = flip(nii.img, k); end; end
if flp(iPhase), phPos = ~phPos; end
if isfield(s, 'bvec'), s.bvec(:, flp) = -s.bvec(:, flp); end
if flp(iSL) && isfield(s, 'SliceTiming') % slices flipped
    s.SliceTiming = flip(s.SliceTiming);
    sc = nii.hdr.slice_code;
    if sc>0, nii.hdr.slice_code = sc+mod(sc,2)*2-1; end % 1<->2, 3<->4, 5<->6
end

% sform
frmCode = all(isfield(s, {'ImageOrientationPatient' 'ImagePositionPatient'}));
frmCode = tryGetField(s, 'TemplateSpace', frmCode);
nii.hdr.sform_code = frmCode; % 1: SCANNER_ANAT
nii.hdr.srow_x = R(1,:);
nii.hdr.srow_y = R(2,:);
nii.hdr.srow_z = R(3,:);

R0 = normc(R(:, 1:3));
sNorm = null(R0(:, setdiff(1:3, iSL))');
if sign(sNorm(ixyz(iSL))) ~= sign(R(ixyz(iSL),iSL)), sNorm = -sNorm; end
shear = norm(R0(:,iSL)-sNorm) > 0.01;
R0(:,iSL) = sNorm;

% qform
nii.hdr.qform_code = frmCode;
nii.hdr.qoffset_x = R(1,4);
nii.hdr.qoffset_y = R(2,4);
nii.hdr.qoffset_z = R(3,4);
[q, nii.hdr.pixdim(1)] = dcm2quat(R0); % 3x3 dir cos matrix to quaternion
nii.hdr.quatern_b = q(2);
nii.hdr.quatern_c = q(3);
nii.hdr.quatern_d = q(4);

if shear
    nii.hdr.hdrTilt = nii.hdr; % copy all hdr for tilt version
    nii.hdr.qform_code = 0; % disable qform
    gantry = tryGetField(s, 'GantryDetectorTilt', 0);
    nii.hdr.hdrTilt.pixdim(iSL+1) = norm(R(1:3, iSL)) * cosd(gantry);
    R(1:3, iSL) = sNorm * nii.hdr.hdrTilt.pixdim(iSL+1);
    nii.hdr.hdrTilt.srow_x = R(1,:);
    nii.hdr.hdrTilt.srow_y = R(2,:);
    nii.hdr.hdrTilt.srow_z = R(3,:);
end

% store some possibly useful info in descrip and other text fields
str = tryGetField(s, 'ImageComments', '');
if isType(s, '\MOCO\'), str = ''; end % useless for MoCo
foo = tryGetField(s, 'StudyComments');
if ~isempty(foo), str = [str ';' foo]; end
str = [str ';' sscanf(s.Manufacturer, '%s', 1)];
foo = tryGetField(s, 'ProtocolName');
if ~isempty(foo), str = [str ';' foo]; end
nii.hdr.aux_file = str; % char[24], info only
seq = asc_header(s, 'tSequenceFileName'); % like '%SiemensSeq%\ep2d_bold'
if isempty(seq)
    seq = tryGetField(s, 'ScanningSequence'); 
else % also add Siemens extra for json
    ind = strfind(seq, '\');
    if ~isempty(ind), seq = seq(ind(end)+1:end); end % like 'ep2d_bold'
    if ~isfield(s, 'ParallelReductionFactorInPlane')
        s.ParallelReductionFactorInPlane = asc_header(s, 'sPat.lAccelFactPE');
    end
    if ~isfield(s, 'ParallelAcquisitionTechnique')
        modes = {'none' 'GRAPPA' 'mSENSE' '' '' 'SliceAccel' '' ''};
        patMode = logical(bitget(asc_header(s, 'sPat.ucPATMode'), 1:8)); % guess
        s.ParallelAcquisitionTechnique = strjoin(modes(patMode), ';');
    end
end
if pf.save_patientName, nii.hdr.db_name = PatientName(s); end % char[18]
nii.hdr.intent_name = seq; % char[16], meaning of the data

foo = tryGetField(s, 'AcquisitionDateTime');
descrip = sprintf('time=%s;', foo(1:min(18,end))); 
if strncmpi(tryGetField(s, 'SequenceName', ''), '*fm2d2r', 3) % Siemens fieldmap
    TE0 = asc_header(s, 'alTE[0]')/1000; % s.EchoTime stores only 1 TE
    TE1 = asc_header(s, 'alTE[1]')/1000;
    dTE = abs(TE1 - TE0); % TE difference
    if ~isempty(dTE)
        descrip = sprintf('dTE=%.4g;%s', dTE, descrip);
        s.deltaTE = dTE;
    end
    if isType(s, '\P\')
        s.EchoTime = TE0; % overwrite EchoTime for json etc.
        s.SecondEchoTime = TE1;
    end
end
TE0 = tryGetField(s, 'EchoTime');
if ~isempty(TE0), descrip = sprintf('TE=%.4g;%s', TE0, descrip); end

% Get dwell time
if ~strcmp(tryGetField(s, 'MRAcquisitionType'), '3D') && ~isempty(iPhase)
    dwell = double(tryGetField(s, 'EffectiveEchoSpacing')) / 1000; % GE
    % http://www.spinozacentre.nl/wiki/index.php/NeuroWiki:Current_developments
    if isempty(dwell) % Philips
        wfs = tryGetField(s, 'WaterFatShift');
        epiFactor = tryGetField(s, 'EPIFactor');
        dwell = wfs ./ (434.215 * (double(epiFactor)+1)) * 1000;
    end
    if isempty(dwell) % Siemens
        hz = csa_header(s, 'BandwidthPerPixelPhaseEncode');
        dwell = 1000 ./ hz / dim(iPhase); % in ms
    end
    if isempty(dwell) % next is not accurate, so as last resort
        dur = csa_header(s, 'RealDwellTime') * 1e-6; % ns to ms
        dwell = dur * asc_header(s, 'sKSpace.lBaseResolution');
    end
    if isempty(dwell) && strncmpi(s.Manufacturer, 'UIH', 3)
        try dwell = s.AcquisitionDuration; % not confirmed yet
        catch
            try dwell = s.MRVFrameSequence.Item_1.AcquisitionDuration; end
        end
        if ~isempty(dwell), dwell = dwell / dim(iPhase); end
    end
    
    if ~isempty(dwell)
        s.EffectiveEPIEchoSpacing = dwell;
        % https://github.com/rordenlab/dcm2niix/issues/130
        readout = dwell * (dim(iPhase)- 1) / 1000; % since 170923
        s.ReadoutSeconds = readout;
        descrip = sprintf('readout=%.3g;dwell=%.3g;%s', readout, dwell, descrip);
    end
end

if ~isempty(iPhase)
    if isempty(phPos), pm = '?'; b67 = 0;
    elseif phPos,      pm = '';  b67 = 1;
    else,              pm = '-'; b67 = 2;
    end
    nii.hdr.dim_info = nii.hdr.dim_info + b67*64;
    axes = 'xyz'; % actually ijk
    phDir = [pm axes(iPhase)];
    s.UnwarpDirection = phDir;
    descrip = sprintf('phase=%s;%s', phDir, descrip);
end
nii.hdr.descrip = descrip; % char[80], drop from end if exceed

% slope and intercept: apply to img if no rounding error 
sclApplied = tryGetField(s, 'ApplyRescale', false);
if any(isfield(s, {'RescaleSlope' 'RescaleIntercept'})) && ~sclApplied
    slope = tryGetField(s, 'RescaleSlope', 1); 
    inter = tryGetField(s, 'RescaleIntercept', 0);
    if isfield(s, 'MRScaleSlope') % Philips: see PAR file for detail
        inter = inter / (slope * double(s.MRScaleSlope));
        slope = 1 / double(s.MRScaleSlope);
    end
    val = sort(double([max(nii.img(:)) min(nii.img(:))]) * slope + inter);
    dClass = class(nii.img);
    if isa(nii.img, 'float') || (mod(slope,1)==0 && mod(inter,1)==0 ... 
            && val(1)>=intmin(dClass) && val(2)<=intmax(dClass))
        nii.img = nii.img * slope + inter; % apply to img if no rounding
    else
        nii.hdr.scl_slope = slope;
        nii.hdr.scl_inter = inter;
    end
elseif sclApplied && isfield(s, 'MRScaleSlope')
    slope = tryGetField(s, 'RescaleSlope', 1) * s.MRScaleSlope; 
    nii.img = nii.img / slope;
end

if pf.scale_16bit && any(nii.hdr.datatype==[4 512]) % like dcm2niix
    if nii.hdr.datatype == 4 % int16
        scale = floor(32000 / double(max(abs(nii.img(:)))));
    else % datatype==512 % uint16
        scale = floor(64000 / double((max(nii.img(:)))));
    end
    nii.img = nii.img * scale;
    nii.hdr.scl_slope = nii.hdr.scl_slope / scale;
end
h{1} = s;

% Possible patient position: HFS/HFP/FFS/FFP / HFDR/HFDL/FFDR/FFDL
% Seems dicom takes care of this, and maybe nothing needs to do here.
% patientPos = tryGetField(s, 'PatientPosition', '');

flds = { % store for nii.ext and json
  'ConversionSoftware' 'SeriesNumber' 'SeriesDescription' 'ImageType' 'Modality' ...
  'AcquisitionDateTime' 'TaskName' 'bval' 'bvec' 'VolumeTiming' ...
  'ReadoutSeconds' 'DelayTimeInTR' 'SliceTiming' 'RepetitionTime' ...
  'ParallelReductionFactorInPlane' 'ParallelAcquisitionTechnique' ...
  'UnwarpDirection' 'EffectiveEPIEchoSpacing' 'EchoTime' 'deltaTE' 'EchoTimes' ...
  'SecondEchoTime' 'InversionTime' 'CardiacTriggerDelayTimes' ...
  'PatientName' 'PatientSex' 'PatientAge' 'PatientSize' 'PatientWeight' ...
  'PatientPosition' 'SliceThickness' 'FlipAngle' 'RBMoCoTrans' 'RBMoCoRot' ...
  'Manufacturer' 'SoftwareVersion' 'MRAcquisitionType' ...
  'InstitutionName' 'InstitutionAddress' 'DeviceSerialNumber' ...
  'ScanningSequence' 'SequenceVariant' 'ScanOptions' 'SequenceName' ...
  'TableHeight' 'DistanceSourceToPatient' 'DistanceSourceToDetector'};
if ~pf.save_patientName, flds(strcmp(flds, 'PatientName')) = []; end
if bids, flds(~cellfun('isempty', regexp(flds, 'Patient.*'))) = []; end
for i = 1:numel(flds)
    if ~isfield(s, flds{i}), continue; end
    nii.json.(flds{i}) = s.(flds{i});
end

%% Subfunction, reshape mosaic into volume, remove padded zeros
function vol = mos2vol(mos, nSL, isUIH)
nMos = ceil(sqrt(nSL)); % nMos x nMos tiles for Siemens, maybe nMos x nMos-1 UIH
[nr, nc, nv] = size(mos); % number of row, col and vol in mosaic
nr = nr / nMos; nc = nc / nMos; % number of row and col in slice
if isUIH && nMos*(nMos-1)>=nSL, nc = size(mos,2) / (nMos-1); end % one col less
vol = zeros([nr nc nSL nv], class(mos));
for i = 1:nSL
    r =    mod(i-1, nMos) * nr + (1:nr); % 2nd slice is tile(2,1)
    c = floor((i-1)/nMos) * nc + (1:nc);
    vol(:, :, i, :) = mos(r, c, :);
end

%% subfunction: set slice timing related info
function [h, hdr] = sliceTiming(h, hdr)
s = h{1};
TR = tryGetField(s, 'RepetitionTime'); % in ms
if isempty(TR), TR = tryGetField(s, 'TemporalResolution'); end
if isempty(TR), return; end
hdr.pixdim(5) = TR / 1000;
hdr.xyzt_units = 8; % seconds
if hdr.dim(5)<3 || tryGetField(s, 'isDTI', 0) || ...
        strncmp(tryGetField(s, 'MRAcquisitionType'), '3D', 2)
    return; % skip 3D, DTI, fieldmap, short EPI etc
end

nSL = hdr.dim(4);
delay = asc_header(s, 'lDelayTimeInTR', 0)/1000; % in ms now
if delay ~= 0, h{1}.DelayTimeInTR = delay; end
TA = TR - delay;

% Siemens mosaic
t = csa_header(s, 'MosaicRefAcqTimes'); % in ms
if ~isempty(t) && isfield(s, 'LastFile') && max(t)-min(t)>TA % MB wrong vol 1
    try t = mb_slicetiming(s, TA); end %#ok<*TRYNC>
end

if isempty(t) && strncmpi(s.Manufacturer, 'UIH', 3)
    t = zeros(nSL, 1);
    if isfield(s, 'MRVFrameSequence') % mosaic
        for j = 1:nSL
            item = sprintf('Item_%g', j);
            str = s.MRVFrameSequence.(item).AcquisitionDateTime;
            t(j) = datenum(str, 'yyyymmddHHMMSS.fff');
        end
    else
        dict = dicm_dict('', 'AcquisitionDateTime');
        for j = 1:nSL
            s1 = dicm_hdr(h{j}.Filename, dict);
            t(j) = datenum(s1.AcquisitionDateTime, 'yyyymmddHHMMSS.fff');
        end
    end
    t = (t - min(t)) * 24 * 3600 * 1000; % day to ms
end

if isempty(t) && any(isfield(s, {'TriggerTime' 'RTIA_timer'})) % GE
    ind = numel(h) + (1-nSL:0); % seen problem for 1st vol, so use last vol
    t = cellfun(@(c)tryGetField(c, 'TriggerTime', 0), h(ind));
    if all(diff(t)==0), t = cellfun(@(c)tryGetField(c, 'RTIA_timer', 0), h(ind)); end
    if all(diff(t)==0), t = []; 
    else
        t = t - min(t);
        ma = max(t) / TA;
        if ma>1, t = t / 10; % was ms*10, old dicom
        elseif ma<1e-3, t = t * 1000; % was sec, new dicom?
        end
    end
end

if isempty(t) && isfield(s, 'ProtocolDataBlock') && ...
        isfield(s.ProtocolDataBlock, 'SLICEORDER') % GE with invalid RTIA_timer
    SliceOrder = s.ProtocolDataBlock.SLICEORDER;
    t = (0:nSL-1)' * TA/nSL;
    if strcmp(SliceOrder, '1') % 0/1: sequential/interleaved based on limited data
        t([1:2:nSL 2:2:nSL]) = t;
    elseif ~strcmp(SliceOrder, '0')
        errorLog(['Unknown SLICEORDER (' SliceOrder ') for ' s.Filename]);
        return;
    end
end

% Siemens multiframe: read TimeAfterStart from last file
if isempty(t) && tryGetField(s, 'NumberOfFrames', 1)>1 &&  ...
        ~isempty(csa_header(s, 'TimeAfterStart'))
    % Use TimeAfterStart, not FrameAcquisitionDatetime. See
    % https://github.com/rordenlab/dcm2niix/issues/240#issuecomment-433036901
    % s2 = struct('FrameAcquisitionDatetime', {cell(nSL,1)});
    % s2 = dicm_hdr(h{end}, s2, 1:nSL); % avoid 1st volume
    % t = datenum(s2.FrameAcquisitionDatetime, 'yyyymmddHHMMSS.fff');
    % t = (t - min(t)) * 24 * 3600 * 1000; % day to ms
    s2 = struct('TimeAfterStart', nan(1, nSL));
    s2 = dicm_hdr(h{end}, s2, 1:nSL); % avoid 1st volume
    t = s2.TimeAfterStart; % in secs
    t = (t - min(t)) * 1000;
end

% Get slice timing for non-mosaic Siemens file. Could remove Manufacturer
% check, but GE/Philips AcquisitionTime seems useless
if isempty(t) && ~tryGetField(s, 'isMos', 0) && strncmpi(s.Manufacturer, 'SIEMENS', 7)
    dict = dicm_dict('', {'AcquisitionDateTime' 'AcquisitionDate' 'AcquisitionTime'});
    t = zeros(nSL, 1);
    for j = 1:nSL
        s1 = dicm_hdr(h{j}.Filename, dict);
        try str = s1.AcquisitionDateTime;
        catch
            try str = [s1.AcquisitionDate s1.AcquisitionTime];
            catch, t = []; break;
            end
        end
        t(j) = datenum(str, 'yyyymmddHHMMSS.fff');
    end
    t = (t - min(t)) * 24 * 3600 * 1000; % day to ms
end

if isempty(t) % non-mosaic Siemens: create 't' based on ucMode
    ucMode = asc_header(s, 'sSliceArray.ucMode'); % 1/2/4: Asc/Desc/Inter
    if isempty(ucMode), return; end
    t = (0:nSL-1)' * TA/nSL;
    if ucMode==2
        t = t(nSL:-1:1);
    elseif ucMode==4
        if mod(nSL,2), t([1:2:nSL 2:2:nSL]) = t;
        else, t([2:2:nSL 1:2:nSL]) = t;
        end
    end
    if asc_header(s, 'sSliceArray.ucImageNumb'), t = t(nSL:-1:1); end % rev-num
end

if numel(t)<2, return; end
t = t - min(t); % it may be relative to 1st slice

t1 = sort(t);
if t1(1)==t1(2) || (t1(end)>TA), sc = 0; % no useful info, or bad timing MB
elseif t1(1) == t1(2), sc = 0; t1 = unique(t1); % was 7 for MB but error in FS
elseif isequal(t, t1), sc = 1; % ascending
elseif isequal(t, flip(t1)), sc = 2; % descending
elseif t(1)<t(3) % ascending interleaved
    if t(1)<t(2), sc = 3; % odd slices first
    else, sc = 5; % Siemens even number of slices
    end
elseif t(1)>t(3) % descending interleaved
    if t(1)>t(2), sc = 4;
    else, sc = 6; % Siemens even number of slices
    end
else, sc = 0; % unlikely to reach
end

h{1}.SliceTiming = 0.5 - t/TR; % as for FSL custom timing
hdr.slice_code = sc;
hdr.slice_end = nSL-1; % 0-based, slice_start default to 0
hdr.slice_duration = min(diff(t1))/1000;

%% subfunction: extract bval & bvec, store in 1st header
function [h, nii] = get_dti_para(h, nii)
nDir = nii.hdr.dim(5);
if nDir<2, return; end
bval = nan(nDir, 1);
bvec = nan(nDir, 3);
s = h{1};
ref = 1; % not coded by Manufacturer, but by how we get bvec (since 190213).
% With this method, the code will get correct ref if bvec ref scheme changes 
% some day, e.g. if GE saves (0018,9089) in the future.
% ref = 0: IMG, UIH for now; PE='ROW" not tested 
% ref = 1: PCS, Siemens/Philips/lateCanon or unknown vendor, this is default
% ref = 2: FPS, Bruker for now (need to verify)
% ref = 3: FPS_GE, confusing signs
% ref = 4: PFS, CANON (ImageComments) by ChrisR
%  Since some dicom do not save bval or bvec for bval=0 case, it is better to
%  loop all directions to detect 'ref'.

nSL = nii.hdr.dim(4);
nFile =  numel(h);
if isfield(s, 'bvec_original') % from BV or PAR file
    bval = s.B_value;
    bvec = s.bvec_original;
    % ref = tryGetField(s, 'bvec_ref', 1); % not implemented yet
elseif isfield(s, 'PerFrameFunctionalGroupsSequence')
    if nFile== 1 % all vol in 1 file, for Philips/Bruker
        iDir = 1:nSL:nSL*nDir;
        if isfield(s, 'SortFrames'), iDir = s.SortFrames(iDir); end
        s2 = struct('B_value', bval', 'DiffusionGradientDirection', bvec', ...
            'MRDiffusionGradOrientation', bvec');
        s2 = dicm_hdr(s, s2, iDir); % call search_MF_val
        bval = s2.B_value';
        bvec = s2.DiffusionGradientDirection';
        if all(isnan(bvec(:)))
            bvec = s2.MRDiffusionGradOrientation';
            if ~all(isnan(bvec(:))), ref = 0; end % UIH
        end
        if isfield(s, 'Private_0177_1100') && all(isnan(bvec(:))) % Bruker
            str = char(s.Private_0177_1100');
            expr = 'DwGradVec\s*=\s*\(\s*(\d+),\s*(\d+)\s*\)\s+'; % DwDir incomplete            
            [C, ind] = regexp(str, expr, 'tokens', 'end', 'once');
            if isequal(str2double(C), [nDir 3])
                ref = 2;
                bvec = sscanf(str(ind:end), '%f', nDir*3);
                bvec = normc(reshape(bvec, 3, []))';
                [~, i] = sort(iDir); bvec(i,:) = bvec;
            end
        end
    elseif nDir == nFile % 1 vol per file, e.g. Siemens/UIH
        for i = 1:nDir
            bval(i) = MF_val('B_value', h{i}, 1);
            a = MF_val('DiffusionGradientDirection', h{i}, 1);
            if isempty(a)
                a = MF_val('MRDiffusionGradOrientation', h{i}, 1);
                if ~isempty(a), ref = 0; end % UIH
            end
            if ~isempty(a), bvec(i,:) = a; end
        end
    else
        errorLog('Number of files and diffusion directions not match');
        return;
    end
elseif nFile>1 % multiple files: order already in slices then volumes
    dict = dicm_dict(s.Manufacturer, {'B_value' 'B_factor' 'SlopInt_6_9' ...
       'DiffusionDirectionX' 'DiffusionDirectionY' 'DiffusionDirectionZ' ...
       'MRDiffusionGradOrientation' 'ImageComments'});
    iDir = (0:nDir-1) * nFile/nDir + 1; % could be mosaic or multiframe
    for j = 1:nDir % no bval/bvec for B0 volume
        s2 = h{iDir(j)};
        val = tryGetField(s2, 'B_value');
        if val == 0, continue; end
        vec = tryGetField(s2, 'DiffusionGradientDirection'); % Siemens/Philips
        if isempty(val) || isempty(vec) % GE/UIH/CANON
            s2 = dicm_hdr(s2.Filename, dict);
        end
        
        if isempty(val), val = tryGetField(s2, 'B_factor'); end % old Philips
        if isempty(val) && isfield(s2, 'SlopInt_6_9') % GE
            val = mod(s2.SlopInt_6_9(1), 100000);
        end
        if isempty(val), val = 0; end % may be B_value=0
        bval(j) = val;
        
        if isempty(vec)
            vec = tryGetField(s2, 'MRDiffusionGradOrientation');
            if ref==1 && ~isempty(vec), ref = 0; end % UIH
        end
        if isempty(vec) % CANON
            vec = sscanf(tryGetField(s2, 'ImageComments', ''), 'b=%*g(%g,%g,%g)');
            if ref==1 && ~isempty(vec), ref = 4; end
        end
        if isempty(vec) % GE, old Philips
            vec(1) = tryGetField(s2, 'DiffusionDirectionX', 0);
            vec(2) = tryGetField(s2, 'DiffusionDirectionY', 0);
            vec(3) = tryGetField(s2, 'DiffusionDirectionZ', 0);
            if ref==1 && strncmpi(s.Manufacturer, 'GE', 2), ref = 3; end
        end
        bvec(j,:) = vec;
    end
end

if all(isnan(bval)) && all(isnan(bvec(:)))
    errorLog(['Failed to get DTI parameters: ' s.NiftiName]);
    return; 
end
bval(isnan(bval)) = 0;
bvec(isnan(bvec)) = 0;

if strncmpi(s.Manufacturer, 'Philips', 7)
    % Remove computed ADC: it may not be the last vol
    ind = find(bval>1e-4 & sum(abs(bvec),2)<1e-4);
    if ~isempty(ind) % DiffusionDirectionality: 'ISOTROPIC'
        bval(ind) = [];
        bvec(ind,:) = [];
        nii.img(:,:,:,ind) = [];
        nii.hdr.dim(5) = nDir - numel(ind);
    end
end

h{1}.bvec_original = bvec; % original from dicom

% http://wiki.na-mic.org/Wiki/index.php/NAMIC_Wiki:DTI:DICOM_for_DWI_and_DTI
[ixyz, R] = xform_mat(s, nii.hdr.dim(2:4)); % R takes care of slice dir
PE = tryGetField(s, 'InPlanePhaseEncodingDirection', '');
if ref == 1 % PCS: Siemens/Philips
    R = normc(R(:, 1:3));
    bvec = bvec * R; % dicom plane to image plane
elseif ref == 2 % FPS: Bruker in Freq/Phase/Slice reference
    if strcmp(PE, 'ROW'), bvec = bvec(:, [2 1 3]); end
elseif ref == 3 % FPS: GE in Freq/Phase/Slice reference
    if strcmp(PE, 'ROW')
        bvec = bvec(:, [2 1 3]);
        bvec(:, 2) = -bvec(:, 2); % because of transpose?
        if ixyz(3)<3
            errorLog(sprintf(['%s: bvec sign for non-axial acquisition with' ...
             ' ROW phase direction not tested.\n Please check ' ...
             'the result and report problem to author.'], s.NiftiName));
        end
    end
    flp = R(ixyz+[0 3 6]) < 0; % negative sign
    flp(3) = ~flp(3); % GE slice dir opposite to LPS for all sag/cor/tra
    if ixyz(3)==1, flp(1) = ~flp(1); end % Sag slice: don't know why
    bvec(:, flp) = -bvec(:, flp);
elseif ref == 4 % CANON
    if strcmp(PE, 'COL') % && is_PA % no PE polarity till 200913
        bvec(:, 1:2) = -bvec(:, [2 1]);
    end
end

% bval may need to be scaled by norm(bvec)
% https://mrtrix.readthedocs.io/en/latest/concepts/dw_scheme.html
nm = sum(bvec .^ 2, 2);
if any(nm>0.01 & abs(nm-1)>0.01) % this check may not be necessary
    h{1}.bval_original = bval; % before scaling
    bval = bval .* nm;
    nm(nm<1e-4) = 1; % remove zeros after correcting bval
    bvec = bsxfun(@rdivide, bvec, sqrt(nm));
end

h{1}.bval = bval; % store all into header of 1st file
h{1}.bvec = bvec; % computed bvec in image ref

%% subfunction: save bval & bvec files
function save_dti_para(s, fname)
if ~isfield(s, 'bvec') || all(s.bvec(:)==0), return; end
if isfield(s, 'bval')
    fid = fopen(strcat(fname, '.bval'), 'w');
    fprintf(fid, '%.5g ', s.bval); % one row
    fclose(fid);
end

str = repmat('%.6f ', 1, size(s.bvec,1));
fid = fopen(strcat(fname, '.bvec'), 'w');
fprintf(fid, [str '\n'], s.bvec); % 3 rows by # direction cols
fclose(fid);

%% Subfunction, return a parameter from CSA Image/Series header
function val = csa_header(s, key)
fld = 'CSAImageHeaderInfo';
if isfield(s, fld) && isfield(s.(fld), key), val = s.(fld).(key); return; end
if isfield(s, key), val = s.(key); return; end % general tag: 2nd choice
try val = s.PerFrameFunctionalGroupsSequence.Item_1.(fld).Item_1.(key); return; end
fld = 'CSASeriesHeaderInfo';
if isfield(s, fld) && isfield(s.(fld), key), val = s.(fld).(key); return; end
val = [];

%% Subfunction, Convert 3x3 direction cosine matrix to quaternion
% Simplied from Quaternions by Przemyslaw Baranski 
function [q, proper] = dcm2quat(R)
% [q, proper] = dcm2quat(R)
% Retrun quaternion abcd from normalized matrix R (3x3)
proper = sign(det(R));
if proper<0, R(:,3) = -R(:,3); end

q = sqrt([1 1 1; 1 -1 -1; -1 1 -1; -1 -1 1] * diag(R) + 1) / 2;
if ~isreal(q(1)), q(1) = 0; end % if trace(R)+1<0, zero it
[mx, ind] = max(q);
mx = mx * 4;

if ind == 1
    q(2) = (R(3,2) - R(2,3)) /mx;
    q(3) = (R(1,3) - R(3,1)) /mx;
    q(4) = (R(2,1) - R(1,2)) /mx;
elseif ind ==  2
    q(1) = (R(3,2) - R(2,3)) /mx;
    q(3) = (R(1,2) + R(2,1)) /mx;
    q(4) = (R(3,1) + R(1,3)) /mx;
elseif ind == 3
    q(1) = (R(1,3) - R(3,1)) /mx;
    q(2) = (R(1,2) + R(2,1)) /mx;
    q(4) = (R(2,3) + R(3,2)) /mx;
elseif ind == 4
    q(1) = (R(2,1) - R(1,2)) /mx;
    q(2) = (R(3,1) + R(1,3)) /mx;
    q(3) = (R(2,3) + R(3,2)) /mx;
end
if q(1)<0, q = -q; end % as MRICron

%% Subfunction: get dicom xform matrix and related info
function [ixyz, R, pixdim, xyz_unit] = xform_mat(s, dim)
if nargin<2
    dim = double([s.Columns s.Rows tryGetField(s, 'LocationsInAcquisition', 0)]);
    nSL = nMosaic(s);
    if ~isempty(nSL) && nSL>0, dim = [dim(1:2)/ceil(sqrt(nSL)) nSL]; end
end
haveIOP = isfield(s, 'ImageOrientationPatient');
if haveIOP, R = reshape(s.ImageOrientationPatient, 3, 2);
else, R = [1 0 0; 0 1 0]';
end
R(:,3) = cross(R(:,1), R(:,2)); % right handed, but sign may be wrong
a = abs(R);
[~, ixyz] = max(a); % orientation info: perm of 1:3
if ixyz(2) == ixyz(1), a(ixyz(2),2) = 0; [~, ixyz(2)] = max(a(:,2)); end
if any(ixyz(3) == ixyz(1:2)), ixyz(3) = setdiff(1:3, ixyz(1:2)); end
if nargout<2, return; end
iSL = ixyz(3); % 1/2/3 for Sag/Cor/Tra slice
signSL = sign(R(iSL, 3));

try 
    pixdim = s.PixelSpacing([2 1]);
    xyz_unit = 2; % mm
catch
    pixdim = [1 1]'; % fake
    xyz_unit = 0; % no unit information
end
thk = tryGetField(s, 'SpacingBetweenSlices');
if isempty(thk), thk = tryGetField(s, 'SliceThickness', pixdim(1)); end
pixdim = [pixdim; thk];
haveIPP = isfield(s, 'ImagePositionPatient');
if haveIPP, ipp = s.ImagePositionPatient; else, ipp = -(dim'.* pixdim)/2; end
% Next is almost dicom xform matrix, except mosaic trans and unsure slice_dir
R = [R * diag(pixdim) ipp];

if dim(3)<2, return; end % don't care direction for single slice

if s.Columns>dim(1) && ~strncmpi(s.Manufacturer, 'UIH', 3) % Siemens mosaic
    R(:,4) = R * [ceil(sqrt(dim(3))-1)*dim(1:2)/2 0 1]'; % real slice location
    vec = csa_header(s, 'SliceNormalVector'); % mosaic has this
    if ~isempty(vec) % exist for all tested data
        if sign(vec(iSL)) ~= signSL, R(:,3) = -R(:,3); end
        return;
    end
elseif isfield(s, 'LastFile') && isfield(s.LastFile, 'ImagePositionPatient')
    R(:, 3) = (s.LastFile.ImagePositionPatient - R(:,4)) / (dim(3)-1);
    thk = norm(R(:,3)); % override slice thickness if it is off
    if abs(pixdim(3)-thk)/thk > 0.01, pixdim(3) = thk; end
    return; % almost all non-mosaic images return from here
end

% Rest of the code is almost unreachable
if strncmp(s.Manufacturer, 'SIEMENS', 7) % both mosaic and regular
    ori = {'Sag' 'Cor' 'Tra'}; ori = ori{iSL};
    sNormal = asc_header(s, ['sSliceArray.asSlice[0].sNormal.d' ori]);
    if asc_header(s, ['sSliceArray.ucImageNumb' ori]), sNormal = -sNormal; end
    if sign(sNormal) ~= signSL, R(:,3) = -R(:,3); end
    if ~isempty(sNormal), return; end
end

pos = []; % volume center we try to retrieve
if isfield(s, 'LastScanLoc') && isfield(s, 'FirstScanLocation') % GE
    pos = (s.LastScanLoc + s.FirstScanLocation) / 2; % mid-slice center
    if iSL<3, pos = -pos; end % RAS convention!
    pos = pos - R(iSL, 1:2) * (dim(1:2)'-1)/2; % mid-slice location
end

if isempty(pos) && isfield(s, 'Stack') % Philips
    ori = {'RL' 'AP' 'FH'}; ori = ori{iSL};
    pos = tryGetField(s.Stack.Item_1, ['MRStackOffcentre' ori]);
    pos = pos - R(iSL, 1:2) * dim(1:2)'/2; % mid-slice location
end

if isempty(pos) % keep right-handed, and warn user
    if haveIPP && haveIOP
        errorLog(['Please check whether slices are flipped: ' s.NiftiName]);
    else
        errorLog(['No orientation/location information found in ' s.Filename]);
    end
elseif sign(pos-R(iSL,4)) ~= signSL % same direction?
    R(:,3) = -R(:,3);
end

%% Subfunction: get a parameter in CSA series ASC header: MrPhoenixProtocol
function val = asc_header(s, key, dft)
if nargin>2, val = dft; else, val = []; end
csa = 'CSASeriesHeaderInfo';
if ~isfield(s, csa) % in case of multiframe
    try s.(csa) = s.SharedFunctionalGroupsSequence.Item_1.(csa).Item_1; end
end
if isfield(s, 'Private_0029_1020') && isa(s.Private_0029_1020, 'uint8')
    str = char(s.Private_0029_1020(:)');
    str = regexp(str, 'ASCCONV BEGIN(.*)ASCCONV END', 'tokens', 'once');
    if isempty(str), return; end
    str = str{1};
elseif isfield(s, 'MrPhoenixProtocol') % X20A
    str = s.MrPhoenixProtocol;
elseif ~isfield(s, csa), return; % non-siemens
elseif isfield(s.(csa), 'MrPhoenixProtocol') % most Siemens dicom
    str = s.(csa).MrPhoenixProtocol;
elseif isfield(s.(csa), 'MrProtocol') % older version dicom
    str = s.(csa).MrProtocol;
else, return;
end

% tSequenceFileName  = ""%SiemensSeq%\gre_field_mapping""
expr = ['\n' regexptranslate('escape', key) '\s*=\s*(.*?)\n'];
str = regexp(str, expr, 'tokens', 'once');
if isempty(str), return; end
str = strtrim(str{1});

if strncmp(str, '""', 2) % str parameter
    val = str(3:end-2);
elseif strncmp(str, '"', 1) % str parameter for version like 2004A
    val = str(2:end-1);
elseif strncmp(str, '0x', 2) % hex parameter, convert to decimal
    val = sscanf(str(3:end), '%x', 1);
else % decimal
    val = sscanf(str, '%g', 1);
end

%% Subfunction: return matlab decompress command if the file is compressed
function func = compress_func(fname)
func = '';
if any(regexpi(fname, '\.mgz$')), return; end
fid = fopen(fname);
if fid<0, return; end
sig = fread(fid, 2, '*uint8')';
fclose(fid);
if isequal(sig, [80 75]) % zip file
    func = 'unzip';
elseif isequal(sig, [31 139]) % gz, tgz, tar
    func = 'untar';
end
% ! "c:\program Files (x86)\7-Zip\7z.exe" x -y -oF:\tmp\ F:\zip\3047ZL.zip

%% Subfuction: for GUI callbacks
function gui_callback(h, evt, cmd, fh)
hs = guidata(fh);
drawnow;
switch cmd
    case 'do_convert'
        src = get(fh, 'UserData');
        dst = hs.dst.Text;
        if isempty(src) || isempty(dst)
            str = 'Source folder/file(s) and Result folder must be specified';
            errordlg(str, 'Error Dialog');
            return;
        end
        rstFmt = (get(hs.rstFmt, 'Value') - 1) * 2; % 0 or 2
        if rstFmt == 4
            if verLessThanOctave
                fprintf('BIDS conversion is easier with MATLAB R2018a or more.\n');
            end
            if get(hs.gzip,  'Value')
                rstFmt = 'bids';
            else
                rstFmt = 'bidsnii';
            end % 1 or 3
        else
            if get(hs.gzip,  'Value'), rstFmt = rstFmt + 1; end % 1 or 3
            if get(hs.rst3D, 'Value'), rstFmt = rstFmt + 4; end % 4 to 7
        end
        set(h, 'Enable', 'off', 'string', 'Conversion in progress');
        clnObj = onCleanup(@()set(h, 'Enable', 'on', 'String', 'Start conversion')); 
        drawnow;
        dicm2nii(src, dst, rstFmt);
        
        % save parameters if last conversion succeed
        pf = getpref('dicm2nii_gui_para');
        pf.rstFmt = get(hs.rstFmt, 'Value');
        pf.rst3D = get(hs.rst3D, 'Value');
        pf.gzip = get(hs.gzip, 'Value');
        pf.src = hs.src.Text;
        ind = strfind(pf.src, '{');
        if ~isempty(ind), pf.src = strtrim(pf.src(1:ind-1)); end
        pf.dst = hs.dst.Text;
        setpref('dicm2nii_gui_para', fieldnames(pf), struct2cell(pf));
    case 'dstDialog'
        folder = hs.dst.Text; % current folder
        if ~isfolder(folder), folder = hs.src.Text; end
        if ~isfolder(folder), folder = fileparts(folder); end
        if ~isfolder(folder), folder = pwd; end
        dst = uigetdir(folder, 'Select a folder for result files');
        if isnumeric(dst), return; end
        hs.dst.Text = dst;
    case 'srcDir'
        folder = hs.src.Text; % initial folder
        if ~isfolder(folder), folder = fileparts(folder); end
        if ~isfolder(folder), folder = pwd; end
        src = jFileChooser(folder, 'Select folders/files to convert');
        if isnumeric(src), return; end
        set(hs.fig, 'UserData', src);
        txt = src{1};
        if numel(src) > 1,  txt = [txt ' {and more}']; end 
        hs.src.Text = txt;
    case 'set_src'
        str = hs.src.Text;
        ind = strfind(str, '{');
        if ~isempty(ind), return; end % no check with multiple files
        if ~isempty(str) && ~exist(str, 'file')
            val = dir(str);
            folder = fileparts(str);
            if isempty(val)
                val = get(fh, 'UserData');
                if iscellstr(val)
                    val = [fileparts(val{1}), sprintf(' {%g files}', numel(val))];
                end
                if ~isempty(val), hs.src.Text = val; end
                errordlg('Invalid input', 'Error Dialog');
                return;
            end
            str = {val.name};
            str = strcat(folder, filesep, str);
        end
        set(fh, 'UserData', str);
    case 'set_dst'
        str = hs.dst.Text;
        if isempty(str), return; end
        if ~exist(str, 'file') && ~mkdir(str)
            hs.dst.Text = '';
            errordlg(['Invalid folder name ''' str ''''], 'Error Dialog');
            return;
        end
    case 'SPMStyle' % turn off compression
        if get(hs.rst3D, 'Value'), set(hs.gzip, 'Value', 0); end
    case 'about'
        item = get(hs.about, 'Value');
        if item == 1 % about
            str = sprintf(['dicm2nii.m by Xiangrui Li\n\n' ...
                'Feedback to: xiangrui.li@gmail.com\n\n' ...
                'Last updated on %s\n'], getVersion);
            helpdlg(str, 'About dicm2nii')
        elseif item == 2 % license
            try
                str = fileread([fileparts(mfilename('fullpath')) '/LICENSE']);
            catch
                str = 'license.txt file not found';
            end
            helpdlg(strtrim(str), 'License')
        elseif item == 3
            doc dicm2nii;
        elseif item == 4
            checkUpdate(mfilename);
        elseif item == 5
            web('www.sciencedirect.com/science/article/pii/S0165027016300073', '-browser');
        end
        set(hs.about, 'Value', 1);
    case 'drop_src' % Java drop source
        try
            if strcmp(evt.DropType, 'file')
                n = numel(evt.Data);
                if n == 1
                    hs.src.Text = evt.Data{1};
                    set(hs.fig, 'UserData', evt.Data{1});
                else
                    hs.src.Text = sprintf('%s {%g files}', ...
                        fileparts(evt.Data{1}), n);
                    set(fh, 'UserData', evt.Data);
                end
            else % string
                hs.src.Text = strtrim(evt.Data);
                gui_callback([], [], 'set_src', fh);
            end
        catch me
            errordlg(me.message);
        end
    case 'drop_dst' % Java drop dst
        try
            if strcmp(evt.DropType, 'file')
                nam = evt.Data{1};
                if ~isfolder(nam), nam = fileparts(nam); end
                hs.dst.Text = nam;
            else
                hs.dst.Text = strtrim(evt.Data);
                gui_callback([], [], 'set_dst', fh);
            end
        catch me
            errordlg(me.message);
        end
    otherwise
        create_gui;
end

%% Subfuction: create GUI or bring it to front if exists
function create_gui
fh = figure('dicm' * 256.^(0:3)'); % arbitury integer
if strcmp('dicm2nii_fig', get(fh, 'Tag')), return; end

scrSz = get(0, 'ScreenSize');
fSz = 9; % + ~(ispc || ismac);
clr = [1 1 1]*206/256;
clrButton = [1 1 1]*216/256;
cb = @(cmd) {@gui_callback cmd fh}; % callback shortcut
uitxt = @(txt,pos) uicontrol('Style', 'text', 'Position', pos, 'FontSize', fSz, ...
    'HorizontalAlignment', 'left', 'String', txt, 'BackgroundColor', clr);
getpf = @(p,dft)getpref('dicm2nii_gui_para', p, dft);
chkbox = @(parent,val,str,cbk,tip) uicontrol(parent, 'Style', 'checkbox', ...
    'FontSize', fSz, 'HorizontalAlignment', 'left', 'BackgroundColor', clr, ...
    'Value', val, 'String', str, 'Callback', cbk, 'TooltipString', tip);

set(fh, 'Toolbar', 'none', 'Menubar', 'none', 'Resize', 'off', 'Color', clr, ...
    'Tag', 'dicm2nii_fig', 'Position', [200 scrSz(4)-600 420 300], 'Visible', 'off', ...
    'Name', 'dicm2nii - DICOM to NIfTI Converter', 'NumberTitle', 'off');

uitxt('Move mouse onto button, text box or check box for help', [8 274 400 16]);
str = sprintf(['Browse convertible files or folders (can have subfolders) ' ...
    'containing files.\nConvertible files can be dicom, Philips PAR,' ...
    ' AFNI HEAD, BrainVoyager files, or a zip file containing those files']);
uicontrol('Style', 'Pushbutton', 'Position', [6 235 112 24], ...
    'FontSize', fSz, 'String', 'DICOM folder/files', 'Background', clrButton, ...
    'TooltipString', str, 'Callback', cb('srcDir'));

jSrc = javaObjectEDT('javax.swing.JTextField');
warning('off', 'MATLAB:ui:javacomponent:FunctionToBeRemoved');
hs.src = javacomponent(jSrc, [118 234 294 24], fh); %#ok<*JAVCM>
hs.src.FocusLostCallback = cb('set_src');
hs.src.Text = getpf('src', pwd);
% hs.src.ActionPerformedCallback = cb('set_src'); % fire when pressing ENTER
hs.src.ToolTipText = ['<html>This is the source folder or file(s). You can<br>' ...
    'Type the source folder name into the box, or<br>' ...
    'Click DICOM folder/files button to browse, or<br>' ...
    'Drag and drop a folder or file(s) into the box'];

uicontrol('Style', 'Pushbutton', 'Position', [6 199 112 24], ...
    'FontSize', fSz, 'String', 'Result folder', 'Background', clrButton, ...
    'TooltipString', 'Browse result folder', 'Callback', cb('dstDialog'));
jDst = javaObjectEDT('javax.swing.JTextField');
hs.dst = javacomponent(jDst, [118 198 294 24], fh);
hs.dst.FocusLostCallback = cb('set_dst');
hs.dst.Text = getpf('dst', pwd);
hs.dst.ToolTipText = ['<html>This is the result folder name. You can<br>' ...
    'Type the folder name into the box, or<br>' ...
    'Click Result folder button to set the value, or<br>' ...
    'Drag and drop a folder into the box'];

uitxt('Output format', [8 166 82 16]);
hs.rstFmt = uicontrol('Style', 'popup', 'Background', 'white', 'FontSize', fSz, ...
    'Value', getpf('rstFmt',1), 'Position', [92 162 82 24], ...
    'String', {' .nii' ' .hdr/.img' ' BIDS (http://bids.neuroimaging.io)'}, ...
    'TooltipString', 'Choose output file format');

hs.gzip = chkbox(fh, getpf('gzip',true), 'Compress', '', 'Compress into .gz files');
sz = get(hs.gzip, 'Extent'); set(hs.gzip, 'Position', [220 166 sz(3)+24 sz(4)]);

hs.rst3D = chkbox(fh, getpf('rst3D',false), 'SPM 3D', cb('SPMStyle'), ...
    'Save one file for each volume (SPM style)');
sz = get(hs.rst3D, 'Extent'); set(hs.rst3D, 'Position', [330 166 sz(3)+24 sz(4)]);
           
hs.convert = uicontrol('Style', 'pushbutton', 'Position', [104 8 200 30], ...
    'FontSize', fSz, 'String', 'Start conversion', ...
    'Background', clrButton, 'Callback', cb('do_convert'), ...
    'TooltipString', 'Dicom source and Result folder needed before start');

hs.about = uicontrol('Style', 'popup',  'String', ...
    {'About' 'License' 'Help text' 'Check update' 'A paper about conversion'}, ...
    'Position', [326 12 88 20], 'Callback', cb('about'));

ph = uipanel(fh, 'Units', 'Pixels', 'Position', [4 50 410 102], 'FontSize', fSz, ...
    'BackgroundColor', clr, 'Title', 'Preferences (also apply to command line and future sessions)');
setpf = @(p)['setpref(''dicm2nii_gui_para'',''' p ''',get(gcbo,''Value''));'];

p = 'lefthand';
h = chkbox(ph, getpf(p,true), 'Left-hand storage', setpf(p), ...
    'Left hand storage works well for FSL, and likely doesn''t matter for others');
sz = get(h, 'Extent'); set(h, 'Position', [4 60 sz(3)+24 sz(4)]);

p = 'save_patientName';
h = chkbox(ph, getpf(p,true), 'Store PatientName', setpf(p), ...
    'Store PatientName in NIfTI hdr, ext and json');
sz = get(h, 'Extent'); set(h, 'Position', [180 60 sz(3)+24 sz(4)]);

p = 'use_parfor';
h = chkbox(ph, getpf(p,true), 'Use parfor if needed', setpf(p), ...
    'Converter will start parallel tool if necessary');
sz = get(h, 'Extent'); set(h, 'Position', [4 36 sz(3)+24 sz(4)]);

p = 'use_seriesUID';
h = chkbox(ph, getpf(p,true), 'Use SeriesInstanceUID if exists', setpf(p), ...
    'Only uncheck this if SeriesInstanceUID is messed up by some third party archive software');
sz = get(h, 'Extent'); set(h, 'Position', [180 36 sz(3)+24 sz(4)]);

p = 'save_json';
h = chkbox(ph, getpf(p,false), 'Save json file', setpf(p), ...
    'Save json file for BIDS (http://bids.neuroimaging.io/)');
sz = get(h, 'Extent'); set(h, 'Position', [4 12 sz(3)+24 sz(4)]);

p = 'scale_16bit';
h = chkbox(ph, getpf(p,false), 'Use 16-bit scaling', setpf(p), ...
    'Losslessly scale 16-bit integers to use dynamic range');
sz = get(h, 'Extent'); set(h, 'Position', [180 12 sz(3)+24 sz(4)]);

hs.fig = fh;
guidata(fh, hs); % store handles
drawnow; set(fh, 'Visible', 'on', 'HandleVisibility', 'callback');

try % java_dnd is based on dndcontrol by Maarten van der Seijs
    java_dnd(jSrc, cb('drop_src'));
    java_dnd(jDst, cb('drop_dst'));
catch me
    fprintf(2, '%s\n', me.message);
end

gui_callback([], [], 'set_src', fh);

%% subfunction: return phase positive and phase axis (1/2) in image reference
function [phPos, iPhase] = phaseDirection(s)
iPhase = [];
fld = 'InPlanePhaseEncodingDirection';
if isfield(s, fld)
    if     strncmpi(s.(fld), 'COL', 3), iPhase = 2; % based on dicm_img(s,0)
    elseif strncmpi(s.(fld), 'ROW', 3), iPhase = 1;
    else, errorLog(['Unknown ' fld ' for ' s.Filename ': ' s.(fld)]);
    end
end

phPos = csa_header(s, 'PhaseEncodingDirectionPositive'); % SIEMENS, image ref
if ~isempty(phPos), return; end
if isfield(s, 'RectilinearPhaseEncodeReordering') % GE
    phPos = ~isempty(regexpi(s.RectilinearPhaseEncodeReordering, 'REVERSE', 'once'));
    return;
elseif isfield(s, 'UserDefineData') % earlier GE
    % https://github.com/rordenlab/dcm2niix/issues/163
    try
    b = s.UserDefineData;
    i = typecast(b(25:26), 'uint16'); % hdr_offset
    v = typecast(b(i+1:i+4), 'single'); % 5.0 to 40.0
    if v >= 25.002, i = i + 76; flag2_off = 777; else, flag2_off = 917; end
    sliceOrderFlag = bitget(b(i+flag2_off), 2);
    phasePolarFlag = bitget(b(i+49), 3);
    phPos = ~xor(phasePolarFlag, sliceOrderFlag);
    end
    return;
end

if isfield(s, 'Stack') % Philips
    try d = s.Stack.Item_1.MRStackPreparationDirection(1); catch, return; end
elseif all(isfield(s, {'PEDirectionFlipped' 'PEDirectionDisplayed'})) % UIH
    % https://github.com/rordenlab/dcm2niix/issues/410
    d = s.PEDirectionDisplayed;
    if s.PEDirectionFlipped, d = d(end); else, d = d(1); end
elseif isfield(s, 'Private_0177_1100') % Bruker
    expr ='(?<=\<\+?)[LRAPSI]{1}(?=;\s*phase\>)'; % <+P;phase> or <P;phase>
    d = regexp(char(s.Private_0177_1100'), expr, 'match', 'once');
    id = regexp('LRAPSI', d);
    id = id + mod(id,2)*2-1;
    str = 'LRAPFH'; d = str(id);
else % unknown Manufacturer
    return;
end
try R = reshape(s.ImageOrientationPatient, 3, 2); catch, return; end
[~, ixy] = max(abs(R)); % like [1 2]
if isempty(iPhase) % if no InPlanePhaseEncodingDirection
    iPhase = strfind('RLAPFH', d);
    iPhase = ceil(iPhase/2); % 1/2/3 for RL/AP/FH
    iPhase = find(ixy==iPhase); % now 1 or 2
end
if     any(d == 'LPH'), phPos = false; % in dicom ref
elseif any(d == 'RAF'), phPos = true;
end
if R(ixy(iPhase), iPhase)<0, phPos = ~phPos; end % tricky! in image ref
if strncmpi(s.Manufacturer, 'Philips', 7), phPos = []; end % invalidate for now

%% subfunction: extract useful fields for multiframe dicom
function s = multiFrameFields(s)
if isfield(s, 'MRVFrameSequence') % not real multi-frame dicom
    try
    s.ImagePositionPatient = s.MRVFrameSequence.Item_1.ImagePositionPatient;
    s.AcquisitionDateTime = s.MRVFrameSequence.Item_1.AcquisitionDateTime;
    item = sprintf('Item_%g', s.LocationsInAcquisition);
    s.LastFile.ImagePositionPatient = s.MRVFrameSequence.(item).ImagePositionPatient;
    end
    return;
end
pffgs = 'PerFrameFunctionalGroupsSequence';
sfgs = 'SharedFunctionalGroupsSequence';
if any(~isfield(s, {sfgs pffgs})), return; end
try nFrame = s.NumberOfFrames; catch, nFrame = numel(s.(pffgs).FrameStart); end

% check frame ordering (Philips often needs SortFrames)
n = numel(MF_val('DimensionIndexValues', s, 1));
if n>0 && isfield(s, 'DimensionIndexSequence')
    % 2 Seq pamameters seen in Bruker (no sense to use Seq)
    ids = {'StackID' 'DataType' 'MRImageTypeMR' 'MRImageLabelType' ...
        'MRImageScanningSequencePrivate' 'CardiacTriggerDelayTime' ...
        'ContrastBolusAgentPhase' 'LUTLabel' ...
        'EffectiveEchoTime' 'MeasurementUnitsCodeSequence' 'PhaseNumber' ...
        'B_value' 'MRDiffusionSequence' 'DiffusionGradientDirection' ...
        'TemporalPositionTimeOffset' 'TemporalPositionIndex' ...
        'ImagePositionVolume' 'InStackPositionNumber'}; % last for slice
    dict = dicm_dict(s.Manufacturer, ids);
    [~, j] = ismember(ids, dict.name);
    tags = dict.tag(j(j>0)); % ids = dict.name(j(j>0))
    iPointer = zeros(1, n); % unknown pointers stay at beginning
    for i = 1:n
        a = s.DimensionIndexSequence.(sprintf('Item_%i',i)).DimensionIndexPointer;
        tag = [65536 1] * double(a);
        [tf, j] = ismember(tag, tags);
        if tf, iPointer(i) = j;
        else, fprintf(2, ' Unknown DimensionIndexPointer (%04x %04x).\n', a);
        end
    end
    [~, iPointer] = sort(iPointer); % sorted in order of ids
    s2 = struct('DimensionIndexValues', nan(n,nFrame));
    s2 = dicm_hdr(s, s2, 1:nFrame);
    [sorted, ind] = sortrows(s2.DimensionIndexValues(iPointer,:)');
    if ~isequal(ind', 1:nFrame)
        if ind(1) ~= 1 || ind(end) ~= nFrame 
            s = dicm_hdr(s.Filename, [], ind([1 end])); % re-read frames [1 end]
        end
        s.SortFrames = ind; % to sort img and get iVol/iSL for PerFrameSQ
    end
    s.LocationsInAcquisition = max(sorted(:,end));
    if mod(nFrame, s.LocationsInAcquisition), s = []; return; end
end

% copy important fields into s
flds = {'EchoTime' 'PixelSpacing' 'SpacingBetweenSlices' 'SliceThickness' ...
        'RepetitionTime' 'FlipAngle' 'RescaleIntercept' 'RescaleSlope' ...
        'ImageOrientationPatient' 'ImagePositionPatient' ...
        'InPlanePhaseEncodingDirection' 'MRScaleSlope' 'CardiacTriggerDelayTime'};
iF = 1; if isfield(s, 'SortFrames'), iF = s.SortFrames(1); end
for i = 1:numel(flds)
    if isfield(s, flds{i}), continue; end
    a = MF_val(flds{i}, s, iF);
    if ~isempty(a), s.(flds{i}) = a; end
end

if ~isfield(s, 'EchoTime')
    a = MF_val('EffectiveEchoTime', s, iF);
    if ~isempty(a), s.EchoTime = a;
    else, try s.EchoTime = str2double(s.EchoTimeDisplay); end
    end
end

% https://github.com/rordenlab/dcm2niix/issues/369
if strncmpi(s.Manufacturer, 'Philips', 7)
  try
    iLast = sprintf('Item_%g', s.NumberOfFrames);
    a = s.(pffgs).(iLast).PrivatePerFrameSq.Item_1.MRImageDynamicScanBeginTime;
    if a>0, s.RepetitionTime = a / (s.NumberOfDynamicScans-1) * 1000; end
  end
end

% for Siemens: the redundant copy makes non-Siemens code faster
% if isfield(s.(sfgs).Item_1, 'CSASeriesHeaderInfo')
%     s.CSASeriesHeaderInfo = s.(sfgs).Item_1.CSASeriesHeaderInfo.Item_1;
% end
% fld = 'CSAImageHeaderInfo';
% if isfield(s.(pffgs).Item_1, fld)
%     s.(fld) = s.(pffgs).(sprintf('Item_%g', iF)).(fld).Item_1;
% end

% check ImageOrientationPatient consistency for 1st and last frame only
if nFrame<2, return; end
iF = nFrame; if isfield(s, 'SortFrames'), iF = s.SortFrames(iF); end
a = MF_val('ImagePositionPatient', s, iF);
if ~isempty(a), s.LastFile.ImagePositionPatient = a; end
fld = 'ImageOrientationPatient';
val = MF_val(fld, s, iF);
if ~isempty(val) && isfield(s, fld) && any(abs(val-s.(fld))>1e-4)
    s = []; return; % inconsistent orientation, skip
end

%% subfunction: return value from Shared or PerFrame FunctionalGroupsSequence
function val = MF_val(fld, s, iFrame)
pffgs = 'PerFrameFunctionalGroupsSequence';
switch fld
    case 'EffectiveEchoTime'
        sq = 'MREchoSequence';
    case {'DiffusionDirectionality' 'B_value'}
        sq = 'MRDiffusionSequence';
    case 'ComplexImageComponent'
        sq = 'MRImageFrameTypeSequence';
    case {'DimensionIndexValues' 'InStackPositionNumber' 'TemporalPositionIndex' ...
            'FrameReferenceDatetime' 'FrameAcquisitionDatetime'}
        sq = 'FrameContentSequence';
    case {'RepetitionTime' 'FlipAngle'}
        sq = 'MRTimingAndRelatedParametersSequence';
    case 'ImagePositionPatient'
        sq = 'PlanePositionSequence';
    case 'ImageOrientationPatient'
        sq = 'PlaneOrientationSequence';
    case {'PixelSpacing' 'SpacingBetweenSlices' 'SliceThickness'}
        sq = 'PixelMeasuresSequence';
    case {'RescaleIntercept' 'RescaleSlope' 'RescaleType'}
        sq = 'PixelValueTransformationSequence';
    case {'InPlanePhaseEncodingDirection' 'MRAcquisitionFrequencyEncodingSteps' ...
            'MRAcquisitionPhaseEncodingStepsInPlane'}
        sq = 'MRFOVGeometrySequence';
    case 'CardiacTriggerDelayTime'
        sq = 'CardiacTriggerSequence';
    case {'SliceNumberMR' 'EchoTime' 'MRScaleSlope' 'PhaseNumber' 'MRImageLabelType'}
        sq = 'PrivatePerFrameSq'; % Philips
    case 'DiffusionGradientDirection' % 
        sq = 'MRDiffusionSequence';
        try
            s2 = s.(pffgs).(sprintf('Item_%g', iFrame)).(sq).Item_1;
            val = s2.DiffusionGradientDirectionSequence.Item_1.(fld);
        catch, val = [0 0 0]';
        end
        if nargin>1, return; end
    otherwise
        error('Sequence for %s not set.', fld);
end
if nargin<2
    val = {'SharedFunctionalGroupsSequence' pffgs sq fld 'NumberOfFrames'}; 
    return;
end
try 
    val = s.SharedFunctionalGroupsSequence.Item_1.(sq).Item_1.(fld);
catch
    try
        val = s.(pffgs).(sprintf('Item_%g', iFrame)).(sq).Item_1.(fld);
    catch
        val = [];
    end
end

%% subfunction: split nii components into multiple nii
function nii = split_components(nii, s)
fld = 'ComplexImageComponent';
if ~strcmp(tryGetField(s, fld, ''), 'MIXED'), return; end

if ~isfield(s, 'Volumes') % PAR file and single-frame file have this
    nSL = nii.hdr.dim(4); nVol = nii.hdr.dim(5);
    iFrames = 1:nSL:nSL*nVol;
    if isfield(s, 'SortFrames'), iFrames = s.SortFrames(iFrames); end
    s1 = struct(fld, {cell(1, nVol)}, 'MRScaleSlope', nan(1,nVol), ...
            'RescaleSlope', nan(1,nVol), 'RescaleIntercept', nan(1,nVol));
    s.Volumes = dicm_hdr(s, s1, iFrames);
end
if ~isfield(s, 'Volumes'), return; end

% suppose scl not applied in set_nii_hdr, since MRScaleSlope is not integer
flds = {'EchoTimes' 'CardiacTriggerDelayTimes'}; % to split
s1 = s.Volumes;
nii0 = nii;
% [c, ia] = unique(s.Volumes.(fld), 'stable'); % since 2013a?
[~, ia] = unique(s1.(fld));
ia = sort(ia);
c = s1.(fld)(ia);
for i = 1:numel(c)
    nii(i) = nii0;
    ind = strcmp(c{i}, s1.(fld));
    nii(i).img = nii0.img(:,:,:,ind);
    slope = s1.RescaleSlope(ia(i)); if isnan(slope), slope = 1; end 
    inter = s1.RescaleIntercept(ia(i)); if isnan(inter), inter = 0; end
    if ~isnan(s1.MRScaleSlope(ia(i)))
        inter = inter / (slope * s1.MRScaleSlope(ia(i)));
        slope = 1 / s1.MRScaleSlope(ia(i));
    end
    nii(i).hdr.scl_inter = inter;
    nii(i).hdr.scl_slope = slope;
    nii(i).hdr.file_name = [s.NiftiName '_' lower(c{i})];
    nii(i) = nii_tool('update', nii(i));
    
    for j = 1:numel(flds)
        if ~isfield(nii(i).json, flds{j}), continue; end
        nii(i).json.(flds{j}) = nii(i).json.(flds{j})(ind);
    end
end

%% Write error info to a file in case user ignores Command Window output
function firstTime = errorLog(errInfo, folder)
persistent niiFolder;
if nargin>1, firstTime = isempty(niiFolder); niiFolder = folder; end
if isempty(errInfo), return; end
fprintf(2, ' %s\n', errInfo); % red text in Command Window
fid = fopen(fullfile(niiFolder, 'dicm2nii_warningMsg.txt'), 'a');
fseek(fid, 0, -1); 
fprintf(fid, '%s\n', errInfo);
fclose(fid);

%% Get version yyyymmdd from README.md 
function dStr = getVersion(str)
dStr = '20191130';
if nargin<1 || isempty(str)
    pth = fileparts(mfilename('fullpath'));
    fname = fullfile(pth, 'README.md');
    if ~exist(fname, 'file'), return; end
    str = fileread(fname);
end
a = regexp(str, 'version\s(\d{4}\.\d{2}\.\d{2})', 'tokens', 'once');
if ~isempty(a), dStr = a{1}([1:4 6:7 9:10]); end

%% Get position info from Siemens CSA ASCII header
% The only case this is useful for now is for DTI_ColFA, where Siemens omit 
% ImageOrientationPatient, ImagePositionPatient, PixelSpacing.
% This shows how to get info from Siemens CSA header.
function s = csa2pos(s, nSL)
ori = {'Sag' 'Cor' 'Tra'}; % 1/2/3
sNormal = zeros(3,1);
for i = 1:3
    sNormal(i) = asc_header(s, ['sSliceArray.asSlice[0].sNormal.d' ori{i}], 0);
end
if all(sNormal==0); return; end % likely no useful info, give up

isMos = tryGetField(s, 'isMos', false);
revNum = asc_header(s, 'sSliceArray.ucImageNumb', 0);
[cosSL, iSL] = max(abs(sNormal));
if isMos && (~isfield(s, 'CSAImageHeaderInfo') || ...
        ~isfield(s.CSAImageHeaderInfo, 'SliceNormalVector'))
    a = sNormal; if revNum, a = -a; end
    s.CSAImageHeaderInfo.SliceNormalVector = a;
end

pos = zeros(3,2);
sl = [0 nSL-1];
for j = 1:2
    key = sprintf('sSliceArray.asSlice[%g].sPosition.d', sl(j));
    for i = 1:3
        pos(i,j) = asc_header(s, [key ori{i}], 0);
    end
end

if ~isfield(s, 'SpacingBetweenSlices')
    if all(pos(:,2)==0) % like Mprage: dThickness & sPosition for volume
        a = asc_header(s, 'sSliceArray.asSlice[0].dThickness') ./ nSL;
        if ~isempty(a), s.SpacingBetweenSlices = a; end
    else
        s.SpacingBetweenSlices = abs(diff(pos(iSL,:))) / (nSL-1) / cosSL;
    end
end

if ~isfield(s, 'PixelSpacing')
    a = asc_header(s, 'sSliceArray.asSlice[0].dReadoutFOV');
    a = a ./ asc_header(s, 'sKSpace.lBaseResolution');
    interp = asc_header(s, 'sKSpace.uc2DInterpolation');
    if interp, a = a ./ 2; end
    if ~isempty(a), s.PixelSpacing = a * [1 1]'; end
end

R(:,3) = sNormal; % ignore revNum for now
if isfield(s, 'ImageOrientationPatient')
    R(:, 1:2) = reshape(s.ImageOrientationPatient, 3, 2);
else
    if iSL==3
        R(:,2) = [0 R(3,3) -R(2,3)] / norm(R(2:3,3));
        R(:,1) = cross(R(:,2), R(:,3));
    elseif iSL==2
        R(:,1) = [R(2,3) -R(1,3) 0] / norm(R(1:2,3));
        R(:,2) = cross(R(:,3), R(:,1));
    elseif iSL==1
        R(:,1) = [-R(2,3) R(1,3) 0] / norm(R(1:2,3));
        R(:,2) = cross(R(:,1), R(:,3));
    end

    rot = asc_header(s, 'sSliceArray.asSlice[0].dInPlaneRot', 0);
    rot = rot - round(rot/pi*2)*pi/2; % -45 to 45 deg, is this right?
    ca = cos(rot); sa = sin(rot);
    R = R * [ca sa 0; -sa ca 0; 0 0 1];
    s.ImageOrientationPatient = R(1:6)';
end

if ~isfield(s, 'ImagePositionPatient')    
    dim = double([s.Columns s.Rows]');
    if all(pos(:,2) == 0) % pos(:,1) for volume center
        if any(~isfield(s,{'PixelSpacing' 'SpacingBetweenSlices'})), return; end
        R = R * diag([s.PixelSpacing([2 1]); s.SpacingBetweenSlices]);
        x = [-dim/2*[1 1]; (nSL-1)/2*[-1 1]];
        pos = R * x + pos(:,1) * [1 1]; % volume center to slice 1&nSL position
    else % this may be how Siemens sets unusual mosaic ImagePositionPatient 
        if ~isfield(s, 'PixelSpacing'), return; end
        R = R(:,1:2) * diag(s.PixelSpacing([2 1]));
        pos = pos - R * dim/2 * [1 1]; % slice centers to slice position
    end
    if revNum, pos = pos(:, [2 1]); end
    if isMos, pos(:,2) = pos(:,1); end % set LastFile same as first for mosaic
    s.ImagePositionPatient = pos(:,1);
    s.LastFile.ImagePositionPatient = pos(:,2);
end

%% subfuction: check whether parpool is available
% Return true if it is already open, or open it if available
function doParal = useParTool
doParal = usejava('jvm');
if ~doParal, return; end

if isempty(which('parpool')) % for early matlab versions
    try 
        if matlabpool('size')<1 %#ok<*DPOOL>
            try
                matlabpool; 
            catch me
                fprintf(2, '%s\n', me.message);
                doParal = false;
            end
        end
    catch
        doParal = false;
    end
    return;
end

% Following for later matlab with parpool
try 
    if isempty(gcp('nocreate'))
        try
            parpool; 
        catch me
            fprintf(2, '%s\n', me.message);
            doParal = false;
        end
    end
catch
    doParal = false;
end

%% subfunction: return nii ext from dicom struct
% The txt extension is in format of: name = parameter;
% Each parameter ends with [';' char(0 10)]. Examples:
% Modality = 'MR'; % str parameter enclosed in single quotation marks
% FlipAngle = 72; % single numeric value, brackets may be used, but optional
% SliceTiming = [0.5 0.1 ... ]; % vector parameter enclosed in brackets
% bvec = [0 -0 0 
% -0.25444411 0.52460458 -0.81243353 
% ...
% 0.9836791 0.17571079 0.038744]; % matrix rows separated by char(10) and/or ';'
function ext = set_nii_ext(s)
flds = fieldnames(s);
ext.ecode = 6; % text ext
ext.edata = '';
for i = 1:numel(flds)
    try val = s.(flds{i}); catch, continue; end
    if ischar(val)
        str = sprintf('''%s''', val);
    elseif numel(val) == 1 % single numeric
        str = sprintf('%.8g', val);
    elseif isvector(val) % row or column
        str = sprintf('%.8g ', val);
        str = sprintf('[%s]', str(1:end-1)); % drop last space
    elseif isnumeric(val) % matrix, like DTI bvec
        fmt = repmat('%.8g ', 1, size(val, 2));
        str = sprintf([fmt char(10)], val'); %#ok
        str = sprintf('[%s]', str(1:end-2)); % drop last space and char(10)
    else % in case of struct etc, skip
        continue;
    end
    ext.edata = [ext.edata flds{i} ' = ' str ';' char([0 10])];
end

% % Matlab ext: ecode = 40
% fname = [tempname '.mat'];
% save(fname, '-struct', 's', '-v7'); % field as variable
% fid = fopen(fname);
% b = fread(fid, inf, '*uint8'); % data bytes
% fclose(fid);
% delete(fname);
% 
% % first 4 bytes (int32) encode real data length, endian-dependent
% if exist('ext', 'var'), n = numel(ext)+1; else n = 1; end
% ext(n).edata = [typecast(int32(numel(b)), 'uint8')'; b];
% ext(n).ecode = 40; % Matlab
 
% % Dicom ext: ecode = 2
% if isfield(s, 'SOPInstanceUID') % make sure it is dicom
%     if exist('ext', 'var'), n = numel(ext)+1; else n = 1; end
%     ext(n).ecode = 2; % dicom
%     fid = fopen(s.Filename);
%     ext(n).edata = fread(fid, s.PixelData.Start, '*uint8');
%     fclose(fid);
% end

%% Fix some broken multiband sliceTiming. Hope this won't be needed in future.
% Odd number of nShot is fine, but some even nShot may have problem.
% This gives inconsistent result to the following example in PDF doc, but I
% would rather believe the example is wrong:
% nSL=20; mb=2; nShot=nSL/mb; % inc=3
% In PDF: 0,10 - 3,13 - 6,16 - 9,19 - 1,11 - 4,14 - 7,17 - 2,12 - 5,15 - 8,18
% result: 0,10 - 3,13 - 6,16 - 9,19 - 2,12 - 5,15 - 8,18 - 1,11 - 4,14 - 7,17
function t = mb_slicetiming(s, TA)
dict = dicm_dict(s.Manufacturer, 'CSAImageHeaderInfo');
s2 = dicm_hdr(s.LastFile.Filename, dict);
t = csa_header(s2, 'MosaicRefAcqTimes'); % try last volume first

% No SL acc factor. Not even multiband flag. This is UGLY
nSL = double(s.LocationsInAcquisition);
mb = ceil((max(t) - min(t)) ./ TA); % based on the wrong timing pattern
if isempty(mb) || mb==1 || mod(nSL,mb)>0, return; end % not MB or wrong mb guess

nShot = nSL / mb;
ucMode = asc_header(s, 'sSliceArray.ucMode'); % 1/2/4: Asc/Desc/Inter
if isempty(ucMode), return; end
t = linspace(0, TA, nShot+1)'; t(end) = [];
t = repmat(t, mb, 1); % ascending, ucMode==1
if ucMode == 2 % descending
    t = t(nSL:-1:1);
elseif ucMode == 4 % interleaved
    if mod(nShot,2) % odd number of shots
        inc = 2;
    else
        inc = nShot / 2 - 1;
        if mod(inc,2) == 0, inc = inc - 1; end
        errorLog([s.NiftiName ': multiband interleaved order, even' ...
            ' number of shots.\nThe SliceTiming information may be wrong.']);
    end
    
% % This gives the result in the PDF doc for example above
%     ind = nan(nShot, 1); j = 0; i = 1; k = 0;
%     while 1
%         ind(i) = j + k*inc;
%         if ind(i)+(mb-1)*nShot > nSL-1
%             j = j + 1; k = 0;
%         else
%             i = i + 1; k = k + 1;
%         end
%         if i>nShot, break; end
%     end
    
    ind = mod((0:nShot-1)*inc, nShot)'; % my guess based on chris data
    
    if nShot==6, ind = [0 2 4 1 5 3]'; end % special case
    ind = bsxfun(@plus, ind*ones(1,mb), (0:mb-1)*nShot);
    ind = ind + 1;

    t = zeros(nSL, 1);
    for i = 1:nShot
        t(ind(i,:)) = (i-1) / nShot;
    end
    t = t * TA;
end
if csa_header(s, 'ProtocolSliceNumber')>0, t = t(nSL:-1:1); end % rev-num

%% subfunction: check ImagePostionPatient from multiple slices/volumes
function [err, h] = checkImagePosition(h)
nFile = numel(h);
ipp = zeros(nFile, 1);
iSL = xform_mat(h{1}); iSL = iSL(3);
for j = 1:nFile, ipp(j,:) = h{j}.ImagePositionPatient(iSL); end

a = diff(sort(ipp));
tol = max(a)/100; % max(a) close to SliceThichness. 1% arbituary
if abs(tryGetField(h{1}, 'GantryDetectorTilt', 0)) > 0.1, tol = tol * 10; end % arbituary
nSL = sum(a > tol) + 1;
err = '';
nVol = numel(ipp) / nSL;
if mod(nVol,1), err = 'Missing file(s) detected'; return; end
h{1}.LocationsInAcquisition = uint16(nSL); % best way for nSL?
if nSL<2 || ~strncmp(h{1}.Manufacturer, 'Philips', 7), return; end

s = h{1};
rows = {};
ids = {'ComplexImageComponent' 'B_value' 'TemporalPositionIdentifier' ...
    'EchoTime' 'MRImageGradientOrientationNumber' 'MRImageLabelType' ...
    'PhaseNumber' 'SliceNumberMR'}; % for Philips par
for i = 1:numel(ids)
    if ~all(cellfun(@(c) isfield(c,ids{i}),h)), continue; end % by JonD
    rows = [rows cellfun(@(c)c.(ids{i}), h', 'UniformOutput', false)];
end
if isempty(rows), return; end
[~, ind] = sortrows(rows);
h = h(ind);
if ind(1) == 1, return; end % first file kept
h{1} = dicm_hdr(h{1}.Filename); % read full hdr
flds = fieldnames(s);
[~, i] = ismember('PixelData', flds);
for j = i+1:numel(flds)
    if isfield(s, flds{j}), h{1}.(flds{j}) = s.(flds{j}); end
end

%% Save JSON file, proposed by Chris G
% matlab.internal.webservices.toJSON(s)
function save_json(s, fname)
flds = fieldnames(s);
fid = fopen(strcat(fname, '.json'), 'w'); % overwrite silently if exist
fprintf(fid, '{\n');
for i = 1:numel(flds)
    nam = flds{i};
    if ~isfield(s, nam), continue; end
    val = s.(nam);
    
    % this if-elseif block takes care of name/val change for BIDS json
    if any(strcmp(nam, {'RepetitionTime' 'InversionTime' 'EchoTimes' 'CardiacTriggerDelayTimes'}))
        val = val / 1000; % in sec now
    elseif strcmp(nam, 'UnwarpDirection')
        nam = 'PhaseEncodingDirection';
        if val(1) == '-' || val(1) == '?', val = val([2 1]); end
        if     val(1) == 'x', val(1) = 'i'; % BIDS spec
        elseif val(1) == 'y', val(1) = 'j';
        elseif val(1) == 'z', val(1) = 'k';
        end
    elseif strcmp(nam, 'EffectiveEPIEchoSpacing')
        nam = 'EffectiveEchoSpacing';
        val = val / 1000;
    elseif strcmp(nam, 'ReadoutSeconds')
        nam = 'TotalReadoutTime';
    elseif strcmp(nam, 'SliceTiming')
        val = (0.5 - val) * s.RepetitionTime / 1000; % FSL style to secs
    elseif strcmp(nam, 'SecondEchoTime')
        nam = 'EchoTime2';
        val = val / 1000;
    elseif strcmp(nam, 'EchoTime')
        % if there are two TEs we are dealing with a fieldmap
        if isfield(s, 'SecondEchoTime')
            nam = 'EchoTime1';
        end
        val = val / 1000;
    elseif strcmp(nam, 'bval')
        nam = 'DiffusionBValue';
    elseif strcmp(nam, 'bvec')
        nam = 'DiffusionGradientOrientation';
    elseif strcmp(nam, 'DelayTimeInTR')
        nam = 'DelayTime';
        val = val / 1000; % secs 
    elseif strcmp(nam, 'ImageType')
        val = regexp(val, '\\', 'split');
    end
    
    fprintf(fid, '\t"%s": ', nam);
    if isempty(val)
        fprintf(fid, 'null,\n');
    elseif ischar(val)
        val = regexprep(val, '([\\"])', '\\$1'); % escape \ "
        fprintf(fid, '"%s",\n', val);
    elseif iscellstr(val)
        fprintf(fid, '[');
        fprintf(fid, '"%s", ', val{:});
        fseek(fid, -2, 'cof'); % remove trailing comma and space
        fprintf(fid, '],\n');
    elseif numel(val) == 1 % scalar numeric
        fprintf(fid, '%.8g,\n', val);
    elseif isvector(val) % row or column
        fprintf(fid, '[\n');
        fprintf(fid, '\t\t%.8g,\n', val);
        fseek(fid, -2, 'cof');
        fprintf(fid, '\t],\n');
    elseif isnumeric(val) % matrix
        fprintf(fid, '[\n');
        fmt = repmat('%.8g, ', 1, size(val, 2));
        fprintf(fid, ['\t\t[' fmt(1:end-2) '],\n'], val');
        fseek(fid, -2, 'cof');
        fprintf(fid, '\n\t],\n');
    else % in case of struct etc, skip
        fprintf(2, 'Unknown type of data for %s.\n', nam);
        fprintf(fid, 'null,\n');
    end
end
fseek(fid, -2, 'cof'); % remove trailing comma and \n
fprintf(fid, '\n}\n');
fclose(fid);

%% Check for newer version for 42997 at Matlab Central
% Simplified from checkVersion in findjobj.m by Yair Altman
function checkUpdate(mfile)
verLink = 'https://github.com/xiangruili/dicm2nii/blob/master/README.md';
webUrl = 'https://www.mathworks.com/matlabcentral/fileexchange/42997';
if ~isdeployed
try
    str = webread(verLink);
catch me
    try
        str = urlread(verLink); %#ok
    catch
        str = sprintf('%s.\n\nPlease download manually.', me.message);
        errordlg(str, 'Web access error');
        web(webUrl, '-browser');
        return;
    end
end

latestStr = getVersion(str);
if datenum(getVersion(), 'yyyymmdd') >= datenum(latestStr, 'yyyymmdd')
    msgbox([mfile ' and the package are up to date.'], 'Check update');
    return;
end

msg = ['Update to the newer version (' latestStr ')?'];
answer = questdlg(msg, ['Update ' mfile], 'Yes', 'Later', 'Yes');
if ~strcmp(answer, 'Yes'), return; end

url = ['https://www.mathworks.com/matlabcentral/mlc-downloads/'...
       'downloads/e5a13851-4a80-11e4-9553-005056977bd0/' ...
       '80e748a3-0ae1-48a5-a2cb-b8380dac0232/packages/zip'];
tmp = tempdir;
try
    fname = websave('dicm2nii_github.zip', url); % 2014a
    unzip(fname, tmp); delete(fname);
    a = dir([tmp 'xiangruili*']);
    if isempty(a), tdir = tmp; else, tdir = [tmp a(1).name '/']; end
catch 
    % system('git clone https://github.com/xiangruili/dicm2nii.git')
    url = 'https://github.com/xiangruili/dicm2nii/archive/master.zip';
    try
        fname = [tmp 'dicm2nii_github.zip'];
        urlwrite(url, fname); %#ok
        unzip(fname, tmp); delete(fname);
        tdir = [tmp 'dicm2nii-master/'];
    catch me
        errordlg(['Error in updating: ' me.message], mfile);
        web(webUrl, '-browser');
        return;
    end
end
movefile([tdir '*.*'], [fileparts(which(mfile)) '/.'], 'f');
rmdir(tdir, 's');
rehash;
warndlg(['Package updated successfully. Please restart ' mfile ...
         ', otherwise it may give error.'], 'Check update');
end

%% Subfunction: return NumberOfImagesInMosaic if Siemens mosaic, or [] otherwise.
% If NumberOfImagesInMosaic in CSA is >1, it is mosaic, and we are done. 
% If not exists, it may still be mosaic due to Siemens bug seen in syngo MR
% 2004A 4VA25A phase image. Then we check EchoColumnPosition in CSA, and if it
% is smaller than half of the slice dim, sSliceArray.lSize is used as nMos. If
% no CSA at all, the better way may be to peek into img to get nMos. Then the
% first attempt is to check whether there are padded zeros. If so we count zeros
% either at top or bottom of the img to decide real slice dim. In case there is
% no padded zeros, we use the single zero lines along row or col seen in most
% (not all, for example some phase img, derived data like moco series or tmap
% etc) mosaic. If the lines are equally spaced, and nMos is divisible by mosaic
% dim, we accept nMos. Otherwise, we fall back to NumberOfPhaseEncodingSteps,
% which is used by dcm2nii, but is not reliable for most mosaic due to partial
% fourier or less 100% phase fov.
function nMos = nMosaic(s)
nMos = csa_header(s, 'NumberOfImagesInMosaic'); % healthy mosaic dicom
if ~isempty(nMos), return; end % seen 0 for GLM Design file and others

% The next fix detects mosaic which is not labeled as MOSAIC in ImageType, nor
% NumberOfImagesInMosaic exists, seen in syngo MR 2004A 4VA25A phase image.
res = csa_header(s, 'EchoColumnPosition'); % half or full of slice dim
if ~isempty(res)
    dim = double(max([s.Columns s.Rows]));
    if asc_header(s, 'sKSpace.uc2DInterpolation', 0), dim = dim / 2; end
    if dim/res/2 >= 2 % nTiles>=2
        nMos = asc_header(s, 'sSliceArray.lSize'); % mprage lSize=1
    end
    return; % Siemens non-mosaic returns here
end

% The fix below is for dicom labeled as \MOSAIC in ImageType, but no CSA.
if ~isType(s, '\MOSAIC') && ~isType(s, '\VFRAME'), return; end % non-mosaic
try nMos = s.LocationsInAcquisition; return; end % try Siemens/UIH private tag
try nMos = numel(fieldnames(s.MRVFrameSequence)); return; end % UIH
    
dim = double([s.Columns s.Rows]); % slice or mosaic dim
img = dicm_img(s, 0) ~= 0; % peek into img to figure out nMos
nP = tryGetField(s, 'NumberOfPhaseEncodingSteps', 4); % sliceDim >= phase steps
c = img(dim(1)-nP:end, dim(2)-nP:end); % corner at bottom-right
done = false;
if all(~c(:)) % at least 1 padded slice: not 100% safe
    c = img(1:nP+1, dim(2)-nP:end); % top-right
    if all(~c(:)) % all right tiles padded: use all to determine
        ln = sum(img);
    else % use several rows at bottom to determine: not as safe as all
        ln = sum(img(dim(1)-nP:end, :));
    end
    z = find(ln~=0, 1, 'last');
    nMos = dim(2) / (dim(2) - z);
    done = mod(nMos,1)==0 && mod(dim(1),nMos)==0;
end
if ~done % this relies on zeros along row or col seen in most mosaic
    ln = sum(img, 2) == 0;
    if sum(ln)<2
        ln = sum(img) == 0; % likely PhaseEncodingDirectionPositive=0
        i = find(~ln, 1, 'last'); % last non-zero column in img
        ln(i+2:end) = []; % leave only 1 true for padded zeros
    end
    nMos = sum(ln);
    done = nMos>1 && all(mod(dim,nMos)==0) && all(diff(find(ln),2)==0);
end
if ~done && isfield(s, 'NumberOfPhaseEncodingSteps')
    nMos = min(dim) / nP;
    done = nMos>1 && mod(nMos,1)==0 && all(mod(dim,nMos)==0);
end

if ~done
    errorLog([ProtocolName(s) ': NumberOfImagesInMosaic not available.']);
    nMos = []; % keep mosaic as it is
    return;
end

nMos = nMos * nMos; % not work for UIH
img = mos2vol(uint8(img), nMos, 0); % find padded slices: useful for STC
while 1
    a = img(:,:,nMos);
    if any(a(:)), break; end
    nMos = nMos - 1;
end

%% return all file names in a folder, including in sub-folders
function files = filesInDir(folder)
dirs = genpath(folder);
dirs = regexp(dirs, pathsep, 'split');
files = {};
for i = 1:numel(dirs)
    if isempty(dirs{i}), continue; end
    curFolder = [dirs{i} filesep];
    a = dir(curFolder); % all files and folders
    a([a.isdir]) = []; % remove folders
    a = strcat(curFolder, {a.name});
    files = [files a]; %#ok<*AGROW>
end

%% Select both folders and files
function out = jFileChooser(folder, prompt, multi, button)
if nargin<4 || isempty(button), button = 'Select'; end
if nargin<3 || isempty(multi), multi = true; end
if nargin<2 || isempty(prompt)
    if multi, prompt = 'Choose files and/or folders';
    else,     prompt = 'Choose file or folder';
    end
end
if nargin<1 || isempty(folder), folder = pwd; end

jFC = javax.swing.JFileChooser(folder);
jFC.setFileSelectionMode(jFC.FILES_AND_DIRECTORIES);
set(jFC, 'MultiSelectionEnabled', logical(multi));
set(jFC, 'ApproveButtonText', button);
set(jFC, 'DialogTitle', prompt);
returnVal = jFC.showOpenDialog([]);
if returnVal ~= jFC.APPROVE_OPTION, out = returnVal; return; end % numeric

if multi
    files = jFC.getSelectedFiles();
    n = numel(files);
    out = cell(1, n);
    for i = 1:n, out{i} = char(files(i)); end
else
    out = char(jFC.getSelectedFile());
end

%% 
function v = normc(M)
vn = sqrt(sum(M .^ 2)); % vn = vecnorm(M);
vn(vn==0) = 1;
v = bsxfun(@rdivide, M, vn);

%%
function BtnModalityTable(h,TT,TS)
if verLessThanOctave
    dat = TT.Data;
else
    dat = cellfun(@char,table2cell(TT.Data),'uni',0);
end
toSkip = any(ismember(dat(:,2:3),'skip'),2);
if all(toSkip)
    warndlg('All images are skipped... Please select the type and modality for all scans','No scan selected');
    return;
end
a = dat(~toSkip, 2:3);
a = strcat(a(:,1), filesep, a(:,2));
if numel(a) ~= numel(unique(a))
    [~, ind] = unique(a);
    ind = setdiff(1:9, ind);
    warndlg(['Need to fix the non-unique name "' a{ind(1)} '".'], 'File name conflict');
    return;
end
setappdata(0,'ModalityTable', dat)
setappdata(0,'SubjectTable', cellfun(@char,table2cell(TS.Data),'uni',0))
delete(h)

%%
function my_closereq(src,~)
% Close request function 
% to display a question dialog box
if verLessThanOctave
    selection = questdlg('Cancel Dicom conversion?','Close dicm2nii','OK','Cancel','Cancel');
else
    selection = uiconfirm(src,'Cancel Dicom conversion?',...
        'Close dicm2nii');
end
switch selection
    case 'OK'
        delete(src)
        setappdata(0,'Canceldicm2nii',true)
    case 'Cancel'
        return
end

%%
function ax = previewDicom(ax,s,axesArgs)
try
    nSL = double(tryGetField(s{1}, 'LocationsInAcquisition'));
    if isempty(nSL)
        nSL = length(s);
    end
    img = dicm_img(s{min(end,round(nSL/2))});
    img = img(:,:,:,round(end/2));

    if verLessThanOctave
        if ~isempty(ax)
            axis(ax);
        end
        axnew = imagesc(img);
        if isempty(ax)
            ax = axnew.Parent;
            setpixelposition(ax,axesArgs{3})
        end
        colormap(ax,axesArgs{5})
        ax.YTickLabel = [];
        ax.XTickLabel = [];
    else
        if isempty(ax)
            ax = uiaxes(axesArgs{:});
        end
        imagesc(ax,img);
    end
    axis(ax,'off');
    set(ax,'BackgroundColor',[0 0 0])
    ax.DataAspectRatio = [s{min(end,round(nSL/2))}.PixelSpacing' 1];
    
    try
        infos = {'EchoTime','RepetitionTime','FlipAngle','MRAcquisitionType','Manufacturer','SeriesDescription'};
        str = {};
        for ii=1:length(infos)
            if isfield(s{1},infos{ii})
                if isnumeric(s{1}.(infos{ii})), frmt = '%s: %g';
                else, frmt = '%s: %s';
                end
                str = [str {sprintf(frmt,infos{ii},s{1}.(infos{ii}))}];
            end
        end
        str = [str {sprintf('%s: %g','Nslices',nSL)}];
        str = [str {sprintf('%s: %g','Nvol',length(s)/nSL)}];
        text(ax,0,0,str,'FontSize',10,'Color',[1 1 1]);
    catch err
        warning(['CANNOT PREVIEW SCANNING INFOS: ' err.message])
    end
catch err
    warning(['CANNOT PREVIEW RUN: ' err.message])
end

%%
function showHelp(types, modalities)
msg = {'BIDS Converter module for dicm2nii',...
    'tanguy.duval@inserm.fr',...
    'http://bids.neuroimaging.io',...
    '------------------------------------------',...
    'Info Table',...
    '  Subject:            subject id. 1st layer in directory structure',...
    '                       ex: John',...
    '                       No space, no dash, no underscore!',...
    '  Session:            session id. 2nd  layer in directory structure',...
    '                       ex: 01',...
    '                       No space, no dash, no underscore!',...
    '  AcquisitionDate:    Session date. 1st Column in the session',...
    '                        description file (sub-Subject_sessions.tsv).',...
    '  Comment:            Comments.     2nd  Column in the session',...
    '                        description file (sub-Subject_sessions.tsv).',...
    '------------------------------------------',...
    'Sequence Table',...
    '  Name:                 SerieDescription extracted from the dicom field.',...
    '  Type:                 type of imaging modality. 3rd layer in directory structure.',...
    ['                        ex: ' strjoin(types,', ')],...
    '                         ''skip'' to skip conversion',...
    '  Modality:             Modality. suffix of filename. ',...
    ['                        ex: ' strjoin(modalities,', ')],...
    '                         ''skip'' to skip conversion',...
    ''};
h = msgbox(msg,'Help on BIDS converter');
set(findall(h,'Type','Text'),'FontName','FixedWidth');
Pos = get(h,'Position'); Pos(3) = 450;
set(h,'Position',Pos)

%%
function val = verLessThanOctave
isOctave = exist('OCTAVE_VERSION', 'builtin') ~= 0;
val = isOctave || verLessThan('matlab','9.4');

%% Return full name for file/path, no matter it exists or not (200120)
% \ is treated as / for unix. This may be bad, since \ is legal char for unix
function rst = fullName(nam)
if ispc
    rst = strrep(char(nam), '/', '\');
    if isempty(regexp(rst, '^([a-zA-Z]:|\\\\)', 'once')) % not \\ or C:
        rst = [pwd '\' rst];
    end
    rst = [rst(1) regexprep(rst(2:end), '\\{2,}', '\\')]; % repeated sep
    if regexp(rst, '\\\.$'), rst(end+(-1:0)) = ''; end
    rst = strrep(rst, '\.\', '\'); % useless current dir
    while 1 % \.. one level up
        i = strfind(rst, '\..');
        if isempty(i), break; end
        i0 = strfind(rst(1:i(1)-1), '\'); % the dir before \..
        if isempty(i0), error(['Invalid name: ' nam]); end
        rst(i0(end):i(1)+2) = '';
    end
    if numel(rst)==2 && rst(2)==':', rst(3) = '\'; end
else
    rst = strrep(char(nam), '\', '/');
    if strncmp(rst, '~', 1), rst = [getenv('HOME') rst(2:end)]; % ~: Home
    elseif ~strncmp(rst, '/', 1), rst = [pwd '/' rst];
    end
    rst = regexprep(rst, '/{2,}', '/');
    if regexp(rst, '/\.$'), rst(end+(-1:0)) = ''; end
    rst = strrep(rst, '/./', '/');
    while 1
        i = strfind(rst, '/..');
        if isempty(i), break; end
        i0 = strfind(rst(1:i(1)-1), '/');
        if isempty(i0), error(['Invalid name: ' nam]); end
        rst(i0(end):i(1)+2) = '';
    end
    if isempty(rst), rst = '/'; end
end

%% this can be removed for matlab 2013b+
function y = flip(varargin)
try
    y = builtin('flip', varargin{:});
catch
    if nargin<2, varargin{2} = find(size(varargin{1})>1, 1); end
    y = flipdim(varargin{:}); %#ok
end

%% this can be removed for matlab 2013b+
function tf = isfolder(folderName)
try tf = builtin('isfolder', folderName);
catch, tf = isdir(folderName); %#ok
end

%% Return true if input is char or single string (R2016b+)
function tf = ischar(A)
tf = builtin('ischar', A);
if tf, return; end
if exist('strings', 'builtin'), tf = isstring(A) && numel(A)==1; end

%% Take precedence over some 3rd party function
function c = cross(a, b)
c = a([2 3 1]).*b([3 1 2]) - a([3 1 2]).*b([2 3 1]);

%%
