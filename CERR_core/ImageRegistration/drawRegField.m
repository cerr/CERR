%draw registration field
function drawRegField(command)
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

switch lower(command)
    case 'init'
        
        setappdata(stateS.handle.CERRSliceViewer, 'isClip', 'off');
        
        w = 600; h = 600;
        screenSize = get(0,'ScreenSize');

        hFieldFig = figure('name', 'Drawing Registration Field(click and drag)', 'units', 'pixels', 'color', [0 0 0], ...
                                'position',[(screenSize(3)-w)/2 (screenSize(4)-h)/2 w h], ...
                                'MenuBar', 'none', 'NumberTitle', 'off', 'resize', 'off', ...
                                'Tag', 'FieldFig', 'DoubleBuffer', 'on', ...
                                'buttondownfcn', 'drawRegField(''axisclicked'')', ...
                                'DeleteFcn', 'drawRegField(''cancel'')');

        ViewerAxis = axes('userdata', [], 'parent', hFieldFig, 'units', 'pixels', 'Tag', 'FieldAxes', ...
                                    'position', [0 0 w h], 'color', [1 0 0], 'box', 'on', ...
                                    'xTickLabel', [], 'yTickLabel', [], 'xTick', [], 'yTick', [], ...
                                    'buttondownfcn', '', ...
                                    'nextplot', 'add', 'linewidth', 3);

        continueButton = uicontrol(hFieldFig, 'style', 'pushbutton', 'units', 'pixel', 'position',...
                            [w-100 60 100 30],'string', 'Continue', 'callback',...
                            'drawRegField(''continue'')','tag', 'continueButton');

        cancelButton = uicontrol(hFieldFig, 'style', 'pushbutton', 'units', 'pixel', 'position',...
                            [w-100 20 100 30],'string', 'Cancel', 'callback',...
                            'drawRegField(''cancel'')','tag', 'cancelButton');

        vols =  planC{indexS.scan}(stateS.imageRegistrationBaseDataset).scanArray;
        im = max(vols, [], 3);
        hIm = imshow(im, 'DisplayRange',[min(im(:)) max(im(:))]);
        set(hIm, 'Hittest', 'off');
        
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
        hAxis = gca;
        hFig = get(hAxis, 'parent');
        
        clicktype = get(hFig, 'selectiontype');

        switch clicktype
            
            case 'normal'
                set(hFig, 'WindowButtonMotionFcn', 'drawRegField(''clipMotion'')', ... 
                    'WindowButtonUpFcn', 'drawRegField(''clipMotionDone'')');
                drawRegField('clipStart');
                
                return;
            case {'alt' 'extend'}
                ud = get(gca, 'userdata');
                delete(findobj('tag', 'clipBox'));
                delete(findobj('tag', 'clipBoxT1'));
                delete(findobj('tag', 'clipBoxT2'));
                
                return;
        end
    
    case 'clipstart'
        hAxis = gca;
        cP = get(hAxis, 'CurrentPoint');
        delete(findobj('tag', 'clipBox'));
        delete(findobj('tag', 'clipBoxT1'));
        delete(findobj('tag', 'clipBoxT2'));
        axesToDraw = hAxis;

       
       line([cP(1,1) cP(1,1),cP(1,1) cP(1,1) cP(1,1)], [cP(2,2) cP(2,2) cP(2,2) cP(2,2) cP(2,2)], ...
                    'tag', 'clipBox', 'userdata', [], 'eraseMode', 'xor', ...
                    'parent', axesToDraw, 'marker', 's', 'markerFaceColor', 'r', 'linestyle', '-', 'color', [.8 .8 .1], 'hittest', 'off');
    
    case 'clipmotion'
        hAxis = gca;
        allLines = findobj(gcbo, 'tag', 'clipBox');
        delete(findobj('tag', 'clipBoxT2'));
        if isempty(allLines)
            return;
        end
        
        p0 = allLines(1);
        cP = get(hAxis, 'CurrentPoint');
        xD = get(p0, 'XData');
        yD = get(p0, 'YData');

        set(allLines, 'XData', [xD(1), xD(1),   cP(1,1), cP(1,1), xD(1)]);
        set(allLines, 'YData', [yD(1), cP(2,2), cP(2,2), yD(1),   yD(1)]);
                
        t1 = text(xD(1)+2, yD(1)-6, [num2str(ceil(xD(1))), ',' num2str(ceil(yD(1)))], 'tag', 'clipBoxT1', 'color', 'yellow', 'edgeColor', 'red');
        t2 = text(cP(1,1)+2, cP(2,2)-6, [num2str(ceil(cP(1,1))), ',' num2str(ceil(cP(2,2)))], 'tag', 'clipBoxT2', 'color', 'yellow', 'edgeColor', 'red');
        
        return;        
       
    case 'clipmotiondone'
        hFig = gcbo;
        set(hFig, 'WindowButtonMotionFcn', '', 'WindowButtonUpFcn', '');
        allLines = findobj(gcbo, 'tag', 'clipBox');
        if ~isempty(allLines)
            xdata = get(allLines, 'XData');
            ydata = get(allLines, 'YData');
            
            xMin = min(xdata);
            xMax = max(xdata);
            yMin = min(ydata);
            yMax = max(ydata);
            
            if mod(xMax-xMin+1, 2)>0, xMin = xMin + 1; end;
            if mod(yMax-yMin+1, 2)>0, yMin = yMin + 1; end;
            
            setappdata(stateS.handle.CERRSliceViewer, 'clipBox', [xMin xMax; yMin yMax]);
        else
            setappdata(stateS.handle.CERRSliceViewer, 'clipBox', []);
        end
        
        return;    
        
end 



