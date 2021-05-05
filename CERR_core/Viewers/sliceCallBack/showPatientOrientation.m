function showPatientOrientation(varargin)
%Show locators planes in all CERR axes.
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
% APA, 4/23/2021


% global planeLocatorLastCall

% persistent num units addToView %ADDED
%
% thisCallTime = now;
%
% if isempty(planeLocatorLastCall)
%     planeLocatorLastCall = thisCallTime;
% else
%     if thisCallTime > planeLocatorLastCall
%         planeLocatorLastCall = thisCallTime;
%     end
% end


global stateS planC

set(stateS.handle.CERRAxisScreenLeftLabel,'visible','off')
set(stateS.handle.CERRAxisScreenRightLabel,'visible','off')
set(stateS.handle.CERRAxisScreenTopLabel,'visible','off')
set(stateS.handle.CERRAxisScreenBottomLabel,'visible','off')

if ~isfield(stateS,'showPatientOrientation') || ~stateS.showPatientOrientation
    %num = [];
    %units = [];
    %addToView = '';
    return;
end

%Get inputs for margins
if nargin>0
    [num,units,addToView] = varargin{:};
end


for i=uint8(1:length(stateS.handle.CERRAxis))
    %hAxis       = stateS.handle.CERRAxis(i);
    [axView, scanNumV, xRange, yRange] = ...
        getAxisInfo(i, 'view', 'scanSets', 'xRange', 'yRange');
    for iScan = 1:length(scanNumV)
        scanNum = scanNumV(iScan);
        axisLabelC = returnViewerAxisLabels(planC,scanNum);
        
        horizAlignLeft = 'left';
        horizAlignRight = 'right';
        
        switch lower(axView)
            case 'transverse'
                leftLabel = axisLabelC{2,1};
                rightLabel = axisLabelC{2,2};
                topLabel = axisLabelC{1,2};
                bottomLabel = axisLabelC{1,1};
            case 'sagittal'
                leftLabel = axisLabelC{1,2};
                rightLabel = axisLabelC{1,1};
                topLabel = axisLabelC{3,1};
                bottomLabel = axisLabelC{3,2};
                horizAlignLeft = 'right';
                horizAlignRight = 'left';
            case 'coronal'
                leftLabel = axisLabelC{2,1};
                rightLabel = axisLabelC{2,2};
                topLabel = axisLabelC{3,1};
                bottomLabel = axisLabelC{3,2};
            case 'legend'
                continue;
        end
        
        dx = xRange(2) - xRange(1);
        dy = yRange(2) - yRange(1);
        leftXPos = xRange(1) + dx*0.02;
        leftYPos = (yRange(1) + yRange(2))/2 + dy*0.02;
        
        rightXPos = xRange(2) - dx*0.02;
        rightYPos = (yRange(1) + yRange(2))/2 + dy*0.02;
        
        bottomXPos = (xRange(1) + xRange(2))/2 + dx*0.02;
        bottomYPos = yRange(2) - dy*0.02;
        
        topXPos = (xRange(1) + xRange(2))/2 + dx*0.02;
        topYPos = yRange(1) + dy*0.02;
        
        set(stateS.handle.CERRAxisScreenLeftLabel(i),'Position',[leftXPos,leftYPos],...
            'String',leftLabel, 'visible','on','horizontalAlignment',horizAlignLeft);
        set(stateS.handle.CERRAxisScreenRightLabel(i),'Position',[rightXPos,rightYPos],...
            'String',rightLabel, 'visible','on','horizontalAlignment',horizAlignRight);
        set(stateS.handle.CERRAxisScreenTopLabel(i),'Position',[topXPos,topYPos],...
            'String',topLabel, 'visible','on','verticalAlignment','top');
        set(stateS.handle.CERRAxisScreenBottomLabel(i),'Position',[bottomXPos,bottomYPos],...
            'String',bottomLabel, 'visible','on','verticalAlignment','bottom');
        
    end
end


%sliceCallBack('focus', stateS.handle.CERRAxis(stateS.currentAxis));