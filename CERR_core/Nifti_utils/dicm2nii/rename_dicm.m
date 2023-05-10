function rename_dicm(files, fmt)
% Rename dicom files so the names are meaningful to human.
% 
% RENAME_DICM(files, outputNameFormat)
% 
% The first input is the dicom file(s) or a folder containing dicom files.
% The second input is the format for the result file names. Support format
% include:
% 
% 1: run1_00001.dcm (SeriesDescription_instance). It is the shortest name, but
%    if there is MoCo series, or users did not change run names, there will be
%    name conflict.
%   
% 2: Smith^John-0004-0001-00001.dcm (PatientName-Series-Acquisition-Instance).
%    This is the BrainVoyager format. It has no name confict, but it is long and
%    less descriptive. Note that BrainVoyager itself has problem to distinguish
%    the two series of images for Siemens fieldmap, while this code can avoid
%    this problem.
% 
% 3: run1_004_00001.dcm (SeriesDescription_Series_Instance). This gives short
%    names, while it is descriptive and there is no name conflict most of time.
% 
% 4: 2334ZL_run1_00001.dcm (PatientName_SeriesDescription_instance). This may be
%    useful if files for different subjects are in the same folder.
% 
% 5: run1_003_001_00001.dcm (SeriesDescription_Series_acquisition_instance). 
%    This ensures no name conflict, and is the default.
% 
% Whenever there is name confict, you will see red warning and the remaining
% files won't be renamed.
% 
% If the first input is not provided or empty, you will be asked to pick up
% a folder.
% 
% See also DICM_HDR, SORT_DICM, ANONYMIZE_DICM
 
% History (yymmdd):
% 0710?? Write it (Xiangrui Li)
% 1304?? Add more options for output format
% 1306?? Exclude PhoenixZIPReport files to avoid error
% 1306?? Fix problem if illegal char in ProtocolName
% 1309?? Use dicm_hdr to replace dicominfo, so it runs much faster
% 1309?? Use 5-digit InstanceNumber, so works better for GE/Philips
% 1402?? Add Manufacturer to flds (bug caused by dicm_hdr update)
% 140506 Use SeriesDescription to replace ProtocolName non-Siemens
% 151001 Avoid cd so it works if m file is at pwd but path not set
% 171211 Make AcquisitionNumer and Manufacturer not mandidate.

if nargin<1 || isempty(files)
    folder = uigetdir(pwd, 'Select a folder containing DICOM files');
    if folder==0, return; end
    files = dir(folder);
    files([files.isdir]) = [];
    files = {files.name};
    
    str = sprintf(['Choose Output format: \n\n' ...
                   '1: run1_00001.dcm (SeriesDescription_instance)\n' ...
                   '2: BrainVoyager format (subj-series-acquisiton-instance)\n' ...
                   '3: run1_001_00001.dcm (SeriesDescription_series_instance)\n' ...
                   '4: subj_run1_00001.dcm (subj_SeriesDescription_instance)\n' ...
                   '5: run1_001_001_00001.dcm (SeriesDescription_series_acquisition_instance)\n']);
    fmt = inputdlg(str, 'Rename Dicom', 1, {'5'});
    if isempty(fmt), return; end
    fmt = str2double(fmt{1});
else
    if exist(files, 'dir') % input is folder
        folder = files;
        files = dir(folder);
        files([files.isdir]) = [];
        files = {files.name};
    else % files
        if ~iscell(files), files = {files}; end
        folder = fileparts(files{1});
        if ~isempty(folder), folder = pwd; end
    end
    if nargin<2 || isempty(fmt), fmt = 5; end
end

flds = {'InstanceNumber' 'AcquisitionNumber' 'SeriesNumber' 'EchoNumber' 'ProtocolName' ...
        'SeriesDescription' 'PatientName' 'PatientID' 'Manufacturer'};
dict = dicm_dict('', flds);
tryGetField = dicm2nii('', 'tryGetField', 'func_handle');

nFile = numel(files);
if nFile<1, return; end
if ~strcmp(folder(end), filesep), folder(end+1) = filesep; end
err = '';
str = sprintf('%g/%g', 1, nFile);
more off;
fprintf(' Renaming DICOM files: %s', str);

for i = 1:nFile
    fprintf(repmat('\b', [1 numel(str)]));
    str = sprintf('%g/%g', i, nFile);
    fprintf('%s', str);
    s = dicm_hdr([folder files{i}], dict);
    vendor = tryGetField(s, 'Manufacturer', '');
    try % skip if no these fields
        sN = s.SeriesNumber;
        aN = tryGetField(s, 'AcquisitionNumber', 1);
        iN = s.InstanceNumber;
        if fmt ~= 2
            if strncmp(vendor, 'SIEMENS', 7)
                pName = strtrim(s.ProtocolName);
            else
                pName = strtrim(s.SeriesDescription);
            end
            pName(~isstrprop(pName, 'alphanum')) = '_'; % valid file name
            pName = regexprep(pName, '_{2,}', '_');
        end
        if fmt==2 || fmt==4
            sName = tryGetField(s, 'PatientName');
            if isempty(sName), sName = tryGetField(s, 'PatientID'); end
            sName(~isstrprop(sName, 'alphanum')) = '_';
            sName = regexprep(sName, '_{2,}', '_');
        end
    catch me %#ok
        continue;
    end
    
    if strncmpi(vendor, 'Philips', 7) % SeriesNumber is useless
        sN = aN;
    elseif strncmpi(vendor, 'SIEMENS', 7) && tryGetField(s, 'EchoNumber', 1)>1
        aN = s.EchoNumber; % fieldmap phase image
    end
    
    if fmt == 1 % pN_001
        name = sprintf('%s_%05g.dcm', pName, iN);
    elseif fmt == 2 % BrainVoyager
        name = sprintf('%s-%04g-%04g-%05g.dcm', sName, sN, aN, iN);
    elseif fmt == 3 % pN_03_00001
        name = sprintf('%s_%02g_%05g.dcm', pName, s.SeriesNumber, iN);
    elseif fmt == 4 % 2322ZL_pN_001
        name = sprintf('%s_%s_%05g.dcm', sName, pName, iN); 
    elseif fmt == 5 % pN_003_001_001
        name = sprintf('%s_%03g_%03g_%05g.dcm', pName, sN, aN, iN); 
    else
        error('Invalid format.');
    end
    
    if strcmpi(files{i}, name), continue; end % done already
    
    if ispc, cmd = ['rename "' folder files{i} '" ' name];
    else, cmd = ['mv "' folder files{i} '" "' folder name '"'];
    end % matlab movefile is too slow
    
    [er, foo] = system(cmd);
    if er, err = [err files{i} ': ' foo]; end %#ok
end
fprintf('\n');
if ~isempty(err), fprintf(2, '\n%s\n', err); end
