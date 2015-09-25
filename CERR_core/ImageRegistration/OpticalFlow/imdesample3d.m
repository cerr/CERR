function im = imdesample3d(img,f,fz)
% Function: im = imdesample3d(img,f,fz)
% down sample the image
%
% f should be 2, 4, 8, 16
% fz should be 1, 2, 4, 8, 16
if( f ~= 2 & f ~= 4 & f ~= 8 & f ~= 16 )
	error('f must equal to 2, 4, 8, 16');
end

[h,w,d] = size(img);

for z = 1:d
	im(:,:,z) = imdesample(img(:,:,z),f);
end

if( fz ~= 1 )
	im2 = im;
	clear im;
	for z = 1:fz:d
		low = z;
		upper = min(z+fz,d);
		im(:,:,(z-1)/fz+1) = sum(im2(:,:,low:upper),3)/(upper-low+1);
	end
end


