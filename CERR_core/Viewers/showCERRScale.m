function showCERRScale(figHandle,handleName,pixelWidth,init,initZoom,scaleFactor)
%Show a small 5 cm scale on the lower-left of the image (initially).
%After any zoom commands show the same length text but now with a new length.
%This scale function assumes that the pixels are square.
%JOD, 18 Nov 02.
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

relScaleFactor = scaleFactor/initZoom;

if strcmpi(init,'no') | strcmpi(init,'refresh')
  hV = getfield(stateS.handle,handleName);
  for i = 1 : length(hV)
    try
      delete(hV(i))
    end
  end
  stateS.handle = setfield(stateS.handle,handleName,[]);
end

p = pixelWidth * relScaleFactor;

rulerColor = stateS.optS.rulerColor;

xlimV = get(gca,'xlim');
ylimV = get(gca,'ylim');

x0 = xlimV(1) + (xlimV(2) - xlimV(1)) * 0.03;
y0 = ylimV(1) + (ylimV(2) - ylimV(1)) * 0.08;

h2 = line([x0, x0 + 5/p],[y0, y0]);
h3 = line([x0, x0],[y0 - 0.5/p, y0 + 0.5/p]);
h4 = line([x0 + 5/p, x0 + 5/p],[y0 - 0.5/p, y0 + 0.5/p]);
tmp = num2str(5/(p/pixelWidth));
if length(tmp) > 4
  tmp = tmp(1:4);
end
str = [tmp ' cm'];

tmp = num2str(scaleFactor);
if length(tmp) > 3
  tmp = tmp(1:3);
end

str2 = [str ' (' tmp ':1)'];

h5 = text(x0+0.3/p,y0+1/p,str2,'fontsize',8);

hV = [h2,h3,h4,h5];

set(hV,'color',rulerColor);

stateS.handle = setfield(stateS.handle,handleName,hV);

