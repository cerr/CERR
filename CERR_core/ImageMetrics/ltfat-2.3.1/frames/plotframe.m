function outsig=plotframe(F,insig,varargin)
%-*- texinfo -*-
%@deftypefn {Function} plotframe
%@verbatim
%PLOTFRAME  Plot frame coefficients
%   Usage: plotframe(F,c,…);
%          C = plotframe(...);
%
%   PLOTFRAME(F,c) plots the frame coefficients c using the plot
%   command associated to the frame F.
%
%   C=PLOTFRAME(...) for frames with time-frequency plots returns the
%   processed image data used in the plotting. The function produces an
%   error for frames which does not have a time-frequency plot.
%
%   PLOTFRAME(F,c,...) passes any additional parameters to the native
%   plot routine. Please see the help on the specific plot routine for a
%   complete description. 
%
%   The following common set of parameters are supported by all plotting
%   routines:
%
%     'dynrange',r
%              Limit the dynamical range to r. The default value of []
%              means to not limit the dynamical range.
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
%     'clim',clim
%              Only show values in between clim(1) and clim(2). This
%              is usually done by adjusting the colormap. See the help on imagesc.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/frames/plotframe.html}
%@seealso{frame, frana}
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

complainif_notenoughargs(nargin,2,'PLOTFRAME');
complainif_notvalidframeobj(F,'PLOTFRAME');

switch(F.type)
   case {'dft','dftreal','dcti','dctii','dctiii','dctiv',...
         'dsti','dstii','dstiii','dstiv'}
      if nargout>0
          error(['%s: Plot function of %s frame does not produce a ',...
                 'TF image'],upper(mfilename),F.type);
      end
end;

switch(F.type)
   case {'fwt','ufwt','wfbt','wpfbt','uwfbt','uwpfbt'}
      info.fname = F.type;
      info.wt = F.g;
end;

switch(F.type)
 case 'dgt'
  outsig = plotdgt(framecoef2native(F,insig),F.a,varargin{:}); 
 case 'dgtreal'
  outsig = plotdgtreal(framecoef2native(F,insig),F.a,F.M,varargin{:}); 
 case 'dwilt'
  outsig = plotdwilt(framecoef2native(F,insig),varargin{:}); 
 case 'wmdct'
  outsig = plotwmdct(framecoef2native(F,insig),varargin{:});
 case 'gen'
  error(['%s: There is no default way of visualizing general frame ' ...
         'coefficients.'],upper(mfilename));
 case 'dft'
  plotfft(insig,varargin{:});
 case 'dftreal'
  plotfftreal(insig, varargin{:});
 case {'dcti','dctii','dctiii','dctiv',...
       'dsti','dstii','dstiii','dstiv'}
  % FIXME : This is not strictly correct, as half the transforms use an
  % odd frequency centering.
  plotfftreal(insig,varargin{:});
 case 'fwt'
    info.Lc = fwtclength(size(insig,1)/F.red,F.g,F.J);
    info.J = F.J;
    info.dim = 1;
    plotwavelets(insig,info,varargin{:});  
 case 'fusion'
    idxaccum = 1;
    L = framelengthcoef(F,numel(insig));
    for p = 1:numel(F.frames)
        atno = frameclength(F.frames{p},L);
        figure(p);
        plotframe(F.frames{p},insig(idxaccum:idxaccum+atno-1),varargin{:});
        idxaccum = idxaccum + atno;
    end
 case 'ufwt'
    info.J = F.J;
    outsig = plotwavelets(framecoef2native(F,insig),info,varargin{:}); 
 case {'wfbt','wpfbt'}
    outsig = plotwavelets(framecoef2native(F,insig),info,varargin{:}); 
 case {'uwfbt','uwpfbt'}
    outsig = plotwavelets(framecoef2native(F,insig),info,varargin{:}); 
 case {'filterbank','filterbankreal','ufilterbank','ufilterbankreal'}
    outsig = plotfilterbank(framecoef2native(F,insig),F.a,[],varargin{:});
end;

if nargout<1
    clear outsig;
end

  

