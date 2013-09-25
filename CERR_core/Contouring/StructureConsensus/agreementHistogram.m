function agreementHistogram(command,varargin)
%function agreementHistogram(command,varargin)
%
%Active Histogram for structure comparison
%
%APA, 03/28/2007
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

global stateS
hFig = findobj('name','Agreement Histogram');

switch upper(command)
    case 'INIT'
        percentV        = varargin{1};
        volV            = varargin{2};
        volStapleV      = varargin{3};
        volKappaV       = varargin{4};
        staple3M        = varargin{5};
        reliability_mat = varargin{6};
        if ~isempty(hFig)
            delete(hFig)
        end
        position = [30 80 600 400];
        hFig        = figure('name','Agreement Histogram','numbertitle','off','position',position,'WindowButtonDownFcn', 'agreementHistogram(''buttondown'');','WindowButtonUpFcn', 'agreementHistogram(''buttonup'');', 'WindowButtonMotionFcn', 'agreementHistogram(''buttonmotion'');', 'interruptible', 'off','CloseRequestFcn','structCompare({''exit''});');
        hAxis       = axes('units', 'normalized', 'position', [0.14 0.14 0.6 0.8],'tag','AgreementHistAx','parent', hFig, 'nextplot', 'add');
        figColor    = get(hFig,'color');
        %Cutoff
        uicontrol(hFig, 'units', 'normalized', 'Position', [0.76 0.85 0.14 0.05], 'Style', 'text', 'enable', 'inactive'  , 'String', 'Confidence:', 'foregroundcolor',[0 0 0] , 'backgroundcolor', figColor, 'fontsize', 10,'fontweight', 'normal','horizontalAlignment','left');
        ud.confidenceLevel = uicontrol(hFig, 'units', 'normalized', 'Position', [0.91 0.85 0.08 0.05], 'Style', 'text', 'String', num2str(mean(percentV)), 'foregroundcolor',[0 0 0] , 'backgroundcolor', figColor, 'fontsize', 9,'fontweight', 'normal','horizontalAlignment','left');
        %Frame
        uicontrol(hFig, 'units', 'normalized', 'Position', [0.75 0.35 0.24 0.47], 'Style', 'frame', 'enable', 'inactive', 'backgroundcolor', figColor, 'fontsize', 12,'fontweight', 'bold','horizontalAlignment','left');
        %Create Structure Heading
        uicontrol(hFig, 'units', 'normalized', 'Position', [0.77 0.75 0.21 0.05], 'Style', 'text', 'enable', 'inactive'  , 'String', 'Create Structure', 'foregroundcolor',[0 0 1] , 'backgroundcolor', figColor, 'fontsize', 12,'fontweight', 'bold','horizontalAlignment','left');
        %Create Structure Heading
        uicontrol(hFig, 'units', 'normalized', 'Position', [0.77 0.65 0.08 0.05], 'Style', 'text', 'enable', 'inactive'  , 'String', 'Name', 'foregroundcolor',[0 0 0] , 'backgroundcolor', figColor, 'fontsize', 9,'fontweight', 'normal','horizontalAlignment','left');
        ud.hNewStructName = uicontrol(hFig, 'units', 'normalized', 'Position', [0.84 0.65 0.14 0.05], 'Style', 'edit', 'String', '', 'foregroundcolor',[0 0 0] , 'backgroundcolor', figColor, 'fontsize', 8,'fontweight', 'normal','horizontalAlignment','left');
        uicontrol(hFig, 'units', 'normalized', 'Position', [0.76 0.55 0.08 0.05], 'Style', 'text', 'enable', 'inactive'  , 'String', 'Method', 'foregroundcolor',[0 0 0] , 'backgroundcolor', figColor, 'fontsize', 9,'fontweight', 'normal','horizontalAlignment','left');
        ud.hNewStructMethod = uicontrol(hFig, 'units', 'normalized', 'Position', [0.84 0.55 0.14 0.05], 'Style', 'popup', 'String', {'Staple','Apparent','Kappa Corrected'}, 'foregroundcolor',[0 0 0] , 'backgroundcolor', figColor, 'fontsize', 9,'fontweight', 'normal','horizontalAlignment','left');
        uicontrol(hFig, 'units', 'normalized', 'Position', [0.82 0.40 0.10 0.05], 'Style', 'push', 'String', 'Go', 'foregroundcolor',[0 0 0] , 'backgroundcolor', figColor, 'fontsize', 10,'fontweight', 'bold','horizontalAlignment','center','callback', 'agreementHistogram(''createStructure'');');
        
        
        plot(percentV,volV,'b-','linewidth',2,'parent',hAxis)
        plot(percentV,volStapleV,'g:','linewidth',2,'parent',hAxis)
        plot(percentV,volKappaV,'m--','linewidth',2,'parent',hAxis)
        legend('Apparent agreement','Staple estimated probabilities','Corrected agreement (Kappa)')
        set(hAxis, 'nextplot', 'replace')
        grid on
        ylabel('\bfAbsolute volume (cc)','parent',hAxis)
        xlabel('\bfConfidence Level (agreement)','parent',hAxis)
        set(hAxis,'xLim',[min(percentV) max(percentV)])
        yLim        = get(hAxis,'yLim');
        hLine       = line([mean(percentV) mean(percentV)],yLim,'color',[1 0 0],'linewidth',1);
        ud.hAxis    = hAxis;
        ud.hLine    = hLine;
        ud.btDwn    = 0;
        ud.staple3M = staple3M;
        ud.reliability_mat = reliability_mat;
        
        set(hFig,'userdata',ud)
        
    case 'BUTTONDOWN'   
        ud = get(hFig,'userdata');
        ud.btDwn    = 1;
        set(hFig,'userdata',ud)
        
    case 'BUTTONMOTION'
        ud = get(hFig,'userdata');
        if ud.btDwn
            cP = get(ud.hAxis, 'CurrentPoint');
            set(ud.hLine, 'XData', [cP(1,1) cP(1,1)]);
        end        
        XData = get(ud.hLine,'XData');
        confidenceLevel = max(0,XData(1));
        set(ud.confidenceLevel,'string',num2str(confidenceLevel))

    case 'BUTTONUP'
        ud = get(hFig,'userdata');
        ud.btDwn    = 0;
        set(hFig,'userdata',ud)    
        XData = get(ud.hLine,'XData');
        showComparisonMask(stateS.structCompare.structAll,max(1e-5,XData(1)))
        
    case 'CREATESTRUCTURE'
        ud = get(hFig,'userdata');  
        hAxis = findobj('parent',hFig,'tag','AgreementHistAx');
        set(hAxis,'nextPlot','add')
        XData = get(ud.hLine,'XData');
        confidenceLevel = max(1e-5,XData(1));
        createMethod = get(ud.hNewStructMethod,'value');
        structureName = get(ud.hNewStructName,'string');
        if isempty(structureName)
            error('Structure Name must be specified.')            
        end
        structNumV = stateS.structCompare.structAll;
        scanNum = getStructureAssociatedScan(structNumV(1));
        if createMethod == 1
            %Staple
            staple3M = ud.staple3M >= confidenceLevel;
            maskToCERRStructure(staple3M, 1, scanNum, structureName);
        elseif createMethod == 2
            %Apparent
            maskM = uint8(getUniformStr(structNumV(1)));
            for i = 2:length(structNumV)
                maskM = maskM + uint8(getUniformStr(structNumV(i)));
            end
            maskM    = maskM >= confidenceLevel * length(structNumV);
            maskToCERRStructure(maskM, 1, scanNum, structureName);

        elseif createMethod == 3
            %Kappa
            reliability_mat = ud.reliability_mat >= confidenceLevel;
            maskToCERRStructure(reliability_mat, 1, scanNum, structureName);
        end        
        set(hAxis,'nextPlot','replace')
end