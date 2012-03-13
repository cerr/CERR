function [varargout] = Vx(planC, varargin)
%Calculate a Vx metric.
%Stand alone metric :       Vx(planC, structNum, doseNum, doseCutoff, 'Percent' or 'Absolute');
%Request m object   :       Vx(planC, 'getnewmetric');
%Evaluate m object  :       Vx(planC, m, 'evaluate');
%LM:  4 Jan 06, JOD: changed interface.
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


indexS = planC{end};
optS = planC{indexS.CERROptions};

if(nargin > 1)
    call = varargin{end};
else
    warning('Incorrect Usage, try: Vx(planC, structNum, doseNum, doseCutoff)');
    return;
end

switch upper(call)
    case 'GETNEWMETRIC'
        m.name = 'Vx';
        m.valueV = [];
        m.description = 'Returns the volume of structure above dose x';
        m.functionName = @Vx;
        m.note = '';
        m.params(1).name = 'Structure';
        m.params(1).type = 'DropDown';
        m.params(1).list = {planC{indexS.structures}.structureName};
        m.params(1).value = 1;

        m.params(3).name = 'Volume in:';
        m.params(3).type = 'DropDown';
        m.params(3).list = {'Percent' 'Absolute'};
        m.params(3).value = 1;

        m.params(2).name = 'dose x';
        m.params(2).type = 'Edit';
        m.params(2).value = '50';

        m.params(4).name = 'IsTarget?';
        m.params(4).type = 'DropDown';
        m.params(4).list ={'Target', 'Not Target'};
        m.params(4).value = 2;

        m.units = [];
        m.range = [0 inf];
        m.doseSets = [1];
        varargout = {planC,m};
    return;

    case 'EVALUATE'
        m = varargin{1};
        structName = planC{indexS.structures}(m.params(1).value).structureName;
        m.note = structName;
        m.valueV = [];
        m.name = ['V' m.params(2).value];

		for i=1:length(m.doseSets)
            [planC, doseBinsV, volsHistV] = getDVHMatrix(planC, m.params(1).value, m.doseSets(i));
            ans = calc_Vx(doseBinsV, volsHistV, str2num(m.params(2).value), m.params(3).value);
            m.valueV = [m.valueV ans];
        end
        if(m.params(3).value == 1)
            m.units = 'Fract';
        else
            m.units = 'Cm^3';
        end
        if m.params(4).value == 1
            %Is target, high vol is best.
            m.range = [0 max(m.valueV)];
        elseif m.params(4).value == 2
            %Not target, low vol is best.
            m.range = [sum(volsHistV) min(m.valueV)];
        end


        varargout = {planC,m};
        return;

    otherwise  %No specific call has been made, assume user just wants raw metric.
        if(nargin > 4)
            structNum = varargin{1};
            doseNum = varargin{2};
            doseCutoff = varargin{3};
            volumeTypeString = varargin{4};
            if(strcmp(upper(volumeTypeString), 'ABSOLUTE'))
                volumeType = 2;
            else
                volumeType = 1;
            end
            [planC, doseBinsV, volsHistV] = getDVHMatrix(planC, structNum, doseNum);
            varargout = {calc_Vx(doseBinsV, volsHistV, doseCutoff, volumeType)};
        else
            error('Not enough parameters, try: Vx(planC, structNum, doseNum, doseCutoff)')
            return;
        end
end
