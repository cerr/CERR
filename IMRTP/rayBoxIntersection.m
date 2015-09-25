function t = rayBoxIntersection(rayOrgS,rayDeltaS,minBoxS,maxBoxS)
%function distance = rayBoxIntersection(rayOrgS,rayDeltaS,minBoxS,maxBoxS)
%
%Parametric intersection with a ray.  Returns parametric point
%of intsersection in range 0...1 or a really big number (>1) if no
%intersection.  A Ray is assumed to be represented by a direction, an origin, and a length,
%i.e., pV = p0V + t * deltaV.
%
%rayOrgS.x, rayOrgS.y, rayOrgS.z are the coords of the ray origin.
%rayDeltaS.x, rayDeltaS.y, rayDeltaS.z  are the components of the ray's direction and maximum length.
%minBoxS.x, minBoxS.y, minBoxS.z are the minimum value coords of the box.
%maxBoxS.x, maxBoxS.y, maxBoxS.z are the maximum value coords of the box.
%The output parameter t has a value between 0 and 1 and is the fraction of the ray
%to the near intersection point.
%
%If no intersection, t = -1 is returned.
%
%The algorithm is based on "Fast Ray-Box Intersection" by Woo in "Graphics Gems I",
%page 395 & cpp implementation by Dun and Parberry "3D Math Primer for Graphics and Games Development",
%
%Adapted to Matlab code by JOD, Oct 03.
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

%return a big number if no intersection:
noIntersection = -1;

% Check for point inside box, trivial reject, and determine parametric
% distance to each front face

true = 1;
false = 0;
inside = true;

rayOrgS.x = rayOrgS.xRel + rayOrgS.isocenter.x;
rayOrgS.y = rayOrgS.yRel + rayOrgS.isocenter.y;
rayOrgS.z = rayOrgS.zRel + rayOrgS.isocenter.z;

if rayOrgS.x < minBoxS.x
    xt = minBoxS.x - rayOrgS.x;
    if (xt > rayDeltaS.x)
      t = noIntersection;
      return
    end
    xt = xt / rayDeltaS.x;
    inside = false;
 elseif (rayOrgS.x > maxBoxS.x)
    xt = maxBoxS.x - rayOrgS.x;
    if (xt < rayDeltaS.x)
      t = noIntersection;
      return
    end
    xt = xt / rayDeltaS.x;
    inside = false;
 else
    xt = -1.0;
end

if (rayOrgS.y < minBoxS.y)
    yt = minBoxS.y - rayOrgS.y;
    if (yt > rayDeltaS.y)
      t = noIntersection;
      return
    end
    yt = yt / rayDeltaS.y;
    inside = false;
 elseif (rayOrgS.y > maxBoxS.y)
    yt = maxBoxS.y - rayOrgS.y;
    if (yt < rayDeltaS.y)
      t = noIntersection;
      return
    end
    yt = yt / rayDeltaS.y;
    inside = false;
 else
    yt = -1.0;
end

if (rayOrgS.z < minBoxS.z)
    zt = minBoxS.z - rayOrgS.z;
    if (zt > rayDeltaS.z)
      t = noIntersection;
      return
    end
    zt = zt / rayDeltaS.z;
    inside = false;
 elseif (rayOrgS.z > maxBoxS.z)
    zt = maxBoxS.z - rayOrgS.z;
    if (zt < rayDeltaS.z)
      t = noIntersection;
      return
    end
    zt = zt / rayDeltaS.z;
    inside = false;
 else
    zt = -1.0;
end

% Inside box?
if inside
    t= 0.0;
    return
end

% Select farthest plane - this is
% the plane of intersection.

which = 0;
t = xt;
if (yt > t)
    which = 1;
    t = yt;
end

if (zt > t)
    which = 2;
    t = zt;
end

switch which

    case 0 % intersect with yz plane

        y = rayOrgS.y + rayDeltaS.y*t;
        if (y < minBoxS.y | y > maxBoxS.y)
          t = noIntersection;
          return
        end
        z = rayOrgS.z + rayDeltaS.z*t;
        if (z < minBoxS.z | z > maxBoxS.z)
          t = noIntersection;
          return
        end

        return

    case 1 % intersect with xz plane

        x = rayOrgS.x + rayDeltaS.x*t;
        if (x < minBoxS.x | x > maxBoxS.x)
          t = noIntersection;
          return
        end
        z = rayOrgS.z + rayDeltaS.z*t;
        if (z < minBoxS.z | z > maxBoxS.z)
          t = noIntersection;
          return
        end

        return

    case 2 % intersect with xy plane

        x = rayOrgS.x + rayDeltaS.x*t;
        if (x < minBoxS.x | x > maxBoxS.x)
          t = noIntersection;
          return
        end
        y = rayOrgS.y + rayDeltaS.y*t;
        if (y < minBoxS.y | y > maxBoxS.y)
          t = noIntersection;
          return
        end

        return

    otherwise

      error('Failure in rayBoxIntersection')

end
