function slicedBeamC = calculateBeamIntersect(sourcePt, polygon, dim, coord)
%slicedBeamC = calculateBeamIntersect(sourcePt, polygon, dim, coord)
%
%Inputs:
%       sourcePt - (x,y,z) coordinates of source point of the beam.
%        polygon - (x,y,z) coordinates defining a closed contour of beam field.
%                  This polygon may represent 50% or 90% max dose level.
%            dim - represents the slice in orthogonal plane desired.
%                  dim=1 for x=const, dim=2 for y=const, dim=3 for z=const.
%          coord - represents constant value for orthogonal plane at which the
%                  contours of beam field are desired.
%
%
%Output:
%   slicedBeamC - cell array containing contours for the beam field. In
%   order to plot the contours use the following:
%   for j=1:length(slicedBeamC)
%       plot(slicedBeamC{j}(1,:),slicedBeamC{j}(2,:),'color','y')
%   end
%
%APA 06/16/06
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

xyzSource = sourcePt;
xyDoseBoundary = polygon;

%% obtain polygon at a large distance from source
xyDoseBoundary(1,:) = xyzSource(1,1) + 1e6*(xyDoseBoundary(1,:)-xyzSource(1,1));
xyDoseBoundary(2,:) = xyzSource(1,2) + 1e6*(xyDoseBoundary(2,:)-xyzSource(1,2));
xyDoseBoundary(3,:) = xyzSource(1,3) + 1e6*(xyDoseBoundary(3,:)-xyzSource(1,3));

switch dim

    case 1
        % original code written for sagittal i.e. y,z (plane perpendicular to x)
    case 2
        % switch y,z to x,z
        xyzSource = xyzSource([2 1 3]);
        xyDoseBoundary = xyDoseBoundary([2 1 3],:);
    case 3
        % switch y,z to x,y
        xyzSource = xyzSource([3 1 2]);
        xyDoseBoundary = xyDoseBoundary([3 1 2],:);

end

XYZsource = repmat(xyzSource',size(xyDoseBoundary(1,:,:)));

%% boundary 1 (intersection between XYZ-plane and rays)
dXv = (xyDoseBoundary(1,:) - XYZsource(1,:));
indZeroSlope = find(abs(dXv)<1e-6);
dXv(indZeroSlope) = inf; % change zero slope to inf
y1 = XYZsource(2,:) + (xyDoseBoundary(2,:) - XYZsource(2,:)).*(coord - XYZsource(1,:))./dXv;
z1 = XYZsource(3,:) + (xyDoseBoundary(3,:) - XYZsource(3,:)).*(coord - XYZsource(1,:))./dXv;

%% cutoff back projection
if length(unique(sign(y1-XYZsource(2,:))))==1 & unique(sign(y1-XYZsource(2,:)))==0
    indToKeep = 1;
else
    intersectToSourceY = y1-XYZsource(2,:);
    polyBoundaryToSourceY = xyDoseBoundary(2,:) - XYZsource(2,:);
    intersectToSourceY(find(abs(intersectToSourceY)<1e-12)) = 0;
    polyBoundaryToSourceY(find(abs(polyBoundaryToSourceY)<1e-6)) = 0;

    intersectToSourceZ = z1-XYZsource(3,:);
    polyBoundaryToSourceZ = xyDoseBoundary(3,:) - XYZsource(3,:);
    intersectToSourceZ(find(abs(intersectToSourceZ)<1e-12)) = 0;
    polyBoundaryToSourceZ(find(abs(polyBoundaryToSourceZ)<1e-6)) = 0;

    indToKeep = (sign(intersectToSourceY) == sign(polyBoundaryToSourceY)) & (sign(intersectToSourceZ) == sign(polyBoundaryToSourceZ));
end
indBreak = find(diff(indToKeep)~=0);

if length(indBreak)==2 & indToKeep(indBreak(1)+1) == 0
    indCorrectOrder = [indBreak(1):-1:1 length(y1):-1:indBreak(2)+1];
    yy1 = y1(indCorrectOrder);
    zz1 = z1(indCorrectOrder);
elseif length(indBreak)==2 & indToKeep(indBreak(1)+1)== -1
    indCorrectOrder = linspace(indBreak(1),1,indBreak(1)-indBreak(2)+1);
    yy1 = y1(indCorrectOrder);
    zz1 = z1(indCorrectOrder);
else
    yy1 = y1(indToKeep);
    zz1 = z1(indToKeep);
end    
    
%% boundary 2 (intersection between XYZ-plane and polygon)
yz3 = {};
if length(yy1)<length(xyDoseBoundary(1,:)) & ~isempty(yy1) % i.e. plane does not intersect all the rays    
    dxDOSEv = [xyDoseBoundary(1,:) ; [xyDoseBoundary(1,2:end) xyDoseBoundary(1,1)]];
    dyDOSEv = [xyDoseBoundary(2,:) ; [xyDoseBoundary(2,2:end) xyDoseBoundary(2,1)]];
    dzDOSEv = [xyDoseBoundary(3,:) ; [xyDoseBoundary(3,2:end) xyDoseBoundary(3,1)]];
    [dxDOSEv, indSort] = sort(dxDOSEv);
    % sort y coords for each line
    for j = 1:length(dyDOSEv(1,:))
        dyDOSEv(:,j) = dyDOSEv(indSort(:,j),j);
    end
    % sort x coords for each line
    for j = 1:length(dzDOSEv(1,:))
        dzDOSEv(:,j) = dzDOSEv(indSort(:,j),j);
    end
    indLine = find(dxDOSEv(1,:)<=coord & dxDOSEv(2,:)>=coord );
    y2 = dyDOSEv(1,indLine) + (dyDOSEv(2,indLine) - dyDOSEv(1,indLine)).*(coord - dxDOSEv(1,indLine))./(dxDOSEv(2,indLine) - dxDOSEv(1,indLine));
    z2 = dzDOSEv(1,indLine) + (dzDOSEv(2,indLine) - dzDOSEv(1,indLine)).*(coord - dxDOSEv(1,indLine))./(dxDOSEv(2,indLine) - dxDOSEv(1,indLine));
    
    % Join points on the two boundaries to draw a ray
    if ~isempty(y2)
        yz3{1} = [yy1(1) y2(1) ; zz1(1) z2(1)];
        yz3{2} = [yy1(end) y2(2) ; zz1(end) z2(end)];
    end

end

%% Return all the lines in in the form of slicedBeamC
slicedBeamC{1} = [yy1 ; zz1];
if ~isempty(yz3)
    slicedBeamC{2} = yz3{1};
    slicedBeamC{3} = yz3{2};
elseif ~isempty(slicedBeamC{1}) % close the contour if intersecting points exist
    slicedBeamC{1}(:,end+1) = slicedBeamC{1}(:,1);
end
