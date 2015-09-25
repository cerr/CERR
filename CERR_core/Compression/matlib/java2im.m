% function img=java2im(a,row,cols)
%
% converts a signed int32 monodimensional array in an
% uint8 x 3 RGB displayable matlab image. The array
% is returned from a getImage() method and the actual
% pixel source is given by a standard ImageConsumer
% (e.g. a PixelGrabber)

function img=java2im(a,rows,cols)
    
    [a1,nb]=s2u(a);
    
    %disp(sprintf('nb: %d',nb));

    matrice=reshape(a1,cols,rows)';
    
    img(:,:,1)=uint8(bitand(bitshift(matrice,-16),hex2dec('FF')));
    img(:,:,2)=uint8(bitand(bitshift(matrice,-8),hex2dec('FF')));
    img(:,:,3)=uint8(bitand(matrice,hex2dec('FF')));
return