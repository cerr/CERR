function [xyTV,xyLV,xyBV,xyRV,newxyTLV,newxyTRV,newxyBLV,newxyBRV,newxyLTV,newxyLBV,newxyRTV,newxyRBV] = dividePolygonInto8Parts(xV,yV,xc,yc)
% function [xyTV,xyLV,xyBV,xyRV,xyTLV,xyTRV,xyBLV,xyBRV,xyLTV,xyLBV,xyRTV,xyRBV] = dividePolygonInto8Parts(xV,yV,xc,yc)
%
% This function divides the passed polygon into Top, Left, Bottom and
% Right, ... parts.
%
% APA, 08/26/2014


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

xyTRV = cutpolygon([xV(:) yV(:)], [[xc; x2],[yc;y2]], 'B');
xyBLV = cutpolygon([xV(:) yV(:)], [[xc; x2],[yc;y2]], 'T');

% Top part
xyTV = cutpolygon([xyTLV(:,1) xyTLV(:,2)], [[xc; x2],[yc;y2]], 'B');

% Left part
xyLV = cutpolygon([xyTLV(:,1) xyTLV(:,2)], [[xc; x2],[yc;y2]], 'T');

% Bottom part
xyBV = cutpolygon([xyBRV(:,1) xyBRV(:,2)], [[xc; x2],[yc;y2]], 'T');

% Right part
xyRV = cutpolygon([xyBRV(:,1) xyBRV(:,2)], [[xc; x2],[yc;y2]], 'B');

% TOP LEFT
newxyTLV = cutpolygon([xyTRV(:,1) xyTRV(:,2)], [[xc; xc],[yc;y2]], 'R');

% TOP RIGHT
newxyTRV = cutpolygon([xyTLV(:,1) xyTLV(:,2)], [[xc; xc],[yc;y2]], 'L');

% BOTTOM LEFT
newxyBRV = cutpolygon([xyBLV(:,1) xyBLV(:,2)], [[xc; xc],[yc;y2]], 'L');

% BOTTOM RIGHT
newxyBLV = cutpolygon([xyBRV(:,1) xyBRV(:,2)], [[xc; xc],[yc;y2]], 'R');


% LEFT TOP
newxyLTV = cutpolygon([xyBLV(:,1) xyBLV(:,2)], [[xc; x2],[yc;yc]], 'B');

%LEFT BOTTOM
newxyLBV = cutpolygon([xyTLV(:,1) xyTLV(:,2)], [[xc; x2],[yc;yc]], 'T');

%RIGHT TOP
newxyRTV = cutpolygon([xyBRV(:,1) xyBRV(:,2)], [[xc; x2],[yc;yc]], 'B');

%RIGHT BOTTOM
newxyRBV = cutpolygon([xyTRV(:,1) xyTRV(:,2)], [[xc; x2],[yc;yc]], 'T');


