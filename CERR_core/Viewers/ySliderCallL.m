function ySliderCallL()
%
%APA, 04/12/2010
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
hs = stateS.legendSlider;
%hs = gcbo;
ud = get(hs,'userdata');
if isempty(ud)
    return;
end
ha = ud{1};
posYall = ud{2};
%posOldY = axis(ha);
posOldY = [get(ha,'xLim'), get(ha,'yLim')];
val = get(hs,'value');
% posYallO = posYall;
% posYallO(1) = posYall(1) -(posOldY(4)-posOldY(3));
valT = posYall(2) - val + posYall(1);
if valT<=posYall(1)
    posNewY = [posYall(1)-(posOldY(4)-posOldY(3)) posYall(1)];
elseif valT>=posYall(2)
    posNewY = [posYall(2)-(posOldY(4)-posOldY(3)) posYall(2)];
else
    posNewY = [posYall(2)-val posYall(2)-val+posYall(1)];
end

% posNewXY = posOldY;
% posNewXY(3:4) = posNewY;
% axis(ha,posNewXY)
%ha.YLim = posNewY;
set(ha,'YLim',posNewY);

% %%% Make lines/text outside axis not visible
% Iall = posYallO(1)+1:posYallO(2)-1;
% InotVisivle1 = find(Iall<posNewY(1));
% InotVisivle2 = find(Iall>posNewY(2));
% InotVisivle = [InotVisivle1 InotVisivle2];
% set(stateS.handle.legend.text(InotVisivle),'string','');
% set(stateS.handle.legend.lines(InotVisivle),'visible','off');



