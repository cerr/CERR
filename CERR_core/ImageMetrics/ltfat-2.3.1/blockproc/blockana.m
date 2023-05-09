function [c, fola] = blockana(F, f, fola)
%-*- texinfo -*-
%@deftypefn {Function} blockana
%@verbatim
%BLOCKANA Blockwise analysis interface
%   Usage: c=blockana(F, f)
%
%   Input parameters:
%      Fa   : Analysis frame object.    
%      f    : Block of signal.
%      fola : Explicitly defined overlap
%   Output parameters:
%      c    : Block coefficients.
%      fola : Stored overlap
%
%   c=BLOCKANA(Fa,f) calculates the coefficients c of the signal block f using 
%   the frame defined by F. The block overlaps are handled according to the 
%   F.blokalg. Assuming BLOCKANA is called in the loop only once, fola*
%   can be omitted and the overlaps are handled in the background
%   automatically.    
%
%
%   References:
%     N. Holighaus, M. Doerfler, G. A. Velasco, and T. Grill. A framework for
%     invertible, real-time constant-Q transforms. IEEE Transactions on
%     Audio, Speech and Language Processing, 21(4):775 --785, 2013.
%     
%     Z. Průša. Segmentwise Discrete Wavelet Transform. PhD thesis, Brno
%     University of Technology, Brno, 2012.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/blockproc/blockana.html}
%@seealso{block, blocksyn, blockplay}
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
    
complainif_notenoughargs(nargin,2,'BLOCKANA');
complainif_notvalidframeobj(F,'BLOCKANA');
    
    if nargin<3
       fola = [];
    end
    
    if ~isfield(F,'blockalg')
        F.blockalg = 'naive';
    end
    
    % Block length
    Lb = size(f,1);
    
    if ~isfield(F,'L')
         error(['%s: The frame object was not accelerated. See ',...
                'BLOCKFRAMEACCEL.'],upper(mfilename));
    end
    
    % Next block index start (from a global point of view, starting with zero)
    nextSb = block_interface('getPos');
    % Block index start (from a global point of view, starting with zero)
    Sb = nextSb-Lb;
    
    do_sliced = strcmp(F.blockalg,'sliced');
    do_segola = strcmp(F.blockalg,'segola');
    
    if strcmp(F.blockalg,'naive')
       if F.L < Lb
          error(['%s: The frame object was accelerated with incompatible ',...
                 'length. The block length is %i but the accelerated ',...
                 'length is %i.'],upper(mfilename),Lb,F.L);
       end
       % Most general. Should work for anything.
       % Produces awful block artifacts when coefficients are altered.
       f = [f; zeros(F.L-size(f,1),size(f,2))];
       c = F.frana(f);
    elseif do_sliced || do_segola

       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       %% STEP 1) Determine overlap lengths 
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       if do_sliced
          if F.L < 2*Lb
            error(['%s: The frame object was accelerated with incompatible ',...
                 'length. The effective block length is %i but the accelerated ',...
                 'length is %i.'],upper(mfilename),2*Lb,F.L);
          end 
           
          % Sliced real-time block processing
          % Equal block length assumtion
          Sbolen = Lb;
          nextSbolen = Lb;
       else
             if ~isfield(F,'winLen') 
                error('%s: Frame does not have FIR windows.',upper(mfilename));
             end
             % Window length
             Lw = F.winLen;
          switch(F.type)
             case 'fwt'
                J = F.J;
                w = F.g;
                m = numel(w.h{1}.h);
                a = w.a(1);
                if Lb<a^J
                   error('%s: Minimum block length is 2^%i=%i.',upper(mfilename),J,a^J);
                end
                rred = (a^J-1)/(a-1)*(m-a);
                Sbolen = rred + mod(Sb,a^J);
                nextSbolen = rred + mod(nextSb,a^J);
             case {'dgtreal','dgt','dwilt','wmdct'}
                a = F.a; 
                Sbolen = ceil((Lw-1)/a)*a + mod(Sb,a);
                nextSbolen = ceil((Lw-1)/a)*a + mod(nextSb,a);
             case {'filterbank','filterbankreal','ufilterbank','ufilterbankreal'}
                a = F.lcma;
                if Lw-1 < a
                   Sbolen = mod(Sb,a);
                   nextSbolen = mod(nextSb,a);
                else
                   Sbolen = ceil((Lw-1)/a)*a + mod(Sb,a);
                   nextSbolen = ceil((Lw-1)/a)*a + mod(nextSb,a);
                end
                %Sbolen = ceil((Lw-1)/a)*a + mod(Sb,a);
                %nextSbolen = ceil((Lw-1)/a)*a + mod(nextSb,a);
             otherwise
                error('%s: Unsupported frame.',upper(mfilename));
          end
       end
       
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       %% STEP 2) Common overlap handling 
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       if nargout>1 && isempty(fola)
           % Avoiding case when empty fola means just uninitialized 
           % custom overlap.
           fola = 0;
       end
       % Append the previous block
       fext = [loadOverlap(Sbolen,size(f,2),fola);f];
       % Save the current block
       if nargout>1
          fola = storeOverlap(fext,nextSbolen);
       else
          storeOverlap(fext,nextSbolen);
       end
       
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       %% STEP 3) Do the rest
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       if do_sliced
          % Multiply by the slicing window (all channels)
          fwin = bsxfun(@times,F.sliwin,fext);
          % If some padding is necessary, do it symmetrically
          pad = F.L-size(fwin,1);
          W = size(fwin,2);
          fwin = [zeros(floor(pad/2),W);...
                  fwin;...
                  zeros(ceil(pad/2),W)];
          % Apply transform
          c = F.frana(fwin);
       else
          switch(F.type)
             case 'fwt'
                c = block_fwt(fext,w,J);
             case {'dgtreal','dgt','dwilt','wmdct'}
                Lwl = floor(Lw/2);
                Lext = Sbolen + Lb - nextSbolen + Lwl;
                startc = ceil(Lwl/a)+1;
                endc = ceil((Lext)/a);
                % Pad with zeros to comply with the frame requirements
                fext = [fext; zeros(F.L-size(fext,1),size(fext,2))];
                c = F.frana(fext(1:F.L,:));
                % Pick just valid coefficients
                cc = F.coef2native(c,size(c));
                cc = cc(:,startc:endc,:);
                c = F.native2coef(cc);
             case {'filterbank','filterbankreal'}
                % Subsampling factors
                a = F.a(:,1);
                % Filter lengths
                gl = F.g_info.gl;
                % Filter offsets
                Lwl = max(gl+F.g_info.offset-1);
                Lext = Sbolen + Lb - nextSbolen + Lwl;
                startc = ceil(Lwl./a)+1;
                endc = ceil((Lext)./a);
                
                fext = [fext; zeros(F.L-size(fext,1),size(fext,2))];
                c = F.frana(fext(1:F.L,:));
                cc = F.coef2native(c,size(c));
                cc = cellfun(@(cEl,sEl,eEl) cEl(sEl:eEl,:),cc,num2cell(startc),num2cell(endc),'UniformOutput',0);
                c = F.native2coef(cc);
          end
       end
    else
       error('%s: Frame was not created with blockaccel.',upper(mfilename));
    end

end % BLOCKANA

function overlap = loadOverlap(L,chan,overlap)
%LOADOVERLAP Loads overlap
%
%
    if isempty(overlap)
       overlap = block_interface('getAnaOverlap');
    end

    % Supply zeros if it is empty
    if isempty(overlap)
        overlap = zeros(L,chan,block_interface('getClassId'));
    end
    Lo = size(overlap,1);
    if nargin<1
        L = Lo;
    end
    % If required more than stored, do zero padding
    if L>Lo
        oTmp = zeros(L,chan);
        oTmp(end-Lo+1:end,:) = oTmp(end-Lo+1:end,:)+overlap;
        overlap = oTmp;
    else
        overlap = overlap(end-L+1:end,:);
    end
    
end % LOADOVERLAP

function overlap = storeOverlap(fext,L)
%STOREOVERLAP Stores overlap
%
%
    if L>size(fext,1)
        error('%s: Storing more samples than passed.',upper(mfilename));
    end
    overlap = fext(end-L+1:end,:);
    
    if nargout<1
       block_interface('setAnaOverlap',overlap); 
    end
end % STOREOVERLAP


