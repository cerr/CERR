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

switch upper(gamaCommand)
    case 'INIT2D'

        stateS.gamma.view = [];
        
        for i = 1:length(planC{indexS.dose})
            doseFraction{i} = planC{indexS.dose}(i).fractionGroupID;
        end
        
        ScreenSize = get(0,'ScreenSize');

        try
            delete(findobj('tag','CERRgammaInputGUI'));
        end

        % Get User Input for 2D dose difference and DTA
        mesFig = figure('numbertitle','off','name','2-D Gamma Calculation','tag','CERRgammaInputGUI','position',...
            [ScreenSize(3)/2 ScreenSize(4)/2 300 250],'MenuBar','none','Resize','off','CloseRequestFcn','CERRGammafnc(''GAMMACANCLE'')');

        bgColor = get(mesFig,'color');

        % Text dose difference
        uicontrol('parent',mesFig,'style','text','backgroundcolor',bgColor,'position',[10 220 100 20],'String', 'Dose Difference (%)');

        % Input dose difference
        uicontrol('parent',mesFig,'style','Edit','backgroundcolor',[1 1 1],'position',[10 200 90 20],'String', '','tag','InputDoseDiff' );

        % Text DTA
        uicontrol('parent',mesFig,'style','text','backgroundcolor',bgColor,'position',[160 220 100 20],'String', 'DTA (mm)');

        % Input DTA
        uicontrol('parent',mesFig,'style','Edit','backgroundcolor',[1 1 1],'position',[160 200 90 20],'String', '','tag','InputDTA');

        % Radio Buttton Type area select
        h = uibuttongroup('parent',mesFig,'units', 'pixels', 'Position',[5 150 292 40],'Tag','CERRgammaViewRadio');
        uicontrol('Style','Radio','String','Transverse','pos',[5 5 90 30],'parent',h);
        uicontrol('Style','Radio','String','Coronal','pos',[120 5 60 30],'parent',h);
        uicontrol('Style','Radio','String','Sagittal','pos',[220 5 60 30],'parent',h);


        set(h,'SelectionChangeFcn',@chgViewGammaSelectRadio);
        set(h,'SelectedObject',[]);  % No selection

        %Text Base Dose
        uicontrol('parent',mesFig,'style','text','backgroundcolor',bgColor,'position',[10 120 80 20],'String', 'Base Dose');
        uicontrol('Style', 'popup','String', doseFraction,'Position', [8 75 290 50],'tag','baseDoseGamma','backgroundcolor', [1 1 1]);

        % Text Ref Dose
        uicontrol('parent',mesFig,'style','text','backgroundcolor',bgColor,'position',[10 70 80 20],'String', 'Ref Dose');
        uicontrol('Style', 'popup','String', doseFraction','Position', [8 25 290 50], 'tag','refDoseGamma','backgroundcolor',[1 1 1]);


        % Button GO
        uicontrol('parent',mesFig,'style','pushbutton','position',[50 10 60 20],'String', 'Calculate','Callback', ['CERRGammafnc(''CALCGAMMA2D'')' ] );

        % Button Cancel
        uicontrol('parent',mesFig,'style','pushbutton','position',[180 10 60 20],'String', 'Cancel','Callback', 'CERRGammafnc(''GAMMACANCLE'')');


    case 'CALCGAMMA2D'

        if isempty(stateS.gamma.view)
            warndlg('Please select View on Gamma GUI');
            return;
        end

        baseDose = get(findobj('tag','baseDoseGamma'),'value');

        refDose = get(findobj('tag','refDoseGamma'),'value');

        if baseDose == refDose
            warndlg('Select different base and reference dose')
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
        % Display gamma result with Pie graph
        passPer = length(find(stateS.gamma.gamma2D<1));

        failPer = length(find(stateS.gamma.gamma2D>1));

        gamaFig = figure('Name',[stateS.gamma.view 'Gamma 2D'],'NumberTitle','off','position',[10 , 10 , 1000 , 600],...
            'menubar','none','resize','off','tag','gamma2dfig');

        gammaAxis = axes('parent',gamaFig,'units', 'pixels','position',[10 ,10 , 580 , 580],'color', [0 0 0], 'xTickLabel', [],...
            'yTickLabel', [],'xTick', [],'yTick', []);

        clrBarAxis = axes('parent',gamaFig,'units', 'pixels','position',[595 ,10 , 15 , 550],'color', [0 0 0], 'xTickLabel', [],...
            'yTickLabel', [],'xTick', [],'yTick', []);

        imagesc(stateS.gamma.gamma2D,'parent',gammaAxis), colorbar(clrBarAxis,'peer',gammaAxis);

        stateS.gamma.handle.gammaAxis = gammaAxis;
        
        stateS.gamma.handle.clrBarAxis = clrBarAxis;
        
        set(gammaAxis,'xTickLabel', [],'yTickLabel', [],'xTick', [],'yTick', []);

        pieAxis =  axes('parent',gamaFig,'units', 'pixels','position',[760 ,350 , 180 , 180],'color', [0 0 0], 'xTickLabel', [],...
            'yTickLabel', [],'xTick', [],'yTick', []);

        x = [passPer failPer];

        explode = [0 1];

        tot = passPer + failPer;

        passPer = Roundoff((passPer/tot)*100,2);

        failPer = Roundoff((failPer/tot)*100,2);

        pie(pieAxis,x,explode,{['Pass = ' num2str(passPer) '%'],['Fail = ' num2str(failPer) '%']}),colormap(jet);

        % Check Box for Binary Gamma Vs Color Scaled
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        h = uibuttongroup('parent',gamaFig,'units', 'pixels', 'visible','off','Position',[700, 200, 250, 40],'Tag','gammaViewRadio');
        clrRdH = uicontrol('Style','Radio','String','Color Scale','pos',[5 5 100 30],'parent',h,'HandleVisibility','off');
        uicontrol('Style','Radio','String','Binary','pos',[110 5 100 30],'parent',h,'HandleVisibility','off');

        set(h,'SelectionChangeFcn',@chgCERRGammaClrMapRadio);
        set(h,'SelectedObject',clrRdH);  % No selection
        set(h,'Visible','on');

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        uicontrol(gamaFig,'Style','text','position',[700, 160, 200, 20],'String',...
            ['DTA =' num2str(stateS.gamma.DTA) ' mm'],'fontsize',10)

        uicontrol(gamaFig,'Style','text','position',[700, 130, 200, 20],'String',...
            ['Dose Diff = ' num2str(stateS.gamma.doseDiff) ' %'],'fontsize',10)

        uicontrol(gamaFig,'Style','text','position',[700, 100, 200, 20],'String',...
            ['Max Base Dose = ' num2str(stateS.gamma.refDoseScale) ' GY'],'fontsize',10)

        uicontrol(gamaFig,'Style','text','position',[700, 70, 200, 20],'String',...
            ['Pass = ' num2str(passPer) '%' '    '  'Fail = ' num2str(failPer) '%'],'fontsize',10)

        uicontrol(gamaFig,'Style','text','position',[700, 30, 200, 20],'String','Pass < 1   Fail > 1','fontsize',10)

        uicontrol(gamaFig,'Style','text','position',[780, 5, 150, 10],'String','Gamma above 2 is snapped to 2','fontsize',7,...
            'fontweight','bold','ForegroundColor',[1 0 0])

    case 'GAMMACANCLE'
        delete(findobj('tag','CERRgammaInputGUI'));
end