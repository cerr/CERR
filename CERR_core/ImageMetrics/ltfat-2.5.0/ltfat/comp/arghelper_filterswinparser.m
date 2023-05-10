function [varargincell,winCell] = arghelper_filterswinparser(windows,varargincell)

% Search for window given as cell array
%
%   Url: http://ltfat.github.io/doc/comp/arghelper_filterswinparser.html

% Copyright (C) 2005-2022 Peter L. Soendergaard <peter@sonderport.dk> and others.
% This file is part of LTFAT version 2.5.0
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
candCellId = cellfun(@(vEl) iscell(vEl) && any(strcmpi(vEl{1},windows)),varargincell);

winCell = {};
% If there is such window, replace cell with function name so that 
% ltfatarghelper does not complain
if ~isempty(candCellId) && any(candCellId)
    candCellIdLast = find(candCellId,1,'last');
    winCell = varargincell{candCellIdLast};
    varargincell(candCellId) = []; % But remove all
    varargincell{end+1} = winCell{1};
end
