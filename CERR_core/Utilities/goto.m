function goto(command,varargin)
% goto
% GOTO function is used for three function.
%   1. To jump to slice with max dose
%       [go to max]
%   2. To jump to a slice with said z-coordinate
%       [go to z [zValue]]
%   3. To jump to a slice with said slice number
%       [go to [sliceNumber]]
%
% Written DK 08/24/06
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


global planC stateS
indexS = planC{end};

switch upper(command)

    case 'Z' % go to slice with given z value
        try
            zNum = varargin{1};
        catch
            prompt = {'Enter the z coord:'};
            dlg_title = 'GO TO Z Value';
            num_lines = 1;
            def = {''};
            zNum = inputdlg(prompt,dlg_title,num_lines,def);
            if isempty(zNum)
                return
            else
                zNum = str2num(zNum{1});
            end
        end
        hAxis = stateS.handle.CERRAxis(1);
        scanSet =  getAxisInfo(hAxis,'scanSets');

        transM = getTransM('scan', scanSet(1) , planC);

        zNum = applyTransM(transM,[zNum,zNum,zNum]);
        setAxisInfo(stateS.handle.CERRAxis(1),'coord',zNum(3));
        CERRRefresh;
        return

    case 'MAX' % go to slice with max dose
        hAxis = gca;
        %Find the slice of max dose
        [doseSets,scanSets]=getAxisInfo(hAxis,'doseSets','scanSets');

        dose3M = getDoseArray(planC{indexS.dose}(doseSets));

        indV = find(dose3M == max(dose3M(:)));

        [ySlice,xSlice,zSlice] = ind2sub(size(dose3M),indV(1)); %in case there are multiple max points

        [xVals, yVals, zVals] = getDoseXYZVals(planC{indexS.dose}(doseSets));

        xCoord = xVals(xSlice);  yCoord = yVals(ySlice);  zCoord = zVals(zSlice);

        transMS = getTransM('scan', scanSets, planC);

        transMD = getTransM('dose', doseSets , planC );
        % Check if transformation matrix is present and apply
        % otherwise use the coordinates as it is

        if isempty(transMD)| isequal(transMD,eye(4))

            if ~isempty(transMS)| ~isequal(transMS,eye(4))

                coordV = applyTransM(transMS,[xCoord yCoord zCoord]);
            else
                coordV = [xCoord yCoord zCoord];
            end

        elseif ~isempty(transMD)| ~isequal(transMD,eye(4))

            coordV = applyTransM(transMD,[xCoord yCoord zCoord]);
        end

    case 'SLICE' % go to slice with given slice number
        hAxis = gca;
        try
            num = varargin{1};
        catch
            prompt = {'Enter the slice number:'};
            dlg_title = 'GO TO SLICE';
            num_lines = 1;
            def = {''};
            num = inputdlg(prompt,dlg_title,num_lines,def);
            if isempty(num)
                return
            else
                num = str2num(num{1});
            end
        end

        if ~isempty(num) & isnumeric(num)
            scanIndx = getAxisInfo(hAxis,'scanSets');
            transM = getTransM('scan',scanIndx,planC);
            [xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(scanIndx));

            coordV = applyTransM(transM,[xVals(num), yVals(num), zVals(num)]);
        else
            error('Not a valid sliceNum.');
        end
        
    otherwise
        
        val = varargin{1};
        hAxis = gca;
        % Find the scan displayed on the current axis
        scanSet = getAxisInfo(hAxis,'scanSets');
        scanTypesC = {planC{indexS.scan}(:).scanType};
        scanType = planC{indexS.scan}(scanSet).scanType;
        scanNumsV = find(strcmpi(scanType,scanTypesC));
        % Loop through scans and slices to find the matching tag
        %numScans = length(planC{indexS.scan});
        for scanNum = scanNumsV
            for slc = 1:length(planC{indexS.scan}(scanNum).scanInfo)
                if planC{indexS.scan}(scanNum).scanInfo(slc).(command) == val
                    % show the scan scanNum                    
                    setAxisInfo(hAxis,'scanSets',scanNum,'scanSelectMode','manual')
                    % Set structure and dose
                    numStructSets = length(planC{indexS.structures});
                    assocScansV = getStructureAssociatedScan(1:numStructSets, planC);
                    structSetNum = [];
                    assocStructSet = find(assocScansV == scanNum);
                    if ~isempty(assocStructSet)
                        structSetNum = assocScansV(assocStructSet(1));
                    end
                    numDoses = length(planC{indexS.dose});
                    assocDosesV = getDoseAssociatedScan(1:numDoses, planC);
                    doseNum = [];
                    if any(assocDosesV)
                        doseNum = find(assocDosesV);
                        doseNum = doseNum(1);
                    end
                    setAxisInfo(hAxis, 'structSelectMode', 'manual',...
                        'doseSelectMode', 'manual',...
                        'structureSets', structSetNum,...
                        'doseSets', doseNum);                    
                    % go to slice
                    goto('slice',slc)
                    return;
                end
            end
        end
        
        return; % no match found
        
end

% Set the slice coordinate on the axes
view = getAxisInfo(hAxis,'view');

switch upper(view)

    case 'SAGITTAL'
        setAxisInfo(hAxis,'coord',coordV(1));

    case 'CORONAL'
        setAxisInfo(hAxis,'coord',coordV(2));

    case 'TRANSVERSE'
        setAxisInfo(hAxis,'coord',coordV(3));
end

% Refresh CERR
CERRRefresh;
