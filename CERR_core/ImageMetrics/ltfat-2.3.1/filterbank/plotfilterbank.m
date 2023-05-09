function C = plotfilterbank(coef,a,varargin)
%-*- texinfo -*-
%@deftypefn {Function} plotfilterbank
%@verbatim
%PLOTFILTERBANK Plot filterbank and ufilterbank coefficients
%   Usage:  plotfilterbank(coef,a);
%           plotfilterbank(coef,a,fc);
%           plotfilterbank(coef,a,fc,fs);
%           plotfilterbank(coef,a,fc,fs,dynrange);
%
%   PLOTFILTERBANK(coef,a) plots filterbank coefficients coef obtained from
%   either the FILTERBANK or UFILTERBANK functions. The coefficients must
%   have been produced with a time-shift of a. For more details on the
%   format of the variables coef and a, see the help of the FILTERBANK
%   or UFILTERBANK functions.
%
%   PLOTFILTERBANK(coef,a,fc) makes it possible to specify the center
%   frequency for each channel in the vector fc.
%
%   PLOTFILTERBANK(coef,a,fc,fs) does the same assuming a sampling rate of
%   fs Hz of the original signal.
%
%   PLOTFILTERBANK(coef,a,fc,fs,dynrange) makes it possible to specify
%   the dynamic range of the coefficients.
%
%   C=PLOTFILTERBANK(...) returns the processed image data used in the
%   plotting. Inputting this data directly to imagesc or similar
%   functions will create the plot. This is usefull for custom
%   post-processing of the image data.
%
%   PLOTFILTERBANK supports all the optional parameters of TFPLOT. Please
%   see the help of TFPLOT for an exhaustive list.
%
%   In addition to the flags and key/values in TFPLOT, PLOTFILTERBANK
%   supports the following optional arguments:
%
%     'fc',fc       Centre frequencies of the channels. fc must be a vector with
%                   the length equal to the number of channels. The
%                   default value of [] means to plot the channel
%                   no. instead of its frequency.
%
%     'ntickpos',n  Number of tick positions along the y-axis. The
%                   position of the ticks are determined automatically.
%                   Default value is 10.
%
%     'tick',t      Array of tick positions on the y-axis. Use this
%                   option to specify the tick position manually.
%
%     'audtick'     Use ticks suitable for visualizing an auditory
%                   filterbank. Same as 'tick',[0,100,250,500,1000,...].
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/filterbank/plotfilterbank.html}
%@seealso{filterbank, ufilterbank, tfplot, sgram}
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

definput.import={'plotfilterbank','tfplot','ltfattranslate'};

definput.keyvals.xres=800;

[flags,kv]=ltfatarghelper({'fc','fs','dynrange'},definput,varargin);


C = coef;

if iscell(C)
  M=numel(C);
  a = comp_filterbank_a(a,M);
  
  if all(rem(a(:,1),1)==0) && any(a(:,2)~=1)
    % Well behaved fractional case   
    % a(:,1) = L
    % a(:,2) = cellfun(@(cEl) size(cEl,1),c);
    L = a(1);
  else
    % Non-fractional case and non-integer hop factors
    L=a(1)*size(C{1},1);
    % Sanity check
    assert(rem(L,1)<1e-3,sprintf('%s: Invalid hop size.',upper(mfilename)));
  end
  

  N=kv.xres;
  coef2=zeros(M,N);
  
  for ii=1:M
    row=C{ii};
    if numel(row)==1
       coef2(ii,:) = row;
       continue;
    end
    coef2(ii,:)=interp1(linspace(0,1,numel(row)),row,...
                       linspace(0,1,N),'nearest');
  end;
  C=coef2;
  delta_t=L/N;
else
  a=a(1);
  Nc=size(C,1);
  N=kv.xres;
  M=size(C,2);
  C=interp1(linspace(0,1,Nc),C,...
       linspace(0,1,N),'nearest');
  C=C.';  
  delta_t=a*Nc/N;
end;

% Freq. pos is just number of the channel.
yr=1:M;

if size(C,3)>1
  error('Input is multidimensional.');
end;

% Apply transformation to coefficients.
if flags.do_db
  C=20*log10(abs(C)+realmin);
end;

if flags.do_dbsq
  C=10*log10(abs(C)+realmin);
end;

if flags.do_linsq
  C=abs(C).^2;
end;

if flags.do_linabs
  C=abs(C);
end;

if flags.do_lin
  if ~isreal(C)
    error(['Complex valued input cannot be plotted using the "lin" flag.',...
           'Please use the "linsq" or "linabs" flag.']);
  end;
end;

% 'dynrange' parameter is handled by converting it into clim
% clim overrides dynrange, so do nothing if clim is already specified
if  ~isempty(kv.dynrange) && isempty(kv.clim)
  maxclim=max(C(:));
  kv.clim=[maxclim-kv.dynrange,maxclim];
end;

% Handle clim by thresholding and cutting
if ~isempty(kv.clim)
  C(C<kv.clim(1))=kv.clim(1);
  C(C>kv.clim(2))=kv.clim(2);
end;

if flags.do_tc
  xr=(-floor(N/2):floor((N-1)/2))*a;
else
  xr=(0:N-1)*delta_t;
end;

if ~isempty(kv.fs)
  xr=xr/kv.fs;
end;

switch(flags.plottype)
  case 'image'
    % Call imagesc explicitly with clim. This is necessary for the
    % situations where the data (is by itself limited (from above or
    % below) to within the specified range. Setting clim explicitly
    % avoids the colormap moves in the top or bottom.
    if isempty(kv.clim)
      imagesc(xr,yr,C);
    else
      imagesc(xr,yr,C,kv.clim);
    end;   
  case 'contour'
    contour(xr,yr,C);
  case 'surf'
    surf(xr,yr,C,'EdgeColor','none');
  case 'pcolor'
    pcolor(xr,yr,C);
end;


if flags.do_colorbar
   colorbar;
   if ~isempty(kv.colormap)
       colormap(kv.colormap); 
   end
end;

axis('xy');
if ~isempty(kv.fs)
  xlabel(sprintf('%s (s)',kv.time),'fontsize',kv.fontsize);
else
  xlabel(sprintf('%s (%s)',kv.time,kv.samples),'fontsize',kv.fontsize);
end;

if isempty(kv.fc)
  ylabel('Channel No.','fontsize',kv.fontsize);
else
  
  if isempty(kv.tick)
    tickpos=linspace(1,M,kv.ntickpos);
    tick=spline(1:M,kv.fc,tickpos);
    
    set(gca,'YTick',tickpos);
    set(gca,'YTickLabel',num2str(tick(:),3));

  else
    nlarge=1000;
    tick=kv.tick;
        
    % Create a crude inverse mapping to determine the positions of the
    % ticks. Include half a channel in each direction, because it is
    % possible to display a tick mark all the way to the edge of the
    % plot.
    manyticks=spline(1:M,kv.fc,linspace(0.5,M+0.5,nlarge));
    
    % Keep only ticks <= than highest frequency+.5*bandwidth
    tick=tick(tick<=manyticks(end));
    
    % Keep only ticks >= lowest frequency-.5*bandwidth
    tick=tick(tick>=manyticks(1));    
    
    nticks=length(tick);
    tickpos=zeros(nticks,1);
    for ii=1:nticks
      jj=find(manyticks>=tick(ii));
      tickpos(ii)=jj(1)/nlarge*M;
    end;

    set(gca,'YTick',tickpos);
    set(gca,'YTickLabel',num2str(tick(:)));

  end;
  
  ylabel(sprintf('%s (Hz)',kv.frequency),'fontsize',kv.fontsize);
  
end;

% To avoid printing all the coefficients in the command window when a
% semicolon is forgotten
if nargout < 1
    clear C;
end


