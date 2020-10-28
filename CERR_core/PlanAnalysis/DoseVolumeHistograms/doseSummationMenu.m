function doseSummationMenu(command)
%"doseSummationMenu"
%   Create the GUI used to sum doses.
%
%Shunde 7/05 - Adapted from doseSubtractionMenu.
%   11/07/05 KU  Modified how new dose name is entered.
%   1/05/08  KU  Function entirely rewritten to allow summation of multiple plans.
%   1/25/08  APA Changed the "addition" code to include transM
%
%Usage:
%   doseSummationMenu()

global planC;
global stateS;
indexS = planC{end};

if nargin == 0
    command = 'init';
end

hFig = findobj('tag', 'CERRDoseSummationFigure');

switch upper(command)
    case 'INIT'
        if ~isempty(hFig)
            delete(hFig);
        end
        screenSize = get(0,'ScreenSize');        
        units = 'pixels';
        y = 480;
        x = 480;

        dx = 20;
        dy = 20;
        
        hFig = figure('Name', 'Dose Summation', 'doublebuffer', 'on', 'units', 'pixels', 'position',[(screenSize(3)-x)/2 (screenSize(4)-y)/2 x y], 'MenuBar', 'none', 'NumberTitle', 'off', 'resize', 'off', 'Tag', 'CERRDoseSummationFigure');    
        stateS.handle.doseSummationMenuFig = hFig; 

        bartop = 80;        
        loadbot = y-65-10;
        
        ud.handles.instruction = uicontrol('units',units,'HorizontalAlignment','left','Position',[dx y-dy-60 x-2*dx 20],'String', 'Select the doses to be included in the sum dose.', 'Style','text','Tag','text1');
        ud.handles.labelname = uicontrol('units',units,'HorizontalAlignment','left','Position',[dx y-dy-10 100 15],'String', 'New Dose Name:', 'Style','text','Tag','text2'); 
        ud.handles.newDoseName = uicontrol('units',units,'Position',[dx y-dy-35 80 20],'BackgroundColor',[1 1 1],'HorizontalAlignment','left','String', '', 'Style','edit','Tag','doseName');          
        ud.handles.lqCheck = uicontrol('units',units,'Position',[dx+95 y-dy-35 50 40],...
            'BackgroundColor',[1 1 1],'HorizontalAlignment','center','String', 'LQ?',...
            'value',1, 'Style','check','Tag','lqCheck','callback', 'doseSummationMenu(''LQCHECK'');');          
        ud.handles.abLabel = uicontrol('units',units,'HorizontalAlignment','center','Position',[dx+150 y-dy-10 50 15],'String', 'a/b:', 'Style','text','Tag','a/b'); 
        ud.handles.abRatio = uicontrol('units',units,'Position',[dx+150 y-dy-35 50 20],'BackgroundColor',[1 1 1],'HorizontalAlignment','left','String', '10', 'Style','edit','Tag','doseName');          
        ud.handles.stdFxLabel = uicontrol('units',units,'HorizontalAlignment','center','Position',[dx+205 y-dy-10 50 15],'String', 'Std Fx:', 'Style','text','Tag','stdFx'); 
        ud.handles.stdFx = uicontrol('units',units,'Position',[dx+205 y-dy-35 50 20],'BackgroundColor',[1 1 1],'HorizontalAlignment','left','String', '2', 'Style','edit','Tag','doseName');          
        ud.handles.assocname = uicontrol('units',units,'HorizontalAlignment','left','Position',[x-dx-170 y-dy-10 80 15],'String', 'Associate with scan:', 'Style','text','Tag','scanAssoc');
        scanStr{1} = 'None';
        for i=1:length(planC{indexS.scan})
            scanStr{i+1} = [num2str(i), '. ', planC{indexS.scan}(i).scanType];
        end        
        ud.handles.scanSelect = uicontrol('units',units,'Position',[x-dx-170 y-dy-35 80 20],'BackgroundColor',[1 1 1],'HorizontalAlignment','left','String', scanStr, 'Style','popup','value',1,'Tag','scanSelect');

        %Make CANCEL and SUM buttons
        ud.handles.cancelButton = uicontrol(hFig, 'callback', 'doseSummationMenu(''CANCEL'');', 'units',units,'Position',[x-dx-70 y-dy-35 70 20],'String','Cancel', 'Style','pushbutton','Tag','cancelButton');
        ud.handles.sumButton = uicontrol(hFig, 'callback', 'doseSummationMenu(''SUM'');', 'units',units, 'Position',[x-dx-70 y-dy-10 70 20],'String','Sum', 'Style','pushbutton','Tag','sumButton');
        
        %Plans frame and label
        planFrame  = uicontrol(hFig, 'units',units,'Position',[dx dy x-2*dx y-dy-bartop], 'style', 'frame');
        frameColor = get(planFrame, 'BackgroundColor');           

        %Create scrollbar on right side. Inactive to start.
        ud.df.handles.scroll = uicontrol(hFig, 'units',units,'Position',[x-dx-20 dy 20 y-dy-bartop], 'style', 'slider', 'enable', 'off','tag','planSlider', 'callback', 'doseSummationMenu(''SLIDER'')');              
        
        %Create plan UICONTROLS.
        uicontrol(hFig, 'units',units,'Position',[23 loadbot-46 15 15], 'style', 'text', 'String', 'No.', 'fontweight', 'bold', 'backgroundcolor', frameColor);   
        uicontrol(hFig, 'units',units,'Position',[40 loadbot-46 100 15], 'style', 'text', 'String', 'Plan Name', 'fontweight', 'bold', 'backgroundcolor', frameColor);   
        uicontrol(hFig, 'units',units,'Position',[dx+130 loadbot-46 70 15], 'style', 'text', 'String', 'Assoc Scan', 'fontweight', 'bold', 'backgroundcolor', frameColor);   
        uicontrol(hFig, 'units',units,'Position',[dx+240 loadbot-46 60 15], 'style', 'text', 'String', 'Select', 'fontweight', 'bold', 'backgroundcolor', frameColor);   
        uicontrol(hFig, 'units',units,'Position',[dx+230 loadbot-46 15 15], 'style', 'check', 'String', '', 'backgroundcolor', frameColor,'callback','doseSummationMenu(''CheckAll'')');   
        uicontrol(hFig, 'units',units,'Position',[dx+300 loadbot-46 100 15], 'style', 'text', 'String', 'Weighting Factor', 'fontweight', 'bold', 'backgroundcolor', frameColor);     
        
        numRows = length(planC{indexS.dose})+49;
        for i=1:numRows
            ud.handles.doseNum(i)   = uicontrol(hFig, 'units',units,'Position',[15 359-i*20 20 15], 'style', 'text', 'String', num2str(i), 'backgroundcolor', frameColor, 'visible', 'off');    
            ud.handles.doseName(i)  = uicontrol(hFig, 'units',units,'Position',[35 359-i*20 80 15], 'style', 'text', 'String', 'Dose', 'backgroundcolor', frameColor, 'visible', 'off');    
            ud.handles.scanName(i)  = uicontrol(hFig, 'units',units,'Position',[160 359-i*20 40 15], 'style', 'text', 'String', 'Scan', 'backgroundcolor', frameColor, 'visible', 'off');    
            ud.handles.doseCheck(i) = uicontrol(hFig, 'units',units,'Position',[280 359-i*20 25 15], 'style', 'checkbox', 'backgroundcolor', frameColor, 'horizontalAlignment', 'center', 'userdata', i, 'Tag', 'DoseCheck', 'callback', 'doseSummationMenu(''Check'')', 'visible', 'off');  
            ud.handles.wtfactor(i)  = uicontrol(hFig, 'units',units,'Position',[340 359-i*20 45 15], 'Style','edit', 'String', '1.0', 'BackgroundColor',[1 1 1],'horizontalAlignment', 'center', 'userdata', i, 'Tag','wtfactor', 'callback', 'doseSummationMenu(''Check'')', 'visible', 'off'); 
            ud.wtfactor(i) = 1;
        end
        ud.numDoseRows = numRows; 
        
        ud.firstVisDose     = 1;
        
        set(hFig, 'userdata', ud);   
        
        nDoses = length(planC{indexS.dose});
        ud.checkedDoses = zeros(nDoses, 1);
        
        
        %Set range of currently displayed doses.
        ud.df.range = 1:min(16, nDoses);

        set(hFig, 'userdata', ud);
        doseSummationMenu('refresh');        

    case 'LQCHECK'
        ud = get(hFig, 'userdata'); 
        lqVal = get(ud.handles.lqCheck,'value');
        onOffStr = 'off';
        if lqVal
            onOffStr = 'on';
        end
        set(ud.handles.abLabel,'enable',onOffStr)
        set(ud.handles.abRatio,'enable',onOffStr)
        set(ud.handles.stdFxLabel,'enable',onOffStr)
        set(ud.handles.stdFx,'enable',onOffStr)
        
        
    case 'REFRESH'
        ud = get(hFig, 'userdata');     
        indexS = planC{end};
        
        %Number of visible doses.
        nvDoses = length(ud.df.range);
        
        %Refresh dose UIelements.
        set(ud.handles.doseNum,  'visible', 'off');
        set(ud.handles.doseName,  'visible', 'off');        
        set(ud.handles.scanName,  'visible', 'off');
        set(ud.handles.doseCheck, 'visible', 'off'); 
        set(ud.handles.wtfactor, 'visible', 'off');
        nDoses = length(ud.checkedDoses);      
        ud.firstVisDose = min(ud.df.range);
        for i=1:min(length(ud.handles.doseName), nvDoses)
            doseNum  = ud.firstVisDose+i-1;
            doseName = planC{indexS.dose}(doseNum).fractionGroupID;    
            if ~isempty(planC{indexS.dose}(doseNum).assocScanUID)
                scanNum = strmatch(planC{indexS.dose}(doseNum).assocScanUID,{planC{indexS.scan}.scanUID});
            else
                scanNum = [];
            end
            scanName = [num2str(scanNum),'. ',planC{indexS.scan}(scanNum).scanType];
            set(ud.handles.doseNum(doseNum), 'string', num2str(doseNum), 'visible', 'on', 'Position',[22 359-i*20 22 15])
            set(ud.handles.doseName(doseNum), 'string', doseName, 'visible', 'on', 'Position',[40 359-i*20 80 15]);     
            set(ud.handles.scanName(doseNum), 'string', scanName, 'visible', 'on', 'Position',[160 359-i*20 40 15]);     
            set(ud.handles.doseCheck(doseNum), 'visible', 'on', 'Position',[280 359-i*20 25 15]);
            set(ud.handles.wtfactor(doseNum), 'visible', 'on', 'Position',[340 359-i*20 45 15]);
        end 
        
        if nDoses > 16
            set(ud.df.handles.scroll, 'min', 0, 'max', nDoses-nvDoses, 'value', nDoses-nvDoses+1-min(ud.df.range), 'enable', 'on', 'sliderstep', [1/(nDoses-nvDoses), nvDoses/(nDoses-nvDoses)]);
        else
            set(ud.df.handles.scroll, 'enable', 'off');
        end

        set(hFig, 'userdata', ud);
        
    case 'CHECK'
        checkNum = get(gcbo, 'userdata');
        type     = get(gcbo, 'Tag');
        ud = get(hFig, 'userdata');
        
        switch upper(type)
            case 'DOSECHECK'
                value = get(gcbo, 'value');
                ud.checkedDoses(checkNum) = value;
                if value == 1
                    assocScan = getAssociatedScan(planC{indexS.dose}(checkNum).assocScanUID);
                    if ~isempty(assocScan)
                        set(ud.handles.scanSelect,'value',1+assocScan)
                    end
                end
            case 'WTFACTOR'
                wtFactor = str2num(get(gcbo, 'string'));
                if ~isempty(wtFactor)
                    ud.wtfactor(checkNum) = wtFactor;
                end
        end
        
        set(hFig, 'userdata', ud);      
       
    case 'CHECKALL'
        ud = get(hFig, 'userdata');
        check_val = get(gcbo, 'value');        
        assocScanV = [];
        for i=1:length(ud.checkedDoses)
            ud.checkedDoses(i) = check_val;
            set(ud.handles.doseCheck,'value',check_val)
            assocScan = getAssociatedScan(planC{indexS.dose}(i).assocScanUID);
            assocScanV = [assocScanV  assocScan];            
        end
        if length(unique(assocScanV)) > 1
            set(ud.handles.scanSelect,'value',1)
        else
            set(ud.handles.scanSelect,'value',1+assocScanV(1))
        end
        set(hFig, 'userdata', ud);
        
        
    case 'SLIDER'
        %Slider was clicked, move ud.df.range.
        ud = get(hFig, 'userdata');
        val = round(get(gcbo, 'value'));
        
        nRows = 16;
        nDoses  = length(planC{indexS.dose});
        
        lastDose = nDoses - val;
        ud.df.range = max(1, lastDose-nRows+1):lastDose;
        set(hFig, 'userdata', ud);        
        doseSummationMenu('REFRESH');  

        
    case 'SUM'
        hFig = findobj('tag', 'CERRDoseSummationFigure');
        ud = get(hFig, 'userdata');
        checkedDoses = find(ud.checkedDoses);
        if isempty(checkedDoses)
			warndlg('You must select at least one dose plan','Incorrect Selection','modal')
            return
        end
        
        % Check for duplicate or blank name.
        newDoseName = get(ud.handles.newDoseName, 'String');        
        if isempty(newDoseName)
            warndlg('Please enter a name for the new plan.', 'Warning','modal');
            return;
        end
        for i = 1:length(planC{indexS.dose})
            if strcmpi(planC{indexS.dose}(1,i).fractionGroupID, newDoseName)
                warndlg('A plan already exists with that name. Please choose another name.', 'Warning','modal');
                return;
            end
        end
        
        %Check that no checked plan has a weighting factor that is blank.
        for i = 1:length(planC{indexS.dose})
            %factor = str2num(get(ud.handles.wtfactor(i), 'String'));
            factor = ud.wtfactor(i);
            if isempty(factor) && ~isempty(find(checkedDoses == i))
                warndlg('Please enter a weighting factor for all selected doses.', 'Warning','modal');
                return
            elseif isempty(factor)
                factor = 0;
            end
            wtfactor(i) = factor;
        end        
        
        % LQ or Physical summation
        lqCheckVal = get(ud.handles.lqCheck,'value');
        if lqCheckVal
            abRatio = str2num(get(ud.handles.abRatio,'string'));
            stdFractionSize = str2num(get(ud.handles.stdFx,'string'));
            SOPInstanceUIDv = {planC{indexS.beams}.SOPInstanceUID};
            paramS.Tk.val = inf;         %Kick-off time of repopulation (days)
            paramS.Tp.val = NaN;        %Potential tumor doubling time (days)
            paramS.alpha.val = NaN;
            paramS.abRatio.val = abRatio;  %alpha/beta            
        end
        
        %% APA code begins
        assocScan = get(ud.handles.scanSelect,'value') - 1;

        if assocScan > 0
            assocScanUID = planC{indexS.scan}(assocScan).scanUID;
            %Get associated transM
            assocTransM = planC{indexS.scan}(assocScan).transM;
            if isempty(assocTransM)
                assocTransM = eye(4);
            end
        else %No Association
            assocScanUID = '';
            assocTransM = eye(4);
        end

        doseNums = checkedDoses;
        
        %Get the x,y,z grid for new dose
        for i = 1:length(doseNums)
            doseNum = doseNums(i);
            %Get x,y,z values for doseNum
            [xV, yV, zV] = getDoseXYZVals(planC{indexS.dose}(doseNum));

            %Get the corners of the original dataset.
            [xCorn, yCorn, zCorn] = meshgrid([min(xV) max(xV)], [min(yV) max(yV)], [min(zV) max(zV)]);

            %Add ones to the corners so we can apply a transformation matrix.
            corners = [xCorn(:) yCorn(:) zCorn(:) ones(prod(size(xCorn)), 1)];

            %Apply transform to corners, so we know boundary of the slice.
            transM = getTransM(planC{indexS.dose}(doseNum),planC);
            if isempty(transM) || isequal(transM,eye(4))
                [xV,yV,zV] = getDoseXYZVals(planC{indexS.dose}(doseNum));
                xGrid{doseNum} = xV(:)';
                yGrid{doseNum} = yV(:)';
                zGrid{doseNum} = zV(:)';
            else
                newCorners = inv(assocTransM) * transM * corners';
                xGrid{doseNum} = linspace(min(newCorners(1,:)), max(newCorners(1,:)), length(xV));
                yGrid{doseNum} = linspace(max(newCorners(2,:)), min(newCorners(2,:)), length(yV));
                zGrid{doseNum} = linspace(min(newCorners(3,:)), max(newCorners(3,:)), length(zV));
            end
            xRes{doseNum} = length(xV);
            yRes{doseNum} = length(yV);
            zRes{doseNum} = length(zV);
            
            %Get associated scan
            assocScanV{doseNum} = getAssociatedScan(planC{indexS.dose}(doseNum).assocScanUID);
        end
        newXgrid = linspace(min(cell2mat(xGrid)),max(cell2mat(xGrid)),max(cell2mat(xRes)));
        newYgrid = linspace(max(cell2mat(yGrid)),min(cell2mat(yGrid)),max(cell2mat(yRes)));
        newZgrid = linspace(min(cell2mat(zGrid)),max(cell2mat(zGrid)),max(cell2mat(zRes)));

        %Obtain doses with same grid
        if isempty(assocTransM)
            assocTransM = eye(4);
        end        
        doseIndC = {};
        doseNumsTmp = doseNums;
        for iSortAll = 1:length(doseNums)
            iSort = doseNums(iSortAll);
            indRemaining = doseNums;
            indRemaining(iSortAll) = [];
            doseSortM = [iSort];
            if ~ismember(iSort,[doseIndC{:}])
                for jSortAll = 1:length(indRemaining)
                    jSort = indRemaining(jSortAll);
                    if ~isempty(getTransM('dose',iSort,planC))
                        doseITM = inv(assocTransM) * getTransM('dose',iSort,planC);
                    else
                        doseITM = inv(assocTransM);
                    end
                    if ~isempty(getTransM('dose',jSort,planC))
                        doseJTM = inv(assocTransM) * getTransM('dose',jSort,planC);
                    else
                        doseJTM = inv(assocTransM);
                    end
                    if isequal([xRes{iSort},yRes{iSort},zRes{iSort}],[xRes{jSort},yRes{jSort},zRes{jSort}]) && isequal(doseITM,doseJTM)
                        doseSortM(end+1) = jSort;
                        indJsort = find(doseNumsTmp == jSort);
                        doseNumsTmp(indJsort) = [];
                    end
                end
            end
            doseIndC{iSort} = doseSortM;
        end
        
        doseNums = doseNumsTmp;
        
        %Loop over doses and add over new grid
        hWait = waitbar(0,'Summing Dose distributions');
        doseSumM = zeros([length(newYgrid),length(newXgrid),length(newZgrid)],'single');
        doseEmptyM = zeros([length(newYgrid),length(newXgrid)],'single');
        
        %Assume dose units are same as that of 1st dose
        doseUnits = getDoseUnitsStr(doseNums(1),planC);
        for i = 1:length(doseNums)
            
            doseNum = doseNums(i);
            
            %Check for transM
            if ~isempty(assocTransM) && ~isequal(assocTransM,eye(4))
                doseTtransM = getTransM('dose',doseNum,planC);
                if isempty(doseTtransM)
                    doseTtransM = eye(4);
                end
                inputTM = inv(assocTransM) * doseTtransM;
            else
                inputTM = getTransM('dose',doseNum,planC);
                if isempty(inputTM)
                    inputTM = eye(4);
                end
            end
            
            %Get the summation for this grid
            doseCombinedM = [];
            for iDoseAll = 1:length(doseIndC{doseNum})
                iDose = doseIndC{doseNum}(iDoseAll);
                doseUnits2 = getDoseUnitsStr(iDose,planC);
                if strcmpi(doseUnits, 'Gy') && strcmpi(doseUnits2, 'cGy')
                    multFact = 0.01;
                elseif strcmpi(doseUnits, 'cGy') && strcmpi(doseUnits2, 'Gy')
                    multFact = 100;
                else
                    multFact = 1;
                end
                doseOffset = planC{indexS.dose}(iDose).doseOffset;
                if isempty(doseOffset)
                    doseOffset = 0;
                end
                doseArray = single(getDoseArray(planC{indexS.dose}(iDose)) - doseOffset);
                % Apply BED/EQD2 correction
                if lqCheckVal
                    ReferencedSOPInstanceUID = planC{indexS.dose}(iDose)...
                        .DICOMHeaders.ReferencedRTPlanSequence.Item_1.ReferencedSOPInstanceUID;
                    planNum = find(strcmpi(ReferencedSOPInstanceUID,SOPInstanceUIDv));
                    paramS.numFractions.val = planC{indexS.beams}(planNum).FractionGroupSequence...
                        .Item_1.NumberOfFractionsPlanned;
                    paramS.numFractions.val = double(paramS.numFractions.val);
                    paramS.frxSize.val = doseArray / paramS.numFractions.val;
                    doseArray = calc_BED(paramS) / (1+stdFractionSize/paramS.abRatio.val);
                end
                
                if ~isempty(doseCombinedM)
                    doseCombinedM = doseCombinedM + multFact * wtfactor(iDose) * doseArray;
                else
                    doseCombinedM = multFact * wtfactor(iDose) * doseArray;
                end
            end

            %Check if this dose is on same grid as the new one
            %if isequal(xGrid{doseNum},newXgrid) && isequal(yGrid{doseNum},newYgrid) && isequal(zGrid{doseNum},newZgrid)
            chkLength = length(xGrid{doseNum})==length(newXgrid) && length(yGrid{doseNum})==length(newYgrid) && length(zGrid{doseNum})==length(newZgrid);
            if sum(sum((inputTM-eye(4)).^2)) < 1e-3 && chkLength && max(abs(xGrid{doseNum}-newXgrid)) < 1e-3 && max(abs(yGrid{doseNum}-newYgrid)) < 1e-3 && max(abs(zGrid{doseNum}-newZgrid)) < 1e-3

                doseSumM = doseSumM + doseCombinedM;
                waitbar((i-1)/length(doseNums),hWait,['Calculating contribution from Dose ', num2str(doseNum)])

            else %interpolation required

                %Transform this dose
                doseTmpM = [];

                for slcNum=1:length(newZgrid)
                    [xV, yV, zV] = getDoseXYZVals(planC{indexS.dose}(doseNum));
                    doseTmp = slice3DVol(doseCombinedM, xV, yV, zV, newZgrid(slcNum), 3, 'linear', inputTM, [], newXgrid, newYgrid);
                    if isempty(doseTmp)
                        doseTmpM(:,:,slcNum) = doseEmptyM;
                    else
                        doseTmpM(:,:,slcNum) = doseTmp;
                    end
                    waitbar((i-1)/length(doseNums) + (slcNum-1)/length(newZgrid)/length(doseNums) ,hWait,['Calculating contribution from Dose ', num2str(doseNum)])
                end
                
                doseSumM = doseSumM + doseTmpM;
                
            end

        end
        
        delete(hWait)

        %Create new dose distribution
        newDoseNum = length(planC{indexS.dose}) + 1;
        planC{indexS.dose}(newDoseNum).doseArray = doseSumM;
        clear doseSumM
        planC{indexS.dose}(newDoseNum).doseUID = createUID('dose');
        planC{indexS.dose}(newDoseNum).assocScanUID = assocScanUID;

        %Find minimum value in 3d array, use its negative as the offset
        maxDose = max(max(max(planC{indexS.dose}(newDoseNum).doseArray)));
        offset = -min(min(min(planC{indexS.dose}(newDoseNum).doseArray)));
        if offset > 0
            planC{indexS.dose}(newDoseNum).doseOffset = offset;
            planC{indexS.dose}(newDoseNum).doseArray = planC{indexS.dose}(newDoseNum).doseArray + offset;
        end

        %set labels on new dose, overwriting some of the copied labels **Check for more labels that need to be replaced
        planC{indexS.dose}(newDoseNum).doseNumber = newDoseNum;
        planC{indexS.dose}(newDoseNum).fractionGroupID = newDoseName;

        %Remove old caching info.
        planC{indexS.dose}(newDoseNum).cachedMask = [];
        planC{indexS.dose}(newDoseNum).cachedColor = [];
        planC{indexS.dose}(newDoseNum).cachedTime = [];

        %Set coordinates.
        planC{indexS.dose}(newDoseNum).sizeOfDimension1 = length(newXgrid);
        planC{indexS.dose}(newDoseNum).sizeOfDimension2 = length(newYgrid);
        planC{indexS.dose}(newDoseNum).sizeOfDimension3 = length(newZgrid);
        planC{indexS.dose}(newDoseNum).horizontalGridInterval = newXgrid(2)-newXgrid(1);
        planC{indexS.dose}(newDoseNum).verticalGridInterval = newYgrid(2)-newYgrid(1);
        planC{indexS.dose}(newDoseNum).depthGridInterval = newZgrid(2)-newZgrid(1);
        planC{indexS.dose}(newDoseNum).coord1OFFirstPoint = newXgrid(1);
        planC{indexS.dose}(newDoseNum).coord2OFFirstPoint = newYgrid(1);
        planC{indexS.dose}(newDoseNum).coord3OfFirstPoint = newZgrid(1);
        planC{indexS.dose}(newDoseNum).zValues = newZgrid;
        planC{indexS.dose}(newDoseNum).doseUnits = doseUnits;

        %switch to new dose, with a short pause to let the dialogue clear.
        pause(.1);
        sliceCallBack('selectDose', num2str(newDoseNum));
        
        nDoses = length(planC{indexS.dose});
        ud.checkedDoses = zeros(nDoses, 1);        
        
        %Refresh this GUI to include new dose distribution
        if nDoses > 16
            ud.df.range = (nDoses-16+1):nDoses;
        end

        %Update slider
        nvDoses = length(ud.df.range);
        set(ud.df.handles.scroll, 'min', 0, 'max', nDoses-nvDoses, 'value', nDoses-nvDoses+1-min(ud.df.range), 'enable', 'on', 'sliderstep', [1/(nDoses-nvDoses), nvDoses/(nDoses-nvDoses)]);

        set(hFig, 'userdata', ud);
        doseSummationMenu('refresh')        

        %% APA code ends
        
        
    case 'CANCEL'
        hFig = findobj('tag', 'CERRDoseSummationFigure');
        delete(hFig);
end
