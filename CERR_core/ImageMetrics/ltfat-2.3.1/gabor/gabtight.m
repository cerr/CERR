function gt=gabtight(varargin)
%-*- texinfo -*-
%@deftypefn {Function} gabtight
%@verbatim
%GABTIGHT  Canonical tight window of Gabor frame
%   Usage:  gt=gabtight(a,M,L);
%           gt=gabtight(g,a,M);
%           gt=gabtight(g,a,M,L);
%           gd=gabtight(g,a,M,'lt',lt);
%
%   Input parameters:
%         g     : Gabor window.
%         a     : Length of time shift.
%         M     : Number of modulations.
%         L     : Length of window. (optional)
%         lt    : Lattice type (for non-separable lattices).
%   Output parameters:
%         gt    : Canonical tight window, column vector.
%
%   GABTIGHT(a,M,L) computes a nice tight window of length L for a
%   lattice with parameters a, M. The window is not an FIR window,
%   meaning that it will only generate a tight system if the system
%   length is equal to L.
%
%   GABTIGHT(g,a,M) computes the canonical tight window of the Gabor frame
%   with window g and parameters a, M.
%
%   The window g may be a vector of numerical values, a text string or a
%   cell array. See the help of GABWIN for more details.
%  
%   If the length of g is equal to M, then the input window is assumed to
%   be a FIR window. In this case, the canonical dual window also has
%   length of M. Otherwise the smallest possible transform length is
%   chosen as the window length.
%
%   GABTIGHT(g,a,M,L) returns a window that is tight for a system of
%   length L. Unless the input window g is a FIR window, the returned
%   tight window will have length L.
%
%   GABTIGHT(g,a,M,'lt',lt) does the same for a non-separable lattice
%   specified by lt. Please see the help of MATRIX2LATTICETYPE for a
%   precise description of the parameter lt.
%
%   If a>M then an orthonormal window of the Gabor Riesz sequence with
%   window g and parameters a and M will be calculated.
%
%   Examples:
%   ---------
%
%   The following example shows the canonical tight window of the Gaussian
%   window. This is calculated by default by GABTIGHT if no window is
%   specified:
%
%     a=20;
%     M=30;
%     L=300;
%     gt=gabtight(a,M,L);
%     
%     % Simple plot in the time-domain
%     figure(1);
%     plot(gt);
%
%     % Frequency domain
%     figure(2);
%     magresp(gt,'dynrange',100);
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/gabtight.html}
%@seealso{gabdual, gabwin, fir2long, dgt}
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
%   REFERENCE: OK

%% ------------ decode input parameters ------------

if nargin<3
    error('%s: Too few input parameters.',upper(mfilename));
end;

if numel(varargin{1})==1
  % First argument is a scalar.

  a=varargin{1};
  M=varargin{2};

  g='gauss';

  varargin=varargin(3:end);  
else    
  % First argument assumed to be a vector.

  g=varargin{1};
  a=varargin{2};
  M=varargin{3};

  varargin=varargin(4:end);
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
  scale=sqrt(a/M);
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
        gt=g./sqrt(long2fir(d,info.gl));

    else
        
        % Long window case
        
        % Just in case, otherwise the call is harmless. 
        g=fir2long(g,L);
        
        gt=comp_gabtight_long(g,a,M)*scale;
        
    end;

else
    
    % Just in case, otherwise the call is harmless. 
    g=fir2long(g,L);

    if (kv.nsalg==1) || (kv.nsalg==0 && kv.lt(2)<=2) 
        
        mwin=comp_nonsepwin2multi(g,a,M,kv.lt,L);
        
        gtfull=comp_gabtight_long(mwin,a*kv.lt(2),M)*scale;
        
        % We need just the first vector
        gt=gtfull(:,1);
            
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
            gt=comp_gabtight_long(g,ar,Mr);
        else                
            p0=comp_pchirp(L,-s0);
            g = p0.*fft(g);
            gt=comp_gabtight_long(g,L/Mr,L/ar)*sqrt(L);
            gt = ifft(conj(p0).*gt);                                 
        end
        
        if s1 ~= 0
            gt = conj(p1).*gt;
        end
        
    end;
    
    if (info.gl<=M) && (R==1)
        gt=long2fir(gt,M);
    end;
    
end;

% --------- post process result -------

if isreal(g) && (kv.lt(2)<=2)
  % If g is real and the lattice is either rectangular or quinqux, then
  % the output is known to be real.
  gt=real(gt);
end;

if info.wasrow
  gt=gt.';
end;

