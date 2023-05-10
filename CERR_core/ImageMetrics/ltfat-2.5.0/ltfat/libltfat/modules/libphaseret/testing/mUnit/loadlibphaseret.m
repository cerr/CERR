function loadlibphaseret(varargin)

definput.keyvals.lib='libphaseret.so';
definput.flags.phase={'load','reload','recompile'};
definput.flags.comptarget={'fulloptim','release','debug'};
definput.flags.verbosity={'quiet','verbose'};
definput.flags.corcpp={'c','cpp'};
definput.keyvals.compiler = [];

[flags,kv,lib]=ltfatarghelper({'lib'},definput,varargin);

[~,libname]=fileparts(lib);
currdir = fileparts(mfilename('fullpath'));
libltfatpath = [currdir, filesep, '..', filesep,'..',filesep,'..',filesep,'..',filesep];
libpath = [libltfatpath, filesep,'build',filesep,lib];
iscompiled = exist(libpath,'file');

makecmd = ['make -C ',libltfatpath];
if ~iscompiled || flags.do_recompile
    [status,result] = system([makecmd, ' clean']);
    if status ~=0, error(result);  end    
   
    makecmd = [makecmd, ' MODULE=%s'];
    makecmd = [makecmd, ' munit -j12'];
    makecmd = [makecmd, ' MATLABROOT=', matlabroot];
    makecmd = [makecmd, sprintf(' COMPTARGET=%s',flags.comptarget)];
    
    if flags.do_cpp
        makecmd = [makecmd, ' USECPP=1'];
    end
    
    if kv.compiler
        makecmd = [makecmd, sprintf(' CC=%s',kv.compiler)];
    end
       
    makecmd_libltfat = sprintf(makecmd,'libltfat');
    if flags.do_verbose
        disp(makecmd_libltfat);
        system(makecmd_libltfat);
    else
        [status,result] = system(makecmd_libltfat);
        if status ~=0, error(result);  end
    end
        
    makecmd_libphaseret = sprintf(makecmd,'libphaseret');
    if flags.do_verbose
        disp(makecmd_libphaseret);
        system(makecmd_libphaseret);
    else
        [status,result] = system(makecmd_libphaseret);
        if status ~=0, error(result);  end
    end
end
    
if libisloaded(libname) 
    if flags.do_reload || flags.do_recompile 
        unloadlibrary(libname);
    else
        error('%s: libphaseret is already loaded. Use ''reload'' to force reload.',upper(mfilename));
    end
end

warning('off');
headerpath = [libltfatpath,'build',filesep,'phaseret.h'];
headerpath_libltfat = [libltfatpath,'build',filesep,'ltfat.h'];
loadlibrary(libpath,headerpath,'mfilename','libphaseretprotofile.m','addheader',headerpath_libltfat);
warning('on');

%
%   Url: http://ltfat.github.io/doc/libltfat/modules/libphaseret/testing/mUnit/loadlibphaseret.html

% Copyright (C) 2005-2022 Peter L. Soendergaard <peter@sonderport.dk> and others.
% This file is part of LTFAT version 2.5.0
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

