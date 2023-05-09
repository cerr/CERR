function fdowns = comp_downs(f,a,varargin)
%-*- texinfo -*-
%@deftypefn {Function} comp_downs
%@verbatim
%COMP_DOWNS Downsampling
%   Usage: fdowns = comp_downs(f,a) 
%          fdowns = comp_downs(f,a,skip,L,'dim',dim) 
%   
%   Input parameters:
%         f     : Input vector/matrix.
%         a     : Downsampling factor.
%         skip  : Skipped initial samples.
%         L     : Length of the portion of the input to be used.
%         dim   : Direction of downsampling.
%   Output parameters:
%         fdowns  : Downsampled vector/matrix.
%
%   Downsamples input f by a factor a (leaves every a*th sample) along
%   dimension dim. If dim is not specified, first non-singleton
%   dimension is used. Parameter skip (integer) specifies how
%   many samples to skip from the beginning and L defines how many
%   elements of the input data are to be used starting at index 1+skip. 
%
%   Examples:
%   ---------
%
%   The default behavior is equal to the subsampling performed
%   in the frequency domain using reshape and sum:
%
%      f = 1:9;
%      a = 3;
%      fupsTD = comp_downs(f,a)
%      fupsFD = real(ifft(sum(reshape(fft(f),length(f)/a,a),2).'))/a
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_downs.html}
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


if(nargin<2)
    error('%s: Too few input parameters.',upper(mfilename));
end

definput.keyvals.dim = [];
definput.keyvals.skip = 0;
definput.keyvals.L = [];
[flags,kv,skip,L]=ltfatarghelper({'skip','L','dim'},definput,varargin);

% a have to be a positive integer
if(a<1)
    a = 1;
end
if(a<0 || rem(a,1)~=0)
    error('%s: Parameter *a* have to be a positive integer.',upper(mfilename));
end

% supported type are [0--a-1]
% if(type<0||type>(a-1))
%     error('%s: Unsupported downsampling type.',upper(mfilename));
% end

if(ndims(f)>2)
    error('%s: Multidimensional signals (d>2) are not supported.',upper(mfilename));
end

% ----- Verify f and determine its length -------
[f,Lreq,Ls,~,dim,permutedsize,order]=assert_sigreshape_pre(f,L,kv.dim,upper(mfilename));

if(skip>=Ls)
    error('%s: Parameter *skip* have to be less than the input length.',upper(mfilename));
end

if(~isempty(L))
   if(Lreq+skip>Ls)
       error('%s: Input length is less than required samples count: L+skip>Ls.',upper(mfilename)); 
   end 
   Ls = Lreq+skip;
end


% Actual computation
fdowns = f(1+skip:a:Ls,:);   


permutedSizeAlt = size(fdowns);
fdowns=assert_sigreshape_post(fdowns,dim,permutedSizeAlt,order);

