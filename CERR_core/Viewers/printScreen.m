% Print CERR screen
%
% Shunde 7/14/05

% 24 Apr 2006 KU  Changed to 'print' (with no UI controls) instead of printpreview because of bug(?) in
%                 Matlab 7.2.  Printpreview hangs up if figure is in fullscreen mode.  Maybe try
%                 printpreview again in future version??
% 27 Dec 2006 KU  Switched back to zbuffer for CERR 3.0.
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


% set(gcf,'renderer','painters');
% set(gcf,'PaperPositionMode','auto');
% orient landscape;
% printpreview;


set(gcf,'renderer','zbuffer');
set(gcf,'PaperPositionMode','auto');
orient landscape;

sentence1 = {'To adjust the size of the printed figure, adjust the screensize of the ',...
                'CERR window rather than changing the printer options.  (The CERR window ',...
                'will fill a standard 8.5x11 paper if it is adjusted to be fullscreen ',...
                'with a screen setting of 1024x768.)'};            
            h=msgbox(sentence1, 'Printing Tip', 'help');
            waitfor(h);
if ispc
    print -v -noui;
else
    print -dsetup -noui;    %untested code for non-windows platforms
end
