function showComparisonMask(structNumAll,percentAgrement)
%
%APA, 04/04/07
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

global stateS planC
indexS = planC{end};

hAxis = stateS.handle.CERRAxis(1);
view = getAxisInfo(hAxis, 'view');
scanSet     = getStructureAssociatedScan(structNumAll(1));
[xUnifV, yUnifV, jnk] = getUniformScanXYZVals(planC{indexS.scan}(scanSet));
[jnk1, jnk2, zCTV] = getScanXYZVals(planC{indexS.scan}(scanSet));
%get handle to agreement histogram
hFig = findobj('name','Agreement Histogram');
ud = get(hFig,'userdata');
reliability_mat = ud.reliability_mat;
staple3M = ud.staple3M;
for structIndex = 1:length(structNumAll)

    structNum = structNumAll(structIndex);

    switch lower(view)

        case 'transverse'
            zValue=getAxisInfo(hAxis,'coord');
            sliceT=findnearest(zCTV,zValue);            
            maskM = getStructureMask(structNum, sliceT, 3, planC);            
            %corrected mask
            correctedMaskM = reliability_mat(:,:,sliceT);
            %staple mask
            stapleMaskM = staple3M(:,:,sliceT);

        case 'coronal'
            yValue=getAxisInfo(hAxis,'coord');
            sliceC=findnearest(yUnifV,yValue);
            maskM = getStructureMask(structNum, sliceC, 2, planC);
            %corrected mask
            correctedMaskM = squeeze(reliability_mat(sliceC,:,:))';
            %staple mask
            stapleMaskM = squeeze(staple3M(sliceC,:,:))';

        case 'sagittal'
            xValue=getAxisInfo(hAxis,'coord');
            sliceS=findnearest(xUnifV,xValue);
            maskM = getStructureMask(structNum, sliceS,1, planC);
            %corrected mask
            correctedMaskM = squeeze(reliability_mat(:,sliceS,:))';
            %staple mask
            stapleMaskM = squeeze(staple3M(:,sliceS,:))';

    end
    maskAll{structIndex} = maskM;
end

%Calculate intersection mask
intersectMask = maskAll{1};
for i=2:length(maskAll)
    intersectMask = intersectMask + maskAll{i};
end
apparentMask    = intersectMask/length(maskAll) >= percentAgrement;
correctedMask   = correctedMaskM >= percentAgrement;
stapleMask      = stapleMaskM >= percentAgrement;

hAxisAparent = stateS.handle.CERRAxis(1);
cleanupAxes(hAxisAparent);
text('parent', hAxisAparent, 'string', 'Apparent', 'position', [.5 .90 0], 'color', [1 0 0], 'units', 'normalized', 'visible', 'on', 'horizontalAlignment', 'center', 'verticalAlignment', 'top','fontSize',14);
hAxisCorrected = stateS.handle.CERRAxis(2);
cleanupAxes(hAxisCorrected);
text('parent', hAxisCorrected, 'string', 'Corrected', 'position', [.5 .90 0], 'color', [1 0 0], 'units', 'normalized', 'visible', 'on', 'horizontalAlignment', 'center', 'verticalAlignment', 'top','fontSize',14);
hAxisStaple = stateS.handle.CERRAxis(3);
cleanupAxes(hAxisStaple);
text('parent', hAxisStaple, 'string', 'STAPLE', 'position', [.5 .90 0], 'color', [1 0 0], 'units', 'normalized', 'visible', 'on', 'horizontalAlignment', 'center', 'verticalAlignment', 'top','fontSize',14);
set([hAxisAparent hAxisCorrected hAxisStaple], 'nextplot', 'add');

switch lower(view)
    case 'transverse'
        %For Trans:
        [i,j] = find(apparentMask);
        [xV, yV, zV] = mtoxyz(i,j,repmat(sliceT, [length(i) 1]),scanSet,planC);
        if ~isempty(xV)
            h = plot(xV,yV,'marker','.','markersize', 5, 'linestyle','none','color','b', 'parent', hAxisAparent, 'tag', 'ROIMask', 'hittest', 'off');
            stateS.handle.mask = [stateS.handle.mask, h];
        end
        [i,j] = find(correctedMask);
        [xV, yV, zV] = mtoxyz(i,j,repmat(sliceT, [length(i) 1]),scanSet,planC);
        if ~isempty(xV)
            h = plot(xV,yV,'marker','.','markersize', 5, 'linestyle','none','color','m', 'parent', hAxisCorrected, 'tag', 'ROIMask', 'hittest', 'off');
            stateS.handle.mask = [stateS.handle.mask, h];
        end
        [i,j] = find(stapleMask);
        [xV, yV, zV] = mtoxyz(i,j,repmat(sliceT, [length(i) 1]),scanSet,planC);
        if ~isempty(xV)
            h = plot(xV,yV,'marker','.','markersize', 5, 'linestyle','none','color','g', 'parent', hAxisStaple, 'tag', 'ROIMask', 'hittest', 'off');
            stateS.handle.mask = [stateS.handle.mask, h];
        end

    case 'coronal'
        [i,j] = find(apparentMask);
        [xV, yV, zV] = mtoxyz(repmat(sliceC, [length(i) 1]), j, i, scanSet, planC, 'uniform', getUniformScanSize(planC{indexS.scan}(scanSet)));
        if ~isempty(xV)
            h = plot(xV,zV,'marker','.','markersize', 5, 'linestyle','none','color','b', 'parent', hAxisAparent, 'tag', 'ROIMask', 'hittest', 'off');
            stateS.handle.mask = [stateS.handle.mask, h];
        end
        [i,j] = find(correctedMask);
        [xV, yV, zV] = mtoxyz(repmat(sliceC, [length(i) 1]), j, i, scanSet, planC, 'uniform', getUniformScanSize(planC{indexS.scan}(scanSet)));
        if ~isempty(xV)
            h = plot(xV,zV,'marker','.','markersize', 5, 'linestyle','none','color','m', 'parent', hAxisCorrected, 'tag', 'ROIMask', 'hittest', 'off');
            stateS.handle.mask = [stateS.handle.mask, h];
        end
        [i,j] = find(stapleMask);
        [xV, yV, zV] = mtoxyz(repmat(sliceC, [length(i) 1]), j, i, scanSet, planC, 'uniform', getUniformScanSize(planC{indexS.scan}(scanSet)));
        if ~isempty(xV)
            h = plot(xV,zV,'marker','.','markersize', 5, 'linestyle','none','color','g', 'parent', hAxisStaple, 'tag', 'ROIMask', 'hittest', 'off');
            stateS.handle.mask = [stateS.handle.mask, h];
        end

    case 'sagittal'
        [i,j] = find(apparentMask);
        [xV, yV, zV] = mtoxyz(j, repmat(sliceS, [length(i) 1]), i, scanSet, planC, 'uniform', getUniformScanSize(planC{indexS.scan}(scanSet)));
        if ~isempty(yV)
            h = plot(yV,zV,'marker','.','markersize', 5, 'linestyle','none','color','b', 'parent', hAxisAparent, 'tag', 'ROIMask', 'hittest', 'off');
            stateS.handle.mask = [stateS.handle.mask, h];
        end
        [i,j] = find(correctedMask);
        [xV, yV, zV] = mtoxyz(j, repmat(sliceS, [length(i) 1]), i, scanSet, planC, 'uniform', getUniformScanSize(planC{indexS.scan}(scanSet)));
        if ~isempty(yV)
            h = plot(yV,zV,'marker','.','markersize', 5, 'linestyle','none','color','m', 'parent', hAxisCorrected, 'tag', 'ROIMask', 'hittest', 'off');
            stateS.handle.mask = [stateS.handle.mask, h];
        end
        [i,j] = find(stapleMask);
        [xV, yV, zV] = mtoxyz(j, repmat(sliceS, [length(i) 1]), i, scanSet, planC, 'uniform', getUniformScanSize(planC{indexS.scan}(scanSet)));
        if ~isempty(yV)
            h = plot(yV,zV,'marker','.','markersize', 5, 'linestyle','none','color','g', 'parent', hAxisStaple, 'tag', 'ROIMask', 'hittest', 'off');
            stateS.handle.mask = [stateS.handle.mask, h];
        end

end


return
