function [remoteGitHash, localGitInfo] = getGitInfo()
%RKP 12/4/2017
% Get information about the Git repository in the current directory, including: 
%          - branch name of the current Git Repo 
%          -Git SHA1 HASH of the most recent commit
%          -url of corresponding remote repository, if one exists
%
% The function first checks to see if a .git/ directory is present. If so it
% reads the .git/HEAD file to identify the branch name and then it looks up
% the corresponding commit.
%
% It then reads the .git/config file to find out the url of the
% corresponding remote repository. This is all stored in a localGitInfo struct.
%
% Note this uses only file information, it makes no external program 
% calls at all. 
%
% This function must be in the base directory of the git repository
%
% Released under a BSD open source license. Based on a concept by Marc
% Gershow.
%
% Andrew Leifer
% Harvard University
% Program in Biophysics, Center for Brain Science, 
% and Department of Physics
% leifer@fas.harvard.edu
% http://www.andrewleifer.com
% 12 September 2011
%
% 
%

% Copyright 2011 Andrew Leifer. All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without modification, are
% permitted provided that the following conditions are met:
% 
%    1. Redistributions of source code must retain the above copyright notice, this list of
%       conditions and the following disclaimer.
% 
%    2. Redistributions in binary form must reproduce the above copyright notice, this list
%       of conditions and the following disclaimer in the documentation and/or other materials
%       provided with the distribution.
% 
% THIS SOFTWARE IS PROVIDED BY <COPYRIGHT HOLDER> ''AS IS'' AND ANY EXPRESS OR IMPLIED
% WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> OR
% CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
% ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
% ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
% 
% The views and conclusions contained in the software and documentation are those of the
% authors and should not be interpreted as representing official policies, either expressed
% or implied, of <copyright holder>.

localGitInfo=[];
remoteGitHash = '';

if isdeployed
    %store date and hash in file under bin
return
end

pth = getCERRPath;
indEnd = strfind(pth,'CERR_core');
basePath = pth(1:indEnd-1);
gitHead = fullfile(basePath,'.git','HEAD');
gitPath = fullfile(basePath,'.git');
if ~exist(gitPath,'file') || ~exist(gitHead,'file')
    %Git is not present
    remoteGitHash = '';
    localGitInfo = '';
    return
end



%Read in the HEAD information, this will tell us the location of the file
%containing the SHA1
text=fileread(gitHead);
parsed=textscan(text,'%s');

if ~strcmp(parsed{1}{1},'ref:') || ~length(parsed{1})>1
        %the HEAD is not in the expected format.
        %give up
        return
end

path=parsed{1}{2};
[pathstr, name, ext]=fileparts(path);
branchName=name;

%save branchname
localGitInfo.branch=branchName;


%Read in SHA1
SHA1text=fileread(fullfile(gitPath,pathstr,[name ext]));
SHA1=textscan(SHA1text,'%s');
localGitInfo.hash=SHA1{1}{1};


%Read in config file
config=fileread(fullfile(gitPath,'config'));
%Find everything space delimited
temp=textscan(config,'%s','delimiter','\n');
lines=temp{1};

remote='';
%Lets find the name of the remote corresponding to our branchName
for k=1:length(lines)
    
    %Are we at the section describing our branch?
    if strcmp(lines{k},['[branch "' branchName '"]'])
        m=k+1;
        %While we haven't run out of lines
        %And while we haven't run into another section (which starts with
        % an open bracket)
        while (m<=length(lines) && ~strcmp(lines{m}(1),'[') )
            temp=textscan(lines{m},'%s');
            if length(temp{1})>=3
                if strcmp(temp{1}{1},'remote') && strcmp(temp{1}{2},'=')
                    %This is the line that tells us the name of the remote 
                    remote=temp{1}{3};
                end
            end
            
            m=m+1;
        end    
    end
end
localGitInfo.remote=remote;


url='';
%Find the remote's url
for k=1:length(lines)
    
    %Are we at the section describing our branch?
    if strcmp(lines{k},['[remote "' remote '"]'])
        m=k+1;
        %While we haven't run out of lines
        %And while we haven't run into another section (which starts with
        % an open bracket)
        while (m<=length(lines) && ~strcmp(lines{m}(1),'[') )
            temp=textscan(lines{m},'%s');
            if length(temp{1})>=3
                if strcmp(temp{1}{1},'url') && strcmp(temp{1}{2},'=')
                    %This is the line that tells us the name of the remote 
                    url=temp{1}{3};
                end
            end
            
            m=m+1;
        end
        
    end
end
%localGitInfo.url=url;

% [~,repName] = strtok(url,':');
%url could also be 'git@github.com:cerr/CERR/commits/testing'
%get to the commits page to view the remote commit hash
%url = 'git@github.com:cerr/CERR';

%if ~isempty(url) && contains(url, '.git')
% use "strfind" instead of "contains" for older versions of matlab
if ~isempty(url) && strfind(url, '.git')
    commitUrl = strrep(url,'.git','/commits/');
    url = strcat(commitUrl,localGitInfo.branch); 
elseif ~isempty(url)
    commitUrl = strcat(url,'/commits/');
    url = strcat(commitUrl,localGitInfo.branch); 
end
% url = ['https://github.com/',commitUrl];

localGitInfo.url=url;

%obtain the date when the .git directory was last updated 
% cerrPath = getCERRPath;
% gitPath = strrep(cerrPath, 'CERR_core\', '.git');

try
    fileInfo = dir(gitPath);
    timeStamp = fileInfo.date;
    localGitInfo.date = timeStamp;
catch
    localGitInfo.date = '';
end
% %check for internet connection
% [~,b]= dos('ping -n 1 www.google.com');
% n=strfind(b,'Lost');
% n1=b(n+7);
% if(n1=='0')    
%     return;
% else
try
    %read remote git information based on url
    weburl = strcat('https://github.com/cerr/CERR/commits/',localGitInfo.branch);
    data = webread(weburl,'term','commit:');
    commitIdIndex = strfind(data, 'commit:');
    remoteGitHash = data(commitIdIndex(1)+7:commitIdIndex(1)+46);
catch
    remoteGitHash = '';
end



