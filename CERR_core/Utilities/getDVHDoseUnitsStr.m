function units = getDVHDoseUnitsStr(DVHNum)
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


%Get the DVH dose units in the form of a string
%
%Adapted from getDoseUnitsStr.m (JOD, 7 Apr 03)
%
% 19 May 2006   KU

global planC stateS

indexS =  planC{end};

units = '';
units = planC{indexS.DVH}(DVHNum).doseUnits;
if ~isempty(units)
  if strcmpi(units,'gray')
    units = 'Gy';
  elseif strcmpi(units,'cgy')
    units = 'cGy';
  elseif strcmpi(units,'cgys')
    units = 'cGy';
  elseif strcmpi(units,'gy')
    units = 'Gy';
  elseif strcmpi(units,'gys')
    units = 'Gy';
  elseif strcmpi(units,'grays')
    units = 'Gy';
  end
end
