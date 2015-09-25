function [varargout] = LKB(planC, varargin)
%Calculate normal tissue complication probability using the Lyman-Kutcher-Burman model.
%Stand alone metric  :       probability = LKB(planC, structNum, doseNum, n, D50, m);
%Request new metric  :       LKB(planC, 'getnewmetric');
%Evaluate new metric :       LKB(planC, m, 'evaluate');
%The last two forms are used by the metric comparison tools.
%Or, invoke using GUI from metrics menu.
%added by JOD, 13 June 05.
%%LM:  4 Jan 06, JOD: changed interface.
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
    warning('Incorrect Usage, try: LKB(planC, structNum, doseNum, n, D50, m)');
    return;
end

switch upper(call)
    case 'GETNEWMETRIC'
        m.name = 'LKB';
        m.valueV = [];
        m.description = 'Lyman-Kutcher-Burman complication probability';
        m.functionName = @LKB;
        m.note = '';
        m.params(1).name = 'Structure';
        m.params(1).type = 'DropDown';
        m.params(1).list = {planC{indexS.structures}.structureName};
        m.params(1).value = 1;
        m.params(2).name = 'IsTarget?';
        m.params(2).type = 'DropDown';
        m.params(2).list ={'Target', 'Not Target'};
        m.params(2).value = 2;
        m.params(3).name = 'n (= 1/a)';
        m.params(3).type = 'Edit';
        m.params(3).value = 1;
        m.params(4).name = 'D50 (Gy)';
        m.params(4).type = 'Edit';
        m.params(4).value = 25;
        m.params(5).name = 'm (=1/(gamma50*sqrt(2*pi))';
        m.params(5).type = 'Edit';
        m.params(5).value = 0.5;
        m.units = [];
        m.range = [0 1];
        m.doseSets = [1];
        varargout = {planC, m};
    return;

    case 'EVALUATE'
        m = varargin{1};
        structName = planC{indexS.structures}(m.params(1).value).structureName;
        m.note = structName;
        m.valueV = [];

        if ~isnumeric(m.params(3).value)
            m.params(3).value = str2num(m.params(3).value);
        end
        if ~isnumeric(m.params(4).value)
            m.params(4).value = str2num(m.params(4).value);
        end
        if ~isnumeric(m.params(5).value)
            m.params(5).value = str2num(m.params(5).value);
        end


        maxD = -inf;
        for i=1:length(m.doseSets)
            [planC, doseBinsV, volsHistV] = getDVHMatrix(planC, m.params(1).value, m.doseSets(i));
            EUD = calc_EUD(doseBinsV, volsHistV, 1/m.params(3).value);
            D50 = m.params(4).value;
            mParam = m.params(5).value;
            %Convert to sigmoidal complication probability:
            tmp = (EUD - D50)/(mParam*D50);
            ERP = 1/2 * (1 + erf(tmp/2^0.5));
            m.valueV = [m.valueV ERP];
        end
        m.range = [0 1];
        m.units = 'prob.';
        varargout = {planC, m};

        return;

    otherwise  %No specific call has been made, assume user just wants raw metric.
        if(nargin > 3)
            structNum = varargin{1};
            doseNum = varargin{2};
            n   = varargin{3};
            D50 = varargin{4};
            mParam = varargin{5};
            [planC, doseBinsV, volsHistV] = getDVHMatrix(planC, structNum, doseNum);
            EUD = calc_EUD(doseBinsV, volsHistV, 1/n);

            %Convert to sigmoidal complication probability:
            tmp = (EUD - D50)/(mParam*D50);
            varargout{1} = 1/2 * (1 + erf(tmp/2^0.5));

        else
            error('Not enough parameters, try: ERP(planC, structNum, doseNum, a, D50, m)')
            return;
        end
    end



