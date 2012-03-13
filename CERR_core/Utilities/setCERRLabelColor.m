function borw = setCERRLabelColor(colorNum, varargin)
%Set the color (black or white) of a label superimposed on a colored background
%JOD, 11 Nov 02
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

if(nargin == 1)
    try
        colorV = planC{indexS.structures}(colorNum).structureColor;
    catch    
        colorV = getColor(colorNum, stateS.optS.colorOrder);
    end
else
    colorV = getColor(colorNum, varargin{1}.colorOrder);
end

if (mean(colorV) < 0.6) & ((max(colorV) == colorV(1)) | (max(colorV) == colorV(3)))  & ~(max(colorV) == colorV(2))
  borw  = [1 1 1]; %white
else
  borw = [ 0 0 0];  %black
end
