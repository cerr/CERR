function addCERRFigureHandle(handle, name)
%function addCERRFigureHandle(handle, name)
%after creating a new figure within the context of CERR, this function should be called
%so that the program can close the figure if CERR is shut down entirely.
%The handle can also be referenced from any function using global CERRHandlesC.
%-Note that the CloseRequestFcn is modified.  Any changes made to the CloseRequestFcn after this function
% is called should include a call to removeCERRFigureHandle.
%-'name' should be the same as the tag for the figure.
%
% 15 Aug 02, V H Clark
%LM  28 Oct 02, JOD
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

CERRHandlesC = stateS.CERRHandlesC

if isfield(CERRHandlesC{end}, name)
  handleLocation = getfield(CERRHandlesC{end}, name);
else
  handleLocation = length(CERRHandlesC);
  CERRHandlesC{end+1} = CERRHandlesC{end}; %move the index structure cell
  CERRHandlesC{end} = setfield(CERRHandlesC{end}, name, handleLocation);
end

CERRHandlesC{handleLocation} = handle;

% fix the figure to call 'removeCERRFigureHandle' on close.  If a CloseRequestFcn is changed in the code,
% it should include a call to 'removeCERRFigureHandle'.
prevCRF = get(handle, 'CloseRequestFcn');
set(handle, 'CloseRequestFcn', [prevCRF ', removeCERRFigureHandle(''' name ''')']);

stateS.CERRHandlesC = CERRHandlesC;