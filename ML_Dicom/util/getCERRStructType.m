function type = getCERRStructType(structS);
%"getCERRStructType"
%   Checks the fields in the passed structS and determines which cell in a
%   planC this structure was pulled from.  This determination is based on the
%   initializeCERR function's field names, so planCs with structs that do
%   not match initializeCERR's prototypes will throw a warning and return
%   [].
%
%   The output is in string form, ie 'dose', 'structures', etc.
%
%JRA 06/27/06
%
%Usage:
%   type = getCERRStructType(structS);
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
      
planInitC = initializeCERR;       

%Get possible cell field names in a planC.
indexFields = fields(planInitC{end});       
       
%Determine the number of cell types initializeCERR returns.       
numCells = length(planInitC);       
    
%Extract fieldnames of the passed structS
myFields = fields(structS);

%Loop over each initialized datatype and compare field names, looking for a
%match to the passed structS.
for i=1:numCells
    
    thisCellsFields = fields(planInitC{i});
              
    fieldsMatch = ismember(thisCellsFields, myFields);
    
    nMatchingFields(i) = sum(fieldsMatch);
          
end

%Find the cell that matched the most fields.
[maxNum, ind] = max(nMatchingFields);

%If more than 1 match in that top cell, assume we know the type now.
if maxNum > 1
    type = indexFields{ind};
    return;    
else 
   %No fields matched at all!
   warning('Structure passed to getCERRStructureType does not appear to be a valid planC structure.  Returning [].');
   type = []; 
end