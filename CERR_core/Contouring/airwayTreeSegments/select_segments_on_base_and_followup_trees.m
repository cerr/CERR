function select_segments_on_base_and_followup_trees(baseCerrFile,baseTreeFile,...
    followupTreeFile,vfFile,segmentsFile)
% function  select_segments_on_base_and_followup_trees(baseCerrFile,baseTreeFile,...
%     followupTreeFile,vfFile)
%
% Example
%
% APA, 5/4/2021


global airwayStateS stateS
% airwayStateS.baseAddNodes = 0;
% airwayStateS.baseShowInCerrViewer = 1;
% airwayStateS.baseRemoveNodes = 0;
% airwayStateS.followupAddNodes = 0;
% airwayStateS.followupShowInCerrViewer = 1;
% airwayStateS.followupRemoveNodes = 0;
% airwayStateS.baseSegmentStartNodes = [];
% airwayStateS.baseSegmentEndNodes = [];
% airwayStateS.basehStartNodes = [];
% airwayStateS.basehEndNodes = [];
% airwayStateS.followupSegmentStartNodes = [];
% airwayStateS.followupSegmentEndNodes = [];
% airwayStateS.followuphStartNodes = [];
% airwayStateS.followuphEndNodes = [];
% airwayStateS.hBaseSegment = [];
% airwayStateS.hFollowupSegment = [];
airwayStateS.selectBaseStartNode = 1;
airwayStateS.selectFollowupStartNode = 1;
% airwayStateS.hBaseStart
% airwayStateS.hBaseEnd
% airwayStateS.hFollowupStart
% airwayStateS.hFollowupEnd

% Create crosshairs 
numAxis = length(stateS.handle.CERRAxis);
for i = 1:numAxis
    hCrosshairV(i) = plot(0,0, ...
        'parent', stateS.handle.CERRAxis(i), 'Marker','+', 'MarkerSize',10,...
        'color', [1 1 0], 'hittest', 'off','linewidth',3,'visible','off');
end

airwayStateS.hCrosshairV = hCrosshairV;


% Load base scan with dose
planC = loadPlanC(baseCerrFile,tempdir);
planC = updatePlanFields(planC);
planC = quality_assure_planC(baseCerrFile,planC);

% Get grid for vf
scanNum = 1;
indexS = planC{end};
[xUnifV,yUnifV,zUnifV] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
xFieldV = [xUnifV(1),xUnifV(2)-xUnifV(1),xUnifV(end)];
yFieldV = [yUnifV(end),yUnifV(1)-yUnifV(2),yUnifV(1)];


% % Load base tree
% load(baseTreeFile)
% elemDistBaseV = elemDistV;
% elemAreaBaseV = elemAreaV;
% elemBaseM = elemM;
% nodeXyzBaseM = nodeXyzM;

% Load base tree
load(baseTreeFile)
minDistBaseV = minDistV;
elemBaseM = elemM;
nodeXyzBaseM = nodeXyzM;
centerTreeXyzBaseM = centerTreeXyzM;
% nodeDistFromCarinaBaseV = nodeDistFromCarinaV;
treeS.nodeXyzM = nodeXyzM;
treeS.elemM = elemM;
xyzStartM = [nodeXyzM(elemM(:,1),1),nodeXyzM(elemM(:,1),2),nodeXyzM(elemM(:,1),3)];
xyzEndM = [nodeXyzM(elemM(:,2),1),nodeXyzM(elemM(:,2),2),nodeXyzM(elemM(:,2),3)];
elemDistV = sum((xyzStartM - xyzEndM).^2,2).^0.5;
airwayGraph = graph(elemM(:,1),elemM(:,2),elemDistV);
treeS.airwayGraph = airwayGraph;
treeS.minDistV = minDistV;
airwayStateS.baseTreeS = treeS;

% Load followup tree
load(followupTreeFile)
minDistFollowupV = minDistV;
elemFollowupM = elemM;
nodeXyzFollowupM = nodeXyzM;
nodeXyzFollowupSmoothM = centerTreeXyzM;
treeS.nodeXyzM = nodeXyzM;
treeS.elemM = elemM;
xyzStartM = [nodeXyzM(elemM(:,1),1),nodeXyzM(elemM(:,1),2),nodeXyzM(elemM(:,1),3)];
xyzEndM = [nodeXyzM(elemM(:,2),1),nodeXyzM(elemM(:,2),2),nodeXyzM(elemM(:,2),3)];
elemDistV = sum((xyzStartM - xyzEndM).^2,2).^0.5;
airwayGraph = graph(elemM(:,1),elemM(:,2),elemDistV);
treeS.airwayGraph = airwayGraph;
% Smooth radius calculation
minDistBaseV = smoothRadius(nodeXyzBaseM,centerTreeXyzBaseM,minDistBaseV);
minDistFollowupV = smoothRadius(nodeXyzFollowupM,nodeXyzFollowupM,minDistFollowupV);
treeS.minDistV = minDistFollowupV;
airwayStateS.followupTreeS = treeS;


% Get deformation at nodes
load(vfFile)

% Get location of base points on followup scan
xDeformV = finterp3(nodeXyzBaseM(:,1),nodeXyzBaseM(:,2),nodeXyzBaseM(:,3),...
    flip(vf(:,:,:,1),1),xFieldV,yFieldV,zUnifV);
yDeformV = finterp3(nodeXyzBaseM(:,1),nodeXyzBaseM(:,2),nodeXyzBaseM(:,3),...
    flip(vf(:,:,:,2),1),xFieldV,yFieldV,zUnifV);
zDeformV = finterp3(nodeXyzBaseM(:,1),nodeXyzBaseM(:,2),nodeXyzBaseM(:,3),...
    flip(vf(:,:,:,3),1),xFieldV,yFieldV,zUnifV);

nodeXyzInterpM = nodeXyzBaseM + [xDeformV(:), yDeformV(:), zDeformV(:)];

airwayStateS.nodeXyzInterpM = nodeXyzInterpM;

% Calculate radius change
distTolerance = 1; %cm
radiusDiffV = calculateRadiusChange(nodeXyzBaseM,nodeXyzFollowupM,...
    minDistBaseV,minDistFollowupV,distTolerance,...
    vf,xFieldV,yFieldV,zUnifV);

% Calculate dose
doseNum = 1;
% nodeDoseV = getDoseAt(doseNum, centerTreeXyzBaseM(:,1), centerTreeXyzBaseM(:,2),...
%     centerTreeXyzBaseM(:,3), planC);
nodeOrigDoseV = getDoseAt(doseNum, nodeXyzBaseM(:,1), nodeXyzBaseM(:,2),...
    nodeXyzBaseM(:,3), planC);

airwayStateS.baseTreeS.nodeOrigDoseV = nodeOrigDoseV;

% Initialize figure to show airway trees
hFig = figure('CloseRequestFcn','airwaySegmentCallback(''closeRequest'')',...
    'numbertitle','off');
% baseAxis = subplot(1,2,1);
% followupAxis = subplot(1,2,2);
% set(baseAxis,'NextPlot','add')
% set(followupAxis,'NextPlot','add')

baseAxis = axes('parent', hFig, 'units', 'normalized','NextPlot','add', ...
    'position', [0.2 0.1 0.38 0.8], 'color', [1,1,1]);
followupAxis = axes('parent', hFig, 'units', 'normalized','NextPlot','add', ...
    'position', [0.6 0.1 0.38 0.8], 'color', [1,1,1]);
hSegList = uicontrol(hFig,'units','normalized','Position',[0.02 0.55, 0.15, 0.4],...
    'Style','list','callback','airwaySegmentCallback(''SEGMENT_CLICKED'')');

hSegAdd = uicontrol(hFig,'units','normalized','Position',[0.02 0.5, 0.03, 0.05],...
    'Style','push','String','+','callback','airwaySegmentCallback(''ADD_SEGMENT'')');
hSegRemove = uicontrol(hFig,'units','normalized','Position',[0.06 0.5, 0.03, 0.05],...
    'Style','push','String','-','callback','airwaySegmentCallback(''REMOVE_SEGMENT'')');
hSegRename = uicontrol(hFig,'units','normalized','Position',[0.1 0.5, 0.07, 0.05],...
    'Style','push','String','Name','callback','airwaySegmentCallback(''RENAME_SEGMENT'')');

hLoadSegments = uicontrol(hFig,'units','normalized','Position',[0.02 0.4, 0.15, 0.05],...
    'Style','push','String','Load','callback','airwaySegmentCallback(''LOAD_SEGMENTS'')');
hSaveSegments = uicontrol(hFig,'units','normalized','Position',[0.02 0.33, 0.15, 0.05],...
    'Style','push','String','Save','callback','airwaySegmentCallback(''SAVE_SEGMENTS'')');
hSegViewer = uicontrol(hFig,'units','normalized','Position',[0.02 0.26, 0.15, 0.05],...
    'Style','push','String','Viewer','callback','airwaySegmentCallback(''SHOW_IN_CERR_VIEWER'')');
hSelectSegNodes = uicontrol(hFig,'units','normalized','Position',[0.02 0.19, 0.15, 0.05],...
    'Style','push','String','Select seg nodes','callback','airwaySegmentCallback(''SELECT_SEGMENT_NODES'')');
hLockBaseTreeToggle = uicontrol(hFig,'units','normalized','Position',[0.02 0.12, 0.15, 0.05],...
    'Style','toggle','String','Lock base tree','callback','airwaySegmentCallback(''LOCK_BASE_TREE'')');
airwayStateS.hAxisBase = baseAxis;
airwayStateS.hAxisFollowup = followupAxis;
airwayStateS.hSegList = hSegList;
airwayStateS.hSegAdd = hSegAdd;
airwayStateS.hSegRemove = hSegRemove;
airwayStateS.hSegRename = hSegRename;
airwayStateS.hSegViewer = hSegViewer;
airwayStateS.hLoadSegments = hLoadSegments;
airwayStateS.hSaveSegments = hSaveSegments;
airwayStateS.hSelectSegNodes = hSelectSegNodes;
airwayStateS.hLockBaseTreeToggle = hLockBaseTreeToggle;
airwayStateS.viewerMode = 1;
airwayStateS.segSelectMode = 0;
segS = struct('segName','segment','nodeXyzM',[],...
    'startNode',[],'endNode',[],'allNodes',[],...
    'hPlot',[],'assocScanUID','');
airwayStateS.followupSegmentS = segS;
airwayStateS.followupSegmentS(:) = [];
airwayStateS.baseSegmentS = segS;
airwayStateS.baseSegmentS(:) = [];
airwayStateS.totalSegments = 0;
airwayStateS.currentSegment = 0;

basePt = plot3(baseAxis,0,0,0,'marker','o','markerSize',12,...
    'MarkerEdgeColor',[0,0,0],'visible','off','hittest','off');
airwayStateS.hBaseStart = plot3(baseAxis,0,0,0,'marker','o','markerSize',12,...
    'MarkerEdgeColor','g','visible','off','color','g','hittest','off');
airwayStateS.hBaseEnd = plot3(baseAxis,0,0,0,'marker','o','markerSize',12,...
    'MarkerEdgeColor','r','visible','off','color','r','hittest','off');


set(baseAxis,'zDir','reverse')
hPlotBase = scatter3(baseAxis,nodeXyzBaseM(:,1),nodeXyzBaseM(:,2),nodeXyzBaseM(:,3),...
'sizeData',12,'MarkerEdgeColor','None',...
'MarkerFaceColor','flat','MarkerFaceAlpha',0.5,'CData',[0.5,0.5,0.5]);
airwayStateS.hPlotBase = hPlotBase;
airwayStateS.basePt = basePt;
%set(hp,'ButtonDownFcn',{buttonDownFcn,varargin{:},nodeValV});
axis(baseAxis,'equal')
view(baseAxis,3)
xlabel(baseAxis,'R - L','fontsize',10)
ylabel(baseAxis,'A - P','fontsize',10)
zlabel(baseAxis,'I - S','fontsize',10)
grid(baseAxis,'on')
title(baseAxis,'Baseline')


% Load followup tree
% load(followupTreeFile)
% baseFig = figure;
% hold on,
% baseAxis = gca;
followupPt = plot3(followupAxis,0,0,0,'marker','o','markerSize',12,...
    'MarkerEdgeColor',[0,0,0],'visible','off','hittest','off');
airwayStateS.hFollowupStart = plot3(followupAxis,0,0,0,'marker','o','markerSize',12,...
    'MarkerEdgeColor','g','visible','off','color','g','hittest','off');
airwayStateS.hFollowupEnd = plot3(followupAxis,0,0,0,'marker','o','markerSize',12,...
    'MarkerEdgeColor','r','visible','off','color','r','hittest','off');
airwayStateS.followupPt = followupPt;
set(followupAxis,'zDir','reverse')
hPlotFollowup = scatter3(followupAxis,nodeXyzFollowupM(:,1),...
    nodeXyzFollowupM(:,2),nodeXyzFollowupM(:,3),...
'sizeData',12,'MarkerEdgeColor','None',...
'MarkerFaceColor','flat','MarkerFaceAlpha',0.5,'CData',[0.5,0.5,0.5]);
airwayStateS.hPlotFollowup = hPlotFollowup;

axis(followupAxis,'equal')
view(followupAxis,3)
xlabel(followupAxis,'R - L','fontsize',10)
ylabel(followupAxis,'A - P','fontsize',10)
zlabel(followupAxis,'I - S','fontsize',10)
grid(followupAxis,'on')
title(followupAxis,'Followup')

airwaySegmentCallback('SHOW_IN_CERR_VIEWER')

if exist('segmentsFile','var') && ~isempty(segmentsFile)
    airwaySegmentCallback('LOAD_SEGMENTS',segmentsFile);
end


% % Callback to add nodes
% buttonDownFcn = @pickStatrStopNodes;
% set(hPlotFollowup,'ButtonDownFcn',{buttonDownFcn,followupAxis});

% % Callback to show nodes in Viewer
% buttonDownFcn = @showNodeInCerrViewer;
% set(hPlotBase,'ButtonDownFcn',{buttonDownFcn,vf,xFieldV,yFieldV,zUnifV,...    
%     basePt,followupPt})

% % Callback to remove nodes
% buttonDownFcn = @removeStatrStopNodes;
% set(hPlotFollowup,'ButtonDownFcn',{buttonDownFcn,followupAxis});



% Set buttondown function



%% Plots

% Create contextmenu
% baseMenu = uicontextmenu('Callback', 'airwayAxisMenu(''init_start_stop_view_nodes'')',...
%     'userdata', {'base',baseAxis,hPlotBase,basePt,vf,xFieldV,yFieldV,zUnifV,followupPt,...
%     minDistBaseV, radiusDiffV, nodeOrigDoseV}, 'parent', hFig);
baseMenu = uicontextmenu('Callback', 'airwayAxisMenu(''init_start_stop_view_nodes'')',...
    'userdata', {'base',baseAxis,hPlotBase,basePt,nodeXyzInterpM,followupPt,...
    minDistBaseV, radiusDiffV, nodeOrigDoseV}, 'parent', hFig);
% followupMenu = uicontextmenu('Callback', 'airwayAxisMenu(''init_start_stop_view_nodes'')',...
%     'userdata', {'followup',followupAxis,hPlotFollowup,followupPt}, 'parent', hFig);
set(baseAxis, 'UIContextMenu', baseMenu);
%set(followupAxis, 'UIContextMenu', followupMenu);

% buttonDownFcn = @showNodeInCerrViewer;
% set(hPlotBase,'ButtonDownFcn',{buttonDownFcn,'base',basePt,nodeXyzInterpM,...
%    followupPt})
% set(hPlotFollowup,'ButtonDownFcn',{buttonDownFcn,'followup',followupPt})


% followupMenu = uicontextmenu('Callback', 'airwayAxisMenu(''choose_start_stop'')',...
%     'userdata', {}, 'parent', followupFig);
% set(baseAxis, 'UIContextMenu', followupMenu);


% m1 = uimenu(baseCtxMenu,'Text','Airway Radius');
% m2 = uimenu(baseCtxMenu,'Text','RT Dose');
% m3 = uimenu(baseCtxMenu,'Text','Change in Airway Radius');


% % Plot elements color-coded by opening radius
% radiusDiffV = (elemDistV(minIndV)-elemDistBaseV)./elemDistBaseV*100;
% radiusDiffV(minDistV > 0.5) = NaN;
% minDist = min(radiusDiffV);
% maxDist = max(radiusDiffV);
% maxMinusMinDist = maxDist - minDist;
% cmapM = CERRColorMap('jetmod');
% cmapSiz = size(cmapM,1)-1;
% cmapIndV = round((radiusDiffV - minDist) / maxMinusMinDist * cmapSiz) + 1;
% 
% xyzStartM = [nodeXyzBaseM(elemBaseM(:,1),1),nodeXyzBaseM(elemBaseM(:,1),2),nodeXyzBaseM(elemBaseM(:,1),3)];
% xyzEndM = [nodeXyzBaseM(elemBaseM(:,2),1),nodeXyzBaseM(elemBaseM(:,2),2),nodeXyzBaseM(elemBaseM(:,2),3)];
% 
% figure ,hold on,
% set(gca,'zDir','reverse')
% for i = 1:size(xyzStartM,1)
%     if ~isnan(elemDistV(minIndV(i))) && ~isnan(elemDistBaseV(i)) && ~isnan(cmapIndV(i))
%         xV = [xyzStartM(i,1), xyzEndM(i,1)];
%         yV = [xyzStartM(i,2), xyzEndM(i,2)];
%         zV = [xyzStartM(i,3), xyzEndM(i,3)];
%         plot3(xV,yV,zV,'color',[cmapM(cmapIndV(i),:),1],...
%             'linewidth',3,'ButtonDownFcn',@showNodeOnFollowupTree); %@gotoNodeInCerrViewer
%         %plot3(xV,yV,zV,'b.')
%     end
% end
% set(gca,'cLim',[minDist,maxDist])
% colormap(cmapM)
% ticksV = linspace(minDist,maxDist,10);
% tickC = {};
% for i = 1:length(ticksV)
%     tickC{i} = num2str(ticksV(i)); 
% end
% hCbar = colorbar('Ticks',ticksV,'TickLabels',tickC);
% axis('equal')
% view(3)
% xlabel('x','fontsize',18)
% ylabel('y','fontsize',18)
% zlabel('z','fontsize',18)
% grid('on')
% title(titleStr)

