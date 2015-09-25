function getCERRLegend(callFlag)
%function getCERRLegend(callFlag)
%Create and update the CERRLegend which displays legend for isodose and structure lines.
%LM: 10 Nov 02, JOD.
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

dy2 = 1.2;   %vertical increment between structure labels

vert = (length(planC{indexS.structures}) + length(stateS.optS.isodoseLevels)) * 0.2;

x1 = 8;
y1 = vert * 7; %38;
dx1 = 25;
dy1 = 1;

x2 = x1 + dx1 + 2;
x3 = x2 + dx1/3;
x4 = x3 + dx1/3;
x5 = x4 + dx1/3;
x6 = x5 + 5;
x7 = x6 + 25;

color2V = get(stateS.handle.CERRSliceViewer, 'Color');
colorV =  color2V + (1 - color2V) * 0.5;

if strcmp(callFlag,'update')

  hLegend = findobj('tag','CERRLegend');
  if isempty(hLegend)
    hLegend = figure('units','inches','position',[5, 1, 2, vert],'numbertitle','off','name','CERR legend','color', color2V,'menubar','none','tag','CERRLegend');
    set(gca,'visible','off')
    stateS.handle.CERRLegend = hLegend;
  end


for i = 1 : length(planC{indexS.structures})
    str = planC{indexS.structures}(i).structureName;
    if ~strcmp(str,'')
      colorV = stateS.optS.colorOrder(i,:);
      color2V = setCERRLabelColor(i);

      %List structures
      uicontrol(hLegend,'style','text','units','characters', ...
      'position',[x1 - 6, y1 - dy2 * i, 4, dy1],'string',[num2str(i) '.  ']);

      uicontrol(hLegend,'style','text','units','characters', 'backgroundcolor', colorV, 'foregroundcolor', color2V, ...
      'position',[x1, y1 - dy2 * i, dx1, dy1],'string',str);
    end
end


y0 = dy2 * length(planC{indexS.structures}) ;

j = 1;
for i = length(stateS.optS.isodoseLevels) : -1 : 1

    colorV = stateS.optS.colorOrder(j,:);

    isodoseLevels = stateS.optS.isodoseLevels;
    type = stateS.optS.isodoseLevelType;

    if strcmpi(stateS.optS.isodoseLevelType,'percent')
      n = 5;
      level = isodoseLevels(j) * stateS.doseArrayMaxValue / 100;
      str = num2str(level);
      if length(str) >= n
        str = str(1:n);
        str = [str ' Gy, (' num2str(isodoseLevels(j)) '%)'];
      else
        str = [str ' Gy, (' num2str(isodoseLevels(j)) '%)'];
      end
    else
      str = isodoseLevels(j);
      str = [str ' Gy'];
    end

    color2V = setCERRLabelColor(j);

    %List structures

    uicontrol(hLegend,'style','text','units','characters', 'backgroundcolor', colorV, 'foregroundcolor', color2V, ...
    'position',[x1, y1 - (dy2 * i) - y0, dx1, dy1],'string',str);

    j = j + 1;

end

set(gca,'visible','off')

end



