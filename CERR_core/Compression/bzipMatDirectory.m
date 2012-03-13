function  [Result] = bzipMatDirectory(userSelect, dirFlag)

% This function compresses a directory containing *.mat binary files
%   using bzip format.
% The function prompts the user to identify a file within desired
%   directory and then batches the conversion to and from this format.
% Output is 0 for errors and 1 otherwise
% UserSelect = 'compress' to bzip entire directory
%                 = 'uncompress' to decompress all *.mat.bz2 files in chosen directory
%dirFlag = not specified or 'subdirs'.  Use this option with userSelect = 'compress' to
%tar & compress all subdirectories under the user selected directory.  This is especially
%useful to compress RTOG archives.
%AIB 4/9/2002
%Latest modifications:
%JOD, 24 Mar 03, compression of subdirectories.
%
% copyright (c) 2001-2006, Washington University in St. Louis.
% Permission is granted to use or modify only for non-commercial, 
% non-treatment-decision applications, and further only if this header is 
% not removed from any file. No warranty is expressed or implied for any 
% use whatever: use at your own risk.  Users can request use of CERR for 
% institutional review board-approved protocols.  Commercial users can 
% request a license.  Contact Joe Deasy for more information 
% (radonc.wustl.edu@jdeasy, reversed).

compressionLevel = '1';  %'1' (fastest, 100K block size) - '9' (most compression, 900K block size)
                       %In informal test, '1' did about as well as '5'.

tic
Result = 1;


if nargin == 1

  switch lower(userSelect)
  case 'compress'
      [fname, pathname] = uigetfile('*.mat', ...
          'Select a *.mat file within directory you wish to compress');
      oldDir = pwd;
      cd(pathname);
      allStuff = dir(pathname);
      for i = 3 : length(allStuff)
          if strcmpi(midstring(allStuff(i).name, length(allStuff(i).name)-2, ...
                  length(allStuff(i).name) ), 'mat')
              outstr = gnuCERRCompression(strcat(pathname,allStuff(i).name), 'compress');
              if ~ischar(outstr)
                  Result = 0.;
                  warning(['Error in compression routine. File = ', allStuff(i).name])
              end
          end
      end
  case 'uncompress'
      [fname, pathname] = uigetfile('*.mat.bz2', ...
          'Select a *.mat.bz2 archive file within directory you wish to uncompress');
      oldDir = pwd;
      cd(pathname);
      allStuff = dir(pathname);
      for i = 3 : length(allStuff)
          if strcmpi(midstring(allStuff(i).name, length(allStuff(i).name)-6, ...
                  length(allStuff(i).name) ), 'mat.bz2')
              outstr = gnuCERRCompression(strcat(pathname,allStuff(i).name), 'uncompress');
              if ~ischar(outstr)
                  Result = 0.;
                  warning(['Error in compression routine. File = ', allStuff(i).name])
              end
          end
      end
  end

elseif nargin == 2  & strcmp(lower(userSelect),'compress')

  oldDir = pwd;
  switch lower(dirFlag)

    case 'subdirs'
      [pathname] = uigetdir(pwd, ...
          'Select a directory which contains subdirectories to be tarred and b-zipped.');
    cd(pathname);
    allStuff = dir(pathname);
    for i = 3 : length(allStuff)
      if allStuff(i).isdir == 1
        pathStr = getCERRPath;
        %tar and compress the subdirectory
        name = allStuff(i).name;
        strDir = [pathStr '/Compression/tar.exe -vcf ' name '.tar ' name];
        system(strDir,'-echo')
        tarFile = dir([name '.tar']);
        %next compress it:
        str = [pathname '\' name '.tar'];
        
        exec = [pathStr '/Compression/bzip2-102-x86-win32.exe -vz' compressionLevel ' ', str];
        system(exec,'-echo')
        %check for success
        bzFile = dir([str '.bz2']);

        if length(bzFile) == 0
          warning(['Failed to compress directory ' name '.  Not deleting subdirectory.'])
        elseif bzFile.bytes/tarFile.bytes > 0.001
          %looks OK, continue
          delstr = ['del ' str];
          system(delstr,'-echo');  %deletes tar file if bzip hasn't already
          %disp(['tar-file ' str ' deleted.'])
          str2 = ['rmdir /s /q ' pathname '\' name];
          system(str2,'-echo');
          disp(['Directory ' pathname '\' name ' deleted.'])
        else
          warning(['Failed to compress directory ' pathname '.  Not deleting subdirectory.'])
        end
      end
    end

  end

elseif nargin == 2  & strcmp(lower(userSelect),'uncompress')

  %%Not implemented yet.

  oldDir = pwd;
  switch lower(dirFlag)

  case 'compressed'
      [pathname] = uigetdir(pwd, ...
          'Select a directory which contains subdirectories to be uncompressed and untarred.');
    cd(pathname);
    allStuff = dir(pathname);

    for i = 3 : length(allStuff)
       name = allStuff(i).name;
      if ~allStuff(i).isdir & length(name) > 4
       if strcmp(name(end-3:end),'.bz2')
        %uncompress and untar the file
        str = [pathname '\' name];
        pathStr = getCERRPath;
        exec = [pathStr 'Compression/bzip2-102-x86-win32.exe -vd ', str];
        system(exec,'-echo')
        tarStr = [pathStr 'Compression/tar.exe -vxf ' name(1:end-4)];
        system(tarStr,'-echo')

        %did tar work?
        if isdir([pathname '\' name(1:end-8)])
          %delete tar file
          system(['del ' pathname '\' name(1:end-4)])
        end

        %if length(bzFile) == 0
        %  warning(['Failed to compress directory ' name '.  Not deleting subdirectory.'])
        %elseif bzFile.bytes/tarFile.bytes > 0.001
        %  %looks OK, continue
        %  delstr = ['del ' str];
        %  system(delstr,'-echo');  %deletes tar file if bzip hasn't already
        %  %disp(['tar-file ' str ' deleted.'])
        %  str2 = ['rmdir /s /q ' pathname '\' name];
        %  system(str2,'-echo');
        %  disp(['Directory ' pathname '\' name ' deleted.'])
        %else
        %  warning(['Failed to compress directory ' pathname '.  Not deleting subdirectory.'])
        %end
       end
      end
   end
  end

end

toc
