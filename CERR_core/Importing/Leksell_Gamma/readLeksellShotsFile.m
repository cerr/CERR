function shotsStruct = readLeksellShotsFile(filename)
%"readLeksellShotsFile"
%   Reads a Leksell shots file using decodeLeksellData and places the
%   fields into a datastructure with meaningful names.  Some values are 
%   multiplied by 0.1 to account for the unit change from Leksell (mm) to 
%   CERR (cm).  Many of the values in Leksell files are a mystery at the 
%   moment, and are stored in variables called "mystery_value_x" where x is
%   a number.  If anyone discovers the meaning of these values please 
%   report them on the CERR webpage at radium.wustl.edu/cerr or to 
%   jalaly@radium.wustl.edu. Currently, the shotsStruct.shots data is not 
%   used in CERR.
%
%JRA 6/13/05
%
%LM: KRK, 05/28/07, added additional documentation, newly discovered
%                   variable meanings and scaled mm to cm
%
%Usage:
%   function shotsStruct = readLeksellShotsFile(filename)
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

%Get meaningful data.
allShotData = data{1};

%Get data on dose matrices.
matrixData = allShotData{6};

%Iterate over matrix data and extract info.
for i = 1:length(matrixData)-1;
    rawMatrix = matrixData{i};
    
    matrixS(i).name = rawMatrix{1};
    matrixS(i).minExtent = rawMatrix{2}*0.1; %Scale mm->cm
    matrixS(i).maxExtent = rawMatrix{3}*0.1;
    matrixS(i).maxDosePoint = rawMatrix{4}*0.1;
    matrixS(i).gridSize = rawMatrix{5}*0.1;        
    matrixS(i).mysteryValue_1 = rawMatrix{6}; %this value is 0 for all cases viewed      
end

%Get the shot data
shotsData = allShotData{7};
shotOffset = 0;
%First iterate over each target point included in shots file.  Many shots
%are filled with empty data.  These are not imported here.
for i = 1:length(shotsData) - 1
           
    shotNum = i - shotOffset;
    
    rawShot = shotsData{i};
    
    %Test for an empty shot/target point.
    warning off MATLAB:nonIntegerTruncatedInConversionToChar    
    try
        compositeData = uint16(vertcat(rawShot{:}));
        warning on MATLAB:nonIntegerTruncatedInConversionToChar        
        if isequal(unique(compositeData), 0)
            shotOffset = shotOffset + 1;
            continue;
        end
    end
    warning on MATLAB:nonIntegerTruncatedInConversionToChar            
            
    %Shot information named similar to the output of the Leksell software
    shotS(shotNum).associatedMatrix  = rawShot{2};     
    shotS(shotNum).targetPoint       = rawShot{3}*0.1;
    shotS(shotNum).weight            = rawShot{4};
    shotS(shotNum).gamma             = rawShot{5}*180/pi; % gamma in radians               
    shotS(shotNum).collimator_helmet = rawShot{6};
    shotS(shotNum).plugging          = rawShot{8};
    shotS(shotNum).srcWeight         = rawShot{13};     
    shotS(shotNum).xyzSrcPositions   = rawShot{16}; % xyz positions in the reference coordinate system (leksell) - no transform needed  
    shotS(shotNum).gamma_transM      = reshape(rawShot{15}, [3, 3]);    % rotation matrix about x with theta=gamma     
    
    %Unknown variables, may only be significant for the treatment software
    %(not CERR).
    shotS(shotNum).mystery_value_1   = rawShot{1};    
    shotS(shotNum).mystery_value_4   = rawShot{7};        
    shotS(shotNum).mystery_value_5   = rawShot{9};        
    shotS(shotNum).mystery_value_6   = rawShot{10};        
    shotS(shotNum).mystery_value_7   = rawShot{11};        
    shotS(shotNum).mystery_value_8   = rawShot{12};            
    shotS(shotNum).mystery_value_10  = rawShot{14};  
end

shotsStruct.doseMatrixInfo  = matrixS;
shotsStruct.shots           = shotS;
