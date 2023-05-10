function loadlibltfat(varargin)
global libltfat_intptrstr;

definput.keyvals.lib='libltfat.so';
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
   
    makecmd = [makecmd, ' MODULE=libltfat'];
    makecmd = [makecmd, ' munit -j12'];
    makecmd = [makecmd, ' MATLABROOT=', matlabroot];
    makecmd = [makecmd, sprintf(' COMPTARGET=%s',flags.comptarget)];
    
    if flags.do_cpp
        makecmd = [makecmd, ' USECPP=1'];
    end
    
    if kv.compiler
        makecmd = [makecmd, sprintf(' CC=%s',kv.compiler)];
    end
    
    if flags.do_verbose
        disp(makecmd);
        system(makecmd);
    else
        [status,result] = system(makecmd);
        if status ~=0, error(result);  end
    end
end
    
if libisloaded(libname) 
    if flags.do_reload || flags.do_recompile 
        unloadlibrary(libname);
    else
        error('%s: libltfat is already loaded. Use ''reload'' to force reload.',upper(mfilename));
    end
end

warning('off');
headerpath = [libltfatpath,'build',filesep,'ltfat.h'];
loadlibrary(libpath,headerpath,'mfilename','libltfatprotofile.m');
warning('on');

intbitsize = 8*calllib('libltfat','ltfat_int_size');
libltfat_intptrstr = sprintf('int%dPtr',intbitsize);









%
%   Url: http://ltfat.github.io/doc/libltfat/modules/libltfat/testing/mUnit/loadlibltfat.html

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

