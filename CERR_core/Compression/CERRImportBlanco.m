function planC = CERRImport(optName, archiveDir, saveFile)
%function planC = CERRImport(optName,archiveDir,saveDir)
%
%Description: Wrapper file to import AAPM/RTOG directories.  The main work is done
%by importRTOGDir.  If called without arguments, the user selects an archive file and
%an options file via GUI dialogs, and the name of the file to save the
%CERR plan to is input via the file save GUI.  Can be called with 1, 2, or 3
%arguments.
%
%Inputs:
%optName -- is the name of an options file (an example file is initCERRImport).
%archiveDir -- is the path of the archive directory, with trailing slash.
%saveFile -- the name, including path, of a file to which to save the CERR plan.
%
%Output: None, except the saved file.
%
%Globals:  None.
%
%Author: J. O. Deasy, deasy@radonc.wustl.edu
%
%Reference:
%W. Harms, Specifications for Tape/Network Format for Exchange of Treatment Planning Information,
%version 3.22., RTOG 3D QA Center, (http://rtog3dqa.wustl.edu), 1997.
%
%Last Modified:  14 Feb 02, by JOD.
%
%Version:  1.x. (Incremented by 0.001 for every modification of this file or a called file.)
%
%Copyright:
%This software is copyright J. O. Deasy and Washington University in St Louis.
%A free license is granted to use or modify but only for non-commercial non-clinical use.
%Any user-modified software must retain the original copyright and notice of changes if redistributed.
%Any user-contributed software retains the copyright terms of the contributor.

% copyright (c) 2001-2006, Washington University in St. Louis.
% Permission is granted to use or modify only for non-commercial, 
% non-treatment-decision applications, and further only if this header is 
% not removed from any file. No warranty is expressed or implied for any 
% use whatever: use at your own risk.  Users can request use of CERR for 
% institutional review board-approved protocols.  Commercial users can 
% request a license.  Contact Joe Deasy for more information 
% (radonc.wustl.edu@jdeasy, reversed).

fname1 = '';
%Interactive or not:
if nargin == 0
    [fname1, pathname] = uigetfile('*.*','Select 0000 file to begin importing.');
    archiveDir = pathname;

    [fname, pathname] = uigetfile('*.m','Select CERR options .m file');
    optName = [pathname fname];

    %   % Would the user like to store the plan as a compressed file?
    %   % The following loop investigates this.
    %   % Compression (gz) is made through GNUZIP (freeware)
    %   % Default compression options are 'verbose' and 'best'
    %   gzip 1.2.4 Win32 (02 Dec 97)
    %   usage: gzip [-acdfhlLnNrtvV19] [-S suffix] [file ...]
    %       -a --ascii       ascii text; convert end-of-lines using local conventions
    %       -c --stdout      write on standard output, keep original files unchanged
    %       -d --decompress  decompress
    %       -f --force       force overwrite of output file and compress links
    %       -h --help        give this help
    %       -l --list        list compressed file contents
    %       -L --license     display software license
    %       -n --no-name     do not save or restore the original name and time stamp
    %       -N --name        save or restore the original name and time stamp
    %       -q --quiet       suppress all warnings
    %       -r --recursive   operate recursively on directories
    %       -S .suf  --suffix .suf     use suffix .suf on compressed files
    %       -t --test        test compressed file integrity
    %       -v --verbose     verbose mode
    %       -V --version     display version number
    %       -1 --fast        compress faster
    %       -9 --best        compress better
    %       file...          files to (de)compress. If none given, use standard input.
    % Logic for compressing files:
    %   Matlab binaries will be created first in all cases; subsequently,
    %       they will be replaced by the corresponding compressed binary IF
    %       the user has selected this option in 'CERROptions.m'

    %fid = fopen(optName,'r');
    %while(1)
    %    tline = fgetl(fid);
    %    if findstr((tline), 'optS.saveZip'), break, end
    %end
    %fclose(fid);
    %index = findstr(tline, '=');
    %toZipOrNot = lower(midstring(tline, (index + 1), length(tline) - 1));
    %if findstr(toZipOrNot, 'yes')
    %    toZipOrNot = 'yes';
    %elseif findstr(toZipOrNot, 'no')
    %    toZipOrNot = 'no';
    %else
    warndlg('Output file compression not set: defaulting to full.', ...
        'CERR Configuration');
end
optS = opts4Exe(optName);

if strcmp(optS.saveZip,'yes')


    %end        % APA commented this end (may be placed incorrectly, gave
    %an error during crosslisting)

    saveFlag = 'ui';

elseif nargin == 1 %Assume options given
    [fname1, pathname] = uigetfile('*.*','Select aapm0000 file to begin importing.');
    archiveDir = pathname;
    fid = fopen(optName,'r');
    while(1)
        tline = fgetl(fid);
        if strfind((tline), 'optS.saveZip'), break, end
    end
    fclose(fid);
    index = strfind(tline, '=');
    toZipOrNot = lower(midstring(tline, (index + 1), length(tline) - 1));
    if strfind(toZipOrNot, 'yes')
        toZipOrNot = 'yes';
    elseif strfind(toZipOrNot, 'no')
        toZipOrNot = 'no';
    else
        warndlg('Output file compression not set: defaulting to full.', ...
            'CERR Configuration');
    end
    optS = opts4Exe(optName);

    saveFlag = 'ui';

elseif nargin == 2
    fid = fopen(optName,'r');
    while(1)
        tline = fgetl(fid);
        if strfind((tline), 'optS.saveZip'), break, end
    end
    fclose(fid);
    index = strfind(tline, '=');
    toZipOrNot = lower(midstring(tline, (index + 1), length(tline) - 1));
    if strfind(toZipOrNot, 'yes')
        toZipOrNot = 'yes';
    elseif strfind(toZipOrNot, 'no')
        toZipOrNot = 'no';
    else
        warndlg('Output file compression not set: defaulting to full.', ...
            'CERR Configuration');
    end
    optS = opts4Exe(optName);

    saveFlag = 'ui';

elseif nargin == 3
    fid = fopen(optName,'r');
    while(1)
        tline = fgetl(fid);
        if strfind((tline), 'optS.saveZip'), break, end
    end
    fclose(fid);
    index = strfind(tline, '=');
    toZipOrNot = lower(midstring(tline, (index + 1), length(tline) - 1));
    if strfind(toZipOrNot, 'yes')
        toZipOrNot = 'yes';
    elseif strfind(toZipOrNot, 'no')
        toZipOrNot = 'no';
    else
        warndlg('Output file compression not set: defaulting to full.', ...
            'CERR Configuration');
    end
    optS = opts4Exe(optName);
    if ~strcmp(saveFile,'no')
        saveFlag = 'spec';
    else
        saveFlag = 'no';
    end
    fname1 = 'aapm0000';

end

%Call the import tool:
planC = importRTOGDir(optS, archiveDir, fname1)


switch saveFlag

    case 'ui'

        [fname pname] = uiputfile( '*.mat', ...
            'Save the plan data as:');
        saveFile = [pname fname];
        if ~strcmp(midstring(saveFile, ...
                length(saveFile)-3, length(saveFile)), '.mat')
            % '*.mat' file type not typed by the user
            % this situation can create a file error when compressing
            %       will add the '*.mat' suffix prior to archive being written
            saveFile = strcat(saveFile, '.mat');
        end
        save(saveFile,'planC')
        if strcmp(toZipOrNot, 'yes') % User wants to compress output file
            outstr = gnuCERRCompression(saveFile,'compress');
            h = dos(outstr);
            if (h) % Function returned as zero when compression complete
                errordlg('File not found by compression routine.', 'CERR compression');
            end
        end

    case 'spec'

        if isempty(saveFile) %save within the subdirectory
            saveFile = [archiveDir 'planC.mat'];
            if strcmp(toZipOrNot, 'yes') % User wants to compress output file
                outstr = gnuCERRCompression(saveFile,'compress');
                h = dos(outstr);
                if (h) % Function returned as zero when compression complete
                    errordlg('File not found by compression routine.', 'CERR compression');
                end
            end
        end

        try
            save(saveFile,'planC')
            if strcmp(toZipOrNot, 'yes') % User wants to compress output file
                outstr = gnuCERRCompression(saveFile,'compress');
                h = dos(outstr);
                if (h) % Function returned as zero when compression complete
                    errordlg('File not found by compression routine.', 'CERR compression');
                end
            end

        catch
            warndlg('That file name was not valid.', 'CERR file save')
            [fname pname] = uiputfile('*.mat','Save the plan data as:');
            saveFile = [pname fname];
            save(saveFile,'planC')
            if strcmp(toZipOrNot, 'yes') % User wants to compress output file
                outstr = gnuCERRCompression(saveFile,'compress');
                h = dos(outstr);
                if (h) % Function returned as zero when compression complete
                    errordlg('File not found by compression routine.', 'CERR compression');
                end
            end

        end
    case 'no'


end


% Unzip routines
% outstr = ['gzip.exe -vd ', fmat]
% dos(outstr)
