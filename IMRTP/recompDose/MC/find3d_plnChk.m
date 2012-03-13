function [iV,jV,kV]=find3d(mask3M)
%"find3d"
%   This is the 3D equivalent of the builtin command, find.
%   It returns the i,j,k indices of non-zero entries.
%
%JOD, 16 Nov 98
%JOD, 26 Feb 03, bugfix.
%JRA, 26 Feb 04, new algorithm, also implements the new fastind2sub.
%
%Usage:
%   [iV,jV,kV]=find3d(mask3M);

indV = find(mask3M(:));
[iV,jV,kV] = fastind2sub(size(mask3M), indV);
iV = iV';
jV = jV';
kV = kV';