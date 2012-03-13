function studyreg = readLeksellStudyregFile(filename)
%"readLeksellStudyregFile"
%   Reads a Leksell studyreg file using decodeLeksellData and places the
%   fields into a datastructure with meaningful names.  This structure
%   shows the meaning of the transformation matrices in the Leksell Study
%   files so that it is clear which modality the matrices are going to and
%   from.  However, this information is not used when importing to CERR
%   because the target modality is always LGP (the Leksell coordinate
%   system).
%
%JRA 6/13/05
%
%LM: KRK, 05/29/07, added additional documentation
%
%Usage:
%   studyreg = readLeksellStudyregFile(filename)
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

fid = fopen(filename, 'r', 'b');

data = decodeLeksellData(fid);

fclose(fid);

%If data does not have at least two elements it is effectively empty.
if length(data) < 2
    studyreg = [];
    return;
end

for i=1:length(data) - 1
    rawStudyreg = data{i};

	studyreg(i).original_modality       = rawStudyreg{1}; %MR/CT/etc
	studyreg(i).target_modality         = rawStudyreg{2}; %Leksell   
  	studyreg(i).registration_value      = rawStudyreg{3}; %original modalities reg. value

end
