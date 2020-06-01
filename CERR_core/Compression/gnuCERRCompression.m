function [outstr] = gnuCERRCompression(aFile, userSelect, tmpExtractDir)
%function [outstr] = gnuCERRCompression(aFile, userSelect)
% This function attempts to compress or decompress a given
%input file into either a *.gz compressed file (if extension == *.mat)
%or dearchive a plan into its original *.mat file (if extension == *.mat.gz)
% Input: aFile is input filename (with complete pathname),
%      userSelect = 'compress' if compression is desired
%            = 'uncompress' if expansion desired
% Why bother with compression?
%bzip reliably compresses *.mat plan files by > 66%
%Also, bzip is siginificantly more memory efficient than .zip.
% Angel I. Blanco 3-23-2002
%Latest modifications:  4-9-2002 AIB
%JOD, 30 Dec 02.

% copyright (c) 2001-2006, Washington University in St. Louis.
% Permission is granted to use or modify only for non-commercial, 
% non-treatment-decision applications, and further only if this header is 
% not removed from any file. No warranty is expressed or implied for any 
% use whatever: use at your own risk.  Users can request use of CERR for 
% institutional review board-approved protocols.  Commercial users can 
% request a license.  Contact Joe Deasy for more information 
% (radonc.wustl.edu@jdeasy, reversed).

oldDir = pwd;
pathStr = getCERRPath;

fmat = ''; outstr = '';
fmat = (strcat('"', aFile,'"'));
if strcmpi(userSelect, 'compress')
    if ~isempty(strfind(aFile,'.mat.bz2'))
        % compressed file exists already!
        warndlg('Compressed output file verified. Will exit compression routine.', ...
            'CERR Compression');
    elseif ~isempty(strfind(aFile,'.mat'))
        if isdeployed
            cd(fullfile(pathStr,'bin','Compression'))
        else
            cd(fullfile(pathStr,'Compression'))
        end
        if ispc
            dos(['bzip2-102-x86-win32.exe -vz1 -f ', fmat]);
        elseif isunix
            unix(['bzip2 -z1 -f ', fmat])
        end
        cd(oldDir);
    end
elseif strcmpi(userSelect, 'uncompress')
    if ~isempty(strfind(aFile,'.mat.bz2'))
        % compressed file exists
        if isdeployed
            cd(fullfile(pathStr,'bin','Compression'))
        else
            cd(fullfile(pathStr,'Compression'))
        end
        [path_jnk,fnameDisk,ext_jnk] = fileparts(fmat);
        dirS = dir(tmpExtractDir);
        del_dir_flag = 0;
        if ismember(fnameDisk,{dirS.name})
            random_str = num2str(rand(1,1));
            tmpExtractDir = fullfile(tmpExtractDir,random_str);
            mkdir(tmpExtractDir)
            del_dir_flag = 1;
        end
        if ispc
            dos(['7z e ', fmat, ' -o"',tmpExtractDir,'"']);
            %Remove temporary directory
            if del_dir_flag == 1                
                rmdir(tmpExtractDir,'s')
            end
            %dos(['bzip2-102-x86-win32.exe -dkv ', fmat]);
        elseif isunix
            unix(['bunzip2 -dk ', fmat])
        end
        cd(oldDir);
    else
        errordlg('Compressed file not found at specified location', ...
            'CERR Compression');
    end
else
    warndlg('Compression method not established.', 'CERR Compression');
end
