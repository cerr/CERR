function [yCouch, lines] =  getCouchLocationHough(scan3M,minLengthOpt,retryOpt)

% Function: getCouchLocationHough
% Description: Returns anterior coordinate of patient couch surface
%
% Usage
% inputStack is a 3-dim array of CT scan image with array axes [Y,X,Z]. [Note: "Image" notation permutes Y <-> X]
% yCouch, the Y-coordinate of the scanning table/couch
%
% EML 2020-04-13
%

if ~exist('minLengthOpt','var')
    minLengthOpt = [];
end

if ~exist('retryOpt','var')
    retryOpt = 0;
end

midptS = floor(size(scan3M,1)/2);

maxM = max(scan3M, [], 3);
histeqM = histeq(maxM);
edgeM1 = edge(histeqM,'sobel',[],'horizontal');
edgeM2 = bwmorph(edgeM1,'thicken');

[H,T,R] = hough(edgeM2);
P = houghpeaks(H,20);

if isempty(minLengthOpt)
    minLength = floor(size(edgeM2,2)/8); % couch covers 1/8th of image
else
    minLength = minLengthOpt;
end

% lines = houghlines(edgeM2,T,R,P,'FillGap',5,'MinLength',minLength);
lines = houghlines(edgeM2,T,R,P);
overlapFraction = zeros(1,numel(lines));
midV = [floor(0.5*midptS):floor(0.5*midptS) + midptS];
% Require couch lines to have same starting & ending point2
yi = zeros(1,numel(lines));
% figure; imagesc(maxM); axis equal; hold on
for i = 1:numel(lines)
    len = norm(lines(i).point1 - lines(i).point2);
    if lines(i).point1(2) == lines(i).point2(2) && len > minLength
%         xy = [lines(i).point1; lines(i).point2];
%         plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');
%         % Plot beginnings and ends of lines
%         plot(xy(1,1),xy(1,2),'x','LineWidth',2,'Color','yellow');
%         plot(xy(2,1),xy(2,2),'x','LineWidth',2,'Color','red');
        lineV = [lines(i).point1(1):lines(i).point2(1)];
        if lines(i).point1(2) > midptS && ~isempty(intersect(lineV,midV))
            yi(i) = lines(i).point2(2);
            overlapFraction(i) = numel(intersect(lineV,midV));
        end
    end
end

if any(overlapFraction)
    [~,I] = max(overlapFraction);
    yCouch = yi(I);
else
    yCouch = min(yi(find(yi > 0)));
end

if retryOpt && isempty(yCouch)
    [yCouch, lines] =  getCouchLocationHough(scan3M,minLength/2);
end
