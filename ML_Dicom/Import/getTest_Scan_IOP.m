function varargout = getTest_Scan_IOP(fileName)
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

% Nominal Values
%  1, 0, 0,   0,  1, 0    %% HFS
% -1, 0, 0,   0, -1, 0    %% HFP
% -1, 0, 0,   0,  1, 0    %% FFS
%  1, 0, 0,   0, -1, 0    %% FFP

isNominal = false;

HFS = [ 1, 0, 0,   0,  1, 0];
HFP = [-1, 0, 0,   0, -1, 0];
FFS = [-1, 0, 0,   0,  1, 0];
FFP = [ 1, 0, 0,   0, -1, 0];

dcmobj = scanfile_mldcm(fileName);

IOP = dcm2ml_Element(dcmobj.get(hex2dec('00200037')))';


if IOP == HFS
    isNominal = true;
    orientation = 'HFS';
    returnValue = 1;

elseif IOP == HFP
    isNominal = true;
    orientation = 'HFP';
    returnValue = 1;

elseif IOP == FFS
    isNominal = true;
    orientation = 'FFS';
    returnValue = 1;

elseif IOP == FFP
    isNominal = true;
    orientation = 'FFP';
    returnValue = 1;
end


if ~isNominal
    % If not Nominal data, then test for known cases /* Using Dr. Matthews Test */
    % Return values
    % 0 == Major Tile
    % 1 == Nominal
    % 2 == n*90 degree rotations
    % 3 == UNITY, i.e.
    
    

end


varargout{1} = isNominal;
varargout{2} = orientation;
varargout{3} = IOP;
varargout{4} = returnValue;