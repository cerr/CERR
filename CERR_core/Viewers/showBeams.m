function showBeams(hAxis)
%function showBeams(hAxis)
%
%Draws contours of beam rays in CERR axis hAxis.
%The data for beam is obtained from IMRTP GUI's userdata.
%
%APA 01/21/09
%
%Usage:
%   showBeams(hAxis);
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

global stateS

% Check if IMRT GUI is visible
%hIMRTPGui = findobj('tag','IMRTPGui');
hIMRTPGui = stateS.handle.IMRTMenuFig;
if isempty(hIMRTPGui)
    return;
end
ud = get(hIMRTPGui,'userData');
IMDosimetryS = ud.IM;

%Get the view/coord of hAxis.
[view, coord] = getAxisInfo(hAxis, 'view', 'coord');

%set(hAxis, 'nextplot', 'add');

%Delete the already existing beamLines
%beamLineH = findobj(hAxis,'tag','beamLine');
if ~isempty(stateS.handle.beamLine)
    axV = get(stateS.handle.beamLine,'parent');
    if iscell(axV)
        axV = [axV{:}];
    end
    indDelV = axV == hAxis;
    delete(stateS.handle.beamLine(indDelV))
    stateS.handle.beamLine(indDelV) = [];
end

%Set dim or return if not a scan view.
switch lower(view)
    case 'transverse'
        dim = 3;
    case 'sagittal'
        dim = 1;
    case 'coronal'
        dim = 2;
    otherwise
        return;
end

for i = 1:length(ud.IM.beams)
    if get(ud.bl.handles.bevChk(i),'value') %IMDosimetryS.beams(i).visible        
        isodoseClosedContour = getBeamCrossSection();
        if ~isempty(isodoseClosedContour)
            %Get (x,y,z) of rotated dose boundary
            thetaPoly = -pi/180*(ud.IM.beams(i).gantryAngle + 90);
            rotatedPolygon(1,:) = isodoseClosedContour(1,:)*cos(thetaPoly) - isodoseClosedContour(2,:)*sin(thetaPoly) + ud.IM.beams(i).x ;
            rotatedPolygon(2,:) = isodoseClosedContour(1,:)*sin(thetaPoly) + isodoseClosedContour(2,:)*cos(thetaPoly) + ud.IM.beams(i).y ;
            rotatedPolygon(3,:) = isodoseClosedContour(3,:) + IMDosimetryS.beams(i).z;
            %Get the intersection of beam and orthogonal plane
            slicedBeam = calculateBeamIntersect([ud.IM.beams(i).x ud.IM.beams(i).y ud.IM.beams(i).z], rotatedPolygon, dim, coord);
            for j=1:length(slicedBeam)
                stateS.handle.beamLine = [stateS.handle.beamLine; ...
                    plot(slicedBeam{j}(1,:),slicedBeam{j}(2,:),'color','y','parent',hAxis,'tag','beamLine')];
            end
        end
    end
end
