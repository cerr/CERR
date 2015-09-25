function CERRGammafnc(gamaCommand, varargin)
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

gammaGUIFig = findobj('tag','CERRgammaInputGUI');

switch upper(gamaCommand)
    case 'INIT2D'

        if ~isempty(gammaGUIFig)
            return;
        end
        
        stateS.gamma.view = [];
        
        for i = 1:length(planC{indexS.dose})
            doseFraction{i} = planC{indexS.dose}(i).fractionGroupID;
        end
        
        ScreenSize = get(0,'ScreenSize');

        try
            delete(findobj('tag','CERRgammaInputGUI'));
        end

        % Get User Input for 2D dose difference and DTA
        gammaGUIFig = figure('numbertitle','off','name','2-D Gamma Calculation','tag','CERRgammaInputGUI','position',...
            [ScreenSize(3)/2 ScreenSize(4)/2 300 250],'MenuBar','none','Resize','off','CloseRequestFcn','CERRGammafnc(''GAMMACANCLE'')');

        bgColor = get(gammaGUIFig,'color');

        % Text dose difference
        uicontrol('parent',gammaGUIFig,'style','text','backgroundcolor',bgColor,'position',[10 220 100 20],'String', 'Dose Difference (%)');

        % Input dose difference
        uicontrol('parent',gammaGUIFig,'style','Edit','backgroundcolor',[1 1 1],'position',[10 200 90 20],'String', '','tag','InputDoseDiff' );

        % Text DTA
        uicontrol('parent',gammaGUIFig,'style','text','backgroundcolor',bgColor,'position',[160 220 100 20],'String', 'DTA (mm)');

        % Input DTA
        uicontrol('parent',gammaGUIFig,'style','Edit','backgroundcolor',[1 1 1],'position',[160 200 90 20],'String', '','tag','InputDTA');

        % Radio Buttton Type area select
        h = uibuttongroup('parent',gammaGUIFig,'units', 'pixels', 'Position',[5 150 292 40],'Tag','CERRgammaViewRadio');
        uicontrol('Style','Radio','String','Transverse','pos',[5 5 90 30],'parent',h);
        uicontrol('Style','Radio','String','Coronal','pos',[120 5 60 30],'parent',h);
        uicontrol('Style','Radio','String','Sagittal','pos',[220 5 60 30],'parent',h);


        set(h,'SelectionChangeFcn',@chgViewGammaSelectRadio);
        set(h,'SelectedObject',[]);  % No selection

        %Text Base Dose
        uicontrol('parent',gammaGUIFig,'style','text','backgroundcolor',bgColor,'position',[10 120 80 20],'String', 'Reference Dose');
        uicontrol('Style', 'popup','String', doseFraction,'Position', [8 75 290 50],'tag','baseDoseGamma','backgroundcolor', [1 1 1]);

        % Text Ref Dose
        uicontrol('parent',gammaGUIFig,'style','text','backgroundcolor',bgColor,'position',[10 70 80 20],'String', 'Evaluation Dose');
        uicontrol('Style', 'popup','String', doseFraction','Position', [8 25 290 50], 'tag','refDoseGamma','backgroundcolor',[1 1 1]);


        % Button GO
        uicontrol('parent',gammaGUIFig,'style','pushbutton','position',[50 10 60 20],'String', 'Calculate','Callback', ['CERRGammafnc(''CALCGAMMA2D'')' ] );

        % Button Cancel
        uicontrol('parent',gammaGUIFig,'style','pushbutton','position',[180 10 60 20],'String', 'Cancel','Callback', 'CERRGammafnc(''GAMMACANCLE'')');

    case 'INIT3D'
        
        if ~isempty(gammaGUIFig)
            return;
        end
       
        for i = 1:length(planC{indexS.dose})
            doseFraction{i} = planC{indexS.dose}(i).fractionGroupID;
        end
        
        ScreenSize = get(0,'ScreenSize');

        try
            delete(findobj('tag','CERRgammaInputGUI'));
        end

        % Get User Input for 2D dose difference and DTA
        gammaGUIFig = figure('numbertitle','off','name','3-D Gamma Calculation','tag','CERRgammaInputGUI','position',...
            [ScreenSize(3)/2 ScreenSize(4)/2 300 300],'MenuBar','none','Resize','off','CloseRequestFcn','CERRGammafnc(''GAMMACANCLE'')');

        bgColor = get(gammaGUIFig,'color');

        % Text dose difference
        uicontrol('parent',gammaGUIFig,'style','text','backgroundcolor',bgColor,'position',[10 260 140 30],'String', 'Dose Difference (% of max ref dose)');
        % Input dose difference
        uicontrol('parent',gammaGUIFig,'style','Edit','backgroundcolor',[1 1 1],'position',[20 240 90 20],'String', '3','tag','InputDoseDiff' );

        % Text DTA
        uicontrol('parent',gammaGUIFig,'style','text','backgroundcolor',bgColor,'position',[160 260 140 30],'String', 'DTA (mm)');
        % Input DTA
        uicontrol('parent',gammaGUIFig,'style','Edit','backgroundcolor',[1 1 1],'position',[170 240 90 20],'String', '3','tag','InputDTA');

        %Text Base Dose
        uicontrol('parent',gammaGUIFig,'style','text','backgroundcolor',bgColor,'position',[10 200 80 20],'String', 'Reference Dose');
        uicontrol('Style', 'popup','String', doseFraction,'Position', [8 155 290 50],'tag','baseDoseGamma','backgroundcolor', [1 1 1]);

        % Text Ref Dose
        uicontrol('parent',gammaGUIFig,'style','text','backgroundcolor',bgColor,'position',[10 155 80 20],'String', 'Evaluation Dose');
        uicontrol('Style', 'popup','String', doseFraction','Position', [8 110 290 50], 'tag','refDoseGamma','backgroundcolor',[1 1 1]);
        
        % Text Threshold
        uicontrol('parent',gammaGUIFig,'style','text','backgroundcolor',bgColor,'position',[10 90 140 30],'String', 'Threshold low dose (% max ref dose)');
        % Input Threshold
        uicontrol('parent',gammaGUIFig,'style','Edit','backgroundcolor',[1 1 1],'position',[160 100 50 20],'String', '5','tag','InputThreshold');

        % Button GO
        uicontrol('parent',gammaGUIFig,'style','pushbutton','position',[50 55 70 20],'String', 'Calculate','Callback', ['CERRGammafnc(''CALCGAMMA3D'')' ] );

        % Button Cancel
        uicontrol('parent',gammaGUIFig,'style','pushbutton','position',[180 55 70 20],'String', 'Cancel','Callback', 'CERRGammafnc(''GAMMACANCLE'')');

        % Waitbar
        axes('units','pixels','Position', [8 15 280 15], 'ytick',[],'xtick',[], 'box', 'on', 'parent', gammaGUIFig, 'color', bgColor);
        uicontrol(gammaGUIFig, 'style', 'text', 'units', 'pixels', 'position', [8 35 40 12], 'string', 'Status', 'fontweight', 'bold');
        %Waitbar axis, part of wb.
        ud.wb.wbAxis = axes('units', 'pixels', 'Position', [8 15 280 15], 'color', [.9 .9 .9], 'ytick',[],'xtick',[], 'box', 'on', 'xlimmode', 'manual', 'ylimmode', 'manual', 'parent', gammaGUIFig);
        ud.wb.patch = patch([0 0 0 0], [0 1 1 0], 'red', 'parent', ud.wb.wbAxis);
        %ud.wb.handles.percent = text(.5, .45, '', 'parent', ud.wb.handles.wbAxis, 'horizontalAlignment', 'center');
        %ud.wb.handles.text = uicontrol(h, 'style', 'text', 'units', units, 'position', [wbX+50 wbY+wbH - 21 wbW-100 15], 'string', '');

        set(gammaGUIFig,'userdata',ud)
        
        
    case 'CALCGAMMA3D'
        
        % Get Inputs and QA

        baseDose = get(findobj('tag','baseDoseGamma'),'value');

        refDose = get(findobj('tag','refDoseGamma'),'value');

        if baseDose == refDose
            warndlg('Select different reference and evaluation dose')
            return
        end

        doseDiffIN = str2num(get(findobj('tag','InputDoseDiff'),'string'));

        if isempty(doseDiffIN)
            warndlg('Please Enter Dose Difference');
            return;
        else
            doseDiff = doseDiffIN/100;
            if doseDiff > 1 || doseDiff < 0
                warndlg('Dose Difference Value not Correct');
                return;
            end
        end

        DTA = str2num(get(findobj('tag','InputDTA'),'string'))/10;
        if isempty(DTA)
            warndlg('Please Enter Distance to Agreement (DTA)');
        end
        
        
        threshold = str2num(get(findobj('tag','InputThreshold'),'string'));
        if isempty(DTA)
            warndlg('Please Enter Threshold. Gamma is calculated for all voxels in reference dose that are above this threshold.');
        end
        
        
        % Check whether base and ref dose are on same grid
%         [xValsBase, yValsBase, zValsBase] = getDoseXYZVals(planC{indexS.dose}(baseDose));        
%         [xValsRef, yValsRef, zValsRef] = getDoseXYZVals(planC{indexS.dose}(refDose)); 
        
%         if length(xValsBase)==length(xValsRef) && length(yValsBase)==length(yValsRef) && length(zValsBase)==length(zValsRef)
%             xDiff = sum((xValsBase-xValsRef).^2);
%             yDiff = sum((yValsBase-yValsRef).^2);
%             zDiff = sum((zValsBase-zValsRef).^2);
%             if max([xDiff yDiff zDiff]) > 1e-3
%                 warndlg('Base and Reference dose grids do not match');
%                 return
%             end
%         else
%             warndlg('Base and Reference dose grids do not match');
%             return;
%         end
            
        createGammaDose(baseDose,refDose,doseDiffIN,DTA,threshold);
        
        CERRGammafnc('DISPCERRGAMMA', length(planC{indexS.dose}));
        
        
    case 'CALCGAMMA2D'

        if isempty(stateS.gamma.view)
            warndlg('Please select View on Gamma GUI');
            return;
        end

        baseDose = get(findobj('tag','baseDoseGamma'),'value');

        refDose = get(findobj('tag','refDoseGamma'),'value');

        if baseDose == refDose
            warndlg('Select different reference and evaluation dose')
            return
        end

        doseDiffIN = str2num(get(findobj('tag','InputDoseDiff'),'string'));

        if isempty(doseDiffIN)
            warndlg('Please Enter Dose Difference');
            return;
        else
            doseDiff = doseDiffIN/100;
            if doseDiff > 1 | doseDiff < 0
                warndlg('Dose Difference Value not Correct');
                return;
            end
        end

        DTA = str2num(get(findobj('tag','InputDTA'),'string'))/10;

        axisInfo = getAxisInfo(stateS.gamma.axis);

        coord = axisInfo.doseObj.coord;

        switch upper(stateS.gamma.view)
            case 'TRANSVERSE'
                dim = 3;
            case 'CORONAL'
                dim = 2;

            case 'SAGITTAL'
                dim = 1;
        end

        [imB, imageXValsB, imageYValsB] = calcDoseSlice(baseDose, coord, dim, planC);

        [imR, imageXValsR, imageYValsR] = calcDoseSlice(refDose, coord, dim, planC);
        
        signX = sign(imageXValsR(2) - imageXValsR(1));
        signY = sign(imageYValsR(2) - imageYValsR(1));
        imageXValsR(1) = imageXValsR(1) - signX*1e-5;
        imageXValsR(end) = imageXValsR(end) + signX*1e-5;
        imageYValsR(1) = imageYValsR(1) - signY*1e-5;
        imageYValsR(end) = imageYValsR(end) + signY*1e-5;
        
        imageXValsR = imageXValsR(:)'; 
        imageYValsR = imageYValsR(:)';
        imageXValsB = imageXValsB(:)';
        imageYValsB = imageYValsB(:)';

        imR = finterp2(imageXValsR, imageYValsR, imR ,imageXValsB, imageYValsB, 1, 0);

        if max(imR(:))== 0
            warndlg('The scan sets are probably not registered; maximum dose is 0');
        end
        % Normalize the dose slice before sending it in.

        maxDIn = max(imB(:));

        imB = imB/maxDIn; imB(imB<0)=0;

        imR = imR/maxDIn; imR(imR<0)=0;       

        CERRGammafnc('GAMMACANCLE');

        hwBar = waitbar(0,'Calculating Gamma 2D ...');

        tic; gamma = 2 * meshgamma2d(imB ,imR,doseDiff,DTA); toc;

        delete(hwBar);

        stateS.gamma.DTA = DTA;
        stateS.gamma.doseDiff = doseDiffIN;
        stateS.gamma.refDoseScale = maxDIn;
        stateS.gamma.gamma2D = gamma;

        CERRGammafnc('DISPCERRGAMMA');

    case 'DISPCERRGAMMA'
        gammaFig = findobj('Name','Gamma Stats');
        if isempty(gammaFig)
            doseNum = varargin{1};
            structNum = 1;
            gammaFig = figure('Name','Gamma Stats','NumberTitle','off','position',[10 , 10 , 300 , 400],...
                'menubar','none','resize','off','tag','gamma2dfig');
            uicontrol(gammaFig,'Style','text','position',[40, 350, 70, 30],'String',...
                'Select Dose','fontsize',10)
            uicontrol(gammaFig,'tag','DoseForGamma','Style','popup','position',[120, 350, 100, 30],'String',...
                {planC{indexS.dose}.fractionGroupID},'fontsize',10,'callback','CERRGammafnc(''DISPCERRGAMMA'');','value',doseNum)
            
            uicontrol(gammaFig,'Style','text','position',[40, 300, 70, 30],'String',...
                'Select Structure','fontsize',10)
            uicontrol(gammaFig,'tag','StructForGamma','Style','popup','position',[120, 300, 100, 30],'String',...
                {planC{indexS.structures}.structureName},'fontsize',10,'callback','CERRGammafnc(''DISPCERRGAMMA'');', 'value',structNum)
            pieAxis = axes('parent',gammaFig,'tag','GammaPiChartAxis','units', 'pixels','position',[75 ,100 , 180 , 180],'color', [0.5 0.5 0.5], 'xTickLabel', [],...
                'yTickLabel', [],'xTick', [],'yTick', [],'nextPlot','add');

        elseif ~isempty(gcbo) && isequal(get(gcbo,'tag'),'StructForGamma')
            structNum = get(gcbo,'value');
            hDose = findobj('tag','DoseForGamma');
            doseNum = get(hDose,'value');
        elseif ~isempty(gcbo) && isequal(get(gcbo,'tag'),'DoseForGamma')
            doseNum = get(gcbo,'value');
            hStruct = findobj('tag','StructForGamma');
            structNum = get(hStruct,'value');
        else % stats GUI already open
            doseNum = varargin{1};
            structNum = 1;
        end
        
        % Get dose at these structure voxels
        scanNum = getStructureAssociatedScan(structNum, planC);
        [rasterSegments, planC, isError] = getRasterSegments(structNum, planC);
        [mask3M, uniqueSlices] = rasterToMask(rasterSegments,scanNum,planC);
        [i,j,k] = find3d(mask3M);
        if ~isempty(i) % i.e. structure is included within the dose distribution
            [xValsScan, yValsScan, zValsScan] = getScanXYZVals(planC{indexS.scan}(scanNum));
            structXvals = xValsScan(j);
            structYvals = yValsScan(i);
            structZvals = zValsScan(uniqueSlices(k));
            % Getting Dose at structure x,y,z
            dosesV = getDoseAt(doseNum, structXvals, structYvals, structZvals, planC);
            
            % Filter points that do not have gamma calculated
            dosesV = dosesV(~isnan(dosesV));
            
            % Display gamma result with Pie graph
            passPer = sum(dosesV<=1.0001);
            
            failPer = numel(dosesV)-passPer;
            
            pieAxis = findobj('tag','GammaPiChartAxis');
            x = [passPer failPer];
            
            explode = [0 1];
            
            tot = passPer + failPer;
            
            passPer = Roundoff((passPer/tot)*100,2);
            
            failPer = Roundoff((failPer/tot)*100,2);
            
            hChild = get(pieAxis,'children');
            delete(hChild)
            hPie = pie(pieAxis,x,explode,{['Pass = ' num2str(passPer) '%'],['Fail = ' num2str(failPer) '%']});
            set(hPie(2:2:end),'color','y','fontWeight','bold','fontSize',12)
            colormap(jet);
            
        end
        


    case 'GAMMACANCLE'
        delete(findobj('tag','CERRgammaInputGUI'));
end