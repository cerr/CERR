function h=semiaudplot(x,y,varargin)
%-*- texinfo -*-
%@deftypefn {Function} semiaudplot
%@verbatim
%SEMIAUDPLOT  2D plot on auditory scale
%   Usage: h=semiaudplot(x,y);
%
%   SEMIAUDPLOT(x,y) plots the data (x,y) on an auditory scale. By
%   default the values of the x-axis will be shown on the Erb-scale.
%
%   SEMIAUDPLOT takes the following parameters at the end of the line of input
%   arguments:
%
%     'x'       Make the x-axis use the auditory scale. This is the default.
%
%     'y'       Make the y-axis use the auditory scale.
%
%     'opts',c  Pass options stored in a cell array onto the plot
%               function.
%
%   In addition to these parameters, the auditory scale can be
%   specified. All scales supported by FREQTOAUD are supported. The default
%   is to use the erb-scale.     
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/auditory/semiaudplot.html}
%@seealso{freqtoaud}
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

if nargin<2
  error('%s: Too few input parameters.',upper(mfilename));
end;

definput.import       = {'ltfattranslate','freqtoaud'};
definput.flags.plotdir= {'x','y'};
definput.keyvals.tick = [0,100,250,500,1000,2000,4000,8000,16000];
definput.keyvals.res  = 500;
definput.keyvals.opts = {};

[flags,kv]=ltfatarghelper({},definput,varargin);

n=500;
tickpos=freqtoaud(kv.tick,flags.audscale);
    
if flags.do_x
  xmin=min(x);
  xmax=max(x);
  audminmax=freqtoaud([xmin,xmax],flags.audscale);
  
  plotval=spline(x,y,audspace(xmin,xmax,n,flags.audscale));
  plot(linspace(audminmax(1),audminmax(2),n),plotval,kv.opts{:});
  set(gca,'XTick',tickpos);
  set(gca,'XTickLabel',num2str(kv.tick(:)));
  xlabel(sprintf('%s (Hz)',kv.frequency));
 
end;

if flags.do_y
  ymin=min(y);
  ymax=max(y);
  audminmax=freqtoaud([ymin,ymax],flags.audscale);
  
  plot(x,freqtoerb(y),kv.opts{:});
  set(gca,'YTick',tickpos);
  set(gca,'YTickLabel',num2str(tick(:)));
  
  ylabel(sprintf('%s (Hz)',kv.frequency));
end;


