function varargout = sort_dicm(srcDir)
% Sort dicom files for different subjects into subject folders. 
% 
% subjects = SORT_DICM(dicmFolder);
% The optional input is the top folder containing dicom file and/or subfodlers
% which may contain dicom files and/or subfolders.
% 
% Optionally, it returns subfolder names for the dicom files.
% 
% It is suggested not to mix dicom files for different subjects into a folder.
% However if, for any reason, a folder contains dicom files for multiple
% subjects, this function will create a subfolder under the dicom folder for
% each subject, and move corresponding files into each subject folder. If a
% subject has more than one studies, each study will have a subfolder.
% 
% This function is kind of obsolete since later version of dicm2nii will convert
% files with more than one subjects.
% 
% See also DICM2NII, DICM_HDR, RENAME_DICM, ANONYMIZE_DICM

% History (yymmdd):
% 141016 Wrote it (Xiangrui Li).
% 141017 Take care of StudyID, return sub-folders.

if nargin<1 || isempty(srcDir)
    srcDir = uigetdir(pwd, 'Select a folder containing DICOM files');
    if ~ischar(srcDir), return; end % user cancelled
end
if ~exist(srcDir, 'dir'), error([srcDir ' not exists.']); end

dirs = genpath(srcDir);
dirs = textscan(dirs, '%s', 'Delimiter', pathsep);
dirs = dirs{1}; % cell str
fnames = {};
for i = 1:numel(dirs)
    curFolder = [dirs{i} filesep];
    foo = dir(curFolder); % all files and folders
    foo([foo.isdir]) = []; % remove folders
    foo = strcat(curFolder, {foo.name});
    fnames = [fnames foo]; %#ok<*AGROW>
end

dict = dicm_dict('', {'PatientName' 'PatientID' 'StudyID'});
h = struct;
n = numel(fnames);
nDicm = 0;
for i = 1:n
    s = dicm_hdr(fnames{i}, dict);
    if isempty(s), continue; end

    if isfield(s, 'PatientName'), subj = s.PatientName;
    elseif isfield(s, 'PatientID'), subj = s.PatientID;
    else, continue;
    end
    if ~isfield(s, 'StudyID'), s.StudyID = '1'; end
    
    P = genvarname(['P' subj]); %#ok<*DEPGENAM>
    if ~isfield(h, P), h.(P) = []; end
    S = genvarname(['S' s.StudyID]);
    if ~isfield(h.(P), S), h.(P).(S) = {}; end
    
    h.(P).(S){end+1} = s.Filename;
    nDicm = nDicm + 1;
end

sep = filesep;
folders = {};
subjs = fieldnames(h);
for i = 1:numel(subjs)
    sub = h.(subjs{i});
    S = fieldnames(sub);
    nS = numel(S);
    for j = 1:nS
        dstDir = [srcDir sep subjs{i}(2:end)];
        if nS>1, dstDir = [dstDir '_study' S{j}(2:end)]; end
        if ~exist(dstDir, 'dir'), mkdir(dstDir); end
        folders{end+1} = dstDir;
        
        for k = 1:numel(sub.(S{j}))
            fname = sub.(S{j}){k};
            [~, nam, ext] = fileparts(fname);
            dstName = [dstDir sep nam ext];
            if ~exist(dstName, 'file'), movefile(fname, dstName); end
        end
    end
end

if nargout
    varargout = {folders'};
else
    fprintf(' %g of %g files sorted into %g subfolders:\n', ...
        nDicm, n, numel(folders));
    fprintf('  %s\n', folders{:});
end
