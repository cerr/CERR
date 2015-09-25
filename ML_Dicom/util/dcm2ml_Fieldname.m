function mlName = dcm2ml_Fieldname(dcmName, tag)
%"dcm2ml_Fieldname"
%   Returns a string that is capable of being used as a Matlab struct
%   fieldname, based on the DICOM fieldname string passed in, by replacing
%   or deleting characters such as "-" "/" "(" etc.  
%
%   The original tag value of the corresponding element should be passed in 
%   to handle the case where the fieldname is "?", or unknown.  In this 
%   situation the fieldname returned is "Private_xxxx_xxxx" where the Xs 
%   are the tag values.
%
%   TODO: consider and add any other possible illegal fieldname characters.
%
%JRA 6/1/06
%
%Usage:
%   mlName = dcm2ml_Fieldname(dcmName)
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

%These characters are deleted: "'/- ?"
dcmName(strfind(dcmName, '''')) = [];
dcmName(strfind(dcmName, '/'))  = [];
dcmName(strfind(dcmName, '-'))  = []; 
dcmName(strfind(dcmName, ' '))  = [];
dcmName(strfind(dcmName, '?'))  = [];
dcmName(strfind(dcmName, '('))  = [];
dcmName(strfind(dcmName, ')'))  = [];
dcmName(strfind(dcmName, '^'))  = [];

%These characters are replaced by an alternative: "(),"  
dcmName(strfind(dcmName, ','))  = '_';

mlName = dcmName;