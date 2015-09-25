function Y = minmaxfilt3(X,filter,varargin)
%  MAXFILT3    Three-dimensional max filter
%
%     Y = MINMAXFILT3(X,'max',[N1 N2 N3]) performs three-dimensional maximum
%     Y = MINMAXFILT3(X,'min',[N1 N2 N3]) performs three-dimensional minimum
%     filtering on the image X using an N1-by-N2-by-N3 window. The result
%     Y contains the maximun value in the N1-by-N2-by-N3 neighborhood around
%     each pixel in the original image. 
%     This function uses the van Herk algorithm for max filters.
%
%     Y = MINMAXFILT3(X,M) is the same as Y = MINMAXFILT3(X,[M M M])
%
%     Y = MINMAXFILT3(X) uses a 3-by-3-by-3 neighborhood.
%
%     Y = MINMAXFILT3(..., 'shape') returns a subsection of the 3D
%     filtering specified by 'shape' :
%        'full'  - Returns the full filtering result,
%        'same'  - (default) Returns the central filter area that is the
%                   same size as X,
%        'valid' - Returns only the area where no filter elements are outside
%                  the image.
%
%     See also : MINFILT2, VANHERK
%

% Initialization
[S, shape] = parse_inputs(varargin{:});

% filtering
dim = size(X);
for k=1:dim(3);
	im=squeeze(X(:,:,k));
	im = vanherk(im,S(1),filter,shape);
	im = vanherk(im,S(2),filter,'col',shape);
	X2(:,:,k) = im;
end

if dim(3) < S(3)
    f = str2func(filter);
    im = f(X2,[],3);
    for k=1:dim(3)
        Y(:,:,k) = im;
    end
else
    dim = size(X2);
    for k=1:dim(2);
        im = squeeze(X2(:,k,:));
        im = vanherk(im,S(3),filter,shape);
        Y(:,:,k) = im;
    end
    Y = permute(Y,[1 3 2]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [S, shape] = parse_inputs(varargin)
shape = 'same';
flag = [0 0]; % size shape

for i = 1 : nargin
   t = varargin{i};
   if strcmp(t,'full') & flag(2) == 0
      shape = 'full';
      flag(2) = 1;
   elseif strcmp(t,'same') & flag(2) == 0
      shape = 'same';
      flag(2) = 1;
   elseif strcmp(t,'valid') & flag(2) == 0
      shape = 'valid';
      flag(2) = 1;
   elseif flag(1) == 0
      S = t;
      flag(1) = 1;
   else
      error(['Too many / Unkown parameter : ' t ])
   end
end

if flag(1) == 0
   S = [3 3 3];
end
if length(S) == 1;
   S(2) = S(1); S(3) = S(1);
end
if length(S) ~= 3
   error('Wrong window size parameter.')
end

