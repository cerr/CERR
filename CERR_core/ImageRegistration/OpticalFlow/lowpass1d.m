function  im2=lowpass1d(im,sigma_or_mask)
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

	G = sigma.^(-0.5)*exp(-(vec.*vec)/2/sigma);
	G = G / sum(G(:));
else
	G = sigma_or_mask;
	wc1 = (size(G,1)-1)/2;
	wc2 = (size(G,2)-1)/2;
end


% Apply a Gaussian low pass filter

im2 = conv3fft1d(im,G');
%im2 = im2(wc1+1:siz(1)+wc1);

f = str2func(class(im));
im2 = f(im2);
