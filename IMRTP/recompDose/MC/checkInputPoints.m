function input = checkInputPoints(input)

% check to see that no y-values are skipped, no data is repeated, and that
% all corners are square.
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


ind = [];

for i = 1:length(input)-1, 
    [val, dir] =  min(abs(input(i+1, :) - input(i, :)));
    if(val>0), 
        input(i+1, dir) = input(i, dir);
    end
    if(dir == 1), 
        if(abs(input(i+1, 2)-input(i, 2))>=2), 
            % insert missing points
            ind = [ind i];
        end
    end
    % there should be exactly two entries with the same yvalue
end


for i = 1:length(ind), 
    x = length(abs(input(ind(i)+1, 2)-input(ind(i), 2))-1);
    xsign = double(input(ind(i)+1, 2)>input(ind(i), 2));
    xsign = xsign*2-1;
    for j = 1:length(x)
        input(end+1, 2) = input(ind(i)+1, 2)-xsign*j;
        input(end, 1) = input(ind(i)+1, 1);
        input(end+1, 2) = input(ind(i)+1, 2)-xsign*j;
        input(end, 1) = input(ind(i)+1, 1);
    end
end

i=1;
insertInd =[]; 
deleteInd = [];
deleteVal = [];
while(i<length(input)) 
    ycurrent = input(i, 2);
    j=i;
    while(input(j, 2)==ycurrent & j<length(input))
        j=j+1;
    end
    if((j-i)<2), 
        insertInd = [insertInd i];
    elseif((j-i)>2),
        deleteInd = [deleteInd i];
        deleteVal = [deleteVal ycurrent];
    end
    i=j;
end

if(~isempty(insertInd))
if(insertInd(end)>=length(input)-1), 
    insertInd(end)=[];
end
end
input = [input; input(insertInd, :)];
    
% want to delete the non-unique value

deleteInd = [];
for i = 1:length(deleteVal), 
    ind = find(input(:,2)==deleteVal(i));
    [jnk, ind1] = unique(input(ind, 1));
    deleteInd = [deleteInd, setdiff(ind, ind(ind1))];
end

input(deleteInd, :) = [];
