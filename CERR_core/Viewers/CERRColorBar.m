function varargout = CERRColorBar(command, varargin)
%"CERRColorBar"
%   Creation of, and callbacks to the CERR colorbar.
%
%JRA 8/6/04
%
%Usage:
%   CERRColorBar('init', hAxis);
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

% DK
if ~isempty(varargin) && ~ischar(varargin{1}) && ishandle(varargin{1})
    hAxis = varargin{1};
else
    hAxis = gca;
end
if stateS.layout == 7 && (strcmpi(get(hAxis,'tag'),'doseCompareAxes') | strcmpi(get(hAxis,'tag'),'ColorbarCompare'))% doseCompare Mode
    colorbarFrameMax =  double(stateS.colorbarFrameMaxCompare);
    doseArrayMaxValue = double(stateS.doseArrayMaxValueCompare);
    doseDisplayRange = double(stateS.doseDisplayRangeCompare);
    colorbarRange = double(stateS.colorbarRangeCompare);
    colorbarFrameMin = double(stateS.colorbarFrameMinCompare);
    colorbarImageH = double(stateS.handle.colorbarImageCompare);
    tag = 'compare';
else
    colorbarFrameMax =  double(stateS.colorbarFrameMax);
    doseArrayMaxValue = double(stateS.doseArrayMaxValue);
    doseDisplayRange = double(stateS.doseDisplayRange);
    colorbarRange = double(stateS.colorbarRange);
    colorbarFrameMin = double(stateS.colorbarFrameMin);
    colorbarImageH = double(stateS.handle.colorbarImage);
    tag = 'normal';
end

switch upper(command)
    case 'INIT'
        %Initialize display ranges.
        hAxis = varargin{1};
        CERRColorBar('REFRESH', hAxis);

    case 'REFRESH'
        offset = 0;
        try
            if(~isempty(planC{indexS.dose}(stateS.doseSet).doseOffset))
                offset = double(planC{indexS.dose}(stateS.doseSet).doseOffset);
            end
        end

        %Set bounds for the colorbar frame
        if isempty(stateS.optS.colorbarMax)
            colorbarFrameMax = max([offset, doseArrayMaxValue - offset, doseDisplayRange(2), colorbarRange(2)]);
        else
            colorbarFrameMax = stateS.optS.colorbarMax;
        end
        if isempty(stateS.optS.colorbarMin)
            if offset > 0
                colorbarFrameMin = min([-offset, -(doseArrayMaxValue - offset), doseDisplayRange(1), colorbarRange(1)]);
            else
                colorbarFrameMin = min([0, doseDisplayRange(1), colorbarRange(1)]);
            end
        else
            colorbarFrameMin = stateS.optS.colorbarMin;
        end

        if colorbarFrameMax == colorbarFrameMin
            colorbarFrameMax = colorbarFrameMin + 1;
        end

        %Ratio of bar height to arrow height;
        ud.ratio = 50;
        ratio = ud.ratio;

        %Clear children of axis passed, prep axis.
        hAxis = varargin{1};
        delete(get(hAxis, 'children'));
        set(hAxis, 'nextplot', 'add', 'visible', 'on', 'hittest', 'off')
        axis(hAxis, 'manual', 'off');

        %Setup Figure in case it is not initialized.
        hFig  = get(hAxis, 'parent');
        set(hFig, 'doublebuffer', 'on');

        ud.dY = double(colorbarFrameMax) - double(colorbarFrameMin);
        ud.dX = 2;

        set(hAxis, 'xLim', [-.5 2.5]);
        set(hAxis, 'yLim', [double(colorbarFrameMin)-ud.dY/(ratio/2) double(colorbarFrameMax)+ud.dY/(ratio/2)]);

        %Create colorbar image.
        cM      = CERRColorMap(stateS.optS.doseColormap);
        if stateS.optS.doubleSidedColorbar
            cM = [flipud(cM);cM];
        end
        nColors = size(cM,1);
        tmpV    = nColors:-1:1;
        cB      = ind2rgb(tmpV', cM);
        upLim   = double(colorbarRange(2));
        lowLim  = double(colorbarRange(1));

        if(colorbarFrameMax>100)
            textNumBot = lowLim/100;
            textNumTop = upLim/100;
            text(0,lowLim-4*ud.dY/(ratio),'x10^2','parent',hAxis,'hittest','off')
        else
            textNumBot = lowLim;
            textNumTop = upLim;
        end
        
        %calculate increment counter
        str             = num2str(abs(colorbarFrameMax));
        indZero         = strfind(str,'0');
        indDot          = strfind(str,'.');
        indToNeglect    = [indZero indDot];
        indAll          = 1:length(str);
        indSignif       = indAll;
        indSignif(indToNeglect) = [];        
        str(min(indSignif))     = '1';
        indNotSignif    = indAll;
        indNotSignif([min(indSignif) indDot]) = [];
        str(indNotSignif) = '0';
        deltaTick = str2double(str);
        
        %Draw ticks
        tickV = [0:-deltaTick:colorbarFrameMin deltaTick:deltaTick:colorbarFrameMax];
        for i = 1:length(tickV)
            plot([1 1.5],[tickV(i) tickV(i)],'color',[0.5 0.5 0.5],'linewidth',0.5,'parent',hAxis)
        end

        %Draw actual image, with margin so image doesnt leak outside frame.
        margin = (upLim-lowLim)/nColors/2;
        colorbarImageH = imagesc([.5 .5], [upLim-margin lowLim+margin], cB, 'parent', hAxis, 'hittest', 'on', 'buttondownfcn', 'CERRColorBar(''ColorbarAxisClicked'')','Tag',tag);
        %Create arrows and associated text for colorRange.
%         ud.handle.colorrangebot = patch([.5 0 1], [lowLim lowLim-ud.dY/ratio lowLim-ud.dY/ratio], 'w', 'edgecolor', 'k', 'buttondownfcn', 'CERRColorBar(''RANGERCLICKED'', ''CRB'')', 'userdata', hAxis, 'parent', hAxis, 'erasemode', 'xor');
%         ud.handle.colorrangebottxt = text(1, lowLim - ud.dY/ratio, sprintf('%.3g',textNumBot), 'verticalAlignment', 'top', 'horizontalAlignment', 'right', 'buttondownfcn', 'CERRColorBar(''RANGERCLICKED'', ''CRB'')', 'fontsize', 8, 'erasemode', 'xor', 'parent', hAxis, 'userdata', hAxis);
%         ud.handle.colorrangetop = patch([.5 0 1], [upLim upLim+ud.dY/ratio upLim+ud.dY/ratio], 'w', 'edgecolor', 'k', 'buttondownfcn', 'CERRColorBar(''RANGERCLICKED'', ''CRT'')', 'userdata', hAxis, 'parent', hAxis, 'erasemode', 'xor');
%         ud.handle.colorrangetoptxt = text(1, upLim + ud.dY/ratio, sprintf('%.3g',textNumTop), 'verticalAlignment', 'bottom', 'horizontalAlignment', 'right', 'buttondownfcn', 'CERRColorBar(''RANGERCLICKED'', ''CRT'')', 'fontsize', 8, 'erasemode', 'xor', 'parent', hAxis, 'userdata', hAxis);
        ud.handle.colorrangebot = patch([.5 0 1], [lowLim lowLim-ud.dY/ratio lowLim-ud.dY/ratio], 'w', 'edgecolor', 'k', 'buttondownfcn', 'CERRColorBar(''RANGERCLICKED'', ''CRB'')', 'userdata', hAxis, 'parent', hAxis);
        ud.handle.colorrangebottxt = text(1, lowLim - ud.dY/ratio, sprintf('%.3g',textNumBot), 'verticalAlignment', 'top', 'horizontalAlignment', 'right', 'buttondownfcn', 'CERRColorBar(''RANGERCLICKED'', ''CRB'')', 'fontsize', 8, 'parent', hAxis, 'userdata', hAxis);
        ud.handle.colorrangetop = patch([.5 0 1], [upLim upLim+ud.dY/ratio upLim+ud.dY/ratio], 'w', 'edgecolor', 'k', 'buttondownfcn', 'CERRColorBar(''RANGERCLICKED'', ''CRT'')', 'userdata', hAxis, 'parent', hAxis);
        ud.handle.colorrangetoptxt = text(1, upLim + ud.dY/ratio, sprintf('%.3g',textNumTop), 'verticalAlignment', 'bottom', 'horizontalAlignment', 'right', 'buttondownfcn', 'CERRColorBar(''RANGERCLICKED'', ''CRT'')', 'fontsize', 8, 'parent', hAxis, 'userdata', hAxis);

        %Create arrows and associated text for doseRange.
        upLim = double(doseDisplayRange(2));
        lowLim = double(doseDisplayRange(1));
        if(colorbarFrameMax>100)
            textNumBot = lowLim/100;
            textNumTop = upLim/100;
        else
            textNumBot = lowLim;
            textNumTop = upLim;
        end
        %ud.handle.doserangebot = patch([1 2 2], [lowLim lowLim lowLim-ud.dY/ratio], 'w', 'edgecolor', 'k', 'buttondownfcn', 'CERRColorBar(''RANGERCLICKED'', ''DRB'')', 'userdata', hAxis, 'parent', hAxis, 'erasemode', 'xor');
        ud.handle.doserangebot = patch([1 2 2], [lowLim lowLim lowLim-ud.dY/ratio], 'w', 'edgecolor', 'k', 'buttondownfcn', 'CERRColorBar(''RANGERCLICKED'', ''DRB'')', 'userdata', hAxis, 'parent', hAxis);
        %ud.handle.doserangebottxt = text(1.2, lowLim - ud.dY/ratio, sprintf('%.3g',textNumBot), 'verticalAlignment', 'top',  'buttondownfcn', 'CERRColorBar(''RANGERCLICKED'', ''DRB'')','horizontalAlignment', 'left', 'fontsize', 8, 'parent', hAxis, 'erasemode', 'xor', 'userdata', hAxis,'color',[0.3 0.3 1]);
        ud.handle.doserangebottxt = text(1.2, lowLim - ud.dY/ratio, sprintf('%.3g',textNumBot), 'verticalAlignment', 'top',  'buttondownfcn', 'CERRColorBar(''RANGERCLICKED'', ''DRB'')','horizontalAlignment', 'left', 'fontsize', 8, 'parent', hAxis, 'userdata', hAxis,'color',[0.3 0.3 1]);
        %ud.handle.doserangetop = patch([1 2 2], [upLim upLim upLim+ud.dY/ratio], 'w', 'edgecolor', 'k', 'buttondownfcn', 'CERRColorBar(''RANGERCLICKED'', ''DRT'')', 'userdata', hAxis, 'parent', hAxis, 'erasemode', 'xor');
        ud.handle.doserangetop = patch([1 2 2], [upLim upLim upLim+ud.dY/ratio], 'w', 'edgecolor', 'k', 'buttondownfcn', 'CERRColorBar(''RANGERCLICKED'', ''DRT'')', 'userdata', hAxis, 'parent', hAxis);
        %ud.handle.doserangetoptxt = text(1.2, upLim + ud.dY/ratio, sprintf('%.3g',textNumTop), 'verticalAlignment', 'bottom', 'horizontalAlignment', 'left',  'buttondownfcn', 'CERRColorBar(''RANGERCLICKED'', ''DRT'')', 'fontsize', 8, 'parent', hAxis, 'erasemode', 'xor', 'userdata', hAxis,'color',[0.3 0.3 1]);
        ud.handle.doserangetoptxt = text(1.2, upLim + ud.dY/ratio, sprintf('%.3g',textNumTop), 'verticalAlignment', 'bottom', 'horizontalAlignment', 'left',  'buttondownfcn', 'CERRColorBar(''RANGERCLICKED'', ''DRT'')', 'fontsize', 8, 'parent', hAxis, 'userdata', hAxis,'color',[0.3 0.3 1]);

        %Draw border around colorbar.
        cFMax = colorbarFrameMax;
        cFMin = colorbarFrameMin;
        line([0 0 1 1 0], [cFMin cFMax cFMax cFMin cFMin], 'color', 'k', 'hittest', 'off', 'parent', hAxis);
        set(hAxis, 'userdata', ud);
        updateColorBarStateS(hAxis,colorbarFrameMax,doseArrayMaxValue,doseDisplayRange,colorbarRange,colorbarFrameMin,colorbarImageH);
        CERRColorBar('REFRESHCOLORBARIMAGE', hAxis);

    case 'COLORBARAXISCLICKED'
        hAxis = get(gcbo, 'parent');
        hFig = get(hAxis, 'parent');
        sT = get(hFig, 'selectionType');

        if strcmpi(sT, 'open')
            tag = get(hAxis,'Tag');
            controlFrame(lower(tag), 'init');
        end

    case 'RANGERCLICKED'
        hAxis = get(gcbo, 'userdata');
        hFig  = get(hAxis, 'parent');
        ud    = get(hAxis, 'userdata');

        %Suspend figure while motion is going on, restore later.
        ud.UISTATE = uisuspend(hFig);

        %Determine which triangle is clicked.
        switch upper(varargin{1})
            case 'CRB'
                ud.handle.movingObject = ud.handle.colorrangebot;
                colorRangeMax = get(ud.handle.colorrangetop, 'yData');
                ud.associatedText = ud.handle.colorrangebottxt;
                ud.associatedTextOffset = -ud.dY/ud.ratio;
                ud.motionbounds = [colorbarFrameMin colorRangeMax(1)];
            case 'CRT'
                ud.handle.movingObject = ud.handle.colorrangetop;
                colorRangeMin = get(ud.handle.colorrangebot, 'yData');
                ud.associatedText = ud.handle.colorrangetoptxt;
                ud.associatedTextOffset = ud.dY/ud.ratio;
                ud.motionbounds = [colorRangeMin(1) colorbarFrameMax];
            case 'DRB'
                ud.handle.movingObject = ud.handle.doserangebot;
                doseRangeMin = get(ud.handle.doserangetop, 'yData');
                ud.associatedText = ud.handle.doserangebottxt;
                ud.associatedTextOffset = -ud.dY/ud.ratio;
                ud.motionbounds = [colorbarFrameMin doseRangeMin(1)];
            case 'DRT'
                ud.handle.movingObject = ud.handle.doserangetop;
                doseRangeMax = get(ud.handle.doserangebot, 'yData');
                ud.associatedText = ud.handle.doserangetoptxt;
                ud.associatedTextOffset = ud.dY/ud.ratio;
                ud.motionbounds = [doseRangeMax(1) colorbarFrameMax];
        end
        %Prepare object/figure for motion.
        %set(ud.handle.movingObject, 'erasemode', 'xor');
        %set(ud.associatedText, 'erasemode', 'xor');
        set(hFig, 'windowbuttonmotionfcn', 'CERRColorBar(''IndicatorMoving'')')
        set(hFig, 'windowbuttonupfcn', 'CERRColorBar(''MotionDone'');')
        set(hAxis, 'userdata', ud);

    case 'INDICATORMOVING'
        hAxis = get(gco, 'userdata');
        hFig  = get(hAxis, 'parent');
        ud    = get(hAxis, 'userdata');
        hObj  = ud.handle.movingObject;
        yData = get(hObj, 'yData');
        cp = get(hAxis, 'currentpoint');
        mB = ud.motionbounds;
        if cp(2,2) > ud.motionbounds(2)
            cp(2,2) = ud.motionbounds(2);
        elseif cp(2,2) < ud.motionbounds(1)
            cp(2,2) = ud.motionbounds(1);
        end
        delta = cp(2,2) - yData(1);
        %Move both the object and text string to new position.
        set(hObj, 'yData', yData+delta);
        textPos = get(ud.associatedText, 'position');
        textPos(2) = yData(1)+delta+ud.associatedTextOffset;

        if(colorbarFrameMax>100)
            txtDisp = yData(1)/100;
        else
            txtDisp = yData(1);
        end
        set(ud.associatedText, 'position', textPos, 'string', sprintf('%.3g',txtDisp));

    case 'MOTIONDONE'
        hAxis = get(gco, 'userdata');
        ud = get(hAxis, 'userdata');

        %Restore the figure to pre-motion state.
        uirestore(ud.UISTATE);

        %Match position of arrow with rounded text value.
        hObj  = ud.handle.movingObject;
        yData = get(hObj, 'yData');
        cP    = str2num(get(ud.associatedText, 'string'));
        % delta = cP - yData(1);
        %APA
        if(colorbarFrameMax>100)
            txtDispVal = cP*100;
        else
            txtDispVal = cP;
        end
        delta = txtDispVal - yData(1);
        % APA

        set(hObj, 'yData', yData+delta);
        textPos = get(ud.associatedText, 'position');
        textPos(2) = cP+ud.associatedTextOffset;
        set(ud.associatedText, 'position', textPos);

        %set(ud.handle.movingObject, 'erasemode', 'xor');
        %set(ud.associatedText, 'erasemode', 'xor');

        doseRangeMax = get(ud.handle.doserangetop, 'yData');
        doseRangeMin = get(ud.handle.doserangebot, 'yData');
        colorRangeMax = get(ud.handle.colorrangetop, 'yData');
        colorRangeMin = get(ud.handle.colorrangebot, 'yData');
        doseDisplayRange    = [doseRangeMin(1) doseRangeMax(1)];
        colorbarRange       = [colorRangeMin(1) colorRangeMax(1)];

        stateS.doseDisplayChanged = 1;
        updateColorBarStateS(hAxis,colorbarFrameMax,doseArrayMaxValue,doseDisplayRange,colorbarRange,colorbarFrameMin,colorbarImageH);
        CERRColorBar('refresh', hAxis);
        controlFrame('colorbar', 'refresh');
        CERRRefresh


    case 'REFRESHCOLORBARIMAGE'
        hAxis = varargin{1};
        ud = get(hAxis, 'userdata');

        if ~isequal(doseDisplayRange(2), doseDisplayRange(1))
            set(colorbarImageH, 'yData', doseDisplayRange, 'visible', 'on')
        else
            set(colorbarImageH, 'yData', doseDisplayRange, 'visible', 'off')
            return;
        end

        cM = CERRColorMap(stateS.optS.doseColormap);
        if stateS.optS.doubleSidedColorbar
            cM = [flipud(cM);cM];
        end

        lowVal = cM(1,:);
        hiVal = cM(end,:);

        if ~isequal(colorbarRange(2), colorbarRange(1))

            percentBelow = (colorbarRange(1) - colorbarFrameMin) / (colorbarRange(2) - colorbarRange(1));
            percentAbove = (colorbarFrameMax - colorbarRange(2)) / (colorbarRange(2) - colorbarRange(1));

            nElements = size(cM, 1);

            cM = [repmat(lowVal, [round(percentBelow*nElements),1]);cM;repmat(hiVal, [round(percentAbove*nElements),1])];

            percentAboveCut = (colorbarFrameMax - doseDisplayRange(2)) / (colorbarFrameMax - colorbarFrameMin);
            percentBelowCut = (doseDisplayRange(1) - colorbarFrameMin) / (colorbarFrameMax - colorbarFrameMin);
            nElements = size(cM, 1);

            toClipAbove = round(percentAboveCut*nElements);
            toClipBelow = round(percentBelowCut*nElements);
            if toClipAbove ~= 0
                cM(nElements - toClipAbove:end,:) = [];
            end
            if toClipBelow ~= 0
                cM(1:toClipBelow,:) = [];
            end

            nColors = size(cM,1);
            tmpV    = nColors:-1:1;
            cB      = ind2rgb(tmpV', cM);

            margin = (doseDisplayRange(2)-doseDisplayRange(1))/nColors/2;

            range = [doseDisplayRange(1) + margin doseDisplayRange(2) - margin];

            set(colorbarImageH, 'cData', cB, 'yData', fliplr(range), 'visible', 'on', 'hittest', 'on')
        else
            set(colorbarImageH, 'visible', 'off')
        end
        updateColorBarStateS(hAxis,colorbarFrameMax,doseArrayMaxValue,doseDisplayRange,colorbarRange,colorbarFrameMin,colorbarImageH);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Added Function to update stateS fields for Color bar%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function updateColorBarStateS(hAxis,colorbarFrameMax,doseArrayMaxValue,doseDisplayRange,colorbarRange,colorbarFrameMin,colorbarImageH)
% DK
global stateS
if stateS.layout == 7 && (strcmpi(get(hAxis,'tag'),'doseCompareAxes') ||...
        strcmpi(get(hAxis,'tag'),'colorBarCompare'))% doseCompare Mode
    stateS.colorbarFrameMaxCompare = colorbarFrameMax;
    stateS.doseArrayMaxValueCompare = doseArrayMaxValue;
    stateS.doseDisplayRangeCompare = doseDisplayRange;
    stateS.colorbarRangeCompare = colorbarRange;
    stateS.colorbarFrameMinCompare = colorbarFrameMin;
    stateS.handle.colorbarImageCompare = colorbarImageH;
else
    stateS.colorbarFrameMax = colorbarFrameMax;
    stateS.doseArrayMaxValue = doseArrayMaxValue;
    stateS.doseDisplayRange  = doseDisplayRange;
    stateS.colorbarRange = colorbarRange;
    stateS.colorbarFrameMin = colorbarFrameMin;
    stateS.handle.colorbarImage = colorbarImageH;
end

