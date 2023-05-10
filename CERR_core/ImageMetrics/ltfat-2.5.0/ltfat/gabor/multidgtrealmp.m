function [c, frec, info] = multidgtrealmp(f,dicts,varargin)
%MULTIDGTREALMP  Matching Pursuit Decomposition with Multi-Gabor Dictionary
%   Usage:  c = multidgtrealmp(f,dicts)
%           c = multidgtrealmp(f,dicts,errdb,maxit)
%           [c,frec,info] = multidgtrealmp(...)
%
%   Input parameters:
%       f        : Input signal
%       dicts    : Dictionaries. Format {g1,a1,M1,g2,a2,M2,...}
%       errdb    : Target normalized approximation error in dB
%       maxit    : Maximum number of iterations.
%   Output parameters:
%       c        : Sparse representation
%       frec     : Reconstructed signal
%       info     : Struct with additional output paramerets
%
%   MULTIDGTREALMP(f,{g1,a1,M1,g2,a2,M2,...,gW,aW,MW}) returns sparse 
%   representation of a signal in W Gabor dictionaries using the 
%   fast matching pursuit algorithm. gw is a Gabor window defined
%   as in DGT and DGTREAL, aw is a hop factor, Mw is the number of 
%   frequency channels. All aw and Mw must be divisible by min(a1,...,aW).
%   The algorithm will try to reach -40 dB relative approximation error
%   in at most numel(f) iterations.
%   The function returns a cell-array with elements storing coefficients
%   for individual Gabor systems such that they can be directly used in
%   IDGTREAL. 
%
%   MULTIDGTREALMP(f,dicts,errdb,maxit) tries to reach normalized 
%   approximation error errdb dB in at most maxit iterations.
%
%   [c,frec,info] = MULTIDGTREALMP(...) in addition returns the
%   aproximation frec and a struct info with the following fields:
%
%     .iter     Number of iterations done.
%
%     .atoms    Number of atoms selected.
%
%     .relres   Final approximation error. If resets are enabled, this is a
%               vector additionally containing the approximation error at 
%               every reset.
%
%     .g        Cell array of numeric windows used in the multi-dictionary
%
%     .a        Array of hop factors for indivitual dictionaries
%
%     .M        Array of numbers of channels for individual dictionaries
%
%     .synthetize  Anonymous function which can be used to synthetize from
%                  the (modified) coefficients as 
%                  frec = sum(info.synthetize(c),dim)
%                  where dim=2 if the input f was a column vector and
%                  dim=1 if it was a row vector. 
%
%   The normalized approximation error is computed as 
%   errdb=20*log10(norm(f-frec)/norm(f)).
%
%   The function takes the following optional parameters at the end of
%   the line of input arguments:
%
%     'kenrnthr',kt     Kernel threshold. Must be in range ]0,1]. 
%                       Default is 1e-4.
%
%     'timeinv'         Use the time invariant phase convention. The
%                       default is 'freqinv'.
%
%     'pedanticsearch'  Be pedantic about the energy of pairs of 
%                       conjugated atoms in the selection step. 
%                       Disabled by default.
%
%     'algorithm',alg   Algorithm to use. Available: 
%                       'mp'(default),'selfprojmp','cyclicmp'
%
%     'reset'           Reset the decomposition until stopping criteria
%                       are met. The reset means a complete synthesis and 
%                       re-analysis. Available: 
%                       'noreset' (default), 'reset', 'quickreset'
%                       Option 'quickreset' applies a heuristic to stop the 
%                       algorithm more quickly when the targer error is 
%                       reached.
%
%   Reset conditions can be controlled by the following key-value pairs:
%
%     'resetit',it      Reset the decomposition every it iteration.
%                       Must be a positive integer.
%
%     'reseterrdb',err  Reset the decomposition when the error estimate 
%                       in dB decreases below err. Must be negative. 
%                       Default is 10*log10(1.1*kv.kernthr).
%
%   The computational routine is only available in C. Use LTFATMEX to
%   to compile it.
%
%   Algorithms
%   ----------
%
%   By default, the function uses the fast MP using approximate update 
%   in the coefficient domain as described in:
%   
%   "Z. Prusa, N. Holighaus, P. Balazs: Fast Matching Pursuit with Multi-Gabor Dictionaries"
%   
%   The kernel threshold limits the minimum approximation error which
%   can be reached. For example the default threshold 1e-4 in general 
%   allows achieving at least -40 dB.
% 
%   Note that this algorithm internally computes the error as
%   errdb = 10*log10(err(k)/norm(f)^2), with err(0) = norm(f)^2 and 
%   err(k) = err(k-1) - abs(cselected(k))^2. Here, cselected(k) is the
%   Gabor coefficient selected at the k-th MP step. This formula is exact 
%   only if the kernel threshold equals 0. Otherwise it serves as a cheap
%   estimate. The exact error is only computed when this function is run
%   with resets enabled and only in between resets. 
%   
%   Examples
%   --------
%
%   The following example shows the decomposition in 3 dictionaries and
%   plots contributions from the individual dictionaries and the residual.:
%
%       [f,fs] = gspi;
%       [c, frec, info] = multidgtrealmp(f,...
%       {'blackman',128,512,'blackman',512,2048,'blackman',2048,8192});
%       frecd = info.synthetize(c);
%       figure(1); 
%       xvals = (0:numel(f)-1)/fs;
%       subplot(4,1,1); plot(xvals,frecd(:,1));ylim([-0.5,0.5]);
%       subplot(4,1,2); plot(xvals,frecd(:,2));ylim([-0.5,0.5]);
%       subplot(4,1,3); plot(xvals,frecd(:,3));ylim([-0.5,0.5]);
%       subplot(4,1,4); plot(xvals,f-frec);ylim([-0.5,0.5]); xlabel('Time (s)');
%
%   See also: dgtreal idgtreal
%
%   References:
%     S. Mallat and Z. Zhang. Matching pursuits with time-frequency
%     dictionaries. IEEE Trans. Signal Process., 41(12):3397--3415, 1993.
%     
%     Z. Průša. Fast matching pursuit with multi-gabor dictionaries.
%     Submitted., 2018.
%     
%     L. Rebollo-Neira, M. Rozložník, and P. Sasmal. Analysis of a low memory
%     implementation of the orthogonal matching pursuit greedy strategy.
%     CoRR, abs/1609.00053v2, 2017.
%     
%     B. L. Sturm and M. G. Christensen. Cyclic matching pursuits with
%     multiscale time-frequency dictionaries. In Conf. Record of the 44th
%     Asilomar Conference on Signals, Systems and Computers, pages 581--585,
%     Nov 2010.
%     
%
%   Url: http://ltfat.github.io/doc/gabor/multidgtrealmp.html

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

%AUTHOR: Zdenek Prusa

thismfile = upper(mfilename);
complainif_notenoughargs(nargin,2,thismfile);
% Define initial value for flags and key/value pairs.
definput.keyvals.errdb=-40;
definput.keyvals.maxit=[];
definput.keyvals.resetit=0;
definput.keyvals.reseterrdb = 0;
%definput.keyvals.iterstep=[];
definput.keyvals.kernthr = 1e-4;
%definput.flags.print={'quiet','print'};
definput.flags.algversion={'fast','slow'};
definput.flags.algorithm={'mp','selfprojmp','cyclicmp'};
definput.flags.search={'plainsearch','pedanticsearch'};
definput.flags.phaseconv={'freqinv','timeinv'};
definput.flags.reset={'noreset','reset','quickreset'};

[flags,kv]=ltfatarghelper({'errdb','maxit'},definput,varargin);

if exist('comp_multidgtrealmp','file') ~= 3 && flags.do_fast
    error(['%s: MEX/OCT file is missing. Either compile the MEX/OCT ',...
           'interfaces or re-run the function with ''slow'''], thismfile);
end

if flags.do_slow
    error('%s: ''slow'' is not supported yet.',thismfile)
end

if flags.do_reset || flags.do_quickreset % Check reseterrdb or resetit
   if kv.reseterrdb == 0
        if kv.resetit == 0 % Set both to conservative default values depending on kernthr
            kv.reseterrdb = 10*log10(1.1*kv.kernthr);
            kv.resetit = round(1000/sqrt(kv.kernthr)); 
        else % If only resetit is given, ignore reseterrdb
            kv.reseterrdb = -flintmax;
        end
   elseif kv.resetit == 0 % If only reseterrdb is given, ignore resetit
        kv.resetit = flintmax;
   end   
   if kv.reseterrdb >= 0
       error('%s: Reset error tolerance must be negative.',thismfile);
   end
   if kv.resetit < 0 || kv.resetit ~= round(kv.resetit)
       error('%s: Number of iterations before reset must be a positive integer.',thismfile);
   end
end

%% ----- step 1 : Verify f and determine its length -------
% Change f to correct shape.
[f,~,Ls,W,dim,permutedsize,order]=assert_sigreshape_pre(f,[],[],upper(mfilename));

if W>1
    error('%s: Input signal can be single channel only.',upper(mfilename));
end

if kv.errdb > 0
    error('%s: Target error must be lower than 0 dB.',upper(mfilename));
end

if ~(kv.kernthr > 0 && kv.kernthr <= 1)
    error('%s: Kernel threshold must be in range ]0,1].',upper(mfilename));
end

if ~iscell(dicts), error('%s: dicts must be cell',thismfile); end
if rem(numel(dicts),3) ~= 0 || ~all(cellfun(@(x)isscalar(x), dicts([2:3:end,3:3:end])))
    error('%s: bad format of dicts. Check {g1,a1,M1,g2,a2,M2,...,gW,aW,MW}',...
        thismfile);
end

dictno = numel(dicts)/3;
gin = dicts(1:3:end);
a = cell2mat(dicts(2:3:end));
M = cell2mat(dicts(3:3:end));

if any(rem(M,a) ~= 0) || any(M./a<2)
    error(['%s: Only integer oversampling greater than 1 is allowed ',...
           'i.e. M/a must be an integer>=2.'],...
    upper(mfilename));
end

if dictno > 1
    asort  = sort(a);
    Msort  = sort(M);
    if any(rem(asort(2:end),asort(1:end-1)) ~= 0)
        error('%s: all au and av must be divisible by min(au,av)',thismfile);
    end
    if any(rem(Msort(2:end),Msort(1:end-1)) ~= 0)
        error('%s: all Mu and Mv must be divisible by min(Mu,Mv)',thismfile);
    end
end

info.a = a;
info.M = M;
info.iter = 0;
info.relres = [];
fnorm = norm(f);

L = filterbanklength(Ls,[a(:);M(:)]);
if isempty(kv.maxit), kv.maxit = L; end

info.g = cell(dictno,1);
for dIdx = 1:dictno
    info.g{dIdx} = setnorm(gabwin(gin{dIdx},a(dIdx),M(dIdx),L),'2');
end

for dIdx = 1:dictno
    condnum = gabframebounds(info.g{dIdx},a(dIdx),M(dIdx));
    if condnum > 1e3
        error('%s: Dictionary %d is badly conditioned.',dIdx,upper(mfilename));
    end
end

% Initial residuum
fpad = postpad(f,L);

% Determine reset/no reset mode and run MP decomposition 
if flags.do_noreset
    [c,info.atoms,info.iter,info.status] = comp_multidgtrealmp(fpad,info.g,a,M,flags.do_timeinv,...
                            kv.kernthr,kv.errdb,kv.maxit,kv.maxit,...
                            flags.do_pedanticsearch, flags.algorithm );
else
    c = cell(1,dictno);
    for dIdx = 1:dictno
        c{dIdx} = zeros(floor(M(dIdx)/2) + 1, L/a(dIdx),class(f));
    end

    remainingit = kv.maxit;
    currerrdb = kv.errdb;
        
    info.resets = -1;
    reseterrdb = kv.reseterrdb;

    while remainingit > 0 && currerrdb < 0
        info.resets = info.resets + 1;
        
        % Adjust number of iterations
        currit = min([remainingit,kv.resetit]);
        if flags.do_quickreset % Adjust reset error condition
            reseterrdb = max([1.2*currerrdb,kv.reseterrdb]);
        end

        [ctmp,info.atoms,info.iter,info.status] = ...
            comp_multidgtrealmp(fpad,info.g,a,M,flags.do_timeinv,...
                                kv.kernthr,reseterrdb,currit,currit,...
                                flags.do_pedanticsearch, flags.algorithm );

        c = cellfun(@(cEl,ctmpEl) cEl + ctmpEl, c(:)',ctmp(:)','UniformOutput', 0);

        remainingit = remainingit - info.iter;

        %The following means that some other stopping criterion has been reached
        if info.status ~=0 && info.status ~=3 && currit ~= info.iter, break; end

        if remainingit > 0
            % Recompute residuum
            frec = sum(cell2mat(cellfun(@(cEl,gEl,aEl,MEl) idgtreal(cEl,gEl,aEl,MEl,flags.phaseconv),...
                   c(:)',info.g(:)',num2cell(a(:))',num2cell(M(:))','UniformOutput',0)),2);
            
            fpad = postpad(f,L) - frec;
            relres = norm(fpad(:)) / fnorm;            
            % Since we are changing the residual, we must adjust the target error
            currerrdb = kv.errdb - 20*log10(relres);            
            if currerrdb < 0
                info.relres(info.resets+1) = relres;
            end
            if info.resets >= 1 && info.relres(end) > info.relres(end-1)
                info.status = 6; 
                break; 
            end
        end
    end

    %Fix the info
    info.atoms = sum(cellfun(@(cEl) numel(find( abs(cEl) > 0 )), c));
    info.iter = kv.maxit - remainingit;
end


if nargout>1
  permutedsize2 = permutedsize; permutedsize2(2) = dictno;
  info.synthetize = @(c) ...
      assert_sigreshape_post(...
      postpad(cell2mat(cellfun(@(cEl,gEl,aEl,MEl) idgtreal(cEl,gEl,aEl,MEl,flags.phaseconv),...
      c(:)',info.g(:)',num2cell(a(:))',num2cell(M(:))','UniformOutput',0)),Ls),...
      dim,permutedsize2,order);
  dim2 = 2;
  if dim == 2, dim2 = 1; end
  frec = sum(info.synthetize(c),dim2);
  if fnorm == 0
    info.relres(end+1) = 0;
  else
    info.relres(end+1) = norm(frec(:)-f(:))/fnorm;
  end
  
  % Fix the status
  if info.relres(end) <= 10^(kv.errdb/20)
      info.status = 0;
  elseif info.iter == kv.maxit
      info.status = 2;
  end
  
  status_str = {...
  'Target error reached',...
  'Maximum number of atoms reached',...
  'Maximum number of iterations reached',...
  'Stalled (abs. norm. error estimate became negative)',...
  'Selected coefficient tolerance reached',...
  'All zeros',...
  'Stalled (Residual has increased since last reset. Try to reduce resetit.)'...
  };
  %info.message = status_str{1 + info.status};
end

