function Study = readLeksellStudyFile(filename)
%"readLeksellStudyFile"
%   Reads a Leksell Study file using decodeLeksellData and places the
%   fields into a datastructure with meaningful names.  Many of the values
%   in Leksell files are a mystery at the moment, and are stored in
%   variables called "mystery_value_x" where x is a number.  If anyone
%   discovers the meaning of these values please report them on the CERR
%   webpage at radium.wustl.edu/cerr or to jalaly@radium.wustl.edu.
%
%JRA 6/13/05
%
%Usage:
%   Study = readLeksellStudyFile(filename)
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
    Study = [];
    return;
end

for i=1:length(data) - 1
    rawStudy = data{i};

	Study(i).modality           = rawStudy{1};
    Study(i).mystery_value_1    = rawStudy{2}; %always a small integer
    %Read in the original transM from the file
    originalTransM = reshape(rawStudy{3}, [4 4]);
    %Take the transpose and the inverse to put into the format used by CERR
    modifiedTransM = inv(originalTransM');
    %Divide the translations by 10 since the matrix was originally for mm
    %(converts the translations to cm)
    modifiedTransM(1,4) = modifiedTransM(1,4)/10;
    modifiedTransM(2,4) = modifiedTransM(2,4)/10;
    modifiedTransM(3,4) = modifiedTransM(3,4)/10;
    Study(i).rcsToxyzTransM = modifiedTransM;
    Study(i).pixelIntensityRange = rawStudy{4}; % appears to be the image intensity range, but does not need to be used for CERR import
    Study(i).registration_value = rawStudy{5};    
    
end
