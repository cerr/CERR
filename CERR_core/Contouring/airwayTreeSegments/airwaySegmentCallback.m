function airwaySegmentCallback(command,varargin)
% function airwaySegmentCallback(command,varargin)
%
% APA, 6/5/2021

global airwayStateS planC

switch upper(command)
    case 'SEGMENT_CLICKED'
        hFig = get(airwayStateS.hAxisBase, 'parent');
        clickType = get(hFig, 'selectiontype');
        switch upper(clickType)
            case 'NORMAL'
                airwayStateS.currentSegment = get(airwayStateS.hSegList,'value');
                numBaseSegments = length(airwayStateS.baseSegmentS);
                numFollowupSegments = length(airwayStateS.followupSegmentS);
                for segNum = 1:numBaseSegments
                    set(airwayStateS.baseSegmentS(segNum).hPlot,'visible','off')
                end
                for segNum = 1:numFollowupSegments
                    if ishandle(airwayStateS.followupSegmentS(segNum).hPlot)
                        set(airwayStateS.followupSegmentS(segNum).hPlot,'visible','off')
                    end
                end
                if ishandle(airwayStateS.baseSegmentS(airwayStateS.currentSegment).hPlot)
                    set(airwayStateS.baseSegmentS(airwayStateS.currentSegment).hPlot,'visible','on')
                end
                if ishandle(airwayStateS.followupSegmentS(airwayStateS.currentSegment).hPlot)
                    set(airwayStateS.followupSegmentS(airwayStateS.currentSegment).hPlot,'visible','on')
                end
                
%                 baseTreeS = airwayStateS.baseTreeS;
%                 followupTreeS = airwayStateS.followupTreeS;
%                 % Show segment on base and followup trees
%                 baseSegmentS = airwayStateS.baseSegmentS(airwayStateS.currentSegment);
%                 followupSegmentS = airwayStateS.followupSegmentS(airwayStateS.currentSegment);
%                 baseSegmentS.startNode % scalar index
%                 baseSegmentS.endNode % scalar index
%                 baseSegmentS.allNodes % scalar indices for base nodes
%                 followupSegmentS.allNodes %scalar indices for followup nodes
%                 baseXyzM = baseTreeS.nodeXyzM(baseSegmentS.allNodes,:);
%                 followupXyzM = followupTreeS.nodeXyzM(followupSegmentS.allNodes,:);
%                 if ~isempty(airwayStateS.hBaseSegment) && ishandle(airwayStateS.hBaseSegment)
%                     delete(airwayStateS.hBaseSegment)
%                 end
%                 if ~isempty(airwayStateS.hFollowupSegment) && ishandle(airwayStateS.hFollowupSegment)
%                     delete(airwayStateS.hFollowupSegment)
%                 end
%                 airwayStateS.hBaseSegment = plot3(baseXyzM(:,1),baseXyzM(:,2),baseXyzM(:,3),'color',[1,0,0],...
%                     'parent',airwayStateS.hAxisBase);
%                 airwayStateS.hFollowupSegment = plot3(followupXyzM(:,1),...
%                     followupXyzM(:,2),followupXyzM(:,3),'color',[1,0,0],...
%                     'parent',airwayStateS.hAxisFollowup);
                
            case 'OPEN'
                % Set buttonDown to pick start/end nodes for segment
                
        end
        
    case 'ADD_SEGMENT'
        strC = get(airwayStateS.hSegList,'String');
        numSegments = length(strC);
        strC{end+1} = ['Seg_',num2str(length(strC)+1)];        
        airwayStateS.currentSegment = numSegments + 1;        
        set(airwayStateS.hSegList,'String',strC,'value',airwayStateS.currentSegment);
        %         hAxisBase = airwayStateS.hAxisBase;
        %         hAxisFollowup = airwayStateS.hAxisFollowup;
        %         hPlotBase = airwayStateS.hPlotBase;
        %         hPlotFollowup = airwayStateS.hPlotFollowup;
        %         axisType = varargin{3};
        %         if strcmpi(axisType,'base')
        %             airwayStateS.baseAddNodes = 1;
        %             airwayStateS.baseShowInCerrViewer = 0;
        %             airwayStateS.baseRemoveNodes = 0;
        %         else
        %             airwayStateS.followupAddNodes = 1;
        %             airwayStateS.followupShowInCerrViewer = 0;
        %             airwayStateS.followupRemoveNodes = 0;
        %         end
        
        indexS = planC{end};
        baseScanIndex = 1;
        followupScanIndex = 2;
        baseScanUID = planC{indexS.scan}(baseScanIndex).scanUID;
        follupScanUID = planC{indexS.scan}(followupScanIndex).scanUID;
        airwayStateS.followupSegmentS(airwayStateS.currentSegment).segName = strC{airwayStateS.currentSegment};
        airwayStateS.followupSegmentS(airwayStateS.currentSegment).nodeXyzM = [];
        airwayStateS.followupSegmentS(airwayStateS.currentSegment).assocScanUID = follupScanUID;
        airwayStateS.baseSegmentS(airwayStateS.currentSegment).segName = strC{airwayStateS.currentSegment};
        airwayStateS.baseSegmentS(airwayStateS.currentSegment).nodeXyzM = [];
        airwayStateS.baseSegmentS(airwayStateS.currentSegment).assocScanUID = baseScanUID;
        
        % Callback to add nodes
        %buttonDownFcn = @pickStatrStopNodes;
        %set(hPlotBase,'ButtonDownFcn',{buttonDownFcn,hAxisBase,'base'});
        %set(hPlotFollowup,'ButtonDownFcn',{buttonDownFcn,hAxisFollowup,'followup'});
        
    case 'REMOVE_SEGMENT'
        strC = get(airwayStateS.hSegList,'String');
        strC(airwayStateS.currentSegment) = [];
        if ishandle(airwayStateS.baseSegmentS(airwayStateS.currentSegment).hPlot)
            delete(airwayStateS.baseSegmentS(airwayStateS.currentSegment).hPlot)
        end
        if ishandle(airwayStateS.followupSegmentS(airwayStateS.currentSegment).hPlot)
            delete(airwayStateS.followupSegmentS(airwayStateS.currentSegment).hPlot)
        end
        airwayStateS.baseSegmentS(airwayStateS.currentSegment) = [];
        airwayStateS.followupSegmentS(airwayStateS.currentSegment) = [];
        set(airwayStateS.hSegList,'String',strC);
        if ~isempty(strC)
            airwayStateS.currentSegment = 1;            
        else
            airwayStateS.currentSegment = 0;
        end
        set(airwayStateS.hSegList,'value',airwayStateS.currentSegment);
        
    case 'RENAME_SEGMENT'
        strC = get(airwayStateS.hSegList,'String');
        segName = strC{airwayStateS.currentSegment};
        prompt={'Enter name for segment:'};
        name='Input segment name';
        numlines=1;
        defaultanswer = {segName};
        segNewName = inputdlg(prompt,name,numlines,defaultanswer);
        if ~isempty(segNewName)
            strC{airwayStateS.currentSegment} = segNewName{1};
            set(airwayStateS.hSegList,'String',strC)
            airwayStateS.baseSegmentS(airwayStateS.currentSegment).segName = segNewName{1};
            airwayStateS.followupSegmentS(airwayStateS.currentSegment).segName = segNewName{1};
        end
        
    case 'LOAD_SEGMENTS'
        if isempty(varargin)            
            [fname,pname] = uigetfile('*.mat','Select filename to save segments');
            fileNam = fullfile(pname,fname);
        else
            fileNam = varargin{1};
        end        
        segmentsInfoS = load(fileNam);
        indexS = planC{end};
        baseScanIndex = 1;
        followupScanIndex = 2;
        baseScanUID = planC{indexS.scan}(baseScanIndex).scanUID;
        follupScanUID = planC{indexS.scan}(followupScanIndex).scanUID;
        
        baseSegmentUID = segmentsInfoS.segmentFeatureS.baseSegmentS(1).assocScanUID;
        followupSegmentUID = segmentsInfoS.segmentFeatureS.followupSegmentS(1).assocScanUID;
        if ~strcmpi(baseScanUID,baseSegmentUID)
            error('Segments do not match the base scan')
        end
                
        % Generate plots for base and followup segments
        numBaseSegs = length(segmentsInfoS.segmentFeatureS.baseSegmentS);
        numFollowupSegs = length(segmentsInfoS.segmentFeatureS.followupSegmentS);

        %airwayStateS.baseSegmentS = segmentsInfoS.segmentFeatureS.baseSegmentS;
        %airwayStateS.followupSegmentS = segmentsInfoS.segmentFeatureS.followupSegmentS;
        
        for segNum = 1:numBaseSegs
            allNodesV = segmentsInfoS.segmentFeatureS.baseSegmentS(segNum).allNodes;
            xyzM = airwayStateS.baseTreeS.nodeXyzM(allNodesV,:);
            if segNum <= length(airwayStateS.baseSegmentS) && ...
                    ishandle(airwayStateS.baseSegmentS(segNum).hPlot)
                delete(airwayStateS.baseSegmentS(segNum).hPlot)
            end
            airwayStateS.baseSegmentS(segNum).hPlot = ...
                plot3(airwayStateS.hAxisBase,xyzM(:,1),xyzM(:,2),xyzM(:,3),'linewidth',5,...
                'color',[0,0,1,1],'hittest','off','visible','off');
            airwayStateS.baseSegmentS(segNum).segName = segmentsInfoS.segmentFeatureS.baseSegmentS(segNum).segName;
            airwayStateS.baseSegmentS(segNum).nodeXyzM = [];
            airwayStateS.baseSegmentS(segNum).startNode = segmentsInfoS.segmentFeatureS.baseSegmentS(segNum).startNode;
            airwayStateS.baseSegmentS(segNum).endNode = segmentsInfoS.segmentFeatureS.baseSegmentS(segNum).endNode;
            airwayStateS.baseSegmentS(segNum).assocScanUID = baseScanUID;

        end    
        
        airwayStateS.baseSegmentS(numBaseSegs+1:end) = [];

        
        % Empty out segments of followup scan
        
        for segNum = 1:numFollowupSegs % should be same as numBaseSegs
            if segNum <= length(airwayStateS.followupSegmentS) && ...
                    ishandle(airwayStateS.followupSegmentS(segNum).hPlot)
                delete(airwayStateS.followupSegmentS(segNum).hPlot)
            end
            airwayStateS.followupSegmentS(segNum).hPlot = [];
            airwayStateS.followupSegmentS(segNum).segName = airwayStateS.baseSegmentS(segNum).segName;
            airwayStateS.followupSegmentS(segNum).nodeXyzM = [];
            airwayStateS.followupSegmentS(segNum).startNode = [];
            airwayStateS.followupSegmentS(segNum).endNode = [];
            airwayStateS.followupSegmentS(segNum).assocScanUID = follupScanUID;
        end
        if strcmpi(follupScanUID,followupSegmentUID)
            for segNum = 1:numFollowupSegs
                allNodesV = segmentsInfoS.segmentFeatureS.followupSegmentS(segNum).allNodes;
                xyzM = airwayStateS.followupTreeS.nodeXyzM(allNodesV,:);
                airwayStateS.followupSegmentS(segNum).hPlot = ...
                    plot3(airwayStateS.hAxisFollowup,xyzM(:,1),xyzM(:,2),xyzM(:,3),'linewidth',5,...
                    'color',[0,0,1,1],'hittest','off','visible','off');
                airwayStateS.followupSegmentS(segNum).segName = airwayStateS.baseSegmentS(segNum).segName;
                airwayStateS.followupSegmentS(segNum).nodeXyzM = [];
                airwayStateS.followupSegmentS(segNum).startNode = segmentsInfoS.segmentFeatureS.followupSegmentS(segNum).startNode;
                airwayStateS.followupSegmentS(segNum).endNode = segmentsInfoS.segmentFeatureS.followupSegmentS(segNum).endNode;
                airwayStateS.followupSegmentS(segNum).assocScanUID = follupScanUID;

            end
        end
        
        airwayStateS.followupSegmentS(numFollowupSegs+1:end) = [];

                
        % Update List        
        strC = {segmentsInfoS.segmentFeatureS.baseSegmentS.segName};
        airwayStateS.currentSegment = 1;
        set(airwayStateS.hSegList,'String',strC,'value',airwayStateS.currentSegment)
        
        airwaySegmentCallback('SHOW_IN_CERR_VIEWER')
        airwaySegmentCallback('SEGMENT_CLICKED')

        
    case 'SAVE_SEGMENTS'
        % Get dose, min radius on base and followup trees for all the segments
        numSegs = length(airwayStateS.baseSegmentS);
        baseMedianDoseV = NaN*ones(numSegs,1);
        baseMedianMinRadiusV = NaN*ones(numSegs,1);
        followupMedianMinRadiusV = NaN*ones(numSegs,1);
        for segNum = 1:numSegs
            baseMedianMinRadiusV(segNum) = median(airwayStateS.baseTreeS.minDistV(airwayStateS.baseSegmentS(segNum).allNodes));
            followupMedianMinRadiusV(segNum) = median(airwayStateS.followupTreeS.minDistV(airwayStateS.followupSegmentS(segNum).allNodes));
            baseMedianDoseV(segNum) = median(airwayStateS.baseTreeS.nodeOrigDoseV(airwayStateS.baseSegmentS(segNum).allNodes));
        end
        
        segmentFeatureS = struct('baseSegmentS',airwayStateS.baseSegmentS,...
            'followupSegmentS',airwayStateS.followupSegmentS,...
            'baseMedianDoseV',baseMedianDoseV,'baseMedianMinRadiusV',baseMedianMinRadiusV,...
            'followupMedianMinRadiusV',followupMedianMinRadiusV);
        [fname,pname] = uiputfile('*.mat','Select filename to save segments');
        fileNam = fullfile(pname,fname);
        save(fileNam,'segmentFeatureS')
        
    case 'SHOW_IN_CERR_VIEWER'
        hPlotBase = airwayStateS.hPlotBase;
        hPlotFollowup = airwayStateS.hPlotFollowup;
        basePt = airwayStateS.basePt;
        followupPt = airwayStateS.followupPt;
        nodeXyzInterpM = airwayStateS.nodeXyzInterpM;
        buttonDownFcn = @showNodeInCerrViewer;
        %set(hPlotBase,'ButtonDownFcn',{buttonDownFcn,axisType,vf,xFieldV,yFieldV,zUnifV,...
        %    basePt,followupPt})         
        set(hPlotBase,'ButtonDownFcn',{buttonDownFcn,'base',basePt,nodeXyzInterpM,followupPt})
        set(hPlotFollowup,'ButtonDownFcn',{buttonDownFcn,'followup',followupPt})
        set(airwayStateS.hSegViewer,'backgroundColor',[0,1,1])
        set(airwayStateS.hSelectSegNodes,'backgroundColor',[0.940, 0.94, 0.94])
        airwayStateS.viewerMode = 1;
        airwayStateS.segSelectMode = 0;
        
    case 'SELECT_SEGMENT_NODES'
        if airwayStateS.currentSegment < 1
            errordlg('Please add segment before selecting start/end nodes')
            return;
        end
        % make viewer points invisible
        set(airwayStateS.basePt,'visible','off')
        set(airwayStateS.followupPt,'visible','off')
        buttonDownFcn = @pickStatrStopNodes;
        
        if ~get(airwayStateS.hLockBaseTreeToggle,'value')
            set(airwayStateS.hPlotBase,'ButtonDownFcn',...
                {buttonDownFcn,airwayStateS.hAxisBase,'base'});
        end
        set(airwayStateS.hPlotFollowup,'ButtonDownFcn',...
        {buttonDownFcn,airwayStateS.hAxisFollowup,'followup'});        
        set(airwayStateS.hSegViewer,'backgroundColor',[0.940, 0.94, 0.94])
        set(airwayStateS.hSelectSegNodes,'backgroundColor',[0,1,1])
        airwayStateS.viewerMode = 0;
        airwayStateS.segSelectMode = 1;

        
    case 'LOCK_BASE_TREE'
        if get(airwayStateS.hLockBaseTreeToggle,'value')
            set(airwayStateS.hLockBaseTreeToggle,'backgroundColor',[0,1,1])
            hPlotBase = airwayStateS.hPlotBase;
            set(hPlotBase,'ButtonDownFcn','')            
        else
            set(airwayStateS.hLockBaseTreeToggle,'backgroundColor',[0.940, 0.94, 0.94])
            if airwayStateS.segSelectMode
                airwaySegmentCallback('SELECT_SEGMENT_NODES')
            elseif airwayStateS.viewerMode
                airwaySegmentCallback('SHOW_IN_CERR_VIEWER')
            end
        end
        
    case 'CLOSEREQUEST'
        delete(airwayStateS.hCrosshairV)
        closereq;
        
end

