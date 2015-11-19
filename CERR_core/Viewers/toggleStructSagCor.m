function toggleStructSagCor(structNum)

global planC stateS
indexS = planC{end};

%matlab_version = stateS.MLVersion;

for i = 1:length(stateS.handle.CERRAxis)
    
    hAxis = stateS.handle.CERRAxis(i);
    
    axisInfo = get(hAxis, 'userdata');
    
    scanSet = getStructureAssociatedScan(structNum);
    
    [view coord] = getAxisInfo(hAxis,'view','coord');
    
    switch upper(view)
        %case 'TRANSVERSE'
        %    dim = 3;
        case 'SAGITTAL'
            dim = 1;
        case 'CORONAL'
            dim = 2;
        otherwise
            continue;
    end
    
    [slcC, xV, zV] = getStructureSlice(scanSet, dim, coord);
    structsOnSliceC = [];
    for cellNum = 1:length(slcC)
        structsOnSliceC{cellNum} = cumbitor(slcC{cellNum}(:));
    end
    if isempty(structsOnSliceC)
        includeCurrStruct = 0;
    elseif structNum<=52
        cellNum = 1;
        structsOnSlice = structsOnSliceC{cellNum};
        includeCurrStruct = bitget(structsOnSlice, structNum);
    else
        cellNum = ceil((structNum-52)/8)+1; %uint8
        structsOnSlice = structsOnSliceC{cellNum};
        %includeCurrStruct = bitget(structsOnSlice, structNum-(cellNum-1)*52); %double
        includeCurrStruct = bitget(structsOnSlice, structNum-52-(cellNum-2)*8); %uint8
    end
    if includeCurrStruct && isfield(planC{indexS.structures}(structNum), 'visible')
        if ~isempty(planC{indexS.structures}(structNum).visible) && ~planC{indexS.structures}(structNum).visible
            includeCurrStruct = 0;
        else
            includeCurrStruct = 1;
        end
    end
    
    if includeCurrStruct
        
        if structNum<=52
            oneStructM = bitget(slcC{cellNum}, structNum); %double
        else
            oneStructM = bitget(slcC{cellNum}, structNum-52-(cellNum-2)*8); %uint8
        end
        
        
        %allStrOnSlc = [allStrOnSlc, structNum];
        
        %display oneStructM using contour
        [c, hStructContour] = contour(xV(:), zV(:), oneStructM, [.5 .5], '-');
        set(hStructContour, 'parent', hAxis);
        if stateS.optS.structureDots
            [c, hStructContourDots] = contour(xV(:), zV(:), oneStructM, [.5 .5], '-');
            set(hStructContourDots, 'parent', hAxis);
        end

        if stateS.optS.structureDots
            set(hStructContourDots, 'linewidth', .5, 'tag', 'structContourDots', 'linestyle', ':', 'color', [0 0 0], 'userdata', structNum, 'hittest', 'off')
        end
        set(hStructContour, 'linewidth', stateS.optS.structureThickness, 'tag', 'structContour');
        %set(hStructContour,'color',getColor(structsInThisScan(structNum), stateS.optS.colorOrder), 'hittest', 'off','userdata', structsInThisScan(structNum));
        set(hStructContour,'color',planC{indexS.structures}(structNum).structureColor, 'hittest', 'off','userdata', structNum);
        label = planC{indexS.structures}(structNum).structureName;
        iV = strfind(label,'_');
        for j =  1 : length(iV)
            index = iV(j) + j - 2;
            label = insert('\',label,index);   %to get correct printing of underlines
        end
        %axisInfo.structureGroup(scanSet).structureSet;
        if stateS.optS.structureDots
            axisInfo.structureGroup(scanSet).handles = [axisInfo.structureGroup(scanSet).handles;hStructContour(:);hStructContourDots(:)];
        else
            axisInfo.structureGroup(scanSet).handles = [axisInfo.structureGroup(scanSet).handles;hStructContour(:)];
        end
        ud.structNum = structNum;
        ud.structDesc = label;
        set(hStructContour, 'userdata', ud);
    end
    
    set(hAxis, 'userdata', axisInfo);

end

