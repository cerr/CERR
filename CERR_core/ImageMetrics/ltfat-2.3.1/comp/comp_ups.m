function fups = comp_ups(f,varargin)
%-*- texinfo -*-
%@deftypefn {Function} comp_ups
%@verbatim
%COMP_UPS Upsampling
%   Usage: fups = comp_ups(f,a) 
%          fups = comp_ups(f,a,type,'dim',dim)
%          fups = comp_ups(f,a,skip,L,'dim',dim) 
%   
%   Input parameters:
%         f     : Input vector/matrix.
%         a     : Upsampling factor.
%         type  : Type of the upsampling/initial skip.
%         L     : Required output length.
%         dim   : Direction of upsampling.
%   Output parameters:
%         fups  : Upsampled vector/matrix.
%
%   Upsamples input f by a factor a (puts a-1 zeros between data elements)
%   along dimension dim. If dim is not specified, first non-singleton
%   dimension is used. Parameter type (integer from [0:3]) specifies whether the upsampling
%   includes beginning/tailing zeros:
%
%   type=0 (default): Includes just tailing zeros.
%   type=1: No beginning nor tailing zeros.
%   type=2: Includes just begining zeros.
%   type=3: Includes both. 
%
%   If non-empty parameter L is passed, it specifies the required output
%   length and the type changes to skip which denotes how many zeros to
%   add before the first sample.
%
%   Examples:
%   ---------
%
%   The outcome of the default upsampling type is equal to the upsampling performed
%   directly in the frequency domain using repmat:
%
%      f = 1:4;
%      a = 3;
%      fupsTD = comp_ups(f,a)
%      fupsFD = real(ifft(repmat(fft(f),1,a)))
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_ups.html}
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


definput.keyvals.dim = [];
definput.keyvals.a = 2;
definput.keyvals.type = 0;
definput.keyvals.L = [];
[flags,kv,a,type,L]=ltfatarghelper({'a','type','L'},definput,varargin);

% a have to be positive integer
if(a<1)
    a = 1;
end
if(type<0)
    type = 0;
end

if(a<0 || rem(a,1)~=0)
    error('%s: Parameter *a* have to be a positive integer.',upper(mfilename));
end
% if L == [], supported types are 0-3
if(isempty(L)&&(type<0||type>3))
    error('%s: Unsupported upsampling type.',upper(mfilename));
end

if(~isempty(L)&&type>=L)
    error('%s: Initial zeros count is bigger than the output length.',upper(mfilename));
end

if(ndims(f)>2)
    error('%s: Multidimensional signals (d>2) are not supported.',upper(mfilename));
end

%% ----- step 1 : Verify f and determine its length -------
[f,~,Ls,~,dim,~,order]=assert_sigreshape_pre(f,[],kv.dim,upper(mfilename));


if(~isempty(L))
    fups=zeros(L,size(f,2),assert_classname(f)); 
    fbound = min(ceil((L-type)/a),Ls);
    fups(1+type:a:fbound*a+type,:)=f(1:fbound); 
else
    if(type==0)
      % Include just tailing zeros.
      fups=zeros(a*Ls,size(f,2),assert_classname(f));    
      fups(1:a:end,:)=f; 
    elseif(type==1)
      % Do not include beginning nor tailing zeros.
      fups=zeros(a*Ls-(a-1),size(f,2),assert_classname(f));    
      fups(1:a:end,:)=f;    
    elseif(type==2)
      % Include just beginning zeros.
      fups=zeros(a*Ls,size(f,2),assert_classname(f));    
      fups(a:a:end,:)=f;  
    elseif(type==3)
      % Include both beginning and tailing zeros.
      fups=zeros(a*Ls+a-1,size(f,2),assert_classname(f));    
      fups(a:a:end,:)=f;   
    end
end

permutedSizeAlt = size(fups);
fups=assert_sigreshape_post(fups,dim,permutedSizeAlt,order);


