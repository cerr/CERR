function pathStr = getCERRPath(stateS)
%"getCERRPath"
%   Get the path to the current CERR installation,
%   including the trailing slash.
%LM:  30 Dec 02, JOD.
%     05 Jul 05, JRA.
%
%Usage:
%   pathStr = getCERRPath

% global stateS

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
