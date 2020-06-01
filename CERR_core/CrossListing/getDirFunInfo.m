function getDirFunInfo(outputFileName, incSubdirs, category, path)
% function getDirFunInfo(outputFileName, incSubdirs, category, pathOrMFilesC)
% Prints information about functions to 'outputFileName'.txt
% (the '.txt' is added if not already included in input.)
% If not specified, output file is placed in the current working directory.
%
% For each function and subfunction in each m-file in the input directory,
% this information is provided:
%    Function name
%    Path
%    Date last modified
%    If the m-file has an associated mec file
%    Subfunction/Not a subfunction
%    Description
%    Functions this function is called by (and path and path of calling function)
%    Functions this function calls (and path of called function)
%    Global variables and line numbers
%    Local variables and line numbers
%
%
% >> incSubdirs is a string containing either 'y' or 'n'.
%     If 'y', then functions in subdirectories will be included as well.
% >> 'category' is a string labeling the function information.
% >> pathOrMFilesC may be: a string with the directory of the information desired.
%     NOTE: the directory (and subdirectories if included) must be on the search path.
%           -If any function names are identical to those in other directories (they are not uniquely named),
%           then THE RELEVANT DIRECTORY (AND SUBDIRECTORIES) MUST BE FIRST ON THE MATLAB SEARCH PATH.
% >> pathOrMFilesC may also be: a cell containing strings with the names of
%                               m-files for which info is desired.
%
%   EXAMPLE USES:
%     >>  using pathOrMFilesC as a path:
%           getDirFunInfo('outputFileName', 'y', 'My Files', 'C:\directory')
%           getDirFunInfo('outputFileName.txt', 'y', 'My Files', 'C:\directory')
%           getDirFunInfo('C:\outputDirectory\outputFileName', 'n', 'Title of Category', 'C:\dir\dir2')
%
%     >>  using pathOrMFilesC as a cell:
%           getDirFunInfo('outputFileName', 'y', 'My Files', {'mfile1','mfile2.m','C:\mfile3'})
%           getDirFunInfo('outputFileName.txt', 'y', 'My Files', {'mfile1','mfile2.m','C:\mfile3'})
%           getDirFunInfo('C:\outputDirectory\outputFileName', 'n', 'Title of Category', {'mfile1','mfile2.m','C:\mfile3'})
%
% Caveats:
%   -If functions and variables used in the m-files have the same name, results will
%      probably not be accurate.
%   -Assumes file has this format:  function name on top line, all comments or spaces on
%      the next lines, and then global variable declarations on the first lines after that.
%   -The list of line numbers for the output variables of the function does not include line 1.
%   -Field names accessed by means of  brackets or parentheses will not appear in the variable
%      listing, although the variables to the left of the '.' will be listed.
%   -If function names are not entirely unique, the relevant directory (and subdirectories, if applicable)
%      must be FIRST on the Matlab search path.
% Created by Vanessa Clark and Joseph Deasy, 6/12/02.
%Latest Modifications:  30 dec 02, JOD.
%                       22 dec 05, APA: Added subscript L,R to variable
%                       line number to tell if that variable is
%                       assigned a value or vice versa. Subscript ? added
%                       to a variable line number indicates multiple
%                       occurances of the variable on that line.
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


global callsM calledByM fileNameC
callsM = [];
calledByM = [];
fileNameC = {};

if iscell(path)
    mfilesC = path;
else

    mfilesC = {};
    subdirNamesC = {};

    mfilesC = addMFiles(mfilesC, path);


    if strcmp(incSubdirs, 'y') % now get the subdirectories if desired
        subdirNamesC = addSubdirs(subdirNamesC, path);
        while ~isempty(subdirNamesC)
            path = subdirNamesC{1};
            subdirNamesC = subdirNamesC(2:end);
            mfilesC = addMFiles(mfilesC, path);
            subdirNamesC = addSubdirs(subdirNamesC, path);
        end
    elseif ~strcmp(incSubdirs, 'n')
        error(['incSubdirs needs to be in the format ''n'' or ''y''.']);
    end

end
if isempty(mfilesC)
    warning(['No output file created.  Directory or cell ' path ' is empty.']);
else
    printFunctionInfo(outputFileName, mfilesC, category);
end

return

%------------------------------------------------
function mfilesC = addMFiles(mfilesCinput, path)

newFileNamesC = {};

whatInfo = what(path);
for i = 1:length(whatInfo.m)
    newFileNamesC = {newFileNamesC{:}, fullfile(path, whatInfo.m{i})};
end

mfilesC = {mfilesCinput{:}, newFileNamesC{:}};

return
%------------------------------------------------
function subdirNamesC = addSubdirs(subdirNamesCinput, path)
subdirNamesC = subdirNamesCinput;
dirInfo = dir(path);

indexToRemove = find(strcmpi({dirInfo.name}, '.'));
dirInfo(indexToRemove) = [];
indexToRemove = find(strcmpi({dirInfo.name}, '..'));
dirInfo(indexToRemove) = [];

for i=1:length(dirInfo) % skip first 2 (they are '.' and '..')
    if dirInfo(i).isdir
        subdirNamesC = {subdirNamesC{:}, fullfile(path, dirInfo(i).name)};
    end
end
return

%---------------------------------------------------------------------------------------------------------
function printFunctionInfo(outputFileName, mfilesC, categoryStr)
% function printFunctionInfo(outputFileName, mfilesC, categoryStr)
%
% puts all function information into a file named 'outputFileName'.m
% Information is gathered from each file named in the mfilesC cell and subfunctions.
% categoryStr is a string that provides information for the title in the file.
%
%   EXAMPLE USES:
%       printFunctionInfo('output.txt', {'mfile1','mfile2.m','C:\mfile3'}, 'My Files')
%       printFunctionInfo('C:\dir\output', {'mfile1','mfile2.m','C:\mfile3'}, 'My Category for Files')
%
% info includes:
% function name, path, last date modified, (sub)function,
% called by, calls, global variables, local variables.
%
% Vanessa Clark, 6/12/02


% get file path, whether passed into the function already or not:
if ~isempty(strfind(outputFileName,'\')) || ~isempty(strfind(outputFileName,'/'))
    str = outputFileName;
else
    s = what;
    str = fullfile(s.path, outputFileName);
end

%add '.txt' if it's not already there:
if ~(length(str)>3 & strcmp(str(end-3:end),'.txt'))
    str = [str '.txt'];
end




%str = which(outputFileName);
fid = fopen(str,'w');
tmpstr=['Information About Functions in the Category "' categoryStr '"'];
fwrite(fid,tmpstr,'char');
fprintf(fid,'\n',[]);
fprintf(fid,'\n',[]);
tmpstr=['----------------------------------------------------------------------'];
fwrite(fid,tmpstr,'char');
fprintf(fid,'\n',[]);
fprintf(fid,'\n',[]);

j=1;
for i = 1:length(mfilesC)
    allData{1,j} = mfilesC{i};
    disp(mfilesC{i});
    [allData{2,j}, subData] = getFunctionInfo(mfilesC{i});
    j=j+1;
    for k = 1:length(subData)
        allData{1,j} = subData{k}{6};
        allData{2,j} = subData{k};
        j = j+1;
    end
end

finalData = getAllFunctionInfo(allData);


% now that we have almost all the data, we need to print it out:
for i = 1:size(finalData,2)

    % finish getting rest of data:

    % Get date last modified ...
    dirInfo = dir(finalData{2,i}{7});
    date{i} = dirInfo.date;
    % ... Done getting date last modified.

    % now print it all out:

    tmpstr=['Function name:  ' finalData{2,i}{6}];
    fwrite(fid,tmpstr,'char');
    fprintf(fid,'\n',[]);

    tmpstr=['    Path:  ' finalData{2,i}{7}];
    fwrite(fid,tmpstr,'char');
    fprintf(fid,'\n',[]);

    tmpstr=['    Last Modified:  ' date{i}];
    fwrite(fid,tmpstr,'char');
    fprintf(fid,'\n',[]);

    %check to see if it has an associated mex file:
    fileNameStem = [finalData{2,i}{7}(1:end-2)];
    if exist(fileNameStem)==3
        tmpstr=['    Has an associated mex file.'];
        fwrite(fid,tmpstr,'char');
        fprintf(fid,'\n',[]);
    end

    tmpstr=['    '];
    fwrite(fid,tmpstr,'char');
    if strncmp(finalData{2,i}{1}, 'subfunction',11)
        tmpstr=['S' finalData{2,i}{1}(2:end) '.'];
        fwrite(fid,tmpstr,'char');
        fprintf(fid,'\n',[]);

    else
        tmpstr=['Not a subfunction.'];
        fwrite(fid,tmpstr,'char');
        fprintf(fid,'\n',[]);

    end

    tmpstr=['Description:  '];
    fwrite(fid,tmpstr,'char');
    fprintf(fid,'\n',[]);

    tmpstr=['~~~~~~~~~~~'];
    fwrite(fid,tmpstr,'char');
    fprintf(fid,'\n',[]);

    tmpstr=['Function header line:  '];
    fwrite(fid,tmpstr,'char');
    %fprintf(fid,'\n',[]);

    %print first line (function line):
    try % in case there is no function line
        tmpstr=[finalData{2,i}{8}{1}(1:end)];
        fwrite(fid,tmpstr,'char');
        fprintf(fid,'\n',[]);
        %if the function line extends for more than one line:
        k = 2;
        while length(finalData{2,i}{8})>=k & ~isempty(finalData{2,i}{8}{k}) & ~strcmp(finalData{2,i}{8}{k}(1),'%')
            tmpstr=['                       ' finalData{2,i}{8}{k}(1:end)];
            fwrite(fid,tmpstr,'char');
            fprintf(fid,'\n',[]);
            k=k+1;
        end

    catch % just don't print it
        tmpstr='{None}';
        fwrite(fid,tmpstr,'char');
        fprintf(fid,'\n',[]);
    end

    % print help data (in finalData{2,i}(8))
    for j = k:length(finalData{2,i}{8})
        tmpstr=['    ' finalData{2,i}{8}{j}(1:end)];
        fwrite(fid,tmpstr,'char');
        fprintf(fid,'\n',[]);
    end


    %tmpstr=help(finalData{2,i}{7});
    %fwrite(fid,tmpstr,'char');

    tmpstr=['~~~~~~~~~~~'];
    fwrite(fid,tmpstr,'char');
    fprintf(fid,'\n',[]);

    fprintf(fid,'\n',[]);
    tmpstr=['Called by:'];
    fwrite(fid,tmpstr,'char');
    fprintf(fid,'\n',[]);

    printFunList(finalData{2,i}{2}, 'Path', fid);
    
    fprintf(fid,'\n',[]);
    tmpstr=['Calls:'];
    fwrite(fid,tmpstr,'char');
    fprintf(fid,'\n',[]);

    printFunList(finalData{2,i}{3}, 'Path', fid);
    
    updateCallsM(finalData{2,i}{6},finalData{2,i}{2},finalData{2,i}{3})

    fprintf(fid,'\n',[]);
    tmpstr=['Global variables:'];
    fwrite(fid,tmpstr,'char');
    fprintf(fid,'\n',[]);

    printVarList(finalData{2,i}{4}, 'Line #', fid);

    fprintf(fid,'\n',[]);
    tmpstr=['Local variables:'];
    fwrite(fid,tmpstr,'char');
    fprintf(fid,'\n',[]);

    printVarList(finalData{2,i}{5}, 'Line #', fid);

    tmpstr=['----------------------------------------------------------------------'];
    fwrite(fid,tmpstr,'char');
    fprintf(fid,'\n',[]);
    fprintf(fid,'\n',[]);


end % of for each function

tmpstr=['{End of File}'];
fwrite(fid,tmpstr,'char');
fclose(fid);

return

function printFunList(list, label2, fid)
%list is a cell array with names of functions or variables ...
%...in the first column and the contents of what label2 describes in the second column.
%
% Prints (with indentation) the contents of the 2xN array with labels.

col2Begin = 20; % this is where the column 2 begins (# of characters from left)

if isempty(list)
    tmpstr=['    {None}'];
    fwrite(fid,tmpstr,'char');
    fprintf(fid,'\n',[]);
end

for j=1:size(list,2)
    tmpstr=['    ' list{1,j} ' ' spaces(col2Begin-length(list{1,j})) label2 ':  ' list{2,j}];
    fwrite(fid,tmpstr,'char');
    fprintf(fid,'\n',[]);
    j = j+1;
end

return


function printVarList(list, label2, fid)
%list is a cell array with names of functions or variables ...
%...in the first column and the contents of what label2 describes in the second column.
%
% Prints (with indentation) the contents of the 2xN array with labels.

col2Begin = 20; % this is where the column 2 begins (# of characters from left)

if isempty(list)
    tmpstr=['    {None}'];
    fwrite(fid,tmpstr,'char');
    fprintf(fid,'\n',[]);
end

for j=1:size(list,2)
    tmpstr=['    ' list{1,j} ' ' spaces(col2Begin-length(list{1,j})) label2 ':  ' ];
    for k=1:length(list{2,j})
        c = list{2,j};
        if iscell(c)
            tmpstr=[tmpstr num2str(list{2,j}{k}) ', '];
        else
            tmpstr=[tmpstr num2str(list{2,j}(k)) ', '];
        end
    end
    tmpstr=[tmpstr(1:(end-2)) ]; %'.'];
    fwrite(fid,tmpstr,'char');
    fprintf(fid,'\n',[]);
end

return

function spaceStr = spaces(num)
%returns a string with num spaces
spaceStr = '';
if (num>=1)
    for i = 1:num
        spaceStr = [spaceStr ' '];
        i = i+1;
    end
end

return

%-----------------------------------------------------------------------------------------------
function [data, subData] = getFunctionInfo(fun, fileSubFunC, begLineNum)
% function [data subData] = getFunctionInfo(fun, fileSubFunC, begLineNum)
%
% Gets information about the input function.
% Returns data, a cell array with 8 cells.
% Also returns subData, a cell array with data arrays for each of the subfunctions in the file.
%
% Input variables:
% fun is a string containing the name of the input function.
% fileSubFunC is a cell array containing data for a subfunction file.  (used for recursive call)
% begLineNum is the line number that the first line of this subfunction corresponds to in the master function.  (used for recursive call)
%
% EXAMPLE USES:
%   getFunctionInfo('funName.m')
%   getFunctionInfo('funName')
%   getFunctionInfo('C:\dir1\dir2\funName')
%
% The information that the data cell array contains is the following:
% Cell 1:  String, either 'function' or 'subfunction of {master function}'
% Cells 2-5 are cell arrays containing Strings with the following info:
% Cell 2:  2xN cell array with name of function and path of function that the input function is called by.
%          e.g. {fun1 fun2 fun3 ... ; path1 path2 path3 ... }   note that paths could be 'built-in'.
%   NOTE:  Cell 2 is left with an empty cell array at the end of this method.  Use getAllFunctionInfo to fill in Cell 2.
% Cell 3:  2xN cell array with name of a function and path of function that the input function calls.
% Cell 4:  2xN cell array with names of global variables used by the function and line numbers.
% Cell 5:  2xN cell array with names of local variables used by the function and line numbers.
% Cell 6:  String with the name of the function.
% Cell 7:  String with the path of the function.
% Cell 8:  Cell array with help file info for the function stored as strings
%
% Assumes file has this format:  function name on top line, all comments or spaces
% on the next lines, and then declares global variables on the first lines after that.
%
% Note:  This does not work for variables and functions with the same name.
%
% Vanessa Clark, 6/11/02

%initialize empty cells elements
data(1:5) = {{}};

% put the name of the function into its place in data.
if isempty(strfind(fun,'\')) %the name of the function does not include its path
    data(6) = {fun};
else % we need to extract the name from the path.
    rest = fun;
    while ~isempty(strfind(rest,'\'))
        [partOfPath, rest] = strtok(rest,'\');
        rest = rest(2:end); % to get rid of the leading '\'
    end
    data{6} = strtok(rest,'.'); % this is the function name.
end

% find the associated m-file for the input function and use that as the path
more = which(fun);
if isempty(more)
    error(['Function ' fun ' not found.  Make sure the function is on the MatLab search path.']);
end
periodLocations = strfind(more,'.');
if ~isempty(periodLocations)
    lastPeriod = periodLocations(end);
else
    lastPeriod = length(more)+1;
end
path = more(1:lastPeriod-1);
ext = more(lastPeriod:end);


data(7) = {[path '.m']}; %{which(fun)}; % likewise with the path of the function.
if isempty(which(data{7}))
    error(['No associated m-file found for ' which(fun)]);
end
% done finding associated m-file

data(8) = {{}};

subData = {};
if nargin==1 %this is not a recursive call with a subfunction, so we need to check for subfunctions)
    file = file2cell(data{7});
    begLineNum = 1;

    %we'll assume all functions that are not subfunctions have the same name as their mfile.
    % let's find the function and its subfunctions

    % currently, line = the line of the first function (or, if there is no fun, it is the line after the last of the file).
    [firstLineMasterFun, foundFun] = findFunLine(1,file);
    if (~foundFun), warning(['Script file: ' data{6} ' found  -- no further analysis on this file.']); return; end
    % doesn't matter what the name of this function is -- the file name takes precedence.
    [firstLineSubFun, foundFun] = findFunLine(firstLineMasterFun+1,file);
    if ~foundFun %then we leave the file alone ... there's only one function.
        fileMasterFun = file;
    else % we truncate the master function file and look for the first subfunction.
        fileMasterFun = {file{firstLineMasterFun:(firstLineSubFun-1)}};

        %search for another function
        while foundFun
            [firstLineNextSubFun, foundFun] = findFunLine(firstLineSubFun+1,file);
            if ~foundFun
                fileSubFun = {file{firstLineSubFun:end}};
            else
                fileSubFun = {file{firstLineSubFun:(firstLineNextSubFun-1)}};
            end
            subFunName = getFunName(file{firstLineSubFun});
            currSubData = getFunctionInfo(fun, fileSubFun, firstLineSubFun);
            currSubData(1) = {['subfunction of ' data{6}]};
            currSubData(6) = {subFunName};
            subData = {subData{:},currSubData};
            firstLineSubFun = firstLineNextSubFun;
        end
    end
    data(1) = {'function'};
    file = fileMasterFun;
else
    file = fileSubFunC;

end


%let's determine which functions call this one later (in getAllFunctionInfo).
data(2) = {{}};

%Determine what functions this calls and which variables it uses by using getwordlets:

data(3) = {{}}; % initialize cells 3 - 5
data(4) = {{}};
data(5) = {{}};

% First find all global variables declared at the top of the file...
% also find help file and put in data(8).
% find the line that says global and put those variables into cell 4.
line = 1; %counter of file lines
atGlobalLine = 0;
foundFunctionLine = 0;
foundHelpFile = 0;
doneWithHelpFile = 0;

while ~atGlobalLine & line<=length(file)
    firstWord = strtok(file{line});
    if strcmp(firstWord,'function') | strncmp(firstWord,'%',1) | isempty(firstWord)
        % The following lines create the help file and put it in data(8)...
        if strcmp(firstWord,'function')
            foundFunctionLine = 1;
            c = data(8);
            data(8) = {[c{:}, file(line)]};  % add this line for more information
            while strfind(file{line}, '...')
                line = line+1;
                c = data(8);
                data(8) = {[c{:}, file(line)]};
            end

        elseif foundFunctionLine & ~doneWithHelpFile & strncmp(firstWord,'%',1)
            %the following lines add the help line(s) to the beginning of help file.
            helpline = file(line);
            helpline = {helpline{1}(1:end)}; % (2:end) instead of (:) if it is desired to get rid of the first '%'
            c = data(8);
            data(8) = {[c{:}, helpline]};

            foundHelpFile = 1;
        elseif foundHelpFile & isempty(firstWord)
            doneWithHelpFile = 1;
        end
        % ...When iteration is over, the previous code will have put the help file in data(8).
        line = line+1; % go on to next line
    else
        atGlobalLine = 1;
    end
end
if line>length(file), warning(['Script file: ' data{6} ' found  -- no further analysis on this file.']); return; end
% now we know that this line either has the word 'global' at the beginning or there are no global variables.
searchNextLine = 1;
while searchNextLine
    [globalWord, restOfVariablesStr] = strtok(file{line});
    if strcmp(globalWord, 'global') % then we add the rest of the variables to the global data cell.
        searchNextWord = 1;
        while searchNextWord
            [variable, restOfVariablesStr] = strtok(restOfVariablesStr);
            if isempty(variable)
                line = line+1;
                %search next line for global variables
                searchNextWord = 0;
            elseif strcmp(variable, '...')    % next line has global variables
                line = line+1;
                restOfVariablesStr = file{line};
            else
                data{4} = {data{4}{1,:}, variable; data{4}{2,:}, []};  %[] will have line numbers
                % go on to next token
            end
        end
    else  %there are no global variables left.
        searchNextLine = 0;
    end
end
% ... Done finding global variables at top of file.

[wordlets, lineNumbers] = getwordlets(fun, file, begLineNum);

% Now we want to find these global variables in the wordlets array and put line numbers into the data{4}{2} array.
if ~isempty(data{4})
    for i = 1:size(data{4},2) % for each global variable
        if ~isempty(wordlets)
            for j = 1:length(wordlets) % for each wordlet
                if strcmp(data{4}{1,i},wordlets{j}) | strcmp(['#' data{4}{1,i}],wordlets{j})  %if the wordlet is a global variable
                    c = data{4}(2,i);
                    % add these line numbers

                    % data{4}(2,i) = {[c{:},lineNumbers{j}{:}]};
                    % APA
                    data{4}(2,i) = {[c{:},lineNumbers{j}]};
                    wordlets{j} = ''; % don't process this wordlet again later on
                end
            end
        end
        c = data{4}(2,i);
        data{4}{2,i} = unique(c{:});
    end
end



for i = 1:size(wordlets,2)
    currentWord = wordlets{i};
    if size(wordlets,2)>i
        nextWord = wordlets{i+1};
    else
        nextWord = '';
    end

    type = which(currentWord, 'in', fun);

    if strcmp(currentWord,'out')
        1; %for debugging
    end

    if isempty(currentWord) %then do absolutely nothing with this wordlet.

        %now check the wordlets array for definite local variables (with '#')...
    elseif strcmp([currentWord '#'], nextWord)  % then currentWord is a variable
        wordlets{i+1}=''; %erase it so we don't use this wordlet twice!
        lineNumbers{i} = {lineNumbers{i}{:},lineNumbers{i+1}{:}}; %but we need the line numbers.
        %it's not global (we already processed global vars), so put in local variables array:
        data{5} = {data{5}{1,:}, currentWord; data{5}{2,:}, lineNumbers{i}};

    elseif strcmp(currentWord(end),'#') %then currentWord is a local variable
        data{5} = {data{5}{1,:}, currentWord(1:end-1); data{5}{2,:}, lineNumbers{i}};

        %...done checking the wordlets array for definite local variables.

    elseif strcmp(type, 'built-in')
        %it can't be a flow control keyword, so we want this function in our list.
        %add this word to function cell array in cell 3
        data{3} = {data{3}{1,:}, currentWord; data{3}{2,:}, type};
    elseif strcmp(currentWord(end),'@')   %then a function handle has been used
        %count it as calling a function, even though it's a handle:
        functionName = currentWord(1:end-1);
        functionPath = which(currentWord(1:end-1),'in',fun);
        if isempty(data{3}) | ~(strcmp(functionName, data{3}{1,end}) & strcmp(functionPath, data{3}{2,end}))
            %then this is a unique function, so add it to the list:
            data{3} = {data{3}{1,:}, functionName; data{3}{2,:}, functionPath};
        end

    elseif ~isempty(strfind(type, '\')) | ~isempty(strfind(type,'/')) %then 'type' is a pathname for the function
        if strcmp(type,which(fun))  % path of this fun is same as master fun
            if ~strcmp(currentWord,fun) % then this is a subfunction.
                type = 'subfunction';
            end
        end
        % now add to function cell array in cell 3
        data{3} = {data{3}{1,:}, currentWord; data{3}{2,:}, type};
    elseif isnan(str2double(currentWord(1)))   %then this wordlet is a variable
        %(this includes struct.field types of variables)
        %add to variable cell array in cell 5
        data{5} = {data{5}{1,:}, currentWord; data{5}{2,:}, lineNumbers{i}};
    end

end % of "for i = 1:size(wordlets,2)"

%Clean up line numbers:
for i = 1:size(data{4},2)
    %data{4}{2,i} = unique([data{4}{2,i}(:)]);
    % APA: Now data{5}{2,i} is of class cell and not double as before
    data{4}{2,i} = unique([data{4}{2,i}]);
end

for i = 1:size(data{5},2)
    % data{5}{2,i} = unique([data{5}{2,i}{:}]);
    % APA: Now data{5}{2,i} is of class cell and not double as before
    data{5}{2,i} = unique([data{5}{2,i}]);
end

return % end of getFunctionInfo

%----------------------------------%
function name = getFunName(header)
%this function gets the name of the function given its first line as a string (header).
if isempty(strfind(header,'=')) % there is no '=', so the function name is the second word.
    [wordThatIsFunction, rest] = strtok(header);
else
    [wordsBeforeEquals, rest] = strtok(header,'=');
    rest = [rest(2:end)]; % to take out '=' at beginning of rest
end

name = strtok(rest,['(',' ']);

return

%--------------------------------------------------------------------------------------------------------
function finData = getAllFunctionInfo(allData)
% function finData = getAllFunctionInfo(allData)
% This function determines which functions are called by which other functions.
%
% allData is a 2xN cell array with file names (row1) and the corresponding data cell arrays (row2).
% e.g.  allData = {'fun1', 'fun2', 'fun3' ... ; data1, data2, data3 ... }
%
% This returns the same allData array with the 2nd cell of each data array modified.
%
% Vanessa Clark, 5/21/02


if ~isempty(allData)
    for i=1:size(allData,2)  % go through each function's data
        if ~isempty(allData{2,i}{3})
            for j=1:size(allData{2,i}{3},2) % for each function name that the current (i) function calls
                if ~strcmp(allData{2,i}{3}{2,j},'built-in') % then we need to check to see if this is in the master list (this statement speeds things up)
                    for k=1:size(allData,2)
                        if strcmp(allData{2,i}{3}{1,j}, allData{2,k}{6}) %& strcmp(allData{2,i}{3}{2,j}, allData{2,k}{7})  % if fun called matches the name of one of the master list of functions
                            if strcmp(allData{2,i}{3}{2,j}, allData{2,k}{7}) | (strcmp(allData{2,i}{3}{2,j},'subfunction') & strcmp(allData{2,i}{7}, allData{2,k}{7})) % either the paths match or one is a subfunction and their master function paths match
                                %then put the current function into the 'called by' cell of the fun called.
                                allData{2,k}{2} = {allData{2,k}{2}{1,:}, allData{2,i}{6}; allData{2,k}{2}{2,:}, allData{2,i}{7}};
                            end
                        end
                    end
                end
            end
        end
    end
end

finData = allData;
return

%----------------------------------------------------------------------------------------------------------
function  [wordlets, lineNumbers] = getwordlets(mname, file, lineOffset)
%function  [wordlets, lineNumbers] = getwordlets(mname, file, lineOffset)
%
%This function returns all possible variables and function names found in
%an mfile named 'mname'.  They are returned in sorted alphabetical order,
%with redundancies and flow control keywords removed, in the cell array
%'wordlets'.  Comments are deleted before analysis of the wordlets.
%
%Also returns lineNumbers, a cell array containing cell arrays with the line numbers
%where the wordlets appear in the mname file.  lineOffset is the starting position of
%the subfunction relative to the master function, if applicable.
%
%If there are two arguments, the file argument takes precedence over mname.
%The file input argument should be a cell array containing strings with the file lines.
%
%   EXAMPLE USES:
%       getwordlets('mFileName')
%       getwordlets('mFileName.m')
%       getwordlets('fileNameDoesntMatter', cellArrayWithFileStrings, 3)
%
%A wordlet is usually returned like this: 'wordletname', but it is returned as
%'#wordletname' if the wordlet is a variable to the left of an equals sign, meaning
%all LOCAL VARIABLES are returned in this form (not including the input variables,
%but including possibly some global variables).
%The variable may be returned in its usual form ('wordletname') as well.
%
%
%This program is free software; you can redistribute it and/or
%modify it under the terms of the GNU General Public License
%as published by the Free Software Foundation; either version 2
%of the License, or (at your option) any later version.
%
%This program is distributed in the hope that it will be useful,
%but WITHOUT ANY WARRANTY; without even the implied warranty of
%MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%GNU General Public License for more details.
%
%A copy of the GNU General Public License can be found
%at the GNU website:  www.gnu.org
%
%Copyright (C) 2000 Joseph O. Deasy
% modified by Vanessa Clark, 6/11/02

%posted to the matlab newsgroup on 5-April-0.

if nargin==1
    s = which(mname);
    file = file2cell(s);
end
%otherwise, file input takes precedence.

if nargin < 3
    lineOffset = 1; %default offset is 1, the beginning of a function.
end

%file = file2cell('D:\programs\matlabr11pt1\toolbox\matlab\datafun\fft.m');

wordlets  = {};
lines = [];  % this array will be used to store the line numbers in parallel with the wordlets until lineNumbers is created.
lineNumbers = {};

delims = {'.^','^','<','>','~','-','+',';',...
    './','/','.\','\','.*','*','[',']','{','}',...
    '(',')','.''','''','"',':','&','!',...'.',
    ',','|','..','...'};
%Note it is important to process, ./ before / and .* before *, etc.

delimChars = {'^','<','>','=','~','-','+',';',...
    '/','\','*','[',']','{','}',...
    '(',')','''','"',':','&','!',...
    ',','|'};

notVariables = {'if','else','elseif','end','switch','case','otherwise','while','for','continue',...
    'break','try','catch','return',... % here ends the flow control keywords
    'function','persistent'};


[funLine, foundFun] = findFunLine(1,file);
if ~foundFun, error('No line beginning with ''function'' in this file.'); end

[delete, file{funLine}] = strtok(file{funLine},'('); %deletes everything before the input argument(s).

file{funLine} = [file{funLine}(2:end)]; %to take out '(' from beginning of line
%now put '#' in front of each word to indicate that it is a variable:
finishedWords = '';
rest = file{funLine};
while ~isempty(rest)
    [putPound, rest] = strtok(rest,[',',' ',')']);
    finishedWords = [finishedWords ' #' putPound];
end
file{funLine} = finishedWords;

for i = 1:length(file)
    % First we need to take out all the characters between ' and ' so we don't process them.
    restOfLine = file{i};
    savedLine = '';

    apos = strfind(restOfLine, ''''); % apos is short for apostrophes
    if ~isempty(apos)
        savedLine = restOfLine(1:apos(1)-1);
    else
        savedLine = restOfLine;
    end

    while ~isempty(apos)
        isBegOfString = 1;
        %find out if it is a matrix operator (otherwise it's the beginning of a string):
        if ~(apos(1)==1)
            prevChar = restOfLine(apos(1)-1);
            if sum(strcmp(prevChar,{'.',')',']','}'})) | ~(sum(strncmp(prevChar,delimChars,1)) | isspace(prevChar))
                %then this is a matrix operator.  Leave it alone.
                isBegOfString = 0;
                if length(apos)>1
                    savedLine = [savedLine restOfLine(apos(1):(apos(2)-1))];
                else
                    savedLine = [savedLine restOfLine(apos(1):end)];
                end
                apos = apos(2:end);
            end
        end
        if isBegOfString
            if length(apos)<2 & isempty(strfind(savedLine, '%')) % not enough ''s and this is not commented out
                warning(['Problem detecting apostrophe as string delimiter or matrix/array transpose in ' mname ' on line ' num2str(i) '.  The code on this line may not be valid.']);
            elseif length(apos)<2 & ~isempty(strfind(savedLine,'%')) % not enough ''s and this is commented out
                % don't worry about this line, because it's commented out anyway.
            elseif length(apos)>2
                savedLine = [savedLine ' ' restOfLine((apos(2)+1):(apos(3)-1))];
            else
                savedLine = [savedLine ' ' restOfLine((apos(2)+1):end)];
            end
            apos = apos(3:end);
        end
    end
    % Now let's take out the comments (from savedLine)

    if strncmp(strtok(savedLine),'%',1)
        savedLine = char(13);
    else
        savedLine = strtok(savedLine,'%');
    end


    file{i} = savedLine;
end

% Next we'll put a '#' at the beginning of every word to the left of an equals sign, excluding the first line.
% also excluding lines that have an "if" in them.
for i=2:length(file)
    restOfLine = file{i};
    resultingLine = '';

    while ~isempty(restOfLine)
        [process, restOfLine] = strtok(restOfLine,';'); % to get the next command on this line
        if ~isempty(strfind(process,'=')) & isempty(strfind(process,'if')) %there is an equals in this command and there is not an 'if'
            [alter, keep] = strtok(process,'=');

            alter = removeLeadingSpaces(alter);

            if ~strncmp(alter, '[', 1) %then there is only one thing being assigned to
                resultingLine = [resultingLine ' #' alter ' '];
            else % there are multiple variables we need to put a # in front of.
                %the first variable is easy:
                alter = alter(2:end); %to get rid of initial '['
                alter = removeLeadingSpaces(alter);
                [alter, rem] = strtok(alter, [char(6:10) char(13) ' ' delimChars{1:end}]);
                resultingLine = [resultingLine ' #' alter ' '];
                % now we need to put a # in front of all the other wordlets we know are variables
                %these are counters of brackets and parenthesis:
                square = 0;
                curly = 0;
                paren = 0;

                comma = 0; % boolean, indicates whether this character is a comma or not
                while ~isempty(rem) % rem is an abbreviation for remainder
                    switch rem(1)
                        case {'('}
                            paren = paren+1;
                        case {')'}
                            paren = paren-1;
                        case {'{'}
                            curly = curly+1;
                        case {'}'}
                            curly = curly-1;
                        case {'['}
                            square = square+1;
                        case {']'}
                            square = square-1;
                        case {','}
                            comma = 1;
                    end
                    resultingLine = [resultingLine rem(1)];
                    rem = rem(2:end);
                    if square == -1
                        %done
                        resultingLine = [resultingLine rem];
                    elseif comma & ~curly & ~square & ~paren % this is after a comma outside of all brackets & parentheses
                        [addpound, rem] = strtok(rem, [char(6:10) char(13) ' ' delimChars{1:end}]);
                        addpound = removeLeadingSpaces(addpound);
                        resultingLine = [resultingLine ' #' addpound ' '];

                        comma = 0; %resets this boolean
                    end
                end
            end
            resultingLine = [resultingLine keep];
        else
            resultingLine = [resultingLine process];
        end
    end
    file{i} = resultingLine;
end

%now let's start parsing the file:
for i = 1:length(file)

    str = file{i};

    % APA: remove == and ~=
    indexV = strfind('==',str);
    indexV = [ indexV strfind('~=',str) ];
    str([indexV indexV+1]) = '';
    % APA: remove == and ~= ends

    % APA: Add blanks to the sides of =
    indexVeq = strfind('=',str);
    if ~isempty(indexVeq)
        str = [str(1:indexVeq-1),' = ',str(indexVeq+1:end)];
    end

    %str(str == ' ') = '&'; %remove whitespace

    for j = 1:length(delims)
        indexV = strfind(delims{j},str);
        for k =1:length(indexV)
            q = indexV(k);
            len = length(delims{j});
            str(q:q+len-1) = blanks(len);
            %Make blanks the same length as delims
        end
    end

    if length(indexVeq)<=1

        eq=[];
        for k = 1:words(str)
            if strcmp(word(str,k),'=')
                eq = k;
                break
            end
        end

        if ~isempty(eq)
            for k=1:eq-1
                str2  = word(str,k);
                lines = [lines,{[num2str(i+(lineOffset-1)),'L']}];
                wordlets = cat(2,wordlets,{str2});
                %lines{length(wordlets)} = [num2str(i+(lineOffset-1)),'L'];
            end
            for k=eq+1:words(str)
                str2  = word(str,k);
                lines = [lines,{[num2str(i+(lineOffset-1)),'R']}];
                wordlets = cat(2,wordlets,{str2});
                %lines{length(wordlets)} = [num2str(i+(lineOffset-1)),'R'];
            end
        else
            for k=1:words(str)
                str2  = word(str,k);
                lines = [lines,{num2str(i+(lineOffset-1))}];
                wordlets = cat(2,wordlets,{str2});
                %lines{length(wordlets)} = [num2str(i+(lineOffset-1))];
            end
        end

    else
        indexVeq = strfind('=',str);
        str(indexVeq) = ' ';
        for k=1:words(str)
            str2  = word(str,k);
            lines = [lines,{[num2str(i+(lineOffset-1)),'?']}];
            wordlets = cat(2,wordlets,{str2});
            %lines{length(wordlets)} = [num2str(i+(lineOffset-1)),'R'];
        end

    end

end


for i=1:length(wordlets)
    if strncmp(wordlets(i), '#', 1) & length(wordlets{i})>1
        wordlets{i} = [wordlets{i}(2:end) '#'];
    elseif strncmp(wordlets(i), '@', 1) & length(wordlets{i})>1
        wordlets{i} = [wordlets{i}(2:end) '@'];
    end
end

[wordlets, i,j] = unique(wordlets);  %eliminate duplicates

%create lineNumbers cell array from lines array:
lineNumbers = cell(1,length(wordlets));
for i=1:length(lines)
    c = lineNumbers(j(i));
    lineNumbers(j(i)) = {[c{:}, {char(lines(i))}]};
    % lineNumbers(j(i)) = {[c{:}, lines{i}]};
end

%take care of nonsense variables...
%take out those that are just the '#' character:
if strcmp(wordlets(1),'#')
    wordlets = wordlets(2:end);
    lineNumbers = lineNumbers(2:end);
end
%take out those that begin with '.' :
while strncmp(wordlets(1),'.',1)
    wordlets = wordlets(2:end);
    lineNumbers = lineNumbers(2:end);
end
%...done removing nonsense variables.

%take out flow control variables:
newWordlets = {};
newLineNumbers = {};

for i=1:length(wordlets)
    currWord = wordlets{i};
    if ~(sum(strcmp(currWord, notVariables)) | (strncmp(currWord,'#',1) & ~isempty([currWord(2:end)]) & sum(strcmp([currWord(2:end)], notVariables))))
        newWordlets = {newWordlets{:}, wordlets{i}};
        newLineNumbers = {newLineNumbers{:}, lineNumbers{i}};
    end
end

wordlets = newWordlets;
lineNumbers = newLineNumbers;

return;


function wordS = word(stringS,n)

%function word(stringS,n)
%Returns the n'th blank delimited word in string of words. n
%must be positive. If there are fewer than n words in the string,
%the null string is returned.
%Inspired by the REXX function 'word'.
%
%ex:
%   c=word('a and b',3)
%

%J.O. Deasy, Feb, 99.



%Get the number of blank-delimited words:
num_words=words(stringS);

if num_words<n
    wordS='';
else
    index=1;
    indices_begin=[];
    indices_end=[];
    beginning=0;
    ending=1;
    while index<=length(stringS)
        char=stringS(index);
        if ~isspace(char) & beginning==0
            indices_begin=[indices_begin,index];
            ending=0;
            beginning=1;
        end
        if isspace(char) & ending==0
            indices_end=[indices_end,index-1];
            beginning=0;
            ending=1;
        end
        index=index+1;
    end
    %special case: if the last character was not a space,
    %then we need to count it as ending a word:
    pos=length(stringS);
    if ~isspace(stringS(pos))
        indices_end=[indices_end,pos];
    end
    wordS=stringS(indices_begin(n):indices_end(n));
end

return;


function num_words=words(stringS)
%Returns the number (num_words) of blank-delimited words in stringC
%A word character is defined as any ASCII character except a blank.
%Inspired by the REXX specification.
%
%Matlab V. 5.2, rel.10
%
%ex.:
%  a='this and that'
%  n=words(a)
%

%J. O. Deasy, Feb. 99.



num_words=0;
hit_word=0;

for i=1:length(stringS)
    next_char=stringS(i);
    if ~isspace(next_char)
        hit_word=1;
    end
    if  isspace(next_char) & hit_word==1
        hit_word=0;
        num_words=num_words+1;
    end
end

if ~isempty(stringS) & ~isspace(stringS(length(stringS)))
    num_words=num_words+1;
end

return

%--------------------------
function outStr = removeLeadingSpaces(inStr)
% removes the leading spaces in the input string and returns the result

while ~isempty(inStr) & isspace(inStr(1))
    inStr = inStr(2:end);
end

outStr = inStr;

return
%---------------------------------------------------------------------------------------------------

function  FileC = file2cell(FileNameS)
%Put a file into a cellarray.  Each cell is a
%line converted to a character string.

%copyright (c) 2001, J.O. Deasy and Washington University in St. Louis.
%Use is granted for non-commercial and non-clinical applications.
%No warranty is expressed or implied for any use whatever.

%LM:  11 Jun 02, VHC.

Newline = 13; %Define value of newline character


try
    fid = fopen(FileNameS,'r');
    FileV = fread(fid);
    fclose(fid);
catch
    FileC = {}
    warning(['Attempt to open ' FileNameS ' failed!'])
    return
end

FileC={};

if ~isempty(FileV)

    FileV(FileV == 10) = [];

    %Break into lines.  Find all the newline characters.
    [LocationV] = find(FileV == Newline);

    %Reprocess to a cellarray
    Start = 1;
    for i = 1:length(LocationV)
        Stop = LocationV(i);
        FileC{i} = char(FileV(Start:Stop-1))';
        Start = Stop + 1;
    end

    if ~isempty(FileC)
        FileC{i+1} = char(FileV(Start:end))';  %to make sure the last line of the file is included in FileC
    end

end

return
%--------------------------------------------------------------------------------------------------
function [funLine, foundFun] = findFunLine(startingLine, file)
%Finds the first line of a function on the starting line or lower.
%foundFun = 1 if there was a line lower than the starting line beginning with 'function'.
% file is a cell array containing strings with the text of the file
%
%Vanessa Clark, 5/20/02

atFunLine = 0;
line = startingLine;
while ~atFunLine & (line<=length(file))
    firstWord = strtok(file{line});
    if strcmp(firstWord,'function')
        atFunLine = 1;
    else
        line = line+1;
    end
end


if line>length(file)
    foundFun = 0;
else
    foundFun = 1;
end

funLine = line;
return

function updateCallsM(fileNam, filesCalledByC, filesCalledC)
%function updateCallsM(fileNam, filesC)
%
%This function updtaes the matrix which stores mapping for files called by
%and the files which call the passes file "fileNam"
%
%APA, 3/2/2010

global callsM calledByM fileNameC

fileNameC{end+1} = fileNam;
numFiles = length(fileNameC);

calledByM(numFiles,numFiles) = 0;
callsM(numFiles,numFiles) = 0;
indFind = find(ismember(fileNameC,filesCalledByC));
calledByM(end,indFind) = 1;

indFind = find(ismember(fileNameC,filesCalledC));
callsM(end,indFind) = 1;

