function UID = getIOD_UID(IOD_type)
%getIOD_UID
%   Given a string indicating an IOD type, returns the UID corresponding to
%   that IOD.  
%
%   Currently supported UID strings are: CT
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


switch upper(IOD_type)
    case 'CT'
        UID = '1.2.840.10008.5.1.4.1.1.2';
    case 'MR'
        UID = '1.2.840.10008.5.1.4.1.1.4';
    otherwise
        error('Unsupported IOD type.');
end