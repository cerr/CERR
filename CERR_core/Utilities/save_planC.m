function planC = save_planC(planC,optS,saveflag,optFileName)
%"save_planC"
%   Saves plan using GUI interface.  Can either behave as Save or SaveAs,
%   where Save prompts to overwrite source planC file and SaveAs raises a
%   file location menu.  saveflag is either 'save' or 'saveas'.  If save is
%   called, the filename is assumed to be contained in stateS.CERRFile.
%
%   If 'save' is called, .bz2 files are automatically compressed and
%   replaced if they existed (assuming the user agrees when prompted).
%
%   If 'saveas' is called and a .bz2 file is specified, it is also
%   automatically compressed.  If a .mat file is specified, the user is
%   asked if compression is desired.
%
%     A.I. Blanco.
%LM:  14 Oct 02, JOD.
%     26 Jun 04, JRA, Added saveas/save distinction.
%     20 Jul 04, JRA, If saveas is used, now updates current file state.
%     20 Aug 04, JRA, Automatic compression if .bz2 file specified.
%     10 Sep 04, JRA, Now check for Matlab7 and saves according to optS.
%     27 Apr 05, JRA, Added tarball handling.
%     26 Jul 06, APA, Removed tarball handling since remote variables are
%     now stored in a subdirectory ...\.._store.
%     09 Jul 07, APA, Used Matlab's built-in tar function to tar CERR plan
%     and the remotely stored files.
%     17 Dec 07, APA, Added option to compress CERR plan using zip utility.
%     11 Jan 08, APA, (incorporated KU's changes) Fixed case where file could
%                     be overwritten without a warning if filename is entered
%                     without an extension. In case of error during save attempt
%                     (eg., permission denied), added ability to re-try.
%
%Usage:
%   zipped = save_planC(planC,optS, saveflag)
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.

global stateS

indexS = planC{end};

%Determine if we want 'save', or 'saveas...' behavior.
if ~exist('saveflag')
    saveflag = 'saveas';
elseif ~strcmpi(saveflag, 'save') & ~strcmpi(saveflag, 'saveas') & ~strcmpi(saveflag, 'passed')
    error('Incorrect call to save_planC.m');
end

%Store the revision and timeSaved into header of planC
planC = updateRevision(planC);

permission = 0;
while permission == 0   %Use while statement in case permission to overwrite file is denied.   KU 12/15/07
    %Acquire save filename according to saveFlag type.
    switch upper(saveflag)
        case 'SAVE'
            button = questdlg(['Are you sure you wish to save changes made to ' stateS.CERRFile ' ?'], 'Overwrite', 'Yes', 'No', 'No');
            if ~strcmpi(button, 'yes')
                CERRStatusString(['Save cancelled. Ready.']);
                return;
            end
            saveFile = stateS.CERRFile;

        case 'SAVEAS'

            deciding = 1;
            while deciding    %Use while statement in case filename is entered without an extension.   KU 12/8/07

                whichPlan = fliplr(strtok(fliplr(fileparts(char(planC{indexS.header}.archive))),'\/'));

                try
                    directory = fileparts(stateS.CERRFile);
                catch
                    directory = cd;
                end
                if isempty(directory)
                    directory = cd;
                end
                wd = cd;
                cd(directory);
                [fname pname] = uiputfile({'*.mat;*.mat.bz2;*mat.zip', 'CERR Plans (*.mat, *.mat.bz2, *.mat.zip)';'*.*', 'All Files (*.*)'},['Save the ' whichPlan ' data as:']);
                cd(wd);
                if isequal(fname,0) | isequal(pname,0)
                    CERRStatusString('Save cancelled. Ready.');
                    return;
                end
                if ~isempty(strfind(fname,'.'))
                    saveFile = fullfile(pname,fname);
                    deciding = 0;
                else     %in case filename is entered without an extension.   KU 12/8/07
                    fname = [fname,'.mat'];
                    list = dir(fullfile(pname, '*.*'));
                    match = 0;
                    for i = 1:size(list,1)
                        if list(i).isdir==0 && strcmpi(fname, list(i).name)
                            match = 1;
                            button = questdlg([[pname fname],' already exists! Do you want to replace it?'],'Save file as?','yes','no','no');
                            if strcmpi(button, 'yes')
                                saveFile = fullfile(pname,fname);
                                deciding = 0;
                                break
                            end
                        end
                    end

                    if match == 0
                        saveFile = fullfile(pname,fname);
                        deciding = 0;
                    end
                end
            end

            %get storage directory for remote variables in the original plan
            remotePath = [];
            if isfield(stateS,'CERRFile') && ~isempty(stateS.CERRFile)
                [pathstr, name, ext] = fileparts(stateS.CERRFile);
                remotePath = fullfile(pathstr,[name,'_store']);
            end

        case 'PASSED'
            saveFile = optFileName;
    end

    %Add .mat if required, parse other valid extensions if they exist.  If
    %invalid extensions exist, they are considered part of the root filename
    %and proper extensions are appended to them.
    [ext, roots] = getFileExtensions(saveFile);
    if ~isempty(ext)
        if strcmpi(ext(1), '.mat')
            zipFile     = 0;
            saveFile    = [roots{1} '.mat'];
        elseif length(ext) > 2 & strcmpi(ext(1), '.tar') & (strcmpi(ext(2), '.bz2') || strcmpi(ext(2), '.zip')) & strcmpi(ext(3), '.mat')
            zipFile     = 1;
            saveFile    = [roots{3} '.mat'];
        elseif length(ext) > 1 & (strcmpi(ext(1), '.bz2') || strcmpi(ext(1), '.zip'))& strcmpi(ext(2), '.mat')
            zipFile     = 1;
            saveFile    = [roots{2} '.mat'];
        else
            saveFile    = [saveFile '.mat'];
            zipFile     = 0;
        end
    else
        saveFile    = [saveFile '.mat'];
        zipFile     = 0;
    end

    %Zip if required, prompting if saveAs w/o .bz2 suffix specified.
    if zipFile
        ans = 'yes';
        %[jnk1,jnk2,ext] = fileparts(stateS.CERRFile);
        %if ~strcmpi(ext,'bz2') || ~strcmpi(ext,'zip')
        extSave = ext;
        indMat = strmatch('.mat',extSave);
        extSave(indMat) = [];
        extSave = extSave{1};
        if ~strcmpi(extSave,'bz2') || ~strcmpi(extSave,'zip')
            if ~isfield(stateS,'optS')
                stateS.optS = CERROptions;
            end
            extSave = stateS.optS.CompressType;
        end
    elseif ~zipFile & strcmpi(saveflag, 'passed')
        ans = 'no';
    elseif ~zipFile & strcmpi(saveflag, 'saveas')
        ans = questdlg('Zip the .mat file using bz2/zip?');
        if ~isfield(stateS,'optS')
            stateS.optS = CERROptions;
        end
        extSave = stateS.optS.CompressType;
    else
        ans = 'no';
    end

    if strcmpi(ans,'yes')
        zipFile = 1;
    end
    %Save the planC to the specified file.
    try
        [saveFile, planC] = writeToDisk(planC, saveFile, zipFile);
        permission = 1;
    catch
        h = warndlg(lasterr,'Error Saving File!','modal');
        uiwait(h);
    end
end

%Remind CERR where the current file is, in case of filename change.
stateS.CERRFile = saveFile;

[pathstr, name, ext] = fileparts(stateS.CERRFile);
switch lower(ans)
    case 'yes'
        if strcmpi(extSave,'bz2')
            CERRStatusString(['Compressing ' saveFile '...']);
            outstr = gnuCERRCompression(saveFile,'compress');
            if (~ischar(outstr)) % Function returned as zero when compression complete
                errordlg('File not found by compression routine.', 'CERR compression');
                return;
            else
                stateS.CERRFile = [saveFile '.bz2'];
            end
        elseif strcmpi(extSave,'zip')
            zip(saveFile,saveFile)
            delete(saveFile)
            stateS.CERRFile = [saveFile '.zip'];
        end
        if exist(fullfile(pathstr,[name,'_store']))==7
            copyfile(fullfile(pathstr,[name,'_store']),fullfile(pathstr,[name,'.mat_store']),'f')
            allFiles = what(fullfile(pathstr,[name,'_store']));
            for i=1:length(allFiles.mat)
                delete(fullfile(pathstr,[name,'_store'],allFiles.mat{i}))
            end
            rmdir(fullfile(pathstr,[name,'_store']))
            [planC, stateS] = updateRemotePaths(planC, stateS, stateS.CERRFile);
        end
end

%tar the files if required
if isfield(stateS,'reqdRemoteFiles') && ~isempty(stateS.reqdRemoteFiles)
    filesToTar = stateS.reqdRemoteFiles;
    if ~isempty(filesToTar)
        dirToTar = fileparts(filesToTar{1});
    end
    %filesToTar{end+1} = stateS.CERRFile;
    tar([stateS.CERRFile,'.tar'],{dirToTar stateS.CERRFile})
    %delete the .mat or .bz2 file since it is in tarred format now
    delete(stateS.CERRFile)
else
    %delete the tar file since no remote files exist
    if exist([stateS.CERRFile,'.tar'],'file')
        try, delete([stateS.CERRFile,'.tar']), end
    end
end

if strcmpi(saveflag,'SAVEAS')
    try, rmdir(remotePath,'s'), end
end

CERRStatusString(['Saved ' name ext '. Ready. (' datestr(now) ')']);

try
    stateS.planMerged = 0;
end

function [saveFile, planC] = writeToDisk(planC, saveFile, zipFile)
%"writeToDisk"
%   Save the planC to disk.  If remote variables exist, handle them.

global stateS
if iscell(planC)
    indexS = planC{end};
end

%Get a list of remote variable files using the save flag to store.
% remoteFiles = listRemoteFiles(planC, 0);
remoteFiles = listRemoteScanAndDose(planC);

%Prepare a list of files that will be added to _store directory.
filesLocal = [];
remoteFullFile = {};
for i = 1:length(remoteFiles)
    switch upper(remoteFiles(i).storageType)
        case {'LOCAL'}
            remotePathLocal{i} = remoteFiles(i).remotePath;
            filesLocal{i} = remoteFiles(i).filename;
            remoteFullFile{i} = fullfile(remotePathLocal{i},filesLocal{i});
    end
end

[pathstr, name, ext] = fileparts(saveFile);
CERRStatusString(['Saving ' name ext '...']);

% save Remotely stored files

if zipFile
    name = [name '.mat'];
end
if length(filesLocal)>0 & ~exist(fullfile(pathstr,[name,'_store']))
    mkdir(fullfile(pathstr,[name,'_store']))
elseif length(filesLocal) < 1
    try
        rmdir(remotePathLocal)
    end
end

for i = 1:length(filesLocal)
    if ~isequal(remoteFullFile{i},fullfile(pathstr,[name,'_store'],filesLocal{i}))
        copyfile(remoteFullFile{i},fullfile(pathstr,[name,'_store'],filesLocal{i}))
    end
end

% delete unnecessary remote files in original plan that were created
% temporarily
for i = 1:length(remoteFullFile)
    if isfield(stateS,'reqdRemoteFiles') && ~ismember(remoteFullFile{i},stateS.reqdRemoteFiles) && ~isequal(fileparts(remoteFullFile{i}),fullfile(pathstr,[name,'_store']))
        delete(remoteFullFile{i})
    end
end

%delete unnecessary remote files in original plan that changed
if ~isempty(stateS) & isfield(stateS,'reqdRemoteFiles')
    for i = 1:length(stateS.reqdRemoteFiles)
        if ~ismember(stateS.reqdRemoteFiles(i),remoteFullFile) & isequal(fileparts(stateS.reqdRemoteFiles{i}),fullfile(pathstr,[name,'_store']))
            delete(stateS.reqdRemoteFiles{i})
        end
    end
end

[planC, stateS] = updateRemotePaths(planC, stateS, saveFile, zipFile);

%Save functions... modified to work with matlab 7
saveOpt = getSaveInfo;
if ~isempty(saveOpt);
    save(saveFile, 'planC', saveOpt);
else
    save(saveFile, 'planC');
end

function [ext, root] = getFileExtensions(filename)
%"getFileExtensions"
%   Returns the file extensions of filename, each in an individual cell, in
%   reverse order.  Also returns the root filename strings for each
%   iteration of the while loop.

ext  = {};
root = {};

[pathstr,fname,fext] = fileparts(filename);
while ~isempty(fext)
    ext{end+1} = fext;
    root{end+1} = fullfile(pathstr, fname);
    [pathstr,fname,fext] = fileparts(fullfile(pathstr, fname));
end

function [planC, stateS] = updateRemotePaths(planC, stateS, saveFile, zipFile)
%"updateRemotePaths"
% update remote path in planC for remote doseArrays and scanArrays. Also
% update fullFiles in stateS

if iscell(planC)
    indexS = planC{end};
else
    return;
end

if ~exist('zipFile')
    zipFile = 0;
end
[pathstr, name, ext] = fileparts(saveFile);
if zipFile
    name = [name '.mat'];
end

stateS.reqdRemoteFiles = {};
for i = 1:length(planC{indexS.scan})
    if ~isLocal(planC{indexS.scan}(i).scanArray)
        planC{indexS.scan}(i).scanArray.remotePath = fullfile(pathstr,[name,'_store']);
        stateS.reqdRemoteFiles{end+1} = fullfile(pathstr,[name,'_store'],planC{indexS.scan}(i).scanArray.filename);
        planC{indexS.scan}(i).scanArraySuperior.remotePath = fullfile(pathstr,[name,'_store']);
        stateS.reqdRemoteFiles{end+1} = fullfile(pathstr,[name,'_store'],planC{indexS.scan}(i).scanArraySuperior.filename);
        planC{indexS.scan}(i).scanArrayInferior.remotePath = fullfile(pathstr,[name,'_store']);
        stateS.reqdRemoteFiles{end+1} = fullfile(pathstr,[name,'_store'],planC{indexS.scan}(i).scanArrayInferior.filename);
    end
end
for i = 1:length(planC{indexS.dose})
    if ~isLocal(planC{indexS.dose}(i).doseArray)
        planC{indexS.dose}(i).doseArray.remotePath = fullfile(pathstr,[name,'_store']);
        stateS.reqdRemoteFiles{end+1} = fullfile(pathstr,[name,'_store'],planC{indexS.dose}(i).doseArray.filename);
    end
end


for i = 1:length(planC{indexS.IM})
    if ~isempty(planC{indexS.IM}(i).IMDosimetry.beams) && ~isLocal(planC{indexS.IM}(i).IMDosimetry.beams(1).beamlets)
        for iBeam = 1:length(planC{indexS.IM}(i).IMDosimetry.beams)            
            planC{indexS.IM}(i).IMDosimetry.beams(iBeam).beamlets.remotePath = fullfile(pathstr,[name,'_store']);
            stateS.reqdRemoteFiles{end+1} = fullfile(pathstr,[name,'_store'],planC{indexS.IM}(i).IMDosimetry.beams(iBeam).beamlets.filename);                        
        end
    end
end


