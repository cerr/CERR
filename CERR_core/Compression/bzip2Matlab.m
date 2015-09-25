function  bzip2Matlab

% This function prompts the user to select a file via gui method
%   If the file ends with *.bz2 suffix
 %      function assumes the file is compressed and will uncompress it
 %      using bzip2
%   Else if the file ends with any other suffix
 %      function attempts to compress it using bzip2
 %  The objective is easier handlng of compressed files in Matlab
%  LM AIB 11/24/2002

% copyright (c) 2001-2006, Washington University in St. Louis.
% Permission is granted to use or modify only for non-commercial, 
% non-treatment-decision applications, and further only if this header is 
% not removed from any file. No warranty is expressed or implied for any 
% use whatever: use at your own risk.  Users can request use of CERR for 
% institutional review board-approved protocols.  Commercial users can 
% request a license.  Contact Joe Deasy for more information 
% (radonc.wustl.edu@jdeasy, reversed).

[fname, pathname] = uigetfile('*.*', ...
    'Select a file you wish to compress or decompress');
tic
oldDir = pwd;
pathStr = getCERRPath;
cd(pathname);
l = length(fname);
fmat = ''; outstr = '';
fmat = (strcat('"',oldDir, '\', fname,'"'));
if (~strcmpi(midstring(fname,l-2,l),'bz2')) % compress file
        cd(pathStr);
        outstr = ['bzip2-102-x86-win32.exe -vv9 ', fmat];
        system(outstr);
        cd(oldDir);
elseif (strcmpi(midstring(fname,l-2,l),'bz2')) % uncompress file
        cd(pathStr);
        outstr = ['bzip2-102-x86-win32.exe -dvv ', fmat];
        system(outstr);
        cd(oldDir);
else
    error('Incorrect filename chosen. Exiting bzip2Matlab.')
end


toc

return
