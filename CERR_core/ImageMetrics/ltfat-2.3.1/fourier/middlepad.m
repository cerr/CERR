function f=middlepad(f,L,varargin)
%-*- texinfo -*-
%@deftypefn {Function} middlepad
%@verbatim
%MIDDLEPAD  Symmetrically zero-extends or cuts a function
%   Usage:  h=middlepad(f,L);
%           h=middlepad(f,L,dim);
%           h=middlepad(f,L,...);
%
%   MIDDLEPAD(f,L) cuts or zero-extends f to length L by inserting
%   zeros in the middle of the vector, or by cutting in the middle
%   of the vector.
%
%   If f is whole-point even, MIDDLEPAD(f,L) will also be whole-point
%   even.
%
%   MIDDLEPAD(f,L,dim) does the same along dimension dim.
%   
%   If f has even length, then f will not be purely zero-extended, but
%   the last element will be repeated once and multiplied by 1/2.
%   That is, the support of f will increase by one!
%
%   Adding the flag 'wp' as the last argument will cut or extend whole point
%   even functions.  Adding 'hp' will do the same for half point even
%   functions.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/middlepad.html}
%@seealso{isevenfunction, fir2long, fftresample}
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

%   AUTHOR : Peter L. Soendergaard
%   TESTING: OK
%   REFERENCE: OK


if nargin<2  
  error('Too few input parameters.');
end;

if  (numel(L)~=1 || ~isnumeric(L))
  error('L must be a scalar');
end;

if rem(L,1)~=0
    error('L must be an integer.');
end;

if L<1
  error('L must be larger than 0.');
end;

% Define initial value for flags and key/value pairs.
definput.flags.centering = {'wp','hp'};
definput.keyvals.dim     = [];

[flags,keyvals,dim]=ltfatarghelper({'dim'},definput,varargin);

[f,L,Ls,W,dim,permutedsize,order]=assert_sigreshape_pre(f,L,dim,'MIDDLEPAD');

Lorig=Ls;

% Skip the main section if there is nothing to do. This is necessary
% because some of the code below cannot handle the case of 'nothing to do'
if L~=Ls
  if flags.do_wp
    
    % ---------------   WPE case --------------------------------------
    
    if Lorig==1
      % Rather trivial case
      f=[f(1,:);zeros(L-1,W,assert_classname(f))];
      
    else
      if Lorig>L
        % Cut
        
        if mod(L,2)==0
          
          % L even. Use average of endpoints.
          f=[f(1:L/2,:);(f(L/2+1,:)+f(Lorig-L/2+1,:))/2;f(Lorig-L/2+2:Lorig,:)];
          
        else
          
          % No problem, just cut.
          f=[f(1:(L+1)/2,:);f(Lorig-(L-1)/2+1:Lorig,:)];
          
        end;     
        
      else
        
        d=L-Lorig;
        
        % Extend
        if mod(Lorig,2)==0
          
          % Lorig even. We must split a value.
          
          f=[f(1:Lorig/2,:);...
             f(Lorig/2+1,:)/2;...
             zeros(d-1,W,assert_classname(f));...
             f(Lorig/2+1,:)/2;...
             f(Lorig/2+2:Lorig,:)];
          
        else
          % Lorig is odd, we can just insert zeros.
          f=[f(1:(Lorig+1)/2,:);zeros(d,W,assert_classname(f));f((Lorig+3)/2:Lorig,:)];
          
        end;
        
      end;
    end;
    
  else
    
    % ------------------ HPE case ------------------------------------
    
    if Lorig==1
        f=[f(1,:);zeros(L-1,W,assert_classname(f))];
    else
      if Lorig>L
        
        d=Lorig-L;
        % Cut
        
        if mod(L,2)==0
          % L even
          
          % No problem, just cut.
          f=[f(1:L/2,:);...
             f(Lorig-L/2+1:Lorig,:);];
          
        else
          
          % Average of endpoints.
          f=[f(1:(L-1)/2,:);(f((L+1)/2,:)+f(Lorig-(L-1)/2,:))/2;...
             f(Lorig-(L-1)/2+1:Lorig,:);];
          
        end;
        
      else
        
        d=L-Lorig;
        
        % Extend
        if mod(Lorig,2)==0 
          
          % Lorig even. We can just insert zeros in the middle.
          
          f=[f(1:Lorig/2,:);...
             zeros(d,W,assert_classname(f));...
             f(Lorig/2+1:Lorig,:)];
          
        else
          % Lorig odd. We need to split a value in two
          f=[f(1:(Lorig-1)/2,:);...
             f((Lorig+1)/2,:)/2;...
             zeros(d-1,W,assert_classname(f));...
             f((Lorig+1)/2,:)/2;...
             f((Lorig-1)/2+2:Lorig,:)];
          
        end;
        
      end;
      
    end;
  end;
  
end;

f=assert_sigreshape_post(f,dim,permutedsize,order);


