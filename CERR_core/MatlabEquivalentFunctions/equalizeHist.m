function [out, T] = equalizeHist(a,cm,hgram)
% Function for image histogram equalization.

% Parameter setup
NPTS = 256;
isIntensityImage = false;

if nargin == 1
    %HISTEQ(I)
    validateattributes(a,{'uint8','uint16','double','int16','single'}, ...
        {'nonsparse'}, mfilename,'I',1);
    n = 64; % Default n
    hgram = ones(1,n)*(numel(a)/n);
    n = NPTS;
    isIntensityImage = true;
elseif nargin == 2
    if numel(cm) == 1
        %HISTEQ(I,N)
        validateattributes(a,{'uint8','uint16','double','int16','single'}, ...
            {'nonsparse'}, mfilename,'I',1);
        validateattributes(cm, {'single','double'},...
            {'nonsparse','integer','real','positive','scalar'},...
            mfilename,'N',2);
        m = cm;
        hgram = ones(1,m)*(numel(a)/m);
        n = NPTS;
        isIntensityImage = true;
    elseif size(cm,2) == 3 && size(cm,1) > 1
        %HISTEQ(X,map)        
        if isa(a, 'uint16')
            error(message('images:histeq:unsupportedUint16IndexedImages'))
        end
        validateattributes(a,{'uint8','double','single'}, ...
            {'nonsparse'},mfilename,'X',1);        
        n = size(cm,1);
        hgram = ones(1,n)*(numel(a)/n);
    else
        %HISTEQ(I,HGRAM)
        validateattributes(a,{'uint8','uint16','double','int16','single'}, ...
            {'nonsparse'}, mfilename,'I',1);
        validateattributes(cm, {'single','double'},...
            {'real','nonsparse','vector','nonempty'},...
            mfilename,'HGRAM',2);
        hgram = cm;
        n = NPTS;
        isIntensityImage = true;
    end
else
    %HISTEQ(X,MAP,HGRAM)
    validateattributes(a,{'uint8','double','uint16','single'}, ...
        {'nonsparse'},mfilename,'X',1);
    if isa(a, 'uint16')
        error(message('images:histeq:unsupportedUint16IndexedImages'))
    end
    validateattributes(hgram, {'single','double'},...
            {'real','nonsparse','vector','nonempty'},...
            mfilename,'HGRAM',3);
    
    n = size(cm,1);
    if length(hgram)~=n
        error(message('images:histeq:HGRAMmustBeSameSizeAsMAP'))
    end
end

if min(size(hgram)) > 1
   error(message('images:histeq:hgramMustBeAVector'))
end

% Normalize hgram
hgram = hgram*(numel(a)/sum(hgram));       % Set sum = numel(a)
m = length(hgram);

% Intensity image or indexed image
if isIntensityImage
    classChanged = false;
    if isa(a,'int16')
        classChanged = true;
        a = im2uint16(a);
    end
    
    [nn,cum] = computeCumulativeHistogram(a,n);
    T = createTransformationToIntensityImage(a,hgram,m,n,nn,cum);
    
    b = grayxform(a, T);
 
    if nargout == 0
        if ismatrix(b)
            imshow(b);
            return;
        else
            out = a;
            return;
        end
    elseif classChanged
        out = im2int16(b);
    else
        out = b;
    end
        
else
    I = ind2gray(a,cm);
    [nn,cum] = computeCumulativeHistogram(I,n);
    T = createTransformationToIntensityImage(a,hgram,m,n,nn,cum);
    
    % Modify colormap by extending the (r,g,b) vectors.
    % Compute equivalent colormap luminance
    ntsc = rgb2ntsc(cm);
    
    % Map to new luminance using T, store in 2nd column of ntsc.
    ntsc(:,2) = T(floor(ntsc(:,1)*(n-1))+1)';
    
    % Scale (r,g,b) vectors by relative luminance change
    map = cm.*((ntsc(:,2)./max(ntsc(:,1),eps))*ones(1,3));
    
    % Clip the (r,g,b) vectors to the unit color cube
    map = map ./ (max(max(map,[],2),1) *ones(1,3));
    
    if nargout == 0
        if ndims(a)==2
            imshow(a,map);
            return;
        else
            out = a;
            return;
        end
    else
        out = map;
    end
end


function [nn,cum] = computeCumulativeHistogram(img,nbins)

nn = imhist(img,nbins)';
cum = cumsum(nn);

end

function T = createTransformationToIntensityImage(a,hgram,m,n,nn,cum)
% Create transformation to an intensity image by minimizing the error
% between desired and actual cumulative histogram.

% Generate cumulative hgram
cumd = cumsum(hgram);

% Calc error
% tol = nn w/ 1st and last element set to 0, then divide by 2 and tile to MxN
tol = ones(m,1)*min([nn(1:n-1),0;0,nn(2:n)])/2;
% Calculate errors btw cumulative histograms
err = (cumd(:)*ones(1,n)-ones(m,1)*cum(:)')+tol;

% Find which combo yielded errors above tolerance
d = find(err < -numel(a)*sqrt(eps));
if ~isempty(d)
    % Set to max err
   err(d) = numel(a)*ones(size(d));
end

% Get min error
% T will be the bin mapping of a to hgram
% T(oldbinval) = newbinval
[dum,T] = min(err); %#ok
% Normalize T
T = (T-1)/(m-1);

end


end