function im = RegdoMirrCheckboard_YuWu(Im1, Im2, rows, cols)
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
    classname = 'uint16';
    Im1 = cast(Im1, classname); 
    Im2 = cast(Im2, classname); 

    m1 = fix(m/rows); n1 = fix(n/cols);

    im = zeros(m,n);
    imMirr = cell(rows, cols);
    for i=1:rows
        for j=1:cols
            c1 = Im1( (i-1)*m1+1:i*m1, (j-1)*n1+1:j*n1 );
            c2 = Im2( (i-1)*m1+1:i*m1, (j-1)*n1+1:j*n1 );
            
            mirrPos = round(size(c1,2)/2);
            
            if mod(size(c1,2), 2) == 0
                isEven = 1;
            else
                isEven = 0;
            end
            imMirr{i, j} = RegdoMirror(c1, c2, mirrPos, isEven);
            imMirr{i, j} = imMirr{i, j}(1:m1, 1:n1);
            
            im( (i-1)*m1+1:i*m1, (j-1)*n1+1:j*n1 ) = imMirr{i,j}-(i^2+j^2)*5;
        end
    end
    
    
        
end