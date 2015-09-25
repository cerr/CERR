function closeAllCERRFigures(varargin)
%Close all figures related to CERR, with the exception of the transverse viewer, which closes itself.
%
% 15 Aug 02, V H Clark
% LM: 30 Dec 02, JOD
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

if nargin == 0
	
	fieldsC = fieldnames(stateS.handle);
	
	for i = 1 : length(fieldsC)
      if ~strcmp(fieldsC{i},'CERRSliceViewer')
        hV = getfield(stateS.handle,fieldsC{i});
        for j = 1 : length(hV)
          try
            delete(hV(j))
          end
        end
      end
	end
	
	if ~stateS.workspacePlan & stateS.planLoaded
        clear global planC
	end
	clear global stateS
    
%If a selective close, only close certain figures.
elseif nargin == 1 & strcmpi(varargin{1},'Selective');
    try, delete(stateS.handle.doseManagementFig);,end;
    try, delete(stateS.handle.doseSubtractionMenuFig);,end;
    try, delete(stateS.handle.IMRTMenuFig);,end;
    try, delete(stateS.handle.DVHMenuFigure);,end;
    try, 
        for i=1:length(stateS.handle.DVHPlot)
            try, delete(stateS.handle.DVHPlot),end;
        end
    end
    try, delete(stateS.handle.metricSelectionFig);,end;
    try, delete(stateS.handle.doseShadowFig);,end;
    try, delete(stateS.handle.graphicalComparisonFig);,end;
    try, delete(stateS.handle.aboutCERRFig);,end;
    try, delete(stateS.handle.structureFusionFig);,end;
    try, delete(stateS.handle.navigationMontage);,end;    
end
    