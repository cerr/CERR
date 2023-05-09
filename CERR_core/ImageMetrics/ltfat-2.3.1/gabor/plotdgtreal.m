function coef=plotdgtreal(coef,a,M,varargin)
%-*- texinfo -*-
%@deftypefn {Function} plotdgtreal
%@verbatim
%PLOTDGTREAL  Plot DGTREAL coefficients
%   Usage: plotdgtreal(coef,a,M);
%          plotdgtreal(coef,a,M,fs);
%          plotdgtreal(coef,a,M,fs,dynrange);
%
%   PLOTDGTREAL(coef,a,M) plots Gabor coefficient from DGTREAL. The
%   parameters a and M must match those from the call to DGTREAL.
%
%   PLOTDGTREAL(coef,a,M,fs) does the same assuming a sampling rate of fs*
%   Hz of the original signal.
%
%   PLOTDGTREAL(coef,a,M,fs,dynrange) additionally limits the dynamic
%   range.
%
%   C=PLOTDGTREAL(...) returns the processed image data used in the
%   plotting. Inputting this data directly to imagesc or similar
%   functions will create the plot. This is usefull for custom
%   post-processing of the image data.
%
%   PLOTDGTREAL supports all the optional parameters of TFPLOT. Please
%   see the help of TFPLOT for an exhaustive list.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/plotdgtreal.html}
%@seealso{dgtreal, tfplot, sgram, plotdgt}
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

%   AUTHOR : Peter L. Soendergaard.
%   TESTING: NA
%   REFERENCE: NA

complainif_notenoughargs(nargin,3,mfilename);
complainif_notposint(a,'a',mfilename);
complainif_notposint(M,'M',mfilename);

definput.import={'ltfattranslate','tfplot'};

[flags,kv,fs]=ltfatarghelper({'fs','dynrange'},definput,varargin);

if rem(M,2)==0
  yr=[0,1];
else
  yr=[0,1-2/M];
end;

coef=tfplot(coef,a,yr,'argimport',flags,kv);

if nargout<1
    clear coef;
end

