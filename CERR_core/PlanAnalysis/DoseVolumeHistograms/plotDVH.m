function doseStat = plotDVH(surfV, volV, avgV, absV, newFlag, gridFlag, stdFlag, cum_diff_string)
%"plotDVH"
%   Plot a set of DVHs/DSHs, given a vector of length nDVH which contains
%   boolean values, 1 if that DVH/DSH should be rendered and zero if not.
%
%Usage:
%   function plotDVH(surfV, volV, absV, newFlag, gridFlag)
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

global planC
global stateS
DVHOptS = [];
indexS = planC{end};
optS = stateS.optS;

volV    = logical(volV);
surfV   = logical(surfV);
avgV    = logical(avgV);
absV    = logical(absV);
legend_str = '';
legend_string = '';
legend_string_abs = '';

%Prepare a figure.
if exist('newFlag') & newFlag == 1
    h = figure('tag', 'DVHPlot', 'doublebuffer', 'on');
    pos = get(h,'position');
    nDVHFigs = length(findobj('tag', 'DVHPlot'));
    set(h,'position',[pos(1)*(1 - 0.05*nDVHFigs),pos(2)*(1 - 0.05*nDVHFigs),pos(3),pos(4)])
    try
        stateS.handle.DVHPlot = [stateS.handle.DVHPlot h];
    catch
        stateS.handle.DVHPlot = h;
    end
else
    h = findobj('tag', 'DVHPlot');
    if ~isempty(h)
        h = h(1);
        delete(get(h, 'children'));
        set(h, 'userdata', []);
        figure(h);
    else
        h = figure('tag', 'DVHPlot', 'doublebuffer', 'on');
        figure(h);
        try
            stateS.handle.DVHPlot = [stateS.handle.DVHPlot h];
        catch
            stateS.handle.DVHPlot = h;
        end
    end
end
set(h, 'userdata', []);
uimenu(h, 'label', 'Expand Options', 'callback',['plotDVHCallback(''EXPANDEDVIEW'')'],'interruptible','on');
set(h,'name',['DVH plot: ' stateS.CERRFile])
color2V = get(stateS.handle.CERRSliceViewer, 'Color');
set(h,'color', color2V);
set(h,'numbertitle','off')
hAxis = axes('parent', h);

if any(volV) && any(surfV)
    ylabel('Fractional volume or area', 'parent', hAxis)
    title('Dose volume or surface histograms', 'parent', hAxis)
elseif any(volV)
    ylabel('Fractional volume', 'parent', hAxis)
    title('Dose volume histograms', 'parent', hAxis)
elseif any(surfV)
    ylabel('Fractional area', 'parent', hAxis)
    title('Dose surface histograms', 'parent', hAxis)
end

if gridFlag
    grid(hAxis, 'on');
else
    grid(hAxis, 'off');
end
%%%%%

absSubPlot = 1;
numAbs = sum(absV);

hOld = findobj('tag','CERRAbsDVHPlot');
gridSetting = 'on'; %default
try
    figure(hOld(1))
    gridSetting = get(gca,'xgrid');
    delete(hOld)
end

hold on
count = 1;
%Iterate over the volV, surfV DVH lists, calculate if flagged.
skipDVH = 0;

if length(volV)==1
    dispLegend = 0;
else
    dispLegend = 1;
end

oldUnits = '';
for i = 1 : length(volV)
    DVHNum  = i;
    doseSet = getAssociatedDose(planC{indexS.DVH}(i).assocDoseUID);    
    str = planC{indexS.DVH}(i).structureName;
    structNum = getAssociatedStr(planC{indexS.DVH}(i).assocStrUID);    
    
    if surfV(i)
        if structNum ~= 0
            sNames = {planC{indexS.DVH}.structureName};
            sameName = find(strcmpi(sNames, str) & surfV);
            flagLSS = find(sameName == i);
            %Draw the surface DSH.
            showDSH(hAxis, DVHNum, doseSet, gridSetting, flagLSS, absV(i), gridFlag, cum_diff_string);
            drawnow
        else
            warning('There is no structure by that name:  only a DVH was saved.')
            CERRStatusString('There is no structure by that name:  only a DVH was saved.')
        end
        str = planC{indexS.DVH}(i).structureName;
        if ~isempty(planC{indexS.DVH}(i).fractionIDOfOrigin)
            str = [str, ' (', num2str(planC{indexS.DVH}(i).fractionIDOfOrigin), ')'];
        end        
        str = regexprep(str,'_','-');
        if dispLegend % if only one DVH is displayed do not show legend
            if isempty(legend_str)
                legend_str = str;
            else
                legend_str = char(legend_str,str);
            end
            
            if absV(i) && isempty(legend_string_abs)
                legend_string_abs = str;
            elseif absV(i)
                legend_string_abs = char(legend_string_abs,str);
            end
            legend(hAxis,'Location', 'NorthEastOutside', legend_str);%adds legend to DSH plot
            absDVHAxis = findobj('tag', 'AbsDVHAxis');
            if ~isempty(absDVHAxis)
                legend(absDVHAxis,'Location', 'NorthEastOutside', legend_string_abs);%adds legend to DVH plot
            end
        end
    end

    if volV(i)
        %Do we have raster segments?
        if structNum ~= 0
            if isempty(planC{indexS.structures}(structNum).rasterSegments)
                warning(['No scan segments stored for structure ' num2str(structNum) ])
            end
        end
        sNames = {planC{indexS.DVH}.structureName};
        sameName = find(strcmpi(sNames, str) & volV);
        flagLSS = find(sameName == i);
        if isempty(doseSet) || isempty(structNum)
            units = planC{indexS.DVH}(i).doseUnits;
        else
            units = getDoseUnitsStr(doseSet,planC);
        end
        if isempty(oldUnits)
            xlabel(['Dose ' units], 'parent', hAxis)
            oldUnits = units;
        elseif ~isempty(oldUnits) && ~strcmpi(units,oldUnits)
            errordlg('Dose units must be same for all DVHs.','Dose Units','modal')
            return;
        end
        
        %Omit DVH's if dose units are not in Gy or cGy
        if ~isempty(planC{indexS.DVH}(DVHNum).DVHMatrix)
            if ~(strcmpi(getDVHDoseUnitsStr(DVHNum), 'cGy') || strcmpi(getDVHDoseUnitsStr(DVHNum), 'Gy'))
                skipDVH = skipDVH +1;
                continue
            end
        else
            if ~(strcmpi(getDoseUnitsStr(doseSet,planC), 'cGy') || strcmpi(getDoseUnitsStr(doseSet,planC), 'Gy'))
                skipDVH = skipDVH +1;
                continue
            end
        end

        %Draw the volume DVH.
        %[planC] = showDVH(hAxis, DVHNum, doseSet, gridSetting, flagLSS, absV(i), gridFlag);
        doseStat = showDVH(hAxis, DVHNum, doseSet, gridSetting, flagLSS, absV(i), gridFlag, cum_diff_string);
        if isempty(doseStat)
            return
        end
        drawnow
        name = planC{indexS.DVH}(DVHNum).structureName;
        if ~isempty(planC{indexS.DVH}(DVHNum).fractionIDOfOrigin)
            name = [name, ' (', num2str(planC{indexS.DVH}(DVHNum).fractionIDOfOrigin), ')'];
        end
        name = regexprep(name,'_','-');
        if dispLegend % if only one DVH is displayed do not show legend
            if isempty(legend_string)
                legend_string = name;
            else
                legend_string = char(legend_string,name); %strvcat(legend_string,name);
            end
            
            if absV(i) && isempty(legend_string_abs)
                legend_string_abs = name;
            elseif absV(i)
                legend_string_abs = char(legend_string_abs,name);
            end
            legend(hAxis,'Location', 'NorthEastOutside', legend_string);%adds legend to DVH plot
            absDVHAxis = findobj('tag', 'AbsDVHAxis');
            if ~isempty(absDVHAxis)
                legend(absDVHAxis,'Location', 'NorthEastOutside', legend_string_abs);%adds legend to DVH plot
            end
        end
    end

    if avgV(i)
        allDVHNum(count,1) = DVHNum;
        if isempty(doseSet)
            allDoseSet(count,1) = 0;
        else
            allDoseSet(count,1)= doseSet;
        end
        count = count +1;
        sNames = {planC{indexS.DVH}.structureName};
        sameName = find(strcmpi(sNames, str) & avgV);
        usrData = get(h,'userdata');
    end
end

if any(avgV)
    ind = find(avgV);
    if length(ind)> 1
        if any(volV)
            volFlag = 1;
        else
            volFlag = 0;
        end
        showDAvH(allDVHNum, allDoseSet, volFlag, stdFlag)
    else
        hWarn = warndlg('More than one structure should be selected to show average plot');
        waitfor(hWarn);
        return
    end
end
hold off


%=================================%
function doseStat = showDSH(hAxis, DVHNum, doseSet, gridSetting, flagLSS, absFlag, gridFlag, cum_diff_string)
%Draw the DSH in the current figure.
global planC
global stateS
indexS = planC{end};
optS = stateS.optS;

hFig = get(hAxis, 'parent');

struct    = planC{indexS.DVH}(DVHNum).structureName;
doseName  = planC{indexS.DVH}(DVHNum).fractionIDOfOrigin;
structNum = getStructNum(struct,planC,indexS);

%If no dose, cant calculate a DSH.
if isempty(doseSet)
    warning('No dose index specified: Cannot calculate DSH.');
    CERRStatusString('No dose index specified: Cannot calculate DSH.');
    return;
end

%Get the DSH data.
[doseV, areaV, zV, planC] = getDSH(structNum, doseSet, planC);
%[doseSortV indV] = sort(doseV);
%areaSortV = areaV(indV);
[doseBinsV, volsHistV] = doseHist(doseV, areaV, optS.DVHBinWidth);
cumAreaV = cumsum(volsHistV);
cumArea2V  = cumAreaV(end) - cumAreaV;

%Determine color of line.
if structNum ~= 0
    %colorV = getColor(structNum, optS.colorOrder);
    colorV = planC{indexS.structures}(structNum).structureColor;
else
    colorV = getColor(DVHNum, optS.colorOrder);
end

% %No need to shift the DSH/DVH data by the offset, since getDSH returns the shifted dose.
% if strcmpi(cum_diff_string,'CUMU')
%     h = plot([0; doseSortV(:)], [1; cumArea2V(:)/cumAreaV(end)], 'parent', hAxis);
%     addDVHtoFig(hFig, struct, doseSet, h, [0; doseSortV(:)], [1; cumArea2V(:)/cumAreaV(end)], 'DSH', 'NOABS', doseV, areaV, doseName);
% elseif strcmpi(cum_diff_string,'DIFF')
%     indPlot = find(areaSortV);
%     h = plot(doseSortV(indPlot), areaSortV(indPlot)/cumAreaV(end));
%     addDVHtoFig(hFig, struct, doseSet, h, doseSortV(indPlot), areaSortV(indPlot)/cumAreaV(end), 'DSH', 'NOABS', doseV, areaV, doseName);
% end

if strcmpi(cum_diff_string,'CUMU')
    h = plot([0, doseBinsV(:)'], [1, cumArea2V(:)'/cumAreaV(end)]);
    addDVHtoFig(hFig, struct, doseSet, h, [0, doseBinsV(:)'], [1, cumArea2V(:)'/cumAreaV(end)], 'DVH', 'NOABS', doseBinsV, volsHistV, doseName);
elseif strcmpi(cum_diff_string,'DIFF')
    indPlot = find(volsHistV);
    h = plot(doseBinsV(indPlot), volsHistV(indPlot)/cumAreaV(end));
    addDVHtoFig(hFig, struct, doseSet, h, doseBinsV(indPlot), volsHistV(indPlot)/cumAreaV(end), 'DVH', 'NOABS', doseBinsV, volsHistV, doseName);
end

set(hAxis,'nextplot','add')
set(h,'color', colorV)
set(h,'linestyle','--')
switch mod(flagLSS, 4)
    case 0
        set(h,'linestyle','--');
    case 1
        set(h,'linestyle','-');
    case 2
        set(h,'linestyle',':');
    case 3
        set(h,'linestyle','-.');
end
set(h,'linewidth',stateS.optS.DVHLineWidth);
drawnow

opt = 'DSHDose';

name = planC{indexS.DVH}(DVHNum).structureName;
nameVol = planC{indexS.DVH}(DVHNum).fractionIDOfOrigin;
doseStat = dispDoseStats(doseBinsV, volsHistV, name, nameVol, planC, indexS, opt);

if absFlag == 1
    hRel = get(hAxis, 'parent');
    hAbsDVH = findobj('tag', 'CERRAbsDVHPlot');
    if isempty(hAbsDVH)
        hFig = figure('tag', 'CERRAbsDVHPlot', 'doublebuffer', 'on');
        uimenu(hFig, 'label', 'Expand Options', 'callback','plotDVHCallback(''EXPANDEDVIEW'')','interruptible','on');
        %absAxis = axes('parent', hFig);
        absAxis = axes('parent', hFig, 'tag', 'AbsDVHAxis', 'nextPlot','Add');
        set(hFig,'numbertitle','off')
        pos = get(hFig,'position');
        nDVHFigs = length(findobj('tag', 'DVHPlot'));
        set(hFig,'position',[pos(1)*(1 - 0.05*nDVHFigs),pos(2)*(1 - 0.05*nDVHFigs),pos(3),pos(4)])        
    else
        hFig = hAbsDVH;
        figure(hFig);
        absAxis = findobj(hFig,'tag', 'AbsDVHAxis');
    end
    
    %p = plot(doseSortV, cumArea2V);
    if strcmpi(cum_diff_string,'CUMU')
        h = plot([doseBinsV(:)'], [cumArea2V(:)]);
        %addDVHtoFig(hFig, struct, doseSet, h, [doseBinsV(:)'], [cumArea2V(:)], 'DVH', 'NOABS', doseBinsV, volsHistV, doseName);
        addDVHtoFig(hFig, struct, doseSet, h, doseBinsV(:)', cumArea2V(:)', 'DSH', 'ABS', doseBinsV, volsHistV, doseName);
    elseif strcmpi(cum_diff_string,'DIFF')
        indPlot = find(volsHistV);
        h = plot(doseBinsV(indPlot), volsHistV(indPlot));
        %addDVHtoFig(hFig, struct, doseSet, h, doseBinsV(indPlot), volsHistV(indPlot), 'DVH', 'NOABS', doseBinsV, volsHistV, doseName);
        addDVHtoFig(hFig, struct, doseSet, h, doseBinsV(indPlot), volsHistV(indPlot), 'DSH', 'ABS', doseBinsV, volsHistV, doseName);
    end
    %addDVHtoFig(h, struct, doseSet, p, doseSortV, cumArea2V, 'DSH', 'ABS', doseV, areaV, doseName);
    set(absAxis,'xgrid',gridSetting)
    set(absAxis,'ygrid',gridSetting)
    %set(h,'tag','CERRAbsDVHPlot')
    if structNum ~= 0
        %colorV = getColor(structNum, optS.colorOrder);
        colorV = planC{indexS.structures}(structNum).structureColor;
    else
        colorV = getColor(DVHNum, optS.colorOrder);
    end
    set(h,'color', colorV)

    switch mod(flagLSS, 4)
        case 0
            set(h,'linestyle','--')
        case 1
            set(h,'linestyle','-')
        case 2
            set(h,'linestyle',':');
        case 3
            set(h,'linestyle','-.');
    end

    set(h,'linewidth',stateS.optS.DVHLineWidth)
    ylabel('Absolute surface area (sq-cm)')
    structNum = getAssociatedStr(planC{indexS.DVH}(DVHNum).assocStrUID);    
    doseSet = getAssociatedDose(planC{indexS.DVH}(DVHNum).assocDoseUID);
    if isempty(doseSet) || isempty(structNum)
        units = planC{indexS.DVH}(DVHNum).doseUnits;
    else
        units = getDoseUnitsStr(doseSet,planC);
    end    
    if ~isempty(units)
        units = ['(' units ')'];
    end    
    xlabel(['Dose ' units])
    
    %title(['Absolute surface area DSH plot for:  ' struct])
    title('Absolute surface area DSH plot')
    if gridFlag
        grid(absAxis, 'on');
    else
        grid(absAxis, 'off');
    end
    figure(hRel)

    set(hFig,'name',['Abs DSH plot: ' stateS.CERRFile])
    stateS.handle.DSHAbsPlots = findobj('tag','CERRAbsDVHPlot');
end
