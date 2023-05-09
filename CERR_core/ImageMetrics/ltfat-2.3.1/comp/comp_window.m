function [g,info] = comp_window(g,a,M,L,lt,callfun);
%-*- texinfo -*-
%@deftypefn {Function} comp_window
%@verbatim
%COMP_WINDOW  Compute the window from numeric, text or cell array.
%   Usage: [g,info] = comp_window(g,a,M,L,s,callfun);
%
%   [g,info]=COMP_WINDOW(g,a,M,L,lt,callfun) will compute the window
%   from a text description or a cell array containing additional
%   parameters.
%
%   This function is the driving routine behind GABWIN and WILWIN.
%
%   See the help on GABWIN and WILWIN for more information.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_window.html}
%@seealso{gabwin, wilwin}
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

  
% Basic discovery: Some windows depend on L, and some windows help define
% L, so the calculation of L is window dependant.
  
% Default values.
info.gauss=0;
info.wasrow=0;
info.isfir=0;
info.istight=0;
info.isdual=0;

isrect=(lt(2)==1);

% Manually get the list of window names
definput=arg_firwin(struct);
firwinnames =  definput.flags.wintype;

% Create window if string was given as input.
if ischar(g)
  winname=lower(g);
  switch(winname)
   case {'pgauss','gauss'}
    complain_L(L,callfun);
    g=comp_pgauss(L,a*M/L,0,0);
    info.gauss=1;
    info.tfr=a*M/L;
   case {'psech','sech'}
    complain_L(L,callfun);
    g=psech(L,a*M/L);
    info.tfr=a*M/L;
   case {'dualgauss','gaussdual'}
    complain_L(L,callfun);
    g=comp_pgauss(L,a*M/L,0,0);
    if isrect
      g=gabdual(g,a,M);
    else
      g=gabdual(g,a,M,'lt',lt);
    end;
    info.isdual=1;
    info.tfr=a*M/L;
   case {'tight'}
    complain_L(L,callfun);
    if isrect
      g=gabtight(a,M,L);
    else
      g=gabtight(a,M,L,'lt',lt);
    end;
    info.tfr=a*M/L;
    info.istight=1;
   case firwinnames
    [g,firinfo]=firwin(winname,M,'2');
    info.isfir=1;
    if isrect
        if firinfo.issqpu && test_isfirtight(g,a,M)
            info.istight=1;
        end;
    end
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
    [g,info.auxinfo] = comp_window(gorig,a,M,L,lt,callfun);    
    if isrect
      g = gabdual(g,a,M,L);
    else
      g = gabdual(g,a,M,L,'lt',lt);
    end;
    % gorig can be string or cell array
    if info.auxinfo.isfir && test_isfir(gorig,M) 
       info.isfir = 1; 
    end
    info.isdual=1;
   case {'tight'}
    gorig = g{2};
    [g,info.auxinfo] = comp_window(gorig,a,M,L,lt,callfun);    
    if isrect
      g = gabtight(g,a,M,L);
    else
      g = gabtight(g,a,M,L,'lt',lt);
    end;
    % The same as in dual?
    if info.auxinfo.isfir && test_isfir(gorig,M) 
       info.isfir = 1; 
    end
    info.istight=1;
   case firwinnames
    [g,firinfo]=firwin(winname,g{2},'energy',g{3:end});
    info.isfir=1;
    if isrect
        if firinfo.issqpu && test_isfirtight(g,a,M)
            info.istight=1;
        end;
    end
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
  if isempty(L)
      info.isfir = 1; 
  end
end;

if rem(length(g),M)~=0
  % Zero-extend the window to a multiple of M
  g=fir2long(g,ceil(length(g)/M)*M);
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
    % defined (gorig{2}) or gorig was given as a numeric vector explicitly.
      if iscell(gorig) && numel(gorig)>1 && isnumeric(gorig{2}) && gorig{2}<=M...
         || ischar(gorig) || isnumeric(gorig) && numel(gorig)<=M   
        isfir = 1; 
      else
         isfir = 0;
      end
      
function istight=test_isfirtight(g,a,M)
    % Tests whether the Gabor system given by *a*, *M* and the FIR window
    % *g* forms a tight frame by computing *a* elements of the diagonal of 
    % the frame operator.
    if numel(g) > M 
        % There is still a small probability that the system is tight
        % or at least tight numerically. We have no cheap way how to
        % figure it out.
        istight = 0;
        return;
    end
    
    Lsmallest = lcm(a,M);
    Nsmallest = Lsmallest/a;
    glong = fir2long(g,Lsmallest).^2;
    
    gdiag = sum(reshape(glong,a,Nsmallest),2);
    istight = all(abs(gdiag(1)-gdiag)<1e-14);
    






