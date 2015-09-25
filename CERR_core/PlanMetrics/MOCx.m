function [varargout] = MOCx(planC, varargin)
%Calculate a MOCx metric.
%Stand alone metric :       MOCx(planC, structNum, doseNum, percent);
%Request m object   :       MOCx(planC, 'getnewmetric');
%Evaluate m object  :       MOCx(planC, m, 'evaluate');
%LM:  4 Jan 06, JOD: changed interface.
%LM: 26 Jun 06, VHC: turned from Dx to mDx (only does upper tail currently)
%LM: 20 Nov 06, VHC: turned from MOHx to MOCx
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
    warning('Incorrect Usage, try: MOCx(planC, structNum, doseNum, percent)');
    return;
end

switch upper(call)
    case 'GETNEWMETRIC'
        m.name = 'MOCx';
        m.valueV = [];
        m.description = 'Returns the mean dose of the coldest x% of the structure (the lower tail)';
        m.functionName = @MOCx;
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
        m.name = ['MOC' m.params(2).value];

        maxD = -inf;
		for i=1:length(m.doseSets)
            [planC, doseBinsV, volsHistV] = getDVHMatrix(planC, m.params(1).value, m.doseSets(i));
            ans = calc_MOCx(doseBinsV, volsHistV, str2num(m.params(2).value));
            m.valueV = [m.valueV ans];
            maxD = max(maxD, max(planC{indexS.dose}(m.doseSets(i)).doseArray(:)));
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
            varargout = {calc_MOCx(doseBinsV, volsHistV, percent)};
        else
            error('Not enough parameters, try: MOCx(planC, structNum, doseNum, percent)')
            return;
        end
end

    