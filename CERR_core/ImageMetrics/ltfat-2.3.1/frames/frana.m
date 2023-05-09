function outsig=frana(F,insig);
%-*- texinfo -*-
%@deftypefn {Function} frana
%@verbatim
%FRANA  Frame analysis operator
%   Usage: c=frana(F,f);
%
%   c=FRANA(F,f) computes the frame coefficients c of the input
%   signal f using the frame F. The frame object F must have been
%   created using FRAME or FRAMEPAIR.
%
%   If f is a matrix, the transform will be applied along the columns
%   of f. If f is an N-D array, the transform will be applied along
%   the first non-singleton dimension.
%
%   The output coefficients are stored as columns. This is usually
%   *not* the same format as the 'native' format of the frame. As an
%   examples, the output from FRANA for a gabor frame cannot be
%   passed to IDGT without a reshape.
%
%   Examples:
%   ---------
%
%   In the following example the signal bat is analyzed through a wavelet 
%   frame. The result are the frame coefficients associated with the input  
%   signal bat and the analysis frame 'fwt':
%
%      f = bat;
%      w = 'sym8';
%      J = 7;
%      F = frame('fwt', w, J); 
%      c = frana(F, f);
%      % A plot of the frame coefficients
%      plotframe(F, c, 'dynrange', 100);
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/frames/frana.html}
%@seealso{frame, framepair, frsyn, plotframe}
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

complainif_notenoughargs(nargin,2,'FRANA');
complainif_notvalidframeobj(F,'FRANA');

if size(insig,1) == 1
    error('%s: Currently only column vectors are supported. See bug #59.',...
          upper(mfilename));    
end


%% ----- step 1 : Verify f and determine its length -------
% Change f to correct shape.
[insig,~,Ls,W,dim,permutedsize,order]=assert_sigreshape_pre(insig,[],[],upper(mfilename));
 
F=frameaccel(F,Ls);

insig=postpad(insig,F.L);

%% ----- do the computation ----

outsig=F.frana(insig);

%% --- cleanup -----

permutedsize=[size(outsig,1),permutedsize(2:end)];

outsig=assert_sigreshape_post(outsig,dim,permutedsize,order);

  

