function out_m = updownsample( in_m,out_x_sz,out_y_sz,is_fourier_flag,is_real_flag )
%
% updownsample - up-sample or down-sample an input series using fourier domain
%                input series needs to be continuous of a high degree
%
% format:   out_m = updownsample( in_m,out_x_sz,out_y_sz,is_fourier_flag,is_real_flag )
%
% input:    in_m                - input matrix for up/down sampling. can be in
%                                 space domain OR in fourier domain, in such
%                                 case, needs to be in matlab format !!!
%                                 (matlab-format = the save as given from fft/fft2)
%           out_x_sz,out_y_sz   - desired number of pixels in the output image
%           is_fourier_flag     - 1: the input is given in the fourier domain
%                                 0: the input is given in the space domain
%                                    (we need to use fft2 to convert to fourier domain)
%           is_real_flag        - 0: the input is a complex matrix -> don't use
%                                    abs() at the output, perform complex
%                                    up/down sampling
%                                 1: the input is real BUT has negative values ->
%                                    use real() at the output
%                                 2: the input is real and positive -> using
%                                    abs() at the output 
%
% output:   out_m               - up/down sampled image 
%
% NOTE: it is important to specify if the image is REAL or COMPLEX, since
%       if the image is REAL -> we have to use ABS() on the inverse fourier
%       transform (because of roundoff errors of the transform).
%
% NOTE: since a desired amount of pixels is needed at the output, there is
%       no attempt to use matrices which are in size of power of 2. this
%       optimization can not be used in this case
%
% NOTE: input series needs to be CONTINUOUS OF A HIGH DEGREE, since the
%       upsampling is done in the frequency domain, which samples the output
%       grid with SINE-like (harmonic) functions
%
% 
% Example:  type "updownsample" for an example. it will load the matlab's
%           child image to a temporary variable, as upsample it
%
%               out = updownsample( A,300,300,0,1 );
%               figure;
%               colormap gray;
%               subplot( 1,2,1 );
%               imagesc( A );
%               subplot( 1,2,2 );
%               imagesc( out );
%


% 
% Theory:   the upsampling is done by zero-padding in the input domain BETWEEN the samples,
%           then at the fourier domain, taking the single spectrum (out of the repetition of spectrums)
%           i.e. low pass with Fcutoff=PI/upsample_factor, zeroing the rest of the spectrum
%           and then doing ifft to the distribution.
%           since we have a zero padding operation in time, we need to multiply by the fourier gain.
%
%              +-----------+     +-------+     +---------+     +--------+     +--------+
%   y[n,m] --> | up-sample | --> |  FFT  | --> |   LPF   | --> | * Gain | --> |  IFFT  | --> interpolated 
%              | factor M  |     +-------+     | Fc=PI/M |     +--------+     +--------+
%              +-----------+                   +---------+
%
%           this operation is the same as the following one (which has less operations):
%
%              +-------+     +--------+     +--------------+     +--------+
%   y[n,m] --> |  FFT  | --> | * Gain | --> | Zero Padding | --> |  IFFT  | --> interpolated 
%              +-------+     +--------+     +--------------+     +--------+
%
%           NOTE THAT, the zero-padding must be such that the D.C. ferquency remains the D.C. frequency
%           and that the zero padding is applied to both positive and negative frequencies. 
%           The zero padding actually condences the frequency -> which yields a longer series in the 
%           image domain, but without any additional information, thus the operation must be an interpolation.


% Copyright (c) 2003, Ohad Gal
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
% 
%     * Redistributions of source code must retain the above copyright
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in
%       the documentation and/or other materials provided with the distribution
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.


% ==============================================
%   check input parameters
% ==============================================
if (nargin==0)
    hFig    = figure( 'visible','off' );
    hImage  = image;
    Child   = get( hImage,'cdata' );
    close( hFig );
	out     = updownsample( Child,300,300,0,1 );
	figure;
	colormap gray;
	subplot( 1,2,1 );
	imagesc( Child );
	subplot( 1,2,2 );
	imagesc( out );
    return
elseif (nargin<5)
    error( 'UpDownSample - insufficient input parameters' );
end


% ==============================================
% get input image size, and calculate the gain
% ==============================================
[in_y_sz,in_x_sz] = size( in_m );
gain_x = out_x_sz/in_x_sz;
gain_y = out_y_sz/in_y_sz;

% ==============================================
% check if up/down sampling is needed at all
% ==============================================
if (gain_x == 1) & (gain_y==1)

    % same gain -> do not change sampling rate
    % ==========================================
    if is_fourier_flag
        switch is_real_flag
            case 0, out_m = ifft2( in_m );
            case 1, out_m = real( ifft2( in_m ) );
            case 2, out_m = abs( ifft2( in_m ) );
        end
    else
        out_m = in_m;
    end
    
else

    % upsample or downsample as needed
    % ==================================
    
    % convert to fourier domain, if input is given in the space domain
    if ~is_fourier_flag
        in_m = fft2(in_m);
    end
    
    % build grid vectors for the up/down sampling
    % ============================================
    % if the input is even & output is odd-> use floor for all
    % if the output is even & input is odd -> use ceil for all
    % other cases - don't care
    % for downsampling -> the opposite
    if (~mod( in_x_sz,2 ) & (out_x_sz>in_x_sz)) | (mod( in_x_sz,2 ) & (out_x_sz<in_x_sz))
        x_output_space  = max(floor((out_x_sz-in_x_sz)/2),0) + [1:min(in_x_sz,out_x_sz)];
        x_input_space   = max(floor((in_x_sz-out_x_sz)/2),0) + [1:min(in_x_sz,out_x_sz)];
    else
        x_output_space  = max(ceil((out_x_sz-in_x_sz)/2),0) + [1:min(in_x_sz,out_x_sz)];
        x_input_space   = max(ceil((in_x_sz-out_x_sz)/2),0) + [1:min(in_x_sz,out_x_sz)];
    end
    if (~mod( in_y_sz,2 ) & (out_y_sz>in_y_sz)) | (mod( in_y_sz,2 ) & (out_y_sz<in_y_sz))
       y_output_space  = max(floor((out_y_sz-in_y_sz)/2),0) + [1:min(in_y_sz,out_y_sz)];
       y_input_space   = max(floor((in_y_sz-out_y_sz)/2),0) + [1:min(in_y_sz,out_y_sz)];
   else
       y_output_space  = max(ceil((out_y_sz-in_y_sz)/2),0) + [1:min(in_y_sz,out_y_sz)];
       y_input_space   = max(ceil((in_y_sz-out_y_sz)/2),0) + [1:min(in_y_sz,out_y_sz)];
   end
   
    % perform the up/down sampling
    padded_out_m    = zeros( out_y_sz,out_x_sz );
    in_m            = fftshift(in_m);
    padded_out_m( y_output_space,x_output_space ) = in_m(y_input_space,x_input_space);
    out_m           = (gain_x*gain_y)*ifft2(ifftshift(padded_out_m));   
    
    % check the output format real or complex
    switch is_real_flag
        case 0, % do nothing
        case 1, out_m   = real( out_m );
        case 2, out_m   = abs( out_m );
    end
    
end
