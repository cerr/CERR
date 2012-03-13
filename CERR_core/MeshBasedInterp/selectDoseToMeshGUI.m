function selectDoseToMeshGUI(command,varargin)
% GUI to enable Mesh Representation of selected dose distributions.
%
% APA, 05/23/2007
% Based on structRenameGUI.m
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

    case 'INIT'

        units = 'pixels';

        x = 340; y = 700;

        hFig = figure('Menu','None','Position',[100,100,x,y],'Name','Mesh Representation of Dose', 'units', 'pixels',...
            'NumberTitle', 'off', 'resize', 'off', 'Tag', 'selectDoseToMeshGUI');

        statusFrame = uicontrol(hFig, 'units',units ,'Position', [10 10 x-18 y-18], 'style', 'frame');

        frameColor = get(statusFrame,'backgroundcolor');

        uicontrol(hFig, 'units',units,'Position',[x/2-125,670,250,20], 'style', 'text', 'String', 'Select Dose for Mesh Representation',...
            'backgroundcolor', frameColor,'fontweight', 'bold','fontsize',8);

        uicontrol(hFig, 'units',units,'Position',[x/2-150,650,250,20], 'style', 'text', 'String', 'Index              Name                     Selection',...
            'backgroundcolor', frameColor,'fontweight', 'bold','fontsize',8, 'horizontalAlignment','left');

        numRows = 30;

        for i=1:numRows
            ud.handles.doseNum(i) = uicontrol(hFig, 'units',units,'Position',[10+3    y-18-30-i*20   20   15], 'style', 'text',...
                'String', num2str(i), 'backgroundcolor', frameColor,'Visible','Off');
            ud.handles.doseName(i)  = uicontrol(hFig, 'units',units,'Position',[10+40   y-18-30-i*20   100  15], 'style', 'text',...
                'String', 'dose Name', 'backgroundcolor', frameColor,'Visible','Off');
            ud.handles.selection(i) = uicontrol(hFig, 'units',units,'Position',[10+185  y-18-30-i*20   100  15], 'style', 'check', 'backgroundcolor', frameColor,...
                'horizontalAlignment', 'center', 'userdata', i, 'Tag', 'newdoseName','Visible','Off');
        end

        ud.numStructRows = numRows;

        for j =  1:length(planC{indexS.dose})
            if isfield(planC{indexS.dose}(j),'meshRep') && ~isempty(planC{indexS.dose}(j).meshRep) && planC{indexS.dose}(j).meshRep == 1
                ud.dose(j).selection = planC{indexS.dose}(j).meshRep;
            else
                ud.dose(j).selection = 0;
            end
        end

        ud.handles.structsSlider = uicontrol(hFig, 'units',units,'Position',[x-18-10 10 20 y-10-10], 'style', 'slider',...
            'enable', 'off','tag','structSlider','callback','selectDoseToMeshGUI(''sliderRefresh'')');

        ud.handles.merge = uicontrol(hFig, 'units',units, 'Position', [x/2-30 12 60 20], 'style', 'pushbutton', ...
            'string', 'Done', 'callback', 'selectDoseToMeshGUI(''done'')');

        set(hFig,'Userdata',ud);

        selectDoseToMeshGUI('refresh')

    case 'REFRESH'

        hFig = findobj('Tag','selectDoseToMeshGUI');

        ud = get(hFig,'Userdata');

        structLen = length(planC{indexS.dose});

        if structLen > ud.numStructRows
            % Enable Slider
            set(ud.handles.structsSlider,'Enable','On');
        end

        if structLen > ud.numStructRows
            set(ud.handles.structsSlider,'enable', 'on','BackgroundColor',[0 0 0]);

            if (structLen/ud.numStructRows) < 2
                max = 2;
            elseif (structLen/ud.numStructRows) > 2
                max = 3;
            elseif (structLen/ud.numStructRows) > 3
                max = 4;
            end

            try
                value = ud.sliderValue;
            catch
                value = max;
                ud.slider.oldValue = value;
            end

            set(ud.handles.structsSlider,'min',1,'max',max,'value',value,'sliderstep',[1 1]);
            % initialize structure slider
            set(hFig,'Userdata',ud);

            selectDoseToMeshGUI('sliderRefresh','init');

        else
            if length(planC{indexS.dose})> ud.numStructRows
                numStruct = ud.numStructRows;
            else
                numStruct = length(planC{indexS.dose});
            end

            for i=1:numStruct
                doseNum  = i;
                doseName = planC{indexS.dose}(doseNum).fractionGroupID;
                set(ud.handles.doseName(doseNum), 'string', doseName, 'visible', 'on');
                set(ud.handles.doseNum(doseNum) , 'visible','on');
                selection =  ud.dose(doseNum).selection;
                set(ud.handles.selection(doseNum) ,'value', selection, 'visible','on');
            end

        end

    case 'SLIDERREFRESH'
        ud = get(findobj('Tag','selectDoseToMeshGUI'),'Userdata');
        oldValue = ud.slider.oldValue;
        olddoseNum = getStructDispLen(oldValue);
    
        if ~(length(varargin) > 0 && strcmpi(varargin,'init'))
            for jj = 1: length(olddoseNum)
                ud.struct(olddoseNum(jj)).selection = get(ud.handles.selection(jj),'value');
            end
        end        

        value = round(get(ud.handles.structsSlider,'value'));
        set(ud.handles.structsSlider,'value',value)        

        ud.slider.oldValue = value;
        set(findobj('Tag','selectDoseToMeshGUI'),'Userdata',ud);

        numStruct = getStructDispLen(value);

        for i = 1:length(numStruct)
            doseNum  = numStruct(i);
            doseName = planC{indexS.dose}(doseNum ).fractionGroupID;
            set(ud.handles.doseName(i), 'string', doseName, 'visible', 'on');
            set(ud.handles.doseNum(i) , 'visible','on','String',doseNum);
            selection =  ud.dose(numStruct(i)).selection;
            set(ud.handles.selection(i) , 'value', selection,'visible','on');
        end

        for j = length(numStruct)+1:ud.numStructRows
            set(ud.handles.doseName(j), 'visible','off');
            set(ud.handles.doseNum(j) , 'visible','off');
            set(ud.handles.selection(j), 'visible','off');
        end

    case 'DONE'
        hFig = findobj('Tag','selectDoseToMeshGUI');
        ud = get(hFig,'Userdata');

        sliderVis = get(ud.handles.structsSlider,'enable');

        %set Matlab path to directory containing the library
        currDir = cd;
        meshDir = fileparts(which('libMeshContour.dll'));
        cd(meshDir)

        loadlibrary('libMeshContour','MeshContour.h')
        if strcmpi(sliderVis,'off')
            waitbarH = waitbar(0,'Generate surface meshes for dose...');
            contourLevels = getIsoDoseLevels;
            for doseNum = 1:length(ud.handles.selection)                
                if doseNum <= length(planC{indexS.dose})
                    selection = get(ud.handles.selection(doseNum),'value');
                    planC{indexS.dose}(doseNum).meshRep = selection;
                    %Clear Mesh from memory
                    doseUID   = planC{indexS.dose}(doseNum).doseUID;                                        
                    if selection == 0
                        for level = 1:length(contourLevels)
                            calllib('libMeshContour','clear',[doseUID,'_',num2str(contourLevels(level))])
                        end                        
                    else
                        doseVolume = planC{indexS.dose}(doseNum).doseArray;
                        doseVolume = permute(doseVolume,[2 1 3]);
                        [xVals, yVals, zVals] = getDoseXYZVals(planC{indexS.dose}(doseNum));
                        %load volume data                        
                        calllib('libMeshContour','loadVolumeData',doseUID,xVals, yVals, zVals, double(doseVolume))                        
                        for level = 1:length(contourLevels)
                            calllib('libMeshContour','generateSurface', doseUID, [doseUID,'_',num2str(contourLevels(level))], double(contourLevels(level)), uint16(10));                            
                        end
                        calllib('libMeshContour','clear',doseUID)
                    end
                end
                waitbar(doseNum/length(ud.handles.selection),waitbarH)
            end
        else
            oldValue = ud.slider.oldValue;
            olddoseNum = getStructDispLen(oldValue);

            for jj = 1: length(olddoseNum)
                ud.dose(olddoseNum(jj)).selection = get(ud.handles.selection(jj),'value');
            end
            
            waitbarH = waitbar(0,'Generating surface meshes for anatomical dose...');
            for doseNum = 1:length(planC{indexS.dose})
                selection = ud.dose(doseNum).selection;
                planC{indexS.dose}(doseNum).meshRep = selection;
                %Clear Mesh from memory
                doseUID   = planC{indexS.dose}(doseNum).doseUID;                
                if selection == 0
                    for level = 1:length(contourLevels)
                        calllib('libMeshContour','clear',[doseUID,'_',num2str(contourLevels(level))])
                    end
                else
                    doseVolume = planC{indexS.dose}(doseNum).doseArray;
                    doseVolume = permute(doseVolume,[2 1 3]);
                    [xVals, yVals, zVals] = getDoseXYZVals(planC{indexS.dose}(doseNum));
                    %load volume data
                    calllib('libMeshContour','loadVolumeData',doseUID,xVals, yVals, zVals, double(doseVolume))
                    for level = 1:length(contourLevels)
                        calllib('libMeshContour','generateSurface', [doseUID,'_',num2str(contourLevels(level))], contourLevels(level), uint16(0));
                    end
                end
                waitbar(doseNum/length(planC{indexS.dose}),waitbarH)
            end
        end
        close(waitbarH)        
        delete(hFig);

        %switch back the current irectory
        cd(currDir)
        
        stateS.doseChanged = 1;
        stateS.doseDisplayChanged = 1;
        CERRRefresh
        
end
return;


function numStruct = getStructDispLen(value)
global planC

indexS = planC{end};

ud = get(findobj('Tag','selectDoseToMeshGUI'),'Userdata');
max = get(ud.handles.structsSlider,'max');

if max == 2
    if value == 2
        numStruct = 1:ud.numStructRows;
    elseif value == 1
        numStruct = ud.numStructRows+1:length(planC{indexS.dose});
    end
elseif max == 3
    if value == 3
        numStruct = 1:ud.numStructRows;
    elseif value == 2
        numStruct = ud.numStructRows+1:ud.numStructRows*2;
    elseif value == 1
        numStruct = ud.numStructRows*2+1:length(planC{indexS.dose});
    end
end
return;
