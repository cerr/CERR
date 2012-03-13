function  im2=lowpass3d(im,sigma_or_mask)
% Function: im = lowpass3d(im,sigma_or_mask)
%
% if sigma_or_mask is a scalar value, it will be used a the sigma value for
% the Gaussian smoothly mask. Or it must be a 3D array to be used as a 3D
% smoothly mask, and the dimensions must be odd.
siz=size(im);

if ndims(im) == 2
	im2 = lowpass2d(im,sigma_or_mask);
	return;
end


if( ndims(sigma_or_mask) ~= 3 )
	% Gaussian smoothing
	sigma = sigma_or_mask(1);

	w=max(2*sigma,3);

	wc=floor(w/2);
	vec=[-wc:wc];
	[x,y,z] = meshgrid(vec,vec,vec);

	v = (x.*x+y.*y+z.*z)/8/sigma;

	G = sigma.^(-0.5)*exp(-v);
	G = G / sum(G(:));
else
	G = sigma_or_mask;
end

siz1 = size(im);
siz2 = size(G);
siz = siz1+siz2-1;

pad = (siz2-1)/2;

im2 = zeros(siz,class(im));
im2(pad(1)+1:end-pad(1),pad(2)+1:end-pad(2),pad(3)+1:end-pad(3)) = im;
for k=1:pad
	im2(k,:,:) = im2(pad(1)+k,:,:);
	im2(end-k+1,:,:) = im2(end-pad(1)+1-k,:,:);
	
	im2(:,k,:) = im2(:,pad(2)+k,:);
	im2(:,end-k+1,:) = im2(:,end-pad(2)+1-k,:);
	
	im2(:,:,k) = im2(:,:,pad(3)+k);
	im2(:,:,end-k+1) = im2(:,:,end-pad(3)+1-k);
end


%im2 = conv3fft(im,G);
im2 = conv3fft(im2,G);
im2 = im2(pad(1)+1:end-pad(1),pad(2)+1:end-pad(2),pad(3)+1:end-pad(3));
im2 = max(im2,0);



