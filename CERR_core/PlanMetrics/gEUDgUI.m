function gEUDgUI(command)
%function gEUDgUI(command)
%
%GUI to model gUID contributions.
%
%APA, 10/28/2014
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullaticklabelmoder, James Alaly, and Joseph O. Deasy.
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

global planC
indexS = planC{end};

switch upper(command)
    case 'INIT'

        %initialize figure for GUI
        hgEUDgUI = findobj('tag','gEUDgUI');
        delete(hgEUDgUI)
        str1 = 'gEUID contributions modeling';
        position = [200 100 850 450];
        hFig = figure('color',[0.8 0.9 0.9],'name',str1,'tag','gEUDgUI','numbertitle','off','position',position);
        ud.dvhAxis = axes('position',[0.1 0.3 0.5 0.6],'tag','dvhAxis','nextPlot','add','box','off','YAxisLocation','left','color','none');
        ud.gEUDAxis = axes('position',[0.1 0.3 0.5 0.6],'tag','gEUDAxis','nextPlot','add','box','off','YAxisLocation','right','color','none','xTick',[],'xTickLabel',[]);

        figureColor = get(hFig, 'Color');

        %create UIcontrols
        units = 'normalized';
        uicontrol(hFig,'style','text','string','Select Type','units',units,'position',[0.7 0.9 0.15 0.06],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left')
        ud.model = uicontrol(hFig,'style','popup','string',{'Target','Critical Structure'},'units',units,'position',[0.84 0.9 0.15 0.06],'fontWeight','normal','fontSize',10,'callBack','gEUDgUI(''EUD_CHANGED'')');
        uicontrol(hFig,'style','text','string','Select Struct','units',units,'position',[0.7 0.8 0.15 0.06],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left')
        %Build list of structure names.
        numStructs = length(planC{indexS.structures});
        if numStructs > 0
            [structuresC{1:numStructs}] = deal(planC{indexS.structures}.structureName);
        else
            structuresC = {'---'};
        end
        ud.struct = uicontrol(hFig,'style','popup','string',structuresC,'units',units,'position',[0.84 0.8 0.15 0.06],'fontWeight','normal','fontSize',10,'callBack','gEUDgUI(''EUD_CHANGED'')');
        uicontrol(hFig,'style','text','string','Select Dose','units',units,'position',[0.7 0.7 0.15 0.06],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left')
        %Build list of dose names.
        numDoses = length(planC{indexS.dose});
        if numDoses > 0
            [dosesC{1:numDoses}] = deal(planC{indexS.dose}.fractionGroupID);
        else
            dosesC = {'---'};
        end
        ud.dose = uicontrol(hFig,'style','popup','string',dosesC,'units',units,'position',[0.84 0.7 0.15 0.06],'fontWeight','normal','fontSize',10,'callBack','gEUDgUI(''EUD_CHANGED'')');

        % initialize a parameter
        ud.a = 1;

        % a parameter
        uicontrol(hFig,'style','text','string','Select Exponent','units',units,'position',[0.7 0.58 0.15 0.08],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left')
        ud.aSlider = uicontrol(hFig,'style','slider','min',-60, 'max', 60, 'SliderStep',[10/120 20/120], 'value', ud.a, 'units',units,'position',[0.85 0.56 0.1 0.04],'fontWeight','normal','fontSize',10,'callBack','gEUDgUI(''SLIDER_CLICKED'')');
        ud.aTxt = uicontrol(hFig,'style','edit','string',ud.a,'units',units,'position',[0.85 0.61 0.1 0.06],'fontWeight','normal','fontSize',12,'BackgroundColor',[1 1 1],'callBack','gEUDgUI(''TEXT_ENTERED'')');
                
        %Information frame
        ud.info.frame = uicontrol(hFig,'style','frame','units',units,'position',[0.1 0.05 0.5 0.12],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'visible','off');
        ud.info.NTCP = uicontrol(hFig,'style','text','string','NTCP = ','units',units,'position',[0.11 0.12 0.48 0.04],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'visible','off');
        ud.info.EUD = uicontrol(hFig,'style','text','string','EUD = ','units',units,'position',[0.11 0.06 0.48 0.04],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'visible','off');

%         %LKB parameter handles
%         ud.params.lkb.n     = [];
%         ud.params.lkb.D50   = [];
%         ud.params.lkb.m     = [];
% 
%         %CV parameter handles
%         ud.params.cv.mu_cr     = [];
%         ud.params.cv.sigma     = [];
%         ud.params.cv.D50       = [];
%         ud.params.cv.gamma50   = [];

        % Plot handles
        ud.gEUDplot = [];
        ud.DVHplot = [];

        ud.modelCurve = [];
        ud.refLines = [];
        ud.maxDose = [];
        ud.eudChanged = 1;

        set(hFig,'userdata',ud)

        gEUDgUI('REFRESH')


    case 'CHANGEMODEL'
        hFig = findobj('tag','gEUDgUI');
        ud = get(hFig,'userdata');
        val = get(ud.model,'value');
%         if val~=1
%             msgbox('Currently, interactive modeling for models other than LKB is not available','Work in Progress','modal')
%             set(ud.model,'value',1)
%             return;
%         end

    case 'EUD_CHANGED'
%         modelIndex = get(gcbo,'value');
%         if modelIndex == 3 % WUSTL LUNG model
%             X1 = [0 32];
%             X2 = [1 0];
%             b = [0.1134   -2.8147   -1.4954];
%             varName1 = 'MeanDose Lung';
%             varName2 = 'COMSI';
%             radModelType = 'NTCP';
%             plotNomogram('init',X1,X2,b,varName1,varName2,radModelType)
%         end

        hFig = findobj('tag','gEUDgUI');
        ud = get(hFig,'userdata');
        ud.eudChanged = 1;
        set(hFig,'userdata',ud)
        gEUDgUI('REFRESH')
        
        
    case 'SLIDER_CLICKED'
        hFig = findobj('tag','gEUDgUI');
        ud = get(hFig,'userdata');
        a = get(gcbo,'value');
        a = double(int32(a*10))/10;
        %a = str2double(sprintf('%.1f',a));
        ud.a = a;
        set(ud.aTxt,'string',a)        
        set(hFig,'userdata',ud)
        gEUDgUI('REFRESH')
        
    case 'TEXT_ENTERED'
        hFig = findobj('tag','gEUDgUI');
        ud = get(hFig,'userdata');
        a = get(gcbo,'string');
        ud.a = str2num(a);
        set(ud.aSlider,'value',ud.a)
        set(hFig,'userdata',ud)
        gEUDgUI('REFRESH')
        
    case 'REFRESH'

        hFig = findobj('tag','gEUDgUI');
        figureColor = get(hFig, 'Color');

        ud = get(hFig,'userdata');

        %delete old model curve
        delete(ud.modelCurve)
        ud.modelCurve = [];
        delete(ud.refLines)
        ud.refLines = [];

        %get structNum and doseNum if defined
        structNum = get(ud.struct,'value');
        structStr = get(ud.struct,'string');
        doseNum = get(ud.dose,'value');
        doseStr = get(ud.dose,'string');
        if strcmpi(structStr{structNum},'---') || strcmpi(doseStr{doseNum},'---')
            structNum = [];
            doseNum = [];
        end        
        
        % Calculate DVH
        numBins = 800;
        [planC, doseBinsV, volsHistV] = getDVHMatrix(planC, structNum, doseNum,numBins);
        cumVolsV = cumsum(volsHistV);
        cumVols2V  = cumVolsV(end) - cumVolsV;
        
        doseStart = minDose(planC,structNum,doseNum,'Absolute');
        indStart = min(find(doseBinsV >= doseStart));
        
        % Preparation for plotting
        %dvhAxisChildren = get(ud.dvhAxis,'children');
        %delete(dvhAxisChildren)
        %ud.DVHplot = plot(ud.dvhAxis,[doseBinsV(indStart:end)], [cumVols2V(indStart:end)/cumVolsV(end)],'k','linewidth',2);
        if isempty(ud.gEUDplot)
            ud.DVHplot = plot(ud.dvhAxis,[doseBinsV(indStart:end)], [cumVols2V(indStart:end)/cumVolsV(end)],'color',[0.5 0.5 0.5],'linewidth',2);
            xlabel(ud.dvhAxis,'Dose (Gy)','fontsize',14)
            ylabel(ud.dvhAxis,'Fraction volume','fontsize',14)
        else
            set(ud.DVHplot,'XData',[doseBinsV(indStart:end)], 'YData', [cumVols2V(indStart:end)/cumVolsV(end)]);            
        end
        
        ntcpModelStr = get(ud.model,'String');
        ntcpModelNum = get(ud.model,'Value');
        ntcpModel = ntcpModelStr{ntcpModelNum};
        switch upper(ntcpModel)
            case 'TARGET'
                
                a = ud.a;
                
                %[dosesV, volsV, isError] = getDVH(structNum, doseNum, planC);
                %mD = median(dosesV);
                %mD = 0;
                %count = 1;
                
                %eudV = [];
                %eudAllBins = calc_EUD(doseBinsV, volsHistV, a);
                eudV = [];
                %totalVolume = sum(volsHistV);
                for i = indStart:length(volsHistV)
                    doseBinsTmpV = doseBinsV;                   
                    %doseBinsTmpV(1:i) = mD;
                    doseBinsTmpV(1:i) = doseBinsTmpV(i);
                    eudV = [eudV calc_EUD(doseBinsTmpV, volsHistV, a)];
                    %eudV(i) = sum(doseBinsV(i:end) .^ a .* (volsHistV(i:end) ./ totalVolume))^(1/a);
                end
                
                %relEUDv = eudAllBins - eudV;
                relEUDv =  eudV;
                
                % Plotting
                %gEUDchildren = get(ud.gEUDAxis,'children');
                %delete(gEUDchildren)
                %plot(ax2,doseBinsV(:), [relEUDv(:)],colorsC{count},'linewidth',2);
                if isempty(ud.gEUDplot)
                    ud.gEUDplot = plot(ud.gEUDAxis,doseBinsV(indStart:end), [relEUDv(:)],'r','linewidth',2);
                    ud.gEUDplotPt = plot(ud.gEUDAxis,doseBinsV(end), doseBinsV(end),'r*','MarkerSize',12); 
                    ylabel(ud.gEUDAxis,'Cumulative contribution to gEUD','fontsize',14)
                    grid(ud.gEUDAxis,'on')
                    set(ud.gEUDAxis,'yLim',[relEUDv(1) doseBinsV(end)])
                else
                    set(ud.gEUDAxis,'yLim',[relEUDv(1) doseBinsV(end)])
                    set(ud.gEUDplotPt,'XData',doseBinsV(end),'YData', doseBinsV(end),'Color','m')
                    set(ud.gEUDplot,'XData',doseBinsV(indStart:end),'YData', relEUDv(:),'Color','r')
                end
                yTickV = floor(relEUDv(1)):1:doseBinsV(end);                
                if (doseBinsV(end)-yTickV(end)) > 0.25
                    set(ud.gEUDAxis,'yTickLabel','')
                    yTickyTicV = [yTickV str2double(sprintf('%0.1f',doseBinsV(end)))];
                    set(ud.gEUDAxis,'yTick',yTickyTicV)
                    set(ud.gEUDAxis,'yTickLabel',yTickyTicV)
                end


            case 'CRITICAL STRUCTURE'
                
 
                a = ud.a;
                
                %[dosesV, volsV, isError] = getDVH(structNum, doseNum, planC);
                %mD = median(dosesV);
                mD = 0;
                %count = 1;
                
                %eudV = [];
                eudAllBins = calc_EUD(doseBinsV, volsHistV, a);
                eudV = [];
                %totalVolume = sum(volsHistV);
                for i = indStart:length(volsHistV)
                    doseBinsTmpV = doseBinsV;                   
                    doseBinsTmpV(1:i-1) = mD;
                    %doseBinsTmpV(1:i) = doseBinsTmpV(i);
                    eudV = [eudV calc_EUD(doseBinsTmpV, volsHistV, a)];
                    %eudV(i) = sum(doseBinsV(i:end) .^ a .* (volsHistV(i:end) ./ totalVolume))^(1/a);
                end
                
                relEUDv = eudAllBins - eudV;
                %relEUDv =  eudV;
                
                % Plotting
                %gEUDchildren = get(ud.gEUDAxis,'children');
                %delete(gEUDchildren)
                
                %plot(ax2,doseBinsV(:), [relEUDv(:)],colorsC{count},'linewidth',2);
                %plot(ud.gEUDAxis,doseBinsV(indStart:end), [relEUDv(:)],'g','linewidth',2);
                
                if isempty(ud.gEUDplot)
                    ud.gEUDplot = plot(ud.gEUDAxis,doseBinsV(indStart:end), [relEUDv(:)],'r','linewidth',2); 
                    ud.gEUDplotPt = plot(ud.gEUDAxis,doseBinsV(end), eudAllBins,'r*','MarkerSize',12); 
                    ylabel(ud.gEUDAxis,'Cumulative contribution to gEUD','fontsize',14)                    
                    grid(ud.gEUDAxis,'on')
                    set(ud.gEUDAxis,'yLim',[0 eudAllBins+1])
                else
                    set(ud.gEUDAxis,'yLim',[0 eudAllBins+1])
                    set(ud.gEUDplotPt,'XData',doseBinsV(end),'YData', eudAllBins,'Color','m')
                    set(ud.gEUDplot,'XData',doseBinsV(indStart:end),'YData', relEUDv(:),'Color','m')
                end
                yTickV = 0:10:eudAllBins;
                if (eudAllBins-yTickV(end)) > 0.25
                    set(ud.gEUDAxis,'yTickLabel','')
                    yTickyTicV = [yTickV str2double(sprintf('%0.1f',eudAllBins))];
                    set(ud.gEUDAxis,'yTick',yTickyTicV)
                    set(ud.gEUDAxis,'yTickLabel',yTickyTicV)
                end                                
                
                
                
%                 %turn on CV handles
%                 set([ud.params.cv.mu_cr ud.params.cv.sigma ud.params.cv.D50 ud.params.cv.gamma50],'visible','on')
%                 %turn off LKB handles
%                 set([ud.params.lkb.n ud.params.lkb.D50 ud.params.lkb.m],'visible','off')
%                 mu_cr   = get(ud.params.cv.mu_cr(2),'value');
%                 set(ud.params.cv.mu_cr(3),'string',num2str(mu_cr))
%                 sigma = get(ud.params.cv.sigma(2),'value');
%                 set(ud.params.cv.sigma(3),'string',num2str(sigma))
%                 D50   = get(ud.params.cv.D50(2),'value');
%                 set(ud.params.cv.D50(3),'string',num2str(D50))
%                 gamma50   = get(ud.params.cv.gamma50(2),'value');
%                 set(ud.params.cv.gamma50(3),'string',num2str(gamma50))
%                 mu_dv = linspace(0.001,1,100);
%                 if ~isempty(structNum) && ~isempty(doseNum) && ud.eudChanged
%                     [ud.doseBinsV, ud.volsHistV] = getDVH(structNum, doseNum,planC);
%                     ud.eudChanged = 0;
%                 elseif isempty(structNum) && isempty(doseNum)
%                     ud.doseBinsV = [];
%                 end
%                 if ~isempty(ud.doseBinsV)
%                     ud.mu_d = sum(ud.volsHistV.*drxlr_probit(1.4142*pi*gamma50*log(ud.doseBinsV/D50+eps)))/sum(ud.volsHistV);
%                     ntcp = drxlr_probit((-log(-log(ud.mu_d))+log(-log(mu_cr)))/sigma);
%                     ud.maxDose = max(planC{indexS.dose}(doseNum).doseArray(:));
%                     ud.maxDose = [];
%                 else
%                     ud.maxDose = [];
%                     ud.mu_d = [];
%                 end
%                 ntcpV = drxlr_probit((-log(-log(mu_dv-eps))+log(-log(mu_cr)))/sigma);
%                 ud.modelCurve = plot(mu_dv,ntcpV,'k','linewidth',2,'parent',ud.modelAxis);
%                 xlabel('mu_d','parent',ud.modelAxis)
%                 ylabel('Normal Tissue Complication Probability','parent',ud.modelAxis)
%                 if ~isempty(ud.mu_d)
%                     ud.refLines = plot([ud.mu_d ud.mu_d],[0 ntcp],'b--','parent',ud.modelAxis);
%                     ud.refLines = [ud.refLines plot([0 ud.mu_d],[ntcp ntcp],'b--','parent',ud.modelAxis)];
%                     set([ud.info.frame ud.info.NTCP ud.info.EUD],'visible','on')
%                     set(ud.info.NTCP,'string',['NTCP = ',num2str(ntcp)])
%                     set(ud.info.EUD,'string',['Relative Damaged Volume = ',num2str(ud.mu_d)])
%                 else
%                     set([ud.info.frame ud.info.NTCP ud.info.EUD],'visible','off')
%                 end
% 
%                 if ~isempty(ud.maxDose)
%                     set(ud.modelAxis,'xLim',[0 ud.maxDose],'yLim',[0 1])
%                 else
%                     set(ud.modelAxis,'xLim',[0.001,1],'yLim',[0 1])
%                 end

        end

        set(hFig,'userdata',ud)

    case 'LKB_A_CHANGED'
        hFig = findobj('tag','gEUDgUI');
        ud = get(hFig,'userdata');
        a = str2double(get(ud.params.lkb.n(3),'string'));
        if isnumeric(a) && a>=-30 && a<=30
            set(ud.params.lkb.n(2),'value',a)
        else
            set(ud.params.lkb.n(3),'string',num2str(get(ud.params.lkb.n(2),'value')))
        end
        gEUDgUI('EUD_CHANGED')

    case 'LKB_D50_CHANGED'
        hFig = findobj('tag','gEUDgUI');
        ud = get(hFig,'userdata');
        D50 = str2double(get(ud.params.lkb.D50(3),'string'));
        if ~isnan(D50) && D50>=0 && D50<=ud.maxDose
            set(ud.params.lkb.D50(2),'value',D50)
        else
            set(ud.params.lkb.D50(3),'string',num2str(get(ud.params.lkb.D50(2),'value')))
        end
        gEUDgUI('REFRESH')

    case 'LKB_M_CHANGED'
        hFig = findobj('tag','gEUDgUI');
        ud = get(hFig,'userdata');
        m = str2double(get(ud.params.lkb.m(3),'string'));
        if isnumeric(m) && m>=0.001 && m<=3
            set(ud.params.lkb.m(2),'value',m)
        else
            set(ud.params.lkb.m(3),'string',num2str(get(ud.params.lkb.m(2),'value')))
        end
        gEUDgUI('REFRESH')

    case 'CV_MU_CR_CHANGED'
        hFig = findobj('tag','gEUDgUI');
        ud = get(hFig,'userdata');
        mu_cr = str2double(get(ud.params.cv.mu_cr(3),'string'));
        if isnumeric(mu_cr) && mu_cr>=0.001 && mu_cr<=1
            set(ud.params.cv.mu_cr(2),'value',mu_cr)
        else
            set(ud.params.cv.mu_cr(3),'string',num2str(get(ud.params.cv.mu_cr(2),'value')))
        end
        gEUDgUI('REFRESH')

    case 'CV_SIGMA_CHANGED'
        hFig = findobj('tag','gEUDgUI');
        ud = get(hFig,'userdata');
        sigma = str2double(get(ud.params.cv.sigma(3),'string'));
        if isnumeric(sigma) && sigma>=0.0005 && sigma<=2
            set(ud.params.cv.sigma(2),'value',sigma)
        else
            set(ud.params.cv.sigma(3),'string',num2str(get(ud.params.cv.sigma(2),'value')))
        end
        gEUDgUI('REFRESH')

    case 'CV_D50_CHANGED'
        hFig = findobj('tag','gEUDgUI');
        ud = get(hFig,'userdata');
        D50 = str2double(get(ud.params.cv.D50(3),'string'));
        if isnumeric(D50) && D50>=0 && D50<=100
            set(ud.params.cv.D50(2),'value',D50)
        else
            set(ud.params.cv.D50(3),'string',num2str(get(ud.params.cv.D50(2),'value')))
        end
        gEUDgUI('REFRESH')

    case 'CV_GAMMA50_CHANGED'
        hFig = findobj('tag','gEUDgUI');
        ud = get(hFig,'userdata');
        gamma50 = str2double(get(ud.params.cv.gamma50(3),'string'));
        if isnumeric(gamma50) && gamma50>=0.01 && gamma50<=1
            set(ud.params.cv.gamma50(2),'value',gamma50)
        else
            set(ud.params.cv.gamma50(3),'string',num2str(get(ud.params.cv.gamma50(2),'value')))
        end
        gEUDgUI('REFRESH')
end

return;

function phi=drxlr_probit(x)
%DREES subfunction
%Written by Issam El Naqa 2003-2005
%Extracted for generalized use 2005, AJH

phi=0.5*(1+erf(x/1.4142));
return
