function ntcpGUI(command)
%function ntcpGUI(command)
%
%GUI to model NTCP.
%
%APA, 02/26/07
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

global planC
indexS = planC{end};

switch upper(command)
    case 'INIT'

        %initialize figure for GUI
        hNTCPGUI = findobj('tag','ntcpGUI');
        delete(hNTCPGUI)
        str1 = 'Interactive NTCP modeling';
        position = [200 100 600 400];
        hFig = figure('color',[0.8 0.9 0.9],'name',str1,'tag','ntcpGUI','numbertitle','off','position',position);
        ud.modelAxis = axes('position',[0.1 0.3 0.5 0.6],'tag','modelAxis','nextPlot','add','box','on');
        set(ud.modelAxis,'tag','ntcpAxis')
        figureColor = get(hFig, 'Color');

        %create UIcontrols
        units = 'normalized';
        uicontrol(hFig,'style','text','string','Select Model','units',units,'position',[0.65 0.9 0.15 0.04],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left')
        ud.model = uicontrol(hFig,'style','popup','string',{'LKB','CV','WUSTL LUNG'},'units',units,'position',[0.82 0.9 0.15 0.04],'fontWeight','normal','fontSize',10,'callBack','ntcpGUI(''EUD_CHANGED'')');
        uicontrol(hFig,'style','text','string','Select Struct','units',units,'position',[0.65 0.8 0.15 0.04],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left')
        %Build list of structure names.
        numStructs = length(planC{indexS.structures});
        if numStructs > 0
            [structuresC{1:numStructs}] = deal(planC{indexS.structures}.structureName);
        else
            structuresC = {'---'};
        end
        ud.struct = uicontrol(hFig,'style','popup','string',structuresC,'units',units,'position',[0.82 0.8 0.15 0.04],'fontWeight','normal','fontSize',10,'callBack','ntcpGUI(''EUD_CHANGED'')');
        uicontrol(hFig,'style','text','string','Select Dose','units',units,'position',[0.65 0.7 0.15 0.04],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left')
        %Build list of dose names.
        numDoses = length(planC{indexS.dose});
        if numDoses > 0
            [dosesC{1:numDoses}] = deal(planC{indexS.dose}.fractionGroupID);
        else
            dosesC = {'---'};
        end
        ud.dose = uicontrol(hFig,'style','popup','string',dosesC,'units',units,'position',[0.82 0.7 0.15 0.04],'fontWeight','normal','fontSize',10,'callBack','ntcpGUI(''EUD_CHANGED'')');

        %Information frame
        ud.info.frame = uicontrol(hFig,'style','frame','units',units,'position',[0.1 0.05 0.5 0.12],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'visible','off');
        ud.info.NTCP = uicontrol(hFig,'style','text','string','NTCP = ','units',units,'position',[0.11 0.12 0.48 0.04],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'visible','off');
        ud.info.EUD = uicontrol(hFig,'style','text','string','EUD = ','units',units,'position',[0.11 0.06 0.48 0.04],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'visible','off');

        %LKB parameter handles
        ud.params.lkb.n     = [];
        ud.params.lkb.D50   = [];
        ud.params.lkb.m     = [];

        %CV parameter handles
        ud.params.cv.mu_cr     = [];
        ud.params.cv.sigma     = [];
        ud.params.cv.D50       = [];
        ud.params.cv.gamma50   = [];

        ud.modelCurve = [];
        ud.refLines = [];
        ud.maxDose = [];
        ud.eudChanged = 1;

        set(hFig,'userdata',ud)

        ntcpGUI('REFRESH')


    case 'CHANGEMODEL'
        hFig = findobj('tag','ntcpGUI');
        ud = get(hFig,'userdata');
        val = get(ud.model,'value');
        if val~=1
            msgbox('Currently, interactive modeling for models other than LKB is not available','Work in Progress','modal')
            set(ud.model,'value',1)
            return;
        end

    case 'EUD_CHANGED'
        modelIndex = get(gcbo,'value');
        if modelIndex == 3 % WUSTL LUNG model
            X1 = [0 32];
            X2 = [1 0];
            b = [0.1134   -2.8147   -1.4954];
            varName1 = 'MeanDose Lung';
            varName2 = 'COMSI';
            radModelType = 'NTCP';
            plotNomogram('init',X1,X2,b,varName1,varName2,radModelType)
        end

        hFig = findobj('tag','ntcpGUI');
        ud = get(hFig,'userdata');
        ud.eudChanged = 1;
        set(hFig,'userdata',ud)
        ntcpGUI('REFRESH')

    case 'REFRESH'

        hFig = findobj('tag','ntcpGUI');
        figureColor = get(hFig, 'Color');

        ud = get(hFig,'userdata');

        %delete old model curve
        delete(ud.modelCurve)
        ud.modelCurve = [];
        delete(ud.refLines)
        ud.refLines = [];

        %initialize handles for LKB model if empty
        if isempty(ud.params.lkb.n)
            units = 'normalized';
            ud.params.lkb.n(1) = uicontrol(hFig,'style','text','string','Exponent (a)','units',units,'position',[0.65 0.6 0.15 0.04],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
            ud.params.lkb.n(2) = uicontrol(hFig,'style','slider','min',-30,'max',30,'value',0.67,'units',units,'position',[0.65 0.55 0.15 0.04],'callBack','ntcpGUI(''EUD_CHANGED'')');
            ud.params.lkb.n(3) = uicontrol(hFig,'style','edit','string','0.67','units',units,'position',[0.82 0.55 0.1 0.04],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'callBack','ntcpGUI(''LKB_A_CHANGED'')');

            ud.params.lkb.D50(1) = uicontrol(hFig,'style','text','string','D50','units',units,'position',[0.65 0.48 0.15 0.04],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
            ud.params.lkb.D50(2) = uicontrol(hFig,'style','slider','min',0,'max',100,'value',21,'units',units,'position',[0.65 0.43 0.15 0.04],'callBack','ntcpGUI(''REFRESH'')');
            ud.params.lkb.D50(3) = uicontrol(hFig,'style','edit','string','21','units',units,'position',[0.82 0.43 0.1 0.04],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'callBack','ntcpGUI(''LKB_D50_CHANGED'')');

            ud.params.lkb.m(1) = uicontrol(hFig,'style','text','string','m','units',units,'position',[0.65 0.36 0.2 0.04],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
            ud.params.lkb.m(2) = uicontrol(hFig,'style','slider','min',0.001,'max',3,'value',0.59,'units',units,'position',[0.65 0.31 0.15 0.04],'callBack','ntcpGUI(''REFRESH'')');
            ud.params.lkb.m(3) = uicontrol(hFig,'style','edit','string','0.59','units',units,'position',[0.82 0.31 0.1 0.04],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'callBack','ntcpGUI(''LKB_M_CHANGED'')');
        end

        if isempty(ud.params.cv.mu_cr)
            units = 'normalized';
            ud.params.cv.mu_cr(1) = uicontrol(hFig,'style','text','string','Crit Rel Vol','units',units,'position',[0.65 0.6 0.15 0.04],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
            ud.params.cv.mu_cr(2) = uicontrol(hFig,'style','slider','min',0.001,'max',1,'value',0.23,'units',units,'position',[0.65 0.55 0.15 0.04],'callBack','ntcpGUI(''EUD_CHANGED'')');
            ud.params.cv.mu_cr(3) = uicontrol(hFig,'style','edit','string','0.23','units',units,'position',[0.82 0.55 0.1 0.04],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'callBack','ntcpGUI(''CV_MU_CR_CHANGED'')');

            ud.params.cv.sigma(1) = uicontrol(hFig,'style','text','string','Popul Var','units',units,'position',[0.65 0.48 0.15 0.04],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
            ud.params.cv.sigma(2) = uicontrol(hFig,'style','slider','min',0.005,'max',2,'value',0.25,'units',units,'position',[0.65 0.43 0.15 0.04],'callBack','ntcpGUI(''REFRESH'')');
            ud.params.cv.sigma(3) = uicontrol(hFig,'style','edit','string','0.25','units',units,'position',[0.82 0.43 0.1 0.04],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'callBack','ntcpGUI(''CV_SIGMA_CHANGED'')');

            ud.params.cv.D50(1) = uicontrol(hFig,'style','text','string','D50','units',units,'position',[0.65 0.36 0.2 0.04],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
            ud.params.cv.D50(2) = uicontrol(hFig,'style','slider','min',0,'max',100,'value',30,'units',units,'position',[0.65 0.31 0.15 0.04],'callBack','ntcpGUI(''REFRESH'')');
            ud.params.cv.D50(3) = uicontrol(hFig,'style','edit','string','30','units',units,'position',[0.82 0.31 0.1 0.04],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'callBack','ntcpGUI(''CV_D50_CHANGED'')');

            ud.params.cv.gamma50(1) = uicontrol(hFig,'style','text','string','gamma50','units',units,'position',[0.65 0.24 0.2 0.04],'fontWeight','bold','fontSize',10,'BackgroundColor', figureColor,'HorizontalAlignment','left');
            ud.params.cv.gamma50(2) = uicontrol(hFig,'style','slider','min',0.01,'max',1,'value',0.1,'units',units,'position',[0.65 0.19 0.15 0.04],'callBack','ntcpGUI(''REFRESH'')');
            ud.params.cv.gamma50(3) = uicontrol(hFig,'style','edit','string','0.74','units',units,'position',[0.82 0.19 0.1 0.04],'fontWeight','normal','fontSize',10,'BackgroundColor', figureColor,'callBack','ntcpGUI(''CV_GAMMA50_CHANGED'')');
        end

        %get structNum and doseNum if defined
        structNum = get(ud.struct,'value');
        structStr = get(ud.struct,'string');
        doseNum = get(ud.dose,'value');
        doseStr = get(ud.dose,'string');
        if strcmpi(structStr{structNum},'---') || strcmpi(doseStr{doseNum},'---')
            structNum = [];
            doseNum = [];
        end

        ntcpModelStr = get(ud.model,'String');
        ntcpModelNum = get(ud.model,'Value');
        ntcpModel = ntcpModelStr{ntcpModelNum};
        switch upper(ntcpModel)
            case 'LKB'
                %turn off CV handles
                set([ud.params.cv.mu_cr ud.params.cv.sigma ud.params.cv.D50 ud.params.cv.gamma50],'visible','off')
                %turn on LKB handles
                set([ud.params.lkb.n ud.params.lkb.D50 ud.params.lkb.m],'visible','on')
                n   = get(ud.params.lkb.n(2),'value');
                set(ud.params.lkb.n(3),'string',num2str(n))
                D50 = get(ud.params.lkb.D50(2),'value');
                set(ud.params.lkb.D50(3),'string',num2str(D50))
                m   = get(ud.params.lkb.m(2),'value');
                set(ud.params.lkb.m(3),'string',num2str(m))
                EUDv = linspace(0,100,100);
                if ~isempty(structNum) && ~isempty(doseNum) && ud.eudChanged
                    [ud.doseBinsV, ud.volsHistV] = getDVH(structNum, doseNum,planC);
                    ud.EUD = calc_EUD(ud.doseBinsV, ud.volsHistV, n);
                    ud.maxDose = max(planC{indexS.dose}(doseNum).doseArray(:));
                    ud.eudChanged = 0;
                elseif isempty(structNum) && isempty(doseNum)
                    ud.EUD = [];
                end
                %Convert to sigmoidal complication probability:
                tmpv = (EUDv - D50)/(m*D50);
                ntcpV = 1/2 * (1 + erf(tmpv/2^0.5));
                %Compute ntcp for selected dose and structure
                if ~isempty(ud.EUD)
                    tmp = (ud.EUD - D50)/(m*D50);
                    ntcp = 1/2 * (1 + erf(tmp/2^0.5));
                end

                ud.modelCurve = plot(EUDv,ntcpV,'k','linewidth',2,'parent',ud.modelAxis);
                xlabel('Equivalent Uniform Dose (Gy)','parent',ud.modelAxis)
                ylabel('Normal Tissue Complication Probability','parent',ud.modelAxis)
                if ~isempty(ud.EUD)
                    ud.refLines = plot([ud.EUD ud.EUD],[0 ntcp],'b--','parent',ud.modelAxis);
                    ud.refLines = [ud.refLines plot([0 ud.EUD],[ntcp ntcp],'b--','parent',ud.modelAxis)];
                    set([ud.info.frame ud.info.NTCP ud.info.EUD],'visible','on')
                    set(ud.info.NTCP,'string',['NTCP = ',num2str(ntcp)])
                    set(ud.info.EUD,'string',['EUD = ',num2str(ud.EUD)])
                else
                    set([ud.info.frame ud.info.NTCP ud.info.EUD],'visible','off')
                end

                if ~isempty(ud.maxDose)
                    set(ud.modelAxis,'xLim',[0 ud.maxDose],'yLim',[0 1])
                else
                    set(ud.modelAxis,'xLim',[0 90],'yLim',[0 1])
                end

            case 'CV'
                %turn on CV handles
                set([ud.params.cv.mu_cr ud.params.cv.sigma ud.params.cv.D50 ud.params.cv.gamma50],'visible','on')
                %turn off LKB handles
                set([ud.params.lkb.n ud.params.lkb.D50 ud.params.lkb.m],'visible','off')
                mu_cr   = get(ud.params.cv.mu_cr(2),'value');
                set(ud.params.cv.mu_cr(3),'string',num2str(mu_cr))
                sigma = get(ud.params.cv.sigma(2),'value');
                set(ud.params.cv.sigma(3),'string',num2str(sigma))
                D50   = get(ud.params.cv.D50(2),'value');
                set(ud.params.cv.D50(3),'string',num2str(D50))
                gamma50   = get(ud.params.cv.gamma50(2),'value');
                set(ud.params.cv.gamma50(3),'string',num2str(gamma50))
                mu_dv = linspace(0.001,1,100);
                if ~isempty(structNum) && ~isempty(doseNum) && ud.eudChanged
                    [ud.doseBinsV, ud.volsHistV] = getDVH(structNum, doseNum,planC);
                    ud.eudChanged = 0;
                elseif isempty(structNum) && isempty(doseNum)
                    ud.doseBinsV = [];
                end
                if ~isempty(ud.doseBinsV)
                    ud.mu_d = sum(ud.volsHistV.*drxlr_probit(1.4142*pi*gamma50*log(ud.doseBinsV/D50+eps)))/sum(ud.volsHistV);
                    ntcp = drxlr_probit((-log(-log(ud.mu_d))+log(-log(mu_cr)))/sigma);
                    ud.maxDose = max(planC{indexS.dose}(doseNum).doseArray(:));
                    ud.maxDose = [];
                else
                    ud.maxDose = [];
                    ud.mu_d = [];
                end
                ntcpV = drxlr_probit((-log(-log(mu_dv-eps))+log(-log(mu_cr)))/sigma);
                ud.modelCurve = plot(mu_dv,ntcpV,'k','linewidth',2,'parent',ud.modelAxis);
                xlabel('mu_d','parent',ud.modelAxis)
                ylabel('Normal Tissue Complication Probability','parent',ud.modelAxis)
                if ~isempty(ud.mu_d)
                    ud.refLines = plot([ud.mu_d ud.mu_d],[0 ntcp],'b--','parent',ud.modelAxis);
                    ud.refLines = [ud.refLines plot([0 ud.mu_d],[ntcp ntcp],'b--','parent',ud.modelAxis)];
                    set([ud.info.frame ud.info.NTCP ud.info.EUD],'visible','on')
                    set(ud.info.NTCP,'string',['NTCP = ',num2str(ntcp)])
                    set(ud.info.EUD,'string',['Relative Damaged Volume = ',num2str(ud.mu_d)])
                else
                    set([ud.info.frame ud.info.NTCP ud.info.EUD],'visible','off')
                end

                if ~isempty(ud.maxDose)
                    set(ud.modelAxis,'xLim',[0 ud.maxDose],'yLim',[0 1])
                else
                    set(ud.modelAxis,'xLim',[0.001,1],'yLim',[0 1])
                end

        end

        set(hFig,'userdata',ud)

    case 'LKB_A_CHANGED'
        hFig = findobj('tag','ntcpGUI');
        ud = get(hFig,'userdata');
        a = str2double(get(ud.params.lkb.n(3),'string'));
        if isnumeric(a) && a>=-30 && a<=30
            set(ud.params.lkb.n(2),'value',a)
        else
            set(ud.params.lkb.n(3),'string',num2str(get(ud.params.lkb.n(2),'value')))
        end
        ntcpGUI('EUD_CHANGED')

    case 'LKB_D50_CHANGED'
        hFig = findobj('tag','ntcpGUI');
        ud = get(hFig,'userdata');
        D50 = str2double(get(ud.params.lkb.D50(3),'string'));
        if ~isnan(D50) && D50>=0 && D50<=ud.maxDose
            set(ud.params.lkb.D50(2),'value',D50)
        else
            set(ud.params.lkb.D50(3),'string',num2str(get(ud.params.lkb.D50(2),'value')))
        end
        ntcpGUI('REFRESH')

    case 'LKB_M_CHANGED'
        hFig = findobj('tag','ntcpGUI');
        ud = get(hFig,'userdata');
        m = str2double(get(ud.params.lkb.m(3),'string'));
        if isnumeric(m) && m>=0.001 && m<=3
            set(ud.params.lkb.m(2),'value',m)
        else
            set(ud.params.lkb.m(3),'string',num2str(get(ud.params.lkb.m(2),'value')))
        end
        ntcpGUI('REFRESH')

    case 'CV_MU_CR_CHANGED'
        hFig = findobj('tag','ntcpGUI');
        ud = get(hFig,'userdata');
        mu_cr = str2double(get(ud.params.cv.mu_cr(3),'string'));
        if isnumeric(mu_cr) && mu_cr>=0.001 && mu_cr<=1
            set(ud.params.cv.mu_cr(2),'value',mu_cr)
        else
            set(ud.params.cv.mu_cr(3),'string',num2str(get(ud.params.cv.mu_cr(2),'value')))
        end
        ntcpGUI('REFRESH')

    case 'CV_SIGMA_CHANGED'
        hFig = findobj('tag','ntcpGUI');
        ud = get(hFig,'userdata');
        sigma = str2double(get(ud.params.cv.sigma(3),'string'));
        if isnumeric(sigma) && sigma>=0.0005 && sigma<=2
            set(ud.params.cv.sigma(2),'value',sigma)
        else
            set(ud.params.cv.sigma(3),'string',num2str(get(ud.params.cv.sigma(2),'value')))
        end
        ntcpGUI('REFRESH')

    case 'CV_D50_CHANGED'
        hFig = findobj('tag','ntcpGUI');
        ud = get(hFig,'userdata');
        D50 = str2double(get(ud.params.cv.D50(3),'string'));
        if isnumeric(D50) && D50>=0 && D50<=100
            set(ud.params.cv.D50(2),'value',D50)
        else
            set(ud.params.cv.D50(3),'string',num2str(get(ud.params.cv.D50(2),'value')))
        end
        ntcpGUI('REFRESH')

    case 'CV_GAMMA50_CHANGED'
        hFig = findobj('tag','ntcpGUI');
        ud = get(hFig,'userdata');
        gamma50 = str2double(get(ud.params.cv.gamma50(3),'string'));
        if isnumeric(gamma50) && gamma50>=0.01 && gamma50<=1
            set(ud.params.cv.gamma50(2),'value',gamma50)
        else
            set(ud.params.cv.gamma50(3),'string',num2str(get(ud.params.cv.gamma50(2),'value')))
        end
        ntcpGUI('REFRESH')
end

return;

function phi=drxlr_probit(x)
%DREES subfunction
%Written by Issam El Naqa 2003-2005
%Extracted for generalized use 2005, AJH

phi=0.5*(1+erf(x/1.4142));
return
