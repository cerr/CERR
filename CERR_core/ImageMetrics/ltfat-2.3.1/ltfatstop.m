function ltfatstop(varargin)
%-*- texinfo -*-
%@deftypefn {Function} ltfatstop
%@verbatim
%LTFATSTOP   Stops the LTFAT toolbox
%   Usage:  ltfatstop;
%
%   LTFATSTOP removes all LTFAT subdirectories from the path.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/ltfatstop.html}
%@seealso{ltfatstart}
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

%% PKG_DEL: ltfatstop('notbasepath')

do_removebp = ~any(strcmpi('notbasepath',varargin));

dirlist = {};
jarsubpath = ['blockproc', filesep(), 'java', filesep(), 'blockproc.jar'];

% Old versions of Matlab does not have "mfilename('fullpath')"
pkg_folder = which(mfilename);
% Kill the function name from the path. -3 for .m and /
pkg_folder=pkg_folder(1:end-numel(mfilename)-3);   

d= dir(pkg_folder);
% Take only valid directories
d= {d(arrayfun(@(dEl) dEl.isdir && ~strcmp(dEl.name(1),'.'),d))};
basedir = {filesep()};
while ~isempty(d)
   for ii=1:numel(d{1})
      name = d{1}(ii).name;
  
      dtmp = dir([pkg_folder basedir{1},name]);
      dtmp = dtmp(arrayfun(@(dEl) dEl.isdir && ~strcmp(dEl.name(1),'.'),dtmp));
   
      if ~isempty(dtmp)
         d{end+1} = dtmp;
         basedir{end+1} = [basedir{1},name,filesep];
      end
         
      if exist([pkg_folder,basedir{1},name,filesep(),lower(name),'init.m'],'file')
          dirtmp = [pkg_folder,basedir{1},name];
          pathCell = regexp(path, pathsep, 'split');
          if ispc  % Windows is not case-sensitive
              onPath = any(strcmpi(dirtmp, pathCell));
          else
              onPath = any(strcmp(dirtmp, pathCell));
          end
          
          % Add to the list only if it is already in path
          if onPath
             dirlist{end+1} = [basedir{1},name];
          end
      end  
   end
   basedir(1) = [];
   d(1) = []; 
end

% Remove directories from the path
cellfun(@(dEl) rmpath([pkg_folder,dEl]),dirlist);

% Remove the root dir
pathCell = regexp(path, pathsep, 'split');
if ispc  % Windows is not case-sensitive
   onPath = any(strcmpi(pkg_folder, pathCell));
else
   onPath = any(strcmp(pkg_folder, pathCell));
end

% This can actually remove user hardcoded path to LTFAT's root.
if onPath && do_removebp
    rmpath(pkg_folder);
end

    
% Clean the classpath  
if ~isempty(which('javaclasspath'))
   try 
      jp = javaclasspath();
      if any(strcmp([pkg_folder filesep() jarsubpath],jp))
         javarmpath([pkg_folder, filesep(), jarsubpath]);
      end
   catch
      % Do nothing. At this point, user is most probably aware that
      % there is something wrong with the JAVA support.
   end
end

