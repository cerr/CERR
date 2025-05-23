function [M,padpre] = padImage(MData, pof2, padval)
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.

if ~exist('padval','var')
    padval = 0;
end

dim = size(MData);
s = 2^pof2;
newdim = ceil(dim/s)*s;

paddim = newdim-dim;
padpre = floor(paddim/2);
padpost = paddim-padpre;

if exist('padarray.m','file')
    M = padarray(MData,padpre,padval,'pre');
    M = padarray(M,padpost,padval,'post');
else
    M = padarray_oct(MData,padpre,padval,'pre');
    M = padarray_oct(M,padpost,padval,'post');
end




