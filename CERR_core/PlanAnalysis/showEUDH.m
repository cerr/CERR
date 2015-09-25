function showEUDH(DVHNum,aParam,op)
%function showEUDH(DVHNum,aParam,op)
%Show Generalized EUD Histograms, the relative contributions
%      of dose bins to total EUD.
%op = 'newEUDH', creates new figure showing relative contributions
%      of dose bins to total EUD, and total EUD.
%      or 'addEUDH' adds a new plot to current figure.
%DVHNum is the index of the DVH in planC, e.g.: planC{DVHIndex}.DVH(DVHNum).DVHMatrix
%
%JOD, 21 Sept 06.
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

global planC

persistent legendC hV

DVHMatrix = planC{planC{end}.DVH}(DVHNum).DVHMatrix;

deltaDose = DVHMatrix(2,1) - DVHMatrix(1,1);

totalVol = sum(DVHMatrix(:,2));

warning('DVH dose bins must be the same size')

switch lower(op)

  case 'neweudh'

    figure
    doseV = DVHMatrix(:,1)+deltaDose/2;
    diffGDVH = doseV .^ aParam .* DVHMatrix(:,2)/totalVol;
    cumGDVH =  cumsum(diffGDVH');
    cumGDVH = (cumGDVH / cumGDVH(end)) * cumGDVH(end)^(1/aParam);
    h = plot(doseV, cumGDVH,'-r','LineWidth',1.5);
    hV = h;
    hold on
    plot(doseV(end), cumGDVH(end),'*r','MarkerSize',5)
    xlabel('Dose')
    ylabel('Cumulative contribution to total gEUD')
    title('gEUD histogram')
    legendC = {planC{planC{end}.DVH}(DVHNum).structureName};
    legend(hV,legendC,'location','best')
    hold off
    warning('Unchecked:  Indexing may be off by one.')
    
    


  case 'addeudh'

    hold on
    doseV = DVHMatrix(:,1)+deltaDose/2;
    diffGDVH = doseV .^ aParam .* DVHMatrix(:,2)/totalVol;
    cumGDVH =  cumsum(diffGDVH');
    cumGDVH = (cumGDVH / cumGDVH(end)) * cumGDVH(end)^(1/aParam);
    h = plot(doseV, cumGDVH ,'-g','LineWidth',1.5);
    hV = [hV, h];
    plot(doseV(end), cumGDVH(end),'*g','MarkerSize',5)
    legendC = {legendC{:},planC{planC{end}.DVH}(DVHNum).structureName};
    legend(hV,legendC,'location','best')
    hold off
    warning('Unchecked:  Indexing may be off by one.')
    


end









