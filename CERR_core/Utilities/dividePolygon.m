function [xyTV,xyLV,xyBV,xyRV] = dividePolygon(xV,yV,xc,yc)
% function [xyTV,xyLV,xyBV,xyRV] = dividePolygon(xV,yV,xc,yc)
%
% This function divides the passed polygon into Top, Left, Bottom and Right
% parts.
%
% APA, 08/23/2012


%xV = planC{indexS.structures}(2).contour(71).segments.points(:,1);
%yV = planC{indexS.structures}(2).contour(71).segments.points(:,2);

if nargin < 3
    xc = mean(xV);
    yc = mean(yV);
end
theta1 = 45*pi/180;
x1 = xc+100*cos(theta1);
y1 = yc+100*sin(theta1);
theta2 = 135*pi/180;
x2 = xc+100*cos(theta2);
y2 = yc+100*sin(theta2);

% Get 45 degree cut
xyTLV = cutpolygon([xV(:) yV(:)], [[xc; x1],[yc;y1]], 'B');
xyBRV = cutpolygon([xV(:) yV(:)], [[xc; x1],[yc;y1]], 'T');

% Top part
xyTV = cutpolygon([xyTLV(:,1) xyTLV(:,2)], [[xc; x2],[yc;y2]], 'B');

% Left part
xyLV = cutpolygon([xyTLV(:,1) xyTLV(:,2)], [[xc; x2],[yc;y2]], 'T');

% Bottom part
xyBV = cutpolygon([xyBRV(:,1) xyBRV(:,2)], [[xc; x2],[yc;y2]], 'T');

% Right part
xyRV = cutpolygon([xyBRV(:,1) xyBRV(:,2)], [[xc; x2],[yc;y2]], 'B');

