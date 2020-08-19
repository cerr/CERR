function b = grayxform(a,T)
% Function to apply a graylevel transform to an image.
% in should be of class uint8, uint16, or double.
% T should be double, in the range [0,1].
%-----------------------------------------------------------------------------
% Ref: http://www4.hcmut.edu.vn/~huynhqlinh/TinhocDC/WebLQNguyen/matlab/tai%20lieu/MATLAB6_COURSE/WORK/IMAGES/IMAGES/PRIVATE/GRAYXFORM.C
               
maxTidx = numel(T)-1;

switch(class(a))

case 'double'
    %Clip values from 0-1
    val = a;
    val(val<0) = 0;
    val(val>1) = 1;
    index = uint32(val .* maxTidx + 0.5);
    b = T(index);
    
case 'uint8'
     if(maxTidx == 255) 
        %We don't need to scale the index
        b = uint8(255.0 * t(a) + 0.5);
     else 
        %Scale the index by maxTidx/255
        scale = maxTidx / 255.0;
        index = uint32(a .* scale + 0.5);
        b = uint8(255.0 * T(index) + 0.5);
     end

case 'uint16'

     if(maxTidx == 65535) 
        b = uint16(65535.0 * t(a) + 0.5);
     else 
        %Scale the index by maxTidx/65535
        scale = maxTidx / 65535.0;
        index = uint32(a .* scale + 0.5);
        b = uint16(65535.0 * T(index) + 0.5);
     end
     
end

end