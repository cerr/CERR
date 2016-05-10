function CERRAxisMenu(command, varargin)
%"CERRAxisMenu"
%   Handles callbacks from the right click menus for all CERR axes.  Also
%   creates new right click menus in passed axes, and interfaces with the
%   ud.axisInfo field that all CERR viewer axes have.
%
%JRA 1/10/05
%
%Usage:
%   function CERRAxisMenu(command, varargin)
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

global planC;
global stateS;
indexS = planC{end};

if ishandle(command) & strcmpi(get(command, 'type'), 'axes')
    varargin{1} = command;
    command     = 'init';
elseif ~ischar(command)
    error('Invalid call to CERRAxisMenu.');
end

switch upper(command)

    case 'INIT'
        hAxis = varargin{1};
        hFig  = get(hAxis, 'parent');
        hMenu = uicontextmenu('Callback', 'CERRAxisMenu(''update_menu'')', 'userdata', hAxis, 'Tag', 'CERRAxisMenu', 'parent', hFig);
        set(hAxis, 'UIContextMenu', hMenu);

    case 'UPDATE_MENU'
        hMenu = gcbo;
        hAxis = get(hMenu, 'userdata');
        
        % Check if it is a legend axis and return
        axView = getAxisInfo(hAxis,'view');
        if strcmpi(axView,'legend')
            return;
        end

        %Wipe out old submenus.
        kids = get(hMenu, 'children');
        delete(kids);

        %Get CERR axis properties.
        axisInfo        = getAxisInfo(hAxis);
        scanSets        = axisInfo.scanSets;
        doseSets        = axisInfo.doseSets;
        structureSets   = axisInfo.structureSets;
        view            = axisInfo.view;

        %Create top level menus.
        hViewM      = uimenu(hMenu, 'Label', 'View');
        hScanM      = uimenu(hMenu, 'Label', 'ScanSet');
        hDoseM      = uimenu(hMenu, 'Label', 'DoseSet');
        hStructM    = uimenu(hMenu, 'Label', 'StructSet');

        if stateS.layout == 7
            hCompareM    = uimenu(hMenu, 'Label', 'Comparison');
            uimenu(hCompareM, 'Label', 'Default', 'checked', 'off', 'Callback', 'doseCompare(''COMPAREMODE'', ''DEFAULT'')');
            uimenu(hCompareM, 'Label', 'Rel Diff', 'checked', 'off', 'Callback', 'doseCompare(''COMPAREMODE'',''RELDIFF'')');
            uimenu(hCompareM, 'Label', 'Abs Diff', 'checked', 'off', 'Callback', 'doseCompare(''COMPAREMODE'',''ABSDIFF'')');
            uimenu(hCompareM, 'Label', 'Rel Max Proj Diff', 'checked', 'off', 'Callback', 'doseCompare(''COMPAREMODE'',''RELMAXPRODIFF'')');
            uimenu(hCompareM, 'Label', 'Rel Min Proj Diff', 'checked', 'off', 'Callback', 'doseCompare(''COMPAREMODE'',''RELMINPRODIFF'')');
            uimenu(hCompareM, 'Label', 'Abs Max Proj Diff', 'checked', 'off', 'Callback', 'doseCompare(''COMPAREMODE'',''ABSMAXPRODIFF'')');
            uimenu(hCompareM, 'Label', 'Abs Min Proj Diff', 'checked', 'off', 'Callback', 'doseCompare(''COMPAREMODE'',''ABSMINPRODIFF'')');
            % set checkmark on selected comparison mode
            doseCompHandleC = get(hCompareM,'children');
            set(doseCompHandleC,'checked','off')
        end
        if stateS.layout == 6
            hCompareM    = uimenu(hMenu, 'Label', 'Comparison', 'separator', 'on');
            uimenu(hCompareM, 'Label', 'Spotlight', 'Callback', 'CERRAxisMenu(''DRAW_SPOTLIGHT'')', 'separator', 'off');
        end
        hQueryM     = uimenu(hMenu, 'Label', 'Query Dose', 'Callback', 'CERRAxisMenu(''QUERY_DOSE'')', 'separator', 'on');
        hRulerM     = uimenu(hMenu, 'Label', 'Draw Ruler', 'Callback', 'CERRAxisMenu(''DRAW_RULER'')', 'separator', 'off');
        hProfileM   = uimenu(hMenu, 'Label', 'Dose/CT Profile', 'Callback', 'CERRAxisMenu(''PROFILE_DOSE'')', 'separator', 'off');

        hDuplicate  = uimenu(hMenu, 'Label', 'Duplicate this view', 'Callback', 'CERRAxisMenu(''DUPLICATE'')', 'separator', 'on', 'userdata', hAxis);
        hDuplicateLink = uimenu(hMenu, 'Label', 'Duplicate/Link this view', 'Callback', 'CERRAxisMenu(''DUPLICATELINK'')', 'separator', 'off', 'userdata', hAxis);
        hOpenInNewFig = uimenu(hMenu, 'Label', 'Open this view to print', 'Callback', 'CERRAxisMenu(''OPENNEWFIG'')', 'separator', 'off', 'userdata', hAxis);
        %Add dose children, checking where correct.
        if strcmpi(axisInfo.doseSelectMode, 'auto')
            chkFlag = 'on';
        else
            chkFlag = 'off';
        end
        nDoses = length(planC{indexS.dose});
        doseNames = {planC{indexS.dose}.fractionGroupID};
        uimenu(hDoseM, 'Label', 'Auto', 'checked', chkFlag, 'Callback', 'CERRAxisMenu(''SET_DOSE'')', 'userdata', {hAxis, []});
        sepFlag = 'on';
        chkFlag = 'off';
        dosesToShow = 20;
        for i=1:min(nDoses,dosesToShow)
            if ismember(i, doseSets)
                chkFlag = 'on';
            end
            uimenu(hDoseM, 'Label', [num2str(i) '. ' doseNames{i}], 'separator', sepFlag, 'checked', chkFlag, 'Callback', 'CERRAxisMenu(''SET_DOSE'')', 'userdata', {hAxis, i});
            sepFlag = 'off';
            chkFlag = 'off';
        end
        if nDoses > dosesToShow
            uimenu(hDoseM, 'Label', 'More Doses...', 'Callback', 'CERRAxisMenu(''SET_DOSE_MORE'')', 'userdata', {hAxis, 'more_dose'});
        end

        %Add scan children.
        if strcmpi(axisInfo.scanSelectMode, 'auto')
            chkFlag = 'on';
        else
            chkFlag = 'off';
        end
        uimenu(hScanM, 'Label', 'Auto', 'checked', chkFlag, 'Callback', 'CERRAxisMenu(''SET_SCAN'')', 'userdata', {hAxis, []});
%         nScans = length(planC{indexS.scan});
%         scanNames = {planC{indexS.scan}.scanType};
%         sepFlag = 'on';
%         chkFlag = 'off';
%         for i=1:nScans
%             if ismember(i, scanSets)
%                 chkFlag = 'on';
%             end
%             uimenu(hScanM, 'Label', [num2str(i) '. ' scanNames{i}], 'separator', sepFlag, 'checked', chkFlag, 'Callback', 'CERRAxisMenu(''SET_SCAN'')', 'userdata', {hAxis, i});
%             sepFlag = 'off';
%             chkFlag = 'off';
%         end
        topMenuFlag = 0;
        addScansToMenu(hScanM,topMenuFlag)


        %Add structM children.
        if strcmpi(axisInfo.structSelectMode, 'auto')
            chkFlag = 'on';
        else
            chkFlag = 'off';
        end
        nStrSet = length(planC{indexS.structureArray});
        uimenu(hStructM, 'Label', 'Auto', 'checked', chkFlag, 'Callback', 'CERRAxisMenu(''SET_STRUCTS'')', 'userdata', {hAxis, []});
        sepFlag = 'on';
        chkFlag = 'off';
        for i=1:nStrSet
            if ismember(i, structureSets)
                chkFlag = 'on';
            end
            uimenu(hStructM, 'Label', [num2str(i) '. '], 'separator', sepFlag, 'checked', chkFlag, 'Callback', 'CERRAxisMenu(''SET_STRUCTS'')', 'userdata', {hAxis, i});
            sepFlag = 'off';
            chkFlag = 'off';
        end

        %Add view children
        views = {'transverse', 'sagittal', 'coronal', 'legend', 'navigation'};
        chkBoolFlagV = strcmpi(views, view);
        chkFlagV = {};
        chkFlagV{chkBoolFlagV} = 'on';
        [chkFlagV{~chkBoolFlagV}] = deal('off');
        uimenu(hViewM, 'Label', 'Transverse', 'Callback', 'CERRAxisMenu(''SET_VIEW'')', 'checked', chkFlagV{1}, 'userdata', hAxis);
        uimenu(hViewM, 'Label', 'Sagittal', 'Callback', 'CERRAxisMenu(''SET_VIEW'')', 'checked', chkFlagV{2}, 'userdata', hAxis);
        uimenu(hViewM, 'Label', 'Coronal', 'Callback', 'CERRAxisMenu(''SET_VIEW'')', 'checked', chkFlagV{3}, 'userdata', hAxis);
        uimenu(hViewM, 'Label', 'Legend', 'Callback', 'CERRAxisMenu(''SET_VIEW'')', 'checked', chkFlagV{4}, 'userdata', hAxis);

        % Display Delete View only for new axes that are created
        %ud = get(hAxis,'userdata');
        if length(stateS.handle.CERRAxis)>4 || iscell(view) % Assume linked axis if datatype is cell.
            uimenu(hViewM, 'Label', 'Delete View', 'checked', chkFlag, 'Callback', 'CERRAxisMenu(''SET_VIEW'')', 'userdata', hAxis);
        end

    case 'SET_VIEW'
        %         stateS.viewChanged = 1;
        menuLabel   = get(gcbo, 'Label');
        hAxis       = get(gcbo, 'userdata');
        sliceCallBack('selectaxisview', hAxis, lower(menuLabel));
        sliceCallBack('refresh');

    case 'SET_SCAN'

        ud = get(gcbo, 'userdata');
        hAxis       = ud{1};
        newScanNum  = ud{2};

        if isempty(newScanNum)
            setAxisInfo(hAxis, 'scanSelectMode', 'auto', 'structSelectMode', 'auto', 'doseSelectMode', 'auto','xRange',[],'yRange',[]);
        else
            setAxisInfo(hAxis, 'scanSelectMode', 'manual', 'scanSets', newScanNum,...
                'xRange',[],'yRange',[]);            
            numScans = length(planC{indexS.scan});
            assocScansV = getStructureSetAssociatedScan(1:numScans, planC);
            structSetNum = [];
            assocStructSet = find(assocScansV == newScanNum);
            if ~isempty(assocStructSet)      
                structSetNum = assocStructSet(1);
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
        end
        %updateAxisRange(hAxis,0,'scan');
        sliceCallBack('refresh');

    case 'SET_STRUCTS'
        ud = get(gcbo, 'userdata');
        hAxis       = ud{1};
        newStrNum   = ud{2};

        if isempty(newStrNum)
            setAxisInfo(hAxis, 'structSelectMode', 'auto');
        else
            %oldStructureSets = getAssociatedStructSet(getAxisInfo(hAxis, 'structureSetUID'));
            oldStructureSets = getAxisInfo(hAxis, 'structureSets');
            if ismember(newStrNum, oldStructureSets)
                structureSets = setdiff(oldStructureSets, newStrNum);
                setAxisInfo(hAxis, 'structureSets', structureSets , 'structSelectMode', 'manual');
            else
                structureSets(1:length(oldStructureSets)+1) = deal(union(oldStructureSets, newStrNum));
                setAxisInfo(hAxis, 'structureSets',structureSets , 'structSelectMode', 'manual');
            end
        end
        sliceCallBack('refresh');

    case 'SET_DOSE'

        ud = get(gcbo, 'userdata');
        hAxis       = ud{1};
        newDoseNum  = ud{2};
        if ~isnumeric(newDoseNum) && strcmp(newDoseNum, 'more_dose')            
            newDoseNum  = varargin{2};
        end

        if stateS.layout == 6

        else  % stateS.layout ~= 6
            if isempty(newDoseNum)
                setAxisInfo(hAxis, 'doseSelectMode', 'auto');
            else
                setAxisInfo(hAxis, 'doseSelectMode', 'manual', 'doseSets',newDoseNum ,'doseSetsLast', newDoseNum);
                if ~isLocal(planC{indexS.dose}(newDoseNum).doseArray)
                    planC{indexS.dose}(newDoseNum).doseArray = getDoseArray(newDoseNum, planC);
                end
            end
            stateS.doseSetChanged = 1;
        end

        sliceCallBack('refresh');
        
    case 'SET_DOSE_MORE'
        ud = get(gcbo,'userdata');
        hAxis = ud{1};
        currentDoseNum = getAxisInfo(hAxis,'doseSets');
        dosesToShow = 20;
        numDoses = length(planC{indexS.dose});
        doseStrC = {};
        count = 1;
        for i = dosesToShow+1 : numDoses
            doseStrC{count} = [num2str(i) '.  ' planC{indexS.dose}(i).fractionGroupID];
            count = count + 1;
        end
        initialValue = [];
        if currentDoseNum > dosesToShow
            initialValue = currentDoseNum - dosesToShow;
        end
        doseIndex = listdlg('PromptString','Toggle Dose', 'SelectionMode','single','ListString',doseStrC,'InitialValue',initialValue);
        if ~isempty(doseIndex)
            CERRAxisMenu('SET_DOSE',hAxis,dosesToShow+doseIndex)
        end        

    case 'DUPLICATE'
        hAxis = get(gcbo, 'userdata');
        sliceCallBack('DUPLICATEAXIS', hAxis);

    case 'DUPLICATELINK'
        hAxis = get(gcbo, 'userdata');
        sliceCallBack('DUPLICATELINKAXIS', hAxis);

    case 'OPENNEWFIG'
        hAxis = get(gcbo, 'userdata');
        openAxisInFig(hAxis)

    case 'QUERY_DOSE'
        sliceCallBack('TOGGLEDOSEQUERY');

    case 'DRAW_RULER'
        sliceCallBack('TOGGLERULER');
        
    case 'DRAW_SPOTLIGHT'
        sliceCallBack('TOGGLESPOTLIGHT');

    case 'PROFILE_DOSE'
        sliceCallBack('TOGGLEDOSEPROFILE');
end

