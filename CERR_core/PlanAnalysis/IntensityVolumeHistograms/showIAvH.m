function showIAvH(IVHNum, scanSet,  volFlag)
% showDIvH
%Draws Average IVH plot for the selected structures. The average is
%calculated for each scan bin for the given normalized volume.IVHNum is an
%array containint the structure number for which average IVH is to be
%calculated. scanSet is an array of corresponding scan set that belon to
%the structure number in IVHNum.
%
% Created DK 03/27/06
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
%
% Usage
% showDIvH(IVHNum, scanSet, gridSetting)
global planC
global stateS
indexS = planC{end};
optS = stateS.optS;


if ~volFlag
    delete(findobj('tag', 'IVHPlot'));
end

count = 0;
struct_str = [];
for i = 1: length(IVHNum)
    count = count + 1;
    struct = planC{indexS.IVH}(IVHNum(i)).structureName;
    struct_str = [struct_str ' :: ' struct];
    if ~isempty(planC{indexS.IVH}(IVHNum(i)).IVHMatrix)
        [scanBinsV, volsHistV] = loadIVHMatrix(IVHNum(i), planC);
        IVHM_temp = [scanBinsV, volsHistV];

        volumeType = planC{indexS.IVH}(IVHNum(i)).volumeType;

        scanType   = planC{indexS.IVH}(IVHNum(i)).scanType;

        switch lower(scanType)   %convert to Gy's

            case 'relative'   %untested code

                scanScale   = planC{indexS.IVH}(IVHNum(i)).scanScale;
                scanBinsV = IVHM_temp(:,1)' * scanScale / 100;

            case 'percent'    %untested code

                scanScale   = planC{indexS.IVH}(IVHNum(i)).scanScale;
                scanBinsV = IVHM_temp(:,1)' * scanScale / 100;

            case 'absolute'

                scanBinsV = IVHM_temp(:,1)';

        end

        switch lower(volumeType)  %convert to cc's

            case 'relative'   %untested code

                volumeScale   = planC{indexS.IVH}(IVHNum(i)).volumeScale;
                volsHistV = IVHM_temp(:,2)' * volumeScale / 100;

            case 'percent'    %untested code

                volumeScale   = planC{indexS.IVH}(IVHNum(i)).volumeScale;
                volsHistV = IVHM_temp(:,2)' * volumeScale / 100;

            case 'absolute'

                volsHistV = IVHM_temp(:,2)';

        end
    else %Compute your own IVH for the given structure
        structNum = getStructNum(struct,planC,indexS);
        [scansV, volsV] = getIVH(structNum, scanSet(i), planC);

        [scanBinsV, volsHistV] = scanHist(scansV, volsV, optS.IVHBinWidth);

        %Store computational results
        planC{indexS.IVH}(IVHNum(i)).volumeType = 'ABSOLUTE';
        planC{indexS.IVH}(IVHNum(i)).scanType   = 'ABSOLUTE';
        planC = saveIVHMatrix(IVHNum(i), scanBinsV, volsHistV, planC);

    end
    IVH_data = [scanBinsV; volsHistV];
    IVHM{count} =   IVH_data;
    binLen(count)= length(scanBinsV);
    binWid(count)= diff(scanBinsV(1:2));
    clear IVH_data
end


if any(find(diff(binWid)))
    CERRStatusString('interpolating bin width');
    warndlg('Not yet implemented! Work in progress');
else
    if any(diff(binLen))
        [len,I]= max(binLen);
        CERRStatusString('scan bins of different length!! interpolating.....');
        IVH_data = IVHM{I};
        scanBinsV_M = IVH_data(1,:);
        volsHistV_M = IVH_data(2,:);
        for i = 1:length(scanBinsV_M)
            totVol = 0;
            IVH_count = 0;
            for j = 1:size(IVHM,2)
                IVH_count = IVH_count + 1;
                if j ==I
                    totVol = totVol + volsHistV_M(i);
                else
                    IVH_data = IVHM{j};
                    scanBinsV = IVH_data(1,:);
                    volsHistV = IVH_data(2,:);
                    vol = interp1(scanBinsV,volsHistV,scanBinsV_M(i));
                    if isnan(vol)
                        vol = 0;
                        IVH_count = IVH_count - 1;
                    end
                    totVol = totVol + vol;
                end
            end
            avgVol(i)= totVol/IVH_count;
        end
    else
        CERRStatusString('No interpolation required! all IVH of equal length');
        warndlg('not yet implemented');
    end
end

cumVolsV = cumsum(avgVol);
cumVols2V  = cumVolsV(end) - cumVolsV;
VolHist = cumVols2V/cumVolsV(end);

h = figure('tag', 'DAvHPlot', 'doublebuffer', 'on');
avgAxis = axes('parent', h);
set(h,'numbertitle','off')
pos = get(h,'position');
set(h,'position',[pos(1)*(1 - 0.05),pos(2)*(1 - 0.05),pos(3),pos(4)])
p = plot([0,scanBinsV_M],[1,VolHist]);

set(p,'linestyle','-')

set(p,'linewidth',stateS.optS.IVHLineWidth)
ylabel('% volume (cc)')

units = 'HU';

if ~isempty(units)
    units = ['(' units ')'];
end

grid(avgAxis, 'on');

xlabel(['Scan ' units])
title(['Average scan IVH plot for:  ' struct_str ])

set(h,'name',['Average IVH plot: ' stateS.CERRFile])
stateS.handle.DAvHPlots = findobj('tag','DAvHPlot');
