function setChildDrawOrder(hAxis)
%"setChildDrawOrder"
%   Reorders the child objects in hAxis so they are drawn in the proper
%   order.  Images/surfaces should be drawn first, with text, lines etc
%   drawn on top of them.  Draworder of images should be maintained.
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

%Get children of hAxis, and their types.
kids = get(hAxis, 'children');
% kidTypes = get(kids, 'type');
kidTags = get(kids, 'tag');

% 	%Find kids of type image or surface.
% 	imgBool = strcmpi(kidTypes, 'image');
% 	surfBool = strcmpi(kidTypes, 'surface');

scanImagesBool = strcmpi(kidTags, 'CTImage');
doseImagesBool = strcmpi(kidTags, 'DoseImage');
compareImagesBool = strcmpi(kidTags, 'comparisonH');

%Save their handles.
hScanImages = kids(scanImagesBool);
hDoseImages = kids(doseImagesBool);
hCompareImages = kids(compareImagesBool);

%Delete them from the kids list and readd at end.
kids(scanImagesBool | doseImagesBool | compareImagesBool) = [];
kids = [kids;hDoseImages;hCompareImages;hScanImages];

%Set the axis children flag.
set(hAxis, 'children', kids);
