function selectStructsToMeshGUI(command,varargin)
% GUI to enable Mesh Representation of selected structures.
%
% APA, 05/17/2007
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

        hFig = figure('Menu','None','Position',[100,100,x,y],'Name','Mesh Representation of Structures', 'units', 'pixels',...
            'NumberTitle', 'off', 'resize', 'off', 'Tag', 'selectStructsToMeshGUI');

        statusFrame = uicontrol(hFig, 'units',units ,'Position', [10 10 x-18 y-18], 'style', 'frame');

        frameColor = get(statusFrame,'backgroundcolor');

        uicontrol(hFig, 'units',units,'Position',[x/2-125,670,250,20], 'style', 'text', 'String', 'Select Structures for Mesh Representation',...
            'backgroundcolor', frameColor,'fontweight', 'bold','fontsize',8);

        uicontrol(hFig, 'units',units,'Position',[x/2-150,650,250,20], 'style', 'text', 'String', 'Index              Name                     Selection',...
            'backgroundcolor', frameColor,'fontweight', 'bold','fontsize',8, 'horizontalAlignment','left');

        numRows = 30;

        for i=1:numRows
            ud.handles.strNum(i) = uicontrol(hFig, 'units',units,'Position',[10+3    y-18-30-i*20   20   15], 'style', 'text',...
                'String', num2str(i), 'backgroundcolor', frameColor,'Visible','Off', 'horizontalAlignment','center');
            ud.handles.strName(i)  = uicontrol(hFig, 'units',units,'Position',[10+40   y-18-30-i*20   100  15], 'style', 'text',...
                'String', 'struct Name', 'backgroundcolor', frameColor,'Visible','Off', 'horizontalAlignment','center');
            ud.handles.selection(i) = uicontrol(hFig, 'units',units,'Position',[10+185  y-18-30-i*20   100  15], 'style', 'check', 'backgroundcolor', frameColor,...
                'horizontalAlignment', 'center', 'userdata', i, 'Tag', 'newStructName','Visible','Off');
        end

        ud.numStructRows = numRows;

        for j =  1:length(planC{indexS.structures})
            if isfield(planC{indexS.structures}(j),'meshRep') && ~isempty(planC{indexS.structures}(j).meshRep) && planC{indexS.structures}(j).meshRep == 1
                ud.struct(j).selection = planC{indexS.structures}(j).meshRep;
            else
                ud.struct(j).selection = 0;
            end
        end

        ud.handles.structsSlider = uicontrol(hFig, 'units',units,'Position',[x-18-10 10 20 y-10-10], 'style', 'slider',...
            'enable', 'off','tag','structSlider','callback','selectStructsToMeshGUI(''sliderRefresh'')');

        ud.handles.done = uicontrol(hFig, 'units',units, 'Position', [x/2-30 12 60 20], 'style', 'pushbutton', ...
            'string', 'Done', 'callback', 'selectStructsToMeshGUI(''done'')');

        set(hFig,'Userdata',ud);

        selectStructsToMeshGUI('refresh')

    case 'REFRESH'

        hFig = findobj('Tag','selectStructsToMeshGUI');

        ud = get(hFig,'Userdata');

        structLen = length(planC{indexS.structures});

        if structLen > ud.numStructRows
            % Enable Slider
            set(ud.handles.structsSlider,'Enable','On');
        end

        if structLen > ud.numStructRows
            set(ud.handles.structsSlider,'enable', 'on');
           
            maxSliderVal = ceil(structLen/ud.numStructRows);

            try
                value = ud.sliderValue;
            catch
                value = maxSliderVal;
                ud.slider.oldValue = value;
            end

            set(ud.handles.structsSlider,'min',1,'max',maxSliderVal,'value',value,'sliderstep',[1/maxSliderVal 1/maxSliderVal]);
            % initialize structure slider
            set(hFig,'Userdata',ud);

            selectStructsToMeshGUI('sliderRefresh','init');

        else
            if length(planC{indexS.structures})> ud.numStructRows
                numStruct = ud.numStructRows;
            else
                numStruct = length(planC{indexS.structures});
            end

            for i=1:numStruct
                structNum  = i;
                structName = planC{indexS.structures}(structNum).structureName;
                set(ud.handles.strName(structNum), 'string', structName, 'visible', 'on');
                set(ud.handles.strNum(structNum) , 'visible','on');
                selection =  ud.struct(structNum).selection;
                set(ud.handles.selection(structNum) ,'value', selection, 'visible','on');
            end

        end

    case 'SLIDERREFRESH'
        ud = get(findobj('Tag','selectStructsToMeshGUI'),'Userdata');
        oldValue = ud.slider.oldValue;
        oldStructNum = getStructDispLen(oldValue);

        if ~(length(varargin) > 0 && strcmpi(varargin,'init'))
            for jj = 1: length(oldStructNum)
                ud.struct(oldStructNum(jj)).selection = get(ud.handles.selection(jj),'value');
            end
        end

        value = round(get(ud.handles.structsSlider,'value'));
        set(ud.handles.structsSlider,'value',value)

        ud.slider.oldValue = value;
        set(findobj('Tag','selectStructsToMeshGUI'),'Userdata',ud);

        numStruct = getStructDispLen(value);

        for i = 1:length(numStruct)
            structNum  = numStruct(i);
            structName = planC{indexS.structures}(structNum ).structureName;
            set(ud.handles.strName(i), 'string', structName, 'visible', 'on');
            set(ud.handles.strNum(i) , 'visible','on','String',structNum);
            selection =  ud.struct(numStruct(i)).selection;
            set(ud.handles.selection(i) , 'value', selection,'visible','on');
        end

        for j = length(numStruct)+1:ud.numStructRows
            set(ud.handles.strName(j), 'visible','off');
            set(ud.handles.strNum(j) , 'visible','off');
            set(ud.handles.selection(j), 'visible','off');
        end

    case 'DONE'
        hFig = findobj('Tag','selectStructsToMeshGUI');
        ud = get(hFig,'Userdata');

        sliderVis = get(ud.handles.structsSlider,'enable');

        %set Matlab path to directory containing the library
        currDir = cd;        
        
        if ispc
            meshDir = fileparts(which('libMeshContour.dll'));
            cd(meshDir);
            loadlibrary('libMeshContour','MeshContour.h');
        elseif isunix
            meshDir = fileparts(which('libMeshContour.so'));
            cd(meshDir);
            loadlibrary('libMeshContour.so','MeshContour.h');
        end
        
        meshClass = 'libMeshContour';
        if strcmpi(sliderVis,'off')
            waitbarH = waitbar(0,'Generate surface meshes for anatomical structures...');
            for i = 1:length(ud.handles.selection)
                structNum = i;
                if structNum <= length(planC{indexS.structures})
                    selection = get(ud.handles.selection(structNum),'value');
                    planC{indexS.structures}(structNum).meshRep = selection;
                    %Clear Mesh from memory
                    if selection == 0
                        calllib(meshClass,'clear',planC{indexS.structures}(structNum).strUID)
                        planC{indexS.structures}(structNum).meshS = [];
                    else
                        try
                            assocScan = getStructureAssociatedScan(structNum,planC);
                            [xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(assocScan));
                            structUID   = planC{indexS.structures}(structNum).strUID;
                            [rasterSegments, planC, isError]    = getRasterSegments(structNum);
                            [mask3M, uniqueSlices] = rasterToMask(rasterSegments, assocScan);
                            mask3M = permute(mask3M,[2 1 3]);
                            if size(mask3M,3)==1
                                if uniqueSlices==1
                                    mask3M(:,:,2) = zeros(size(mask3M));
                                    uniqueSlices = [uniqueSlices uniqueSlices+1];
                                elseif uniqueSlices==length(zVals)
                                    mask3M(:,:,2) = zeros(size(mask3M));
                                    uniqueSlices = [uniqueSlices uniqueSlices-1];
                                else
                                    mask3M(:,:,2) = zeros(size(mask3M));
                                    uniqueSlices = [uniqueSlices uniqueSlices+1];
                                end
                            end
                            calllib(meshClass,'loadVolumeAndGenerateSurface',structUID,xVals,yVals,zVals(uniqueSlices), double(mask3M),0.5, uint16(10))
                            %Store mesh under planC
                            planC{indexS.structures}(structNum).meshS = calllib(meshClass,'getSurface',structUID);
                        catch
                            planC{indexS.structures}(structNum).meshRep = 0;
                        end
                    end
                end
                waitbar(i/length(ud.handles.selection),waitbarH)
            end
        else
            oldValue = ud.slider.oldValue;
            oldStructNum = getStructDispLen(oldValue);

            for jj = 1: length(oldStructNum)
                ud.struct(oldStructNum(jj)).selection = get(ud.handles.selection(jj),'value');
            end
            
            waitbarH = waitbar(0,'Generate surface meshes for anatomical structures...');
            for i = 1:length(planC{indexS.structures})
                selection = ud.struct(i).selection;
                planC{indexS.structures}(i).meshRep = selection;
                %Clear Mesh from memory
                if selection == 0
                    calllib('libMeshContour','clear',planC{indexS.structures}(i).strUID)
                    planC{indexS.structures}(i).meshS = [];
                else
                    try
                        assocScan = getStructureAssociatedScan(i,planC);
                        [xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(assocScan));
                        structUID   = planC{indexS.structures}(i).strUID;
                        [rasterSegments, planC, isError]    = getRasterSegments(i);
                        [mask3M, uniqueSlices] = rasterToMask(rasterSegments, assocScan);
                        mask3M = permute(mask3M,[2 1 3]);
                        if size(mask3M,3)==1
                            if uniqueSlices==1
                                mask3M(:,:,2) = zeros(size(mask3M));
                                uniqueSlices = [uniqueSlices uniqueSlices+1];
                            elseif uniqueSlices==length(zVals)
                                mask3M(:,:,2) = zeros(size(mask3M));
                                uniqueSlices = [uniqueSlices uniqueSlices-1];
                            else
                                mask3M(:,:,2) = zeros(size(mask3M));
                                uniqueSlices = [uniqueSlices uniqueSlices+1];
                            end
                        end
                        calllib('libMeshContour','loadVolumeAndGenerateSurface',structUID,xVals,yVals,zVals(uniqueSlices), double(mask3M),0.5, uint16(10))
                        %Store mesh under planC
                        planC{indexS.structures}(i).meshS = calllib('libMeshContour','getSurface',structUID);
                    catch
                        planC{indexS.structures}(i).meshRep = 0;
                    end
                end
                waitbar(i/length(planC{indexS.structures}),waitbarH)
            end
        end
        close(waitbarH);
        %unloadlibrary('libMeshContour');
        delete(hFig);
        
        %switch back the current directory
        cd(currDir);
        
        stateS.structsChanged = 1;
        CERRRefresh;
        
end

return;

function numStruct = getStructDispLen(value)
global planC

indexS = planC{end};

ud = get(findobj('Tag','selectStructsToMeshGUI'),'Userdata');
maxSliderVal = get(ud.handles.structsSlider,'max');

value = maxSliderVal - value + 1;

if length(planC{indexS.structures}) <= ud.numStructRows
    numStruct = 1:length(planC{indexS.structures});
else
    if ceil(length(planC{indexS.structures}) / ud.numStructRows) == value
        numStruct = (value-1)*ud.numStructRows+1:length(planC{indexS.structures});
    else
        numStruct = (value-1)*ud.numStructRows+1:(value)*ud.numStructRows;
    end
end
return;
