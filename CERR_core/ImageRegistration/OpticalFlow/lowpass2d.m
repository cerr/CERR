function  im2=lowpass2d(im,sigma_or_mask)
% Function: im = lowpass2d(im,sigma_or_mask)
%
% if sigma_or_mask is a scalar value, it will be used a the sigma value for
% the Gaussian smoothly mask. Or it must be a 2D array to be used as a 2D
% smoothly mask, and the dimensions must be odd.

siz=size(im);

if( min(size(sigma_or_mask)) == 1 )
	sigma = sigma_or_mask(1);

	w=max(2*sigma,3);

	wc=floor(w/2);
	wc1 = wc;
	wc2 = wc;
	vec=[-wc:wc];
	[x,y] = meshgrid(vec,vec);

	G = sigma.^(-0.5)*exp(-(x.*x+y.*y)/4/sigma);
	G = G / sum(G(:));
else
	G = sigma_or_mask;
	if ndims(G) == 3
		G = squeeze(G(:,:,1));
		G = G / sum(G(:));
	end
	wc1 = (size(G,1)-1)/2;
	wc2 = (size(G,2)-1)/2;
end


% Apply a Gaussian low pass filter

im2 = conv2(G,im);
im2 = im2(wc1+1:siz(1)+wc1,wc2+1:siz(2)+wc2);

f = str2func(class(im));
im2 = f(im2);
