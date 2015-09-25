function conditionPlots(hFig)
%"conditionPlots"
%   Adjusts all plots in the figure to some standard.
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

if exist('hFig')
    hFigs = hFig;
else
    rootKids = get(0, 'children');
    hFigs = rootKids(strcmpi(get(rootKids, 'type'), 'figure'));
end

for j=1:length(hFigs)

    hFig = hFigs(j);
%     pos = get(hFig, 'position');
%     pos = [pos(1) pos(2) 280 336];
%     set(hFig, 'position', pos);
%     axis fill;
        
    kids = get(hFig, 'children');
    
    axes = kids(strcmpi(get(kids, 'type'), 'axes'));

	for i=1:length(axes)
        h = axes(i);
       
        set(h, 'FontSize', 14, 'FontWeight', 'Bold');       
%         set(get(h, 'children'), 'color', [0 0 0]);          
        set(get(h, 'title'), 'FontSize', 14, 'FontWeight', 'Bold');
        set(get(h, 'xlabel'), 'FontSize', 14, 'FontWeight', 'Bold');
        set(get(h, 'ylabel'), 'FontSize', 14, 'FontWeight', 'Bold');               
        hDraw = get(h, 'Children');       % Drawings 
        hLines = hDraw(strcmpi(get(hDraw, 'type'), 'line'));
        set(hLines, 'LineWidth', 2, 'MarkerSize', 9);
%         set(hLines, 'LineWidth', 2);
                
        legend = findobj(h, 'Tag', 'legend');
        legKids = get(legend, 'children');
        text = legKids(strcmpi(get(legKids, 'type'), 'text'));
        set(text, 'fontsize', 12, 'fontweight', 'Bold');                 
	end
    
end