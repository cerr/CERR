% function showNodeInCerrViewer(src,evt,axisType,basePt,vf,xFieldV,yFieldV,zUnifV,...
%     followupPt,~)
function showNodeInCerrViewer(src,evt,axisType,basePt,nodeXyzInterpM,followupPt,~)


global stateS airwayStateS

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
set(basePt,'XData',x,'YData',y,'ZData',z,'visible','on')

%disp('Base node')
%indMin(1)
% %[x,y,z]
% titleStr = get(get(get(src,'parent'),'title'),'String');
% if ~isempty(findstr(titleStr,'cm'))
%     baseTreeVal = minDistBaseV(indMin(1));
% elseif ~isempty(findstr(titleStr,'Gy'))
%     baseTreeVal = nodeDoseV(indMin(1));
% else % percent change
%     baseTreeVal = nodeDiffV(indMin(1));
% end
% followupTreeVal = minDistV(minIndV(indMin(1)));
% set(hBaseText,'String',baseTreeVal,'visible','on')
% if minDistNodesV(indMin(1)) < 1
%     set(hFollowupText,'String',followupTreeVal,'visible','on')
% else
%     set(hFollowupText,'String','NaN','visible','on')
% end

if strcmpi(axisType,'base')
%     xDeformV = finterp3(x,y,z,...
%         flip(vf(:,:,:,1),1),xFieldV,yFieldV,zUnifV);
%     yDeformV = finterp3(x,y,z,...
%         flip(vf(:,:,:,2),1),xFieldV,yFieldV,zUnifV);
%     zDeformV = finterp3(x,y,z,...
%         flip(vf(:,:,:,3),1),xFieldV,yFieldV,zUnifV);
%     
%     nodeXyzInterpV = [x,y,z] + [xDeformV(:), yDeformV(:), zDeformV(:)];
    
    nodeXyzInterpV = nodeXyzInterpM(indMin,:);
    
    set(followupPt,'XData',nodeXyzInterpV(1), 'YData',nodeXyzInterpV(2), ...
        'ZData',nodeXyzInterpV(3),'visible','on')
end

if isempty(stateS) 
    return
end

zoomMargin = 5; %cm
for ax = 1:length(stateS.handle.CERRAxis)
    
    hAxis = stateS.handle.CERRAxis(ax);
    
    % Set the slice coordinate on the axes
    [axView,scanSets] = getAxisInfo(hAxis,'view','scanSets');
    if scanSets == 1 % base scan
        xCoord = x;
        yCoord = y;
        zCoord = z;
        if strcmpi(axisType,'followup')
            continue;
        end
    elseif scanSets == 2 % moving scan (followup)
        if strcmpi(axisType,'base')
            xCoord = nodeXyzInterpV(1);
            yCoord = nodeXyzInterpV(2);
            zCoord = nodeXyzInterpV(3);
        else
            xCoord = x;
            yCoord = y;
            zCoord = z;
        end
    end
    
    switch upper(axView)
        
        case 'SAGITTAL'
            setAxisInfo(hAxis,'coord',xCoord,'xRange',[yCoord-zoomMargin,yCoord+zoomMargin],...
                'yRange',[zCoord-zoomMargin,zCoord+zoomMargin]);
            
        case 'CORONAL'
            setAxisInfo(hAxis,'coord',yCoord,'xRange',[xCoord-zoomMargin,xCoord+zoomMargin],...
                'yRange',[zCoord-zoomMargin,zCoord+zoomMargin]);
            
        case 'TRANSVERSE'
            setAxisInfo(hAxis,'coord',zCoord,'xRange',[xCoord-zoomMargin,xCoord+zoomMargin],...
                'yRange',[yCoord-zoomMargin,yCoord+zoomMargin]);
        case 'LEGEND'
            continue;
    end
    zoomToXYRange(hAxis)
end

% Refresh CERR
stateS.CTDisplayChanged = 1;
CERRRefresh;

% Show crosshair
if strcmpi(axisType,'followup')
    set(airwayStateS.hCrosshairV(2),'XData',x, 'YData',y,'visible','on')
else
    set(airwayStateS.hCrosshairV(1),'XData',x, 'YData',y,'visible','on')
    set(airwayStateS.hCrosshairV(2),'XData',nodeXyzInterpV(1), 'YData',nodeXyzInterpV(2),'visible','on')
end

end

