function g=firkaiser(L,beta,varargin)
%-*- texinfo -*-
%@deftypefn {Function} firkaiser
%@verbatim
%FIRKAISER  Kaiser-Bessel window
%   Usage:  g=firkaiser(L,beta);
%           g=firkaiser(L,beta,...);
%
%   FIRKAISER(L,beta) computes the Kaiser-Bessel window of length L with
%   parameter beta. The smallest element of the window is set to zero when
%   the window has an even length. This gives the window perfect whole-point
%   even symmetry, and makes it possible to use the window for a Wilson
%   basis.
%
%   FIRKAISER takes the following flags at the end of the input arguments:
%
%     'normal'   Normal Kaiser-Bessel window. This is the default.
%
%     'derived'  Derived Kaiser-Bessel window.
%
%     'wp'       Generate a whole point even window. This is the default.
%
%     'hp'       Generate half point even window.
%  
%   Additionally, FIRKAISER accepts flags to normalize the output. Please
%   see the help of NORMALIZE. Default is to use 'peak' normalization.
%
%
%   References:
%     A. V. Oppenheim and R. W. Schafer. Discrete-time signal processing.
%     Prentice Hall, Englewood Cliffs, NJ, 1989.
%     
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/sigproc/firkaiser.html}
%@seealso{firwin, normalize}
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
  error('Too few input arguments.');
end;

if numel(beta)>1
  error('beta must be a scalar.');
end;

% Define initial value for flags and key/value pairs.
definput.import={'normalize'};
definput.importdefaults={'null'};
definput.flags.centering={'wp','hp'};
definput.flags.stype={'normal','derived'};

[flags,keyvals]=ltfatarghelper({},definput,varargin);

cent=0;
if flags.do_hp
  cent=.5;
end;

if flags.do_normal
  
  if (L == 1)
    g = 1;
  else
    m = L - 1;
    k = (0:L-1)'+rem(L,2)/2-.5+cent;
    k = 2*beta/(L-1)*sqrt(k.*(L-1-k));
    g = besseli(0,k)/besseli(0,beta);
  end;

  g=ifftshift(g);
  
  if ((flags.do_wp && rem(L,2)==0) || ...
      (flags.do_hp && rem(L,2)==1))
    
    % Explicitly zero last element. This is done to get the right
    % symmetry, and because that element sometimes turn negative.
    g(floor(L/2)+1)=0;
  end;
  
else
  
  if rem(L,2)==1    
    error('The length of the choosen window must be even.');
  end;
  
  if flags.do_wp 
    if rem(L,4)==0
      L2=L/2+2;
    else
      L2=L/2+1;
    end;
  else
    L2=floor((L+1)/2);
  end;
  
  % Compute a normal Kaiser window
  g_normal=fftshift(firkaiser(L2,beta,flags.centering));
  
  g1=sqrt(cumsum(g_normal(1:L2))./sum(g_normal(1:L2)));
  
  if flags.do_wp 
    if rem(L,2)==0
      g=[flipud(g1);...
         g1(2:L/2)];
    else
      g=[flipud(g1);...
         g1(1:floor(L/2))];
    end;    
  else
    g=[flipud(g1);...
       g1];
  end;

    if ((flags.do_wp && rem(L,2)==0) || ...
      (flags.do_hp && rem(L,2)==1))
    
    % Explicitly zero last element. This is done to get the right
    % symmetry, and because that element sometimes turn negative.
    g(floor(L/2)+1)=0;
  end;

  
end;

% The besseli computation sometimes generates a zero imaginary component.
g=real(g);

g=normalize(g,flags.norm);


