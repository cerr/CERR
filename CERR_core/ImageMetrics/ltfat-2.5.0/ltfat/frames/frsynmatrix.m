function G=frsynmatrix(F,L);
%FRSYNMATRIX  Frame synthesis operator matrix
%   Usage: G=frsynmatrix(F,L);
%
%   G=FRSYNMATRIX(F,L) returns the matrix representation G of the frame
%   synthesis operator for a frame F of length L. The frame object F*
%   must have been created using FRAME.
%
%   The frame synthesis operator matrix contains all the frame atoms as
%   column vectors. It has dimensions L xNcoef, where Ncoef is the
%   number of coefficients. The number of coefficients can be found as
%   Ncoef=frameclength(L). This means that the frame matrix is usually
%   *very* large, and this routine should only be used for small values of
%   L.
%
%   The action of the frame analysis operator FRANA is equal to
%   multiplication with the Hermitean transpose of the frame synthesis
%   matrix. Consider the following simple example:
%
%     L=200;
%     F=frame('dgt','gauss',10,20);
%     G=frsynmatrix(F,L);
%     testsig = randn(L,1);
%     res = frana(F,testsig)-G'*testsig;
%     norm(res)
%     % Show the matrix (real and imaginary parts)
%     figure(1); imagesc(real(G));
%     figure(2); imagesc(imag(G));
%
%   See also: frame, frana, frsyn
%
%   Url: http://ltfat.github.io/doc/frames/frsynmatrix.html

% Copyright (C) 2005-2022 Peter L. Soendergaard <peter@sonderport.dk> and others.
% This file is part of LTFAT version 2.5.0
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

callfun = upper(mfilename);
complainif_notenoughargs(nargin,2,callfun);
complainif_notposint(L,'L',callfun);
complainif_notvalidframeobj(F,callfun);

Lcheck=framelength(F,L);

if Lcheck~=L
    error('%s: Incompatible frame length. Next compatible one is %i.',...
          upper(mfilename),Lcheck);
end;

if F.realinput
    
    %switch(F.type)
    %  case 'dgtreal'
        
    %  This code correctly reproduces the matrix represenation of the
    %  analysis operator, but not of the synthesis.
    %
    %    F2=frame('dgt',F.g,F.a,F.M);
    %    G2=frsynmatrix(F2,L);
    %    M2=floor(F.M/2)+1;
    %    N=L/F.a;
    %    G=zeros(L,M2*N);
    %    for n=0:N-1
    %        G(:,1+n*M2:(n+1)*M2)=G2(:,1+n*F.M:M2+n*F.M);
    %    end;
        
    %  otherwise
     error(['%s: The synthesis operator of real-valued-input frames is ' ...
            'non-linear and does not have a matrix represenation.'],...
            upper(mfilename));
        %end;
else
  Ncoef = framered(F)*L;
  % sprintf for Octave compatibility
  assert(abs(Ncoef-round(Ncoef))<1e-3,...
         sprintf('%s: There is a bug. Ncoef=%d should be an integer.',...
         upper(mfilename),Ncoef));
  % Fix the system length
  Faccel = frameaccel(F,L);
  Ncoef=round(Ncoef);
  G = zeros(L,Ncoef);
  
  Ftype = F.type;
  
  if strcmpi(Ftype,'filterbank') && all(F.a(:,2) == 1)
      % Only integer-subsamped filterbanks are translation-invariant
      Ftype = 'regfilterbank';
  end

  switch Ftype
      case {'ufwt','uwfbt','uwpfbt'}
          for nstep = 1:L:Ncoef
              G(:,nstep) = comp_framevector(Faccel, Ncoef, nstep);
              for l = 1:L-1
                 G(:, nstep+l) = circshift(G(:, nstep+l-1), 1);
              end
          end
      case {'wfbt','wpfbt','ufilterbank','regfilterbank'}
          cnative = framecoef2native(Faccel, zeros(Ncoef,1));
          if iscell(cnative)
              Lc = cellfun(@(cEl) size(cEl,1), cnative);
          else
              Lc = ones(size(cnative,2),1)*size(cnative,1);
          end
          nstep = 1;
          for ii = 1:numel(Lc)
              G(:,nstep) = comp_framevector(Faccel, Ncoef, nstep);
              for l = 1:Lc(ii)-1
                 G(:, nstep+l) = circshift(G(:, nstep + l - 1), L/Lc(ii));
              end              
              nstep = nstep + Lc(ii);
          end
      otherwise
          tmpf = zeros(Ncoef,1); tmpf(1) = 1;
          for n = 1:Ncoef
              G(:,n) = Faccel.frsyn(tmpf);
              tmpf = circshift(tmpf,1);
          end
  end
end;

function g = comp_framevector(Faccel,Ncoef,nidx)
tmpf = zeros(Ncoef,1); tmpf(nidx) = 1;
g = Faccel.frsyn(tmpf);


