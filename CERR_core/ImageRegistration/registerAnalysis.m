function registerAnalysis(command)
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
hViewer = stateS.handle.CERRSliceViewer;

% prepare analysis figure
units = 'pixels';
screenSize = get(0,'ScreenSize');
w = 700; h = 400;
hFig = figure('name', 'Registration Composition Views', 'units', units, 'Color', 'k',...
                            'position',[(screenSize(3)-w)/2 (screenSize(4)-h)/2 w h], ...
                            'MenuBar', 'none', 'NumberTitle', 'off', 'resize', 'off', ...
                            'Tag', 'compositionView', 'DoubleBuffer', 'off', ...
                            'DeleteFcn', 'CERRRegistrationRigidSetup(''close'', [])');

traAxes = axes('Parent',hFig, 'Color',[0.25 0.25 0.25],'units', 'normalized', 'position', [0.04 0.01 0.3 1], 'Tag','traAxes');
sagAxes = axes('Parent',hFig, 'Color',[0.25 0.25 0.25],'units', 'normalized', 'position', [0.35 0.01 0.3 1], 'Tag','sagAxes');
corAxes = axes('Parent',hFig, 'Color',[0.25 0.25 0.25],'units', 'normalized', 'position', [0.66 0.01 0.3 1], 'Tag','corAxes');
title = uicontrol('Parent',hFig, 'style', 'text', 'units', 'normalized', 'position', [0 0.9  1 .1], ...
                    'FontSize', 16, 'backgroundColor', [.7 .7 .7],'HorizontalAlignment', 'center', 'string', '');

axList = [traAxes sagAxes corAxes];

for aIndex=1:length(stateS.handle.CERRAxis)-1
    
    hAxis = stateS.handle.CERRAxis(aIndex);
    axisInfo = get(hAxis, 'userdata');

    fImg = axisInfo.scanObj(stateS.imageRegistrationBaseDataset).data2M;
    mImg = axisInfo.scanObj(stateS.imageRegistrationMovDataset).data2M;

    axes(axList(aIndex));
    ratio = [1 1 1];
    switch command

        case 'difference'
            I1 = cast(fImg, 'int16');
            I2 = cast(mImg, 'int16');
            
            im = imsubtract(I1, I2);
            imagesc(im,[min(im(:)) max(im(:))]);
            colormap(gray);
            set(title, 'string', 'difference between base and moving');
            
        case 'checker_board'    
            
            im = RegdoCheckboard(fImg, mImg, 3, 3);
            imagesc(im, [0 1]);
            set(title, 'string', 'checkerboard between base and moving');
            
    end
    daspect(ratio);
    set(gca, 'XTick', [], 'YTick', []);
    
end
    
color = [.7 .3 .7];
set(get(traAxes,'XLabel'),'String','Transverse','color', color, ...
    'FontName','times','FontAngle','italic', 'FontWeight', 'bold', 'FontSize',12);
set(get(sagAxes,'XLabel'),'String','Sagittal','color', color, ...
    'FontName','times','FontAngle','italic', 'FontWeight', 'bold', 'FontSize',12);  
set(get(corAxes,'XLabel'),'String','Coronal','color', color, ...
    'FontName','times','FontAngle','italic', 'FontWeight', 'bold', 'FontSize',12);    