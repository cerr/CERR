status=1;

%-*- texinfo -*-
%@deftypefn {Function} blockprocinit
%@verbatim
% Add entry to the dynamic classpath if JVM is present.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/blockproc/blockprocinit.html}
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
if ~isempty(which('javaaddpath')) 
   try
      % Here it gets somewhat confusing. This script is called in
      % ltfatstart, but the jar is created in ltfatmex. It prints nasty
      % warning, if it cannot find the jar. Adding a folder to the classpath,
      % which is then filled with compiled classes by ltfatmex is fine. 
      %
      % Moreover, according to the Matlab documentation:
      %
      % MATLAB calls the 'clear java' command whenever you change the dynamic path. 
      % It clears definition of all Java classes defined by files on the dynamic class path,
      % removes all variables from the base workspace, and removes all compiled scripts, functions,
      % global, persistent variables and MEX-functions from memory.

      jarFile = 'blockproc.jar';
      javaDirPath = [basepath,filesep,'blockproc',filesep,'java'];
      jarPath = [javaDirPath,filesep,jarFile];
      
      if exist(jarPath,'file')
         if any(cellfun(@(cpEl)strcmp(cpEl,javaDirPath),javaclasspath))
            javarmpath(javaDirPath);
         end
         % Adding a jar file. Once added to the classpath, it cannot be
         % deleted. Removing it from the classpath issues again the 'clear
         % java' command, but the jar cannot be removed while Matlab is
         % running at all.
         % http://www.mathworks.com/support/solutions/en/data/1-37JYLQ/?product=ML&solution=1-37JYLQ
         javaaddpath([basepath,filesep,'blockproc',filesep,'java',filesep,jarFile]);
      else
         % Adding directory with *.class files. Does not block.
         javaaddpath([basepath,filesep,'blockproc',filesep,'java']);
      end
   catch 
       % Use lasterr for Octave compatibility
       err=lasterr;
       if ltfatstartprint
           warning(sprintf('%s: JVM support not present.',upper(mfilename)));
       end;
   end
   
   % Check if Java is not only in a headless state
   % We are not using warning_isjavaheadless directly because it migh not
   % yet be in the path
 %  ge = javaMethod('getLocalGraphicsEnvironment','java.awt.GraphicsEnvironment');
 %  if javaMethod('isHeadless',ge)
 %      warning(sprintf(['%s: JRE is available in headless mode only. ',...
 %              'Block processing GUI will not work. Consider ',...
 %              'installing full JRE.'],upper(mfilename)));
 %  end
else
    if ltfatstartprint
        warning(sprintf('%s: Java toolbox not present.',upper(mfilename)));
    end;
end

