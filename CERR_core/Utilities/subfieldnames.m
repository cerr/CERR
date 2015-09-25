function s=subfieldnames(a,prefix)
% SUBFIELDNAMES returns ALL fieldnames, not
% just the first tier
%
% written by m. schweisguth, adapted from
% initial version by m. robbins.
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

if isstruct(a)
else
    s = {};
    return;
end

if exist('prefix','var')
else
    prefix = inputname(1);
end;

ss    = struct('type','.','subs','');
fn    = fieldnames(a);
cells = cell(1,length(fn));

stringcount = 0;

%note: MATLAB will return the first field value for
%      non-homogeneous structures.

for ii=1:length(fn)
    ss.subs = fn{ii};
    aa      = subsref(a,ss);
    if isstruct(aa)& ~isempty(aa)
        cells{ii}   = subfieldnames(aa,[prefix '.' fn{ii}]);
        stringcount = stringcount + length(cells{ii});
    else
        cells{ii}   = { [prefix '.' fn{ii}] };
        stringcount = stringcount + 1;
    end;
end;

%collect the results together:

s    = cell(1,stringcount);
indx = 1;

for ii=1:length(cells)
    fn   = cells{ii};
    fnii = length(fn);
    s(indx:indx+fnii-1) = fn(1:fnii);
    indx = indx + fnii;
end;
