function plotIVH(surfV, volV, avgV, absV, newFlag, gridFlag, cum_diff_string)
%"plotIVH"
%   Plot a set of IVHs/DSHs, given a vector of length nIVH which contains
%   boolean values, 1 if that IVH/DSH should be rendered and zero if not.
%
%Usage:
%   function plotIVH(surfV, volV, absV, newFlag, gridFlag)%
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
IVHOptS = [];
indexS = planC{end};
optS = stateS.optS;

volV    = logical(volV);
surfV   = logical(surfV);
avgV    = logical(avgV);
absV    = logical(absV);

%Prepare a figure.
if exist('newFlag') & newFlag == 1
    h = figure('tag', 'IVHPlot', 'doublebuffer', 'on');
    pos = get(h,'position');
    nIVHFigs = length(findobj('tag', 'IVHPlot'));
    set(h,'position',[pos(1)*(1 - 0.05*nIVHFigs),pos(2)*(1 - 0.05*nIVHFigs),pos(3),pos(4)])
    try
        stateS.handle.IVHPlot = [stateS.handle.IVHPlot h];
    catch
        stateS.handle.IVHPlot = h;
    end
else
    h = findobj('tag', 'IVHPlot');
    if ~isempty(h)
        h = h(1);
        delete(get(h, 'children'));
        set(h, 'userdata', []);
        figure(h);
    else
        h = figure('tag', 'IVHPlot', 'doublebuffer', 'on');
        figure(h);
        try
            stateS.handle.IVHPlot = [stateS.handle.IVHPlot h];
        catch
            stateS.handle.IVHPlot = h;
        end
    end
end
set(h, 'userdata', []);
uimenu(h, 'label', 'Expand Options', 'callback',['plotIVHCallback(''EXPANDEDVIEW'')'],'interruptible','on');
set(h,'name',['IVH plot: ' stateS.CERRFile])
color2V = get(stateS.handle.CERRSliceViewer, 'Color');
set(h,'color', color2V);
set(h,'numbertitle','off')

ud = get(findobj('Tag', 'IVHGui'),'userdata');
scanNum = get(ud.af.handles.scan,'value');
imageType = planC{indexS.scan}(scanNum).scanInfo(1).imageType;

if strcmpi(imageType,'CT')
    units = 'HU';
elseif strcmpi(imageType,'PET')
    units = 'SUV';
else
    units = '';
end

if ~isempty(units)
    units = ['(' units ')'];
end
hAxis = axes('parent', h);
xlabel([imageType ' ' units], 'parent', hAxis)
ylabel('Fractional volume or area', 'parent', hAxis)
title('Scan volume or surface histograms', 'parent', hAxis)
if gridFlag
    grid(hAxis, 'on');
else
    grid(hAxis, 'off');
end
%%%%%

absSubPlot = 1;
numAbs = sum(absV);

hOld = findobj('tag','CERRAbsIVHPlot');
gridSetting = 'on'; %default
try
    figure(hOld(1))
    gridSetting = get(gca,'xgrid');
    delete(hOld)
end

hold on
count = 1;
%Iterate over the volV, surfV IVH lists, calculate if flagged.
for i = 1 : length(volV)
    IVHNum  = i;
    scanSet = getAssociatedScan(planC{indexS.IVH}(i).assocScanUID);
    str = planC{indexS.IVH}(i).structureName;
    structNum = getStructNum(str,planC,indexS);
    if surfV(i)
        if structNum ~= 0
            sNames = {planC{indexS.IVH}.structureName};
            sameName = find(strcmpi(sNames, str) & surfV);
            flagLSS = find(sameName == i);
            %Draw the surface DSH.
            showDSH(hAxis, IVHNum, scanSet, gridSetting, flagLSS, absV(i), gridFlag, cum_diff_string);
            drawnow
        else
            warning('There is no structure by that name:  only a IVH was saved.')
            CERRStatusString('There is no structure by that name:  only a IVH was saved.')
        end
    end

    if volV(i)
        %Do we have raster segments?
        if structNum ~= 0
            if isempty(planC{indexS.structures}(structNum).rasterSegments)
                warning(['No scan segments stored for structure ' num2str(structNum) ])
            end
        end
        sNames = {planC{indexS.IVH}.structureName};
        sameName = find(strcmpi(sNames, str) & volV);
        flagLSS = find(sameName == i);
        %Draw the volume IVH.
        %[planC] = showIVH(hAxis, IVHNum, scanSet, gridSetting, flagLSS, absV(i), gridFlag);
        showIVH(hAxis, IVHNum, scanSet, gridSetting, flagLSS, absV(i), gridFlag, cum_diff_string);
        drawnow
    end

    if avgV(i)
        allIVHNum(count,1) = IVHNum;
        allScanSet(count,1)= scanSet;
        count = count +1;
        sNames = {planC{indexS.IVH}.structureName};
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
        showIAvH(allIVHNum, allScanSet, volFlag)
    else
        hWarn = warndlg('More than one structure should be selected to show average plot');
        waitfor(hWarn);
        return
    end
end
hold off


%=================================%
function showDSH(hAxis, IVHNum, scanSet, gridSetting, flagLSS, absFlag, gridFlag, cum_diff_string)
%Draw the DSH in the current figure.
global planC
global stateS
indexS = planC{end};
optS = stateS.optS;

hFig = get(hAxis, 'parent');

struct    = planC{indexS.IVH}(IVHNum).structureName;
scanName  = planC{indexS.IVH}(IVHNum).scanType;
structNum = getStructNum(struct,planC,indexS);

%If no scan, cant calculate a DSH.
if isempty(scanSet)
    warning('No scan index specified: Cannot calculate DSH.');
    CERRStatusString('No scan index specified: Cannot calculate DSH.');
    return;
end

%Get the DSH data.
[scanV, areaV, zV, planC] = getISH(structNum, scanSet, planC);
[scanSortV indV] = sort(scanV);
areaSortV = areaV(indV);
cumAreaV = cumsum(areaSortV);
cumArea2V  = cumAreaV(end) - cumAreaV;

%Determine color of line.
if structNum ~= 0
    %colorV = getColor(structNum, optS.colorOrder);
    colorV = planC{indexS.structures}(structNum).structureColor;
else
    colorV = getColor(IVHNum, optS.colorOrder);
end

%Shift the DSH/IVH data by the offset, if it exists and plot.
if isfield(planC{indexS.scan}(scanSet).scanInfo(1),'CTOffset')
    offset = planC{indexS.scan}(scanSet).scanInfo(1).CTOffset;
else
    offset = 0;
end
if strcmpi(cum_diff_string,'CUMU')
    h = plot([scanSortV(1) - offset; scanSortV(:) - offset], [1; cumArea2V(:)/cumAreaV(end)], 'parent', hAxis);
    addDVHtoFig(hFig, struct, scanSet, h, [scanSortV(1)-offset; scanSortV(:) - offset], [1; cumArea2V(:)/cumAreaV(end)], 'DSH','NOABS',scanV, areaV, scanName);
elseif strcmpi(cum_diff_string,'DIFF')
    indPlot = find(areaSortV);
    h = plot(scanSortV(indPlot)-offset, areaSortV(indPlot)/cumAreaV(end));
    addDVHtoFig(hFig, struct, scanSet, h, scanSortV(indPlot)-offset, areaSortV(indPlot)/cumAreaV(end), 'DSH', 'NOABS', scanV, areaV, scanName);
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
set(h,'linewidth',stateS.optS.IVHLineWidth);
drawnow

opt = 'DSHScan';
dispScanStats(scanV, areaV, struct, scanName, planC, indexS, opt);

if absFlag == 1
    hRel = get(hAxis, 'parent');
    h = figure('tag', 'IVHPlot', 'doublebuffer', 'on');
    uimenu(h, 'label', 'Expand Options', 'callback','plotIVHCallback(''EXPANDEDVIEW'')','interruptible','on');
    absAxis = axes('parent', h);
    set(h,'numbertitle','off')
    pos = get(h,'position');
    nIVHFigs = length(findobj('tag', 'IVHPlot'));
    set(h,'position',[pos(1)*(1 - 0.05*nIVHFigs),pos(2)*(1 - 0.05*nIVHFigs),pos(3),pos(4)])
    p = plot(scanSortV, cumArea2V);
    addDVHtoFig(h, struct, scanSet, p, scanSortV, cumArea2V, 'DSH', 'ABS', scanV, areaV, scanName);
    set(absAxis,'xgrid',gridSetting)
    set(absAxis,'ygrid',gridSetting)
    set(h,'tag','CERRAbsIVHPlot')
    if structNum ~= 0
        %colorV = getColor(structNum, optS.colorOrder);
        colorV = planC{indexS.structures}(structNum).structureColor;
    else
        colorV = getColor(IVHNum, optS.colorOrder);
    end
    set(p,'color', colorV)

    switch mod(flagLSS, 4)
        case 0
            set(p,'linestyle','--')
        case 1
            set(p,'linestyle','-')
        case 2
            set(p,'linestyle',':');
        case 3
            set(p,'linestyle','-.');
    end

    set(p,'linewidth',stateS.optS.IVHLineWidth)
    ylabel('Absolute surface area (sq-cm)')
    
    ud = get(findobj('Tag', 'IVHGui'),'userdata');
    scanNum = get(ud.af.handles.scan,'value');
    imageType = planC{indexS.scan}(scanNum).scanInfo(1).imageType;

    if strcmpi(imageType,'CT')
        units = 'HU';
    elseif strcmpi(imageType,'PET')
        units = 'SUV';
    else
        units = '';
    end
    
    if ~isempty(units)
        units = ['(' units ')'];
    end
    xlabel([imageType ' ' units])
    title(['Absolute surface area DSH plot for:  ' struct])
    if gridFlag
        grid(absAxis, 'on');
    else
        grid(absAxis, 'off');
    end
    figure(hRel)
    hCERR = stateS.handle.CERRSliceViewer;
    title_str = get(hCERR,'name');
    set(h,'name',['Abs DSH plot: ' stateS.CERRFile])
    stateS.handle.DSHAbsPlots = findobj('tag','CERRAbsIVHPlot');
end


function showIVH(hAxis, IVHNum, scanSet, gridSetting, flagLSS, absFlag, gridFlag, cum_diff_string)
%Draw a IVH in hAxis.

global planC
global stateS
indexS = planC{end};
optS = stateS.optS;

hFig = get(hAxis, 'parent');

struct = planC{indexS.IVH}(IVHNum).structureName;


scanName  = planC{indexS.IVH}(IVHNum).scanType;

structNum = getStructNum(struct,planC,indexS);

if ~isempty(planC{indexS.IVH}(IVHNum).IVHMatrix)

    [scanBinsV, volsHistV] = loadIVHMatrix(IVHNum, planC);
    IVHM = [scanBinsV, volsHistV];

    volumeType = planC{indexS.IVH}(IVHNum).volumeType;

    scanType   = planC{indexS.IVH}(IVHNum).scanType;
    
    scanUnits =  planC{indexS.IVH}(IVHNum).scanUnits;

    switch lower(scanUnits)   %convert to Gy's

        case 'relative'   %untested code

            scanScale   = planC{indexS.IVH}(IVHNum).scanScale;
            scanBinsV = IVHM(:,1)' * scanScale / 100;

        case 'percent'    %untested code

            scanScale   = planC{indexS.IVH}(IVHNum).scanScale;
            scanBinsV = IVHM(:,1)' * scanScale / 100;

        case 'absolute'

            scanBinsV = IVHM(:,1)';

    end

    switch lower(volumeType)  %convert to cc's

        case 'relative'   %untested code

            volumeScale   = planC{indexS.IVH}(IVHNum).volumeScale;
            volsHistV = IVHM(:,2)' * volumeScale / 100;

        case 'percent'    %untested code

            volumeScale   = planC{indexS.IVH}(IVHNum).volumeScale;
            volsHistV = IVHM(:,2)' * volumeScale / 100;

        case {'absolute', 'differential', 'cumulative'}

            volsHistV = IVHM(:,2)';

    end

    cumVolsV = cumsum(volsHistV);

    cumVols2V  = cumVolsV(end) - cumVolsV;  %cumVolsV is the cumulative volume lt that corresponding scan
    %including that scan bin.
    
    if isfield(planC{indexS.scan}(scanSet).scanInfo(1),'CTOffset')
        offset = planC{indexS.scan}(scanSet).scanInfo(1).CTOffset;
    else
        offset = 0;
    end

    %No need to shift DVH by doseOffset since it is already included in doseBinsV.
    if strcmpi(cum_diff_string,'CUMU')
        h = plot([scanBinsV(1) - offset, scanBinsV - offset], [1, cumVols2V/cumVolsV(end)]);
        addDVHtoFig(hFig, struct, scanSet, h, [scanBinsV(1) - offset, scanBinsV - offset], [1, cumVols2V/cumVolsV(end)], 'IVH', 'NOABS', scanBinsV, volsHistV, scanName);
    elseif strcmpi(cum_diff_string,'DIFF')
        indPlot = find(volsHistV);
        h = plot(scanBinsV(indPlot)-offset, volsHistV(indPlot)/cumVolsV(end));
        addDVHtoFig(hFig, struct, scanSet, h, scanBinsV(indPlot)-offset, volsHistV(indPlot)/cumVolsV(end), 'IVH', 'NOABS', scanBinsV, volsHistV, scanName);
    end    
    
    set(hAxis,'nextplot','add')
    structNum = getStructNum(struct,planC,indexS);

    if structNum ~= 0
        %colorV = getColor(structNum, optS.colorOrder);
        colorV = planC{indexS.structures}(structNum).structureColor;
    else
        colorV = getColor(IVHNum, optS.colorOrder);
    end
    set(h,'color', colorV)

    %Set linestyle based on flagLSS
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

    set(h,'linewidth',stateS.optS.IVHLineWidth)
    drawnow

    opt = 'standardScan';
    name = planC{indexS.IVH}(IVHNum).structureName;
    nameVol = planC{indexS.IVH}(IVHNum).scanType;
    dispScanStats(scanBinsV, volsHistV, name, nameVol, planC, indexS, opt)


else   %compute yer own

    [scansV, volsV] = getIVH(structNum, scanSet, planC);

    [scanBinsV, volsHistV] = doseHist(scansV, volsV, optS.IVHBinWidth);

    cumVolsV = cumsum(volsHistV);

    cumVols2V  = cumVolsV(end) - cumVolsV;  %cumVolsV is the cumulative volume lt that corresponding scan
    %including that scan bin.
    
    if isfield(planC{indexS.scan}(scanSet).scanInfo(1),'CTOffset')
        offset = planC{indexS.scan}(scanSet).scanInfo(1).CTOffset;
    else
        offset = 0;
    end

    %No need to shift DVH by doseOffset since it is already included in doseBinsV.
    if strcmpi(cum_diff_string,'CUMU')
        h = plot([scanBinsV(1) - offset, scanBinsV - offset], [1, cumVols2V/cumVolsV(end)]);
        addDVHtoFig(hFig, struct, scanSet, h, [scanBinsV(1) - offset, scanBinsV - offset], [1, cumVols2V/cumVolsV(end)], 'IVH', 'NOABS', scanBinsV-offset, volsHistV, scanName);
    elseif strcmpi(cum_diff_string,'DIFF')
        indPlot = find(volsHistV);
        h = plot(scanBinsV(indPlot)-offset, volsHistV(indPlot)/cumVolsV(end));
        addDVHtoFig(hFig, struct, scanSet, h, scanBinsV(indPlot)-offset, volsHistV(indPlot)/cumVolsV(end), 'DVH', 'NOABS', scanBinsV(indPlot)-offset, volsHistV(indPlot), scanName);
    end

    set(hAxis,'nextplot','add')
    set(h,'linewidth',stateS.optS.IVHLineWidth)

    if structNum ~= 0
        %colorV = getColor(structNum, optS.colorOrder);
        colorV = planC{indexS.structures}(structNum).structureColor;
    else
        colorV = getColor(IVHNum, optS.colorOrder);
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
    opt = 'standardScan';
    name = planC{indexS.IVH}(IVHNum).structureName;
    nameVol = planC{indexS.IVH}(IVHNum).scanType;
    dispScanStats(scanBinsV, volsHistV, name, nameVol, planC, indexS, opt)

    binWidth = optS.IVHBinWidth;

    %Store computational results
    planC{indexS.IVH}(IVHNum).volumeType = 'ABSOLUTE';    
    planC{indexS.IVH}(IVHNum).scanUnits =  'ABSOLUTE';
    planC = saveIVHMatrix(IVHNum, scanBinsV, volsHistV, planC);

end

if absFlag == 1

    hRel = gcf;
    h = figure('tag', 'IVHPlot', 'doublebuffer', 'on');
    uimenu(h, 'label', 'Expand Options', 'callback',['plotIVHCallback(''EXPANDEDVIEW'')'],'interruptible','on');
    absAxis = axes('parent', h);
    set(h,'numbertitle','off')
    pos = get(h,'position');
    set(h,'position',[pos(1)*(1 - 0.05),pos(2)*(1 - 0.05),pos(3),pos(4)])
    if structNum ~= 0
        %colorV = getColor(structNum, optS.colorOrder);
        colorV = planC{indexS.structures}(structNum).structureColor;
    else
        colorV = getColor(IVHNum, optS.colorOrder);
    end    
    
    if strcmpi(cum_diff_string,'CUMU')
        p = plot([scanBinsV(1) - offset, scanBinsV - offset], [1, cumVols2V]);
        addDVHtoFig(hFig, struct, scanSet, h, [scanBinsV(1) - offset, scanBinsV - offset], [1, cumVols2V], 'IVH', 'NOABS', scanBinsV, volsHistV, scanName);
    elseif strcmpi(cum_diff_string,'DIFF')
        indPlot = find(volsHistV);
        p = plot(scanBinsV(indPlot)-offset, volsHistV(indPlot));
        addDVHtoFig(hFig, struct, scanSet, h, scanBinsV(indPlot)-offset, volsHistV(indPlot), 'DVH', 'NOABS', scanBinsV, volsHistV, scanName);
    end
    set(p,'color', colorV)
    %  IVHOptS(IVHNum).hAbsAxis = h;


    switch mod(flagLSS, 4)
        case 0
            set(p,'linestyle','--')
        case 1
            set(p,'linestyle','-')
        case 2
            set(p,'linestyle',':');
        case 3
            set(p,'linestyle','-.');
    end

    set(p,'linewidth',stateS.optS.IVHLineWidth)
    ylabel('Absolute volume (cc)')
    
    ud = get(findobj('Tag', 'IVHGui'),'userdata');
    scanNum = get(ud.af.handles.scan,'value');
    imageType = planC{indexS.scan}(scanNum).scanInfo(1).imageType;

    if strcmpi(imageType,'CT')
        units = 'HU';
    elseif strcmpi(imageType,'PET')
        units = 'SUV';
    else
        units = '';
    end
    
    if ~isempty(units)
        units = ['(' units ')'];
    end
    if gridFlag
        grid(absAxis, 'on');
    else
        grid(absAxis, 'off');
    end
    xlabel([imageType ' ' units])
    title(['Absolute volume IVH plot for:  ' struct])
    figure(hRel)
    hCERR = stateS.handle.CERRSliceViewer;
    title_str = get(hCERR,'name');
    set(h,'name',['Abs IVH plot: ' stateS.CERRFile])
    stateS.handle.IVHAbsPlots = findobj('tag','CERRAbsIVHPlot');
end