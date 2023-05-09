function [L,tfr]=longpar(varargin)
%-*- texinfo -*-
%@deftypefn {Function} longpar
%@verbatim
%LONGPAR  Parameters for LONG windows
%   Usage:  [L,tfr]=longpar(Ls,a,M);
%           [L,tfr]=longpar('dgt',Ls,a,M);
%           [L,tfr]=longpar('dwilt',Ls,M);
%           [L,tfr]=longpar('wmdct',Ls,M);
%
%   [L,tfr]=LONGPAR(Ls,a,M) or [L,tfr]=LONGPAR('dgt',Ls,a,M) calculates the 
%   minimal transform length L for a DGT of a signal of length Ls with
%   parameters a and M. L is always larger than Ls. The parameters tfr*
%   describes the time-to-frequency ratio of the chosen lattice.
%
%   An example can most easily describe the use of LONGPAR. Assume that
%   we wish to perform Gabor analysis of an input signal f with a 
%   suitable Gaussian window and lattice given by a and M. The following
%   code will always work:
%
%     Ls=length(f);
%     [L,tfr]=longpar(Ls,a,M);
%     g=pgauss(L,tfr);
%     c=dgt(f,g,a,M);
%
%   [L,tfr]=LONGPAR('dwilt',Ls,M) and [L,tfr]=LONGPAR('wmdct',Ls,M) will
%   do the same for a Wilson/WMDCT basis with M channels.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/longpar.html}
%@seealso{dgt, dwilt, pgauss, psech, pherm}
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

complainif_argnonotinrange(nargin,3,4,mfilename);

if ischar(varargin{1})
    ttype=varargin{1};
    pstart=2;
else
    ttype='dgt';
    pstart=1;
end;

Ls=varargin{pstart};

if (numel(Ls)~=1 || ~isnumeric(Ls))
  error('Ls must be a scalar.');
end;
if rem(Ls,1)~=0
  error('Ls must be an integer.');
end;


switch(lower(ttype))
    case 'dgt'
        if nargin<pstart+2
            error('Too few input parameters for DGT type.');
        end;
        
        a=varargin{pstart+1};
        M=varargin{pstart+2};
        
        smallest_transform=lcm(a,M);
        L=ceil(Ls/smallest_transform)*smallest_transform;
        b=L/M;
        tfr=a/b;
    case {'dwilt','wmdct'}
        if nargin<pstart+1
            error('Too few input parameters for DWILT/WMDCT type.');
        end;
        M=varargin{pstart+1};

        smallest_transform=2*M;
        L=ceil(Ls/smallest_transform)*smallest_transform;
        b=L/(2*M);
        tfr=M/b;
    otherwise
        error('Unknown transform type.');
end;

