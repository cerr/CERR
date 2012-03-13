function hMenu = rtMenu
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

h = uicontextmenu
uimenu(h, 'label', 'Find plans where this field:', 'selectionhighlight', 'off')
uimenu(h, 'label', 'contains <expression>.', 'separator', 'on')
uimenu(h, 'label', 'does not contain <expression>.')
uimenu(h, 'label', 'exists.')
uimenu(h, 'label', 'does not exist.')
uimenu(h, 'label', 'is empty.')
uimenu(h, 'label', 'is not empty.')

hMenu = h