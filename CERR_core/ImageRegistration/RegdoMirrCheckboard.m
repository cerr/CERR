function im = RegdoMirrCheckboard(Im1, Im2, numRows, numCols)
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

      
    [m n p] = size(Im1);
    classname = class(Im1);
    %Im1 = cast(Im1, classname); 
    %Im2 = cast(Im2, classname); 

    m1 = fix(m/numRows); 
    n1 = fix(n/numCols);
    black = zeros(m1, n1, classname);
    white = ones(m1, n1, classname);
    [ROW,COL] = ndgrid(1:m1,1:n1);
    indKeepV = ((ROW-m1/2).^2)/(m1/2)^2 + ((COL-n1/2).^2)/(n1/2)^2 <= 1;
    black(indKeepV) = 1;
    
%     %tile = [black white; white black];
%     tile = [black black; black black];
%     I = repmat(tile, [ceil(m/(2*m1)) ceil(n/(2*n1)) p]);
     
    I = logical(size(Im1));
    I(1:numRows*m1,1:numCols*n1) = repmat(black,numRows, numCols);
    
    CA_Image = min(Im1(:))*single(I);
    
    Imov = I*0;
    
    for rowNum = 1:numRows
        
        for colNum = 1:numCols            
            
            indJv = 1:floor(n1/2);
            j1Start = (colNum-1)*n1 + n1 - floor(n1/2);
            j2Start = (colNum-1)*n1;
            jEnd   = colNum*n1;
            
            iStart = (rowNum-1)*m1+1;
            iEnd   = rowNum*m1;
            
            j1V = j1Start+indJv;
            j2V = j2Start+indJv;
            iV = iStart:iEnd;
            
            Iblock = CA_Image(iV,(j2Start+1):jEnd);
            
            IblockMov = Imov(iV,1:floor(n1/2));
           
            Iblock(1:m1,(n1-floor(n1/2)+1):n1) = Im1(iV,j1V);
            Iblock(1:m1,1:floor(n1/2)) = flipdim(Im2(iV,j1V),2);
            
            CA_Image(iV,(j2Start+1):jEnd) = Iblock;
            
            IblockMov(1:m1,1:floor(n1/2)) = 1;
            Imov(iV,(j2Start+1):j2Start+size(IblockMov,2)) = IblockMov;            
            
        end
        
    end
    
      
    CA_Image(I==0) = min(Im1(:));
    Imov = Imov.*I;

    
%     % Apply different color for moving half of the image
%     CA_Image(:,:,2) = CA_Image(:,:,1);
%     CA_Image(:,:,3) = CA_Image(:,:,1);
%     
%     CA_Image = (CA_Image - min(CA_Image(:))) / (max(CA_Image(:))-min(CA_Image(:)));
%     CA_Image(:,:,2) = CA_Image(:,:,2) + Imov*0.136;
%     CA_Image(:,:,3) = CA_Image(:,:,3) + Imov*0.136;
%     CA_Image = min(CA_Image,1);
%     % Apply different color for moving half of the image ends
    
    
%     c1 = I(1:m, 1:n, 1:p);
%     c2 = (1-c1);
% 
%     CA_Image = c1.*(Im2) + c2.*(Im1);
%     CA_Image(:,:,2) = CA_Image(:,:,1);
%     CA_Image(:,:,3) = CA_Image(:,:,1);
%     CA_Image = single(CA_Image);
%     
%     c1 = single(c1);
%     CA_Image = (CA_Image - min(CA_Image(:))) / (max(CA_Image(:))-min(CA_Image(:)));
%     CA_Image(:,:,2) = CA_Image(:,:,2) + c1*0.136;
%     CA_Image(:,:,3) = CA_Image(:,:,3) + c1*0.136;
%     CA_Image = min(CA_Image,1);
%     
    
    im = CA_Image;
    
end