%% Log for CERR m-files
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

%%
[filesChangedC,filesRemovedC,filesAddedC,dirsChangedC,dirsRemovedC,dirsAddedC] = mlog('DIFF',getCERRPath);

%%
if ~isempty(filesChangedC)    
    disp([num2str(length(filesChangedC)),' file/s modified'])
    for i=1:length(filesChangedC)
        disp(filesChangedC{i})
    end
end

%%
if ~isempty(filesRemovedC)
    disp([num2str(length(filesRemovedC)),' file/s removed'])
    for i=1:length(filesRemovedC)
        disp(filesRemovedC{i})
    end
end

%%
if ~isempty(filesAddedC)
    disp([num2str(length(filesAddedC)),' file/s added'])
    for i=1:length(filesAddedC)
        disp(filesAddedC{i})
    end
end

%%
if ~isempty(dirsRemovedC)
    disp([num2str(length(dirsRemovedC)),' directory/ies removed'])
    for i=1:length(dirsRemovedC)
        disp(dirsRemovedC{i}(5:end))
    end
end

%%
if ~isempty(dirsAddedC)
    disp([num2str(length(dirsAddedC)),' directory/ies added'])
    for i=1:length(dirsAddedC)
        disp(dirsAddedC{i}(5:end))
    end
end
