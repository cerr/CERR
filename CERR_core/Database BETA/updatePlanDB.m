function planDB = updatePlanDB(planDB, varargin)
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
%
%"updatePlanDB"
%   Sync the plan database with contents of <path> and its subdirs.
%
%   Given a planDB (or [] if a new planDB is being created), scan <path>
%   and all subdirectories for .mat/.mat.bz2 files. If .mat files are encountered
%   that did not exist in the planDB or have been modified since the last
%   update, load them and attempt to compile a planC extract.  If files
%   exist in planDB that do not exist in <path>, flag them as not present.
%   .mat files that do not contain planCs have an extract of [] and their
%   isPlanC field is set to 0.
%
%   If a user defined function handle @<fcnName> has been specified,
%   it is executed by passing planC as the only parameter.  Output is
%   stored in the userdata field.  The 'userfiles' field is a list of
%   filenames that, if changed, require the database to recompile. This
%   should be the file(s) containing <fcnName> and its child functions.
%
%   planDB parameters 'path', 'template' and 'function' are stored in the 
%   planDB and only need to be referenced after the first update if they
%   need to be changed.
%
%   JRA 11/28/03
%
%  To make new DB:     
%     planDB = updateplanDB([],'path', <path>, 'template', makeTemplate, 'addfunction', @<fcnName>, <full path to function file>)
%  Update existing: 
%     planDB = updateplanDB(planDB);
%  Update for new template:
%     planDB = updateplanDB(planDB, 'template', makeTemplate);

% Steps to update the database:
%    1. Parse Input Arguments        - gives path, template, and ufs
%    2. Check validity of plan path      
%    3. Scan HD path for plans.

%    4. Compare found plans to stored plans:
%         i. add new plans -- keep index of new plans
%         ii. flag missing files -- keep index of missing 
%         iii. flag changed files as needing update -- keep index.
%         iv. leave unchanged files alone          
%    
%    4. check for a template change: if changed, flag all plans to get new template.               
%         
%    3. Update ufs
%     i. Remove deleted ufs
%     ii. add new userfunctions
%     iii. for functions that must be recalced this run flag all plans to get recalc.
%       
% 
%    5. loop over plans, loading if user or template.  calc necessary stuff. Update plan timestamp at load time.

%Start timer.
updateStartTime = datestr(now);

%Check arguments.  If no args, use the internal template and path.
[path, template, userfuncts, reusePlanC] = evaluateArgs(planDB, nargin, varargin);

%Check validity of path.
if ~isdir(path)
    disp(['planDB>> ''' path ''' does not exist. All files will be flagged not present.']);
    %No matfiles exist, create empty struct.
    matFiles = struct('name', {}, 'path', {}, 'lastMod', {});
else
	%Find all the .mat and .mat.bz2 files in path.
	disp(['planDB>> Searching for .mat & .mat.bz2 files in ' path]);    
	matFiles = findMatFiles(path);   
    disp(['planDB>> Found ' num2str(length(matFiles)) ' .mat and .mat.bz2 files.']);
end

%Get list of archived files, get list of files found in HD scan.
[storedFileNames, presentFileNames, planDB] = getFilenameList(planDB, matFiles);

%Find indices of new files, removed files.
[newFiles newIndex] = setdiff(presentFileNames, storedFileNames);
[removedFiles removedIndex] = setdiff(storedFileNames, presentFileNames);

%Add the new files to the planDB.
disp(['planDB>> ADDING ' num2str(length(newIndex)) ' new files.']);
for i=1:length(newIndex)
    plan.extract = [];
    plan.userdata = [];
    plan.info.name = matFiles(newIndex(i)).name;
    plan.info.path = matFiles(newIndex(i)).path;
    %Leave lastMod empty so these matFiles will be updated.
    plan.info.lastMod = '';
    plan.isPlanC = [];
    plan.isPresent = 1;
    planDB.matFiles(end+1) = plan;
end

%set isPresent flag for files that no longer exist, do not remove from db.
disp(['planDB>> FLAGGING ' num2str(length(removedIndex)) ' files as missing.']);
for i=1:length(removedIndex)
    planDB.matFiles(removedIndex(i)).isPresent = 0;
end

%Refresh lists.
[storedFileNames, presentFileNames, planDB] = getFilenameList(planDB, matFiles);



%Find indices of files already existing in the database.
storedPlanInfo = [planDB.matFiles.info];
[bool, ind] = ismember(storedFileNames, presentFileNames);

ind(ind==0) = [];

%Flag modified or new files for updating.
needsFullUpdate = ~strcmp({storedPlanInfo(bool).lastMod}, {matFiles(ind).lastMod});

%set isPresent flag for all found files.
presentFiles = find(bool);
disp(['planDB>> FLAGGING ' num2str(length(presentFiles)) ' files as present.']);
for i=1:length(presentFiles)
    planDB.matFiles(presentFiles(i)).isPresent = 1;
end

%We have a fully updated file list in planDB, and a list of flags to indicate which files
%have changed or been added at this point in needsFullUpdate.

%Find which userfunctions have changed or been added, and need calculation.
[ufChanged, planDB] = userFilesChanged(planDB, userfuncts);
changed = find(ufChanged);

%Some output statements for the kids.
if ~isempty(changed)
    string = [];
    for i = 1:length(changed)
        string = [string ' ' planDB.userfunctions(changed(i)).fHandle];
    end
    if length(changed) == 1
        plural = '';
        verb = ' is';
    else
        plural = 's';
        verb = ' are';
    end
    disp(['planDB>> User function' plural string verb ' new or changed and requires calculation.']);
end

%Create a boolean matrix where each row is a plan and each column a
%userfunction.  If userfunction 3 for matFile 5 is true, calculate that
%user function for matFile 5.  New user functions are flagged true for all
%plans, as all plans need this new function calculated.  For new or changed
%plans, flag all userfunctions as needing calculation.
refreshUD = repmat(ufChanged, length(planDB.matFiles), 1);
refreshUD(needsFullUpdate,:) = 1;

%Create a similar boolean vector to refresh template.
refreshTemplate = zeros(length(planDB.matFiles), 1);
refreshTemplate(needsFullUpdate) = 1;
   
%If template has changed, all plans need template refreshed.
if isfield(planDB, 'template')
	templateExpired = ~isempty(setxor(template, planDB.template));
else
    templateExpired = 1;
end
if templateExpired
    planDB.template = template;
    refreshTemplate = ones(length(planDB.matFiles),1);
end
    

%Now iterate over all files in planDB.matFiles.  If a matFile is a plan,
%check if it requires its extract or any userfunctions to be recalculated
%by looking at refreshTemplate and refreshUD.  If so, load the plan and
%calculate only what needs refreshing.
for i=1:length(planDB.matFiles)
    plan = planDB.matFiles(i);
    if plan.isPresent
        %If any changes, load the plan.   
        fullfilename = fullfile(planDB.matFiles(i).info.path,planDB.matFiles(i).info.name);
        if any([refreshTemplate(i) refreshUD(i,:)])
            disp(['planDB>> UPDATE ' planDB.matFiles(i).info.name]);
            
            tic
            if reusePlanC
                global planC
            end
            planC = loadPlan(fullfilename);                
            disp(['      >> Loaded in ' num2str(toc) 's']);    
        end

        if refreshTemplate(i)
            tic
            plan.extract = compileExtract(planC, template);
            disp(['      >> Extracted in ' num2str(toc) 's']);
        end                  
        
        for j=1:size(refreshUD, 2)  
            if refreshUD(i, j)
                tic
                plan.userdata{j} = compileUser(planC, str2func(planDB.userfunctions(j).fHandle));
                disp(['      >> User function ' planDB.userfunctions(j).fHandle ' run in ' num2str(toc) 's']);
            end
        end       
        info = dir(fullfilename);
        %Set timestamp to detect future modifications.
        plan.info.lastMod = info.date;
        %If no extract, file is not a planC.
        plan.isPlanC = ~isempty(plan.extract);
        planDB.matFiles(i) = plan;
    end
end

%PlanDB is now fully updated.  Stamp.
updateEndTime = datestr(now);

planDB.lastUpdateStart = updateStartTime;
planDB.lastUpdateEnd = updateEndTime;
planDB.template = template;
planDB.path = path;

%Build the index of fieldnames into plans, for database browsing.
planDB.fieldIndex = compileFieldnameIndex(planDB.matFiles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function extract = compileExtract(planC, template)
%Make an extract out of the planC if it is not [].
if isempty(planC)
   extract = [];
   return;
else
   extract = makeExtract(planC, template);    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function userdata = compileUser(planC, fHandle);
%Run user function if it exists, store returend data.
if isempty(fHandle) | isempty(planC)
    userdata = [];
    return;
else
    userdata = feval(fHandle, planC);    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function planC = loadPlan(filename)
%Load the .mat file and check if a planC exists in the workspace.
%If it does, return planC, else return [].  Also handles .bz2 by extracting
%to a tempfile in the tempDirectory and deleting when finished.
compressed = 0;

oldPathStr = pwd;
newPathStr = getCERRPath;

if strcmpi(filename(end-3:end), '.bz2')    
    %Is compressed.  Decompress and load. LEAVE original file.
    cd(newPathStr);
    cd('Compression'); 
    compressed = 1;
    tempFile = fullfile(tempdir, 'temp.mat');
    if ispc
        dos(['bzip2-102-x86-win32.exe -vdkc "', filename, '">> ' tempFile]);
    elseif isunix
        unix(['bzip2 -dck ', filename, ' > ' tempFile]);
    end
    filename = tempFile;
    cd(oldPathStr);
end

clear planC;
try
    load(filename);
catch
    planC = []; %fileload has failed. return.   
    return;
end

if compressed
    try
        delete(tempFile);
    end
end

if ~exist('planC')
    planC = [];
    return;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [path, template, userfunctions, reusePlanC] = evaluateArgs(planDB, nargs, vargs)
% Evaluated passed arguments, returning parameters needed to run update.
ufs = [];
oldfHandle = 0;

%Grab old values if they exist.
try,    path        = planDB.path;                 ,end
try,    template    = planDB.template;             ,end
try,    ufs         = planDB.userfunctions;        ,end

reusePlanC = 0;

i = 1;
while i <= nargs-1
    switch vargs{i}
        case 'path'
            %Overwrite path if a new one is specified.
            path = vargs{i+1};
            i = i + 2;
        case 'template'
            %Overwrite template if a new one is specified.
            template = vargs{i+1};
            i = i + 2;
        case 'delfunction'
            %Scrap the specified user function.
            [jnk, ind] = intersect({ufs.fHandle} , func2str(vargs{i+1}));
            ufs(ind) = [];
            i = i + 2;
        case 'addfunction'
            %Add the new user function and userfiles list.
            
            %First check if it already exists.
            if isfield(ufs, 'fHandle')
                [jnk, ind] = intersect({ufs.fHandle} , func2str(vargs{i+1}));
            else
                jnk = [];
            end
            if ~isempty(jnk)
                warning(['User function ' func2str(vargs{i+1}) ' already exists. Overwriting old associated userfiles.']);
            else
                ind = length(ufs) + 1;
            end
            ufs(ind).fHandle = func2str(vargs{i+1});
            ufs(ind).files = vargs{i+2};
            if ~iscell(ufs(ind).files)
                ufs(ind).files = {ufs(ind).files};
            end
            ufs(ind).date = [];
            i = i + 3;
        case 'reusePlanC'
            i = i + 1;
            reusePlanC = 1;
        otherwise
            error('Invalid Call');
    end       
end    
userfunctions = ufs;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [storedFileNames, presentFileNames, planDB] = getFilenameList(planDB, matFiles);
%Returns a list of matfiles on the local HD and a list of matfiles stored in the planDB
if ~isempty(planDB) & isfield(planDB, 'matFiles')
	for i=1:length(planDB.matFiles)
        storedFileNames{i} = fullfile(planDB.matFiles(i).info.path, planDB.matFiles(i).info.name);
	end
else
    planDB.matFiles = struct('extract', {}, 'userdata', {}, 'info', {}, 'isPlanC', {}, 'isPresent', {});
    storedFileNames = {};    
end
for i=1:length(matFiles)
    presentFileNames{i} = fullfile(matFiles(i).path,matFiles(i).name);
end
%Filenames/directories are caps insensitive and caps inconsistent on pc.
%Uppercase them for purposes of name comparison.
if (ispc)
    presentFileNames = upper(presentFileNames);
    storedFileNames = upper(storedFileNames);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [changed, planDB] = userFilesChanged(planDB, userfuncts)
%Returns a vector of userFile sets that have been modified. Also returns planDB with
%the userfiletime field changed.

%Array of flags to indicate if any userfiles have changed.
changed = zeros(1,length(userfuncts));

if isfield(planDB, 'userfunctions')   
    oldFuncts = planDB.userfunctions;
    
    %Get indices of userfunctions that has been removed.
    [diff,ind] = setdiff({planDB.userfunctions.fHandle}, {userfuncts.fHandle});
    
    %Delete old userdata.
    for i=1:length(planDB.matFiles)
        planDB.matFiles(i).userdata(ind) = [];
    end
    planDB.userfunctions(ind) = [];
    
    %Get indices of new userfunctions, add to planDB.
    [newDiff, newInd] = setdiff({userfuncts.fHandle}, {planDB.userfunctions.fHandle});
    planDB.userfunctions(end+1:end+length(newDiff)) = userfuncts(newInd);
    
    %Flag these new userfuncs as needing calculation.
    [diff,ind] = setdiff({planDB.userfunctions.fHandle}, {userfuncts.fHandle});
    changed(ind) = 1;
else    
    %All userfunctions are new, update all.
    planDB.userfunctions = userfuncts;
    changed = ones(1,length(userfuncts));       
end

%Check and update userfile timestamps
for j = 1:length(planDB.userfunctions)
    files = planDB.userfunctions(j).files;       
	fileInfo = struct('name', {}, 'date', {}, 'bytes', {}, 'isdir', {});
    
	for i=1:length(files)
        fileInfo(end+1) = dir(files{i});
	end
	
	%Has file list changed? If so flag as needing recalculation.
	if ~isfield(planDB.userfunctions, 'files') | ~isfield(planDB.userfunctions, 'date')
        changed(j) = 1;
    elseif ~isequal(length(files), length(planDB.userfunctions(j).files))
        changed(j) = 1;
	elseif ~isempty(setxor(files, planDB.userfunctions(j).files))
        changed(j) = 1;
	elseif ~isequal({fileInfo.date}, planDB.userfunctions(j).date)
        changed(j) = 1;
	end
	
    %Save current timestamp info.
	if changed(j)
        files = files;
        planDB.userfunctions(j).date = {fileInfo.date};
    end
    
end