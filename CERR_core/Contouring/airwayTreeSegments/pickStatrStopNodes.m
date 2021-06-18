function pickStatrStopNodes(src,evt,hAxis,axisType,~)

global airwayStateS

% set(src,'Marker','o','MarkerSize',12,'MarkerEdgeColor',[0,0,0])
xV = get(src,'XData');
yV = get(src,'YData');
zV = get(src,'ZData');
%x = mean(xV);
%y = mean(yV);
%z = mean(zV);
distV = (xV-evt.IntersectionPoint(1)).^2 + (yV-evt.IntersectionPoint(2)).^2 + ...
    (zV-evt.IntersectionPoint(3)).^2;
[minDist,indMin] = min(distV);
if minDist > 0.5
    return;
end
x = xV(indMin(1));
y = yV(indMin(1));
z = zV(indMin(1));

if strcmpi(axisType,'base')
    if airwayStateS.selectBaseStartNode % size(airwayStateS.baseSegmentStartNodes,1) > size(airwayStateS.baseSegmentEndNodes,1)
        %airwayStateS.baseSegmentEndNodes(end+1,:) = [x,y,z];
        airwayStateS.baseSegmentS(airwayStateS.currentSegment).startNode = indMin(1); 
        airwayStateS.selectBaseStartNode = 0;
        set(airwayStateS.hBaseStart,'XData',x,'YData',y,'zData',z,'visible','on')
        %set(airwayStateS.hBaseEnd,'visible','off')
%         airwayStateS.basehEndNodes = [airwayStateS.basehEndNodes,...
%             plot3(x,y,z,'parent',hAxis,'marker','o','MarkerFaceColor','r',...
%             'markerSize',8,'hittest','off')];
    else
        %airwayStateS.baseSegmentStartNodes(end+1,:) = [x,y,z];
        %set(airwayStateS.hBaseEnd,'XData',x,'YData',y,'zData',z,'visible','on')
        airwayStateS.baseSegmentS(airwayStateS.currentSegment).endNode = indMin(1);
        airwayGraph = airwayStateS.baseTreeS.airwayGraph;
        startNode = airwayStateS.baseSegmentS(airwayStateS.currentSegment).startNode;
        endNode = airwayStateS.baseSegmentS(airwayStateS.currentSegment).endNode;
        allNodesV = shortestpath(airwayGraph,startNode,endNode);
        airwayStateS.baseSegmentS(airwayStateS.currentSegment).allNodes = allNodesV;  
        xyzM = airwayStateS.baseTreeS.nodeXyzM(allNodesV,:);
        if ishandle(airwayStateS.baseSegmentS(airwayStateS.currentSegment).hPlot)
            delete(airwayStateS.baseSegmentS(airwayStateS.currentSegment).hPlot)
        end
        airwayStateS.baseSegmentS(airwayStateS.currentSegment).hPlot = ...
            plot3(airwayStateS.hAxisBase,xyzM(:,1),xyzM(:,2),xyzM(:,3),'linewidth',5,...
            'color',[0,0,1,1],'hittest','off');
        airwayStateS.selectBaseStartNode = 1;
        set(airwayStateS.hBaseStart,'visible','off')
        airwaySegmentCallback('SEGMENT_CLICKED')
%         airwayStateS.basehStartNodes = [airwayStateS.basehStartNodes,...
%             plot3(x,y,z,'parent',hAxis,'marker','o','MarkerFaceColor','g',...
%             'markerSize',8,'hittest','off')];
    end
else
    if airwayStateS.selectFollowupStartNode  %size(airwayStateS.followupSegmentStartNodes,1) > size(airwayStateS.followupSegmentEndNodes,1)
        %airwayStateS.followupSegmentEndNodes(end+1,:) = [x,y,z];
        airwayStateS.followupSegmentS(airwayStateS.currentSegment).startNode = indMin(1);
        airwayStateS.selectFollowupStartNode = 0;
        set(airwayStateS.hFollowupStart,'XData',x,'YData',y,'zData',z,'visible','on')
        %set(airwayStateS.hFollowupEnd,'visible','off')        
%         airwayStateS.followuphEndNodes = [airwayStateS.followuphEndNodes,...
%             plot3(x,y,z,'parent',hAxis,'marker','o','MarkerFaceColor','r',...
%             'markerSize',8,'hittest','off')];
    else
        %         airwayStateS.followupSegmentStartNodes(end+1,:) = [x,y,z];
        airwayStateS.followupSegmentS(airwayStateS.currentSegment).endNode = indMin(1);
        airwayGraph = airwayStateS.followupTreeS.airwayGraph;
        startNode = airwayStateS.followupSegmentS(airwayStateS.currentSegment).startNode;
        endNode = airwayStateS.followupSegmentS(airwayStateS.currentSegment).endNode;
        allNodesV = shortestpath(airwayGraph,startNode,endNode);
        airwayStateS.followupSegmentS(airwayStateS.currentSegment).allNodes = allNodesV;
        %set(airwayStateS.hFollowupEnd,'XData',x,'YData',y,'zData',z,'visible','on')
        xyzM = airwayStateS.followupTreeS.nodeXyzM(allNodesV,:);
        if ishandle(airwayStateS.followupSegmentS(airwayStateS.currentSegment).hPlot)
            delete(airwayStateS.followupSegmentS(airwayStateS.currentSegment).hPlot)
        end
        airwayStateS.followupSegmentS(airwayStateS.currentSegment).hPlot = ...
            plot3(airwayStateS.hAxisFollowup,xyzM(:,1),xyzM(:,2),xyzM(:,3),'linewidth',5,...
            'color',[0,0,1,1],'hittest','off');
        airwayStateS.selectFollowupStartNode = 1;
        set(airwayStateS.hFollowupStart,'visible','off')
        airwaySegmentCallback('SEGMENT_CLICKED')
        
%         airwayStateS.followuphStartNodes = [airwayStateS.followuphStartNodes,...
%             plot3(x,y,z,'parent',hAxis,'marker','o','MarkerFaceColor','g',...
%             'markerSize',8,'hittest','off')];
    end    
end

end

