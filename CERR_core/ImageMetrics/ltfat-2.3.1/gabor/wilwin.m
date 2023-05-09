function [g,info] = wilwin(g,M,L,callfun);
%-*- texinfo -*-
%@deftypefn {Function} wilwin
%@verbatim
%WILWIN  Compute a Wilson/WMDCT window from text or cell array
%   Usage: [g,info] = wilwin(g,M,L);
%
%   [g,info]=WILWIN(g,M,L) computes a window that fits well with the
%   specified number of channels M and transform length L. The window itself
%   is specified by a text description or a cell array containing additional
%   parameters.
%
%   The window can be specified directly as a vector of numerical
%   values. In this case, WILWIN only checks assumptions about transform
%   sizes etc.
%
%   [g,info]=WILWIN(g,M) does the same, but the window must be a FIR
%   window, as the transform length is unspecified.
%
%   The window can be specified as one of the following text strings:
%  
%     'gauss'      Gaussian window with optimal concentration
%
%     'dualgauss'  Riesz dual of Gaussian window with optimal concentration.
%
%     'tight'      Window generating an orthonormal basis
%
%   In these cases, a long window is generated with a length of L.
%
%   It is also possible to specify one of the window names from FIRWIN. In
%   such a case, WILWIN generates the specified FIR window with a length
%   of M.
%
%   The window can also be specified as cell array. The possibilities are:
%
%     {'gauss',...}
%       Additional parameters are passed to PGAUSS
%
%     {'dual',...}
%       Dual window of whatever follows. See the examples below.
%
%     {'tight',...}
%       Orthonormal window of whatever follows.
%
%   It is also possible to specify one of the window names from FIRWIN as
%   the first field in the cell array. In this case, the remaining
%   entries of the cell array are passed directly to FIRWIN.
%
%   Some examples:
%
%     g=wilwin('gauss',M,L);
%
%   This computes a Gaussian window of length L fitted for a system with
%   M channels. :
%
%     g=wilwin({'gauss',1},M,L);
%
%   This computes a Gaussian window with equal time and frequency support
%   irrespective of M. :
%
%     gd=wilwin('gaussdual',M,L);
%
%   This computes the dual of a Gaussian window fitted for a system with M*
%   channels. :
%
%     gd=wilwin({'tight','gauss'},M,L);
%
%   This computes the orthonormal window of the Gaussian window fitted for
%   the system. :
%
%     g=wilwin({'dual',{'hann',20}},M,L);
%
%   This computes the dual of a Hann window of length 20.  
%
%   The structure info provides some information about the computed
%   window:
%
%     info.gauss
%        True if the window is a Gaussian.
%
%     info.tfr
%        Time/frequency support ratio of the window. Set whenever it makes sense.
%
%     info.wasrow
%        Input was a row window
%
%     info.isfir
%        Input is an FIR window
%
%     info.isdual
%        Output is the dual window of the auxiliary window.
%
%     info.istight
%        Output is known to be a tight window.
%
%     info.auxinfo
%        Info about auxiliary window.
%   
%     info.gl
%        Length of window.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/wilwin.html}
%@seealso{pgauss, firwin, gabwin}
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

% Assert correct input.
complainif_argnonotinrange(nargin,2,4,mfilename);

if nargin==2
  L=[];
end;
  
% Basic discovery: Some windows depend on L, and some windows help define
% L, so the calculation of L is window dependant.
  
% Default values.
info.gauss=0;
info.wasrow=0;
info.isfir=0;
info.istight=0;
info.isdual=0;

% Manually get the list of window names
definput=arg_firwin(struct);
firwinnames =  definput.flags.wintype;

% Create window if string was given as input.
if ischar(g)
  winname=lower(g);
  switch(winname)
   case {'pgauss','gauss'}
    complain_L(L,callfun);
    g=comp_pgauss(L,2*M*M/L,0,0);
    info.gauss=1;
    info.tfr=2*M*M/L;
   case {'psech','sech'}
    complain_L(L,callfun);
    g=psech(L,2*M*M/L);
    info.tfr=a*M/L;
   case {'dualgauss','gaussdual'}
    complain_L(L,callfun);
    g=comp_pgauss(L,2*M*M/L,0,0);
    g=wildual(g,M);
    info.isdual=1;
    info.tfr=a*M/L;
   case {'tight'}
    complain_L(L,callfun);
    g=wilorth(M,L);
    info.tfr=2*M*M/L;
    info.istight=1;
   case firwinnames
    [g,firinfo]=firwin(winname,2*M,'2');
    info.isfir=1;
    if firinfo.issqpu
      info.istight=1;
    end;
   otherwise
    error('%s: Unknown window type: %s',callfun,winname);
  end;
end;

if iscell(g)
  if isempty(g) || ~ischar(g{1})
    error('First element of window cell array must be a character string.');
  end;
  
  winname=lower(g{1});
  
  switch(winname)
   case {'pgauss','gauss'}
    complain_L(L,callfun);
    [g,info.tfr]=pgauss(L,g{2:end});
    info.gauss=1;
   case {'psech','sech'}
    complain_L(L,callfun);
    [g,info.tfr]=psech(L,g{2:end});    
   case {'dual'}
    gorig = g{2};  
    [g,info.auxinfo] = wilwin(gorig,M,L,callfun);    
    g = wildual(g,M,L);
    
    % gorig can be string or cell array
    if info.auxinfo.isfir && test_isfir(gorig,M)
        info.isfir = 1; 
    end
    
    info.isdual=1;
   case {'tight'}
    gorig = g{2};
    [g,info.auxinfo] = wilwin(g{2},M,L,callfun);    
    g = wilorth(g,M,L);  
    % gorig can be string or cell array
    if info.auxinfo.isfir && test_isfir(gorig,M)
        info.isfir = 1; 
    end
    info.istight=1;
   case firwinnames
    g=firwin(winname,g{2},'energy',g{3:end});
    info.isfir=1;
   otherwise
    error('Unsupported window type.');
  end;
end;

if isnumeric(g)
  if size(g,2)>1
    if size(g,1)==1
      % g was a row vector.
      g=g(:);
      info.wasrow=1;
    end;
  end;
end;

if rem(length(g),2*M)~=0
  % Zero-extend the window to a multiple of 2*M
  g=fir2long(g,ceil(length(g)/(2*M))*2*M);
end;

% Information to be determined post creation.
info.wasreal = isreal(g);
info.gl      = length(g);

if (~isempty(L) && (info.gl<L))
  info.isfir=1;
end;

function complain_L(L,callfun)
  
  if isempty(L)
    error(['%s: You must specify a length L if a window is represented as a ' ...
           'text string or cell array.'],callfun);
  end;
  
  function isfir=test_isfir(gorig,M)
    % Original window is FIR, dual window is FIR if length of the original
    % window is <= M. This is true if the length was not explicitly
    % defined (gorig{2}).
    if iscell(gorig) && numel(gorig)>1 && isnumeric(gorig{2}) && gorig{2}<=2*M...
         || ischar(gorig)   
        isfir = 1; 
    else
       isfir = 0;
    end


