function cervixPETHelperGUI(command,varargin)
%function cervixPETHelperGUI(command,varargin)
%
%Helper Interface for Cervix PET-CT
%
%APA, 10/22/2008

try
    global planC funStateS
    indexS = planC{end};
end

if nargin==0
    command = 'INIT';
end

switch upper(command)

    case 'INIT'

        % define margin constraints
        leftMarginWidth = 300;
        topMarginHeight = 50;
        funStateS.leftMarginWidth = leftMarginWidth;
        funStateS.topMarginHeight = topMarginHeight;

        str1 = 'Cervix PET-CT Helper';
        position = [5 40 700 550];


        if isempty(findobj('tag','cervixHelpMainFig'))
            % initialize main GUI figure
            hMain = figure('tag','cervixHelpMainFig','name',str1,'numbertitle','off','position',position,...
                'CloseRequestFcn', 'cervixPETHelperGUI(''closeRequest'')','menubar','none','resize','on','color',[0.8 0.8 0.8]);
        else
            figure(findobj('tag','cervixHelpMainFig'))
            return
        end

        funStateS = [];
        funStateS.hMain = hMain;

        figureWidth = position(3); figureHeight = position(4);

        % create title handles
        handle(1) = uicontrol(hMain,'tag','titleFrame','units','pixels','Position',[80 figureHeight-topMarginHeight+5 500 40 ],'Style','frame','backgroundColor',[0.8 0.8 0.8]);
        handle(2) = uicontrol(hMain,'tag','title','units','pixels','Position',[81 figureHeight-topMarginHeight+10 498 30 ], 'String','Cervix PET-CT Helper','Style','text', 'fontSize',10,'FontWeight','Bold','HorizontalAlignment','center','backgroundColor',[0.8 0.8 0.8]);
        handle(3) = uicontrol(hMain,'tag','titleFrame','units','pixels','Position',[leftMarginWidth-1 60 1 figureHeight-topMarginHeight-70 ],'Style','frame','backgroundColor',[0.8 0.8 0.8]);

        %% put copyright information
        hcopyrightAxis  = axes('parent',hMain,'units', 'pixels', 'position', [450 5 230 30]);
        text(0,0.7,'\copyright 2008  I. El Naqa, A.P. Apte, J.O. Deasy, WUSM','parent',hcopyrightAxis,'fontSize',8);
        axis(hcopyrightAxis, 'off')

        posTop = figureHeight-topMarginHeight;

        % create input handles
        inputH(1) = uicontrol(hMain,'tag','registrationTitle','units','pixels','Position',[20 posTop-40 200 20], 'String','IMAGE REGISTRATION','Style','text', 'fontSize',9.5,'FontWeight','Bold','BackgroundColor',[0.8 0.8 0.8],'HorizontalAlignment','left');
        str = 'Register CT-baseline, CT-A, CT-B, CT-C Images using CERR (Scan -> Image Fusion). "Finalize Registration" applies transformations to PET images.';
        uicontrol(hMain,'units','pixels','Position',[20 posTop-80 250 40], 'String',str,'Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',[0.8 0.8 0.8],'HorizontalAlignment','left');
        inputH(2) = uicontrol(hMain,'tag','registrationPush','units','pixels','Position',[20 posTop-105 200 20], 'String','Finalize Registration','Style','push', 'fontSize',9,'FontWeight','normal','BackgroundColor',[1 1 1],'HorizontalAlignment','left','callBack','cervixPETHelperGUI(''SHOWMESSAGE'')');

        inputH(3) = uicontrol(hMain,'tag','contourTitle','units','pixels','Position',[20 posTop-150 200 20], 'String','AUTO IMAGE SEGMENTATION','Style','text', 'fontSize',9.5,'FontWeight','Bold','BackgroundColor',[0.8 0.8 0.8],'HorizontalAlignment','left');
        str = 'Contour ROI on baseline-PET using CERR (Structures -> Contouring). Pushing button below creates 40% tumor segmentation on all PET images.';
        uicontrol(hMain,'units','pixels','Position',[20 posTop-190 250 40], 'String',str,'Style','text', 'fontSize',8,'FontWeight','normal','BackgroundColor',[0.8 0.8 0.8],'HorizontalAlignment','left');
        inputH(4) = uicontrol(hMain,'tag','contourPush','units','pixels','Position',[20 posTop-215 200 20], 'String','Propogate ROI and Auto Segment','Style','push', 'fontSize',9,'FontWeight','normal','BackgroundColor',[1 1 1],'HorizontalAlignment','left','callBack','cervixPETHelperGUI(''SHOWMESSAGE'')');

        inputH(5) = uicontrol(hMain,'tag','heteroMetricsTitle','units','pixels','Position',[20 posTop-260 200 20], 'String','HETEROGENITY METRICS','Style','text', 'fontSize',9.5,'FontWeight','Bold','BackgroundColor',[0.8 0.8 0.8],'HorizontalAlignment','left');
        inputH(6) = uicontrol(hMain,'tag','heteroMetricsPush','units','pixels','Position',[20 posTop-280 200 20], 'String','Export Metrics','Style','push', 'fontSize',9,'FontWeight','normal','BackgroundColor',[1 1 1],'HorizontalAlignment','left','callBack','cervixPETHelperGUI(''SHOWMESSAGE'')');

        % create Message-display handle
        inputH(5) = uicontrol(hMain,'tag','messageTxt','units','pixels','Position',[leftMarginWidth+40 posTop*3/4-300 figureWidth-leftMarginWidth-80 posTop*0.8/4+300], 'String','','Style','text', 'fontSize',9.5,'FontWeight','Normal','BackgroundColor',[0.8 0.8 0.8],'HorizontalAlignment','left');

        funStateS.handle.inputH = inputH;


    case 'SHOWMESSAGE'

        indBase_ct  = 1;
        indBase_pet = 2;
        indA_ct     = 3;
        indA_pet    = 4;
        indB_ct     = 5;
        indB_pet    = 6;
        indC_ct     = 7;
        indC_pet    = 8;
        pushedTag = get(gcbo,'tag');
        if strcmpi(pushedTag,'registrationPush')
            planC{indexS.scan}(indA_pet).transM = planC{indexS.scan}(indA_ct).transM;
            planC{indexS.scan}(indB_pet).transMCur = planC{indexS.scan}(indB_ct).transM;           
            %Apply transM to PET A and B images
            str{1} = 'DONE FINALIZING REGISTRATION';
            str{2} = '';
            str{3} = ['Transformation matrices for scan#',num2str(indA_pet),' (',planC{indexS.scan}(indA_pet).scanType,') and scan#',num2str(indB_pet),' (',planC{indexS.scan}(indB_pet).scanType,') have been updated. Please draw ROI on scan#',num2str(indBase_pet),' (',planC{indexS.scan}(indBase_pet).scanType,') and proceed to auto segmentation.'];
        elseif strcmpi(pushedTag,'contourPush')
            %Get structures with name equal to roi
            structNum = find(strcmpi('roi',{planC{indexS.structures}.structureName}));
            assocScansV = getStructureAssociatedScan(structNum);
            if ~ismember(indBase_pet,assocScansV) 
                errordlg('ROI contour required on base PET scan','ROI on base PET','modal')
                return;
            end
            indBase = find(assocScansV==indBase_pet);
            structNum = structNum(indBase);            
            %Generate 40% contour on baseline PET
            contourSUV(structNum,40)
            planC{indexS.structures}(end).structureName = '40% PET Baseline';
            %copy ROI to PET A
            planC = copyStrToScan_meshBased(structNum,indA_pet,planC);
            %Generate 40% contour on PET A
            contourSUV(length(planC{indexS.structures}),40)
            runCERRCommand(['del structure ',num2str(length(planC{indexS.structures})-1)]);
            planC{indexS.structures}(end).structureName = '40% PET A';
            %copy ROI to PET B
            planC = copyStrToScan_meshBased(structNum,indB_pet,planC);
            %Generate 40% contour on PET B
            contourSUV(length(planC{indexS.structures}),40)
            runCERRCommand(['del structure ',num2str(length(planC{indexS.structures})-1)]);
            planC{indexS.structures}(end).structureName = '40% PET B';
            %copy ROI to PET C
            planC = copyStrToScan_meshBased(structNum,indC_pet,planC);
            %Generate 40% contour on PET C
            contourSUV(length(planC{indexS.structures}),40)
            runCERRCommand(['del structure ',num2str(length(planC{indexS.structures})-1)]);
            planC{indexS.structures}(end).structureName = '40% PET C';
            str{1} = 'DONE CONTOURING';            
        elseif strcmpi(pushedTag,'heteroMetricsPush')
            clc
            structNum = getStructNum('40% PET Baseline',planC,planC{end});
            disp('Heterogenity Metrics for Baseline PET')
            [energy_40base,contrast_40base,Entropy_40base,Homogeneity_40base,standard_dev_40base,Ph_40base,slope_base] = getHaralicParams(structNum);            
            [jnk,jnk,raw] = xlsread('Cervix_PET_data.xls');
            rowIndex = size(raw,1)+1;
            dataM = [slope_base,energy_40base,contrast_40base,Entropy_40base,Homogeneity_40base,standard_dev_40base];
            PtName = planC{indexS.scan}(1).scanInfo(1).patientName;
            [SUCCESS,MESSAGE] = xlswrite('Cervix_PET_data.xls',{PtName},['A',num2str(rowIndex),':A',num2str(rowIndex)]);
            if ~SUCCESS
                errordlg(MESSAGE.message,'Error Writing to Excel','modal')
                return
            end
            [SUCCESS,MESSAGE] = xlswrite('Cervix_PET_data.xls',{datestr(now)},['B',num2str(rowIndex),':B',num2str(rowIndex)]);
            if ~SUCCESS
                errordlg(MESSAGE.message,'Error Writing to Excel','modal')
                return
            end
            acquisitionDate = datestr(datenum(num2str(planC{indexS.scan}(indBase_pet).scanInfo(1).DICOMHeaders.AcquisitionDate),'yyyymmdd'));
            [SUCCESS,MESSAGE] = xlswrite('Cervix_PET_data.xls',{acquisitionDate},['D',num2str(rowIndex),':D',num2str(rowIndex)]);
            if ~SUCCESS
                errordlg(MESSAGE.message,'Error Writing to Excel','modal')
                return
            end
            [SUCCESS,MESSAGE] = xlswrite('Cervix_PET_data.xls',dataM,['E',num2str(rowIndex),':J',num2str(rowIndex)]);
            if ~SUCCESS
                errordlg(MESSAGE.message,'Error Writing to Excel','modal')
                return
            end
            structNum = getStructNum('40% PET A',planC,planC{end});            
            disp('Heterogenity Metrics for PET A')
            acquisitionDate = datestr(datenum(num2str(planC{indexS.scan}(indA_pet).scanInfo(1).DICOMHeaders.AcquisitionDate),'yyyymmdd'));
            [SUCCESS,MESSAGE] = xlswrite('Cervix_PET_data.xls',{acquisitionDate},['L',num2str(rowIndex),':L',num2str(rowIndex)]);
            if ~SUCCESS
                errordlg(MESSAGE.message,'Error Writing to Excel','modal')
                return
            end
            [energy_40A,contrast_40A,Entropy_40A,Homogeneity_40A,standard_dev_40A,Ph_40A,slope_A] = getHaralicParams(structNum);            
            dataM = [slope_A,energy_40A,contrast_40A,Entropy_40A,Homogeneity_40A,standard_dev_40A];
            [SUCCESS,MESSAGE] = xlswrite('Cervix_PET_data.xls',dataM,['M',num2str(rowIndex),':R',num2str(rowIndex)]);
            if ~SUCCESS
                errordlg(MESSAGE.message,'Error Writing to Excel','modal')
                return
            end
            structNum = getStructNum('40% PET B',planC,planC{end});
            disp('Heterogenity Metrics for PET B')
            acquisitionDate = datestr(datenum(num2str(planC{indexS.scan}(indB_pet).scanInfo(1).DICOMHeaders.AcquisitionDate),'yyyymmdd'));
            [SUCCESS,MESSAGE] = xlswrite('Cervix_PET_data.xls',{acquisitionDate},['T',num2str(rowIndex),':T',num2str(rowIndex)]);
            if ~SUCCESS
                errordlg(MESSAGE.message,'Error Writing to Excel','modal')
                return
            end
            [energy_40B,contrast_40B,Entropy_40B,Homogeneity_40B,standard_dev_40B,Ph_40B,slope_B] = getHaralicParams(structNum);
            dataM = [slope_B,energy_40B,contrast_40B,Entropy_40B,Homogeneity_40B,standard_dev_40B];
            [SUCCESS,MESSAGE] = xlswrite('Cervix_PET_data.xls',dataM,['U',num2str(rowIndex),':Z',num2str(rowIndex)]);
            if ~SUCCESS
                errordlg(MESSAGE.message,'Error Writing to Excel','modal')
                return
            end
            structNum = getStructNum('40% PET B',planC,planC{end});
            disp('Heterogenity Metrics for PET C')
            acquisitionDate = datestr(datenum(num2str(planC{indexS.scan}(indC_pet).scanInfo(1).DICOMHeaders.AcquisitionDate),'yyyymmdd'));
            [SUCCESS,MESSAGE] = xlswrite('Cervix_PET_data.xls',{acquisitionDate},['AB',num2str(rowIndex),':AB',num2str(rowIndex)]);
            if ~SUCCESS
                errordlg(MESSAGE.message,'Error Writing to Excel','modal')
                return
            end
            [energy_40C,contrast_40C,Entropy_40C,Homogeneity_40C,standard_dev_40C,Ph_40C,slope_C] = getHaralicParams(structNum);
            dataM = [slope_C,energy_40C,contrast_40C,Entropy_40C,Homogeneity_40C,standard_dev_40C];
            [SUCCESS,MESSAGE] = xlswrite('Cervix_PET_data.xls',dataM,['AC',num2str(rowIndex),':AH',num2str(rowIndex)]);
            if ~SUCCESS
                errordlg(MESSAGE.message,'Error Writing to Excel','modal')
                return
            end
            str = 'Exported metrics to Excel file Cervix_PET_data.xls';
        end
        set(funStateS.handle.inputH(5),'string',str)
        
    case 'CLOSEREQUEST'
        closereq

end

end
