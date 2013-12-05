function createROI(clipBoxMsg,planC)
% function createROI(clipBoxMsg, planC)
%
% APA, 05/04/2012

if ~exist('planC','var')
    global planC
end
indexS = planC{end};
global stateS

if nargin == 0
    ButtonName = questdlg('Choose type of clip-box', 'Create ROI', 'Rectangular', 'Free-hand', 'Cancel', 'Cancel');
    if strcmpi(ButtonName, 'Rectangular')
        stateS.clipState = 1;
        figure(stateS.handle.CERRSliceViewer)
        stateS.ROIcreationMode = 1;
    elseif strcmpi(ButtonName, 'Free-hand')
        stateS.ROIcreationMode = 2;
        stateS.clipState = 1;
        figure(stateS.handle.CERRSliceViewer)
    end
    return;
elseif nargin == 1 && strcmpi(clipBoxMsg,'clipBoxDrawn')
    clipHv = [];
    for axisNum = 1:length(stateS.handle.CERRAxis)
        clipHv = [clipHv findobj(stateS.handle.CERRAxis(axisNum),'tag','clipBox')];
    end
    return;
elseif nargin == 1 && strcmpi(clipBoxMsg,'createROI')
    clipHv = [];
    for axisNum = 1:length(stateS.handle.CERRAxis)
        clipHv = [clipHv findobj(stateS.handle.CERRAxis(axisNum),'tag','clipBox')];
    end
    if length(clipHv) < 2
        return;
    else
        stateS.clipState = 0;
        % Continue to create an ROI based on clip boxes
    end
end

switch stateS.ROIcreationMode
    
    case 1 % rectangular
        
        xmin = Inf;
        xmax = -Inf;
        ymin = Inf;
        ymax = -Inf;
        zmin = Inf;
        zmax = -Inf;
        
        for axisNum = 1:length(stateS.handle.CERRAxis)
            hClip = findobj(stateS.handle.CERRAxis(axisNum),'tag','clipBox');
            if ~isempty(hClip)
                axisView = getAxisInfo(stateS.handle.CERRAxis(axisNum),'view');
                switch upper(axisView)
                    case 'TRANSVERSE'
                        xData = get(hClip,'xData');
                        yData = get(hClip,'yData');
                        xmin = min([xData,xmin]);
                        ymin = min([yData,ymin]);
                        xmax = max([xData,xmax]);
                        ymax = max([yData,ymax]);
                    case 'SAGITTAL'
                        yData = get(hClip,'xData');
                        zData = get(hClip,'yData');
                        ymin = min([yData,ymin]);
                        zmin = min([zData,zmin]);
                        ymax = max([yData,ymax]);
                        zmax = max([zData,zmax]);
                    case 'CORONAL'
                        xData = get(hClip,'xData');
                        zData = get(hClip,'yData');
                        xmin = min([xData,xmin]);
                        zmin = min([zData,zmin]);
                        xmax = max([xData,xmax]);
                        zmax = max([zData,zmax]);
                end
            end
        end
        
        % delete clipbox
        delete(clipHv)
        
        scanNum = getAxisInfo(gca,'scanSets');
        scanNum = scanNum(1);
        
        xV = [xmin xmax xmax xmin xmin];
        yV = [ymin ymin ymax ymax ymin];
        pointsM = [xV' yV'];
        
        % get min and max slices
        zValsV = [planC{indexS.scan}(scanNum).scanInfo.zValue];
        minSliceIndex = findnearest(zValsV,zmin);
        maxSliceIndex = findnearest(zValsV,zmax);
        slcsV = minSliceIndex:maxSliceIndex;
        
        % Create a rectangular ROI on each transverse slice
        newStructNum = length(planC{indexS.structures}) + 1;
        newStructS = newCERRStructure(scanNum, planC);
        for slcNum = slcsV
            newStructS.contour(slcNum).segments(1).points = [pointsM zValsV(slcNum)*pointsM.^0];
        end
        for slcNum = 1:minSliceIndex-1
            newStructS.contour(slcNum).segments.points = [];
        end
        for slcNum = maxSliceIndex+1:length(zValsV)
            newStructS.contour(slcNum).segments.points = [];
        end
        
        stateS.structsChanged = 1;
        
        newStructS.structureName    = 'ROI';
        
        planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructS, newStructNum);
        planC = getRasterSegs(planC, newStructNum);
        planC = updateStructureMatrices(planC, newStructNum);
        
        % Refresh View
        CERRRefresh
        
    case 2 % Free hand
        xmin = Inf;
        xmax = -Inf;
        ymin = Inf;
        ymax = -Inf;
        zmin = Inf;
        zmax = -Inf;        
        transXYpts = [];
        SagYZpts = [];
        CorXZpts = [];
        for axisNum = 1:length(stateS.handle.CERRAxis)
            hClip = findobj(stateS.handle.CERRAxis(axisNum),'tag','clipBox');
            if ~isempty(hClip)
                axisView = getAxisInfo(stateS.handle.CERRAxis(axisNum),'view');
                switch upper(axisView)
                    case 'TRANSVERSE'
                        xData = get(hClip,'xData');
                        yData = get(hClip,'yData');
                        xmin = min([xData,xmin]);
                        ymin = min([yData,ymin]);
                        xmax = max([xData,xmax]);
                        ymax = max([yData,ymax]);                        
                        transXYpts = [xData(:) yData(:)];
                    case 'SAGITTAL'
                        yData = get(hClip,'xData');
                        zData = get(hClip,'yData');
                        ymin = min([yData,ymin]);
                        zmin = min([zData,zmin]);
                        ymax = max([yData,ymax]);
                        zmax = max([zData,zmax]);                        
                        SagYZpts = [yData(:) zData(:)];
                    case 'CORONAL'
                        xData = get(hClip,'xData');
                        zData = get(hClip,'yData');
                        xmin = min([xData,xmin]);
                        zmin = min([zData,zmin]);
                        xmax = max([xData,xmax]);
                        zmax = max([zData,zmax]);                        
                        CorXZpts = [xData(:) zData(:)];
                end
            end
        end
        
        % delete clipbox
        delete(clipHv)   
        
        scanNum = getAxisInfo(gca,'scanSets');
        scanNum = scanNum(1);
        
        uniflag = 1;
        structName = 'ROI';
        
        [xVals, yVals, zVals] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
        firstZval = zVals(1);
        firstXval = xVals(1);
        firstYval = yVals(1);

        uniformSiz = getUniformScanSize(planC{indexS.scan}(scanNum));
        mask3M = zeros(uniformSiz,'uint8');
        
        minSliceIndex = findnearest(zVals,zmin);
        maxSliceIndex = findnearest(zVals,zmax);
        minRowIndex = findnearest(yVals,ymin);
        maxRowIndex = findnearest(yVals,ymax);
        minColIndex = findnearest(xVals,xmin);
        maxColIndex = findnearest(xVals,xmax);
        
        if ~isempty(transXYpts)
            [transRv,transCv,sV] = xyztom(transXYpts(:,1),transXYpts(:,2),firstZval*transXYpts(:,1).^0,scanNum,planC,uniflag);
            transM = zeros(uniformSiz(1), uniformSiz(2), 'uint8');
            [rowM, colM] = meshgrid(1:uniformSiz(1), 1:uniformSiz(2));
            inM = inpolygon(rowM, colM, round(transRv),round(transCv));
            transM(inM) = 1;
            for slc = minSliceIndex:maxSliceIndex
                mask3M(:,:,slc) = transM';
            end            
        end
        
        if ~isempty(SagYZpts)
            [sagRv,cV,sagSv] = xyztom(firstXval*SagYZpts(:,1).^0,SagYZpts(:,1),SagYZpts(:,2),scanNum,planC,uniflag);
            sagM = zeros(uniformSiz(3), uniformSiz(1), 'uint8');
            [rowM, slcM] = meshgrid(1:uniformSiz(1), 1:uniformSiz(3));
            inM = inpolygon(rowM, slcM, round(sagRv),round(sagSv));
            sagM(inM) = 1;
            sagM = reshape(sagM',[uniformSiz(1) 1 uniformSiz(3)]);
            for col = minColIndex:maxColIndex
                mask3M(:,col,:) = mask3M(:,col,:) & sagM;
            end
        end
        
        if ~isempty(CorXZpts)
            [rV,corCv,corSv] = xyztom(CorXZpts(:,1),CorXZpts(:,1).^0*firstYval,CorXZpts(:,2),scanNum,planC,uniflag);
            corM = zeros(uniformSiz(3), uniformSiz(2), 'uint8');
            [colM, slcM] = meshgrid(1:uniformSiz(2), 1:uniformSiz(3));
            inM = inpolygon(colM, slcM, round(corCv),round(corSv));
            corM(inM) = 1;
            corM = reshape(corM',[1 uniformSiz(2) uniformSiz(3)]);
            for row = maxRowIndex:minRowIndex
                mask3M(row,:,:) = mask3M(row,:,:) & corM;
            end            
        end

        planC = maskToCERRStructure(mask3M, uniflag, scanNum, structName, planC);
        
        % Refresh View
        stateS.structsChanged = 1;
        CERRRefresh        
        
end


