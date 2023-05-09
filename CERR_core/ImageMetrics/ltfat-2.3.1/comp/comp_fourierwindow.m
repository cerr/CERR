function [g,info] = comp_fourierwindow(g,L,callfun);
%-*- texinfo -*-
%@deftypefn {Function} comp_fourierwindow
%@verbatim
%COMP_FOURIERWINDOW  Compute the window from numeric, text or cell array.
%   Usage: [g,info] = comp_fourierwindow(g,L,callfun);
%
%   [g,info]=COMP_FOURIERWINDOW(g,L,callfun) will compute the window
%   from a text description or a cell array containing additional
%   parameters. 
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_fourierwindow.html}
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
info.isfir=0;

% Manually get the list of window names
definput=arg_firwin(struct);
firwinnames =  definput.flags.wintype;

% Create window if string was given as input.
if ischar(g)
  winname=lower(g);
  switch(winname)
   case {'pgauss','gauss'}
    complain_L(L,callfun);
    g=comp_pgauss(L,1,0,0);
    info.gauss=1;
    info.tfr=1;
   case {'psech','sech'}
    complain_L(L,callfun);
    g=psech(L,1);
    info.tfr=1;
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
   case firwinnames
    g=firwin(winname,g{2:end});
    info.isfir=1;
   otherwise
    error('Unsupported window type.');
  end;
end;

if isnumeric(g)
  % The DGT window format to struct with .h field format
  if size(g,2)>1
    if size(g,1)>1
      error('%s: g must be a vector',callfun);
    else
      % g was a row vector.
      g=g(:);
    end;
  end;
  g_time=g;
  g=struct();
  g.h=fftshift(g_time);
  info.gl=numel(g_time);
  g.offset=-floor(info.gl/2);  
  g.fc=0;
  g.realonly=0;
  info.wasreal=isreal(g.h);
  % And continue processing this since it becomes a FIR filter.
end

    if isstruct(g)
        if isfield(g,'h') && isnumeric(g.h) && isvector(g.h)
            info.wasreal=isreal(g.h);
            info.gl=length(g.h);
            info.isfir=1;
            
            % g.h was a row vector
            if size(g.h,2)>1
                g.h = g.h(:);
            end
            
            % In case a filter lacks .offset, set it to zero
            if ~isfield(g,'offset')
                g.offset= 0; 
            end
        elseif isfield(g,'H')  && ... 
               ( isnumeric(g.H) && isvector(g.H) || isa(g.H,'function_handle') )
           
            info.wasreal=isfield(g,'realonly') && g.realonly;
            info.gl=[];
            
            % g.H was a row vector
            if size(g.H,2)>1
                g.H = g.H(:);
            end
            
            % In case a filter lacks .foff, make a low-pass filter of it.
            if ~isfield(g,'foff')
                g.foff= @(L) 0; 
            end
            
            if isa(g.H,'function_handle')
                if ~isa(g.foff,'function_handle')
                    error('%s: g.foff should be a function handle.',...
                           callfun);
                end
            elseif isnumeric(g.H)
                if ~isfield(g,'L')
                    error('%s: .H is numeric, but g.L was not defined.',...
                          callfun);
                end
            end
 
        else
            error(['%s: The struct. defining a filter must contain ',...
                   'either .h (numeric vector) or .H (numeric vector, ',...
                   'anonymous fcn) fields.'],callfun);
        end;
    else
        % We can probably never get here
        % Information to be determined post creation.
        info.wasreal = isreal(g);
        info.gl      = length(g);
        
        if (~isempty(L) && (info.gl<L))
            info.isfir=1;
        end;
            
    end;
    

    
function complain_L(L,callfun)
  
  if isempty(L)
    error(['L:undefined',...
           '%s: You must specify a length L if a window is represented as a ' ...
           'text string, cell array or anonymous function.'],callfun);
  end;



