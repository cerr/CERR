function C = plotwavelets(c,info,varargin)
%-*- texinfo -*-
%@deftypefn {Function} plotwavelets
%@verbatim
%PLOTWAVELETS  Plot wavelet coefficients
%   Usage:  plotwavelets(c,info,fs) 
%           plotwavelets(c,info,fs,'dynrange',dynrange,...)
%
%   PLOTWAVELETS(c,info) plots the wavelet coefficients c using
%   additional parameters from struct. info. Both parameters are returned
%   by any forward transform function in the wavelets directory.
%
%   PLOTWAVELETS(c,info,fs) does the same plot assuming a sampling rate
%   fs Hz of the original signal.
%
%   plowavelets(c,info,fs,'dynrange',dynrange) additionally limits the 
%   dynamic range.
%
%   C=PLOTWAVELETS(...) returns the processed image data used in the
%   plotting. Inputting this data directly to imagesc or similar functions
%   will create the plot. This is usefull for custom post-processing of the
%   image data.
%
%   PLOTWAVELETS supports optional parameters of TFPLOT. Please see
%   the help of TFPLOT for an exhaustive list.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/plotwavelets.html}
%@seealso{fwt, tfplot, complainif_notenoughargs(nargin,2,'plotwavelets');}
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

if isempty(c) || ~(iscell(c) || isnumeric(c))
    error('%s: c must be non-empty cell or numeric array.',upper(mfilename));
end

if ~isstruct(info) || ~isfield(info,'fname')
    error(['%s: info must be struct obtained as the 2nd return param. ',... 
           'of the comp. routine.'],upper(mfilename));
end
    
definput.import={'tfplot'};
definput.flags.fwtplottype = {'tfplot','stem'};
definput.keyvals.fs = [];
definput.keyvals.dynrange = [];
[flags,kv]=ltfatarghelper({'fs','dynrange'},definput,varargin);

if(flags.do_stem)
   error('%s: Flag %s not supported yet.',upper(mfilename),flags.fwtplottype);
end

switch info.fname
    case {'ufwt','uwfbt','uwpfbt'}
       % Only one channel signals can be plotted.
       if(ndims(c)>2)
          error('%s: Multichannel not supported.',upper(mfilename));
       end  
    case {'wfbt','dtwfbreal','dtwfb','wpfbt'}
        if any(cellfun(@(cEl) size(cEl,2)>1,c))
          error('%s: Multichannel input not supported.',upper(mfilename));
       end
end

maxSubLen = 800;
draw_ticks = 1;

switch info.fname
    case 'fwt'
    %% FWT plot
       % Change to the cell format
       if(isnumeric(c))
           c = wavpack2cell(c,info.Lc,info.dim);
       end
       maxSubLen = max(info.Lc);

       % Only one channel signals can be plotted.
       if(size(c{1},2)>1)
          error('%s: Multichannel input not supported.',upper(mfilename));
       end

       subbNo = numel(c);
       w = fwtinit(info.wt);
       aBase = w.a;
       filtNo = numel(w.h);
       J = info.J;
       a = [aBase(1).^J, reshape(aBase(2:end)*aBase(1).^(J-1:-1:0),1,[])]';
    case 'ufwt'
       subbNo = size(c,2);
       a = ones(subbNo,1);

       w = fwtinit(info.wt);
       filtNo = numel(w.h);
       J = info.J; 
    case {'wfbt','dtwfbreal','dtwfb'}
       maxSubLen = max(cellfun(@(cEl) size(cEl,1),c));
       a = treeSub(info.wt);
       subbNo = numel(c);
       draw_ticks = 0;
    case 'uwfbt'
       subbNo = size(c,2);
       a = ones(subbNo,1);
       draw_ticks = 0;
    case 'wpfbt'
       maxSubLen = max(cellfun(@(cEl) size(cEl,1),c));
       aCell = nodesSub(nodeBForder(0,info.wt),info.wt);
       a = cell2mat(cellfun(@(aEl) aEl(:)',aCell,'UniformOutput',0));
       draw_ticks = 0;
    case 'uwpfbt'
       subbNo = size(c,2);
       a = ones(subbNo,1);
       draw_ticks = 0;
    otherwise
       error('%s: Unknown function name %s.',upper(mfilename),info.fname);
end

% POST optional operations
switch info.fname
    case 'dtwfb'
        % Do subband equivalent of fftshift
        [c(1:end/2), c(end/2+1:end)] = deal( c(end/2+1:end), c(1:end/2));
        a = [a(end:-1:1);a];
end

% Use plotfilterbank
C=plotfilterbank(c,a,[],kv.fs,kv.dynrange,flags.plottype,...
  flags.log,flags.colorbar,flags.display,'fontsize',kv.fontsize,'clim',kv.clim,'xres',min([maxSubLen,800]));

if(draw_ticks)
   % Redo the yticks and ylabel
   yTickLabels = cell(1,subbNo);
   yTickLabels{1} = sprintf('a%d',J);
   Jtmp = ones(filtNo-1,1)*(J:-1:1);
   for ii=1:subbNo-1
      yTickLabels{ii+1} = sprintf('d%d',Jtmp(ii));
   end

   ylabel('Subbands','fontsize',kv.fontsize);
   set(gca,'ytick',1:subbNo);
   set(gca,'ytickLabel',yTickLabels,'fontsize',kv.fontsize);
end

% To avoid printing all the coefficients in the command window when a
% semicolon is forgotten
if nargout < 1
    clear C;
end



