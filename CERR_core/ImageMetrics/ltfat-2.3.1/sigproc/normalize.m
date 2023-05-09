function [f,fnorm]=normalize(f,varargin)
%-*- texinfo -*-
%@deftypefn {Function} normalize
%@verbatim
%NORMALIZE  Normalize input signal by specified norm
%   Usage:  h=normalize(f,...);
% 
%   NORMALIZE(f,...) will normalize the signal f by the specified norm.
%
%   [f,fnorm]=NORMALIZE(f,...) does the same thing, but in addition
%   returns norm fnorm of a signal f.
%
%   The norm is specified as a string and may be one of:
%
%     '1'       Normalize the l^1 norm to be 1.
%
%     'area'    Normalize the area of the signal to be 1. This is exactly the same as '1'.
%
%     '2'       Normalize the l^2 norm to be 1.
%
%     'energy'  Normalize the energy of the signal to be 1. This is exactly
%               the same as '2'.
%
%     'inf'     Normalize the l^{inf} norm to be 1.
%
%     'peak'    Normalize the peak value of the signal to be 1. This is exactly
%               the same as 'inf'.
%
%     'rms'     Normalize the Root Mean Square (RMS) norm of the
%               signal to be 1.
%
%     's0'      Normalize the S0-norm to be 1.
%
%     'wav'     Normalize to the l^{inf} norm to be 0.99 to avoid 
%               possible clipping introduced by the quantization procedure 
%               when saving as a wav file. This only works with floating
%               point data types.
%
%     'null'    Do NOT normalize, output is identical to input.
%
%
%   It is possible to specify the dimension:
%
%      'dim',d  
%                Work along specified dimension. The default value of []
%                means to work along the first non-singleton one.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/sigproc/normalize.html}
%@seealso{rms, s0norm}
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
  
if ~isnumeric(f) 
  error('%s: Input must be numerical.',upper(mfilename));
end;

if nargin<1
  error('%s: Too few input parameters.',upper(mfilename));
end;

definput.import={'normalize'};
definput.keyvals.dim=[];

[flags,kv]=ltfatarghelper({},definput,varargin);

if flags.do_null || flags.do_norm_notset || isempty(f);
  return
end;

if isa(f,'integer') && ~flags.do_wav
   error('%s: Integer data types are unsupported.',upper(mfilename)); 
end

%% ------ Computation --------------------------
 
[f,L,Ls,W,dim,permutedsize,order]=assert_sigreshape_pre(f,[],kv.dim, ...
                                                  upper(mfilename));
fnorm = zeros(W,1);

for ii=1:W  
  
  if flags.do_1 || flags.do_area
    fnorm(ii) =  norm(f(:,ii),1);
    f(:,ii)=f(:,ii)/fnorm(ii);
  end;

  if flags.do_2 || flags.do_energy 
    fnorm(ii) = norm(f(:,ii),2);
    f(:,ii)=f(:,ii)/fnorm(ii);
  end;

  if flags.do_inf || flags.do_peak
    fnorm(ii) = norm(f(:,ii),Inf);
    f(:,ii)=f(:,ii)/fnorm(ii);
  end;

  if flags.do_rms
    fnorm(ii) = rms(f(:,ii));
    f(:,ii)=f(:,ii)/fnorm(ii);
  end;
  
  if flags.do_s0 
    fnorm(ii) = s0norm(f(:,ii));
    f(:,ii)=f(:,ii)/fnorm(ii);
  end;
  
  if flags.do_wav
    if isa(f,'float')
       fnorm(ii) = norm(f(:,ii),Inf); 
       f(:,ii) = 0.99*f(:,ii)/fnorm(ii);
    else
       error(['%s: TO DO: Normalizing integer data types not supported ',...
              'yet.'],upper(mfilename));
    end
  end;
  
end;


f=assert_sigreshape_post(f,kv.dim,permutedsize,order);

