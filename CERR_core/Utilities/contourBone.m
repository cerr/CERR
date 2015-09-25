function contourBone(command)
%function contourBone
%
% APA, 09/17/2009
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

hFig = findobj('tag','ContourBoneGUI');

if ~isempty(hFig)
    figure(hFig)
end

if isempty(command)
    command = 'init';
end
switch upper(command)

    case 'INIT'

        if ~isempty(hFig)
            figure(hFig)
            return;
        end
        str1 = ['Contour Bone'];
        position = [50 80 250 300];
        hFig = figure('tag','ContourBoneGUI','name',str1,'numbertitle','off',...
            'position',position,'ToolBar','none','MenuBar','none','color',[0.9 0.9 0.9],...
            'CloseRequestFcn', 'contourBone(''closeRequest'')');
        set(gca,'nextPlot','add')
        set(gca,'visible','off')
        stateS.handle.contourBoneFig = hFig;
        units = 'normalized';
        uicolor = [0.8 0.8 0.1];
        hROIFrame       = uicontrol(hFig,'units', units, 'Style', 'frame', 'Position',[0.08 0.60 0.84 0.34]);
        hROIString      = uicontrol(hFig,'units', units, 'Style', 'text', 'Position',[0.08 0.90 0.45 0.06],'string','ROI Selection','fontWeight','bold','fontSize',11,'horizontalAlignment','left');
        hSelectROI      = uicontrol(hFig,'units',units,'style', 'PushButton', 'position',[0.1 0.77 0.7 0.1], 'BackgroundColor',uicolor, 'callback','contourBone(''select_roi'')','interruptible','on','string', 'Select Region of interest');
        hDoneSelectROI  = uicontrol(hFig,'units',units,'style', 'PushButton', 'position',[0.1 0.62 0.7 0.1], 'BackgroundColor',uicolor, 'callback','contourBone(''done_selecting_roi'')','interruptible','on','string', 'Done Selecting Region of interest');

        hContourFrame           = uicontrol(hFig,'units', units, 'Style', 'frame', 'Position',[0.08 0.22 0.84 0.34]);
        hContourString          = uicontrol(hFig,'units', units, 'Style', 'text', 'Position',[0.08 0.51 0.45 0.06],'string','Auto Segment','fontWeight','bold','fontSize',11,'horizontalAlignment','left');
        hContourThresholdStr1   = uicontrol(hFig,'units', units, 'Style', 'text', 'Position',[0.1 0.40 0.35 0.06],'string','Contour Level','fontWeight','normal','fontSize',10,'horizontalAlignment','left');
        hContourThresholdEdit   = uicontrol(hFig,'units', units, 'Style', 'edit', 'Position',[0.46 0.40 0.18 0.06],'string','1120','fontWeight','normal','fontSize',10,'horizontalAlignment','left');
        %hContourThresholdStr2   = uicontrol(hFig,'units', units, 'Style', 'text', 'Position',[0.55 0.40 0.1 0.06],'string','%','fontWeight','normal','fontSize',10,'horizontalAlignment','left');
        hContourCreate          = uicontrol(hFig,'units',units,'style', 'PushButton', 'position',[0.68 0.40 0.15 0.06], 'BackgroundColor',uicolor, 'callback','contourBone(''create_contour'')','interruptible','on','string', 'Go','fontWeight','bold');


        hDeleteContourStr       = uicontrol(hFig,'units', units, 'Style', 'text', 'Position',[0.1 0.28 0.25 0.06],'string','Delete','fontWeight','normal','fontSize',10,'horizontalAlignment','left');
        strNameC = {planC{indexS.structures}.structureName};
        hDeleteContourSelect    = uicontrol(hFig,'units', units, 'Style', 'popup', 'Position',[0.27 0.28 0.5 0.06],'string',strNameC,'value',length(strNameC),'fontWeight','normal','fontSize',10,'horizontalAlignment','left');
        hDeleteContourPush      = uicontrol(hFig,'units', units, 'Style', 'push', 'Position',[0.78 0.28 0.12 0.06],'string','Go','fontWeight','bold','fontSize',10,'callback','contourBone(''delete_contour'')', 'horizontalAlignment','left');

        ud.handles.ROI.hSelectROI = hSelectROI;
        ud.handles.Contour.hContourThresholdEdit = hContourThresholdEdit;
        ud.handles.Contour.hDeleteContourSelect = hDeleteContourSelect;
        
        set(hFig,'userdata',ud)

    case 'SELECT_ROI'
        stateS.clipState = 1;

    case 'DONE_SELECTING_ROI'
        %Get xMin, yMin, zMin, xMax, yMax, zMax
        hBox = findobj('tag', 'clipBox');
        x = [];
        y = [];
        z = [];
        for i=1:length(hBox)
            switch get(hBox(i),'userdata')
                case 'transverse'
                    x = [x get(hBox(i),'XData')];
                    y = [y get(hBox(i),'YData')];
                case 'sagittal'
                    y = [x get(hBox(i),'XData')];
                    z = [z get(hBox(i),'YData')];
                case 'coronal'
                    x = [y get(hBox(i),'XData')];
                    z = [z get(hBox(i),'YData')];
            end
        end
        xMin = min(x);
        yMin = min(y);
        zMin = min(z);
        xMax = max(x);
        yMax = max(y);
        zMax = max(z);
        clipbox = [xMin yMin zMin xMax yMax zMax];
        if length(clipbox) ~= 6
            error('Please select region of interest on two of the T, C or S views')
        end
        ud = get(hFig,'userdata');
        ud.clipbox = clipbox;
        set(hFig,'userdata',ud)
        %sliceCallBack('CLIPMOTIONDONE')
        delete(hBox)
        stateS.clipState = 0;
        CERRRefresh

    case 'CREATE_CONTOUR'

        ud = get(hFig,'userdata');
        clipbox = ud.clipbox;
        xMin = clipbox(1);
        yMin = clipbox(2);
        zMin = clipbox(3);
        xMax = clipbox(4);
        yMax = clipbox(5);
        zMax = clipbox(6);
        hContourThresholdEdit = ud.handles.Contour.hContourThresholdEdit;
        cutoff1 = str2num(get(hContourThresholdEdit,'string'));        
        if isempty(cutoff1)
            error('Incorrect number specified for percent intensity to contour.')
        end       
        percent = 100-cutoff1;
        
        scanNum = stateS.scanSet;
        [xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(scanNum));
        [jMin, jnk] = findnearest(xVals, xMin);
        [jnk, jMax] = findnearest(xVals, xMax);
        [iMin, jnk] = findnearest(yVals, yMin);
        [jnk, iMax] = findnearest(yVals, yMax);
        [kMin, jnk] = findnearest(zVals, zMin);
        [jnk, kMax] = findnearest(zVals, zMax);

        scanArray3M = getScanArray(scanNum);
        SUVvals3M                           = scanArray3M(iMax:iMin,jMin:jMax,kMin:kMax);
        clear scanArray3M
        %maxSUVinStruct                      = max(SUVvals3M(:));
        %cutoff                              = percent/100*maxSUVinStruct;
        [xVals, yVals, zVals]               = getScanXYZVals(planC{indexS.scan}(scanNum));
        %voxelArea = abs((xVals(2) - xVals(1)) * (yVals(2) - yVals(1)));
        %Hardcode voxelArea to make it correspond to physical dimensions
        voxelArea = 0.014;
        xVals = xVals(jMin:jMax);
        yVals = yVals(iMax:iMin);
        newStructNum                        = length(planC{indexS.structures}) + 1;

        uniqueSlices = kMin:kMax;

        level_set = 0;
        if level_set == 1
            %Level Set parameters
            lambda1 = 2;
            lambda2 = 2;
            lambda3 = 1;
            mu = 100;
            cinit = sqrt((xMax-xMin)^2 + (yMax-yMin)^2)/2;
            maxiter = 50;

            phi = autocontourLevelSet(lambda1,lambda2,lambda3, mu,maxiter,cinit, jMin, jMax,iMax,iMin,uniqueSlices,SUVvals3M,scanNum);

        else

            newStructS = newCERRStructure(scanNum, planC);
            for slcNum = 1:length(uniqueSlices)
%                 [numRow,numCol] = size(SUVvals3M(:,:,slcNum));
%                 initialContour = zeros(numRow,numCol);
%                 initialContour(round(numRow/2),round(numCol/2)) = 1;
%                 initialContour = zeros(4,4);
%                 initialContour(round(2:3),round(2:3)) = 1;
%                 phi = active_contoursegment_cerr_fast(SUVvals3M(:,:,slcNum),initialContour);

                C = contourc(xVals, yVals, double(SUVvals3M(:,:,slcNum)),[cutoff1 cutoff1]);
                indC = getSegIndices(C);
                if ~isempty(indC)
                    for seg = 1:length(indC)
                        segArea = polyarea(C(1,indC{seg})',C(2,indC{seg})');
                        if segArea <= 8 * voxelArea
                            continue;
                        end                        
                        points = [C(:,indC{seg})' zVals(uniqueSlices(slcNum))*ones(length(C(1,indC{seg})),1)];
                        %newStructS.contour(uniqueSlices(slcNum)).segments(seg).points = points;
                        newStructS.contour(uniqueSlices(slcNum)).segments(end+1).points = points;
                    end
                else
                    newStructS.contour(uniqueSlices(slcNum)).segments.points = [];
                end
            end

            for l = max(uniqueSlices)+1 : length(planC{indexS.scan}(scanNum).scanInfo)
                newStructS.contour(l).segments.points = [];
            end
            stateS.structsChanged = 1;

            newStructS.structureName    = ['Threshold ',num2str(cutoff1)];

            planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructS, newStructNum);
            planC = getRasterSegs(planC, newStructNum);
            planC = updateStructureMatrices(planC, newStructNum, uniqueSlices);
            CERRRefresh
            %Update structure deletion list
            hDeleteContourSelect = ud.handles.Contour.hDeleteContourSelect;
            strNameC = {planC{indexS.structures}.structureName};
            set(hDeleteContourSelect,'string',strNameC,'value',length(strNameC))
        end

        return;
        
    case 'DELETE_CONTOUR'
        ud = get(hFig,'userdata');
        hDeleteContourSelect = ud.handles.Contour.hDeleteContourSelect;
        structNum = get(hDeleteContourSelect,'value');
        runCERRCommand(['del structure ',num2str(structNum)]);
        strNameC = {planC{indexS.structures}.structureName};
        set(hDeleteContourSelect,'string',strNameC,'value',length(strNameC))

        
    case 'CLOSEREQUEST'
        hBox = findobj('tag', 'clipBox');
        delete(hBox)
        stateS.clipState = 0;
        stateS.handle = rmfield(stateS.handle,'contourBoneFig');
        try
            CERRRefresh
        end
        closereq

end
return;



function indC = getSegIndices(C)
% function getSegIndices(C)
%
%This function returns the indices for each segment of input contour C.
%C is output from in-built "contourc" function
%
%APA, 12/15/2006

start = 1;
counter = 1;
indC = [];
while start < length(C(2,:))
    numPts = C(2,start);
    indC{counter} = [(start+1):(start+numPts) start+1];
    start = start + numPts + 1;
    counter = counter + 1;
end
