function [cvec,Lc] = wavcell2pack(ccell,varargin)
%-*- texinfo -*-
%@deftypefn {Function} wavcell2pack
%@verbatim
%WAVCELL2PACK Changes wavelet coefficients storing format
%   Usage:  [cvec,Lc] = wavcell2pack(ccell);
%           [cvec,Lc] = wavcell2pack(ccell,dim);
%
%   Input parameters:
%         ccell    : Coefficients stored in a collumn cell-array.
%         dim      : Dimension along which the data were transformed. 
%
%   Output parameters:
%         cvec     : Coefficients in packed format.
%         Lc       : Vector containing coefficients lengths.
%
%   [cvec,Lc] = WAVCELL2PACK(ccell) assembles a column vector or a matrix
%   cvec using elements of the cell-array ccell in the following
%   manner:
%
%      cvec(1+sum(Lc(1:j-1)):sum(Lc(1:j),:)=ccell{j};
%
%   where Lc is a vector of length numel(ccell) containing number of
%   rows of each element of ccell.
%
%   [cvec,Lc] = WAVCELL2PACK(ccell,dim) with dim==2 returns a
%   transposition of the previous.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wavcell2pack.html}
%@seealso{wavpack2cell, fwt, wfbt, wpfbt}
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

% AUTHOR: Zdenek Prusa

if(nargin<1)
    error('%s: Too few input parameters.',upper(mfilename));
end

definput.keyvals.dim = 1;
[flags,kv,dim]=ltfatarghelper({'dim'},definput,varargin);
if(dim>2)
    error('%s: Multidimensional data is not accepted.',upper(mfilename));
end

% Actual computation
Lc = cellfun(@(x) size(x,1), ccell);
cvec = cell2mat(ccell);

% Reshape back to rows
if(dim==2)
    cvec = cvec.';
end




