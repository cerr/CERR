%test_PID
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


figure

colormap jet

s = 12;

PIDM = getPID(s, 1, planC, 'transverse', 'max');

subplot(1,3,1), imagesc(PIDM), axis image, title('transverse')

PIDM = getPID(s, 1, planC, 'saggital', 'max');

subplot(1,3,2), imagesc(PIDM), axis image, title('saggital')

PIDM = getPID(s, 1, planC, 'coronal', 'max');

subplot(1,3,3), imagesc(PIDM), axis image, colorbar, title('coronal')
