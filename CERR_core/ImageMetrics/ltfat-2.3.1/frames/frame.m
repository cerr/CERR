function F=frame(ftype,varargin);
%-*- texinfo -*-
%@deftypefn {Function} frame
%@verbatim
%FRAME  Construct a new frame
%   Usage: F=frame(ftype,...);
%
%   F=FRAME(ftype,...) constructs a new frame object F of type
%   ftype. Arguments following ftype are specific to the type of frame
%   chosen.
%
%   Time-frequency frames
%   ---------------------
%
%   FRAME('dgt',g,a,M) constructs a Gabor frame with window g,
%   time-shift a and M channels. See the help on DGT for more
%   information.
%
%   FRAME('dgtreal',g,a,M) constructs a Gabor frame for real-valued
%   signals with window g, time-shift a and M channels. See the help
%   on DGTREAL for more information.
%
%   FRAME('dwilt',g,M) constructs a Wilson basis with window g and M*
%   channels. See the help on DWILT for more information.
%
%   FRAME('wmdct',g,M) constructs a windowed MDCT basis with window g*
%   and M channels. See the help on WMDCT for more information.
%
%   FRAME('filterbank',g,a,M) constructs a filterbank with filters g,
%   time-shifts of a and M channels. For the ease of implementation, it
%   is necessary to specify M, even though it strictly speaking could be
%   deduced from the size of the windows. See the help on FILTERBANK for
%   more information on the parameters. Similarly, you can construct a
%   uniform filterbank by selecting 'ufilterbank', a positive-frequency
%   filterbank by selecting 'filterbankreal' or a uniform
%   positive-frequency filterbank by selecting 'ufilterbankreal'.
%
%   FRAME('nsdgt',g,a,M) constructs a non-stationary Gabor frame with
%   filters g, time-shifts of a and M channels. See the help on
%   NSDGT for more information on the parameters. Similarly, you can
%   construct a uniform NSDGT by selecting 'unsdgt', an NSDGT for
%   real-valued signals only by selecting 'nsdgtreal' or a
%   uniform NSDGT for real-valued signals by selecting 'unsdgtreal'.
%
%   Wavelet frames
%   --------------
%
%   FRAME('fwt', w, J) constructs a wavelet frame with wavelet definition 
%   w and J number of filterbank iterations. Similarly, a redundant time 
%   invariant wavelet representation can be constructed by selecting 'ufwt'.
%   See the help on FWT and UFWT for more information.
%
%   FRAME('wfbt', wt) constructs a wavelet filterbank tree defined by
%   the wavelet filterbank tree definition wt. Similarly, an undecimated
%   wavelet filterbank tree can be constructed by selecting 'uwfbt'. See the
%   help on WFBT and UWFBT for more information.
%
%   FRAME('wpfbt', wt) constructs a wavelet packet filterbank tree 
%   defined by the wavelet filterbank tree definition wt. Similarly, an
%   undecimated wavelet packet filterbank tree can be constructed by selecting
%   'uwpfbt'. See the help on WPFBT and UWPFBT for more information.
%
%   Pure frequency frames
%   ---------------------
%
%   FRAME('dft') constructs a basis where the analysis operator is the
%   DFT, and the synthesis operator is its inverse, IDFT. Completely
%   similar to this, you can enter the name of any of the cosine or sine
%   transforms DCTI, DCTII, DCTIII, DCTIV, DSTI, DSTII,
%   DSTIII or DSTIV.
%
%   FRAME('dftreal') constructs a normalized FFTREAL basis for
%   real-valued signals of even length only. The basis is normalized
%   to ensure that is it orthonormal.
%
%   Special / general frames
%   ------------------------
%
%   FRAME('gen',g) constructs a general frame with a synthesis matrix g.
%   The frame atoms must be stored as column vectors in the matrix.
%
%   FRAME('identity') constructs the canonical orthonormal basis, meaning
%   that all operators return their input as output, so it is the dummy
%   operation.
%
%   Container frames
%   ----------------
%
%   FRAME('fusion',w,F1,F2,...) constructs a fusion frame, which is
%   the collection of the frames specified by F1, F2,... The vector
%   w contains a weight for each frame. If w is a scalar, this weight
%   will be applied to all the sub-frames.
%
%   FRAME('tensor',F1,F2,...) constructs a tensor product frame, where the
%   frames F1, F2,... are applied along the 1st, 2nd etc. dimensions. If
%   you don't want any action along a specific dimension, use the identity
%   frame along that dimension. Any remaining dimensions in the input
%   signal are left alone.
%
%   Wrapper frames
%   --------------
%
%   Frames types in this section are "virtual". They serve as a wrapper for
%   a different type of frame.
%
%   FRAME('erbletfb',fs,Ls,...) constructs an Erb-let filterbank frame for
%   a given samp. frequency fs working with signals of length Ls. See
%   ERBFILTERS for a description of additional parameters as all 
%   parameters other than the frame type string 'erbletfb' are passed to it.
%   NOTE: The resulting frame is defined only for a single signal length
%   Ls. Shorter signals will be zero-padded, signals longer than Ls*
%   cannot be processed.
%   The actual frame type is 'filterbank' or 'filterbankreal'.
%
%   FRAME('cqtfb',fs,fmin,fmax,bins,Ls,...) constructs a CQT filterbank 
%   frame for a given samp. frequency fs working with signals of length 
%   Ls. See CQTFILTERS for a description of other parameters.
%   NOTE: The resulting frame is defined only for a single signal length
%   Ls. Shorter signals will be zero-padded, signals longer than Ls*
%   cannot be processed.
%   The actual frame type is 'filterbank' or 'filterbankreal'.
%  
%   Examples
%   --------
%
%   The following example creates a Modified Discrete Cosine Transform frame,
%   analyses an input signal and plots the frame coefficients:
%
%      F=frame('wmdct','gauss',40);
%      c=frana(F,greasy);
%      plotframe(F,c,'dynrange',60);
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/frames/frame.html}
%@seealso{frana, frsyn, plotframe}
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

  
complainif_notenoughargs(nargin,1,'FRAME');

if ~ischar(ftype)
  error(['%s: First argument must be a string denoting the type of ' ...
         'frame.'],upper(mfilename));
end;

ftype=lower(ftype);

% True if the frame only works with real-valued input.
F.realinput=0;

% True if the frame only works with a fixed length.
F.fixedlength = 0;

% Handle the windowed transforms
switch(ftype)
 case {'dgt','dwilt','wmdct','filterbank','ufilterbank',...
       'nsdgt','unsdgt','wfbt','uwfbt','wpfbt'}
  F.g=varargin{1};
  
 case {'dgtreal','filterbankreal','ufilterbankreal',...
      'nsdgtreal','unsdgtreal'}
  F.g=varargin{1};
  F.realinput=1;
  
 case {'fwt','ufwt'}
  F.g=varargin{1};
  F.J=varargin{2};
  complainif_notposint(F.J,'J','FRAME');
end;

% Input param checking
switch(ftype)
  case 'fusion'
     wtmp = varargin{1};
     % Check w 
     if ~isnumeric(varargin{1}) || ...
        ~(isscalar(wtmp) || numel(wtmp) == numel(varargin) -1)
       error('%s: Weights are not in a correct format.',upper(mfilename));
     end
     
     % Check frame objects
     for ii=2:numel(varargin)
        complainif_notvalidframeobj(varargin{ii},'FRAME');
     end
  case 'tensor'
     % Check frame objects
     for ii=1:numel(varargin)
        complainif_notvalidframeobj(varargin{ii},'FRAME');
     end        
end


% For parsing optional parameters to the transforms.
vargs={};
definput=struct();

%% ---- Pre-optional parameters
% Common operations to deal with the input parameters.
switch(ftype)
  case {'dgt','dgtreal'}
    F.a=varargin{2};
    F.M=varargin{3};
    
    vargs=varargin(4:end);
    definput.keyvals.lt=[0 1];
    definput.flags.phase={'freqinv','timeinv'};    

  case {'dwilt','wmdct'}
    F.M=varargin{2};
  case {'filterbank','ufilterbank','filterbankreal','ufilterbankreal'}
    F.a=varargin{2};
    F.M=varargin{3};
    
    [F.a,~]=comp_filterbank_a(F.a,F.M,struct());
    
  case {'nsdgt','unsdgt','nsdgtreal','unsdgtreal'}
    F.a=varargin{2};
    F.M=varargin{3};
    
    % Sanitize 'a' and 'M'. Make M a column vector of length N,
    % where N is determined from the length of 'a'
    F.a=F.a(:);
    F.N=numel(F.a);
    F.M=bsxfun(@times,F.M(:),ones(F.N,1));
  case {'ufwt'}
    vargs=varargin(3:end);
    definput.flags.scaling={'sqrt','noscale','scale'};
  case {'uwfbt'}
    vargs=varargin(2:end);
    definput.flags.scaling={'sqrt','noscale','scale'};
  case {'wpfbt'}
    vargs=varargin(2:end);
    definput.flags.interscaling={'intsqrt','intnoscale','intscale'};
  case {'uwpfbt'}
    vargs=varargin(2:end);
    definput.flags.interscaling={'intsqrt','intnoscale','intscale'};
    definput.flags.scaling={'sqrt','noscale','scale'};
end;

[F.flags,F.kv]=ltfatarghelper({},definput,vargs);

F.type=ftype;
F.origargs=varargin;
F.vargs=vargs;


%% ------ Post optional parameters

% Default value, works for all bases
F.red=1;

% Default value, frame works for all lengths
F.length=@(Ls) Ls;

switch(ftype)
  case 'gen'
    F.g=varargin{1};
    F.frana=@(insig) F.g'*insig;
    F.frsyn=@(insig) F.g*insig;
    F.length = @(Ls) size(F.g,1);
    F.red = size(F.g,2)/size(F.g,1);
      
  case 'identity'
    F.frana=@(insig) insig;
    F.frsyn=@(insig) insig;
    
  case 'dft'
    F.frana=@(insig) dft(insig,[],1);
    F.frsyn=@(insig) idft(insig,[],1);
    
  case 'dftreal'
    F.frana=@(insig) fftreal(insig,[],1)/sqrt(size(insig,1));
    F.frsyn=@(insig) ifftreal(insig,(size(insig,1)-1)*2,1)*sqrt((size(insig,1)-1)*2);
    F.length=@(Ls) ceil(Ls/2)*2;
    F.lengthcoef=@(Ncoef) (Ncoef-1)*2;
    F.realinput=1;
    F.clength = @(L) floor(L/2)+1;

  case 'dcti'
    F.frana=@(insig) dcti(insig,[],1);
    F.frsyn=@(insig) dcti(insig,[],1);

  case 'dctii'
    F.frana=@(insig) dctii(insig,[],1);
    F.frsyn=@(insig) dctiii(insig,[],1);

  case 'dctiii'
    F.frana=@(insig) dctiii(insig,[],1);
    F.frsyn=@(insig) dctii(insig,[],1);

  case 'dctiv'
    F.frana=@(insig) dctiv(insig,[],1);
    F.frsyn=@(insig) dctiv(insig,[],1);

  case 'dsti'
    F.frana=@(insig) dsti(insig,[],1);
    F.frsyn=@(insig) dsti(insig,[],1);

  case 'dstii'
    F.frana=@(insig) dstii(insig,[],1);
    F.frsyn=@(insig) dstiii(insig,[],1);

  case 'dstiii'
    F.frana=@(insig) dstiii(insig,[],1);
    F.frsyn=@(insig) dstii(insig,[],1);

  case 'dstiv'
    F.frana=@(insig) dstiv(insig,[],1);
    F.frsyn=@(insig) dstiv(insig,[],1);

  case 'dgt'
    F.coef2native=@(coef,s) reshape(coef,[F.M,s(1)/F.M,s(2)]);
    F.native2coef=@(coef)   reshape(coef,[size(coef,1)*size(coef,2),size(coef,3)]);
    F.frana=@(insig) F.native2coef(comp_dgt(insig,F.g,F.a,F.M,F.kv.lt,F.flags.do_timeinv,0,0));
    F.frsyn=@(insig) comp_idgt(F.coef2native(insig,size(insig)),F.g,F.a,F.kv.lt,F.flags.do_timeinv,0);    
    F.length=@(Ls) dgtlength(Ls,F.a,F.M,F.kv.lt);
    F.red=F.M/F.a;
    
  case 'dgtreal'
    F.coef2native=@(coef,s) reshape(coef,[floor(F.M/2)+1,s(1)/(floor(F.M/ ...
                                                      2)+1),s(2)]);
    F.native2coef=@(coef)   reshape(coef,[size(coef,1)*size(coef,2),size(coef,3)]);
    F.frana=@(insig) F.native2coef(comp_dgtreal(insig,F.g,F.a,F.M,F.kv.lt,F.flags.do_timeinv));
    F.frsyn=@(insig) comp_idgtreal(F.coef2native(insig,size(insig)),F.g,F.a,F.M,F.kv.lt,F.flags.do_timeinv);  
    F.length=@(Ls) dgtlength(Ls,F.a,F.M,F.kv.lt);
    F.red=F.M/F.a;
    F.lengthcoef=@(Ncoef) Ncoef/(floor(F.M/2)+1)*F.a;
    F.clength = @(L) L/F.a*(floor(F.M/2)+1);
    
  case 'dwilt'
    F.coef2native=@(coef,s) reshape(coef,[2*F.M,s(1)/F.M/2,s(2)]);
    F.native2coef=@(coef)   reshape(coef,[size(coef,1)*size(coef,2),size(coef,3)]);
    F.frana=@(insig) F.native2coef(comp_dwilt(insig,F.g,F.M));
    F.frsyn=@(insig) comp_idwilt(F.coef2native(insig,size(insig)),F.g);  
    F.length=@(Ls) dwiltlength(Ls,F.M);
    
  case 'wmdct'
    F.coef2native=@(coef,s) reshape(coef,[F.M,s(1)/F.M,s(2)]);
    F.native2coef=@(coef)   reshape(coef,[size(coef,1)*size(coef,2),size(coef,3)]);
    F.frana=@(insig) F.native2coef(comp_dwiltiii(insig,F.g,F.M));
    F.frsyn=@(insig) comp_idwiltiii(F.coef2native(insig,size(insig)),F.g);  
    F.length=@(Ls) dwiltlength(Ls,F.M);        
    
  case 'filterbank'
    F.red=sum(F.a(:,2)./F.a(:,1));
    F.length=@(Ls) filterbanklength(Ls,F.a);
    F.lengthcoef=@(Ncoef) Ncoef/F.red;
    F.native2coef=@(coef) cell2mat(coef(:));
    F.coef2native=@(coef,s) vect2cell(coef,round(s(1)/F.red*F.a(:,2)./F.a(:,1)));
    F.frana=@(insig) F.native2coef(comp_filterbank(insig,F.g,F.a));
    F.frsyn=@(insig) comp_ifilterbank(F.coef2native(insig,size(insig)),...
                                      F.g,F.a,round(size(insig,1)/F.red));
    F.destructor=@() clear('comp_filterbank','comp_ifilterbank');
    
  case 'filterbankreal'
    F.red=2*sum(F.a(:,2)./F.a(:,1));
    F.length=@(Ls) filterbanklength(Ls,F.a);
    F.lengthcoef=@(Ncoef) 2*Ncoef/(F.red);
    F.native2coef=@(coef) cell2mat(coef(:));
    F.coef2native=@(coef,s) vect2cell(coef,round(2*s(1)/F.red*F.a(:,2)./F.a(:,1)));
    F.frana=@(insig) F.native2coef(comp_filterbank(insig,F.g,F.a));
    F.frsyn=@(insig) 2*real(comp_ifilterbank(F.coef2native(insig,size(insig)),F.g,F.a,...
                                             round(2*size(insig,1)/F.red)));
    F.destructor=@() clear('comp_filterbank','comp_ifilterbank');
    
  case 'ufilterbank'
    F.red=sum(F.a(:,2)./F.a(:,1));
    F.length=@(Ls) filterbanklength(Ls,F.a);
    F.lengthcoef=@(Ncoef) round(Ncoef/F.red);
    F.coef2native=@(coef,s) reshape(coef,[s(1)/F.M,F.M,s(2)]);
    F.native2coef=@(coef)   reshape(coef,[size(coef,1)*size(coef,2),size(coef,3)]);
    F.frana=@(insig) F.native2coef(ufilterbank(insig,F.g,F.a));
    F.frsyn=@(insig) ifilterbank(F.coef2native(insig,size(insig)),F.g,F.a);   
    
  case 'ufilterbankreal'
    F.red=2*sum(F.a(:,2)./F.a(:,1));
    F.length=@(Ls) filterbanklength(Ls,F.a);
    F.lengthcoef=@(Ncoef) round(Ncoef/F.red*2);
    F.coef2native=@(coef,s) reshape(coef,[s(1)/F.M,F.M,s(2)]);
    F.native2coef=@(coef)   reshape(coef,[size(coef,1)*size(coef,2),size(coef,3)]);
    F.frana=@(insig) F.native2coef(ufilterbank(insig,F.g,F.a));
    F.frsyn=@(insig) 2*real(ifilterbank(F.coef2native(insig,size(insig)),F.g, ...
                                        F.a));
    
  case 'nsdgt'
    F.coef2native=@(coef,s) mat2cell(coef,F.M,s(2));
    F.native2coef=@(coef) cell2mat(coef(:));
    F.length=@(Ncoef) sum(F.a);
    F.lengthcoef=@(Ncoef) sum(F.a);
    F.red=sum(F.M)/sum(F.a);
    F.frana=@(insig) F.native2coef(nsdgt(insig,F.g,F.a,F.M));
    F.frsyn=@(insig) insdgt(F.coef2native(insig,size(insig)),F.g,F.a);
    
  case 'unsdgt'
    F.coef2native=@(coef,s) reshape(coef,[F.M(1),s(1)/F.M(1),s(2)]);
    F.native2coef=@(coef)   reshape(coef,[size(coef,1)*size(coef,2),size(coef,3)]);
    F.frana=@(insig) F.native2coef(unsdgt(insig,F.g,F.a,F.M));
    F.frsyn=@(insig) insdgt(F.coef2native(insig,size(insig)),F.g,F.a);
    F.length=@(Ncoef) sum(F.a);
    F.lengthcoef=@(Ncoef) sum(F.a);
    F.red=sum(F.M)/sum(F.a);    

  case 'nsdgtreal'
    F.coef2native=@(coef,s) mat2cell(coef,floor(F.M/2)+1,s(2));
    F.native2coef=@(coef) cell2mat(coef(:));
    F.frana=@(insig) F.native2coef(nsdgtreal(insig,F.g,F.a,F.M));
    F.frsyn=@(insig) insdgtreal(F.coef2native(insig,size(insig)),F.g,F.a,F.M);
    F.length=@(Ncoef) sum(F.a);
    F.lengthcoef=@(Ncoef) sum(F.a);
    F.red=sum(F.M)/sum(F.a); 
    F.clength=@(L) sum(floor(F.M/2)+1);
    
  case 'unsdgtreal'
    F.coef2native=@(coef,s) reshape(coef,floor(F.M(1)/2)+1,s(1)/ ...
                                    (floor(F.M(1)/2)+1),s(2));
    F.native2coef=@(coef)   reshape(coef,[size(coef,1)*size(coef,2),size(coef,3)]);
    F.frana=@(insig) F.native2coef(unsdgtreal(insig,F.g,F.a,F.M));
    F.frsyn=@(insig) insdgtreal(F.coef2native(insig,size(insig)),F.g,F.a,F.M);
    F.length=@(Ncoef) sum(F.a);
    F.lengthcoef=@(Ncoef) sum(F.a);
    F.red=sum(F.M)/sum(F.a); 
    F.clength=@(L) numel(F.M)*(floor(F.M(1)/2)+1);
                
  case 'fusion'
    F.w=varargin{1};
    F.frames=varargin(2:end);
    
    if any(cellfun(@(fEl) fEl.realinput,F.frames))
        error(['%s: Real-valued-input-only frames are not currently ',...
               'supported in the fusion frame.'],upper(mfilename));
    end
    
    F.Nframes=numel(F.frames);
    F.w=bsxfun(@times,F.w(:),ones(F.Nframes,1));    
    F.length = @(Ls) comp_framelength_fusion(F,Ls);
    F.red=sum(cellfun(@framered,F.frames));
    
    % These definitions binds F itself, so they must execute last
    F.frana=@(insig) comp_frana_fusion(F,insig);
    F.frsyn=@(insig) comp_frsyn_fusion(F,insig);

    
  case 'tensor'
    % This frame type is currently broken. It must be reworked to reshape
    % to the standard layout in order not to break all the assumptions.
    F.frames=varargin;
    F.Nframes=numel(F.frames);
    for ii=1:F.Nframes
        if F.frames{ii}.realinput
            error(['It is not safe to embed a real-valued-input-only frame ' ...
                   'into the tensor frame.']);
        end;
    end;
    
    F.frana=@(insig) comp_frana_tensor(F,insig);
    F.frsyn=@(insig) comp_frsyn_tensor(F,insig);
    
    F.length=@(Ls) comp_framelength_tensor(F,Ls);

    F.red=prod(cellfun(@framered,F.frames));
    
  case {'fwt','dwt'}
    % We have to initialize F.g here already
    [F.g, F.info]=fwtinit({'strict',F.g});
    F.red= 1/(F.g.a(1)^(F.J)) + sum(1./(F.g.a(1).^(0:F.J-1))*sum(1./F.g.a(2:end)));
    F.frana=@(insig) wavcell2pack(comp_fwt(insig,F.g.h,F.g.a,F.J,'per'));
    F.frsyn=@(insig) comp_ifwt(...
                        wavpack2cell(insig,fwtclength(size(insig,1)/F.red,F.g,F.J)),...
                               F.g.g,F.g.a,F.J,size(insig,1)/F.red,'per');
    F.length=@(Ls) fwtlength(Ls,F.g,F.J);
  case {'wfbt'}
    [F.g,F.info]=wfbtinit({'strict',F.g});
    F.red = sum(1./treeSub(F.g));
    % comp_ specific
    [F.wtPath, F.rangeLoc, F.rangeOut] = treeBFranges(F.g);
    
    F.coef2native = @(coef,s) wavpack2cell(coef,wfbtclength(s(1)/F.red,F.g));
    F.native2coef = @(coef) wavcell2pack(coef);
    F.frana=@(insig) F.native2coef(comp_wfbt(insig,F.g.nodes(F.wtPath),...
                                             F.rangeLoc,F.rangeOut,'per'));
    F.frsyn=@(insig) comp_iwfbt(F.coef2native(insig,size(insig)),...
                                F.g.nodes(F.wtPath(end:-1:1)),...
                                [nodesInLen(F.wtPath(end:-1:1),size(insig,1)/F.red,1,F.g);size(insig,1)/F.red],...
                                F.rangeLoc(end:-1:1),F.rangeOut(end:-1:1),...
                                'per');
    F.length=@(Ls) wfbtlength(Ls,F.g);
  case {'wpfbt'}
    F.g=wfbtinit({'strict',F.g});
    F.red = sum(cellfun(@(aEl) sum(1./aEl),nodesSub(nodeBForder(0,F.g),F.g)));
    % comp_ specific
    F.wtPath = nodeBForder(0,F.g);
    F.rangeLoc = nodesLocOutRange(F.wtPath,F.g);
    [F.pOutIdxs,F.chOutIdxs] = treeWpBFrange(F.g);
    
    F.coef2native = @(coef,s) wavpack2cell(coef,...
                    s(1)./cell2mat(cellfun(@(aEl) aEl(:),...
                    reshape(nodesSub(nodeBForder(0,F.g),F.g),[],1),...
                    'UniformOutput',0))./F.red);
    F.native2coef = @(coef) wavcell2pack(coef);

    F.frana=@(insig) F.native2coef(...
                        comp_wpfbt(insig,F.g.nodes(F.wtPath),...
                                   F.rangeLoc,'per',F.flags.interscaling));
    F.frsyn=@(insig) comp_iwpfbt(F.coef2native(insig,size(insig)),...
                                 F.g.nodes(F.wtPath(end:-1:1)),...
                                 F.pOutIdxs,F.chOutIdxs,...
                                 size(insig,1)/F.red,...
                                 'per',F.flags.interscaling);
    F.length=@(Ls) wfbtlength(Ls,F.g);
  case {'ufwt'}
    F.g=fwtinit({'strict',F.g});
    F.coef2native = @(coef,s) reshape(coef,[s(1)/(F.J*(numel(F.g.a)-1)+1),F.J*(numel(F.g.a)-1)+1,s(2)]);
    F.native2coef = @(coef) reshape(coef,[size(coef,1)*size(coef,2),size(coef,3)]);
    F.frana=@(insig) F.native2coef(comp_ufwt(insig,F.g.h,F.g.a,F.J,F.flags.scaling));
    F.frsyn=@(insig) comp_iufwt(F.coef2native(insig,size(insig)),F.g.g,F.g.a,F.J,F.flags.scaling);
    F.length=@(Ls) Ls;
    F.red=(F.J*(numel(F.g.a)-1)+1);
  case {'uwfbt'}
    F.g=wfbtinit({'strict',F.g});

    % comp_ specific
    [F.wtPath, F.rangeLoc, F.rangeOut] = treeBFranges(F.g);
    F.nodesUps = nodesFiltUps(F.wtPath,F.g);
    F.red = sum(cellfun(@numel,F.rangeOut));
    
    F.coef2native = @(coef,s) reshape(coef,[s(1)/F.red,F.red,s(2)]);
    F.native2coef = @(coef) reshape(coef,[size(coef,1)*size(coef,2),size(coef,3)]);
    F.frana=@(insig) F.native2coef(...
                        comp_uwfbt(insig,F.g.nodes(F.wtPath),F.nodesUps,...
                                   F.rangeLoc,F.rangeOut,F.flags.scaling));
    F.frsyn=@(insig) comp_iuwfbt(F.coef2native(insig,size(insig)),...
                                 F.g.nodes(F.wtPath(end:-1:1)),...
                                 F.nodesUps(end:-1:1),F.rangeLoc(end:-1:1),...
                                 F.rangeOut(end:-1:1),F.flags.scaling);
    F.length=@(Ls) Ls;
  case {'uwpfbt'}
    F.g= wfbtinit({'strict',varargin{1}});
    F.red = sum(cellfun(@(fEl) numel(fEl.g),F.g.nodes));
    % comp_ specific
    F.wtPath = nodeBForder(0,F.g);
    F.nodesUps = nodesFiltUps(F.wtPath,F.g);
    F.rangeLoc = nodesLocOutRange(F.wtPath,F.g);
    [F.pOutIdxs,F.chOutIdxs] = treeWpBFrange(F.g);
    
    F.coef2native = @(coef,s) reshape(coef,[s(1)/F.red,F.red,s(2)]);
    F.native2coef = @(coef) reshape(coef,[size(coef,1)*size(coef,2),size(coef,3)]);
    F.frana=@(insig) F.native2coef(...
                        comp_uwpfbt(insig,F.g.nodes(F.wtPath),F.rangeLoc,...
                                    F.nodesUps,F.flags.scaling,...
                                    F.flags.interscaling));
    F.frsyn=@(insig) comp_iuwpfbt(F.coef2native(insig,size(insig)),...
                                  F.g.nodes(F.wtPath(end:-1:1)),...
                                  F.nodesUps(end:-1:1),F.pOutIdxs,F.chOutIdxs,...
                                  F.flags.scaling,F.flags.interscaling);
    F.length=@(Ls) Ls;

    
  %%%%%%%%%%%%%%%%%%%%
  %% WRAPPER FRAMES %%
  %%%%%%%%%%%%%%%%%%%%
  case {'erbletfb','cqtfb'}
    switch(ftype)
        case 'erbletfb'
            [g,a,~,L] = erbfilters(varargin{:});
        case 'cqtfb'
            [g,a,~,L] = cqtfilters(varargin{:});
    end
    % Search for the 'complex' flag
    do_complex = ~isempty(varargin(strcmp('complex',varargin)));
    if do_complex
       F = frameaccel(frame('filterbank',g,a,numel(g)),L);
    else
       F = frameaccel(frame('filterbankreal',g,a,numel(g)),L);
    end
    F.fixedlength = 1;
 
  otherwise
    error('%s: Unknown frame type: %s',upper(mfilename),ftype);  

end;


% This one is placed at the end, to allow for F.red to be defined
% first.
if ~isfield(F,'lengthcoef')
    F.lengthcoef=@(Ncoef) Ncoef/framered(F);
end;






