function cola=blockplot(p,arg0,arg1,cola)
%-*- texinfo -*-
%@deftypefn {Function} blockplot
%@verbatim
%BLOCKPLOT Plot block coefficients
%   Usage: blockplot(p,c);
%          blockplot(p,F,c);
%          blockplot(p,F,c,cola);
%
%   Input parameters:
%         p     : JAVA object of the class net.sourceforge.ltfat.SpectFrame.
%         F     : Frame object.
%         c     : Block coefficients.
%         cola  : (Optional) overlap from previous block.
%
%   Output parameters:
%         cola  : Overlap to the next block.
%
%   BLOCKPLOT(p,F,c) appends the block coefficients c to the running 
%   coefficient plot in p. The coefficients must have been obtained by
%   c=blockana(F,...). The format of c is changed to a rectangular 
%   layout according to the type of F. p must be a Java object with a
%   append method.  
%
%   cola=BLOCKPLOT(p,F,c,cola) does the same, but adds cola to the 
%   first respective coefficients in c and returns last coefficients from
%   c. This is only relevant for the sliced window blocking approach.
%
%   BLOCKPLOT(p,c) or BLOCKPLOT(p,[],c) does the same, but expects c 
%   to be already formatted matrix of real numbers. The data dimensions
%   are not restricted, but it will be shrinked or expanded to fit with
%   the running plot.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/blockproc/blockplot.html}
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

complainif_notenoughargs(nargin,2,'BLOCKPLOT');

if ~isempty(arg0) && isstruct(arg0) && isfield(arg0,'frana')
    F = arg0;
    c = arg1;
    complainif_notenoughargs(nargin,3,'BLOCKPLOT');
    complainif_notvalidframeobj(F,'BLOCKPLOT');
    if size(c,2)>1
        error('%s: Only one channel input is supported.',upper(mfilename));
    end
    
    ctf = framecoef2tfplot(F,c(:,1));

    if strcmp(F.blockalg,'sliced')
       % DO the coefficient overlapping or cropping
       %ctf = ctf(:,floor(end*3/8):floor(end*5/8)+1);

       if nargin>3 
          olLen = ceil(size(ctf,2)/2);
          if isempty(cola)
             cola = zeros(size(ctf,1),olLen,class(ctf));
          end

          ctf(:,1:olLen) = ctf(:,1:olLen) + cola;
          cola = ctf(:,end+1-olLen:end);
          ctf = ctf(:,1:olLen);
       end
    end
    
    ctf = abs(ctf);
else
    if ~isempty(arg0)
        c = arg0;
    elseif nargin>2
        c = arg1;
    else
        error('%s: Not enough input arguments',upper(mfilename));
    end
    if ~isreal(c)
        error('%s: Complex values are not supported',upper(mfilename));
    end
    ctf = c;
end

if isoctave
   % The JAVA 2D-array handling is row-major
   ctf = cast(ctf,'double').';
   javaMethod('append',p,ctf(:),size(ctf,2),size(ctf,1));
else
   % Matlab casts correctly
   ctf = cast(ctf,'single');
   javaMethod('append',p,ctf);
end



