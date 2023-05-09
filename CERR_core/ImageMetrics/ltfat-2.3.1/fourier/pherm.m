function [g,D]=pherm(L,order,varargin)
%-*- texinfo -*-
%@deftypefn {Function} pherm
%@verbatim
%PHERM  Periodized Hermite function
%   Usage: g=pherm(L,order);
%          g=pherm(L,order,tfr);
%          [g,D]=pherm(...);
% 
%   Input parameters:
%      L     : Length of vector.
%      order : Order of Hermite function.
%      tfr   : ratio between time and frequency support.
%   Output parameters:
%      g     : The periodized Hermite function
%
%   PHERM(L,order,tfr) computes samples of a periodized Hermite function
%   of order order. order is counted from 0, so the zero'th order
%   Hermite function is the Gaussian.
%
%   The parameter tfr determines the ratio between the effective support
%   of g and the effective support of the DFT of g. If tfr>1 then g*
%   has a wider support than the DFT of g.
%
%   PHERM(L,order) does the same setting tfr=1.
%
%   If order is a vector, PHERM will return a matrix, where each column
%   is a Hermite function with the corresponding order.
%
%   [g,D]=PHERM(...) also returns the eigenvalues D of the Discrete
%   Fourier Transform corresponding to the Hermite functions.
%
%   The returned functions are eigenvectors of the DFT. The Hermite
%   functions are orthogonal to all other Hermite functions with a
%   different eigenvalue, but eigenvectors with the same eigenvalue are
%   not orthogonal (but see the flags below).
%
%   PHERM takes the following flags at the end of the line of input
%   arguments:
%
%     'accurate'  Use a numerically very accurate that computes each
%                 Hermite function individually. This is the default.
%
%     'fast'      Use a less accurate algorithm that calculates all the
%                 Hermite up to a given order at once.
%
%     'noorth'    No orthonormalization of the Hermite functions. This is
%                 the default.
%
%     'polar'     Orthonormalization of the Hermite functions using the
%                 polar decomposition orthonormalization method.
%
%     'qr'        Orthonormalization of the Hermite functions using the
%                 Gram-Schmidt orthonormalization method (usign qr).
%
%   If you just need to compute a single Hermite function, there is no
%   speed difference between the 'accurate' and 'fast' algorithm.
%
%   Examples:
%   ---------
%
%   The following plot shows the spectrograms of 4 Hermite functions of
%   length 200 with order 1, 10, 100, and 190:
%
%     subplot(2,2,1);
%     sgram(pherm(200,1),'nf','tc','lin','nocolorbar'); axis('square');
%
%     subplot(2,2,2);
%     sgram(pherm(200,10),'nf','tc','lin','nocolorbar'); axis('square');
%    
%     subplot(2,2,3);
%     sgram(pherm(200,100),'nf','tc','lin','nocolorbar'); axis('square');
%    
%     subplot(2,2,4);
%     sgram(pherm(200,190),'nf','tc','lin','nocolorbar'); axis('square');
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/pherm.html}
%@seealso{hermbasis, pgauss, psech}
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

% AUTHORs: Thomasz Hrycak and Peter L. Soendergaard.
% 

if nargin<2
  error('%s: Too few input parameters.',upper(mfilename));
end;

definput.keyvals.tfr=1;
definput.flags.phase={'accurate','fast'};
definput.flags.orthtype={'noorth','polar','qr'};
[flags,kv,tfr]=ltfatarghelper({'tfr'},definput,varargin);
  
if size(L,1)>1 || size(L,2)>1
  error('L must be a scalar');
end;

if rem(L,1)~=0
  error('L must be an integer.')
end;

% Parse tfr and order.
if sum(1-(size(tfr)==1))>1
  error('tfr must be a scalar or vector');
end;

if sum(1-(size(order)==1))>1
  error('"order" must be a scalar or vector');
end;

W=length(order);

order=order(:);


% Calculate W windows.
if flags.do_accurate
    % Calculate W windows.
    g=zeros(L,W);
    for w=1:W
        
        thisorder=order(w);
        safe=get_safe(thisorder);

        % Outside the interval [-safe,safe] then H(thisorder) is numerically zero.
        nk=ceil(safe/sqrt(L/sqrt(tfr)));
        
        sqrtl=sqrt(L);
        
        lr=(0:L-1).';
        for k=-nk:nk
            xval=(lr/sqrtl-k*sqrtl)/sqrt(tfr);
            g(:,w)=g(:,w)+comp_hermite(thisorder, sqrt(2*pi)*xval);
        end;
        
    end;
    
else
    
    highestorder=max(order);
    safe=get_safe(highestorder);

    % Outside the interval [-safe,safe] then H(thisorder) is numerically zero.
    nk=ceil(safe/sqrt(L/sqrt(tfr)));

    g=zeros(L,highestorder+1);
    sqrtl=sqrt(L);
        
    lr=(0:L-1).';
    for k=-nk:nk
        xval=(lr/sqrtl-k*sqrtl)/sqrt(tfr);
        g=g+comp_hermite_all(highestorder+1, sqrt(2*pi)*xval);
    end;

    g=g(:,order+1);
    
end;

if flags.do_polar
    % Orthonormalize within each of the 4 eigenspaces
    for ii=0:3
        subidx=(rem(order,4)==ii);
        gsub=g(:,subidx);
        [U,S,V]=svd(gsub,0);
        gsub=U*V';
        g(:,subidx)=gsub;        
    end;
        
end;

if flags.do_qr
    % Orthonormalize within each of the 4 eigenspaces
    for ii=0:3
        subidx=(rem(order,4)==ii);
        gsub=g(:,subidx);
        [Q,R]=qr(gsub,0);
        g(:,subidx)=Q;        
    end;       
end;

if flags.do_noorth
    % Just normalize it, no orthonormalization
    g=normalize(g);
end;

if nargout>1
    % set up the eigenvalues
    D = exp(-1i*order*pi/2);
end;


function safe=get_safe(order)
% These numbers have been computed numerically.
    if order<=6
        safe=4;
    else 
        if order<=18
            safe=5;
        else 
            if order<=31
                safe=6;                
            else 
                if order<=46
                    safe=7;
                else
                    % Anything else, use a high number.
                    safe=12;
                end;
            end;
        end;
    end;
    

