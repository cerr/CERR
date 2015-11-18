function [e, thresh] = canny(im, varargin)
%CANNY is an implementation of the Canny edge detector
%   E = CANNY(IM) takes a 2-D grey-level image or a 3-D array representing
%   a volume and returns a 2-D or 3-D logical edge map using centred
%   differences and non-maximum suppression. No smoothing or thresholding
%   is done when only one argument is given.
%
%       IM is a 2-D or 3-D double or single array. (An RGB image is treated
%       as an M*N*3 volume.)
%
%   E = CANNY(IM, SIGMA) carries out Gaussian smoothing as part of gradient
%   estimation. The input array is extended by reflection at its boundaries
%   if necessary.
%
%       SIGMA is the smoothing parameter for the Gaussian mask. If it is a
%       scalar, smoothing is isotropic. SIGMA may also be a vector with one
%       element for each dimension of IM. For a 2-D array, SIGMA(1)
%       specifies sigma for the columns and SIGMA(2) sigma for the rows; in
%       image coordinates this means that SIGMA is of the form [SIGMA_Y,
%       SIGMA_X]. For a 3-D array the order is column, row, slice.
%
%       If SIGMA is the empty matrix, sqrt(2) is used as the smoothing
%       constant, to be consistent with the SIGMA argument of the EDGE
%       function.
%
%       If SIGMA is omitted no smoothing is done. To specify a threshold
%       but no smoothing, set SIGMA to zero.
%
%   E = CANNY(IM, SIGMA, THRESH) also carries out hysteresis thresholding.
%   THRESH has the same functionality as the threshold argument of EDGE.
%   (Name-value pairs may be used instead of the THRESH argument for more
%   control.)
%
%       THRESH may be a 2-element row vector [LO HI], specifying low and
%       high thresholds relative to the maximum gradient magnitude GMAX. If
%       THRESH is a scalar, the high threshold is set to THRESH*GMAX and
%       the low threshold to 0.4*THRESH*GMAX.
%
%       If THRESH is the empty matrix CANNY selects thresholds
%       automatically in a similar way to EDGE. CANNY(IM, SIGMA, []) is the
%       same as CANNY(IM, SIGMA, 'TMethod', 'histogram', 'TValue', 0.7,
%       'TRatio', 0.4) - see below.
%
%       If THRESH is omitted thresholding is controlled by name-value
%       pairs.
%
%   E = CANNY(IM, SIGMA, THRESH, NAME, VALUE, ...) 
%   E = CANNY(IM, SIGMA, NAME, VALUE, ...) 
%       allow further parameters to be set as name-value pairs.
%
%   Region of interest parameter:
%
%       'Region' - a region of interest in the input array specified as
%       [MINROW, MAXROW, MINCOL, MAXCOL] for 2-D images and as [MIN1, MAX1,
%       MIN2, MAX2, MIN3, MAX3] for 3-D arrays. The output array will have
%       size [MAXROW-MINROW+1, MAXCOL-MINCOL+1] or [MAX1-MIN1+1,
%       MAX2-MIN2+1, MAX3-MIN3+1]. The default is to process the whole
%       array so that E has the same size as IM. Reflection at the input
%       array boundaries is used to avoid trimming if necessary.
% 
%   Differencing parameter:
% 
%       'Centred' - logical scalar controlling gradient estimation. See
%       GRADIENTS_N.
% 
%           true (default) - Centred differences are used, and there is no
%           positional bias in the edge locations.
% 
%           false - differences between nearest neighbours are used, and
%           edge positions are biased such that E(I,J) indicates that an
%           edge has been detected at E(I-0.5,J-0.5). This option offers
%           slightly tighter localisation with very low-noise data. If
%           sub-pixel positions are computed, a correction is made for the
%           offset.
%
%   Non-maximum suppression parameters. See NONMAXSUPPRESS.
%
%       'SMethod' - String giving the method for interpolation for
%       non-maximum suppression. May be 'boundary', 'nearest' 'linear',
%       'cubic' or 'spline'. The default is 'boundary'.
%
%       'SRadius' - Radius at which interpolation is done for all options
%       except 'boundary'. The default is 1.
%
%       'SubPixel' (default false) - If true, sub-pixel interpolation is
%       carried out on the edge positions by fitting a parabola to the
%       three gradient magnitudes round the peak. The result E will be a
%       structure with two fields:
%
%           E.edge - a logical array with true at the edge positions
% 
%           E.subpix - In the 2-D case, if E.edge(I,J) is true,
%           E.subpix{1}(I,J) is the first (row) coordinate of the estimated
%           sub-pixel position of the edge point. E.subpix{2} gives the
%           second (column) coordinate. The 3-D case is similar.
% 
%   Thresholding parameters. The THRESH argument should be omitted when
%   these are used.
%
%       'TMethod' - The value is one of the following strings, giving the
%       method for determining the thresholds which are applied to the
%       gradient magnitude.
%
%           'none' - No thresholding is done (the default).
%
%           'absolute' - The value given by 'TValue' is used directly.
%
%           'relMax' - The value given by 'TValue' is multiplied by the
%           maximum gradient magnitude.
%
%           'histogram' - 'TValue' specifies the fraction of array elements
%           that have gradient magnitudes falling below the threshold.
%
%       'TValue' - The parameter value sets the threshold using the method
%       specified. If the value is a scalar, it sets the high threshold and
%       the low threshold is set by the value of 'TRatio'. If the method is
%       'absolute' or 'relMax', the value can be a 2-element row vector [LO
%       HI] giving the low and high thresholds for hysteresis thresholding.
%
%       'TRatio' - This sets the low threshold so that the ratio (low
%       threshold)/(high threshold) is equal to the parameter value. This
%       is the only way to set the low threshold for the 'histogram'
%       method. If TValue is a scalar and TRatio is omitted or empty,
%       simple thresholding at the high threshold (without hysteresis) is
%       done.
%
%       'TConn' - The connectivity for finding continuous edges and surfaces
%       for hysteresis thresholding. The defaults and possible values are
%       as for IMRECONSTRUCT.
%
%   [E, THRESH] = CANNY(...) returns the absolute threshold that was
%   applied.
%
% Comparison with the EDGE function
% ---------------------------------
%
% Differences between CANNY and the Image Processing Toolbox EDGE function
% with the 'canny' option:
%
%   * 3-D arrays can be processed.
%   * Sub-pixel edge position estimation is an option.
%   * The parameters are in a different order. Smoothing is done before
%   thresholding, so it makes sense to have the arguments in that order.
%   * If SIGMA and THRESH are omitted the defaults are no smoothing and no
%   thresholding. (If they are given as [] the defaults are as for EDGE.)
%   * Anisotropic smoothing is possible.
%   * There is more control over how non-maximum suppression is carried
%   out.
%   * There is more control over how thresholds are set.
%   * Thresholds set using the distribution of gradients are found using
%   a sort rather than a histogram of 64 bins.
%   * Returned thresholds are absolute, not relative. Together with the
%   'absolute' threshold option, this allows different images to be treated
%   consistently.
%   * Edges may go right up to the boundary of the output image, rather
%   than being clipped just short of it.
%   * The gradients, non-maximum suppression and hysteresis thresholding
%   functions are accessible independently, so the processing pipeline can
%   be separated to allow more elaborate schemes to be developed.
%   * By default, centred differences are used so that there is no
%   systematic bias in edge position. The EDGE function exhibits a
%   half-pixel bias towards the left and top of the image, probably because
%   it uses non-centred gradient estimates. Thus in an image whose rows are
%   [0 0 0.6 1 1], CANNY will mark column 3, whereas the EDGE function will
%   mark column 2. CANNY will use non-centred differences as an option.
%   * Centred differences mean that by default CANNY effectively smooths
%   slightly more than EDGE for the same value of SIGMA.
%
% Examples
% --------
%
% 2-D image with defaults as for EDGE. The output will not be identical to
% that from EDGE due to differences in the algorithm.
%
%       im = single(imread('pout.tif'));
%       e = canny(im, [], []);
%       imshow(e);
%
% 3-D volume with threshold values set relative to maximum gradient,
% anisotropic smoothing to reflect the resolution differences and subpixel
% position estimation to give a smoother plot:
%
%       mriload = load('mri');   % example data
%       im3 = single(squeeze(ind2gray(mriload.D, mriload.map)));
%       e = canny(im3, [1 1 0], ...
%           'TMethod', 'relMax', 'TValue', [0.5 0.9], ...
%           'SubPixel', true);
%       plot3(e.subpix{1}(e.edge), ...
%           e.subpix{2}(e.edge), e.subpix{3}(e.edge), '.');
%
% Reference
% ---------
%
% J.F.Canny, "A Computational Approach to Edge Detection," IEEE PAMI
% 8(6):679-698, 1986.
%
% See also: edge, gradients_n, nonmaxSuppress, hystThresh, imreconstruct,
% griddedInterpolant

% Sort arguments. Most checking done by other functions.
inp = inputParser;
checkthresh = @(t) checkattributes(t, {'numeric'}, ...
    {'nonnan' 'real' 'finite' 'nonnegative' 'nondecreasing'}) && ...
    (isempty(t) || isscalar(t) || isequal(size(t), [1 2]));
inp.addOptional('sigma', 0);
inp.addOptional('thresh', [], checkthresh);
inp.addParamValue('Region', 'same');
inp.addParamValue('Centred', true);
inp.addParamValue('SMethod', 'boundary');
inp.addParamValue('SRadius', 1);
inp.addParamValue('TMethod', 'none')
inp.addParamValue('TValue', [], checkthresh)
inp.addParamValue('TRatio', [], @(t) isempty(t) || ...
    checkattributes(t, {'numeric'}, ...
    {'nonnan' 'real' 'nonnegative' 'scalar' '<=' 1}));
inp.addParamValue('TConn', []);
inp.addParamValue('SubPixel', false);
inp.parse(varargin{:});

sigma = inp.Results.sigma;
if isempty(sigma)
    sigma = sqrt(2);        % default for IPT edge function
end

% smoothing
g = gradients_n(im, sigma, ...
    'Region', inp.Results.Region, 'Centred', inp.Results.Centred);

% non-maximum suppression
[e, gMag] = nonmaxSuppress(g, 'Method', inp.Results.SMethod, ...
    'Radius', inp.Results.SRadius, 'SubPixel', inp.Results.SubPixel);

% correct for offset if sub-pixel estimate with offset gradients
if inp.Results.SubPixel && ~inp.Results.Centred
    e.subpix = cellfun(@(a) a-0.5, e.subpix, 'UniformOutput', false);
end

% hysteresis thresholding
[tmeth, thresh, tratio, tconn] = threshargs(inp);

if ~strcmp(tmeth, 'none')
    thresh = findThreshold(gMag, tmeth, thresh, tratio);
    if inp.Results.SubPixel
        e.edge = hystThresh(e.edge, gMag, thresh, tconn);
    else
        e = hystThresh(e, gMag, thresh, tconn);
    end
end

end


function [tmeth, thresh, tratio, tconn] = threshargs(inp)
% Sort out threshold argument and name-value pairs

if ~ismember('thresh', inp.UsingDefaults)    % simple threshold argument

    if ~all(ismember({'TMethod' 'TValue' 'TRatio' 'TConn'}, ...
            inp.UsingDefaults))
        error('DavidYoung:canny:threshargs', ...
            'Threshold name-value pairs used with threshold argument');
    end
    thresh = inp.Results.thresh;
    if isempty(thresh)
        % defaults as per IPT edge function
        tmeth = 'histogram';
        thresh = 0.7;
        tratio = 0.4;
    else
        % interpret consistently with IPT edge function
        tmeth = 'relMax';
        if isscalar(thresh)
            tratio = 0.4;
        else
            tratio = [];
        end
    end
    tconn = {};
    
else                                    % name-value pairs
    
    tmeth = inp.Results.TMethod;
    thresh = inp.Results.TValue;
    tratio = inp.Results.TRatio;
    tconn = inp.Results.TConn;
    
    if ~strcmp(tmeth, 'none') && isempty(thresh)
        error('DavidYoung:canny:noThresholdValue', ...
            'Threshold method set but no threshold value');
    end
    
end

end


function t = findThreshold(g, method, val, tratio)
% Returns a threshold value for edge detection

switch method
    case 'absolute'
        t = val;
    case 'relMax'
        t = val * max(g(:));
    case 'histogram'
        if ~isscalar(val)
            error('DavidYoung:canny:lowThreshHistogram', ...
                'Low threshold set explicitly with histogram option');
        end
        t = fractile(g, val);
    otherwise
        error('DavidYoung:canny:badThreshMethod', ...
            'Unknown threshold method %s', method);
end

if ~isempty(tratio)
    if isscalar(t)
        t = [tratio*t t];
    else
        error('DavidYoung:canny:redundantThresholds', ...
            'Ratio and low and high thresholds all specified');
    end
end

end
