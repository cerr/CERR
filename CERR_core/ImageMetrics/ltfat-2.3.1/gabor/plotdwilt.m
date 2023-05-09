function C=plotdwilt(coef,varargin)
%-*- texinfo -*-
%@deftypefn {Function} plotdwilt
%@verbatim
%PLOTDWILT  Plot DWILT coefficients
%   Usage: plotdwilt(coef);
%          plotdwilt(coef,fs);
%          plotdwilt(coef,fs,dynrange);
%
%   PLOTDWILT(coef) will plot coefficients from DWILT.
%
%   PLOTDWILT(coef,fs) will do the same assuming a sampling rate of fs*
%   Hz of the original signal. Since a Wilson representation does not
%   contain coefficients for all positions on a rectangular TF-grid, there
%   will be visible 'holes' among the lowest (DC) and highest (Nyquist rate)
%   coefficients. See the help on WIL2RECT.
%
%   PLOTDWILT(coef,fs,dynrange) will additionally limit the dynamic
%   range.
%
%   C=PLOTDWILT(...) returns the processed image data used in the
%   plotting. Inputting this data directly to imagesc or similar
%   functions will create the plot. This is useful for custom
%   post-processing of the image data.
%   
%   PLOTDWILT supports all the optional parameters of TFPLOT. Please
%   see the help of TFPLOT for an exhaustive list.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/plotdwilt.html}
%@seealso{dwilt, tfplot, sgram, wil2rect}
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

if nargin<1
  error('%s: Too few input parameters.',upper(mfilename));
end;

definput.import={'ltfattranslate','tfplot'};

[flags,kv,fs]=ltfatarghelper({'fs','dynrange'},definput,varargin);

M=size(coef,1)/2;

% Find smallest value in the coefficients, because we will be inserting
% zeros, which messes up the dynamic range. Set a minimum value of the
% dynamic range based on this
maxc=max(abs(coef(:)));
minc=min(abs(coef(:)));
if isempty(kv.dynrange)
  if flags.do_db
    kv.dynrange=20*log10(maxc/minc);
  end;
  if flags.do_dbsq
    kv.dynrange=10*log10(maxc/minc);
  end;
end;

coef=wil2rect(coef);

yr=[0,1];

C=tfplot(coef,M,yr,'argimport',flags,kv);

if nargout<1
    clear C;
end


