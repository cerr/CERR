function transM = getTransM(type, number, planC)
%"getTransM"
%   Return the transM, or transformation matrix for a given dose, struct or
%   scan object.  Valid values for type are 'dose', 'scan', 'struct'.
%   Number is the dose, scan, or structure number whose transM is wanted.
%
%   An alternate call is to pass the actual scan/dose/structure field from
%   CERR in the planField parameter, ie. planC{indexS.dose}(2) would ask
%   for the 2nd dose's transM.
%
%   transM is a 4x4 transformation matrix.  If no transM exists [] is
%   returned.
%
%   JRA 1/18/05
%
%Usage:
%   function transM = getTransM(type, number, planC)
%OR
%   function transM = getTransM(planField, planC)
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


planField   = [];
transM      = eye(4);

%Parse input arguments.
if isstruct(type) && iscell(number)
    planC = number;
    indexS = planC{end};
    planField = type;
    if isfield(planField, 'scanInfo');
        type = 'scan';
    elseif isfield(planField, 'doseArray');
        type = 'dose';
    elseif isfield(planField, 'structureName');
        type = 'struct';
    else
        error('Invalid planField passed to getTransM.');
    end
elseif ischar(type) && isnumeric(number) && iscell(planC)

    %If request scan/struct/dose zero, return [];
    if isempty (number)
        transM = [];
        return;
    end

    indexS = planC{end};
    switch lower(type)
        case 'dose'
            planField = planC{indexS.dose}(number);
        case 'scan'
            planField = planC{indexS.scan}(number);
        case {'struct', 'structure'}
            planField = planC{indexS.structures}(number);
    end

else
    error('Invalid call to getTransM.');
end

switch lower(type)
    case 'scan'
        %If the scan has a transM, return it.
        if isfield(planField, 'transM') && ~isempty(planField.transM)
            transM = planField.transM;
        end
    case 'dose'
        %If the dose has a transM, return it, if it is associated with a
        %scan, return that scan's transM if it exists.
        if isfield(planField, 'transM') && ~isempty(planField.transM)
            transM = planField.transM;
        elseif isfield(planField, 'assocScanUID') && ~isempty(planField.assocScanUID)
            aS = getAssociatedScan(planField.assocScanUID,planC);
            if aS == 0
                transM = eye(4);
            else
                transM = getTransM('scan', aS, planC);
            end
        end
    case {'struct', 'structure'}
        %If the structure is associated with a scan, return that scan's
        %transM if it exists.
        if isfield(planField, 'assocScanUID') && ~isempty(planField.assocScanUID)
            aS = getAssociatedScan(planField.assocScanUID, planC);
            transM = getTransM('scan', aS, planC);
        end
    otherwise
        error('Invalid ''type'' parameter passed to getTransM.');
end

