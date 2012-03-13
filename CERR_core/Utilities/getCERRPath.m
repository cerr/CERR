function pathStr = getCERRPath
%"getCERRPath"
%   Get the path to the current CERR installation,
%   including the trailing slash.
%LM:  30 Dec 02, JOD.
%     05 Jul 05, JRA.
%
%Usage:
%   pathStr = getCERRPath
% copyright (c) 2001-2008, Washington University in St. Louis.
% Permission is granted to use or modify only for non-commercial, 
% non-treatment-decision applications, and further only if this header is 
% not removed from any file. No warranty is expressed or implied for any 
% use whatever: use at your own risk.  Users can request use of CERR for 
% institutional review board-approved protocols.  Commercial users can 
% request a license.  Contact Joe Deasy for more information 
% (radonc.wustl.edu@jdeasy, reversed).
global stateS

%Get path to gzip.exe
try
	str = which('CERR.root');
	if ispc
      indV = find(str == '\');
      ind = max(indV);
	elseif isunix
      indV = find(str == '/');
      ind = max(indV);
	end
	
	pathStr = str(1:ind);
catch
	%This catch exists because "which" cannot be executed from compiled code, 
	%so instead we use the stateS.workingDirectory, which is set when the 
	%viewer is first run.
    pathStr = stateS.workingDirectory;
end
