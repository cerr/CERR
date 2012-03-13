function [rayWedgeLength] = rayWedgeIntersect(IM, indexBeam, distWedge);
%rayOrgS.x, rayOrgS.y, rayOrgS.z are the coords of the ray origin.
%rayDeltaS.x, rayDeltaS.y, rayDeltaS.z  are the components of the ray's direction and maximum length.
%minBoxS.x, minBoxS.y, minBoxS.z are the minimum value coords of the box.Fdi
%maxBoxS.x, maxBoxS.y, maxBoxS.z are the maximum value coords of the box.
%The output parameter t has a value between 0 and 1 and is the fraction of the ray

% Output the rayLength of each PB passing the wedge.


% Default value for indexBeam is 1.
% Default value for distWedge is 18.6 cm. i.e. distance from the source to
% the top surface of the wedge.

% project the 'orig's "z" coordinates onto the same 'z' plane, i.e. the
% center of the wedge.
% The ray starting from 'orig' enter 'AE',

% Case 1.    If it exits from AB or BC. dist = |exitV-entranceV|
% Case 2.    If it exits from CD or ED. calc. intersect of the ray with CE.,
% as intersectV. dist = |intersectV - entranceV|
% Case 3.    Else, error.

% In beams eye view, when gA = 0; collAngle = 0, looking from the source along the
% central axis, the coordinates is:
%
%
%                                (couch)-------->y+ (gantry)
% If/usuall the patient is head-in & face-up, so the x+ points to patient's left.



%                .orig (y=0,z=0)

%  inferior/y- A ____________________E  gantry/y+
%               |                  /|
%               |                /  |     |z+
%               |              /    |     |
%               |            /      |     |z-
%              B|__________/________|
%               C           D

% Since the wedge rotates as gantry does, so do the calculation in the
% 'beam's eye view', i.e.

sourceS = IM.beams(indexBeam);
figure; plot(sourceS.yPBPosV, sourceS.xPBPosV, '+');
xlabel('y/cm'); ylabel('x/cm'); title('BEV')

% Need to figure out the corners of the wedge.
% minBoxS corresponds to C.
minBoxS = struct('x', 0, 'y', -7, 'z', -5.8-distWedge)
% maxBoxS corresponds to E.
maxBoxS = struct('x', 0, 'y',  3, 'z', -distWedge)

rayLength = sourceS.isodistance;
centralV = [0 0 -1];         %The cos direction of the centralV.
isodistance = sourceS.isodistance;

%In "rayBoxIntersection.m", the (x,y,z) coordinates is recaulated based on
%the (xRel, yRel, zRel), and isocenter(x,y,z). Need to over-write this.
% Always starts at (0,0,0) in BEV.
rayOrgS = struct('xRel', 0, 'yRel', 0, 'zRel', 0);
rayOrgS.isocenter = struct('x', 0, 'y', 0, 'z', 0);
% In 'rayBoxIntersection.m', rayOrgS is reculated.
%rayOrgS.x = rayOrgS.xRel + rayOrgS.isocenter.x;
%rayOrgS.y = rayOrgS.yRel + rayOrgS.isocenter.y;
%rayOrgS.z = rayOrgS.zRel + rayOrgS.isocenter.z;
rayWedgeLength = zeros(length(sourceS.yPBPosV),1);

for i = 1 : length(sourceS.yPBPosV)

    angleZ = atan(sourceS.yPBPosV(i)./isodistance);

    cosRay = [0 cos(pi/2-angleZ) -abs(cos(angleZ))];
    %Above, cosRay(3), i.e. cosine direction's z components should be egative.
    rayDeltaS.x = 0;
    rayDeltaS.y = cosRay(2)*rayLength;
    rayDeltaS.z = cosRay(3)*rayLength;

    %are the components of the ray's direction and maximum length.
    deltaV = [rayDeltaS.x, rayDeltaS.y, rayDeltaS.z];

    t_entrance = rayBoxIntersection(rayOrgS,rayDeltaS,minBoxS,maxBoxS);

    % rayDeltaS (x,y,z) should be the center of each PB).
    % pro

    % get the ray entrance point coordinates.
    deltaV = [rayDeltaS.x, rayDeltaS.y, rayDeltaS.z];
    entranceV = t_entrance * deltaV;   %Since it starts from (0,0,0)

    %Reflect to find exit point (assume length of ray is long enough that ray does exit):

    if t_entrance ~= -1

        %find exit point
        %get end of ray
        rayOrgS2.xRel = rayDeltaS.x;  %reflected source positions
        rayOrgS2.yRel = rayDeltaS.y;
        rayOrgS2.zRel = rayDeltaS.z;

        rayDeltaS2.x = - rayDeltaS.x;
        rayDeltaS2.y = - rayDeltaS.y;
        rayDeltaS2.z = - rayDeltaS.z;

        rayOrgS2.isocenter = rayOrgS.isocenter;

        t = rayBoxIntersection(rayOrgS2,rayDeltaS2,minBoxS,maxBoxS);

        t_exit = 1 - t;

        exitV = t_exit * deltaV;
       
        %visualization:
        if (i == 1 || mod(i,50) == 0) 
        Y = [-7.0 -4.35   -4.35 -7.0 -7.0];
        Z = [-5.8 -5.8  0    0  -5.8]-distWedge;
        figure; line(Y,Z, 'Color', 'b', 'LineStyle', '-', 'Marker', 'o');
        Y = [-4.35  3.0  -4.35 -4.35];
        Z = [-5.8    0     0   -5.8]-distWedge;
        hold on; line(Y,Z, 'Color', 'r', 'LineStyle', '-', 'Marker', 'o'); axis equal;
        xlabel('Y/cm'); ylabel('Z/cm'); title('Elekta Universal Wedge');
        hold on; line([entranceV(2) exitV(2)], [entranceV(3) exitV(3)],'Color', 'g');
        end
    else
        error('PB Ray does not intersect CT scan.');
    end

    % project the 'orig's "z" coordinates onto the same 'z' plane, i.e. the
    % center of the wedge.
    % The ray starting from 'orig' enter 'AE',

    %                .orig (y=0,z=0)

    %  inferior/y- A ____________________E  gantry/y+
    %               |                  /|
    %               |                /  |     |z+
    %               |              /    |     |
    %               |            /      |     |z-
    %              B|__________/________|
    %               C           D

    % the raylength is dist(exitV-entranceV)
    % unless  thesegment(exitV-entranceV) intersect with DE, update exitV with
    % the new intersect;
    rayWedgeLength(i) = sqrt(dot((exitV-entranceV)', (exitV-entranceV)'));

    D = [0      -4.35    minBoxS.z];
    E = [0  maxBoxS.y    maxBoxS.z];

    % Points on entranceV -> exitV:  p = entranceV + t*(exitV - entranceV)
    % points on DE: Q = D +s*(E-D);

    denominator = (E(3)-D(3))*(exitV(2)-entranceV(2)) - (E(2)-D(2))*(exitV(3)-entranceV(3));
    t = (E(2)-D(2))*(entranceV(3)-D(3)) - (E(3)-D(3))*(entranceV(2)-D(2));
    t = t/denominator;
    s = (exitV(2)-entranceV(2))*(entranceV(3)-D(3)) - (exitV(3)-entranceV(3))*(entranceV(2)-D(2));
    s = s/denominator;
    
    if (denominator < eps)
        % parallel to DE
        % do nothing
        disp('parallel');
        return;
    elseif (t>0 && t<1 && s>0 && s<1)
        exitV = entranceV + t*(exitV-entranceV);
         rayWedgeLength(i) = sqrt(dot((exitV-entranceV)', (exitV-entranceV)'));
        %rayWedgeLength(i) = t*rayWedgeLength(i);  %equivalent to the above

    end

    %Visulization:
      if (i == 1 || mod(i,50) == 0) 
          hold on; line([entranceV(2) exitV(2)], [entranceV(3) exitV(3)],'Color', 'k');
      end


end

return;