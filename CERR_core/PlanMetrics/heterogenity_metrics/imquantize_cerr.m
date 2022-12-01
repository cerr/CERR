function q = imquantize_cerr(x,nL,xmin,xmax,binwidth)
% function q = imquantize_cerr(x,nL,xmin,xmax,binwidth)
%
% Function to quantize an image. The image can be quantized in the
% following two ways based on :
% 1> Number of bins: Specify the first two input arguments. i.e. the image
% matrix x and the number of levels nL. The min/max can be passed using the
% xmin, xmax arguments. If they are empty or not passed, the min/max are
% computed from the image x.
% 2> Bin width: the nL, xmin, xmax are input as empty. Specify the
% bin width using the binwidth argument
%
% APA, 2/26/2018

if exist('xmin','var') && ~isempty(xmin)
    x(x<xmin) = xmin;
else
    xmin = min(x(:));
end

if exist('xmax','var') && ~isempty(xmax)
    x(x>xmax) = xmax;
else
    xmax = max(x(:));
end

if ~isempty(nL)
    % matlab's discretization from graycomatrix
    slope = (nL-1) / (xmax - xmin);
    intercept = 1 - (slope*(xmin));
    q = round(imlincomb(slope,x,intercept,'double'));
    
elseif exist('binwidth','var') && ~isempty(binwidth)
    if xmin < 0
        edgeMin = xmin - rem(xmin,binwidth) - binwidth;
    else
        edgeMin = xmin - rem(xmin,binwidth);
    end
    if xmax < 0
        edgeMax = xmax - rem(xmax,binwidth);
    else
        edgeMax = xmax - rem(xmax,binwidth) + binwidth;        
    end
    edgeV = edgeMin:binwidth:edgeMax;
    q = discretize(x,edgeV);
else
    %No quantization
    warning('Returning input image. Specify the number of bins or the binwidth to quantize.')
    q = x;
end

return
