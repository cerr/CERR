function [c,h] = CERRContour(hAxis, xV, yV, data2M, contourLevels, lineStyle)
%function [c,h] = CERRContour(xV, yV, data2M, contourLevels, lineStyle)
%This function draws the contour plot in M6 format and returns the contour
%matrix c and the handles to drawn contours h.
%
%APA 9/25/2006


if MLVersion <= 6
    [c,h] = contour(xV, yV, data2M, contourLevels, lineStyle);
    set(h, 'parent', hAxis)
    return
end

%Loop over each level if MLVersion > 6
c = []; h = [];
for levNum = 1:length(contourLevels)
    [cLev,hLev] = contour(xV, yV, data2M, [contourLevels(levNum) contourLevels(levNum)], lineStyle, 'parent', hAxis);
    set(hLev,'userData',contourLevels(levNum))
    c = [c cLev];
    h = [h hLev];
end    
