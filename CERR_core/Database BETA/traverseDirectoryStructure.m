function results = traverseDirectoryStructure(rootPath, style, functionName, varargin)
%"traverseDirectoryStructure"
%   Given a path, <rootPath>, execute the function given by functionname
%   string <functionName> in rootPath and all of its subdirectories. Compile 
%   the output of functionName's call in a datastructure. Must specify 'pre' 
%   or 'post' in the style field for pre or post evaluation. varargin contains 
%   any arguments for the function <functionname>.
%
%   JRA 11/7/03
%
% Usage: results = traverseDirectoryStructure(rootPath, style, functionName, varargin)
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

oldpwd = pwd;
try
	cd(rootPath);
    rootPath = pwd;
	numArgs = nargout(functionName);
	
	%Establish result's struct fields but clear it of data.
	results.dir = '';
	results.data = '';
	results(1) = [];
	
	if strcmpi(style,'pre')
        [outputs{1:numArgs}] = feval(functionName, varargin{:});
        results(1).dir = rootPath;
        results(1).data = outputs;
	end
	
	dirContents = dir;
	for i = 1:length(dirContents)
        fileInfo = dirContents(i);
        if (strcmpi(fileInfo.name,'.') | strcmpi(fileInfo.name,'..'))
            continue
        end
        
        if fileInfo.isdir
            if nargin > 3
                output = traverseDirectoryStructure(fullfile(rootPath, fileInfo.name), style, functionName, varargin);
            else
                output = traverseDirectoryStructure(fullfile(rootPath, fileInfo.name), style, functionName);
            end
            results(end+1:end+length(output)) = output;
        end
	end       
	
	if strcmpi(style,'post')
        [outputs{1:numArgs}] = feval(functionName,varargin{:});
        results(end+1).dir = rootPath;         %Add to end of array.   
        results(end).data = outputs;           %Just end since array grew from last step.
    end
    cd(oldpwd);
catch    
   cd(oldpwd)
   error(['Error in traverseDirectoryStructure: ' lasterr '.']);
end