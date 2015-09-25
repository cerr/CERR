function CERRStatusString(str, dispFlag)
%"CERRStatusString"
%   Display a status string in the console and/or in the CERR Gui.
%
%LM:  JOD, 3 Jan 02.
%     JOD, 7 May 03, Changed CERRStatusString format.
%
%   If flag = 'both' or is undefined, status goes to console and CERR
%   GUI.  If flag = 'gui', status goes only to gui.  If flag = 'console'
%   status goes only to console.
%
%Usage:
%   CERRStatusString(str, dispFlag)
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

global stateS

%Check options to see if StatusString should be muted, only display to the GUI.
if isempty(stateS)
    optS = CERROptions;
elseif isfield(stateS, 'optS');
    optS = stateS.optS;    
else
    optS = [];
end
   
if ~isempty(optS) && isfield(optS, 'CERRStatusStringEnabled') 
    if ~optS.CERRStatusStringEnabled
        dispFlag = 'gui';
    end
end    

if ~exist('dispFlag','var')
    dispFlag = 'both';   
end

if ishandle(1)
    g = gcf;
end

%Also write non-empty strings to the matlab console:
if strcmpi(dispFlag, 'both') || strcmpi(dispFlag, 'console')
    if ~strcmp(str,'')
        disp(['CERR>>  ' str])
    end
end

h = [];
try
    h = stateS.handle.CERRSliceViewer;
end


if ishandle(h)
    set(0,'CurrentFigure',h);
    
    if strcmpi(dispFlag, 'both') || strcmpi(dispFlag, 'gui')
        try
            set(stateS.handle.CERRStatus,'string',str)
            drawnow
        end
        
        %return to old figure
        if ishandle(1)
            set(0,'CurrentFigure',g);
        end
    end
end


