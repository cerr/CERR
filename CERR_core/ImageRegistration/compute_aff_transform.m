function [fh,A]=compute_aff_transform(f, ref_pts, target_pts)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get the affine transformation from given control points pairs, assuming
% the points are correctly matched!
% Written by: Issam El Naqa  Date: 09/09/03
% Revised by:                Date:
% f: reference image
% ref_pts: control points from reference image
% target_pts: control points from target image (unregistered)
% A: Affine estimated matrix
% fh: warped f using A
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

% check sizes
[mr,nr]=size(ref_pts); [mt,nt]=size(target_pts); 
if (mr < 3) | (mt <3)
    errordlg('Minimum number of control points is 3!', 'co_reggui Error', 'replace');
elseif  (mr~=mt) 
    errordlg('Control points are do not match properly!', 'co_reggui Error', 'replace');
elseif (nr ~=2) |  (nt ~=2)  
    errordlg('Control points should be entered as M x 2!', 'co_reggui Error', 'replace');
end

% assume A of the form A=RST (rotation,scaling, translation)
% then A has form of [a11 a12 0;a21 a22 0; a31 a32 1], need to estimate the
% a's by solving:
% [tx ty 1]=[rx ry 1] *A;
R=[ref_pts, ones(mr,1)];
Ainv=R\target_pts; % ignore last column.
e3=[0;0;1];
A=inv([Ainv,e3]);
A(:,3)=e3;
% apply warping using the estimated A matrix
[h,w]=size(f);
[x,y]=meshgrid([1:h],[1:w]);
f_coord=[x(:),y(:),ones(h*w,1)];
fh_coord=f_coord*A;
xd=fh_coord(:,1); yd=fh_coord(:,2);
% apply interpolation
fh=reshape(bilinear_interpolation(double(f),xd,yd),w,h)';
return









