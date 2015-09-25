function viewImportLog
%
% Latest modifications  KU  26 Mar 2006
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.

global stateS planC

indexS = planC{end};

%Display list of import logs
if isempty(planC{indexS.importLog})
    CERRStatusString('No import log available.')
    return;
end
str = {planC{indexS.importLog}.startTime};
[logFile,ok] = listdlg('PromptString',{'Select log file to view:',...
                '',...
                'Import Date and Time:'},...
                'ListSize',[250 180],'SelectionMode','single',...
                'ListString',str,...
                'OKString', 'View log file');    
if ok == 0
    return
end

% diary on;
diary importLog.txt;

h = waitbar(0,'Retrieving log file...');

display(['Start time: ', planC{indexS.importLog}(logFile).startTime]);
display(['End time:   ', planC{indexS.importLog}(logFile).endTime]);
disp(' ');

file = planC{indexS.importLog}(logFile).importLog;
format compact
for i = 1 : length(file)
  disp(file{i});
  waitbar(i/length(file));
end
close(h); 


diary off;
if ispc
    %Open file in Notepad
    dos ('notepad importLog.txt &');
else
    edit importLog.txt;
end
delete importLog.txt;
%----------END OF FILE-----------------