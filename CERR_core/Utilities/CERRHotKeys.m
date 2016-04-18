function CERRHotKeys()
%Routing function called by all CERR figures on keypress
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

global planC stateS; %global is temporary, until stateS and planC are stored in figure userdata.

if ~isempty(planC) && iscell(planC)
    indexS = planC{end};
else
    return;
end

%get Tag of figure making callback.
figureName = get(gcbf, 'Tag');
keyPressed = get(gcbf, 'CurrentCharacter');
keyValue = uint8(keyPressed);
%
if ~isempty(stateS.currentKeyPress)
    stateS.currentKeyPress = keyValue;
end

%if key pressed has no ASCII analogue, quit. He's dead Jim.
if(isempty(keyValue))
    return;
end

%Else, switch based on the key value.  If the same key has different
%effects depending on the figure it originates from, switch on the
%figureName to decide on action.
switch(keyValue)

    case {30, 119} %up arrow
        
        if stateS.layout == 6 && isempty(stateS.currentKeyPress)
            hAxis = gca;
            if ~ismember(hAxis,stateS.handle.CERRAxis);
                return;
            end
            translateScanOnAxis(hAxis, 'PREVSLICE')
            return;
        end
        switch(upper(figureName))
            case 'CERRSLICEVIEWER'
                sliceCallBack('ChangeSlc','PREVSLICE');
            case 'NAVIGATIONFIGURE'
                navigationMontage('up');
            otherwise
        end

    case {31, 115} %down arrow
        if stateS.layout == 6 && isempty(stateS.currentKeyPress)
            hAxis = gca;
            if ~ismember(hAxis,stateS.handle.CERRAxis);
                return;
            end
            translateScanOnAxis(hAxis, 'NEXTSLICE')
            return;
        end        
        switch(upper(figureName))
            case 'CERRSLICEVIEWER'
                sliceCallBack('ChangeSlc','NEXTSLICE');
            case 'NAVIGATIONFIGURE'
                navigationMontage('down');
            otherwise
        end

    case 28 %left arrow
        switch(upper(figureName))
            case 'NAVIGATIONFIGURE'
                navigationMontage('left');
            otherwise
        end

    case 29 %right arrow
        switch(upper(figureName))
            case 'NAVIGATIONFIGURE'
                navigationMontage('right');
            otherwise
        end

    case 66 %'B' Toggles bookmark on current Slice
        navigationMontage('togglebookmark');

    case 98 %'b' Cycles through bookmarked slices.
        try
            %sN = stateS.sliceNum;
            aI = getAxisInfo(stateS.handle.CERRAxis(stateS.currentAxis));
            scanSet = aI.scanSets;
            if strcmpi(aI.view,'transverse')
                zValue = aI.coord;
                [xs, ys, zs] = getScanXYZVals(planC{indexS.scan}(scanSet));
                sN = findnearest(zs, zValue);

                marked = find([planC{indexS.scan}(scanSet).scanInfo.bookmarked]);
                if ~isempty(marked)
                    newSlice = min(marked(marked > sN));
                    if isempty(newSlice)
                        newSlice = marked(1);
                    end
                    %stateS.sliceNum = newSlice;
                    setAxisInfo(stateS.handle.CERRAxis(stateS.currentAxis),'coord',zs(newSlice))
                    CERRRefresh;
                end
            else
                errordlg('Current slice must be transverse')
            end
        end
    case 96 % ` key, next to the 1.  Always calls LabBook.
        LabBookGui('CAPTURE');

    case 127 % delete key.  If in contour mode, deletes contour? think about it.        
        if stateS.contourState
            % delete all segments on the slice
            hAxis = stateS.handle.CERRAxis(stateS.contourAxis);
            contourControl('deleteAllSegments', hAxis)
        end

    case 122 % 'z' key, toggles zoom.
        %         val = get(stateS.handle.zoom, 'value');
        %         set(stateS.handle.zoom, 'value', xor(val, 1));
        sliceCallBack('TOGGLEZOOM');

    case 101 % 'e' key
        contourControl('editMode');
        controlFrame('contour', 'refresh');

    case 100 % 'd' key
        contourControl('drawMode');
        controlFrame('contour', 'refresh');

    case 27 % 'esc' key

    case 116 %'t' key
        contourControl('threshMode');
        controlFrame('contour', 'refresh');

    case 114 %'r' key;
        contourControl('reassignMode');
        controlFrame('contour', 'refresh');
        
    case {76,108} % l or L key
        val = get(stateS.handle.CTLevelWidthInteractive,'value');
        if val == 0
            set(stateS.handle.CTLevelWidthInteractive,'value',1);
        else
            set(stateS.handle.CTLevelWidthInteractive,'value',0);
        end
        sliceCallBack('TOGGLESCANWINDOWING');

end