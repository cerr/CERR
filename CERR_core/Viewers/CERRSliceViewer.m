function CERRSliceViewer(varargin)
%function CERRSliceViewer(varargin)
%
%Description: Wrapper file to kick off the CERR slice viewer.  The main work is done
%by sliceCallBack.
%
%Globals:
%optS  -- options structure set in initCERRSlice
%planC -- the CERR plan cell array
%stateS  -- a structure to contain some extra information.
%
%Author: J. O. Deasy, deasy@radonc.wustl.edu
%
%
%Last Modified:  10 April 2002,  by A I Blanco.
%                16 August 2002, by V H Clark.
%                15 October 2002, by J O Deasy
%
%
%Copyright:
%This software is copyright J. O. Deasy and Washington University in St Louis.
%A free license is granted to use or modify but only for non-commercial non-clinical use.
%Any user-modified software must retain the original copyright and notice of changes if redistributed.
%Any user-contributed software retains the copyright terms of the contributor.
%No warranty or fitness is expressed or implied for any purpose whatsoever--use at your own risk.
%#function CERRHotKeys CERRSliceViewer
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

%global optS planC stateS CERRFile
global planC stateS

stateS = [];
planC  = [];

%Set Keypressfunction call back for ALL subsequent figures.
set(0,'DefaultFigureCreateFcn','set(gcbo,''WindowKeyPressFcn'',''CERRHotKeys'')')

%Detect and store working directory, in case this is the compiled version.
%This must go before any calls to getCERRPath
if ispc
     stateS.workingDirectory = [pwd '\'];
 elseif isunix
     stateS.workingDirectory = [pwd '/'];
else
     stateS.workingDirectory = [];
     error('Non Windows/Unix type system detected.')
end
disp(['Working Directory: ' stateS.workingDirectory]);

%splashScreen('on'); %Bring up the splash screen.

%Get options file
if nargin == 0    %Default to the CERROptions.m file stored in the CERR directory
  pathStr = getCERRPath;
  optName = [pathStr 'CERROptions.m'];
elseif nargin == 1 & ischar(varargin{:})  %UI to get options file: 'CERRSliceViewer -f'
  if strcmp(lower(varargin{:}),'-f')
    [fname, pathname] = uigetfile('*.m','Select options .m file');
    optName = [pathname fname];
  else
    error('Wrong option string: to use default option file (CERROptions.m) type ''CERRSliceViewer -f''')
  end
end

optS = opts4Exe(optName);


[fname, pathname] = uigetfile('*.mat;*.bz2', ...
'Select CERR .mat file or bzip archive for viewing');  %at position 100, 100 in pixels.

if fname == 0
  disp('No file selected for viewing.');
  %splashScreen('off');
  return
end

file = [pathname fname];


% Test for compressed file (*.gz), GNUZIP (freeware).  Code by A. Blanco.
if ~isempty(strfind(file,'.bz2'))
    outstr = gnuCERRCompression(file, 'uncompress');
    file = file(1:end-3);
end

CERRFile = file;

planC = load(file,'planC');

planC = planC.planC;   %Conversion from struct created by load

indexS = planC{end};  %use original index from plan!

stateS.optS        = optS;
stateS.dir         = 1;                   %Initial direction of paging through CT slices.
stateS.dirSag      = 1;
stateS.dirCor      = 1;
stateS.CERRFile    = CERRFile;

%-----------initialize GUI---------------------%
sliceCallBack('init')
