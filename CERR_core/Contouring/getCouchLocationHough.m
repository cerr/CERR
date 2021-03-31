function [yCouch, lines] =  getCouchLocationHough(inputStack,minLengthOpt)

%
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

midpt = floor(size(inputStack,1)/2);

maxS = max(inputStack, [], 3);
histeqS = histeq(maxS);
edgeM = edge(histeqS,'sobel',[],'horizontal');
edgeS = bwmorph(edgeM,'thicken');
    
[H,T,R] = hough(edgeS);
P = houghpeaks(H,20);

if isempty(minLengthOpt)
    minLength = floor(size(edgeS,2)/8); % couch covers 1/8th of image
else
    minLength = minLengthOpt;
end

lines = houghlines(edgeS,T,R,P,'FillGap',5,'MinLength',minLength);

% Require couch lines to have same starting & ending point2
yi = zeros(1,numel(lines)); 
for i = 1:numel(lines)
    if lines(i).point1(2) == lines(i).point2(2)
        if lines(i).point1(2) > midpt
            yi(i) = lines(i).point2(2); 
        end
    end
end

yCouch = min(yi(find(yi > 0)));