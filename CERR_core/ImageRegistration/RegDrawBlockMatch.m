function RegDrawBlockMatch(CurAxes, im, Nx, Ny, Offset, color1, color2, scaleX, scaleY)
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
    
% global planC
% global stateS
% 
% % if stateS.optS.useOpenGL
% axisInfo = get(CurAxes, 'userdata');
% surfaces = [axisInfo.scanObj.handles];
% try
%     hFrame = stateS.handle.controlFrame;
%     ud = get(hFrame,'userdata');
%     DataIndex = get(ud.handles.baseSet,'value');
%     [xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(DataIndex));
%     
%     xLims = [min(xV) max(xV)];
%     yLims = [min(yV) max(yV)];
%     zLims = [min(zV) max(zV)];
% end

delete(findobj('tag', 'blockmatchLine', 'parent', CurAxes));
   
    xV = get(im, 'xdata');
    yV = get(im, 'ydata');
    zV = get(im, 'zdata');
    
    xLims = [min(xV(:)) max(xV(:))];
    yLims = [min(yV(:)) max(yV(:))];
    zLims = [min(zV(:)) max(zV(:))];
    
    sliceXVals = linspace(min(xV(:)), max(xV(:)), Nx+1);
    sliceYVals = linspace(min(yV(:)), max(yV(:)), Ny+1);
    sliceZVals = linspace(min(zV(:)), max(zV(:)), 1);
    
    [X, Y, Z] = meshgrid(sliceXVals, sliceYVals, sliceZVals);

    line(X, Y, Z, 'parent', CurAxes, 'tag', 'blockmatchLine', 'color', [.1 0.36 .1], 'linewidth', 1);
    line(X', Y', Z, 'parent', CurAxes, 'tag', 'blockmatchLine', 'color', [.1 0.36 .1], 'linewidth', 1);

    for j = 1 : Ny
        for i = 1 : Nx
            x = sliceXVals(i)/2 + sliceXVals(i+1)/2; %subOrigin{j+1, i+1}(1);
            y = sliceYVals(j)/2 + sliceYVals(j+1)/2;
            
            os = Offset{Ny-j+1, i};
            
            t = 0:pi/80:2*pi;
            xx = x + 0.5*cos(t);
            yy = y + 0.5*sin(t);
%             line( xx, yy, zV(1)*ones(1, size(xx,2)), 'marker', '.', 'markerfacecolor', 'b', 'parent', CurAxes, ...
%                     'tag', 'blockmatchLine', 'LineWidth', 1, 'Color', color1);
            fill3( xx, yy, zV(1)*ones(1, size(xx,2)), color1, 'parent', CurAxes, 'tag', 'blockmatchLine');
            
            x1 = x + os(1)/10; %mm to cm;  %x1 = x + os(1)/(scaleX*10);
            y1 = y + os(2)/10; %mm to cm %y1 = y + os(2)/(scaleY*10);
            line( [x x1], [y y1], zV(1:2), 'linestyle', '-', 'parent', CurAxes, 'tag', 'blockmatchLine', ...
                    'LineWidth', 1.5, 'Color', color2);

            
        end
    end
        

end
