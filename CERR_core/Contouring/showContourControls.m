function showContourControls(callFlag)
%Display contour related buttons and
%define callbacks.
%JOD.
%LM:  2 Dec 02, JOD.
%Latest modifications:  JOD, 9 Jan 03, added quit do not save.
%                       JOD, 15 Jan 03, added revert; changed tooltip on nudge.
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


global stateS planC

indexS = planC{end};

dy2 = 2.3;   %vertical increment between controls

numTools = 12;
vert = numTools * 1.7 * 0.2;

%set display position constants
x1 = 4;
y1 = vert * 7;
dx1 = 25;
dy1 = 1.8;

x2 = x1 + dx1 + 2;
x3 = x2 + dx1/3;
x4 = x3 + dx1/3;
x5 = x4 + dx1/3;
x6 = x5 + 5;
x7 = x6 + 25;

color2V = get(stateS.handle.CERRSliceViewer, 'Color');
colorV =  color2V + (1 - color2V) * 0.5;

if strcmp(callFlag,'update')

  hTools = findobj('tag','CERRContourTools');
  if isempty(hTools)
    hTools = figure('units','inches','position',[8, 1, 1.7, vert],'numbertitle','off','name','Contour','color', color2V,'menubar','none','tag','CERRContourTools');
    set(gca,'visible','off')
    stateS.handle.CERRContourTools = hTools;
  end

  units = 'characters';

  uicontrol(hTools,'units',units,'pos',[x1, y1 - dy2 * 1, dx1, dy1],'string','Make new segment', ...
          'callback',['contourControls(''startsegment'');'],'tooltipstring','Make new segment with the mouse');

  uicontrol(hTools,'units',units,'pos',[x1, y1 - dy2 * 2, dx1, dy1],'string','Pick segment', ...
          'callback',['contourControls(''selectsegment'');'],'tooltipstring','Pick active segment with mouse');

  uicontrol(hTools,'units',units,'pos',[x1, y1 - dy2 * 3, dx1, dy1],'string','Copy to higher', ...
          'callback',['contourControls(''copyup'');'],'tooltipstring','Copy segments to next higher number slice');

  uicontrol(hTools,'units',units,'pos',[x1, y1 - dy2 * 4, dx1, dy1],'string','Copy to lower', ...
          'callback',['contourControls(''copydown'');'],'tooltipstring','Copy segments to next lower number slice');

  stateS.handle.scaleContour = uicontrol(hTools,'units',units,'pos',[x1, y1 - dy2 * 5, dx1/2.5, dy1 * 0.8],'style','text','string','Scale', ...
          'callback',['contourControls(''scale'');'],'tooltipstring','Scale the active segment by the factor entered');

  stateS.handle.scaleContour = uicontrol(hTools,'units',units,'pos',[x1 + dx1/2.5 + 2, y1 - dy2 * 5, dx1/2.5, dy1 * 0.8],'style','edit','string','', ...
          'callback',['contourControls(''scale'');'],'tooltipstring','Scale the active segment by the factor entered',...
          'BackgroundColor',[1 1 1]);

  stateS.handle.modifyContour = uicontrol(hTools,'units',units,'pos',[x1, y1 - dy2 * 6, dx1, dy1],'string','Modify points', ...
          'Style','checkbox','value',0,'max',1,'min',0,'busyaction','cancel',...
          'callback',['contourControls(''modifysegment'');'],'tooltipstring','Modify the active segment points.  Hit return to quit.');

  stateS.handle.nudgeContour = uicontrol(hTools,'units',units,'pos',[x1, y1 - dy2 * 7, dx1, dy1],'string','Nudge segment',...
        'callback',['contourControls(''nudge'');'],'Style','checkbox','value',0,'max',1,'min',0,...
        'tooltipstring','Nudge segment using the arrow keys.  Hit return to quit.','busyaction','cancel');

  uicontrol(hTools,'units',units,'pos',[x1, y1 - dy2 * 8, dx1, dy1],'string','Snip out a section', ...
          'callback',['contourControls(''redosection'');'],'tooltipstring','Snip out and redo a section');

  uicontrol(hTools,'units',units,'pos',[x1, y1 - dy2 * 9, dx1, dy1],'string','Clear segment', ...
          'callback',['contourControls(''clearsegment'');'],'tooltipstring','Clear active segment');

  uicontrol(hTools,'units',units,'pos',[x1, y1 - dy2 * 10, dx1, dy1],'string','Revert', ...
          'callback',['contourControls(''revert'');'],'tooltipstring','Revert to original contours');

  uicontrol(hTools,'units',units,'pos',[x1, y1 - dy2 * 11, dx1, dy1],'string','Quit and save', ...
          'callback',['contourControls(''quit'');'],'tooltipstring','Quit contouring');

  uicontrol(hTools,'units',units,'pos',[x1, y1 - dy2 * 12, dx1, dy1],'string','Quit and revert', ...
          'callback',['contourControls(''quitNoSave'');'],'tooltipstring','Quit contouring and do not save the contours');

drawnow

end



