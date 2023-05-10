function anonymize_dicm(src, rst, subID)
% Replace PatientName in dicom header with an ID without altering ANYTHING else.
% 
%  anonymize_dicm('sourceFolder', 'anonymizedFolder', 3) % 'sub003' as ID
% 
% All three input argument are optional:
%  1. A dicom file name or a folder containing dicom files to anonymize.
%  2. A file name (single source file) or a folder to save the result file(s).
%  3. Starting subject ID to replace PatientName, default 'sub001'. This can be
%     numeric, like 3 which will be converted into 'sub003', or full string like
%     'subj_04' specifying both the prefix and starting ID number.
% 
% To avoid subject name confusion, this function replaces PatientName with an ID
% (third input argument). In case of multiple patients, the ID will be increased
% by 1 for each patient, and a file 'subjIDs_PatientNames.mat' will be saved
% into the source folder to indicate the correspondence between the original
% PatientName and assigned subject IDs.
% 
% See also DICM_HDR, SORT_DICM, RENAME_DICM, DICM2NII, DICM_SAVE

% 161226 Wrote it (xiangrui.li@gmail.com)
% 170103 Take care of confusion of multi-subjects; safer by using dicm tag.

% 3rd input can be either a number, or string like 'subj_001'
if nargin<3 || isempty(subID), subID = 'sub001'; end
if isnumeric(subID), subID = sprintf('sub%03g', subID); end
if ~isstrprop(subID(end), 'digit')
    error('subject ID must be a number or string in format of ''sub001''');
end
a = subID;
while ~all(isstrprop(a, 'digit'))
    ind = find(isstrprop(a, 'digit'), 1);
    a = a(ind:end);
end
iPN = str2double(a); % start ID number
n = numel(a);
idStr = [subID(1:numel(subID)-n) '%0' num2str(n) 'g']; % for sprintf

if nargin<1 || isempty(src)
    src = uigetdir(pwd, 'Select the folder containing dicom files');
    if isnumeric(src), return; end
end

if nargin<2 || isempty(rst)
    if isdir(src), def = src; else, def = fileparts(src); end %#ok<*ISDIR>
    if ~isdir(src) && (exist(src, 'file') || (iscell(src) && numel(src)==1))
        [rst, pth] = uiputfile([def filesep '*.dcm'], ...
            'Input file name to save the anonymized file');
        if isnumeric(rst), return; end
        rst = fullfile(pth, rst);
    else
        rst = uigetdir(def, 'Select or create a folder to save anonymized files');
        if isnumeric(rst), return; end
    end
end

if isdir(src)
    nams = dir(src);
    nams([nams.isdir]) = [];
    nams = {nams.name};
    nams = strcat(src, filesep, nams);
elseif ischar(src)
    nams = cellstr(src);
end
nFile = numel(nams);

dict = dicm_dict('', 'PatientName');
if nFile>1 && ~exist(rst, 'dir'), mkdir(rst); end
subjIDs = {}; PatientNames = {}; % for record keeping
for i = 1:nFile
    s = dicm_hdr(nams{i}, dict);
    if isempty(s), continue; end % not dicom
          
    if nFile == 1 % 2nd arg is file name
        nam = rst;
    else % 2nd arg is dir
        [~, nam, ext] = fileparts(s.Filename);
        nam = fullfile(rst, strcat(nam, ext));
    end
    
    try 
        pn = s.PatientName;
    catch % only a copy if no PatientName
        copyfile(s.Filename, nam, 'f');
        continue;
    end

    ip = strcmp(PatientNames, pn);
    if any(ip)
        subID = subjIDs{ip};
    else
        ip = numel(PatientNames) + 1;
        PatientNames{ip} = pn; %#ok<*AGROW>
        subID = sprintf(idStr, iPN+ip-1);
        if mod(numel(subID),2), subID(end+1) = char(0); end
        subjIDs{ip} = subID;
    end
    
    fid = fopen(s.Filename, 'r', 'l');
    b8 = fread(fid, inf, 'uint8=>uint8')';
    fclose(fid);
    
    try
        tsUID = s.TransferSyntaxUID;
        be = strcmp(tsUID, '1.2.840.10008.1.2.2');
        expl = ~strcmp(tsUID, '1.2.840.10008.1.2');
    catch
        be = false;
        expl = true;
    end
    if be, ed = 'b'; tag = char([0 16 0 16]); % '0010' '0010' 'PN' 'PatientName'
    else,  ed = 'l'; tag = char([16 0 16 0]); 
    end
    if expl, tag = [tag 'PN']; end
    try n = s.PixelData.Start; catch, n = s.FileSize; end
    i0 = strfind(char(b8(1:n)), tag);
    if isempty(i0) % almost impossible
        fprintf(2, 'Failed to locate PatitentName in %s\n', s.Filename);
        copyfile(s.Filename, nam, 'f');
        continue;
    end
    i0 = i0(1) + numel(tag);
    n = double(b8(i0+(0:1)));
    if be, n = n(1)*256 + n(2); else, n = n(2)*256 + n(1); end % uint16
    
    fid = fopen(nam, 'w', ed);
    fwrite(fid, b8(1:i0-1), 'uint8'); % till len
    fwrite(fid, numel(subID), 'uint16'); % len: endian related
    fwrite(fid, subID, 'char'); % ID
    fwrite(fid, b8(i0+2+n:end), 'uint8'); % skip len & PatientName
    fclose(fid);
end

if numel(subjIDs)<2, return; end
subjIDs = deblank(subjIDs); % remove padded null
matNam = fullfile(fileparts(nams{1}), 'subjIDs_PatientNames.mat');
try
    save(matNam, 'subjIDs', 'PatientNames');
catch me
    fprintf(2, '%s\n subjIDs_PatientNames saved into result folder.\n', me.message);
    matNam = fullfile(fileparts(nam), 'subjIDs_PatientNames.mat');
    save(matNam, 'subjIDs', 'PatientNames');    
end
