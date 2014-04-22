function upsampled3M = fft_upsample3d(data3M,upsample_rate)
% function upsampled3M = fft_upsample3d(data3M,upsample_rate)
%
% This function upsamples data3M to the new size based on upsample_rate. If
% upsample_rate is scalar, the new size is upsample_rate times the old size.
% If the upsample_rate is of length 3, the new size is of the size
% upsample_rate. This code assumes data3M contains only 0 or positive values.
%
% Example usage:
%
% global planC
% indexS = planC{end};
% upsample_rate = 2;
% upsampledScan3M = fft_upsample3d(planC{indexS.scan}(1).scanArray,upsample_rate);
%
% APA, 04/22/2014

in_m = data3M;
in_sz = size(in_m);

if length(upsample_rate) == 1
    out_sz = in_sz*upsample_rate;
else
    out_sz = upsample_rate;
end

gain_x = out_sz(2)/in_sz(2);
gain_y = out_sz(1)/in_sz(1);
gain_z = out_sz(3)/in_sz(3);
in_m = fftn(in_m);
padded_out_m = zeros(out_sz);
in_m = fftshift(in_m);
iV = floor(out_sz(1)/2-in_sz(1)/2)+1:floor(out_sz(1)/2+in_sz(1)/2);
jV = floor(out_sz(2)/2-in_sz(2)/2)+1:floor(out_sz(2)/2+in_sz(2)/2);
kV = floor(out_sz(3)/2-in_sz(3)/2)+1:floor(out_sz(3)/2+in_sz(3)/2);
padded_out_m(iV,jV,kV) = in_m;
upsampled3M = abs(gain_x*gain_y*gain_z*ifftn(ifftshift(padded_out_m)));

