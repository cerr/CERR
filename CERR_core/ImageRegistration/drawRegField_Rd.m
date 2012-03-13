%draw registration field
function drawRegField_Rd(command)
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

global planC stateS;
indexS = planC{end};

% dimF = size(planC{indexS.scan}(stateS.imageRegistrationBaseDataset).scanArray);
% dimM = size(planC{indexS.scan}(stateS.imageRegistrationMovDataset).scanArray);

switch lower(command)
    case 'init'
        
        setappdata(stateS.handle.CERRSliceViewer, 'isClip', 'off');
        setappdata(stateS.handle.CERRSliceViewer, 'clipBox_baseTrans', []);
        setappdata(stateS.handle.CERRSliceViewer, 'clipBox_baseSag', []);
        setappdata(stateS.handle.CERRSliceViewer, 'clipBox_movTrans', []);
        setappdata(stateS.handle.CERRSliceViewer, 'clipBox_movSag', []);
        
        w = 600; h = 600;
        screenSize = get(0,'ScreenSize');

        hFieldFig = figure('name', 'Drawing Registration Field(click and drag)', 'units', 'pixels', 'color', [0.75 0.75 0.78], ...
                                'position',[(screenSize(3)-w)/2 (screenSize(4)-h)/2 w h], ...
                                'MenuBar', 'none', 'NumberTitle', 'off', 'resize', 'off', ...
                                'Tag', 'FieldFig', 'DoubleBuffer', 'on', ...
                                'buttondownfcn', 'drawRegField_Rd(''axisclicked'')', ...
                                'DeleteFcn', 'drawRegField_Rd(''cancel'')');

        %base dataset view
        vols =  planC{indexS.scan}(stateS.imageRegistrationBaseDataset).scanArray;
        baseTransAxis = axes('userdata', [], 'parent', hFieldFig, 'units', 'pixels', 'Tag', 'baseTransAxes', ...
                                    'position', [30 h/2 w/2 h/2], 'color', [1 0 0], 'box', 'on', 'ydir', 'normal', ...
                                    'xTickLabel', [], 'yTickLabel', [], 'xTick', [], 'yTick', [], ...
                                    'buttondownfcn', 'drawRegField_Rd(''axisclicked'')', ...
                                    'nextplot', 'add', 'linewidth', 3);
        
        ylabel('base Transverse', 'fontsize',12, 'fontweight','b')
        %im = max(vols, [], 3);
        im = squeeze(mean(vols, 3));
        hIm = imshow(im, 'DisplayRange',[min(im(:)) max(im(:))]);
        daspect([planC{indexS.scan}(stateS.imageRegistrationBaseDataset).scanInfo(1).grid1Units, ...
                 planC{indexS.scan}(stateS.imageRegistrationBaseDataset).scanInfo(1).grid2Units, 1]);
        set(hIm, 'Hittest', 'off');
                
        baseSagAxis = axes('userdata', [], 'parent', hFieldFig, 'units', 'pixels', 'Tag', 'baseSagAxes', ...
                                    'position', [w/2+30 h/2 w/2-30 h/2], 'color', [1 0 0], 'box', 'on', 'ydir', 'normal', ...
                                    'xTickLabel', [], 'yTickLabel', [], 'xTick', [], 'yTick', [], ...
                                    'buttondownfcn', '', ...
                                    'nextplot', 'add', 'linewidth', 3);
        ylabel('base Sagittal', 'fontsize',12, 'fontweight','b')
        im = squeeze(mean(vols, 2));
        hIm = imshow(im', 'DisplayRange',[min(im(:)) max(im(:))]);
        daspect([planC{indexS.scan}(stateS.imageRegistrationBaseDataset).scanInfo(1).sliceThickness, ...
                 planC{indexS.scan}(stateS.imageRegistrationBaseDataset).scanInfo(1).grid1Units, 1]);
        set(hIm, 'Hittest', 'off');
        
        %moving dataset view
        vols =  planC{indexS.scan}(stateS.imageRegistrationMovDataset).scanArray;
        movTransAxis = axes('userdata', [], 'parent', hFieldFig, 'units', 'pixels', 'Tag', 'movTransAxes', ...
                                    'position', [30 0 w/2 h/2], 'color', [1 0 0], 'box', 'on', 'ydir', 'normal', ...
                                    'xTickLabel', [], 'yTickLabel', [], 'xTick', [], 'yTick', [], ...
                                    'buttondownfcn', '', ...
                                    'nextplot', 'add', 'linewidth', 3);
        
        ylabel('Moving Transverse', 'fontsize',12, 'fontweight','b')
        %im = max(vols, [], 3);
        im = mean(vols, 3);
        %im = median(vols, 3);
        hIm = imshow(im, 'DisplayRange',[min(im(:)) max(im(:))]);
        daspect([planC{indexS.scan}(stateS.imageRegistrationMovDataset).scanInfo(1).grid1Units, ...
                 planC{indexS.scan}(stateS.imageRegistrationMovDataset).scanInfo(1).grid2Units, 1]);
        set(hIm, 'Hittest', 'off');
        
        
        movSagAxis = axes('userdata', [], 'parent', hFieldFig, 'units', 'pixels', 'Tag', 'movSagAxes', ...
                                    'position', [w/2+30 0 w/2-30 h/2], 'color', [1 0 0], 'box', 'on', 'ydir', 'normal', ...
                                    'xTickLabel', [], 'yTickLabel', [], 'xTick', [], 'yTick', [], ...
                                    'buttondownfcn', '', ...
                                    'nextplot', 'add', 'linewidth', 3);
        ylabel('Moving Sagittal', 'fontsize',12, 'fontweight','b')
        im = squeeze(mean(vols, 2));
        hIm = imshow(im', 'DisplayRange',[min(im(:)) max(im(:))]);
        daspect([planC{indexS.scan}(stateS.imageRegistrationMovDataset).scanInfo(1).sliceThickness, ...
                 planC{indexS.scan}(stateS.imageRegistrationMovDataset).scanInfo(1).grid1Units, 1]);
        set(hIm, 'Hittest', 'off');

        continueButton = uicontrol(hFieldFig, 'style', 'pushbutton', 'units', 'pixel', 'position',...
                            [w-220 10 100 30],'string', 'Continue', 'callback',...
                            'drawRegField_Rd(''continue'')','tag', 'continueButton');

        cancelButton = uicontrol(hFieldFig, 'style', 'pushbutton', 'units', 'pixel', 'position',...
                            [w-120 10 100 30],'string', 'Cancel', 'callback',...
                            'drawRegField_Rd(''cancel'')','tag', 'cancelButton');

        helpText = uicontrol(hFieldFig, 'style', 'text', 'units', 'pixel', 'position',[w-580 5 300 32], ...
                             'ForegroundColor', [1 0 0], 'backgroundcolor', [0.75 0.75 0.78], 'fontsize', 10, ...
                             'string', 'click and drag on base for (X,Y) definition and mov for z definition.');
        
        setappdata(stateS.handle.CERRSliceViewer, 'isClip', 'off');
        setappdata(stateS.handle.CERRSliceViewer, 'clipBox', []);
        
        uiwait;

    case 'continue'
       setappdata(stateS.handle.CERRSliceViewer, 'isClip', 'on');
       uiresume;
       
            
    case 'cancel'
       setappdata(stateS.handle.CERRSliceViewer, 'isClip', 'off');
       uiresume;
       
       
    case 'axisclicked'
        hFig = gcf;
        
        clicktype = get(hFig, 'selectiontype');
        curPos = get(hFig, 'currentpoint');
        if (curPos(1)>=0)&&(curPos(1)<300)&&(curPos(2)>=0)&&(curPos(2)<300)
            axes(findobj('tag', 'movTransAxes'));
        end
        if (curPos(1)>=0)&&(curPos(1)<300)&&(curPos(2)>=300)&&(curPos(2)<=600)
            axes(findobj('tag', 'baseTransAxes'));
        end
        if (curPos(1)>=300)&&(curPos(1)<=600)&&(curPos(2)>=300)&&(curPos(2)<=600)
            axes(findobj('tag', 'baseSagAxes'));
        end
        if (curPos(1)>=300)&&(curPos(1)<=600)&&(curPos(2)>=0)&&(curPos(2)<=300)
            axes(findobj('tag', 'movSagAxes'));
        end
        

        switch clicktype
            
            case 'normal'
                set(hFig, 'WindowButtonMotionFcn', 'drawRegField_Rd(''clipMotion'')', ... 
                    'WindowButtonUpFcn', 'drawRegField_Rd(''clipMotionDone'')');
                drawRegField_Rd('clipStart');
                
                return;
            case {'alt' 'extend'}
                ud = get(gca, 'userdata');
                delete(findobj('tag', 'clipBox','parent', gca));
                delete(findobj('tag', 'clipBoxT1', 'parent', gca));
                delete(findobj('tag', 'clipBoxT2', 'parent', gca));
                
                return;
        end
    
    case 'clipstart'
        hAxis = gca;
        cP = get(hAxis, 'CurrentPoint');
        delete(findobj('tag', 'clipBox', 'parent', gca));
        delete(findobj('tag', 'clipBoxT1', 'parent', gca));
        delete(findobj('tag', 'clipBoxT2', 'parent', gca));
        axesToDraw = hAxis;

        
        img = get(findobj('parent', gca, 'type', 'image'), 'cdata');
        dim = size(img);
        if (cP(1,1)>0)&&(cP(1,1)<dim(2))&&(cP(2,2)>0)&&(cP(2,2)<dim(1))
            line([cP(1,1) cP(1,1),cP(1,1) cP(1,1) cP(1,1)], [cP(2,2) cP(2,2) cP(2,2) cP(2,2) cP(2,2)], ...
                    'tag', 'clipBox', 'userdata', [], 'eraseMode', 'xor', ...
                    'parent', axesToDraw, 'marker', 's', 'markerFaceColor', 'r', 'linestyle', '-', 'color', [.8 .8 .1], ...
                    'hittest', 'off');
        end
    case 'clipmotion'
        hAxis = gca;
        allLines = findobj(gca, 'tag', 'clipBox');
        delete(findobj('tag', 'clipBoxT2', 'parent', gca));
        if isempty(allLines)
            return;
        end
        
        p0 = allLines(1);
        cP = get(hAxis, 'CurrentPoint');
        xD = get(p0, 'XData');
        yD = get(p0, 'YData');
        
        img = get(findobj('parent', gca, 'type', 'image'), 'cdata');
        dim = size(img);
        if (cP(1,1)>0)&&(cP(1,1)<dim(2))&&(cP(2,2)>0)&&(cP(2,2)<dim(1))
            set(allLines, 'XData', [xD(1), xD(1),   cP(1,1), cP(1,1), xD(1)]);
            set(allLines, 'YData', [yD(1), cP(2,2), cP(2,2), yD(1),   yD(1)]);
        end
        
        t1 = text(xD(1)+2, yD(1)-6, [num2str(ceil(xD(1))), ',' num2str(ceil(yD(1)))], 'parent', gca, 'tag', 'clipBoxT1', 'color', 'yellow', 'edgeColor', 'red');
        t2 = text(cP(1,1)+2, cP(2,2)-6, [num2str(ceil(cP(1,1))), ',' num2str(ceil(cP(2,2)))], 'parent', gca, 'tag', 'clipBoxT2', 'color', 'yellow', 'edgeColor', 'red');
        
        return;        
       
    case 'clipmotiondone'
        hFig = gcbo;
        set(hFig, 'WindowButtonMotionFcn', '', 'WindowButtonUpFcn', '');
        allLines = findobj(gca, 'tag', 'clipBox');
        view = get(gca, 'tag');
        if ~isempty(allLines)
            xdata = get(allLines, 'XData');
            ydata = get(allLines, 'YData');
            
            xMin = min(xdata);
            xMax = max(xdata);
            yMin = min(ydata);
            yMax = max(ydata);
            
            if mod(xMax-xMin+1, 2)>0, xMin = xMin + 1; end;
            if mod(yMax-yMin+1, 2)>0, yMin = yMin + 1; end;
            
            
            if strcmpi(view, 'baseTransAxes');
                setappdata(stateS.handle.CERRSliceViewer, 'clipBox_baseTrans', [xMin xMax; yMin yMax]);
            end
            if strcmpi(view, 'baseSagAxes');
                setappdata(stateS.handle.CERRSliceViewer, 'clipBox_baseSag', [xMin xMax; yMin yMax]);
            end
            if strcmpi(view, 'movTransAxes');
                setappdata(stateS.handle.CERRSliceViewer, 'clipBox_movTrans', [xMin xMax; yMin yMax]);
            end
            if strcmpi(view, 'movSagAxes');
                setappdata(stateS.handle.CERRSliceViewer, 'clipBox_movSag', [xMin xMax; yMin yMax]);
            end
        else
            if strcmpi(view, 'baseTransAxes');
                setappdata(stateS.handle.CERRSliceViewer, 'clipBox_baseTrans', []);
            end
            if strcmpi(view, 'baseSagAxes');
                setappdata(stateS.handle.CERRSliceViewer, 'clipBox_baseSag', []);
            end
            if strcmpi(view, 'movTransAxes');
                setappdata(stateS.handle.CERRSliceViewer, 'clipBox_movTrans', []);
            end
            if strcmpi(view, 'movSagAxes');
                setappdata(stateS.handle.CERRSliceViewer, 'clipBox_movSag', []);
            end
        end
        
        return;    
        
end 



