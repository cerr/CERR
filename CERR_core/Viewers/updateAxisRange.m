function updateAxisRange(hAxis,flag,utility)
% updateAxisRange
% Checks for the transformation matrix. If the matrix is present then it
% updates the xRange and yRange for the axes and recalculates the coord for each axes
% Created DK 02/28/06
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

global planC stateS
indexS = planC{end};


[view coord,scanSet]    = getAxisInfo(hAxis, 'view','coord','scanSets');

if isempty(scanSet)
    scanSet = stateS.scanSet;
end

[xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(scanSet(1)));

if strcmpi(view,'TRANSVERSE') || strcmpi(view,'SAGITTAL') || strcmpi(view,'CORONAL')
    try
        %Get the transM for this scan.
        transM = getTransM(planC{indexS.scan}(scanSet(1)), planC);
    catch
        transM = [];
    end
    if isempty(transM)==0 && isequal(transM,eye(4))==0
        
        %Get the 8 corners of the scan;
        [xCorner, yCorner, zCorner] = meshgrid([xV(1) xV(end)], [yV(1) yV(end)], [zV(1) zV(end)]);

        %Apply the transM to get the new extremes of x,y,z.
        [xT, yT, zT] = applyTransM(transM, xCorner(:), yCorner(:), zCorner(:));
        if flag
            switch upper(utility)
                case 'CONTOUR'
                    coord = getappdata(hAxis,'oldCoord');
%                     %Coord is to be used what axis was already set to
%                     points = applyTransM(transM,[coord, coord, coord]);
%                     coordX = points(1); coordY = points(2); coordZ = points(3);
%                 otherwise
%                     coordX = coord; coordY = coord; coordZ = coord;
            end
        else
            switch upper(view)
                case 'TRANSVERSE'
                    coord = mean(zT);
                case 'SAGITTAL'
                    coord =  mean(xT);
                case 'CORONAL'
                    coord = mean(yT);
            end

        end

        switch upper(view)
            case 'TRANSVERSE' % DIM 3
                setAxisInfo(hAxis, 'xRange', [min(xT) max(xT)], 'yRange', [min(yT) max(yT)], 'coord', coord);
            case 'SAGITTAL' % DIM 1
                setAxisInfo(hAxis, 'xRange', [min(yT) max(yT)], 'yRange', [min(zT) max(zT)], 'coord', coord);
            case 'CORONAL' % DIM 2
                setAxisInfo(hAxis, 'xRange', [min(xT) max(xT)], 'yRange', [min(zT) max(zT)], 'coord', coord);
        end
    else
        if flag
            %Coord is to be used what axis was already set to
            
        else
            switch upper(view)
                case 'TRANSVERSE'
                    coord = zV(ceil(length(zV)/2));
                case 'SAGITTAL'
                    coord = xV(ceil(length(xV)/2));
                case 'CORONAL'
                    coord = yV(ceil(length(yV)/2));
            end

        end
        switch upper(view)
            case 'TRANSVERSE'
                setAxisInfo(hAxis,'xRange', [min(xV) max(xV)], 'yRange', [min(yV) max(yV)], 'coord',coord);
            case 'SAGITTAL'
                setAxisInfo(hAxis,'xRange', [min(yV) max(yV)], 'yRange', [min(zV) max(zV)], 'coord',coord);
            case 'CORONAL'
                setAxisInfo(hAxis,'xRange', [min(xV) max(xV)], 'yRange', [min(zV) max(zV)], 'coord', coord);
        end
    end
end
return