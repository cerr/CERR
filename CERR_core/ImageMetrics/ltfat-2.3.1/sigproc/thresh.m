function [xo,N]=thresh(xi,lambda,varargin);
%-*- texinfo -*-
%@deftypefn {Function} thresh
%@verbatim
%THRESH   Coefficient thresholding
%   Usage:  x=thresh(x,lambda,...);
%           [x,N]=thresh(x,lambda,...);
%
%   THRESH(x,lambda) will perform hard thresholding on x, i.e. all
%   elements with absolute value less than scalar lambda will be set to zero.
%
%   THRESH(x,lambda,'soft') will perform soft thresholding on x,
%   i.e. lambda will be subtracted from the absolute value of every element
%   of x.
%
%   The lambda parameter can also be a vector with number of elements
%   equal to numel(xi) or it can be a numeric array of the same shape 
%   as xi. lambda is then applied element-wise and in a column major 
%   order if lambda is a vector. 
%
%   [x,N]=THRESH(x,lambda) additionally returns a number N specifying
%   how many numbers where kept.
%
%   THRESH takes the following flags at the end of the line of input
%   arguments:
%
%     'hard'    Perform hard thresholding. This is the default.
%
%     'wiener'  Perform empirical Wiener shrinkage. This is in between
%               soft and hard thresholding.
%
%     'soft'    Perform soft thresholding.  
%
%     'full'    Returns the output as a full matrix. This is the default.
%
%     'sparse'  Returns the output as a sparse matrix.
%
%   The function wTHRESH in the Matlab Wavelet toolbox implements some of
%   the same functionality.
%
%   The following code produces a plot to demonstrate the difference
%   between hard and soft thresholding for a simple linear input:
%
%     t=linspace(-4,4,100);
%     plot(t,thresh(t,1,'soft'),'r',...
%          t,thresh(t,1,'hard'),'.b',...
%          t,thresh(t,1,'wiener'),'--g');
%     legend('Soft thresh.','Hard thresh.','Wiener thresh.','Location','NorthWest');
%
%
%   References:
%     S. Ghael, A. Sayeed, and R. Baraniuk. Improved wavelet denoising via
%     empirical Wiener filtering. In Proceedings of SPIE, volume 3169, pages
%     389--399. San Diego, CA, 1997.
%     
%     J. Lim and A. Oppenheim. Enhancement and bandwidth compression of noisy
%     speech. Proceedings of the IEEE, 67(12):1586--1604, 1979.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/sigproc/thresh.html}
%@seealso{largestr, largestn}
%@end deftypefn

% Copyright (C) 2005-2016 Peter L. Soendergaard <peter@sonderport.dk>.
% This file is part of LTFAT version 2.3.1
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

%   AUTHOR : Kai Siedenburg, Bruno Torresani and Peter L. Soendergaard.
%   TESTING: OK
%   REFERENCE: OK

complainif_notenoughargs(nargin,2,'THRESH');

is_sameshape = ndims(lambda)==ndims(xi) && all(size(lambda)==size(xi));

if ~isnumeric(lambda) || ...
   ~isscalar(lambda) && ... % lambda is not scalar
   numel(lambda)~=numel(xi) && ... % lambda does not have the same number of elements
   ~(is_sameshape)    % lambda does not have the same shape
  error(['%s: lambda must be a scalar, a vector with ',...
         'numel(lambda)==numel(xi) or whatever shape xi has such that ',...
         'all(size(lambda)==size(xi))'],upper(mfilename));
end;

% Define initial value for flags and key/value pairs.
definput.import={'thresh'};
[flags,keyvals]=ltfatarghelper({},definput,varargin);

if flags.do_sparse
  if ndims(xi)>2
    error(['%s: Sparse output is only supported for 1D/2D input. This ',...
           'is a limitation of Matlab/Octave.'],upper(mfilename));
  end;
  if ~isa(xi,'double')
      error(['%s: Input is not double prec. data array and sparse output can,'...
             'be double precision data type only. This is a ',... 
             'Matlab/Octave limitation.'],upper(mfilename));
  end
end;

% Reshape lambda if it is a vector
if ~is_sameshape && ~isscalar(lambda)
    lambda = reshape(lambda,size(xi));
end

if flags.do_sparse
    
  xo=sparse(size(xi,1),size(xi,2));
  
  if flags.do_hard
     if isscalar(lambda)  
        % Create a significance map pointing to the non-zero elements.
        signifmap=find(abs(xi)>=lambda);
     else
        signifmap=abs(xi)>=lambda; 
     end  
      
     xo(signifmap)=xi(signifmap); 
  else
      if isscalar(lambda)  
        % Create a significance map pointing to the non-zero elements.
        signifmap=find(abs(xi)>lambda);
     else
        signifmap=abs(xi)>lambda; 
     end  
  
  if flags.do_wiener
    if isscalar(lambda)   
       xo(signifmap) = 1 - (lambda./abs(xi(signifmap))).^2;
    else
       xo(signifmap) = 1 - (lambda(signifmap)./abs(xi(signifmap))).^2;
    end
    xo(signifmap) = xi(signifmap).*xo(signifmap); 
  end;
  
  if flags.do_soft
    if isscalar(lambda) 
      %    xo(signifmap)=xi(signifmap) - sign(xi(signifmap))*lambda;
      xo(signifmap)=(abs(xi(signifmap)) - lambda) .* ...
        exp(i*angle(xi(signifmap)));
    else
      xo(signifmap)=(abs(xi(signifmap)) - lambda(signifmap)) .* ...
        exp(i*angle(xi(signifmap)));
        
    end
    % The line above produces very small imaginary values when the input
    % is real-valued. The next line fixes this
    if isreal(xi)
      xo=real(xo);
    end;
  end;
  end
  
  if nargout==2
    N=numel(signifmap);
  end;
    
else
  % Dense case
  xo=zeros(size(xi),assert_classname(xi));

  % Create a mask with a value of 1 for non-zero elements. For full
  % matrices, this is faster than the significance map.

  if flags.do_hard
    if nargout==2
      mask=abs(xi)>=lambda;
      N=sum(mask(:));
      xo=xi.*mask;
    else
      xo=xi.*(abs(xi)>=lambda);    
    end;
    
  end;
  
  if flags.do_soft
      % In the following lines, the +0 is significant: It turns
      % -0 into +0, oh! the joy of numerics.
      
      if nargout==2
          xa=abs(xi)-lambda;    
          mask=xa>=0;
          xo=(mask.*xa+0).*sign(xi);
          N=sum(mask(:))-sum(xa(:)==0);      
      else
          xa=abs(xi)-lambda;    
          xo=((xa>=0).*xa+0).*sign(xi);
      end;
  end;
  
  if flags.do_wiener
      xa = lambda./abs(xi);
      xa(isinf(xa)) = 0;
      xa = 1 - xa.^2;
      
      if nargout==2
          mask = xa>0;
          xo = xi.*xa.*mask;
          N = sum(mask(:));
      else
          xo = xi.*xa.*(xa>0);
      end
      
  end;
end;


