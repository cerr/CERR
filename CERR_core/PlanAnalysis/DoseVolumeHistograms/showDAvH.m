function showDAvH(DVHNum, doseSet,  volFlag, stdFlag)
% showDAvH
%Draws Average DVH plot for the selected structures. The average is
%calculated for each dose bin for the given normalized volume.DVHNum is an
%array containint the structure number for which average DVH is to be
%calculated. doseSet is an array of corresponding dose set that belon to
%the structure number in DVHNum.
%
% Created DK 03/27/06
%
% Usage
% showDAvH(DVHNum, doseSet, gridSetting)
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

if ~volFlag
    delete(findobj('tag', 'DVHPlot'));
end

count = 0;
struct_str = [];
for i = 1: length(DVHNum)
    count = count + 1;
    struct = planC{indexS.DVH}(DVHNum(i)).structureName;
    struct_str = [struct_str ' :: ' struct];
    if ~isempty(planC{indexS.DVH}(DVHNum(i)).DVHMatrix)
        [doseBinsV, volsHistV] = loadDVHMatrix(DVHNum(i), planC);
        DVHM_temp = [doseBinsV, volsHistV];

        volumeType = planC{indexS.DVH}(DVHNum(i)).volumeType;

        doseType   = planC{indexS.DVH}(DVHNum(i)).doseType;

        switch lower(doseType)   %convert to Gy's

            case 'relative'   %untested code

                doseScale   = planC{indexS.DVH}(DVHNum(i)).doseScale;
                doseBinsV = DVHM_temp(:,1)' * doseScale / 100;

            case 'percent'    %untested code

                doseScale   = planC{indexS.DVH}(DVHNum(i)).doseScale;
                doseBinsV = DVHM_temp(:,1)' * doseScale / 100;

            case 'absolute'

                doseBinsV = DVHM_temp(:,1)';

        end

        switch lower(volumeType)  %convert to cc's

            case 'relative'   %untested code

                volumeScale   = planC{indexS.DVH}(DVHNum(i)).volumeScale;
                volsHistV = DVHM_temp(:,2)' * volumeScale / 100;

            case 'percent'    %untested code

                volumeScale   = planC{indexS.DVH}(DVHNum(i)).volumeScale;
                volsHistV = DVHM_temp(:,2)' * volumeScale / 100;

            case 'absolute'

                volsHistV = DVHM_temp(:,2)';

        end
    else %Compute your own DVH for the given structure
        if isempty(doseSet(i))| doseSet(i)== 0
            errordlg('there is no associated dose. Exiting ...');
            return;
        end

        structNum = getStructNum(struct,planC,indexS);

        [dosesV, volsV] = getDVH(structNum, doseSet(i), planC);

        [doseBinsV, volsHistV] = doseHist(dosesV, volsV, optS.DVHBinWidth);

        %Store computational results
        planC{indexS.DVH}(DVHNum(i)).volumeType = 'ABSOLUTE';

        planC{indexS.DVH}(DVHNum(i)).doseType   = 'ABSOLUTE';

        planC = saveDVHMatrix(DVHNum(i), doseBinsV, volsHistV, planC);

        planC{indexS.DVH}(DVHNum(i)).doseSignature = calcDoseSignature(doseSet(i), planC);
    end

    DVH_data = [doseBinsV; volsHistV];

    DVHM{count} =   DVH_data;

    binLen(count)= length(doseBinsV);

    if length(doseBinsV)==1
        binWid(count)= doseBinsV;
    else
        binWid(count)= diff(doseBinsV(1:2));
    end

    clear DVH_data
end


if any(find(diff(binWid)))
    CERRStatusString('interpolating bin width');
    warndlg('Average DVH for different Structure Set Not yet implemented !!',...
        'Work in progress');
    return
else
    if any(diff(binLen))

        CERRStatusString('dose bins of different length!! interpolating.....');

        [len,I]= max(binLen);

        DVH_data = DVHM{I};

        xi = DVH_data(1,:);

        totVol = DVH_data(2,:);

        numDVH = size(DVHM,2);

        allVolNorm = normailzeDVHVol(DVH_data(2,:));

        for i = 1:numDVH

            if i ~= I
                DVH_data = DVHM{i};

                x = DVH_data(1,:);

                y = DVH_data(2,:);

                vol = interp1(x,y,xi);

                vol(isnan(vol))=0;

                totVol = totVol + vol;

                volNorm = normailzeDVHVol(vol);
                
                allVolNorm = [allVolNorm ; volNorm];
            end
        end
        avgVol = totVol / numDVH;
    else

        CERRStatusString('No interpolation required! all DVH of equal length');

        divFactor = length(binLen);

        for i = 1:divFactor

            DVH_data = DVHM{i};

            volsHistV = DVH_data(2,:);

            if i == 1
                avgVol = volsHistV;
            else
                avgVol = avgVol + volsHistV;
            end
        end
        avgVol = avgVol/divFactor;                    
    end
end

[VolHist cumVols2V]  = normailzeDVHVol(avgVol);

h = figure('tag', 'DAvHPlot', 'doublebuffer', 'on');

avgAxis = axes('parent', h);

set(h,'numbertitle','off')

pos = get(h,'position');

set(h,'position',[pos(1)*(1 - 0.05),pos(2)*(1 - 0.05),pos(3),pos(4)])

plot([0,xi],[1,VolHist],'linestyle','-','linewidth',stateS.optS.DVHLineWidth);

if stdFlag
    hold on
    
    CERRStatusString('Ploting Average DVH with Standard Deviation');
    
    stdVol = calculate_std_avgDVH(allVolNorm);
    
    avgPlusSTD= VolHist + stdVol;
    
    avgMinusSTD = VolHist - stdVol;
    
    plot([0 xi],[1 avgPlusSTD],'--r',[0 xi],[1 avgMinusSTD],'--r');
    
end
ylabel('% volume (cc)')

units = getDoseUnitsStr(stateS.doseSet,planC);

if ~isempty(units)
    units = ['(' units ')'];
end

grid(avgAxis, 'on');

xlabel(['Dose ' units])
title(['Average dose DVH plot for:  ' struct_str ])

set(h,'name',['Average DVH plot: ' stateS.CERRFile])

stateS.handle.DAvHPlots = findobj('tag','DAvHPlot');


function stdDVH = calculate_std_avgDVH(allVol)

stdDVH = std(allVol,1,1);


function [VolHist cumVols2V] = normailzeDVHVol(avgVol)

cumVolsV = cumsum(avgVol);

cumVols2V  = cumVolsV(end) - cumVolsV;

VolHist = cumVols2V/cumVolsV(end);