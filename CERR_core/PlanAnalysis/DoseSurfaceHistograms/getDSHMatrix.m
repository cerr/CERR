function [planC, doseBinsV, areaHistV] = getDSHMatrix(planC, structNum, doseNum)
%"getDSHMatrix"
%   Wrapper function to get DSH data.  Use this to get the doseV/areaV
%   vectors used to represent DSH data for a structNum and doseNum.  If the
%   surface points have not previously been calculated they are stored in
%   the planC. 
%
%JRA 2/24/05
%
%Usage:
%   [planC, doseBinsV, areaHistV] = getDSHMatrix(planC, structNum, doseNum)
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

indexS = planC{end};

[doseV, areaV, zV, planC] = getDSH(structNum, doseNum, planC);

[doseBinsV, indV]    = sort(doseV);
areaHistV            = areaV(indV);