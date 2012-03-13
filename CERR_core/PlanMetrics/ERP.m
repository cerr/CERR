function [varargout] = ERP(planC, varargin)
%function [varargout] = ERP(planC, varargin)
%Calculate normal tissue EUD-based Response Probability.
%This is the same as the LKB model except the inputs are different:
%-- instead of m as the slope parameter, we use gamma50,
%-- instead of n as the exponent, we use the EUD input parameter, a.
%Otherwise, the math is the same.
%Stand alone metric  :       probability = ERP(planC, structNum, doseNum, a, D50, gamma50);
%Request new metric  :       ERP(planC, 'getnewmetric');
%Evaluate new metric :       ERP(planC, m, 'evaluate');
%Can be invoked using a GUI under the DVH metrics menu.
%added by JOD, 13 June 05.
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
    warning('Incorrect Usage, try: ERP(planC, structNum, doseNum, a, D50, gamma50)');
    return;
end

switch upper(call)
    case 'GETNEWMETRIC'
        m.name = 'ERP';
        m.valueV = [];
        m.description = 'EUD-based response probability';
        m.functionName = @ERP;
        m.note = '';
        m.params(1).name = 'Structure';
        m.params(1).type = 'DropDown';
        m.params(1).list = {planC{indexS.structures}.structureName};
        m.params(1).value = 1;
        m.params(2).name = 'IsTarget?';
        m.params(2).type = 'DropDown';
        m.params(2).list ={'Target', 'Not Target'};
        m.params(2).value = 2;
        m.params(3).name = 'a (= 1/n)';
        m.params(3).type = 'Edit';
        m.params(3).value = 1;
        m.params(4).name = 'D50 (Gy)';
        m.params(4).type = 'Edit';
        m.params(4).value = 25;
        m.params(5).name = 'gamma50 (=1/(m * sqrt(2 * pi))';
        m.params(5).type = 'Edit';
        m.params(5).value = 2;
        m.units = [];
        m.range = [0 1];
        m.doseSets = [1];
        varargout = {planC,m};
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
            EUD = calc_EUD(doseBinsV, volsHistV, m.params(3).value);
            D50 = m.params(4).value;
            gamma50 = m.params(5).value;
            %Convert to sigmoidal complication probability:
            tmp = (EUD - D50) * gamma50 * (2 * pi).^0.5/D50;
            ERP = 1/2 * (1 + erf(tmp/2^0.5));
            m.valueV = [m.valueV ERP];
        end
        m.range = [0 1];
        m.units = 'prob.';
        varargout = {planC,m};


        return;

    otherwise  %No specific call has been made, assume user just wants raw metric.
        if(nargin > 3)
            structNum = varargin{1};
            doseNum = varargin{2};
            a   = varargin{3};
            D50 = varargin{4};
            gamma50 = varargin{5};
            [planC, doseBinsV, volsHistV] = getDVHMatrix(planC, structNum, doseNum);
            EUD = calc_EUD(doseBinsV, volsHistV, a);

            %Convert to sigmoidal complication probability:
            tmp = (EUD - D50) * gamma50 * (2 * pi).^0.5/D50;
            varargout{1} = 1/2 * (1 + erf(tmp/2^0.5));

        else
            error('Not enough parameters, try: ERP(planC, structNum, doseNum, a, D50, gamma50)')
            return;
        end
    end
