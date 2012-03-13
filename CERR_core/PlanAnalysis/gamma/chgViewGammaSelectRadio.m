function chgViewGammaSelectRadio(source, evdata)
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

global stateS

if strcmpi(evdata.EventName,'SelectionChanged')

    gammaView = get(evdata.NewValue,'string');

    stateS.gamma.view = gammaView;
    try
        for i = 1: length(stateS.handle.CERRAxis)
            axisInfo = getAxisInfo(stateS.handle.CERRAxis(i));
            if strcmpi(axisInfo.doseObj.view, gammaView)
                stateS.gamma.axis = stateS.handle.CERRAxis(i);
            end
        end
    end

    %     switch upper(gammaView)
    %         case 'TRANSVERSE'
    %         case 'CORONAL'
    %         case 'SAGITTAL'
    %     end
end