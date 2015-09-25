function units = getDoseUnitsStr(doseSet,planC)
%Get the dose units in the form of a string
%JOD, 7 Apr 03.
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


indexS =  planC{end};

units = planC{indexS.dose}(doseSet).doseUnits;
if ~isempty(lower(units))

    % All variants for Gray
    if strcmpi(units,'grays')
        units = 'Gy';
    elseif strcmpi(units,'gy')
        units = 'Gy';
    elseif strcmpi(units,'gys')
        units = 'Gy';
    elseif strcmpi(units,'gray')
        units = 'Gy';

        % All variants for Centi Gray
    elseif strcmpi (units,'cgrays')
        units = 'cGy';
    elseif strcmpi(units,'cgy')
        units = 'cGy';
    elseif strcmpi(units,'cgys')
        units = 'cGy';
    elseif strcmpi(units,'cgray')
        units = 'cGy';
    end
end
