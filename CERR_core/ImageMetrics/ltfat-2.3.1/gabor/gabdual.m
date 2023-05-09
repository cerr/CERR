function gd=gabdual(g,a,M,varargin)
%-*- texinfo -*-
%@deftypefn {Function} gabdual
%@verbatim
%GABDUAL  Canonical dual window of Gabor frame
%   Usage:  gd=gabdual(g,a,M);
%           gd=gabdual(g,a,M,L);
%           gd=gabdual(g,a,M,'lt',lt);
%
%   Input parameters:
%         g     : Gabor window.
%         a     : Length of time shift.
%         M     : Number of channels.
%         L     : Length of window. (optional)
%         lt    : Lattice type (for non-separable lattices).
%   Output parameters:
%         gd : Canonical dual window.
%
%   GABDUAL(g,a,M) computes the canonical dual window of the discrete Gabor
%   frame with window g and parameters a, M.
%
%   The window g may be a vector of numerical values, a text string or a
%   cell array. See the help of GABWIN for more details.
%
%   If the length of g is equal to M, then the input window is assumed
%   to be an FIR window. In this case, the canonical dual window also has
%   length of M. Otherwise the smallest possible transform length is chosen
%   as the window length.
%
%   GABDUAL(g,a,M,L) returns a window that is the dual window for a system
%   of length L. Unless the dual window is a FIR window, the dual window
%   will have length L.
%
%   GABDUAL(g,a,M,'lt',lt) does the same for a non-separable lattice
%   specified by lt. Please see the help of MATRIX2LATTICETYPE for a
%   precise description of the parameter lt.
%
%   If a>M then the dual window of the Gabor Riesz sequence with window
%   g and parameters a and M will be calculated.
%
%   Examples:
%   ---------
%
%   The following example shows the canonical dual window of the Gaussian
%   window:
%
%     a=20;
%     M=30;
%     L=300;
%     g=pgauss(L,a*M/L);
%     gd=gabdual(g,a,M);
%     
%     % Simple plot in the time-domain
%     figure(1);
%     plot(gd);
%
%     % Frequency domain
%     figure(2);
%     magresp(gd,'dynrange',100);
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/gabdual.html}
%@seealso{gabtight, gabwin, fir2long, dgt}
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

%   AUTHOR : Peter L. Soendergaard.
%   TESTING: TEST_DGT
%   REFERENCE: REF_GABDUAL.
  
%% ---------- Assert correct input.

if nargin<3
  error('%s: Too few input parameters.',upper(mfilename));
end;

definput.keyvals.L=[];
definput.keyvals.lt=[0 1];
definput.keyvals.nsalg=0;
[flags,kv,L]=ltfatarghelper({'L'},definput,varargin);

%% ------ step 2: Verify a, M and L
if isempty(L)
    if isnumeric(g)
        % Use the window length
        Ls=length(g);
    else
        % Use the smallest possible length
        Ls=1;
    end;

    % ----- step 2b : Verify a, M and get L from the window length ----------
    L=dgtlength(Ls,a,M,kv.lt);

else

    % ----- step 2a : Verify a, M and get L

    Luser=dgtlength(L,a,M,kv.lt);
    if Luser~=L
        error(['%s: Incorrect transform length L=%i specified. Next valid length ' ...
               'is L=%i. See the help of DGTLENGTH for the requirements.'],...
              upper(mfilename),L,Luser);
    end;

end;

%% ----- step 3 : Determine the window 

[g,info]=gabwin(g,a,M,L,kv.lt,'callfun',upper(mfilename));

if L<info.gl
  error('%s: Window is too long.',upper(mfilename));
end;

R=size(g,2);
% -------- Are we in the Riesz sequence of in the frame case

scale=1;
if a>M*R
  % Handle the Riesz basis (dual lattice) case.
  % Swap a and M, and scale differently.
  scale=a/M;
  tmp=a;
  a=M;
  M=tmp;
end;

% -------- Compute ------------- 

if kv.lt(2)==1
    % Rectangular case
    if (info.gl<=M) && (R==1)
        
        % Diagonal of the frame operator
        d = gabframediag(g,a,M,L);
        gd=g./long2fir(d,info.gl);
                
    else
        
        % Long window case
        
        % Just in case, otherwise the call is harmless. 
        g=fir2long(g,L);
        
        gd=comp_gabdual_long(g,a,M)*scale;
        
    end;

else
    % Non-separable case
    g=fir2long(g,L);

    if (kv.nsalg==1) || (kv.nsalg==0 && kv.lt(2)<=2) 
        
        mwin=comp_nonsepwin2multi(g,a,M,kv.lt,L);
        
        gdfull=comp_gabdual_long(mwin,a*kv.lt(2),M)*scale;
        
        % We need just the first vector
        gd=gdfull(:,1);
            
    else        
        
        [s0,s1,br] = shearfind(L,a,M,kv.lt);        
        
        if s1 ~= 0
            p1 = comp_pchirp(L,s1);
            g = p1.*g;                
        end
        
        b=L/M;
        Mr = L/br;
        ar = a*b/br;
        
        if s0 == 0
            gd=comp_gabdual_long(g,ar,Mr);
        else                
            p0=comp_pchirp(L,-s0);
            g = p0.*fft(g);
            gd=comp_gabdual_long(g,L/Mr,L/ar)*L;
            gd = ifft(conj(p0).*gd);                                 
        end
        
        if s1 ~= 0
            gd = conj(p1).*gd;
        end
        
    end;

    if (info.gl<=M) && (R==1)
        gd=long2fir(gd,M);
    end;
        
end;
    
% --------- post process result -------

if isreal(g) && (kv.lt(2)==1 || kv.lt(2)==2)
  % If g is real and the lattice is either rectangular or quinqux, then
  % the output is known to be real.
  gd=real(gd);
end;

if info.wasrow
  gd=gd.';
end;

