function im = imdesample(img,f)
%
% down sample the image
%
% f should be 2, 4, 8
%
if( f ~= 2 & f ~= 4 & f ~= 8 & f ~= 16 )
	error('f must equal to 2, 4, 8, 16');
end

[h,w] = size(img);

for r = 1:h/f;
	for c = 1:w/f;
		r0 = (r-1)*f+1;
		c0 = (c-1)*f+1;
		im(r,c) = sum(sum(img(r0:r0+f-1,c0:c0+f-1)))/f/f;
	end
end


