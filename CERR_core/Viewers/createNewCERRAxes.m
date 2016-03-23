function createNewCERRAxes(numAxes)
% function createNewCERRAxes(numAxes)
%
% This function creates new CERR axes and its associated metadata.
%
% APA, 03/01/2016

global stateS

numOldAxes = length(stateS.handle.CERRAxis);

% for i = 1:numAxes
%    sliceCallBack('DUPLICATEAXIS',stateS.handle.CERRAxis(1)); 
% end
% return;

for i = numOldAxes+(1:numAxes) % create linked axis to the transverse axis
    aI = axisInfoFactory;
    stateS.handle.CERRAxis(i) = axes('parent',stateS.handle.CERRSliceViewer, 'units', 'pixels', 'position', [1 1 1 1],...
        'color', [0 0 0], 'ZLim',[-2 2], 'xTickLabel', [], 'yTickLabel', [], 'xTick', [], 'yTick', [], 'buttondownfcn',...
        'sliceCallBack(''axisClicked'')', 'nextplot', 'add', 'yDir', 'reverse', 'linewidth', 2);
    
    tickV = linspace(0.02,0.1,6);
    for j = 1:6
        ticks1V(j) = line([tickV(j) tickV(j)], [0.01 0.03], [2 2], 'parent', stateS.handle.CERRAxis(i), 'color', 'y', 'hittest', 'off', 'visible', 'off');
        ticks2V(j) = line([0.01 0.03], [tickV(j) tickV(j)], [2 2], 'parent', stateS.handle.CERRAxis(i), 'color', 'y', 'hittest', 'off', 'visible', 'off');
    end
                
    %aI = stateS.handle.aI(1);
    aI.coord   = 0;
    aI.view    = 'transverse';
    
    aI.scanObj(1:end) = [];
    aI.doseObj(1:end) = [];
    aI.structureGroup(1:end) = [];
    aI.miscHandles = [];
    aI.xRange = [];
    aI.yRange = [];
    
%     aI.coord       = {'Linked', hCSVA};
%     aI.view        = {'Linked', hCSVA};
%     aI.xRange      = {'Linked', hCSVA};
%     aI.yRange      = {'Linked', hCSVA};      
    
    stateS.handle.CERRAxisTicks1(i,:) = ticks1V;
    stateS.handle.CERRAxisTicks2(i,:) = ticks2V;
    stateS.handle.CERRAxisLabel1(i) = text('parent', stateS.handle.CERRAxis(i), 'string', '', 'position', [.02 .98 0], 'color', [1 0 0], 'units', 'normalized', 'visible', 'off', 'horizontalAlignment', 'left', 'verticalAlignment', 'top');
    stateS.handle.CERRAxisLabel2(i) = text('parent', stateS.handle.CERRAxis(i), 'string', '', 'position', [.90 .98 0], 'color', [1 0 0], 'units', 'normalized', 'visible', 'off', 'horizontalAlignment', 'left', 'verticalAlignment', 'top');
    stateS.handle.CERRAxisScale1(i) = line([0.02 0.1], [0.02 0.02], [2 2], 'parent', stateS.handle.CERRAxis(i), 'color', [1 0.5 0.5], 'hittest', 'off', 'visible', 'off');
    stateS.handle.CERRAxisScale2(i) = line([0.02 0.02], [0.02 0.1], [2 2], 'parent', stateS.handle.CERRAxis(i), 'color', [1 0.5 0.5], 'hittest', 'off', 'visible', 'off');
    stateS.handle.CERRAxisLabel3(i) = text('parent', stateS.handle.CERRAxis(i), 'string', '5', 'position', [0.02 0.1 0], 'color', 'y', 'units', 'data', 'visible', 'off', 'hittest', 'off','fontSize',8);
    stateS.handle.CERRAxisLabel4(i) = text('parent', stateS.handle.CERRAxis(i), 'string', '5', 'position', [0.1 0.02 0], 'color', 'y', 'units', 'data', 'visible', 'off', 'hittest', 'off','fontSize',8);

    
    stateS.handle.CERRAxisPlnLoc{i} = [];
    stateS.handle.CERRAxisPlnLocSdw{i} = [];
    if ~strcmpi(aI.view, 'Legend')
        
        for count = 1:10
            if stateS.MLVersion < 8.4
                stateS.handle.CERRAxisPlnLocSdw{i}(count) = line([0.02 0.1], [0.02 0.02], [2 2], 'parent', stateS.handle.CERRAxis(i), 'Color', [0 0 0], 'tag', 'planeLocatorShadow', 'userdata', {'horz', 'trans', i}, 'hittest', 'off', 'linewidth', 1, 'erasemode','xor');
                stateS.handle.CERRAxisPlnLoc{i}(count) = line([0.02 0.1], [0.02 0.02], [2 2], 'parent', stateS.handle.CERRAxis(i), 'Color', [0 0 0], 'tag', 'planeLocator',  'buttondownfcn', 'sliceCallBack(''locatorClicked'')', 'userdata', {'vert', 'trans', i}, 'linewidth', 1, 'erasemode','xor');
            else
                stateS.handle.CERRAxisPlnLocSdw{i}(count) = line([0.02 0.1], [0.02 0.02], [2 2], 'parent', stateS.handle.CERRAxis(i), 'Color', [0 0 0], 'tag', 'planeLocatorShadow', 'userdata', {'horz', 'trans', i}, 'hittest', 'off', 'linewidth', 1);
                stateS.handle.CERRAxisPlnLoc{i}(count) = line([0.02 0.1], [0.02 0.02], [2 2], 'parent', stateS.handle.CERRAxis(i), 'Color', [0 0 0], 'tag', 'planeLocator',  'buttondownfcn', 'sliceCallBack(''locatorClicked'')', 'userdata', {'vert', 'trans', i}, 'linewidth', 1);
            end
        end
        
    end
    
    aI.miscHandles = [aI.miscHandles stateS.handle.CERRAxisLabel1(i) ...
        stateS.handle.CERRAxisLabel2(i) stateS.handle.CERRAxisLabel3(i) ...
        stateS.handle.CERRAxisLabel4(i) stateS.handle.CERRAxisScale1(i) ...
        stateS.handle.CERRAxisScale2(i) stateS.handle.CERRAxisTicks1(i,:) ...
        stateS.handle.CERRAxisTicks2(i,:)];           
    
    for j = 1:stateS.optS.linePoolSize
        aI.lineHandlePool(1).lineV(j) = line(NaN, NaN, 'parent', stateS.handle.CERRAxis(i), 'linestyle', '-', 'hittest', 'off', 'visible', 'off');
        aI.lineHandlePool(1).dotsV(j) = line(NaN, NaN, 'parent', stateS.handle.CERRAxis(i), 'linestyle', ':', 'hittest', 'off', 'visible', 'off');
    end
    aI.lineHandlePool(1).currentHandle = 0;    

    stateS.handle.aI = dissimilarInsert(stateS.handle.aI,aI);
    
end
