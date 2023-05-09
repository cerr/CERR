function coef=tfplot(coef,step,yr,varargin)
%-*- texinfo -*-
%@deftypefn {Function} tfplot
%@verbatim
%TFPLOT  Plot coefficient matrix on the TF plane
%   Usage: tfplot(coef,step,yr);
%          tfplot(coef,step,yr,...);
%
%   TFPLOT(coef,step,yr) will plot a rectangular coefficient array on the
%   TF-plane. The shift in samples between each column of coefficients is
%   given by the variable step. The vector yr is a 1 x2 vector
%   containing the lowest and highest normalized frequency.
%
%   C=TFPLOT(...) returns the processed image data used in the
%   plotting. Inputting this data directly to imagesc or similar
%   functions will create the plot. This is usefull for custom
%   post-processing of the image data.
%
%   TFPLOT is not meant to be called directly. Instead, it is called by
%   other plotting routines to give a uniform display format. 
%
%   TFPLOT (and all functions that call it) takes the following arguments.
%
%     'dynrange',r
%              Limit the dynamical range to r by using a colormap in
%              the interval [chigh-r,chigh], where chigh is the highest
%              value in the plot. The default value of [] means to not
%              limit the dynamical range.
%
%     'db'     Apply 20*log_{10} to the coefficients. This makes 
%              it possible to see very weak phenomena, but it might show 
%              too much noise. A logarithmic scale is more adapted to 
%              perception of sound. This is the default.
%
%     'dbsq'   Apply 10*log_{10} to the coefficients. Same as the
%              'db' option, but assume that the input is already squared.  
%
%     'lin'    Show the coefficients on a linear scale. This will
%              display the raw input without any modifications. Only works for
%              real-valued input.
%
%     'linsq'  Show the square of the coefficients on a linear scale.
%
%     'linabs'  Show the absolute value of the coefficients on a linear scale.
%
%     'tc'     Time centering. Move the beginning of the signal to the
%              middle of the plot. 
%
%     'clim',clim   Use a colormap ranging from clim(1) to clim(2). These
%                   values are passed to imagesc. See the help on imagesc.
%
%     'image'       Use imagesc to display the plot. This is the default.
%
%     'contour'     Do a contour plot.
%          
%     'surf'        Do a surf plot.
%
%     'colorbar'    Display the colorbar. This is the default.
%
%     'nocolorbar'  Do not display the colorbar.
%
%     'display'     Display the figure. This is the default.
%
%     'nodisplay'   Do not display figure. This is usefull if you only
%                   want to obtain the output for further processing.
%
%   If both 'clim' and 'dynrange' are specified, then 'clim' takes
%   precedence.
%
%   It is possible to customize the text by setting the following values:
%
%     'time', t       The word denoting time. Default is 'Time'
%
%     'frequency',f   The word denoting frequency. Default is 'Frequency'
%  
%     'samples',s     The word denoting samples. Default is 'samples'
%  
%     'normalized',n  Defult value is 'normalized'.
%  
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/tfplot.html}
%@seealso{sgram, plotdgt, plotdgtreal, plotwmdct, plotdwilt}
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

if nargin<2
  error('%s: Too few input parameters.',upper(mfilename));
end;

definput.import={'ltfattranslate','tfplot'};
[flags,kv,fs]=ltfatarghelper({'fs','dynrange'},definput,varargin);

M=size(coef,1);
N=size(coef,2);

if size(coef,3)>1
  error('Input is multidimensional.');
end;

% Apply transformation to coefficients.
if flags.do_db
  coef=20*log10(abs(coef)+realmin);
end;

if flags.do_dbsq
  coef=10*log10(abs(coef)+realmin);
end;

if flags.do_linsq
  coef=abs(coef).^2;
end;

if flags.do_linabs
  coef=abs(coef);
end;

if flags.do_lin
  if ~isreal(coef)
    error(['Complex valued input cannot be plotted using the "lin" flag.',...
           'Please use the "linsq" or "linabs" flag.']);
  end;
end;
  
% 'dynrange' parameter is handled by converting it into clim
% clim overrides dynrange, so do nothing if clim is already specified
if  ~isempty(kv.dynrange) && isempty(kv.clim)
  maxclim=max(coef(:));
  kv.clim=[maxclim-kv.dynrange,maxclim];
end;

% Handle clim by thresholding and cutting
if ~isempty(kv.clim)
  coef(coef<kv.clim(1))=kv.clim(1);
  coef(coef>kv.clim(2))=kv.clim(2);
end;
  
if flags.do_tc
  xr=(-floor(N/2):floor((N-1)/2))*step;
  coef=fftshift(coef,2);
else
  xr=(0:N-1)*step;
end;


if flags.do_display
    if ~isempty(kv.fs)
        xr=xr/kv.fs;
        yr=yr*fs/2;
    end;
    
    % Convert yr to range of values
    yr=linspace(yr(1),yr(2),M);
        
    switch(flags.plottype)
      case 'image'
        % Call imagesc explicitly with clim. This is necessary for the
        % situations where the data (is by itself limited (from above or
        % below) to within the specified range. Setting clim explicitly
        % avoids the colormap moves in the top or bottom.
        if isempty(kv.clim)
            imagesc(xr,yr,coef);
        else
            imagesc(xr,yr,coef,kv.clim);
        end;
      case 'contour'
        contour(xr,yr,coef);
      case 'surf'
        surf(xr,yr,coef,'EdgeColor','none');
      case 'pcolor'
        pcolor(xr,yr,coef);
    end;
    
    if flags.do_colorbar
        colorbar;
        if ~isempty(kv.colormap)
            colormap(kv.colormap); 
        end
    end;
    
    axis('xy');
    if ~isempty(kv.fs)
        xlabel(sprintf('%s (s)',kv.time));
        ylabel(sprintf('%s (Hz)',kv.frequency));
    else
        xlabel(sprintf('%s (%s)',kv.time,kv.samples));
        ylabel(sprintf('%s (%s)',kv.frequency,kv.normalized));
    end;
    
end;

if nargout<1
    clear coef;
end

