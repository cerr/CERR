function ltfatmex(varargin)
%-*- texinfo -*-
%@deftypefn {Function} ltfatmex
%@verbatim
%LTFATMEX   Compile Mex/Oct interfaces
%   Usage:  ltfatmex;
%           ltfatmex(...);
%
%   LTFATMEX compiles the C backend in order to speed up the execution of
%   the toolbox. The C backend is linked to Matlab and Octave through Mex
%   and Octave C++ interfaces.
%   Please see INSTALL-Matlab or INSTALL-Octave for the requirements.
%
%   The action of LTFATMEX is determined by one of the following flags:
%
%     'compile'  Compile stuff. This is the default.
%
%     'clean'    Removes the compiled functions.
%
%     'test'     Run some small tests that verify that the compiled
%                functions work.
%
%   The target to work on is determined by on of the following flags.
%
%   General LTFAT:
%
%     'lib'      Perform action on the LTFAT C library.
%
%     'mex'      Perform action on the mex / oct interfaces.
%
%     'pbc'      Perform action on the PolyBoolClipper code for use with MULACLAB
%
%     'auto'     Choose automatically which targets to work on from the 
%                previous ones based on the operation system etc. This is 
%                the default.
%
%   Block-processing framework related:
%
%     'playrec'  Perform action on the playrec code for use with real-time
%                block streaming framework.
%
%     'java'     Perform compilation of JAVA classes into the bytecode.
%                The classes makes the GUI for the blockproc. framework.
%
%   Other:
%
%      'verbose' Print action details. 
%
%      'debug'   Build a debug version. This will disable compiler 
%                optimizations and include debug symbols.
%                
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/ltfatmex.html}
%@end deftypefn

% Copyright (C) 2005-2016 Peter L. Soendergaard <peter@sonderport.dk>.
% This file is part of LTFAT version 2.3.1
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

%   AUTHOR : Peter L. Soendergaard.
%   TESTING: NA
%   REFERENCE: NA

% Verify that comp_pgauss is in path
if ~exist('comp_pgauss','file')
  disp(' ');
  disp('--- LTFAT - The Linear Time Frequency Analysis toolbox. ---');
  disp(' ')
  disp('To start the toolbox, call LTFATSTART as the first command.');
  disp(' ');
  return;
end;

bp=mfilename('fullpath');
bp=bp(1:end-length(mfilename));


definput.flags.target={'auto','lib','mex','pbc','playrec','java','blockproc'};
% This has to be also defined 
definput.flags.comptarget={'release','debug'};
definput.flags.command={'compile','clean','test'};
definput.flags.verbosity={'noverbose','verbose'};
definput.keyvals.jobs = [];

s = which('ltfatarghelper');
if strcmpi(mexext,s(end-numel(mexext)+1:end))
   % We must avoid calling corrupt ltfatarghelper.mexext
   % The following must not fail 
   try
       ltfatarghelper({},struct(),{});
   catch
       if any(strcmpi('verbose',varargin))
           fprintf('Removing corrupt ltfatarghelper.%s',mexext);
       end
       delete(s);
       % Now there is just a ltfatarghelper.m
   end
end

[flags,kv]=ltfatarghelper({},definput,varargin);

% Remember the current directory.
curdir=pwd;

% Compile backend lib?
do_lib  = flags.do_lib || flags.do_auto;
% Compile MEX/OCT interfaces?
do_mex  = flags.do_mex || flags.do_auto;
% Compile MEX PolyBoolClipper.mex
do_pbc  = flags.do_pbc || flags.do_auto;
% Compile MEX playrec.mex... using Portaudio library.
% (relevant only for the bloc processing framework)
do_playrec  = flags.do_playrec || flags.do_blockproc;
% Compile Java classes containing GUI for the bloc proc. framework.
do_java  = flags.do_java || flags.do_blockproc;

if isoctave
	extname='oct';
    ext='oct';
else
    extname='mex';
    ext=mexext;
end;

fftw_lib_names = {'fftw3', 'fftw3f' };

% Check if we are on Windows
if ispc
    makefilename='Makefile_mingw';
    make_exe = 'mingw32-make';
    sharedExt = 'dll';
    %fftw_lib_names = {'fftw3', 'fftw3f' };
    % The pre-compiled Octave for Windows comes only in 32bit version (3.6.4)
    % We use different Makefiles
    if isoctave
      makefilename='Makefile_mingwoct';      
    end
end;

% Check if we are on Unix-type system
if isunix
   makefilename='Makefile_unix';
   make_exe = 'make';
   sharedExt = 'so';
end;

% Check if we are on Mac
if ismac
   makefilename='Makefile_mac';
   make_exe = 'make';
   sharedExt = 'dylib';
end;


clear mex;
% -------------- Handle cleaning --------------------------------
if flags.do_clean

  if do_lib
    disp('========= Cleaning libltfat ===============');
    cd([bp,'lib',filesep,'ltfatcompat']);
    callmake(make_exe,makefilename,'target','clean',flags.verbosity);
    %[status,result]=system([make_exe, ' -f ',makefilename,' clean']);
    %disp('Done.');    
  end;
  
  if do_mex
    fprintf('========= Cleaning %s interfaces =========\n', upper(extname));
     cd([bp,extname]);
     callmake(make_exe,makefilename,'target','clean','ext',ext,flags.verbosity);
     %[status,result]=system([make_exe, ' -f ',makefilename,' clean',...
     %                ' EXT=',ext]); 
  end;
  
  if do_pbc
     % Use the correct makefile 
     makefilename_pbc = makefilename;
     if isoctave
       if ~strcmpi(makefilename(end-2:end),ext)
          makefilename_pbc = [makefilename,ext];
       end
    end 
      
    disp('========= Cleaning PolyBoolClipper ====================');
    cd([bp,'thirdparty',filesep,'polyboolclipper']);
    clear mex; 
    callmake(make_exe,makefilename_pbc,'target','clean','ext',mexext,flags.verbosity);
    %[status,result]=system([make_exe, ' -f ',makefilename,' clean',' EXT=',mexext]);
  end;
  
  if do_playrec
     % Use the correct makefile 
     if isoctave
       if ~strcmpi(makefilename(end-2:end),ext)
          makefilename = [makefilename,ext];
       end
    end 
      
    disp('========= Cleaning PLAYREC ================');
    cd([bp,'thirdparty',filesep,'Playrec']);
    clear mex; 
    %[status,result]=system([make_exe, ' -f ',makefilename,' clean',' EXT=',mexext]);
    callmake(make_exe,makefilename,'target','clean','ext',mexext,flags.verbosity); 
  end;
  
  if do_java
    disp('========= Cleaning JAVA ================');
    cd([bp,'blockproc',filesep,'java']);
    %[status,result]=system([make_exe,' clean']);
    callmake(make_exe,[],'target','clean',flags.verbosity);
  end;

  cd(curdir);
end;

% -------------- Handle compiling  --------------------------------

if flags.do_compile
  if do_lib
    disp('========= Compiling libltfat ==============');
    cd([bp,'lib',filesep,'ltfatcompat']);
    clear mex; 
    
    dfftw = ['-l',fftw_lib_names{1}];
    sfftw = ['-l',fftw_lib_names{2}];
    if ispc && ~isoctave
        fftw_lib_found_names = searchfor(bp,fftw_lib_names,sharedExt);
        if ~isempty(fftw_lib_found_names)
           dfftw = ['-l:',fftw_lib_found_names{1}];
           sfftw = ['-l:',fftw_lib_found_names{2}];
       end
    end
      % DFFTW and SFFTW are not used in the unix_makefile
      [status,result] = callmake(make_exe,makefilename,'matlabroot','arch',...
                       'dfftw',dfftw,'sfftw',sfftw,flags.verbosity,...
                       'comptarget',flags.comptarget,'jobs',kv.jobs);
      if(~status)
        disp('Done.');
      else
        error('Failed to build LTFAT libs:\n %s',result);
      end
    %end;
  end;
  
  if do_mex
    fprintf('========= Compiling %s interfaces ========\n', upper(extname));
    clear mex; 
    cd([bp,extname]);
    
    dfftw = ['-l',fftw_lib_names{1}];
    sfftw = ['-l',fftw_lib_names{2}];
    if ~isoctave
        fftw_lib_found_names = searchfor(bp,fftw_lib_names,sharedExt);
        if ~isempty(fftw_lib_found_names)
            if ~ismac
               dfftw = ['-l:',fftw_lib_found_names{1}];
               sfftw = ['-l:',fftw_lib_found_names{2}];
            else
                % We need a full path here.
               dfftw = [binDirPath(),filesep,fftw_lib_found_names{1}];
               sfftw = [binDirPath(),filesep,fftw_lib_found_names{2}];               
            end
       end
    end
    
    [status,result] = callmake(make_exe,makefilename,'matlabroot','arch',...
                      'ext',ext,'dfftw',dfftw,'sfftw',sfftw,...
                      flags.verbosity,...
                      'comptarget',flags.comptarget,'jobs',kv.jobs);

    if(~status)
      disp('Done.');
    else
      error('Failed to build %s interfaces: %s \n',upper(extname),result);
    end
  end;
  
  if do_pbc
    makefilename_pbc = makefilename;
    if isoctave
       if ~strcmpi(makefilename(end-2:end),ext)
          makefilename_pbc = [makefilename,ext];
       end
    end  
      
    disp('========= Compiling PolyBoolClipper ===================');
    % Compile PolyBoolClipper mex file for use with mulaclab
    cd([bp,'thirdparty',filesep,'polyboolclipper']);
    clear mex; 
    [status,result] = callmake(make_exe,makefilename_pbc,'matlabroot','arch',...
                      'ext',ext,flags.verbosity);

    if(~status)
      disp('Done.');
    else
      error('Failed to build PlyBoolClipper:\n %s',result);
    end
  end;
  if do_playrec
    disp('========= Compiling PLAYREC ===============');
    cd([bp,'thirdparty',filesep,'Playrec']);
    clear mex; 
    % Compile the Playrec (interface to portaudio) for the real-time block-
    % stream processing

     portaudioLib = '-lportaudio';

     binArchPath = binDirPath();
       playrecRelPath = ['thirdparty',filesep,'Playrec'];

       foundPAuser = [];
       if ispc
          foundPAuser = dir([bp,playrecRelPath,filesep,'*portaudio*',sharedExt,'*']);
       end
       
       foundPAmatlab = [];
       if ~isoctave
          % Check if portaudio library is present in the Matlab installation
          foundPAmatlab = dir([binArchPath,filesep,'*portaudio*',sharedExt,'*']);
       end
       
       if ~isempty(foundPAuser)
          if numel(foundPAuser)>1
             error('Ambiguous portaudio libraries in %s. Please leave just one.',playrecRelPath);
          end
          foundPAuser = foundPAuser(1).name;

       elseif ~isempty(foundPAmatlab)
          if numel(foundPAmatlab)>1
             if ispc 
                %This should not happen on Windows
                %Use the first one on Linux
                error('Ambiguous portaudio libraries in %s.',binArchPath);
             end
          end
             foundPAmatlab = foundPAmatlab(1).name;
       else
          if ispc && isoctave || ispc
          error(['Portaudio not found. Please download Portaudio http://www.portaudio.com\n',...
                 'and build it as a shared library and copy it to the\n',...
                 '%s directory. \n'],playrecPath);
          end
       end

    if isoctave
       if ~strcmpi(makefilename(end-2:end),ext)
          makefilename = [makefilename,ext];
       end
    end
    
    doPAuser = ~isempty(foundPAuser);
    doPAmatlab = ~isempty(foundPAmatlab) && ~doPAuser;

    if doPAmatlab 
       if ismac
          % Full path is needed on MAC since 
          % clang does not understand -l: prefix.
          portaudioLib = [binArchPath,filesep,foundPAmatlab];    
       else
          portaudioLib = ['-l:',foundPAmatlab]; 
       end
       fprintf('    ...using %s from Matlab installation.\n',foundPAmatlab);
    elseif doPAuser
        portaudioLib = ['-l:',foundPAuser]; 
        fprintf('   ...using %s from ltfat%s%s.\n',...
                  foundPAuser,filesep,playrecRelPath);
    end

    [status,result] = callmake(make_exe,makefilename,'matlabroot','arch',...
                      'ext',mexext,'portaudio',portaudioLib,'extra','HAVE_PORTAUDIO',...
                      flags.verbosity);
    if(~status)
      disp('Done.');
    else
      error('Failed to build PLAYREC:\n %s',result);
    end
  end;
  
  if do_java
    disp('========= Compiling JAVA classes ===================');
    % Compile the JAVA classes
    cd([bp,'blockproc',filesep,'java']);
    clear mex; 
    [status,result] = callmake(make_exe,'Makefile',flags.verbosity);
    if(~status)
      disp('Done.');
    else
      error('Failed to build JAVA classes:\n %s',result);
    end
  end;
end;

% -------------- Handle testing ---------------------------------------

if flags.do_test
  
  if do_mex
    
    fprintf('========= Testing %s interfaces ==========\n', extname);
    fprintf('1.: Test if comp_pgauss.%s was compiled: ',ext);
    fname=['comp_pgauss.',ext];
    if exist(fname,'file')
      disp('SUCCESS.');
    else
      disp('FAILED.');
    end;
    
    fprintf('2.: Test if pgauss executes:              ');
    pgauss(100);
    % If the execution of the script makes it here, we know that pgauss
    % did not crash the system, so we can just print success. Same story
    % with the following entries.
    disp('SUCCESS.');

    fprintf('3.: Test if fftreal executes:             ');
    fftreal(randn(10,1),10);
    disp('SUCCESS.');

    fprintf('4.: Test if dgt executes:                 ');
    dgt(randn(12,1),randn(12,1),3,4);
    disp('SUCCESS.');

    
  end;
  
end;

% Jump back to the original directory.
cd(curdir);


function status = filesExist(filenames)
   if(~iscell(filenames))
      filenames={filenames};
   end
   for ii=1:length(filenames)
      filename = filenames{ii};
      if(~exist(filename,'file'))
         error('%s: File %s not found.',mfilename,filename);
      end
   end
 
function found_files=searchfor(bp,files,sharedExt)

found_names = {};
      if ispc 
         for ii=1:numel(files) 
            % Search the ltfat/mex lib
            L = dir([bp,'mex',filesep,'*',files{ii},'*.',sharedExt]);
            if isempty(L)
                error(['%s: %s could not be found in ltfat/mex subdir.',...
                       ' Please download the FFTW dlls and install them.'],...
                      upper(mfilename),files{ii});
            end
            found_files{ii} = L(1).name;
            fprintf('   ...using %s from ltfat/mex.\n',L(1).name);
         end
      elseif isunix
          for ii=1:numel(files)
             L = dir([binDirPath(),filesep,'*',files{ii},'*.',sharedExt,'*']); 
             
             if isempty(L)
                 error('%s: Matlab FFTW libs were not found. Strange.',...
                      upper(mfilename));
             end

             found_files{ii} = L(1).name;

             fprintf('   ...using %s from Matlab installation.\n',...
                     found_files{ii});
          end
          
      end;

function path=binDirPath()
path = [matlabroot,filesep,'bin',filesep,computer('arch')];
   
function [status,result]=callmake(make_exe,makefilename,varargin)
%CALLMAKE   
%   Usage:  callmake(make_exe,makefilename);
%           callmake(make_exe,makefilename,'matlabroot',matlabroot,...);
%
%   `callmake(make_exe,makefilename)` is a platform independent wrapper for
%   calling the make command `make_exe` on `makefilename` file. When 
%   `makefilename` is missing or is empty, the default `Makefile` file is
%   used.
%   
%   `callmake(...,'target',target)` used `target` from the makefile.
%
%   Flags:
%
%       matlabroot:   Pass MATLABROOT=matlabroot variable to the makefile.
%
%       arch:         Pass ARCH=computer('arch') variable to the makefile.
%
%   Key-value parameters:
%
%       ext:          Pass EXT variable to the makefile.
%
%       portaudio:    Pass PORTAUDIO variable to the makefile.
%
%       dfftw:        Pass DFFTW variable to the makefile.
%
%       sfftw:        Pass SFFTW variable to the makefile.
  

  if nargin < 2 || isempty(makefilename)
     systemCommand = make_exe; 
  else
     systemCommand = [make_exe, ' -f ',makefilename];
  end
  definput.flags.matlabroot={'none','matlabroot'};
  definput.flags.arch={'none','arch'};
  definput.keyvals.ext=[];
  definput.keyvals.dfftw=[];
  definput.keyvals.sfftw=[];
  definput.keyvals.target=[];
  definput.keyvals.comptarget=[];
  definput.keyvals.portaudio=[];
  definput.keyvals.extra=[];
  definput.keyvals.jobs =[];
  definput.flags.verbosity={'noverbose','verbose'};
  [flags,kv]=ltfatarghelper({},definput,varargin);
  
  if flags.do_matlabroot
     systemCommand = [systemCommand, ' MATLABROOT=','"',matlabroot,'"']; 
  end
  
  if flags.do_arch
     systemCommand = [systemCommand, ' ARCH=',computer('arch')]; 
  end
  
  if ~isempty(kv.ext)
     systemCommand = [systemCommand, ' EXT=',kv.ext]; 
  end
  
  if ~isempty(kv.dfftw)
     systemCommand = [systemCommand, ' DFFTW=',kv.dfftw]; 
  end
  
  if ~isempty(kv.sfftw)
     systemCommand = [systemCommand, ' SFFTW=',kv.sfftw]; 
  end
  
  if ~isempty(kv.portaudio)
     systemCommand = [systemCommand, ' PORTAUDIO=',kv.portaudio]; 
  end
  
  if ~isempty(kv.comptarget) && ~strcmpi(kv.comptarget,'release')
     systemCommand = [systemCommand, ' COMPTARGET=',kv.comptarget];
  end

  if ~isempty(kv.extra)
     systemCommand = [systemCommand, ' ',kv.extra,'=1']; 
  end
  
  if ~isempty(kv.target)
     systemCommand = [systemCommand,' ',kv.target];  
  end
  
  if ~isempty(kv.jobs)
      if isnumeric(kv.jobs)
        systemCommand = [systemCommand,sprintf(' -j%d',kv.jobs)];
      elseif ischar(kv.jobs)
        systemCommand = [systemCommand,sprintf(' -j%s',kv.jobs)];  
      end
  end

  if flags.do_verbose
      fprintf('Calling:\n    %s\n\n',systemCommand);
  end
    
  [status,result]=system(systemCommand);
  
  if flags.do_verbose && ~isoctave
     disp(result); 
  end
  
  


      


