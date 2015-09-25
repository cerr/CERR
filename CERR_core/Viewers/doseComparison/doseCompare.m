function doseCompare(command,varargin)
% doseCompare
% Used to show dose associated with scan in a compare mode. 
% 
% Written DK
% 
% Usage: doseCompare(command,varargin)
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
hCSVA = stateS.handle.CERRSliceViewerAxis;
switch upper(command)
    case 'INIT'
        if stateS.layout == 7
            return
        end
        scanNum = getAxisInfo(hCSVA,'scanSets');
        
        if isempty(scanNum)
            scanNum = stateS.scanSet;
        end
        
        % doseNum = length(planC{indexS.dose});%Get number of dose
        doseNum = getScanAssociatedDose(scanNum,'all');

        if length(doseNum) < 2
            warndlg('Dose Comparison tool requires 2 or more doses associated to currnet scan');
            return
        elseif length(doseNum) > 4
            newAxis = 3;
        else
            newAxis = length(doseNum)-1;            
        end
        stateS.doseCompare.newAxis = newAxis;

        if stateS.layout == 6
            scanCompare('exit');
        end

        if length( stateS.handle.CERRAxis)>4
            delete(stateS.handle.CERRAxis(4:end));
            stateS.handle.CERRAxisLabel1(5:end)=[];
            stateS.handle.CERRAxisLabel2(5:end)=[];
            stateS.handle.CERRAxis(5:end)=[];
        end

        %Calculating positions for each viewport
        leftMarginWidth = 195; bottomMarginHeight = 70;
        pos = get(stateS.handle.CERRSliceViewer, 'position');
        figureWidth = pos(3); figureHeight = pos(4);
        wid = (figureWidth-leftMarginWidth-70-10)/5;
        hig = (figureHeight-bottomMarginHeight-20)/2;


        stateS.oldDoseSet = stateS.doseSet;
        stateS.doseSet = doseNum(1);


        %change the layout after checking the number of dose in the plan
        stateS.layout = 7;
        stateS.Oldlayout = 7;
        doseSetsLast = getAxisInfo(hCSVA,'doseSets');
        scanSetsLast = getAxisInfo(hCSVA,'scanSets');
        setAxisInfo(hCSVA,'doseSets',doseNum(1),'doseSelectMode', 'manual','doseSetsLast',doseSetsLast,'scanSetsLast',scanSetsLast);
        %delete any new duplicate axis.
        if length(stateS.handle.CERRAxis) > 4
            delete(stateS.handle.CERRAxis(5:end));
            stateS.handle.CERRAxis = stateS.handle.CERRAxis(1:4);
        end

        for i = 1:newAxis % create linked axis to the transverse axis
            stateS.handle.CERRAxis(end+1) = axes('parent',stateS.handle.CERRSliceViewer, 'units', 'pixels', 'position', [1 1 1 1],...
                'color', [0 0 0], 'xTickLabel', [], 'yTickLabel', [], 'xTick', [], 'yTick', [], 'buttondownfcn',...
                'sliceCallBack(''axisClicked'')', 'nextplot', 'add', 'yDir', 'reverse', 'linewidth', 2,'visible','off','Tag','doseCompareAxes');

            stateS.handle.CERRAxisLabel1(end+1) = text('parent', stateS.handle.CERRAxis(end), 'string', '', 'position', [.02 .98 0],...
                'color', [1 0 0], 'units', 'normalized', 'visible', 'off', 'horizontalAlignment', 'left', 'verticalAlignment', 'top');
            
            stateS.handle.CERRAxisLabel2(end+1) = text('parent', stateS.handle.CERRAxis(end), 'string', '', 'position', [.90 .98 0],...
                'color', [1 0 0], 'units', 'normalized', 'visible', 'off', 'horizontalAlignment', 'left', 'verticalAlignment', 'top');

            AI(i).miscHandles = [stateS.handle.CERRAxisLabel1(end) stateS.handle.CERRAxisLabel2(end)];
        end

        axisInfo = get(hCSVA, 'userdata');
        axisInfo.scanObj(1:end) = [];
        axisInfo.doseObj(1:end) = [];
        axisInfo.structureGroup(1:end) = [];
        axisInfo.miscHandles = [];
        axisInfo.coord       = {'Linked', hCSVA};
        axisInfo.view        = {'Linked', hCSVA};
        axisInfo.xRange      = {'Linked', hCSVA};
        axisInfo.yRange      = {'Linked', hCSVA};

        for i = 1:newAxis
            axisInfo.miscHandles = AI(i).miscHandles;
            set(stateS.handle.CERRAxis(4+i), 'userdata', axisInfo);
            setAxisInfo(stateS.handle.CERRAxis(4+i),'doseSets',doseNum(i+1),'doseSelectMode', 'manual');
            CERRAxisMenu(stateS.handle.CERRAxis(4+i));
            set(stateS.handle.CERRAxis(4+i),'visible','on');
        end

        if stateS.MLVersion >= 8.4
            set(stateS.handle.CERRAxis,'ClippingStyle','rectangle')
        end
        
        stateS.handle.doseColorbar.Compare = axes('units', 'pixels', 'position', [leftMarginWidth+60+wid*4+20 bottomMarginHeight+30 50 hig-40],...
            'xTickLabel', [], 'yTickLabel', [], 'xTick', [], 'yTick', [], 'Tag', 'ColorbarCompare', 'visible', 'off');
        stateS.doseSetChanged = 1;
        CERRRefresh
        sliceCallBack('RESIZE');

    case 'COMPAREMODE'
        hAxis = gca;
        stateS.doseSetChanged = 1;
        refDose= getAxisInfo(hCSVA,'doseSets');
        tarDose= getAxisInfo(hAxis,'doseSets');
       
        doseNumOld = length(planC{indexS.dose});

        switch upper(varargin{1})
            case 'DEFAULT'
                doseNum = getAssociatedDose(planC{indexS.dose}(getAxisInfo(hAxis,'doseSetsLast')).doseUID);
                setappdata(hAxis,'compareMode',[]);
            otherwise
                setappdata(hAxis,'compareMode',upper(varargin{1}));
                [doseNum flag] = chkDose(refDose,tarDose);
                if ~flag & isempty(doseNum)%if not calculated
                    DoseAdditionSubtraction(planC{indexS.dose}(refDose),planC{indexS.dose}(tarDose),'Subtract',0);
                    doseNum = length(planC{indexS.dose});
                    if doseNumOld == doseNum
                        return
                    end
                end
        end
        setAxisInfo(hAxis,'doseSets',doseNum);
        CERRRefresh

    case 'EXIT'
        stateS.Oldlayout = [];
        stateS.doseSet = stateS.oldDoseSet;
        stateS.doseSetChanged = 1;
        delete(stateS.handle.doseColorbar.Compare)

        hDel = (findobj('Tag','doseCompareAxes'));
        for i = 1:length(hDel)
            hDel_ind = find(stateS.handle.CERRAxis == hDel(i));
            delete(stateS.handle.CERRAxis(hDel_ind));
            stateS.handle.CERRAxisLabel1(hDel_ind)=[];
            stateS.handle.CERRAxisLabel2(hDel_ind)=[];
            stateS.handle.CERRAxis(hDel_ind)=[];
        end
        for i = 1:length(stateS.handle.CERRAxis)
            setAxisInfo(stateS.handle.CERRAxis(i),'doseSets',getAxisInfo(stateS.handle.CERRAxis(i),'doseSetsLast'),...
                'scanSets',getAxisInfo(stateS.handle.CERRAxis(i),'scanSetsLast'));
            setappdata(stateS.handle.CERRAxis(i),'compareMode',[]);
        end
        sliceCallBack('resize');
        CERRRefresh
end