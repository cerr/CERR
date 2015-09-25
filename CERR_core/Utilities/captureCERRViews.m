function [F,thumb] = captureCERRViews(origFname,thumbFname)
%function captureCERRViews
%
%Writes CERR views to png files. 
%
%Input:
%origFname is the filename for original-sized image without extension
%thumbFname is the filename for thumb-sized image without extension
%
%Output:
%F is the capture for original image.
%thumb is the capture for thumbnail.
%
%Example:
%[F,thumb] = captureCERRViews('orig','thumb');
%
%DK, 05/20/2008
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


global stateS
hFig = stateS.handle.CERRSliceViewer;
hLMargin = findobj(hFig,'Tag', 'leftMargin');
lMarginPos = get(hLMargin,'position');
figPos = get(hFig,'position');

%Original resolution
% sliceCallBack('focus',stateS.handle.CERRAxis(4))

F = getframe(hFig,[lMarginPos(3) 65 figPos(3)-lMarginPos(3) figPos(4)-65]);

%Thumbnail
hAxis = stateS.handle.CERRAxis(1);
hPl = findobj(hAxis,'Tag','planeLocator');
hPl = [hPl findobj(hAxis,'Tag','planeLocatorShadow')];
delete(hPl)
set(stateS.handle.CERRAxisLabel1(1),'String','')
set(stateS.handle.CERRAxisLabel2(1),'String','')
Faxis = getframe(hAxis);
thumbnailWidth = 300;
[y,x,color] = size(Faxis.cdata);
resizeFactor = thumbnailWidth/x;
thumb = Faxis;
thumb.cdata = imresize(Faxis.cdata,resizeFactor,'nearest');

%Plot
%figure, image(F.cdata)

imwrite(F.cdata, [origFname '.png'], 'png');
imwrite(thumb.cdata, [thumbFname '.png'], 'png');

CERRRefresh
