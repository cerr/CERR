function coef = plotnsdgtreal(coef,a,varargin)
%-*- texinfo -*-
%@deftypefn {Function} plotnsdgtreal
%@verbatim
%PLOTNSDGTREAL Plot NSDGTREAL coefficients
%   Usage:  plotnsdgtreal(c,a,fs,dynrange);
%
%   Input parameters:
%         coef     : Cell array of coefficients.
%         a        : Vector of time positions of windows.
%         fs       : signal sample rate in Hz (optional).
%         dynrange : Colorscale dynamic range in dB (optional).
%
%   PLOTNSDGTREAL(coef,a) plots coefficients computed using NSDGTREAL or
%   UNSDGTREAL. For more details on the format of the variables coef and a,
%   please read the function help for these functions.
%
%   PLOTNSDGTREAL(coef,a,fs) does the same assuming a sampling rate of
%   fs Hz of the original signal.
%
%   PLOTNSDGTREAL(coef,a,fs,dynrange) additionally limits the dynamic range.
%
%   C=PLOTNSDGTREAL(...) returns the processed image data used in the
%   plotting. Inputting this data directly to imagesc or similar
%   functions will create the plot. This is useful for custom
%   post-processing of the image data.
%
%   PLOTNSDGTREAL supports all the optional parameters of TFPLOT. Please
%   see the help of TFPLOT for an exhaustive list. In addition, the
%   following parameters may be specified:
%
%     'xres',xres  Approximate number of pixels along x-axis /time.
%                  Default value is 800
%
%     'yres',yres  Approximate number of pixels along y-axis / frequency
%                  Default value is 600
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/nonstatgab/plotnsdgtreal.html}
%@seealso{tfplot, nsdgt, nsdgtreal}
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

%   AUTHOR : Florent Jaillet & Peter L. Soendergaard
%   TESTING: OK 
%   REFERENCE: NA

if nargin<2
  error('%s: Too few input parameters.',upper(mfilename));
end;

definput.import={'ltfattranslate','tfplot'};

definput.keyvals.xres=800;
definput.keyvals.yres=600;

[flags,kv,fs]=ltfatarghelper({'fs','dynrange'},definput,varargin);

timepos=cumsum(a)-a(1);

N=length(a);
cwork=zeros(kv.yres,N);

%% -------- Interpolate in frequency ---------------------

for ii=1:N
  column=coef{ii};
  M=length(column);
  cwork(:,ii)=interp1(linspace(0,1,M),column,linspace(0,1,kv.yres),'nearest');
end;

%% --------  Interpolate in time -------------------------

% Time step in next equidistant spacing on the x-axis (in samples)
aplot=timepos(end)/kv.xres;

% Time positions where we want our pixels plotted (in samples)
xr=(0:kv.xres-1)*aplot;

coef=zeros(kv.yres,kv.xres);
for ii=1:kv.yres
  data=interp1(timepos,cwork(ii,:).',xr,'nearest').';
  coef(ii,:)=data;
end;

yr=[0,1];

coef=tfplot(coef,aplot,yr,'argimport',flags,kv);

if nargout<1
    clear coef;
end

