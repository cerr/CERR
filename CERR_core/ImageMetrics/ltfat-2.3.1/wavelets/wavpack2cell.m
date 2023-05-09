function [ccell,dim] = wavpack2cell(cvec,Lc,varargin)
%-*- texinfo -*-
%@deftypefn {Function} wavpack2cell
%@verbatim
%WAVPACK2CELL Changes wavelet coefficients storing format
%   Usage:  
%          ccell = wavpack2cell(cvec,Lc);
%          ccell = wavpack2cell(cvec,Lc,dim);
%
%   Input parameters:
%         cvec     : Coefficients in packed format.
%         Lc       : Vector containing coefficients lengths.
%         dim      : Dimension along which the data were transformed. 
%
%   Output parameters:
%         ccell    : Coefficients stored in a cell-array. Each element is
%                    a column vector or a matrix.
%         dim      : Return used dim. Usefull as an input of the
%                    complementary function WAVCELL2PACK.
%
%   ccell = WAVPACK2CELL(cvec,Lc) copies coefficients from a single column
%   vector or columns of a matrix cvec of size [sum(Lc), W] to the cell
%   array ccell of length length(Lc). Size of j*-th element of ccell*
%   is [Lc(j), W] and it is obtained by:
% 
%      ccell{j}=cvec(1+sum(Lc(1:j-1)):sum(Lc(1:j),:);
%
%   ccell = WAVPACK2CELL(cvec,Lc,dim) allows specifying along which
%   dimension the coefficients are stored in cvec. dim==1 (default)
%   considers columns (as above) and dim==2 rows to be coefficients 
%   belonging to separate channels. Other values are not supported. For 
%   dim=2, cvec size is [W, sum(Lc)], Size of j*-th element of ccell*
%   is [Lc(j), W] and it is obtained by:
% 
%      ccell{j}=cvec(:,1+sum(Lc(1:j-1)):sum(Lc(1:j)).';
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wavpack2cell.html}
%@seealso{wavcell2pack, fwt, wfbt, wpfbt}
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


if(nargin<2)
    error('%s: Too few input parameters.',upper(mfilename));
end

if(~isnumeric(cvec))
    error('%s: *cvec* is not a numeric array.',upper(mfilename));
end

definput.keyvals.dim = [];
[flags,kv,dim]=ltfatarghelper({'dim'},definput,varargin);

%If dim is not specified use first non-singleton dimension.
if(isempty(dim))
    dim=find(size(cvec)>1,1);
end

if(dim>2)
    error('%s: Multidimensional data is not accepted.',upper(mfilename));
end

if(dim==2)
    cvec = cvec.';
end

if(sum(Lc)~=size(cvec,1))
    error('%s: Sum of elements of Lc is not equal to vector length along dimension %d. Possibly wrong dim?',upper(mfilename),dim);
end

% Actual computation
ccell = mat2cell(cvec,Lc);

