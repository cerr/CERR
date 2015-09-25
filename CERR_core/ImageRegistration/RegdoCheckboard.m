function im = RegdoCheckboard(Im1, Im2, rows, cols)
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

    m1 = fix(m/rows); n1 = fix(n/cols);
    black = zeros(m1, n1, classname);
    white = ones(m1, n1, classname);
    tile = [black white; white black];
    I = repmat(tile, [ceil(m/(2*m1)) ceil(n/(2*n1)) p]);
    c1 = I(1:m, 1:n, 1:p);
    c2 = (1-c1);

    CA_Image = c1.*(Im2) + c2.*(Im1);
    CA_Image(:,:,2) = CA_Image(:,:,1);
    CA_Image(:,:,3) = CA_Image(:,:,1);
    CA_Image = single(CA_Image);
    
    c1 = single(c1);
    CA_Image = (CA_Image - min(CA_Image(:))) / (max(CA_Image(:))-min(CA_Image(:)));
    CA_Image(:,:,2) = CA_Image(:,:,2) + c1*0.136;
    CA_Image(:,:,3) = CA_Image(:,:,3) + c1*0.136;
    CA_Image = min(CA_Image,1);
    
%     r = 0.05;
%     frac1 = (max(Im1(:))-min(Im1(:)))*r;
%     frac2 = (max(Im2(:))-min(Im2(:)))*r;
%     CA_Image = c1.*(Im2+frac2) + c2.*(Im1-frac1);
    
    im = CA_Image;
        
end