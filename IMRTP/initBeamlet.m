function beamlet = initBeamlet
%function beamlet = initBeamlet
%This function returns a beamlet structure for IMRTP.
%
%APA 10/10/06
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

beamlet = struct(...                      %This is a *2D* structure array with index:  {structNum, beamletNum}.
                    'structureName', '',...    %Structure name
                    'format',[], ...          %Influence storage format e.g., pre-scaled uint8.
                    'influence',[], ...       %Sparse influence/dose element storage, within the structure points: only non-zeros are stored
                    'beamNum',  [], ...       %Beam indentifier.
                    'fullLength',[], ...      %Number of dose elements in non-sparse structure; used to put dose back in.
                    'indexV',[], ...          %Index of nonzero influence/dose values into influence/dose vector
                    'maxInfluenceVal',[], ...  %The maximum influence matrix value for this PB.  Needed to scale dose back up after conversion from uint8 (or whatever) format.
                    'lowDosePoints', [], ...   %Compressed boolean vector indicating points that are scaled from 0...1/256 * maxDose.
                    'sampleRate', 1, ...
                    'strUID','' ...
                    );
return;
