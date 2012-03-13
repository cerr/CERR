function [varargout] = Dx(planC, varargin)
%Calculate a Dx metric.
%Stand alone metric :       Dx(planC, structNum, doseNum, percent);
%Request m object   :       Dx(planC, 'getnewmetric');
%Evaluate m object  :       Dx(planC, m, 'evaluate');
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
    warning('Incorrect Usage, try: Dx(planC, structNum, doseNum, percent)');
    return;
end

switch upper(call)
    case 'GETNEWMETRIC'
        m.name = 'Dx';
        m.valueV = [];
        m.description = 'Returns the lowest dose in x% of structure';
        m.functionName = @Dx;
        m.note = '';
        m.params(1).name = 'Structure';
        m.params(1).type = 'DropDown';
        m.params(1).list = {planC{indexS.structures}.structureName};
        m.params(1).value = 1;

        m.params(2).name = 'percent';
        m.params(2).type = 'Edit';
        m.params(2).value = '50';

        m.params(3).name = 'IsTarget?';
        m.params(3).type = 'DropDown';
        m.params(3).list ={'Target', 'Not Target'};
        m.params(3).value = 2;

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
        m.name = ['D' m.params(2).value];

        maxD = -inf;
		for i=1:length(m.doseSets)
            [planC, doseBinsV, volsHistV] = getDVHMatrix(planC, m.params(1).value, m.doseSets(i));
            ans = calc_Dx(doseBinsV, volsHistV, str2num(m.params(2).value));
            m.valueV = [m.valueV ans];
            doseArray = getDoseArray(planC{indexS.dose}(m.doseSets(i)));
            maxD = max(maxD, max(doseArray(:)));
        end
        if m.params(3).value == 1
            %Is target, high maxDose is best.
            m.range = [0 max(m.valueV)];
        elseif m.params(3).value == 2
            m.range = [maxD min(m.valueV)];
        end
        m.units = getDoseUnitsStr(i,planC);
        varargout = {planC,m};
        return;

    otherwise
        if(nargin > 3)
            structNum = varargin{1};
            doseNum = varargin{2};
            percent = varargin{3};
            [planC, doseBinsV, volsHistV] = getDVHMatrix(planC, structNum, doseNum);
            varargout = {calc_Dx(doseBinsV, volsHistV, percent)};
        else
            error('Not enough parameters, try: Dx(planC, structNum, doseNum, percent)')
            return;
        end
end

    