function gt=nsgabtight(g,a,M,varargin)
%-*- texinfo -*-
%@deftypefn {Function} nsgabtight
%@verbatim
%NSGABTIGHT  Canonical tight window for non-stationary Gabor frames
%   Usage:  gt=nsgabtight(g,a,M);
%           gt=nsgabtight(g,a,M,L);
%
%   Input parameters:
%         g     : Cell array of windows
%         a     : Vector of time shifts of windows.
%         M     : Vector of numbers of channels.
%         L     : Transform length.
%   Output parameters:
%         gt : Cell array of canonical tight windows
%
%   NSGABTIGHT(g,a,M) computes the canonical tight windows of the 
%   non-stationary discrete Gabor frame defined by windows given in g and  
%   time-shifts given by a.
%   
%   NSGABTIGHT is designed to be used with functions NSDGT and
%   INSDGT.  Read the help on NSDGT for more details about the variables
%   structure.
%
%   The computed tight windows are only valid for the 'painless case', that
%   is to say that they ensure perfect reconstruction only if for each 
%   window the number of frequency channels used for computation of NSDGT is
%   greater than or equal to the window length. This correspond to cases
%   for which the frame operator is diagonal.
%
%
%   References:
%     P. Balazs, M. Doerfler, F. Jaillet, N. Holighaus, and G. A. Velasco.
%     Theory, implementation and applications of nonstationary Gabor frames.
%     J. Comput. Appl. Math., 236(6):1481--1496, 2011.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/nonstatgab/nsgabtight.html}
%@seealso{nsgabtight, nsdgt, insdgt}
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

%   AUTHOR : Florent Jaillet
%   TESTING: TEST_NSDGT
%   REFERENCE:

if nargin<3
  error('%s: Too few input parameters.',upper(mfilename));
end;

if ~isnumeric(a)
  error('%s: a must be numeric.',upper(mfilename));
end;

if ~isnumeric(M)
  error('%s: M must be numeric.',upper(mfilename));
end;

definput.keyvals.L=sum(a);
[flags,kv,L]=ltfatarghelper({'L'},definput,varargin);

timepos=cumsum(a)-a(1);

N=length(a);

[g,info]=nsgabwin(g,a,M);

a=info.a;
M=info.M;

if info.isfac
    if info.ispainless
        f=zeros(L,1); % Diagonal of the frame operator

        % Compute the diagonal of the frame operator:
        f=nsgabframediag(g,a,M);
        
        % As we want tight frame, we will use the sqrt of the operator
        f=sqrt(f);
        
        % Initialize the result with g
        gt=g;
        
        % Correct each window to ensure perfect reconstrution
        for ii=1:N
            shift=floor(length(g{ii})/2);
            tempind=mod((1:length(g{ii}))+timepos(ii)-shift-1,L)+1;
            gt{ii}(:)=circshift(circshift(g{ii},shift)./f(tempind),-shift);
        end
    
    else
        if 0
            % Convert to freq. domain and run filterbanktight
            gf=cell(1,N);
            gt=cell(1,N);
            for ii=1:N
                gf{ii}=circshift(fft(fir2long(g{ii},L)),timepos(ii));
            end;
            
            gft=filterbanktight(gf,M);
            for ii=1:N
                gt{ii}=ifft(circshift(gft{ii},-timepos(ii)));
            end;
                
        else
            error(['%s: Not implemented yet.'],upper(mfilename));
        end;
    end;
else
            
    error(['%s: The canonical tight frame of this system is not a ' ...
               'non-stationary Gabor frame.'],upper(mfilename));
end;

