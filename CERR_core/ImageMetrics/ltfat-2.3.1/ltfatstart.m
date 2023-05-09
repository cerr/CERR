function ltfatstart(varargin)
%-*- texinfo -*-
%@deftypefn {Function} ltfatstart
%@verbatim
%LTFATSTART   Start the LTFAT toolbox
%   Usage:  ltfatstart;
%
%   LTFATSTART starts the LTFAT toolbox. This command must be run
%   before using any of the functions in the toolbox.
%
%   To configure default options for functions, you can use the
%   LTFATSETDEFAULTS function in your startup script. A typical startup
%   file could look like:
%
%     addpath('/path/to/my/work/ltfat');
%     ltfatstart;
%     ltfatsetdefaults('sgram','nocolorbar');
%
%   This will add the main LTFAT directory to you path, start the
%   toolbox, and configure SGRAM to not display the colorbar.
%
%   The function walks the directory tree and adds a subdirectory 
%   to path if the directory contain a [subdirectory,init.m] 
%   script setting a status variable to some value greater than 0.   
%   status==1 identifies a toolbox module any other value just a
%   directory to be added to path.
%
%   LTFATSTART(0) supresses any status messages.
%
%   !!WARNING for MATLAB users!!
%   ----------------------------
%
%   The function indirectly calls clear all, which clears all your global
%   and persistent variables. It comes with calling javaaddpath in
%   blockproc/blockprocinit.m. You can avoid calling it by passing 
%   additional 'nojava' flag.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/ltfatstart.html}
%@seealso{ltfatsetdefaults, ltfatmex, ltfathelp, ltfatstop}
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

%   AUTHOR : Peter L. Soendergaard, Zdenek Prusa
%   TESTING: NA

%% PKG_ADD: ltfatstart(0); 

do_java = 1;
ltfatstartprint=1;
if nargin>0
    scalarIds = cellfun(@isscalar,varargin);
    nojavaIds = strcmpi('nojava',varargin);
    
    if ~all(scalarIds | nojavaIds)
        error(['LTFATSTART: Only a single scalar and flag, '...
               '''nojava'' are recognized']);
    end
    
    if any(nojavaIds)
        do_java = 0;
    end
    
    scalars = varargin(scalarIds);
    if numel(scalars)>1
        error('LTFATSTART: Only a single scalar can be passed.');  
    elseif numel(scalars) == 1
        ltfatstartprint=scalars{1};
    end
end;

% Sometimes the run command used further does not return back to the 
% current directory, here we explicitly store the current directory and 
% cd to it at the end or is something goes wrong.
currdir = pwd;

% Get the basepath as the directory this function resides in.
% The 'which' solution below is more portable than 'mfilename'
% becase old versions of Matlab does not have "mfilename('fullpath')"
basepath=which('ltfatstart');
% Kill the function name from the path.
basepath=basepath(1:end-13);

pathCell = regexp(path, pathsep, 'split');
if ispc  % Windows is not case-sensitive
   bponPath = any(strcmpi(basepath, pathCell));
else
   bponPath = any(strcmp(basepath, pathCell));
end

if ~bponPath % To avoid recursion during pkg load
    addpath(basepath);
end

bp=basepath;
 
% Load the version number
[FID, MSG] = fopen ([bp,filesep,'ltfat_version'],'r');
if FID == -1
    error(MSG);
else
    ltfat_version = fgetl (FID);
    fclose(FID);
end

ignored_dirs_common = {[filesep(),'mat2doc'],...
                       [filesep(),'src']};

ignored_inits = {};
if ~do_java
    ignored_inits{end+1} = {'blockprocinit.m',1};
end

%% --- Check for old versions of Octave and Matlab
if isoctave
   major_rq=3;
   minor_rq=6;
   intp='Octave';
   req_versionname='3.6.0';
   ignore_dirs = [{[filesep(),'mex']},...
                  ignored_dirs_common];
else
   major_rq=7;
   minor_rq=9;
   intp='Matlab';
   req_versionname='2009b';
   ignore_dirs = [{[filesep(),'oct']},...
                  ignored_dirs_common];
end;

% Split into major and minor version
s=version;
stops=find(s=='.');
major_no  = str2num(s(1:stops(1)));
if numel(stops)==1
  minor_no  = str2num(s(stops(1)+1:end));
  bugfix_no = 0;
else
  minor_no  = str2num(s(stops(1)+1:stops(2)));
  bugfix_no = str2num(s(stops(2)+1:end));
end;

% Do the check, multiply by some big number to make the check easy
if major_rq*1000+minor_rq>major_no*1000+minor_no
  warning(['Your version of %s is too old for this version of LTFAT ' ...
         'to function proberly. Your need at least version %s of %s.'],...
	  intp,req_versionname,intp);
end;


%% -----------  install the modules -----------------

modules={};
nplug=0;

% List all files in base directory
d=dir(basepath);

% Pick only valid directories and wrap it in a cell array
d={d(arrayfun(@(dEl) dEl.isdir && ~strcmp(dEl.name(1),'.'),d))};
basedir = {filesep};

while ~isempty(d)
  for ii=1:length(d{1})
    name=d{1}(ii).name;
  
    % Skip ignored directories
    if any(cellfun(@(iEl) strcmp([basedir{1},name],iEl),ignore_dirs))
      continue;
    end
    
    % Store only valid subdirectories, we will go trough them later
    dtmp = dir([bp,basedir{1},name]);
    dtmp = dtmp(arrayfun(@(dEl) dEl.isdir && ~strcmp(dEl.name(1),'.'),dtmp));
    if ~isempty(dtmp)
      d{end+1} = dtmp;
      % Store base directory too
      basedir{end+1} = [basedir{1},name,filesep];
    end
  
    % The file is a directory and it does not start with '.' This could
    % be a module
    initfilename = [lower(name),'init.m'];
    initfilefullpath = [bp,basedir{1},name,filesep,initfilename];
    if ~exist(initfilefullpath,'file')
      continue
    end;
    
    % Now we know that we have found a module
  
    % Set 'status' to zero if the module forgets to define it.
    status=0;
  
    module_version=ltfat_version;
     
    % Add the module dir to the path
    addpath([bp,basedir{1},name]);
    
    iffound = cellfun(@(iEl) strcmpi(initfilename,iEl{1}),ignored_inits);
    
    if any(iffound)
        status = ignored_inits{iffound}{2};
    else
        % Execute the init file to see if the status is set.
        % We are super paranoid co we wrap the call to a try block
        try
            run(initfilefullpath);
        catch
            % If the run command breaks, it might not cd back to the
            % original directory. We do it manually here:
            cd(currdir);
        end
    end
    
    if status>0
      % Only store top-level modules
      if status==1 && strcmp(basedir{1},filesep)
        nplug=nplug+1;
        modules{nplug}.name=name;
        modules{nplug}.version=module_version;
      end;
    else
      % Something failed, restore the path
      rmpath([bp,basedir{1},name]);
    end;
  end;
  % Remove the just processed dir from the list
  basedir(1) = [];
  d(1) = []; 
end


% Check if Octave was called using 'silent'
%if isoctave
%  args=argv;
%  for ii=1:numel(args)
%    s=lower(args{ii});
%    if strcmp(s,'--silent') || strcmp(s,'-q')
%      printbanner=0;
%    end;
%  end;
%end;

if ltfatstartprint
  try
    s=which('comp_pgauss');
    if isempty(s)
      error('comp_pgauss not found, something is wrong.')
    end;
  
    if strcmp(s(end-1:end),'.m')
      backend = 'LTFAT is using the script language backend.';
    else
      if isoctave
        backend = 'LTFAT is using the C++ Octave backend.';
      else
        backend = 'LTFAT is using the MEX backend.';
      end;
    end;
  catch
    backend = 'Error with backend, consider running "ltfatmex clean" immediately.';
  end; 
  
  banner = sprintf(['LTFAT version %s. Copyright 2005-2018 Peter L. Soendergaard. ' ...
                    'For help, please type "ltfathelp". %s'], ...
                   ltfat_version,backend);
  
  disp(banner);
  
  if ~isoctave() && do_java
      disp('(Your global and persistent variables have just been cleared. Sorry.)');
  end
  
  if exist('ltfat_binary_notes.m','file')
    ltfat_binary_notes;    
  end;

end;

if isoctave()
    % On Windows the run command might not change back to the original path
    cd(currdir); 
end

%% ---------- load information into ltfathelp ------------
clear ltfatarghelper;
% As comp is now in the path, we can call ltfatarghelper
ltfatsetdefaults('ltfathelp','versiondata',ltfat_version,...
                 'modulesdata',modules);

%% ---------- other initializations ---------------------

% Force the loading of FFTW, necessary for Matlab 64 bit on Linux. Thanks
% to NFFT for this trick.
fft([1,2,3,4]);


