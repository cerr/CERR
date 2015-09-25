function [tagName, hexString] = tag2strings(tag, dcmobj)
%"tag2strings"
%   Convert a decimal representation of a Dicom tag into two strings, the
%   tagName which is a decription of the field, and a hexString which gives 
%   the tag in hex form '(xxxx,yyyy)'.
%
%   A dcmobj must be passed in to provide a link to the dicomdictionary.
%
%JRA 06/13/06
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

%Usage:
%   [tagName, hexString] = tag2strings(tag, dcmobj)

hexString    = char(org.dcm4che2.util.TagUtils.toString(tag));
tagName      = char(dcmobj.nameOf(tag));

