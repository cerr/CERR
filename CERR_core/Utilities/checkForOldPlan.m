function planC = checkForOldPlan(planC)
%checkForOldPlan
%Checks for the old bug where the length of dose or structure fields is 1
%although they are empty.
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
indField = fieldnames(indexS);
for i = 1:length(indField)
    if length(planC{indexS.(indField{i})})==1
        switch lower(indField{i})
            case 'header'
            case 'comment'
            case 'scan'
                if isempty(planC{indexS.scan}.scanArray)
                    planC{indexS.scan}(1)=[];
                end
            case 'structures'
                if isempty(planC{indexS.structures}.contour)
                    planC{indexS.structures}(1)=[];
                end
            case 'structureArray'
                if isempty(planC{indexS.structureArray}.indicesArray)
                    planC{indexS.structureArray}(1)=[];
                end
            case 'beamGeometry'
            case 'beams'
            case 'dose'
                if isempty(planC{indexS.dose}.doseArray)
                    planC{indexS.dose}(1)=[];
                else
                    doseUnits = upper(getDoseUnitsStr(1,planC));
                    switch doseUnits
                        case 'GY'
                            % Do nothing
                        case 'CGY'
                            % Convert it to Gy
                            planC{indexS.dose}(1).doseUnits = 'GY';
                            planC{indexS.dose}(1).doseArray = planC{indexS.dose}(1).doseArray ./ 100;
                        otherwise
                            prompt = {'Enter Dose Units (Gy or CGy) :'};
                            dlg_title = 'Dose Units unknown';
                            num_lines = 1;
                            def = {'Gy'};
                            answer = inputdlg(prompt,dlg_title,num_lines,def);
                            
                            if answer == 0
                                 error('Cannot Proceed with Export without Dose Units');
                            end
                            
                            switch upper(answer)
                                case 'CGY'
                                    % Convert it to Gy
                                    planC{indexS.dose}(1).doseUnits = 'GY';
                                    planC{indexS.dose}(doseSet).doseArray = planC{indexS.dose}(doseSet).doseArray ./ 100;                                   
                            end
                    end
                end
            case 'DVH'
                if isempty(planC{indexS.DVH}.DVHMatrix)
                    planC{indexS.DVH}(1)=[];
                end
            case 'IVH'
            case 'digitalFilm'
            case 'RTTreatment'
            case 'IM'
            case 'importLog'
            case 'CERROptions'
            case 'indexS'
        end
    end
end