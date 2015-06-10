function doseStat = showDVH(hAxis, DVHNum, doseSet, gridSetting, flagLSS, absFlag, gridFlag, cum_diff_string)
%Draw a DVH in hAxis.
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
indexS = planC{end};
optS = stateS.optS;

hFig = get(hAxis, 'parent');

struct = planC{indexS.DVH}(DVHNum).structureName;

if isfield(planC{indexS.DVH},'fractionGroupID') && ~isempty(planC{indexS.DVH}(DVHNum).fractionGroupID)
    doseName  = planC{indexS.DVH}(DVHNum).fractionGroupID;
else
    doseName  = planC{indexS.DVH}(DVHNum).fractionIDOfOrigin;
end

structNum = getStructNum(struct,planC,indexS);

if ~isempty(planC{indexS.DVH}(DVHNum).DVHMatrix)

    [doseBinsV, volsHistV] = loadDVHMatrix(DVHNum, planC);
    DVHM = [doseBinsV, volsHistV];

    volumeType = planC{indexS.DVH}(DVHNum).volumeType;

    doseType   = planC{indexS.DVH}(DVHNum).doseType;

    switch lower(doseType)   %convert to Gy's

        case 'relative'   %untested code

            doseScale   = planC{indexS.DVH}(DVHNum).doseScale;
            doseBinsV = DVHM(:,1)' * doseScale / 100;

        case 'percent'    %untested code

            doseScale   = planC{indexS.DVH}(DVHNum).doseScale;
            doseBinsV = DVHM(:,1)' * doseScale / 100;

        case {'absolute', 'plunc','physical'}

            doseBinsV = DVHM(:,1)';

    end

    switch lower(volumeType)  %convert to cc's

        case 'relative'   %untested code

            volumeScale   = planC{indexS.DVH}(DVHNum).volumeScale;
            volsHistV = DVHM(:,2)' * volumeScale / 100;

        case 'percent'    %untested code

            volumeScale   = planC{indexS.DVH}(DVHNum).volumeScale;
            volsHistV = DVHM(:,2)' * volumeScale / 100;

        case {'absolute', 'differential', 'cumulative'}

            volsHistV = DVHM(:,2)';

    end

    cumVolsV = cumsum(volsHistV);

    cumVols2V  = cumVolsV(end) - cumVolsV;  %cumVolsV is the cumulative volume lt that corresponding dose
    %including that dose bin.

    %No need to shift DVH by doseOffset since it is already included in doseBinsV.
    if strcmpi(cum_diff_string,'CUMU')
        h = plot([0, doseBinsV], [1, cumVols2V/cumVolsV(end)]);
        addDVHtoFig(hFig, struct, doseSet, h, [0, doseBinsV], [1, cumVols2V/cumVolsV(end)], 'DVH', 'NOABS', doseBinsV, volsHistV, doseName);
    elseif strcmpi(cum_diff_string,'DIFF')
        indPlot = find(volsHistV);
        h = plot(doseBinsV(indPlot), volsHistV(indPlot)/cumVolsV(end));
        addDVHtoFig(hFig, struct, doseSet, h, doseBinsV(indPlot), volsHistV(indPlot)/cumVolsV(end), 'DVH', 'NOABS', doseBinsV, volsHistV, doseName);
    end

    set(hAxis,'nextplot','add')
    structNum = getStructNum(struct,planC,indexS);

    if structNum ~= 0
        %colorV = getColor(structNum, optS.colorOrder);
        colorV = planC{indexS.structures}(structNum).structureColor;
    else
        colorV = getColor(DVHNum, optS.colorOrder);
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

    set(h,'linewidth',stateS.optS.DVHLineWidth)
    drawnow

    opt = 'standardDose';
    name = planC{indexS.DVH}(DVHNum).structureName;

else   %compute yer own

    [dosesV, volsV, isError] = getDVH(structNum, doseSet, planC);

    if isError
        if stateS.webtrev.isOn
            warning('No raster segment present');
            doseStat = [];
        else
            errordlg('No raster segment present');
        end
                
        delete(findobj('tag','CERRAbsDVHPlot'));
        return
    end

    [doseBinsV, volsHistV] = doseHist(dosesV, volsV, optS.DVHBinWidth);

    cumVolsV = cumsum(volsHistV);

    cumVols2V  = cumVolsV(end) - cumVolsV;  %cumVolsV is the cumulative volume lt that corresponding dose
    %including that dose bin.
    %No need to shift DVH by doseOffset since getDVH already includes it.
    if strcmpi(cum_diff_string,'CUMU')
        h = plot([0, doseBinsV], [1, cumVols2V/cumVolsV(end)]);
        addDVHtoFig(hFig, struct, doseSet, h, [0, doseBinsV], [1, cumVols2V/cumVolsV(end)], 'DVH', 'NOABS', doseBinsV, volsHistV, doseName);
    elseif strcmpi(cum_diff_string,'DIFF')
        indPlot = find(volsHistV);
        h = plot(doseBinsV(indPlot), volsHistV(indPlot));
        addDVHtoFig(hFig, struct, doseSet, h, doseBinsV(indPlot), volsHistV(indPlot)/cumVolsV(end), 'DVH', 'NOABS', doseBinsV, volsHistV, doseName);
    end

    set(hAxis,'nextplot','add')
    set(h,'linewidth',stateS.optS.DVHLineWidth)

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
    opt = 'standardDose';
    name = planC{indexS.DVH}(DVHNum).structureName;        

    %Store computational results
    planC{indexS.DVH}(DVHNum).volumeType = 'ABSOLUTE';
    planC{indexS.DVH}(DVHNum).doseType   = 'ABSOLUTE';
    planC = saveDVHMatrix(DVHNum, doseBinsV, volsHistV, planC);
    planC{indexS.DVH}(DVHNum).doseSignature = calcDoseSignature(doseSet, planC);
    planC{indexS.DVH}(DVHNum).doseUnits = getDoseUnitsStr(doseSet,planC);

end

if absFlag == 1

    hRel = gcf;
    hAbsDVH = findobj('tag', 'CERRAbsDVHPlot');
    if isempty(hAbsDVH)
        h = figure('tag', 'CERRAbsDVHPlot', 'doublebuffer', 'on');
        uimenu(h, 'label', 'Expand Options', 'callback','plotDVHCallback(''EXPANDEDVIEW'')','interruptible','on');
        set(h,'numbertitle','off')
        pos = get(h,'position');
        set(h,'position',[pos(1)*(1 - 0.05),pos(2)*(1 - 0.05),pos(3),pos(4)])
        absAxis = axes('parent', h, 'tag', 'AbsDVHAxis', 'nextPlot','Add');
    else
        h = hAbsDVH;
        figure(h);
        absAxis = findobj(h,'tag', 'AbsDVHAxis');
    end    
    
    if strcmpi(cum_diff_string,'DIFF')
        indPlot = find(volsHistV);
        p = plot(doseBinsV(indPlot), volsHistV(indPlot));
        addDVHtoFig(h, struct, doseSet, p, doseBinsV(indPlot), volsHistV(indPlot), 'DVH', 'ABS', doseBinsV, volsHistV, doseName);
    elseif strcmpi(cum_diff_string,'CUMU')
        p = plot(doseBinsV, cumVols2V);
        addDVHtoFig(h, struct, doseSet, p, doseBinsV, cumVols2V, 'DVH', 'ABS', doseBinsV, volsHistV, doseName);
    end
    set(absAxis,'xgrid',gridSetting)
    set(absAxis,'ygrid',gridSetting)
    set(h,'tag','CERRAbsDVHPlot')
    %  DVHOptS(DVHNum).hAbsAxis = h;
    if structNum ~= 0
        %colorV = getColor(structNum, optS.colorOrder);
        colorV = planC{indexS.structures}(structNum).structureColor;
    else
        colorV = getColor(DVHNum, optS.colorOrder);
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

    set(p,'linewidth',stateS.optS.DVHLineWidth)
    ylabel('Absolute volume (cc)')
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
    
    if gridFlag
        grid(absAxis, 'on');
    else
        grid(absAxis, 'off');
    end
    xlabel(['Dose ' units])
    name = planC{indexS.DVH}(DVHNum).structureName;
    if ~isempty(planC{indexS.DVH}(DVHNum).fractionIDOfOrigin)
        name = [name, ' (', num2str(planC{indexS.DVH}(DVHNum).fractionIDOfOrigin), ')'];
    end
    name = regexprep(name,'_','-');    
    % title(['Absolute volume DVH plot for:  ' name])
    title(absAxis,'Absolute volume DVH')
    figure(hRel)

    set(h,'name',['Abs DVH plot: ' stateS.CERRFile])
    stateS.handle.DVHAbsPlots = findobj('tag','CERRAbsDVHPlot');
end

nameVol = planC{indexS.DVH}(DVHNum).fractionIDOfOrigin;
doseStat = dispDoseStats(doseBinsV, volsHistV, name, nameVol, planC, indexS, opt);
